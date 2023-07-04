"""
$(TYPEDSIGNATURES)

Calculates the indices at the start of a load. For build load sets this includes 'imaginary' nodes
that don't yet represent a volume with powder in it (but will after recoat). `recoatLoadSet` should
be set to true if the current load set includes powder recoating, and false if it does not.

See [`Types.Indices`](@ref) for more details on the struct returned by this function.
"""
function calcInds(res, ghost, ΔH, recoatLoadSet)
    ind = CartesianIndices(res)
    linInd = LinearIndices(res)
    x, y, z = size(ind)
    gInd = LinearIndices(ghost)

    # Set all (but z₂) boundaries
    #!format: off
    # ^ to keep these lined up
    x₁ = [(ind[  1, j, k], linInd[  1, j, k], gInd[  0, j, k]) for j in 1:y, k in 1:z]
    x₂ = [(ind[end, j, k], linInd[end, j, k], gInd[end, j, k]) for j in 1:y, k in 1:z]
    y₁ = [(ind[i,   1, k], linInd[i,   1, k], gInd[i,   0, k]) for i in 1:x, k in 1:z]
    y₂ = [(ind[i, end, k], linInd[i, end, k], gInd[i, end, k]) for i in 1:x, k in 1:z]
    z₁ = [(ind[i,   j, 1], linInd[i,   j, 1], gInd[i, j,   0]) for i in 1:x, j in 1:y]
    #!format: on

    if recoatLoadSet
        # On normal layers set the top to be imaginary
        iᵣ = vec(ind[:, :, 1:(end-ΔH)])
        iᵢ = vec(ind[:, :, (1+end-ΔH):end])
        z₂ = [
            (ind[i, j, end-ΔH], linInd[i, j, end-ΔH], gInd[i, j, (z-ΔH)+1])
            for i in 1:x, j in 1:y
        ]
    else
        # On preheat and cool down layers set everything as real
        iᵣ = vec(ind)
        iᵢ = CartesianIndices([])
        z₂ = [(ind[i, j, end], linInd[i, j, end], gInd[i, j, z+1]) for i in 1:x, j in 1:y]
    end

    iₘ = iᵣ[cld(length(iᵣ), 2)]

    return Types.Indices(iᵣ, iᵢ, x₁, x₂, y₁, y₂, z₁, z₂, iₘ, ΔH)
end

