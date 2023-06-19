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
