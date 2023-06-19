"""
$(TYPEDSIGNATURES)

Returns a vector of heat flux density coefficients representing the lamp, with the same node spacing
as the simulation. The returned vector can be multiplied by the lamp power, in watts, to get a
vector of heat flux densities of the lamp.

# Arguments

  - `lampVector::Vector` : A vector represeting the heat distribution of the lamp in the y axis
  - `lampWidth` : The total width represented by the lamp vector (in the y axis, in nodes).
  - `geometry::Geometry` : The simulation geometry

!!! note

    If the lamp width divided by the length of the lamp vector is not equal to the Δy then linear
    interpolation is used to fill in the values.

!!! warn

    This uses the Δx and Δy node spacings to calculate the area used to convert to heat flux
    density, because of this it is only applicable to the z₁ and z₂ boundaries.
"""
function lampMaker(lampVector::Vector, lampWidth, geometry::Geometry)
    # The all caps version is the width in number of nodes
    # Take a shortcut if the vector is the right length, interpolate the values if not
    if lampWidth == length(lampVector)
        adjustedVector = lampVector
    else
        tmpRange = range(1, lampWidth, length(lampVector))
        interpolation = linear_interpolation(tmpRange, lampVector)
        adjustedVector = [interpolation(i) for i in 1:lampWidth]
    end

    # Divide by the sum of the total weighted array. So if it was expanded to a 2d array the width
    # of the build it would total to 1.
    vector_sum = sum(adjustedVector) * geometry.X_BUILD
    normLampVec = adjustedVector ./ vector_sum

    # Divide by the area of the nodes area on the top surface to convert from a heat flow
    # coefficient to a heat flux coefficient
    area = geometry.Δx * geometry.Δy
    lampq = normLampVec ./ area

    return lampq
end

"""
$(TYPEDSIGNATURES)

Calculates the new temperature of a an overhead heater that has a given power output and is set to a
given power (`powerIn`) values.

# Arguments

  - `powerOut` : A function that takes the temperatu of the heater and returns the power output
  - `overheadHeatCapacity` : The heat capacity of the overhead heater
  - `prevOverheadTemp` : The previous temperature of the overhead heaters
"""
function overheadTempFunc(powerIn, powerOut, overheadHeatCapacity, Δt, prevOverheadTemp)
    powerOut = powerOut(prevOverheadTemp)
    energy = (powerIn - powerOut) * Δt
    ΔT = energy / overheadHeatCapacity
    currOverheadTemp = prevOverheadTemp + ΔT

    return currOverheadTemp
end

"""
$(TYPEDSIGNATURES)

Sets the time that the cooling starts, to be used to calculate how far into the cooling the
simulation is during future time steps.

It also finds how far into the cooling curves of the different components to start based on the
current temperature of that component. If the current temperature is less than any temperature in
the cooling curve it will default to starting at the end of the curve.

This requires the type of `pistonCool`, `airCool` and `surfaceHeat` have methods for `findfirst`
"""
function coolingStart(tₚ, t, params::AbstractProblemParams)
    params.coolStart = t

    pc = params.pistonCool
    pistonOld = params.pistonHeat(tₚ)
    pb = bounds(pc.itp)[1][1]:bounds(pc.itp)[1][2]
    pistonCoolStart = findfirst(x -> pc(x) <= pistonOld, pb)
    params.pistonCoolStart = isnothing(pistonCoolStart) ? 0 : pistonCoolStart - 1

    ac = params.airCool
    airOld = params.airHeat(tₚ)
    ab = bounds(ac.itp)[1][1]:bounds(ac.itp)[1][2]
    airCoolStart = findfirst(x -> ac(x) <= airOld, ab)
    params.airCoolStart = isnothing(airCoolStart) ? 0 : airCoolStart - 1

    sc = params.surfaceCool
    surfaceOld = params.surfaceHeat(tₚ)
    sb = bounds(sc.itp)[1][1]:bounds(sc.itp)[1][2]
    surfaceCoolStart = findfirst(x -> sc(x) <= surfaceOld, sb)
    params.surfaceCoolStart = isnothing(surfaceCoolStart) ? 0 : surfaceCoolStart - 1
    @debug "coolingStart" _group = "hss" t params.coolStart params.pistonCoolStart params.airCoolStart params.surfaceCoolStart
end

