"""
$(TYPEDSIGNATURES)

Solves a timestep by calculating new material propeties, setting ghost node boundary conditions,
using an explicit finited difference method and then conditionally recoating the poweder (if the
load specifies). The results are stored in the Results struct cr that is passed into the function.

# Arguments

  - `cts` : The struct that will be used to store the results from this solver.
  - `pts` : The results struct with the results from the previous step.
"""
function timeSolver!(
    cts::AbstractResult,
    pts::AbstractResult,
    ls::Types.LoadStep,
    prob::Problem,
)
    @debug "Starting timestep t=$(cts.t)" _group = "core"
    calcMatProps!(pts, cts, prob, ls.ind.iᵣ)
    Boundary.padWithGhost!(pts, cts, ls, prob)
    fdmSolver!(cts, ls.ind.iᵣ, prob)
    @debug "FDM solver" _group = "solver" cts.T[ls.ind.iₘ]
    nanfiller!(cts, ls.ind.iᵢ)
    return
end

@testitem "timeSolver!" begin
    using Test, HSSSimulations, JLD2
    prob, ls, pts, cts = load(joinpath(@__DIR__, "../../test/test_inputs/full_in.jld2"),
        "G", "ls", "pts", "cts")
    Solver.timeSolver!(cts, pts, ls, prob)
    @testset "Temperature changes everywhere" begin
        @test all(
            map(!=, filter(!isnan, pts.T), filter(!isnan, cts.T)),
        )
    end
end

"""
$(TYPEDSIGNATURES)

Uses the explicit time step finite difference heat form of the heat equation to calculate the new
results using ghost cell boundary conditions.

In simple terms this takes the avarage for all nodes for the one around the one being calculated
(from the previous time step), and uses the difference between that and the temperature of the
current node (for the previous time step) multiplied by the fourier number `Fo` to calculate the
temperature of that node for the current timestep. This is done for all nodes. As ghost nodes are
used, this function is the same for all nodes and doesn't need special logic for boundary nodes.
"""
function fdmSolver!(cts, indᵣ, p)
    Threads.@threads for index in indᵣ
        u, v, w = Tuple(index)
        cts.T[index] =
            p.Fx[index] * (p.Tᵗ⁻¹[u-1, v, w] + p.Tᵗ⁻¹[u+1, v, w]) +
            p.Fy[index] * (p.Tᵗ⁻¹[u, v-1, w] + p.Tᵗ⁻¹[u, v+1, w]) +
            p.Fz[index] * (p.Tᵗ⁻¹[u, v, w-1] + p.Tᵗ⁻¹[u, v, w+1]) +
            p.Tᵗ⁻¹[u, v, w] * (1 - (2 * p.Fx[index] + 2 * p.Fy[index] + 2 * p.Fz[index]))
    end
end

"""
$(TYPEDSIGNATURES)

Fills non real cells with NaNs instead of the undef value there currently. Using NaN instead of zero
both allows for a check to see if the cell has been initialised and makes them not show up in plots.

This needs to be called on all loads (not just recoat loads) as on the loads before recoat there are
still imaginary nodes that need filling (for pretty plotting).
"""
nanfiller!(cts, indᵢ) = Threads.@threads for i in indᵢ
    cts.T[i] = NaN
    cts.M[i] = NaN
    cts.C[i] = NaN
end
