"""
$(TYPEDEF)

The results from a single timestep, use directly to create the initial conditions. Also created for
each time step during the simulation.

This saves the data from the default material model and the heat transfer solver. For information on
how to create a new result struct see [Time/Load Step Results](@ref).

# Fields
$(TYPEDFIELDS)
"""
struct Result{P<:AbstractArray} <: AbstractResult
    "Temperature for each node"
    T::P
    "Melt state for each node"
    M::P
    "Consolidation state for each node"
    C::P
    "Time of timestep, since the start of the build"
    t::Float64
    "The progress through the load step (0=start, 0.5=half way, 1=end)"
    tₚ::Float64
end

"""
$(TYPEDSIGNATURES)

Create an empty result. This is used during the simulation to create the results for each time step.
"""
function Result(geomSize, t, tₚ)
    T = Array{Float64}(undef, geomSize...)
    M = Array{Float64}(undef, geomSize...)
    C = Array{Float64}(undef, geomSize...)
    return Result{typeof(T)}(T, M, C, t, tₚ)
end

"""
$(TYPEDSIGNATURES)

Create a result with uniform fields
"""
Result(geomSize, Tᵢ, Mᵢ, Cᵢ) = Result(geomSize, Tᵢ, Mᵢ, Cᵢ, 0.0)

"""
$(TYPEDSIGNATURES)

Create a result with uniform fields and a given time.
"""
function Result(geomSize, Tᵢ, Mᵢ, Cᵢ, t)
    T = fill(Tᵢ, geomSize)
    M = fill(Mᵢ, geomSize)
    C = fill(Cᵢ, geomSize)
    return Result{typeof(T)}(T, M, C, t, 0.0)
end

"""
    $(FUNCTIONNAME)(loadResultsFolder, loadResults::StructVector{T}) where {T<:AbstractResult}

Saves the results of a load step into the folder for the current load step in the output file of the
problem, given by the `loadResultsFolder` argument.

Any new methods for this function should dispatch on the type parameter of the `loadResults`, and
save any desired results to the file like so:

```julia
function loadStepSaver(loadResultsFolder, loadResults::StructVector{T}) where {T<:AbstractResult}
    loadResultsFolder["time"] = loadResults.t
    loadResultsFolder["T"] = stack(loadResults.T)
    return
end
```

!!! note

    `stack` is used as a very efficient way of converting the vector of 3D arrays from the
    `StructVector` in to a 4D array.
"""
function loadStepSaver end

"""
$(TYPEDSIGNATURES)

Saves the results for the temperature, melt state and consolidation state as 4D arrays of X,Y,Z and
t. And the time is saved as a 1D Array.
"""
function loadStepSaver(loadResultsFolder, loadResults::StructVector{T}) where {T<:Result}
    loadResultsFolder["time"] = loadResults.t
    loadResultsFolder["T"] = stack(loadResults.T)
    loadResultsFolder["M"] = stack(loadResults.M)
    loadResultsFolder["C"] = stack(loadResults.C)
    return
end

"""
    $(FUNCTIONNAME)(prob<:Problem, file)

Runs at the end of the simulation to save any additional results that only need to be saved once, as
opposed to for every nth time step. The [`Types.Problem`](@ref) type and any of its type parameters
can be dispatched on.

See [`AbstractOtherResults`](@ref) for a place to store random data, and [Tutorial 4: Saving More
Results](@ref) for a detailed guide.
"""
function otherResults end

"""
$(TYPEDSIGNATURES)

Default [`otherResults`](@ref) method that just saves the maximum melt state reached for each node.
"""
function otherResults(
    problem::Problem{T,Gh,Mp,R,OR,B},
    file,
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    file["MeltMax"] = problem.matProp.Mₘ
    return
end
