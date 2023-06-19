"""
$(TYPEDSIGNATURES)

Powder recoating logic. This updates the indices and fills the new real indices with the initial
results provided in the simulation's `Problem`, except the temperature, which is set to `temp`. This
allows for the new powder temp to be set to the temperature of the powder in the hopper, or feed
bed, at that time in the build. This always runs in the positive y axis, so new powder is always
deposited starting from `[:, 1, :]` and going to `[:, end, :]`.
"""
function recoating!(
    pts::AbstractResult,
    cts::AbstractResult,
    G::GVars{T,Gh,Mp,R,OR,B},
    ls::LoadStep,
    recoatDist,
    temp,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    # Skip recoating if the distance is less than the first indices
    if recoatDist < 1
        @debug "recoating!" _group = "b_adv" recoatDist "Recoat Skipped"
        return
    end

    oldiᵢ = ls.ind.iᵢ
    updateInds!(ls.ind, recoatDist, ls.size, G.Tᵗ⁻¹)
    newNodes = oldiᵢ ∩ ls.ind.iᵣ
    for i in newNodes
        pts.T[i] = temp
        G.Tᵗ⁻¹[i] = temp
        pts.M[i] = G.init.M[i]
        pts.C[i] = G.init.C[i]
    end

    calcMatProps!(pts, cts, G, newNodes)
    @debug "recoating!" _group = "b_adv" recoatDist temp newNodes
    return
end

@testitem "recoating!" begin
    using Test, HSSSimulations, JLD2
    using .Boundary
    G, ls, pts, cts = load(joinpath(@__DIR__, "../../test/test_inputs/full_in.jld2"),
        "G", "ls", "pts", "cts")
    temp = 50
    @testset "All top layer is imaginary at no recoat dist" begin
        recoating!(pts, cts, G, ls, 0, temp)
        @test ls.ind.iᵢ == vec(CartesianIndices(pts.T)[:, :, end])
    end
    @testset "Half distance" begin
        recoating!(pts, cts, G, ls, floor(Int, G.geometry.Y / 2), temp)
        @testset "Is setting everything it should" begin
            i = ls.ind.iᵣ[end]
            @test pts.T[i] == temp
            @test G.Tᵗ⁻¹[i] == temp
            @test pts.M[i] == G.init.M[i]
            @test pts.C[i] == G.init.C[i]
        end
    end
    @testset "No imaginaries at full distance" begin
        recoating!(pts, cts, G, ls, G.geometry.Y, temp)
        @test ls.ind.iᵢ == []
    end
end

"""
$(TYPEDSIGNATURES)

Makes a vector the length of the y-axis of the simulation. It represents the overlap between the
simulation area an object that moves in the y-axis, whos left and right edge are given by `objPos`.
The overlap is filled with the value passed as `movingObj`.

The difference between the first and second value of the `objPos` Tuple multipled by the spacing in
the y-axis (Δy) should match the width of the moving object.

# Examples

```jldoctest
julia> geometry = Geometry((0.015, 0.015, 0.010), 0.005, 0.010; offset=(0, 0.01));

julia> movingObjOverlap(geometry, true, (2, 4))
3-element Vector{Bool}:
 1
 1
 0
```
"""
function movingObjOverlap(geometry::Geometry, movingObj, objPos::Tuple{Int,Int})
    objLeft, objRight = objPos .- geometry.Y_OFFSET
    bedLeft = 1
    bedRight = geometry.Y

    ret = zeros(typeof(movingObj), geometry.Y)

    start = bedLeft ∨ objLeft
    finish = bedRight ∧ objRight
    ret[start:finish] .= movingObj
    @debug "mOO non-vector" _group = "b_adv" objLeft objRight start finish

    return ret
end

"""
$(TYPEDSIGNATURES)

Makes a vector the length of the y-axis of the simulation. It represents the overlap between the
simulation area an object that moves in the y-axis, whos right edge are given by `objPos`. The
overlap is filled with the matching values from the vector `movingObj`.

The length of the vector multipled by the spacing in the y-axis (Δy) should match the width of the
moving object.

# Examples

```jldoctest
julia> geometry = Geometry((0.015, 0.015, 0.010), 0.005, 0.010; offset=(0, 0.01));

julia> movingObjOverlap(geometry, [1, 2, 3, 4, 5], 6)
3-element Vector{Int64}:
 2
 3
 4

julia> movingObjOverlap(geometry, [1, 2, 3, 4, 5], 8)
3-element Vector{Int64}:
 0
 1
 2
```
"""
function movingObjOverlap(geometry::Geometry, movingObj::T, objPos::Int) where {T<:AbstractVector}
    bedPos = geometry.Y_OFFSET

    objLeft = objPos - length(movingObj) + 1
    objRight = objPos
    bedLeft = bedPos + 1
    bedRight = bedPos + geometry.Y

    ret = zeros(eltype(movingObj), geometry.Y)

    retStart = bedLeft ∨ objLeft - bedPos
    retFinish = bedRight ∧ objRight - bedPos

    objStart = objLeft ∨ bedLeft - objLeft + 1
    objFinish = objRight ∧ bedRight - objLeft + 1

    ret[retStart:retFinish] .= movingObj[objStart:objFinish]
    @debug "mOO vector" _group = "b_adv" objLeft objRight retStart retFinish objStart objFinish

    return ret
end

"""
$(TYPEDSIGNATURES)

Makes a matrix with the same dimensions as the top surface of the simulation area. It represents the
overlap between the simulation area an object that moves in the y-axis, whos right edge are given by
`objPos`. The overlap is filled with the matching values from the matrix `movingObj`.

Also for Matrix inputs, the length of the first axis multipled by the spacing in the x-axis (Δx)
should match the depth of the moving object and the length of the second axis multipled by the
spacing in the y-axis (Δy) should match the width of the moving object.

# Examples

```jldoctest
julia> geometry = Geometry((0.015, 0.015, 0.010), 0.005, 0.010; offset=(0, 0.01));

julia> movingObjOverlap(geometry, [1 2 3; 4 5 6; 7 8 9], 4)
3×3 Matrix{Int64}:
 2  3  0
 5  6  0
 8  9  0
```
"""
function movingObjOverlap(geometry::Geometry, movingObj::T, objPos::Int) where {T<:AbstractMatrix}
    # NOTE: The matrix method is only tested on a subset of the cases, as it currently uses similar
    # code to the vector method. If the implementation changes, update the tests to cover all cases
    bedPos = geometry.Y_OFFSET

    objLeft = objPos - size(movingObj)[2] + 1
    objRight = objPos
    bedLeft = bedPos + 1
    bedRight = bedPos + geometry.Y

    ret = zeros(eltype(movingObj), geometry.X, geometry.Y)

    retStart = bedLeft ∨ objLeft - bedPos
    retFinish = bedRight ∧ objRight - bedPos

    objXStart = geometry.X_OFFSET + 1
    objXFinish = geometry.X_OFFSET + geometry.X

    objStart = objLeft ∨ bedLeft - objLeft + 1
    objFinish = objRight ∧ bedRight - objLeft + 1

    ret[:, retStart:retFinish] .= movingObj[objXStart:objXFinish, objStart:objFinish]
    @debug "mOO vector" _group = "b_adv" objXStart objXFinish objLeft objRight retStart retFinish objStart objFinish

    return ret
end

@testitem "movingObjOverlap" begin
    using HSSSimulations, Test
    using .Boundary
    # pos: 3-5
    geo = Geometry((0.015, 0.015, 0.010), 0.005, 0.010; offset=(0.01, 0.01))
    # underscores are unsimulated bed, Ω is simulated bed
    # _ _ Ω Ω Ω
    # 1 2 3 4 5
    objVec = [1, 2, 3, 4, 5]
    objVecSmall = [1, 2]
    objVecOne = [1]
    objVecMatch = [1, 2, 3]

    objMat = [
        1 1 1 1 1
        1 2 2 2 1
        1 2 2 2 1
        1 2 3 2 1
        1 2 4 2 1
        1 2 2 2 1
        1 1 1 1 1
    ]

    # All of the following conditions has to be handled. Tested for both a bool and a vector input.
    # The diagrams match to the test cases, e.g the left most diagram is the first test case, and
    # the rightmost the last. For the left and right overlap cases there are multiple tests.
    @testset "no_overlap" begin
        # ----        or        ----                 <-- moving object
        #      ----        ----                      <-- simulated area of bed
        @testset "bool" begin
            @test movingObjOverlap(geo, true, (0, 2)) == [0, 0, 0]
            @test movingObjOverlap(geo, true, (6, 8)) == [0, 0, 0]
        end
        @testset "vector" begin
            @test movingObjOverlap(geo, objVec, 1) == [0, 0, 0]
            @test movingObjOverlap(geo, objVec, 10) == [0, 0, 0]
        end
        @testset "matrix" begin
            @test movingObjOverlap(geo, objMat, 1) == [0 0 0; 0 0 0; 0 0 0]
            @test movingObjOverlap(geo, objMat, 10) == [0 0 0; 0 0 0; 0 0 0]
        end
    end
    @testset "total_overlap" begin
        # ----------  or  ---- or ------ or ------   <-- moving object
        #    ----         ----      ----    ----     <-- simulated area of bed
        @testset "bool" begin
            @test movingObjOverlap(geo, true, (1, 6)) == [1, 1, 1]
            @test movingObjOverlap(geo, true, (3, 5)) == [1, 1, 1]
            @test movingObjOverlap(geo, true, (3, 6)) == [1, 1, 1]
            @test movingObjOverlap(geo, true, (1, 5)) == [1, 1, 1]
        end
        @testset "vector" begin
            @test movingObjOverlap(geo, objVec, 6) == [2, 3, 4]
            @test movingObjOverlap(geo, objVecMatch, 5) == [1, 2, 3]
            @test movingObjOverlap(geo, objVec, 7) == [1, 2, 3]
            @test movingObjOverlap(geo, objVec, 5) == [3, 4, 5]
        end
        @testset "matrix" begin
            @test movingObjOverlap(geo, objMat, 6) == [2 2 2; 2 3 2; 2 4 2]
        end
    end
    @testset "inside_overlap" begin
        #    ----   or ----    or   -----            <-- moving object
        #   ------     ------     -------            <-- simulated area of bed
        @testset "bool" begin
            @test movingObjOverlap(geo, true, (4, 4)) == [0, 1, 0]
            @test movingObjOverlap(geo, true, (3, 3)) == [1, 0, 0]
            @test movingObjOverlap(geo, true, (5, 5)) == [0, 0, 1]
        end
        @testset "vector" begin
            @test movingObjOverlap(geo, objVecOne, 4) == [0, 1, 0]
            @test movingObjOverlap(geo, objVecSmall, 4) == [1, 2, 0]
            @test movingObjOverlap(geo, objVecSmall, 5) == [0, 1, 2]
        end
    end
    @testset "left_overlap" begin
        # -----                                      <-- moving object
        #   -----                                    <-- simulated area of bed
        @testset "bool" begin
            @test movingObjOverlap(geo, true, (2, 4)) == [1, 1, 0]
            @test movingObjOverlap(geo, true, (2, 3)) == [1, 0, 0]
        end
        @testset "vector" begin
            @test movingObjOverlap(geo, objVec, 4) == [4, 5, 0]
            @test movingObjOverlap(geo, objVec, 3) == [5, 0, 0]
            @test movingObjOverlap(geo, objVecSmall, 3) == [2, 0, 0]
        end
    end
    @testset "right_overlap" begin
        #      -----                                 <-- moving object
        #   ------                                   <-- simulated area of bed
        @testset "bool" begin
            @test movingObjOverlap(geo, true, (4, 6)) == [0, 1, 1]
            @test movingObjOverlap(geo, true, (5, 6)) == [0, 0, 1]
        end
        @testset "vector" begin
            @test movingObjOverlap(geo, objVec, 8) == [0, 1, 2]
            @test movingObjOverlap(geo, objVec, 9) == [0, 0, 1]
            @test movingObjOverlap(geo, objVecSmall, 6) == [0, 0, 1]
        end
    end
end
