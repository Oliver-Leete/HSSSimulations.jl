"$(TYPEDEF)"
abstract type AbstractOverheadsBoundary <: AbstractBoundary end

"$(TYPEDSIGNATURES)"
function Types.boundaryHeatTransferRate(T, _, p::AbstractOverheadsBoundary)
    return (
        convectionFlow(T, p.airTemp, p.h) +
        (
            (1 - p.Po) * radiationFlow(T, p.surfaceTemp, p.ε) +
            p.Po * radiationFlow(T, p.overheadTemp, p.ε)
        )
    )
end

"""
$(TYPEDEF)

Boundary for the top surface of a HSS build with no lamp or print carriage movement. Assumes the
heater controller is the same as our HSS machine where It only updates the overhead power every
overheadLayerStep number of layers, and only once on that layer.

# Fields
$(TFIELDS)
"""
struct OverheadsBoundary <: AbstractOverheadsBoundary
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
    "Weighting of overhead heaters vs raditiation loss"
    Po::Float64
end

"$(TYPEDSIGNATURES)"
function OverheadsBoundary(
    pts::AbstractResult,
    cts::AbstractResult,
    prob::Problem{T,Gh,Mp,R,OR,B},
    ls::Types.LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    param = prob.params

    # Overhead update logic
    if ls.layerNum - param.overheadLayerStep >= param.lastUpdatedOverhead
        param.lastUpdatedOverhead = ls.layerNum
        surfaceCurrent = pts.T[ls.ind.z₂[1][1]]
        if surfaceCurrent > (param.surfaceTarget + param.surfaceTol)
            overheadPower = param.overheadPower - param.overheadPowerStep
        elseif surfaceCurrent < (param.surfaceTarget - param.surfaceTol)
            overheadPower = param.overheadPower + param.overheadPowerStep
        else
            overheadPower = param.overheadPower
        end
        param.overheadPower = clamp(overheadPower, 0, param.overheadMaxPower)
        @debug "Overhead Power updated" _group = "hss" surfaceCurrent overheadPower
    end
    overheadTemp = param.overheadHeatupFunc(param.overheadPower, param.overheadTemp, cts)
    param.overheadTemp = overheadTemp

    airTemp = param.airHeat(cts.t)
    surfaceTemp = param.surfaceHeat(cts.t)
    ε = prob.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    @debug "OverheadsBoundary" _group = "hss" cts.tₚ overheadTemp surfaceTemp airTemp
    return OverheadsBoundary(overheadTemp, surfaceTemp, ε, airTemp, h, Po)
end

"""
    loadNoTop(tₗ, skip)

Returns the compleate [`HSSBound.Load`](@ref) struct for a HSS build with no lamp or print carriage
movement. This assumes that a subset of the build is being simulated and the the edge boundaries can
be approximated as symetrical (no heat flow).

Uses [`HSSBound.OverheadsBoundary`](@ref) for the top surface, [`HSSBound.PistonBoundary`](@ref) for
the bottom surface and the default [`Boundary.SymetryBoundary`](@ref) functions for the sides.
"""
function loadOverheads(tₗ, skip)
    return Load(;
        name = "Overheads Only",
        tₗ   = tₗ,
        skip = skip,
        z₁   = PistonBoundary,
        z₂   = OverheadsBoundary,
    )
end

"""
$(TYPEDEF)

Like the [`OverheadsBoundary`](@ref) but it sets the overhead power to 0w (turning it off). Assumes
that once cooling starts it doesn't stop.

# Fields
$(TFIELDS)
"""
struct OverheadsCoolBoundary <: AbstractOverheadsBoundary
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
    "Weighting of overhead heaters vs raditiation loss"
    Po::Float64
end

"$(TYPEDSIGNATURES)"
function OverheadsCoolBoundary(
    pts::AbstractResult,
    cts::AbstractResult,
    prob::Problem{T,Gh,Mp,R,OR,B},
    _::Types.LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    param = prob.params

    if isnan(param.coolStart)
        coolingStart(pts.t, cts.t, prob.params)
    end

    tAir = (cts.t - param.coolStart) + param.airCoolStart
    tSurface = (cts.t - param.coolStart) + param.surfaceCoolStart

    param.overheadTemp =
        overheadTemp = param.overheadHeatupFunc(0.0, param.overheadTemp, cts)

    airTemp = param.airCool(tAir)
    surfaceTemp = param.surfaceCool(tSurface)
    ε = prob.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    @debug "OverheadsCoolBoundary" _group = "hss" overheadTemp tAir tSurface surfaceTemp airTemp h
    return OverheadsCoolBoundary(overheadTemp, surfaceTemp, ε, airTemp, h, Po)
end

"""
$(TYPEDSIGNATURES)

Uses [`HSSBound.OverheadsCoolBoundary`](@ref) and [`HSSBound.PistonCoolBoundary`](@ref) so that
the overhead and piston heaters are turned off. Assumes that once cooling starts it doesn't stop.
"""
function loadCooldown(tₗ, skip)
    return Load(;
        name = "Overheads Off",
        tₗ   = tₗ,
        skip = skip,
        z₁   = PistonCoolBoundary,
        z₂   = OverheadsCoolBoundary,
    )
end
