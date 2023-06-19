"""
$(TYPEDSIGNATURES)

Boundary for the top surface of a HSS build with the print head carriage over the build volume
depositing ink.

# Fields
$(TFIELDS)
"""
struct InkBoundary <: AbstractBoundary
    "Temperatur of overhead heater"
    overheadTemp::Float64
    "Temperatur of machine internal surface"
    surfaceTemp::Float64
    "Black Body Emmissivity"
    ε::Float64
    "Temperature of air above build bed"
    airTemp::Float64
    "Convection coefficient"
    h::Float64
    "Carriage shadow array"
    shadow::Vector{Bool}
    "Weighting of overhead heaters vs raditiation loss"
    Po::Float64
end

"$(TYPEDSIGNATURES)"
function InkBoundary(
    _::AbstractResult,
    cts::AbstractResult,
    G::GVars{T,Gh,Mp,R,OR,B},
    ls::Types.LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    param = G.params

    param.overheadTemp =
        overheadTemp = param.overheadHeatupFunc(param.overheadPower, param.overheadTemp, cts)

    # The position of the righthand side of the carriage (well, the left, but everything is reversed)
    pos = ceil(Int, (param.printCarriageWidth + G.geometry.Y_BUILD) * (1 - cts.tₚ))
    shadowPos = (pos - param.printCarriageWidth, pos)
    shadow = movingObjOverlap(G.geometry, true, shadowPos)

    printDist = pos - G.geometry.Y_BUILD - param.printOffset
    printHeight = (ls.size[3]+1-G.geometry.ΔH):ls.size[3]
    if 0 < printDist <= G.geometry.Y
        G.eᵗ[:, printDist:end, printHeight] .= G.ink.nodes[:, printDist:end, printHeight]
    elseif printDist <= 0
        # As the print is in reverse direction, it is compleate when printDist <= 0
        G.eᵗ[:, :, printHeight] .= G.ink.nodes[:, :, printHeight]
    end

    airTemp = param.airHeat(cts.t)
    surfaceTemp = param.surfaceHeat(cts.t)
    ε = G.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    @debug "InkBoundary" _group = "hss" cts.tₚ overheadTemp surfaceTemp airTemp shadow[ls.ind.iₘ[2]] G.eᵗ[ls.ind.iₘ] printDist
    return InkBoundary(overheadTemp, surfaceTemp, ε, airTemp, h, shadow, Po)
end

"$(TYPEDSIGNATURES)"
function Types.boundaryHeatTransferRate(T, i, p::InkBoundary)
    shadow = p.shadow[i[2]]
    return (
        convectionFlow(T, p.airTemp, p.h) +
        radiationFlow(T, p.surfaceTemp, p.ε) * (shadow || (1 - p.Po)) +
        radiationFlow(T, p.overheadTemp, p.ε) * ¬shadow * p.Po
    )
end

"""
$(TYPEDSIGNATURES)

Returns the compleate [`Types.Load`](@ref) struct for a HSS build with the print head carriage over
the build volume depositing ink. This assumes that a subset of the build is being simulated and the
the edge boundaries can be approximated as symetrical (no heat flow).

Uses [`HSSBound.InkBoundary`](@ref) for the top surface, [`HSSBound.PistonBoundary`](@ref) for the
bottom surface and the default [`Boundary.SymetryBoundary`](@ref) for the sides.
"""
loadInkStroke(tₗ, skip) = Load(;
    name = "Inking",
    tₗ   = tₗ,
    skip = skip,
    z₁   = PistonBoundary,
    z₂   = InkBoundary,
)

# @testitem "loadInkStroke" begin
#     using Test, HSSSimulations, JLD2
#
#     G, ls, pts, cts = load("test/test_inputs/full_in.jld2", "G", "ls", "pts", "cts")
#     ls = HSSSimulations.LoadStep(;
#         load = G.buildLoads[end],
#         time = ls.time,
#         size = ls.size,
#         ind = ls.ind,
#         init = ls.init,
#         name = "ink",
#         layerNum = 12,
#     )
#     cts = Result((G.geometry.X, G.geometry.Y, G.geometry.Z), cts.t, 1.0)
#     G.ink.nodes[:,:,12] .= 1.0
#     HSSSimulations.padWithGhost!(pts, cts, ls, G)
#     @testset "all ink has been laid down" begin
#         @test all(map((x, y) -> (x == y), G.eᵗ[:,:,12], G.ink.nodes[:,:,12]))
#     end
# end