"""
An example structure to hold the boundary condition constants used in the example boundary condition
functions. T1 must be a function that has the same signature as [`overheadTempFunc`](@ref)

# Fields
$(TFIELDS)
"""
mutable struct HSSParams{T1,T2,T3,T4,T5,T6,F1,F2} <: AbstractProblemParams
    "Parameter set name"
    const name::String

    "Function to find piston tempeature during heating"
    const pistonHeat::T1
    "Function to find piston tempeature during cooling"
    const pistonCool::T2
    "Contact conduction coefficient of piston to powder bed"
    const conductionCoef::Float64

    "Function to find air tempeature during heating"
    const airHeat::T3
    "Function to find air tempeature during cooling"
    const airCool::T4
    "Convection coefficient of piston to powder bed"
    const convectionCoef::Float64
    "Function to find the machine's internal surface tempeature during heating"
    const surfaceHeat::T5
    "Function to find the machine's internal surface tempeature during cooling"
    const surfaceCool::T6
    "Function to find temperature of newly deposited powder"
    const powderTemp::F2

    "Lamp distribution vector during sinter stroke"
    const sinterLamp::Vector{Float64}
    "Lamp distribution vector during recoat stroke"
    const recoatLamp::Vector{Float64}
    "Width of the lamp's irradiation area in nodes"
    const lampWidth::Int
    "Lamp offset from sinter carriage right side in nodes"
    const lampOffset::Int
    "Recoat/Sinter carriage width in nodes"
    const carriageWidth::Int
    "Print head carriage width in nodes"
    const printCarriageWidth::Int
    "Print head offset from right side of print head carriage in nodes"
    const printOffset::Int
    "Recoater position offset from right side of recoater carriage in nodes"
    const recoatOffset::Int

    "Target temperature of top surface of powder bed"
    const surfaceTarget::Float64
    "Tolerance of target temperature of top surface of powder bed"
    const surfaceTol::Float64
    """Function to find overhead heater temp, takes the current power, current overhead temperature
    and the current time step `result` struct, should return the new overhead heater temperature"""
    const overheadHeatupFunc::F1
    "How often to check if target temperature has been met"
    const overheadLayerStep::Int
    "How much to step overhead power if target not met"
    const overheadPowerStep::Float64
    "Maximum power of the overheads"
    const overheadMaxPower::Float64
    "Weighting of overhead heaters to radiation loss"
    const percentOverhead::Float64
    "Current power input of overhead heaters"
    overheadPower::Float64
    "Current temperature of overhead heaters"
    overheadTemp::Float64
    "The last layer the overheads were updated on"
    lastUpdatedOverhead::Int
    "The time at the start of cooling loads"
    coolStart::Float64
    "The offset time if the piston wasn't at max temp at start of cooling"
    pistonCoolStart::Float64
    "The offset time if the air wasn't at max temp at start of cooling"
    airCoolStart::Float64
    "The offset time if the machine's internal suraface wasn't at max temp at start of cooling"
    surfaceCoolStart::Float64
end