@testitem "calcInds" begin
    using HSSSimulations, Test
    using OffsetArrays
    using .Types, .Boundary
    CI = CartesianIndex
    res = (2, 2, 3)
    ghost = OffsetArray(zeros(4, 4, 6), -1, -1, -1)
    @testset "any_load" begin
        ΔH = 1
        inds = calcInds(res, ghost, ΔH, Types.PreheatLoadSet)
        @test inds.x₁ == [
            (CI(1, 1, 1), CI(0, 1, 1))  (CI(1, 1, 2), CI(0, 1, 2))  (CI(1, 1, 3), CI(0, 1, 3))
            (CI(1, 2, 1), CI(0, 2, 1))  (CI(1, 2, 2), CI(0, 2, 2))  (CI(1, 2, 3), CI(0, 2, 3))
        ]
        @test inds.x₂ == [
            (CI(2, 1, 1), CI(3, 1, 1))  (CI(2, 1, 2), CI(3, 1, 2))  (CI(2, 1, 3), CI(3, 1, 3))
            (CI(2, 2, 1), CI(3, 2, 1))  (CI(2, 2, 2), CI(3, 2, 2))  (CI(2, 2, 3), CI(3, 2, 3))
        ]
        @test inds.y₁ == [
            (CI(1, 1, 1), CI(1, 0, 1))  (CI(1, 1, 2), CI(1, 0, 2))  (CI(1, 1, 3), CI(1, 0, 3))
            (CI(2, 1, 1), CI(2, 0, 1))  (CI(2, 1, 2), CI(2, 0, 2))  (CI(2, 1, 3), CI(2, 0, 3))
        ]
        @test inds.y₂ == [
            (CI(1, 2, 1), CI(1, 3, 1))  (CI(1, 2, 2), CI(1, 3, 2))  (CI(1, 2, 3), CI(1, 3, 3))
            (CI(2, 2, 1), CI(2, 3, 1))  (CI(2, 2, 2), CI(2, 3, 2))  (CI(2, 2, 3), CI(2, 3, 3))
        ]
        @test inds.z₁ == [
            (CI(1, 1, 1), CI(1, 1, 0))  (CI(1, 2, 1), CI(1, 2, 0))
            (CI(2, 1, 1), CI(2, 1, 0))  (CI(2, 2, 1), CI(2, 2, 0))
        ]
    end
    @testset "other_loads_only" begin
        ΔH = 1
        inds = calcInds(res, ghost, ΔH, Types.PreheatLoadSet)
        @test inds.z₂ == [
            (CI(1, 1, 3), CI(1, 1, 4))  (CI(1, 2, 3), CI(1, 2, 4))
            (CI(2, 1, 3), CI(2, 1, 4))  (CI(2, 2, 3), CI(2, 2, 4))
        ]
        @test inds.iᵣ == vec(CartesianIndices(res))
        @test inds.iᵢ == []
    end
    @testset "build_loads_only" begin
        ΔH = 1
        inds = calcInds(res, ghost, ΔH, Types.BuildLoadSet)
        @test inds.z₂ == [
            (CI(1, 1, 2), CI(1, 1, 3))  (CI(1, 2, 2), CI(1, 2, 3))
            (CI(2, 1, 2), CI(2, 1, 3))  (CI(2, 2, 2), CI(2, 2, 3))
        ]
        @test inds.iᵣ == vec(CartesianIndices(res)[:, :, 1:2])
        @test inds.iᵢ == vec(CartesianIndices(res)[:, :, 3])
    end
    @testset "build_loads_thick_layer" begin
        ΔH = 2
        inds = calcInds(res, ghost, ΔH, Types.BuildLoadSet)
        @test inds.z₂ == [
            (CI(1, 1, 1), CI(1, 1, 2))  (CI(1, 2, 1), CI(1, 2, 2))
            (CI(2, 1, 1), CI(2, 1, 2))  (CI(2, 2, 1), CI(2, 2, 2))
        ]
        @test inds.iᵣ == vec(CartesianIndices(res)[:, :, 1])
        @test inds.iᵢ == vec(CartesianIndices(res)[:, :, 2:3])
    end
end

"""
$(TYPEDSIGNATURES)

Updates an indices struct during a load step. Used to update the real and imaginary nodes during
recoat of the powder layer based on the `recoatDist` (how far through the layer the powder has
been deposited in number of nodes into the simulation area).
"""
function updateInds!(indStruct::Types.Indices, recoatDist, resSize, ghost)
    ind = CartesianIndices(resSize)
    linInd = LinearIndices(resSize)
    x, y, z = resSize
    gInd = LinearIndices(ghost)
    recoatHeight = z - indStruct.ΔH

    # Update the active/inactive nodes
    indStruct.iᵣ =
        vcat(vec(ind[:, :, 1:recoatHeight]), vec(ind[:, 1:recoatDist, (recoatHeight+1):end]))
    indStruct.iᵢ = vec(ind[:, (recoatDist+1):end, (recoatHeight+1):end])

    # Update the y₂ face so that boundary isn't left dangling
    if indStruct.ΔH > 1
        indStruct.y₂ = hcat(
            [
                (ind[i, end, k], linInd[i, end, k], gInd[i, end, k]) for i in 1:x,
                k in 1:(recoatHeight+1)
            ],
            [
                (ind[i, recoatDist, k], linInd[i, recoatDist, k], gInd[i, recoatDist+1, k]) for
                i in 1:x,
                k in (recoatHeight+2):z
            ],
        )
    end

    indStruct.z₂ = hcat(
        [(ind[i, j, end], linInd[i, j, end], gInd[i, j, z+1]) for i in 1:x, j in 1:recoatDist],
        [
            (ind[i, j, recoatHeight], linInd[i, j, recoatHeight], gInd[i, j, recoatHeight+1])
            for i in 1:x,
            j in (recoatDist+1):y
        ],
    )

    indStruct.iₘ = indStruct.iᵣ[cld(length(indStruct.iᵣ), 2)]

    return
