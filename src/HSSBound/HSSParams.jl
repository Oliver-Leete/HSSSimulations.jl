"""
$(TYPEDEF)

The parameter struct for a standard HSS build. This is intended to proved the required parameters
for the load sets produced by [`HSSLoads`](@ref).

See [`HSSParams`](@ref HSSParams(::Geometry;)) for the default constructor.

!!! note

    If the fields below are not documented correctly in whatever method you are using to view this
    documentation, try looking directly at the source code.

# Fields
$(TYPEDFIELDS)
"""
mutable struct HSSParams{T1,T2,T3,T4,T5,T6,T7,T8} <: AbstractProblemParams
    "Parameter set name, only used for user reference"
    const name::String

    """Function to find piston tempeature during heating. Takes the current time since the start of
    the build in seconds and returns the piston temperature in °C"""
    const pistonHeat::T1
    """Function to find piston tempeature during cooling. Takes the current time since the start of
    the cooldown phase of the build, in seconds, and returns the piston temperature in °C"""
    const pistonCool::T2
    "Contact conduction coefficient of piston to powder bed, in W/m²k"
    const conductionCoef::Float64

    """Function to find air tempeature during heating. Takes the current time since the start of the
    build in seconds and returns the air temperature in °C"""
    const airHeat::T3
    """Function to find air tempeature during cooling. Takes the current time since the start of the
    cooldown phase of the build, in seconds, and returns the air temperature in °C"""
    const airCool::T4
    "Convection coefficient of piston to powder bed, in W/m²k"
    const convectionCoef::Float64
    """Function to find machine's surface tempeature during heating. Takes the current time since
    the start of the build in seconds and returns the machine's surface temperature in °C"""
    const surfaceHeat::T5
    """Function to find machine's surface tempeature during cooling. Takes the current time since
    the start of the cooldown phase of the build, in seconds, and returns the machine's surface
    temperature in °C"""
    const surfaceCool::T6
    """Function to find newly deposited powdertempeature during heating. Takes the current time
    since the start of the build in seconds and returns the temperature of newly deposited powder in
    °C"""
    const powderTemp::T8

    "Lamp distribution vector during sinter stroke, in W/m²"
    const sinterLamp::Vector{Float64}
    "Lamp distribution vector during recoat stroke, in W/m²"
    const recoatLamp::Vector{Float64}
    "Width of the lamp's irradiation area in # of nodes"
    const lampWidth::Int
    "Lamp offset from sinter carriage right side, in # of nodes"
    const lampOffset::Int
    "Recoat/Sinter carriage width, in # of nodes"
    const carriageWidth::Int
    "Print head carriage width, in # of nodes"
    const printCarriageWidth::Int
    "Print head offset from right side of print head carriage, in # of nodes"
    const printOffset::Int
    "Recoater position offset from right side of recoater carriage, in # of nodes"
    const recoatOffset::Int

    "Target temperature of top surface of powder bed, in °C"
    const surfaceTarget::Float64
    "Tolerance of target temperature of top surface of powder bed, in °C"
    const surfaceTol::Float64
    """Function to find overhead heater temp, takes the current power in watts and the current
    overhead heater temperature in °C and should return the new overhead heater temperature in
    °C"""
    const overheadHeatupFunc::T7
    "How often to check if target temperature has been met, in number of layers"
    const overheadLayerStep::Int
    "How much to step overhead power if target not met, in % of maximum power"
    const overheadPowerStep::Float64
    "Maximum power of the overheads, in watts"
    const overheadMaxPower::Float64
    "Weighting of overhead heaters to radiation loss"
    const percentOverhead::Float64
    "Current power input of overhead heaters, in watts"
    overheadPower::Float64
    "Current temperature of overhead heaters, in °C"
    overheadTemp::Float64
    "The last layer the overheads were updated on"
    lastUpdatedOverhead::Int
    "The time at the start of cooling loads, in seconds since the start of the build"
    coolStart::Float64
    """The offset time if the piston wasn't at max temp at start of cooling, in seconds after the
    start of the piston cooldown curve"""
    pistonCoolStart::Float64
    """The offset time if the air wasn't at max temp at start of cooling, in seconds after the start
    of the air cooldown curve"""
    airCoolStart::Float64
    """The offset time if the machine's internal suraface wasn't at max temp at start of cooling, in
    seconds after the start of the surface cooldown curve"""
    surfaceCoolStart::Float64
end

