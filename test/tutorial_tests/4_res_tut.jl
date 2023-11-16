using HSSSimulations
using .Types
using .Results
using .HSSBound

struct OverheadResult{P<:AbstractArray,V<:AbstractArray} <: AbstractResult
    "Temperature"
    T::P
    "Melt state"
    M::P
    "Consolidation state"
    C::P
    "Overhead Heater Temperature"
    O::V
    "Time of timestep"
    t::Float64
    "The progress through the load step (0=start, 1=end)"
    tₚ::Float64
end

function OverheadResult(geomSize, t, tₚ)
    T = Array{Float64}(undef, geomSize...)
    M = Array{Float64}(undef, geomSize...)
    C = Array{Float64}(undef, geomSize...)
    O = Vector{Float64}(undef, 1)
    return OverheadResult{typeof(T),typeof(O)}(T, M, C, O, t, tₚ)
end

function OverheadResult(geomSize, Tᵢ, Mᵢ, Cᵢ, t, tₚ)
    T = fill(Tᵢ, geomSize)
    M = fill(Mᵢ, geomSize)
    C = fill(Cᵢ, geomSize)
    O = Vector{Float64}(undef, 1)
    return OverheadResult{typeof(T),typeof(O)}(T, M, C, O, t, tₚ)
end

function overheadHeatupFunc(powerIn::Float64, prevOverheadTemp::Float64, cts)
    overheadTemp = HSSBound.overheadTempFunc(
        powerIn,
        x -> (0.596x - 12.2),
        118.923,
        geometry.Δt,
        prevOverheadTemp,
    )
    cts.O[1] = overheadTemp
    return overheadTemp
end

function Results.loadStepSaver(
    loadResultsFolder,
    loadResults::Results.StructVector{T},
) where {T<:OverheadResult}
    loadResultsFolder["time"] = loadResults.t
    loadResultsFolder["T"] = stack(loadResults.T)
    loadResultsFolder["M"] = stack(loadResults.M)
    loadResultsFolder["C"] = stack(loadResults.C)
    loadResultsFolder["O"] = stack(loadResults.O)
    return
end

struct OverheadContRes <: AbstractOtherResults
    layerChanged::Vector{Int}
    timeChanged::Vector{Float64}
    newPower::Vector{Float64}
end

function HSSBound.OverheadsBoundary(
    pts::AbstractResult,
    cts::AbstractResult,
    prob::Problem{T,Gh,Mp,R,OR,B},
    ls::Types.LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:OverheadContRes,B<:Any}
    param = prob.params

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

        push!(prob.otherResults.layerChanged, ls.layerNum)
        push!(prob.otherResults.timeChanged, cts.t)
        push!(prob.otherResults.newPower, param.overheadPower)

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

function Results.otherResults(
    prob::Types.Problem{T,Gh,Mp,R,OR,B},
    file,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:OverheadContRes,B<:Any}
    file["MeltMax"] = prob.matProp.Mₘ
    file["CoolStart"] = prob.params.coolStart
    file["Overheads/layerChanged"] = prob.otherResults.layerChanged
    file["Overheads/timeChanged"] = prob.otherResults.timeChanged
    file["Overheads/newPower"] = prob.otherResults.newPower
    return
end

geometry = Geometry(
    (0.016, 0.016, 0.0122),
    0.001,
    1e-2;
    Δz=0.003 / 30,
    Δh=0.0001,
    offset=(0.0925, 0.1425),
    buildSize=(0.200, 0.300),
    name="30 layers preheat, 50 pre square pad layers 32 layer thich square and 10 post square padding layers",
)

params = HSSParams(geometry; overheadHeatupFunc=overheadHeatupFunc)
otherResults = OverheadContRes(Vector{Int}(), Vector{Float64}(), Vector{Float64}())

init = OverheadResult((geometry.X, geometry.Y, geometry.Z), 25.0, 0.0, 0.0, 0.0, 0)

loadSets = HSSLoads(4, geometry; nrPreheat=90, lenPreheat=10.0, nrCool=90, lenCool=10.0)
material = PA2200(geometry)

initialLayer = 30

inkArray = fill(material.eₚ, (geometry.X, geometry.Y, geometry.Z))
inkArray[5:end-4, 5:end-4, 60:end-10] .= material.eᵢ
ink = Ink(inkArray, "Sample square")

file = "results_tutorial.jld2"
description = "A simulation to test out saving overhead heater results"

problem = Problem(;
    geometry=geometry,
    matProp=material,
    params=params,
    loadSets=loadSets,
    init=init,
    initLay=initialLayer,
    ink=ink,
    file=file,
    otherResults=otherResults,
    description=description,
)

resultFile, finalResults = problemSolver(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
