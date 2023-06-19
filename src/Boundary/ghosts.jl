"""
$(TYPEDSIGNATURES)

Wraps the temperature array with ghost cells and updates the Tᵗ⁻¹ array in the
[`Problem`](@ref) with the new value. The ghost cells are calculated based on a the boundaries
for each face provided in the current load. See [`Types.Load`](@ref) for more details on these
boundaries.
"""
function padWithGhost!(pts::AbstractResult, cts::AbstractResult, ls, prob)
    prob.Tᵗ⁻¹[CartesianIndices(pts.T)] = pts.T
    (; Δx, Δy, Δz) = prob.geometry

    # Run the z₂ boundary parameter calculator, and then calculate the ghost nodes for z₂
    # boundary equation.
    # The top boundary goes first as that is probably where you'll put things like recoat logic.
    # This is done outside of the loop so that the inds lists in the loop represent the updated ones.
    params::ls.load.z₂ = ls.load.z₂(pts, cts, prob, ls)
    innerLoop!(prob.Tᵗ⁻¹, pts.T, params, ls.ind.z₂, Δz, prob.κ)
    @debug "padWithGhost!" _group = "bound" ls.load.z₂ prob.Tᵗ⁻¹[ls.ind.z₂[end][1]] prob.Tᵗ⁻¹[ls.ind.z₂[end][2]]
    # Iterate over every boundary and calculate the ghost nodes for that boundary using the relevant
    # boundary equation.
    for (loadType, ind, gdist) in (
        (ls.load.z₁, ls.ind.z₁, Δz),
        (ls.load.x₁, ls.ind.x₁, Δx), (ls.load.x₂, ls.ind.x₂, Δx),
        (ls.load.y₁, ls.ind.y₁, Δy), (ls.load.y₂, ls.ind.y₂, Δy),
    )
        loopParams::loadType = loadType(pts, cts, prob, ls)
        innerLoop!(prob.Tᵗ⁻¹, pts.T, loopParams, ind, gdist, prob.κ)
        @debug "padWithGhost!" _group = "bound" loadType prob.Tᵗ⁻¹[ind[end][1]] prob.Tᵗ⁻¹[ind[end][2]]
    end
end

"""
$(TYPEDSIGNATURES)

The inner loop of [`padWithGhost!`](@ref). This exists for no reason other than as a [function
barrier](https://docs.julialang.org/en/v1/manual/performance-tips/#kernel-functions) to allow for
the compiler to know the type of `params` for better dispatch.
"""
innerLoop!(Tᵗ⁻¹, T, params, ind, gdist, κ) =
    Threads.@threads for (i, g) in ind
        ϕ⃗ = boundaryHeatTransferRate(T[i], i, params)
        Tᵗ⁻¹[g] = boundaryTemp(ϕ⃗, T[i], κ[i], gdist)
    end

@testitem "padWithGhost!" begin
    using Test, HSSSimulations, JLD2
    using .Boundary
    prob, ls, pts, cts = load(joinpath(@__DIR__, "../../test/test_inputs/full_in.jld2"),
        "prob", "ls", "pts", "cts")
    padWithGhost!(pts, cts, ls, prob)
    @testset "pts.T copied over" begin
        newT = filter(!=(0.0), prob.Tᵗ⁻¹[CartesianIndices(pts.T)])
        oldT = filter(!isnan, pts.T)
        @test all(map(==, oldT, newT))
    end
    @testset "all ghosts updated" begin
        prob2 = load(joinpath(@__DIR__, "../../test/test_inputs/full_in.jld2"), "prob")
        for boundary in [:z₂, :x₁, :x₂, :y₁, :y₂, :z₁]
            ind = getproperty(ls.ind, boundary)
            @test all(map(i -> prob.Tᵗ⁻¹[i[2]] != prob2.Tᵗ⁻¹[i[2]], ind))
        end
    end
    @testset "No top or bottom ghosts NaN" begin
        @test !any(map(i -> isnan(prob.Tᵗ⁻¹[i[2]]), ls.ind.z₁))
        @test !any(map(i -> isnan(prob.Tᵗ⁻¹[i[2]]), ls.ind.z₂))
    end
end

"""
$(TYPEDSIGNATURES)

Calculates a temperature for a ghost cell that will give the heat flux density (ϕ⃗, in wm⁻²)
to a node with a temperature of T. `gdist` is the distance between the ghost and real node in
meters, eg. for a z boundary it would be `Δz`.
"""
boundaryTemp(ϕ⃗, T, κ, gdist) = T + ((ϕ⃗ * gdist) / κ)

@testitem "boundaryTemp" begin
    # I don't normally test functions that don't leave the file, but in I've made an exception
    # because I've messed up the maths of this one too many times
    using HSSSimulations, Test
    using .Boundary
    T, κ, gdist = 150, 0.2, 0.01
    @test Boundary.boundaryTemp(0.0, T, κ, gdist) == T
    @test Boundary.boundaryTemp(400, T, κ, gdist) == T + 20
    @test Boundary.boundaryTemp(-400, T, κ, gdist) == T - 20
end
