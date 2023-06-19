"""
$(TYPEDEF)

Boundary for the top surface of a HSS build with the print head carriage over the build area but not
on the ink deposition stroke.

# Fields
$(TFIELDS)
"""
struct BlankBoundary <: AbstractBoundary
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
function BlankBoundary(
    _::AbstractResult,
    cts::AbstractResult,
    G::GVars{T,Gh,Mp,R,OR,B},
    ls::LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    param = G.params

    param.overheadTemp =
        overheadTemp = param.overheadHeatupFunc(param.overheadPower, param.overheadTemp, cts)

    # The position of the righthand side of the carriage (well, the left, but everything is reversed)
    pos = ceil(Int, (param.printCarriageWidth + G.geometry.Y_BUILD) * cts.tₚ)
    shadowPos = (pos - param.printCarriageWidth, pos)
    shadow = movingObjOverlap(G.geometry, true, shadowPos)

    airTemp = param.airHeat(cts.t)
    surfaceTemp = param.surfaceHeat(cts.t)
    ε = G.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    @debug "BlankBoundary" _group = "hss" overheadTemp surfaceTemp airTemp shadow[ls.ind.iₘ[2]]
    return BlankBoundary(overheadTemp, surfaceTemp, ε, airTemp, h, shadow, Po)
end

"$(TYPEDSIGNATURES)"
function Types.boundaryHeatTransferRate(T, i, p::BlankBoundary)
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
the build area but not on the ink deposition stroke. This assumes that a subset of the build is
being simulated and the the edge boundaries can be approximated as symetrical (no heat flow).

Uses [`HSSBound.BlankBoundary`](@ref) for the top surface, [`HSSBound.PistonBoundary`](@ref) for the
bottom surface and the default [`Boundary.SymetryBoundary`](@ref) functions for the sides.
"""
function loadBlankStroke(tₗ, skip)
    return Load(;
        name = "No Inking",
        tₗ   = tₗ,
        skip = skip,
        z₁   = PistonBoundary,
        z₂   = BlankBoundary,
    )
end