end

@testitem "updateInds!" begin
    using HSSSimulations, Test
    using OffsetArrays
    using .Types, .Boundary
    CI = CartesianIndex
    res = (2, 2, 3)
    ghost = OffsetArray(zeros(4, 4, 6), -1, -1, -1)
    @testset "thin_layer_partial" begin
        ΔH = 1
        inds = calcInds(res, ghost, ΔH, Types.BuildLoadSet)
        oldy = copy(inds.y₂)
        Boundary.updateInds!(inds, 1, res, ghost)
        @test inds.z₂ == [
            (CI(1, 1, 3), CI(1, 1, 4))  (CI(1, 2, 2), CI(1, 2, 3))
            (CI(2, 1, 3), CI(2, 1, 4))  (CI(2, 2, 2), CI(2, 2, 3))
        ]
        @test inds.y₂ == oldy
        @test inds.iᵣ ==
              vcat(vec(CartesianIndices(res)[:, :, 1:2]), vec(CartesianIndices(res)[:, 1, 3]))
        @test inds.iᵢ == vec(CartesianIndices(res)[:, 2, 3])
        @test sort(inds.iᵣ ∪ inds.iᵢ) == vec(CartesianIndices(res))
        @test inds.iᵣ ∩ inds.iᵢ == CartesianIndex{3}[]
    end
    @testset "thin_layer_full" begin
        ΔH = 1
        inds = calcInds(res, ghost, ΔH, Types.BuildLoadSet)
        Boundary.updateInds!(inds, 2, res, ghost)
        @test inds.z₂ == [
            (CI(1, 1, 3), CI(1, 1, 4))  (CI(1, 2, 3), CI(1, 2, 4))
            (CI(2, 1, 3), CI(2, 1, 4))  (CI(2, 2, 3), CI(2, 2, 4))
        ]
        @test inds.y₂ == [
            (CI(1, 2, 1), CI(1, 3, 1))  (CI(1, 2, 2), CI(1, 3, 2))  (CI(1, 2, 3), CI(1, 3, 3))
            (CI(2, 2, 1), CI(2, 3, 1))  (CI(2, 2, 2), CI(2, 3, 2))  (CI(2, 2, 3), CI(2, 3, 3))
        ]
        @test inds.iᵣ == vec(CartesianIndices(res))
        @test inds.iᵢ == CartesianIndex{3}[]
        @test sort(inds.iᵣ ∪ inds.iᵢ) == vec(CartesianIndices(res))
        @test inds.iᵣ ∩ inds.iᵢ == CartesianIndex{3}[]
    end
    @testset "thick_layer" begin
        ΔH = 2
        inds = calcInds(res, ghost, ΔH, Types.BuildLoadSet)
        Boundary.updateInds!(inds, 1, res, ghost)
        @test inds.z₂ == [
            (CI(1, 1, 3), CI(1, 1, 4))  (CI(1, 2, 1), CI(1, 2, 2))
            (CI(2, 1, 3), CI(2, 1, 4))  (CI(2, 2, 1), CI(2, 2, 2))
        ]
        @test inds.y₂ == [
            (CI(1, 2, 1), CI(1, 3, 1))  (CI(1, 2, 2), CI(1, 3, 2))  (CI(1, 1, 3), CI(1, 2, 3))
            (CI(2, 2, 1), CI(2, 3, 1))  (CI(2, 2, 2), CI(2, 3, 2))  (CI(2, 1, 3), CI(2, 2, 3))
        ]
        @test inds.iᵣ ==
              vcat(vec(CartesianIndices(res)[:, :, 1]), vec(CartesianIndices(res)[:, 1, 2:3]))
        @test inds.iᵢ == vec(CartesianIndices(res)[:, 2, 2:3])
        @test sort(inds.iᵣ ∪ inds.iᵢ) == vec(CartesianIndices(res))
        @test inds.iᵣ ∩ inds.iᵢ == CartesianIndex{3}[]
    end
end
