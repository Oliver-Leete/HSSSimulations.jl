# Result Type Recipes

## Basic Results

A basic result type that only stores the temperature, can be used with [A
Basic Material Model](@ref).

!!! warning
    
    As this struct is what stores the data during the simulation, if this is
    used with the normal material model you will get an error, as it needs the
    `M` and `C` fields that we have removed.

As well as defining the type, it helps to have a few convenient constructors,
some of these will be needed for the type to function in the simulation. It also
needs an implementation of [`Results.loadStepSaver`](@ref).

```julia
struct BasicResult{P<:AbstractArray} <: AbstractResult
    "Temperature"
    T::P
    "Time of timestep"
    t::Float64
    "The progress through the load step (0=start, 1=end)"
    tₚ::Float64
end

"""
Create an empty result
"""
function BasicResult(geomSize, t, tₚ)
    T = Array{Float64}(undef, geomSize...)
    return BasicResult{typeof(T)}(T, t, tₚ)
end

"""
Create a result with uniform fields
"""
function BasicResult(geomSize, Tᵢ, t, tₚ)
    T = fill(Tᵢ, geomSize)
    return BasicResult{typeof(T)}(T, t, tₚ)
end

"""
Function to save the results for each load step
"""
function Results.loadStepSaver(
    loadResultsFolder,
    loadResults::StructVector{T},
) where {T<:BasicResult}
    loadResultsFolder["time"] = loadResults.t
    loadResultsFolder["T"] = stack(loadResults.T)
    return
end
```