"""
    $(FUNCTIONNAME)(Geometry; kwargs...) -> HSSParams

The `geometry` (of type [`Geometry`](@ref)) should be the same one used for the simulation. If the
piston target temperature is chaneged then the piston path will need to be changed to curves that
will match the target temperature. The same applies if the preheat bed is thicker than the normal
≈3 mm.

This is intended to proved the required parameters for the load sets produced by [`HSSLoads`](@ref).

See [`HSSParams`](@ref) for information on the fields of the created struct.

# Arguments

  - `name = "HSS example problem boundary"`: A name for the parameter set, only used for user
    reference.

  - `pistonPath = joinpath(artifact"HSS", "HSS_Piston.jld2")`: Where to find the piston heat up and
    cool down curves data file.
  - `airPath = joinpath(artifact"HSS", "HSS_Surface.jld2")`: Where to find the machine's internal
    surface heat up and cool down curves data file.
  - `surfacePath = joinpath(artifact"HSS", "HSS_Air.jld2")`: Where to find the machine's internal
    air heat up and cool down curves data file.
  - `conductionCoef = 7500.0`: The conduction coefficient of the top surface of the bed, in W/m²k.
  - `lampVector = [0.0, 1, 2, 2, 2, 2, 2, 1, 0]`: The y-axis distribution of the lamp power, see
    [`lampMaker`](@ref) for more details.
  - `lampWidth = 0.100`: The width of the lamps power distribution, in meters.
  - `lampOffset = 0.175`: The distance between the left edge of the lamp carriage and th left edge
    of the lamp's distribution, in meters.
  - `carriageWidth = 0.275`: The width of the lamp/recoater carriage, in meters.
  - `recoatOffset = 0.045`: The offset between the left edge of the recoater carriage and the left
    edge of the recoater, in meters.
  - `printCarriageWidth = 0.180`: The width of the print head carriage, in meters.
  - `printOffset = 0.110`: The offset between the left edge of the print head carriage and the left
    edge of the print nozzles.
  - `surfaceTarget = 160.0`: The target temperature of the top surface of the powder bed. Used to
    control the overhead heaters, in °C.
  - `surfaceTol = 1.0`: The tolerance of the bed surface temperature when compared to the target
    temperature, in °C.
  - `overheadLayerStep = 3`: How often, in number of layers, to update the overhead power based on
    the bed surface temperature.
  - `overheadPercentStep = 1.0`: How big of a step in overhead power to make each time they are
    updated, in % of total power.
  - `overheadTemp = 25.0`: The starting temperature of the overhead heaters themselves, in °C.
  - `overheadPower = 0.6 * 300`: The starting input power of the overhead heaters, in watts.
  - `overheadPowerOut = T -> (0.596T - 12.2)`: A function that takes the current overhead heater
    temperature and returns the output power of the heater.
  - `overheadHeatCapacity = 118.923`: The heat capacity of the overhead heaters, in J/K.
  - `overheadMaxPower = 300.0`: The maximum input power of the overhead heaters.
  - `convectionCoef = 4.0`: The convection coefficient of the top surface of the bed, in W/m²k.
  - `sinterPower = 2000.0`: The output power of the sinter lamp during the sinter stroke.
  - `recoatPower = 0.0`: The output power of the sinter lamp during the recoat stroke.
  - `lastUpdatedOverhead = 0`: The last layer the overhead heaters were updated on.
  - `percentOverhead = 0.2125`: The percentage of the surfaces that the top surface of the powder
    bed is exposed to that is the overhead heaters, as opposed to the other internal surfaces of the
    machine.
  - `powderTempDelta = 25`: The difference between the surface temperature of the machine and the
    temperature of the powder being deposited.
  - `overheadHeatupFunc`: A function that takes an input power and a previous overhead heater temperature
    and returns the temperature for the overhead heaters for the next time step. This uses
    [`HSSBound.overheadTempFunc`](@ref) by default, using the function shown below:

```julia
overheadHeatupFunc = function (powerIn::Float64, prevOverheadTemp::Float64, _)
    return overheadTempFunc(
        powerIn,
        overheadPowerOut,
        overheadHeatCapacity,
        geometry.Δt,
        prevOverheadTemp,
    )
end
```
"""
function HSSParams(
    geometry::Geometry;
    name                 = "HSS example problem boundary",
    pistonPath           = joinpath(artifact"HSS", "HSS_Piston.jld2"),
    airPath              = joinpath(artifact"HSS", "HSS_Surface.jld2"),
    surfacePath          = joinpath(artifact"HSS", "HSS_Air.jld2"),
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
    overheadPowerOut     = T -> (0.596T - 12.2),
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
