"""
$(TYPEDEF)

Boundary for the top surface of a HSS build with the recoat/lamp carriage over the build area, the
lamp set to recoat power and new powder being deposited.

# Fields
$(TFIELDS)
"""
struct RecoatBoundary <: AbstractBoundary
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
function RecoatBoundary(
    pts::AbstractResult,
    cts::AbstractResult,
    G::GVars{T,Gh,Mp,R,OR,B},
    ls::LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    param = G.params

    param.overheadTemp =
        overheadTemp = param.overheadHeatupFunc(param.overheadPower, param.overheadTemp, cts)

    airTemp = param.airHeat(cts.t)
    surfaceTemp = param.surfaceHeat(cts.t)
    eₗ = G.eᵗ
    ε = G.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    # The position of the righthand side of the carriage (well, the left, but everything is reversed)
    pos = ceil(Int, (param.carriageWidth + G.geometry.Y_BUILD) * cts.tₚ)
    shadowPos = (pos - param.carriageWidth, pos)
    shadow = movingObjOverlap(G.geometry, true, shadowPos)

    recoatDist = pos - param.recoatOffset
    if G.geometry.Y_OFFSET < recoatDist <= G.geometry.Y_OFFSET + G.geometry.Y
        recoatDist = recoatDist - G.geometry.Y_OFFSET
        recoating!(pts, cts, G, ls, recoatDist, param.powderTemp(cts.t))
    elseif recoatDist > G.geometry.Y_OFFSET + G.geometry.Y
        recoatDist = G.geometry.Y
        recoating!(pts, cts, G, ls, recoatDist, param.powderTemp(cts.t))
    end
    lampPos = pos - param.lampOffset
    lamp = movingObjOverlap(G.geometry, param.recoatLamp, lampPos)

    @debug "RecoatBoundary" _group = "hss" overheadTemp surfaceTemp airTemp lamp[ls.ind.iₘ[2]] shadow[ls.ind.iₘ[2]]
    return RecoatBoundary(overheadTemp, surfaceTemp, eₗ, ε, airTemp, h, lamp, shadow, Po)
end

"$(TYPEDSIGNATURES)"
function Types.boundaryHeatTransferRate(T, i, p::RecoatBoundary)
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

Returns the compleate [`Types.Load`](@ref) struct for a HSS build with the recoat/lamp carriage over
the build area, the lamp set to recoat power and new powder being deposited movement. This assumes
that a subset of the build is being simulated and the the edge boundaries can be approximated as
symetrical (no heat flow).

Uses [`HSSBound.RecoatBoundary`](@ref) for the top surface, [`HSSBound.PistonBoundary`](@ref) for the bottom
surface and the default [`Boundary.SymetryBoundary`](@ref) functions for the sides.
"""
function loadRecoatStroke(tₗ, skip)
    return Load(;
        name = "Recoating",
        tₗ   = tₗ,
        skip = skip,
        z₁   = PistonBoundary,
        z₂   = RecoatBoundary,
    )
end
