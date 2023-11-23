"""
$(TYPEDSIGNATURES)

Boundary for the top surface of a HSS build with the print head carriage over the build volume
depositing ink.

# Fields
$(TYPEDFIELDS)
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
    prob::Problem{T,Gh,Mp,R,OR,B},
    ls::Types.LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    param = prob.params

    param.overheadTemp =
        overheadTemp = param.overheadHeatupFunc(param.overheadPower, param.overheadTemp, cts)

    # The position of the righthand side of the carriage (well, the left, but everything is reversed)
    pos = ceil(Int, (param.printCarriageWidth + prob.geometry.Y_BUILD) * (1 - cts.tₚ))
    shadowPos = (pos - param.printCarriageWidth, pos)
    shadow = movingObjOverlap(prob.geometry, true, shadowPos)

    printDist = pos - prob.geometry.Y_BUILD - param.printOffset
    printHeight = (ls.size[3]+1-prob.geometry.ΔH):ls.size[3]
    if 0 < printDist <= prob.geometry.Y
        prob.eᵗ[:, printDist:end, printHeight] .= prob.ink.nodes[:, printDist:end, printHeight]
    elseif printDist <= 0
        # As the print is in reverse direction, it is compleate when printDist <= 0
        prob.eᵗ[:, :, printHeight] .= prob.ink.nodes[:, :, printHeight]
    end

    airTemp = param.airHeat(cts.t)
    surfaceTemp = param.surfaceHeat(cts.t)
    ε = prob.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    @debug "InkBoundary" _group = "hss" cts.tₚ overheadTemp surfaceTemp airTemp shadow[ls.ind.iₘ[2]] prob.eᵗ[ls.ind.iₘ] printDist
    return InkBoundary(overheadTemp, surfaceTemp, ε, airTemp, h, shadow, Po)
end

"$(TYPEDSIGNATURES)"
function Types.boundaryHeatTransferRate(T, i, p::InkBoundary)
    shadow = p.shadow[i[2]]
    return (
        convectionFlow(T, p.airTemp, p.h) +
        radiationFlow(T, p.surfaceTemp, p.ε) * (shadow || (1 - p.Po)) +
        radiationFlow(T, p.overheadTemp, p.ε) * !shadow * p.Po
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
