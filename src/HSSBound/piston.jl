"$(TYPEDEF)"
abstract type AbstractPistonBoundary <: AbstractBoundary end

"$(TYPEDSIGNATURES)"
Types.boundaryHeatTransferRate(T, _, p::AbstractPistonBoundary) = conductionFlow(T, p.piston, p.h)

"""
$(TYPEDEF)

Boundary for the bottom surface of a HSS build for loads where the heater is turned on. Assumes that
the piston maintains a constant temperature at after the initial heat up.

# Fields
$(TFIELDS)
"""
struct PistonBoundary <: AbstractPistonBoundary
    "Piston temperature"
    piston::Float64
    "Contact conduction coefficient"
    h::Float64
end

"$(TYPEDSIGNATURES)"
function PistonBoundary(
    _::AbstractResult,
    cts::AbstractResult,
    prob::Problem{T,Gh,Mp,R,OR,B},
    _::Types.LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    pistonTemp = prob.params.pistonHeat(cts.t)
    @debug "PistonBoundary" _group = "hss" pistonTemp
    return PistonBoundary(pistonTemp, prob.params.conductionCoef)
end

"""
$(TYPEDEF)

Boundary for the bottom surface of a HSS build for cooldown loads. Assumes that once cooling starts
it doesn't stop.

# Fields
$(TFIELDS)
"""
struct PistonCoolBoundary <: AbstractPistonBoundary
    "Piston temperature"
    piston::Float64
    "Contact conduction coefficient"
    h::Float64
end

"$(TYPEDSIGNATURES)"
function PistonCoolBoundary(
    pts::AbstractResult,
    cts::AbstractResult,
    prob::Problem{T,Gh,Mp,R,OR,B},
    _::Types.LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    if isnan(prob.params.coolStart)
        coolingStart(pts.t, cts.t, prob.params)
    end
    tPiston = (cts.t - prob.params.coolStart) + prob.params.pistonCoolStart
    pistonTemp = prob.params.pistonCool(tPiston)
    @debug "PistonBoundary" _group = "hss" tPiston pistonTemp
    return PistonCoolBoundary(pistonTemp, prob.params.conductionCoef)
end
