# Main API

```@meta
DocTestSetup = quote
    using HSSSimulations
end
```

This page covers the basic API used for running simple simulations. Each
section will also link to the relevant advanced API that can be used to further
customise the behaviour of that part of the simulation. See [Advanced API
Introduction](@ref) for more information on how to use the advanced API.

## Solver

```@docs
problemSolver
Problem(; kwargs...)
```

## Simulation Geometry

```@docs
Geometry(::Any,::Any,::Any)
```

## Ink Struct

```@docs
Ink
```

## Materials

One example material is exported as part of the basic API. To see how to define
new materials or new material models, see [Material Model](@ref).

```@docs
PA2200
```

## Time Step Results

The default time step/initial results struct shown below saves the data from the
default material model and the heat transfer solver. For information on how to
create a new result struct see [Time/Load Step Results](@ref).

```@docs
Result
Result(::Any,::Any,::Any,::Any,::Any,::Any)
Result(::Any,::Any)
Result(::Any,::Any,::Any,::Any,::Any)
Result(::Any,::Any,::Any)
```

## Other Results

These are results that are saved once at the end of the simulation, for when 

The default final results struct shown below saves the maximum melt state from
the default material model and nothing else. For information on how to create a
new result struct see [End of Simulation Results](@ref).

```@docs
OtherResults
```

## Boundary Loads

Two functions are provided below to create loads and load sets. The
[`basicLoad`](@ref) function creates a single basic load that can be used
with [`FixedLoadSet`](@ref) and [`LayerLoadSet`](@ref) to make load sets for
the `loadSets` argument of the [`Problem`](@ref Problem(; kwargs...)). For
information on how to make more loads, see [Boundary Model](@ref).

The [`HSSLoads`](@ref) constructor creates a full list of load sets needed to
simulate a typical HSS build. For more information on these loads, see [HSS
Boundary](@ref).

```@docs
basicLoad
HSSLoads
FixedLoadSet
LayerLoadSet
```

## Boundary Parameters

```@docs
BasicProblemParams
HSSParams(::Geometry)
```

## Settings

```@docs
Options
package_groups
```

## Results File Structure

The last part of the API to cover is the format of the simulation results that
are saved. These use the `JLD2` package to save to a Hierarchical Data Format
version 5 (HDF5) based format. Most of the information stored should be readable
by any HDF5 compatible software or libraries, except the input problem, which
requires the software to understand Julia types (the easiest way is to just use
Julia, it's mostly saved in case it needs to be rerun).

By default, this is stored compressed using the `ZlibCompressor` compressor.

The results have the following structure:

```text
Tree                           Description
Results
│
├─ Description                 - An overview of the problem that has been solved
├─ Input                       - The full problem struct that has been solved
├─ Start_Time                  - The computer's clock time at the end of the simulation
├── Results
│   ├─ MeltMax                 - The maximum melt state reached in the simulation
│   │
│   ├── Preheat-1              - List of loads run during the preheating load set
│   │   ├─ 1
│   │   ├─ 2
│   │   └─ ⋯ (3 more entries)
│   │
│   ├── Layer-2                - 1st Layer
│   │   ├─ 1                   - 1st Layer's 1st Load
│   │   ├─ 2                   - 1st Layer's 2nd Load
│   │   └─ ⋯ (6 more entries)  - And so on for the remaining loads
│   │
│   ├── Layer-3                - 2nd Layer
│   │   ├─ 1 (5 entries)
│   │   ├─ 2
│   │   └─ ⋯ (6 more entries)
│   │
│   ├─ ⋯ (25 more entries)     - And so on for the remaining layers
│   │
│   └── Cooldown-28            - List of loads run during the cooldown load set
│       ├─ 1
│       ├─ 2
│       └─ ⋯ (3 more entries)
│
├─ Results_Index               - A list of all load results indices within this file
├─ Finish_Time                 - The computer's clock time at the end of the simulation
└─ _types                      - Ignore (Used internally by JLD2)
```

Where each of the loads has these fields:

```text
Tree           Description

Load
├─ name        - The load's name
├─ time        - 1D array of the times of the load's time steps
├─ T           - 4D array of temperatures (X, Y, Z, time step)
├─ M           - 4D array of melt states (X, Y, Z, time step)
└─ C           - 4D array of consolidation states (X, Y, Z, time step)
```

!!! tip
    
    [`Results.loadStepSaver`](@ref), [`Solver.otherResults`](@ref), are the
    two functions used for saving simulation results to the file. so looking
    at their implementation might help with if anything is not covered here.
    [`Solver.startMetadata`](@ref) and [`Solver.finishMetadata`](@ref) are also
    used to save a few extra bits of metadata to the file. I'd also recommend a
    tool like [HDFView](https://www.hdfgroup.org/downloads/hdfview/) to get an
    idea for the structure of the results.
