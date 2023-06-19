"""
$(TYPEDEF)

Boundary for the top surface of a HSS build for when the recoat/lamp carriage is over the build bed
and the lamp is set to sinter power.

# Fields
$(TFIELDS)
"""
struct SinterBoundary <: AbstractBoundary
    "Temperatur of overhead heater"
    overheadTemp::Float64
    "Temperatur of machine internal surface"
    surfaceTemp::Float64
    "Net absorbtivity relative to lamp"
    eₗ::Array{Float64,3}
    "Black Body Emmissivity"
    ε::Float64
    "Temperature of air above build bed"
    airTemp::Float64
    "Convection coefficient"
    h::Float64
    "Sinter lamp array"
    lamp::Vector{Float64}
    "Carriage shadow array"
    shadow::Vector{Bool}
    "Weighting of overhead heaters vs raditiation loss"
    Po::Float64
end

"$(TYPEDSIGNATURES)"
function SinterBoundary(
    _::AbstractResult,
    cts::AbstractResult,
    G::GVars{T,Gh,Mp,R,OR,B},
    ls::LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    param = G.params

    param.overheadTemp =
        overheadTemp = param.overheadHeatupFunc(param.overheadPower, param.overheadTemp, cts)

    airTemp = param.airHeat(cts.t)
    surfaceTemp = param.surfaceHeat(cts.t)
    e = G.eᵗ
    ε = G.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    # The position of the righthand side of the carriage (well, the left, but everything is reversed)
    pos = ceil(Int, (param.carriageWidth + G.geometry.Y_BUILD) * (1 - cts.tₚ))
    shadowPos = (pos - param.carriageWidth, pos)
    shadow = movingObjOverlap(G.geometry, true, shadowPos)

    lampPos = pos - param.lampOffset
    lamp = movingObjOverlap(G.geometry, param.sinterLamp, lampPos)

    @debug "SinterBoundary" _group = "hss" overheadTemp surfaceTemp airTemp lamp[ls.ind.iₘ[2]] shadow[ls.ind.iₘ[2]]
    return SinterBoundary(overheadTemp, surfaceTemp, e, ε, airTemp, h, lamp, shadow, Po)
end

"$(TYPEDSIGNATURES)"
function Types.boundaryHeatTransferRate(T, i, p::SinterBoundary)
    shadow = p.shadow[i[2]]
    lamp = p.lamp[i[2]]
    eₗ = p.eₗ[i]
    return (
        convectionFlow(T, p.airTemp, p.h) +
        radiationFlow(T, p.surfaceTemp, p.ε) * (shadow || (1 - p.Po)) +
        radiationFlow(T, p.overheadTemp, p.ε) * ¬shadow * p.Po +
        lamp * eₗ
    )
end

"""
$(TYPEDSIGNATURES)

Returns the compleate [`Types.Load`](@ref) struct for a HSS build with recoat/lamp carriage over
the build and the recoat lamp set to sinter power. This assumes that a subset of the build is being
simulated and the the edge boundaries can be approximated as symetrical (no heat flow).

Uses [`HSSBound.SinterBoundary`](@ref) for the top surface, [`HSSBound.PistonBoundary`](@ref) for
the bottom surface and the default [`Boundary.SymetryBoundary`](@ref) for the sides.
"""
function loadSinterStroke(tₗ, skip)
    return Load(;
        name = "Sintering",
        tₗ   = tₗ,
        skip = skip,
        z₁   = PistonBoundary,
        z₂   = SinterBoundary,
    )
end