"""
$(TYPEDSIGNATURES)

The `geometry` (of type [`Geometry`](@ref)) should be the same one used for the simulation.
If the piston target temperature is chaneged then the piston path will need to be changed to curves
that will match the target temperature. Same if the preheat bed is thicker than the normal ≈3 mm.
"""
function HSSParams(
    geometry::Geometry;
    name                 = "HSS example problem boundary",
    pistonPath           = joinpath(artifact"HSS", "../../data/HSS_Piston.jld2"),
    airPath              = joinpath(artifact"HSS", "../../data/HSS_Surface.jld2"),
    surfacePath          = joinpath(artifact"HSS", "../../data/HSS_Air.jld2"),
    conductionCoef       = 7500.0,
    lampVector           = [0.0, 1, 2, 2, 2, 2, 2, 1, 0],
    lampWidth            = 0.100,
    lampOffset           = 0.175,
    carriageWidth        = 0.275,
    recoatOffset         = 0.045,
    printCarriageWidth   = 0.180,
    printOffset          = 0.110,
    surfaceTarget        = 160.0,
    surfaceTol           = 1.0,
    overheadLayerStep    = 3,
    overheadPercentStep  = 1.0,
    overheadTemp         = 25.0,
    overheadPower        = 0.6 * 300,
    overheadPowerOut     = x -> (0.596x - 12.2),
    overheadHeatCapacity = 118.923,
    overheadMaxPower     = 300.0,
    convectionCoef       = 4.0,
    sinterPower          = 2000.0,
    recoatPower          = 0.0,
    lastUpdatedOverhead  = 0,
    percentOverhead      = 0.2125,
    powderTempDelta      = 25,
    overheadHeatupFunc   = function (powerIn::Float64, prevOverheadTemp::Float64, _)
        return overheadTempFunc(
        powerIn,
        overheadPowerOut,
        overheadHeatCapacity,
        geometry.Δt,
        prevOverheadTemp
    )
    end,
)
    overheadPowerStep = 300 * (overheadPercentStep / 100)

    airHeatTime = jldopen(airPath)["Heat Time"]
    airHeatTemp = jldopen(airPath)["Heat Temp"]
    airCoolTime = jldopen(airPath)["Cool Time"]
    airCoolTemp = jldopen(airPath)["Cool Temp"]
    airHeat = linear_interpolation(airHeatTime, airHeatTemp; extrapolation_bc=Flat())
    airCool = linear_interpolation(airCoolTime, airCoolTemp; extrapolation_bc=Flat())

    surfaceHeatTime = jldopen(surfacePath)["Heat Time"]
    surfaceHeatTemp = jldopen(surfacePath)["Heat Temp"]
    surfaceCoolTime = jldopen(surfacePath)["Cool Time"]
    surfaceCoolTemp = jldopen(surfacePath)["Cool Temp"]
    surfaceHeat = linear_interpolation(surfaceHeatTime, surfaceHeatTemp; extrapolation_bc=Flat())
    surfaceCool = linear_interpolation(surfaceCoolTime, surfaceCoolTemp; extrapolation_bc=Flat())

    pistonHeatTime = jldopen(pistonPath)["Heat Time"]
    pistonHeatTemp = jldopen(pistonPath)["Heat Temp"]
    pistonCoolTime = jldopen(pistonPath)["Cool Time"]
    pistonCoolTemp = jldopen(pistonPath)["Cool Temp"]
    pistonHeat = linear_interpolation(pistonHeatTime, pistonHeatTemp; extrapolation_bc=Flat())
    pistonCool = linear_interpolation(pistonCoolTime, pistonCoolTemp; extrapolation_bc=Flat())

    lampOffset = ceil(Int, lampOffset / geometry.Δy)
    lampWidth = ceil(Int, lampWidth / geometry.Δy)
    lampSpot = lampMaker(lampVector, lampWidth, geometry)
    sinterLamp = sinterPower .* lampSpot
    recoatLamp = recoatPower .* lampSpot

    carriageWidth = ceil(Int, carriageWidth / geometry.Δy)
    recoatOffset = ceil(Int, recoatOffset / geometry.Δy)
    printCarriageWidth = ceil(Int, printCarriageWidth / geometry.Δy)
    printOffset = ceil(Int, printOffset / geometry.Δy)

    powderTemp(t) = surfaceHeat(t) + powderTempDelta

    return HSSParams(
        name,
        pistonHeat,
        pistonCool,
        conductionCoef,
        airHeat,
        airCool,
        convectionCoef,
        surfaceHeat,
        surfaceCool,
        powderTemp,
        sinterLamp,
        recoatLamp,
        lampWidth,
        lampOffset,
        carriageWidth,
        printCarriageWidth,
        printOffset,
        recoatOffset,
        surfaceTarget,
        surfaceTol,
        overheadHeatupFunc,
        overheadLayerStep,
        overheadPowerStep,
        overheadMaxPower,
        percentOverhead,
        overheadPower,
        overheadTemp,
        lastUpdatedOverhead,
        NaN,
        NaN,
        NaN,
        NaN,
    )
end

"""
$(TYPEDSIGNATURES)

Returns a list of loads for the preheat, build and cooldown loadsets for a default build for the HSS
example. The same `skip` is used for all load steps (See [Why We Skip Some Results](@ref) for more
information on `skip`).

```jldoctest
julia> HSSLoads(10, Geometry((1,1,1),1,1); nrPreheat=5, lenPreheat=60.0, nrCool=5, lenCool=60.0, sinterSpeed=0.160)
3-element Vector{AbstractLoadSet}:
   name : Preheat
  loads
----------------------

  Name: Overheads Only
  For 5 loads



   name : Layer
  finishLayer : 0
  loads
----------------------

  Name: Overheads Only
  Name: Sintering
  Name: Overheads Only
  Name: Recoating
  Name: Overheads Only
  Name: No Inking
  Name: Overheads Only
  Name: Inking



   name : Cooldown
  loads
----------------------

  Name: Overheads Off
  For 5 loads
```
"""
function HSSLoads(
    skip, geometry;
    nrPreheat=5,
    lenPreheat=60.0,
    nrCool=5,
    lenCool=60.0,
    sinterSpeed=0.160,
    lcAndBedWidth=0.605,
)
    sinterDuration = lcAndBedWidth / sinterSpeed
    return [
        FixedLoadSet("Preheat", [
            loadOverheads(lenPreheat, skip)
            for _ in 1:nrPreheat
        ]),
        LayerLoadSet(
            "Layer",
            geometry.Nₗ,
            [
                loadOverheads(4.84, skip),
                loadSinterStroke(sinterDuration, skip),
                loadOverheads(1.6, skip),
                loadRecoatStroke(7.92, skip),
                loadOverheads(6.72, skip),
                loadBlankStroke(1.28, skip),
                loadOverheads(1.2, skip),
                loadInkStroke(1.28, skip),
            ],
        ),
        FixedLoadSet("Cooldown", [
            loadCooldown(lenCool, skip)
            for _ in 1:nrCool
        ]),
    ]
end
