```@meta
EditURL = "<unknown>/docs/lit/res_tut.jl"
```

# Tutorial 4: Saving More Results
[![](https://mybinder.org/badge_logo.svg)](<unknown>)
[![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](<unknown>)

```julia
using HSSSimulations
using .Types
using .Res
using .HSSBound
```

## Overview

This tutorial will go over both of the ways to save data from the simulation. One method
saves results for every time step (well, the ones that the results aren't skipped for) of the
simulation. The other, simpler, method saves some results at the end of the simulation.

For this tutorial we will save some of the information about the overhead heaters. The temperature
of the heaters will be saved at every time step. And a list of layers where the power was updated
will be saved (along) with every layer that they're saved for.

## Setting Up the Time Step Results

To store results for each time step we will need to make a new [`AbstractResult`](@ref) type. This
is very similar to the built in [`Result`](@ref) type, with the addition of the `O` field, where
we'll store the overhead heater temperature. This has to be an array of some kind instead of just
a float64 to allow for the value to be mutable (so we can update it once it has been calculated).

```julia
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
```

!!! warning

    As this struct is what stores the data during the simulation, all subtypes **MUST** have the
    `T`, `t` and `tₚ` fields, and if you want to use it with the default material model it will
    also need the `M` and `C` fields.

In addition, we'll also need some constructors for our new type, one empty one that is used in the
simulation code:

```julia
function OverheadResult(geomSize, t, tₚ)
    T = Array{Float64}(undef, geomSize...)
    M = Array{Float64}(undef, geomSize...)
    C = Array{Float64}(undef, geomSize...)
    O = Vector{Float64}(undef, 1)
    return OverheadResult{typeof(T),typeof(O)}(T, M, C, O, t, tₚ)
end
```

And one to create one filled with given values, that we'll use to create our initial conditions
result:

```julia
function OverheadResult(geomSize, Tᵢ, Mᵢ, Cᵢ, t, tₚ)
    T = fill(Tᵢ, geomSize)
    M = fill(Mᵢ, geomSize)
    C = fill(Cᵢ, geomSize)
    O = Vector{Float64}(undef, 1)
    return OverheadResult{typeof(T),typeof(O)}(T, M, C, O, t, tₚ)
end
```

## Recording the Time Step Results

We have the new types ready to store the data, so now we can update some functions to actually
fill them with data. The function we care about is the one that finds the new temperature for the
overhead heaters, which conveniently is just one of the arguments to HSSParams. So we can just
make a function that we'll pass in when calling [`HSSParams`](@ref). This is basically just the
default function, but with the added step `cts.O[1] = oveheadTemp` to save our result.

```julia
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
```

As well as recording the results, we also need to save them. This is done with the
[`Res.loadStepSaver`](@ref) function. We can create a method for this function that uses our
`OverheadResult` type. Although it can't be dispatched on directly, instead we dispatch on a type
from the `StructArrays` package, with our type as its type parameter. This is handily rexported by
the Res module, so we can use it from there.

The [`Res.loadStepSaver`](@ref) function is given a folder of the output file that we can then
save the contents of `loadResults` to. `loadResults` is acts as a struct who's fields are vectors
of the fields of our `OverheadResult` struct. But we can use `stack` to turn the vectors of arrays
into higher dimension arrays before saving them. This will make them the right format to work with
the built in post processing functions.

```julia
function Res.loadStepSaver(
    loadResultsFolder,
    loadResults::Res.StructVector{T},
) where {T<:OverheadResult}
    loadResultsFolder["time"] = loadResults.t
    loadResultsFolder["T"] = stack(loadResults.T)
    loadResultsFolder["M"] = stack(loadResults.M)
    loadResultsFolder["C"] = stack(loadResults.C)
    loadResultsFolder["O"] = stack(loadResults.O)
    return
end
```

Before this function is called, the name of the load has already been saved to the name field, so
we don't have to worry about that here (just don't try and save something else to the name field
here, it will error).

## Saving Results at the End

Compared to saving results for every time step, saving results at the end is much easier. The
downside is that we can only save things that we have access to at the end. And the only things
we have access to at the end are the contents of [`GVars`](@ref). Luckely, there is a placeholder
field in GVars called `otherResults`. To use this we can make an [`AbstractOtherResults`](@ref)
that stores whatever data we want. For this we'll make one that stores some information about the
overhead heater controller.

We'll store a list of layers that caused the overhead heater to update, along with the time of the
update and the new power.

```julia
struct OverheadContRes <: AbstractOtherResults
    layerChanged::Vector{Int}
    timeChanged::Vector{Float64}
    newPower::Vector{Float64}
end
```

To save this data we will use the HSSBound module and make a new version of the constructor for
[`HSSBound.OverheadsBoundary`](@ref) that dispatches on our new type. This is just the same as the
default method, but with three `push!` statements added.

```julia
function HSSBound.OverheadsBoundary(
    pts::AbstractResult,
    cts::AbstractResult,
    G::GVars{T,Gh,Mp,R,OR,B},
    ls::LoadStep,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:OverheadContRes,B<:Any}
    param = G.params
```

Overhead update logic

```julia
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
        param.overheadPower = min(max(overheadPower, 0), param.overheadMaxPower)

        push!(G.otherResults.layerChanged, ls.layerNum)
        push!(G.otherResults.timeChanged, cts.t)
        push!(G.otherResults.newPower, param.overheadPower)

        @debug "Overhead Power updated" _group = "hss" surfaceCurrent overheadPower
    end
    overheadTemp = param.overheadHeatupFunc(param.overheadPower, param.overheadTemp, cts)
    param.overheadTemp = overheadTemp

    airTemp = param.airHeat(cts.t)
    surfaceTemp = param.surfaceHeat(cts.t)
    ε = G.matProp.ε
    h = param.convectionCoef
    Po = param.percentOverhead

    @debug "OverheadsBoundary" _group = "hss" cts.tₚ overheadTemp surfaceTemp airTemp
    return OverheadsBoundary(overheadTemp, surfaceTemp, ε, airTemp, h, Po)
end
```

Also, the other contents of a few of GVars's fields can be customised by us, the `matProp` field
contains the [`AbstractMatProp`](@ref) struct for the simulation, and the `params` field contains
the simulation's [`AbstractProblemParams`](@ref) struct. So if we were making a new material model
then we could use it's struct to store something and then save it all at the end, or the same for
boundary conditions with the parameters struct.

In addition to our `otherResults` struct, we will also save a couple of things that are already
available from the default structs. The maximum melt state is from the [`MatProp`](@ref) struct
(and is normally saved by this function anyway), and `coolStart` is from the [`HSSParams`](@ref)
struct (and is not normally saved).

We'll make a method for [`otherResults`](@ref) that dispatches on our `OverheadContRes` struct.
This method saves `MeltMax` and `CoolStart` to the top level results folder of the output file,
and all of our overhead controller stuff to its own subfolder of the results.

```julia
function Res.otherResults(
    G::Types.GVars{T,Gh,Mp,R,OR,B},
    file,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:OverheadContRes,B<:Any}
    file["MeltMax"] = G.matProp.Mₘ
    file["CoolStart"] = G.params.coolStart
    file["Overheads/layerChanged"] = G.otherResults.layerChanged
    file["Overheads/timeChanged"] = G.otherResults.timeChanged
    file["Overheads/newPower"] = G.otherResults.newPower
    return
end
```

If we didn't want to store any data outside of what is incleded anyway from the material property
or parameters struct, then we could have just made our new `AbstractOtherResults` struct empty and
still used it to dispatch a method for [`Res.otherResults`](@ref).

In fact, as the default [`OtherResults`](@ref) struct is empty and isn't used, you can replace it
with an empty struct of your own to use to dispatch methods of other functions. So if you wanted
to change the behavour of one of the boundaries, or of the material model, but don't want to have
to replace those structs, then just use the `otherResults`. I'll leave it as an exercise for the
reader to rewrite the previous tutorial using this method to make things shorter.

## The Rest of the Setup

From here on it's similar to our other simulations. The one exceptions being the fact that we need
to pass our `overheadHeatupFunc` into [`HSSParams`](@ref) and the fact that we need to pass an
empty `OverheadContRes` into the problem. Creating a [`Geometry`](@ref) first to feed into the
[`HSSParams`](@ref). We'll also change some of the settings of the geometry so that it goes a bit
faster but be less accurate, if you want to try this out on a full simulation feel free to use the
geometry from the full build tutorial.

```julia
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
```

Then the new stuff

```julia
params = HSSParams(geometry; overheadHeatupFunc=overheadHeatupFunc)
otherResults = OverheadContRes(Vector{Int}(), Vector{Float64}(), Vector{Float64}())
```

We also need to make sure to use our new results struct for our initial conditions, this will tell
the simulation to use it for the rest of the time steps.

```julia
init = OverheadResult((geometry.X, geometry.Y, geometry.Z), 25.0, 0.0, 0.0, 0.0, 0)
```

And the rest of it

```julia
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
```

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

