"""
$(TYPEDEF)

The results from a single timestep, use directly to create the initial conditions. Also created for
each time step during the simulation.

# Fields
$(TFIELDS)
"""
struct Result{P<:AbstractArray} <: AbstractResult
    "Temperature"
    T::P
    "Melt state"
    M::P
    "Consolidation state"
    C::P
    "Time of timestep"
    t::Float64
    "The progress through the load step (0=start, 1=end)"
    tₚ::Float64
end

"""
$(TYPEDSIGNATURES)

Re-expose the default constructor
"""
Result(T, M, C, t, tₚ) = Result{typeof(T)}(T, M, C, t, tₚ)

"""
$(TYPEDSIGNATURES)

Create a result filled with zeros
"""
function Result(geomSize, t)
    T = zeros(geomSize)
    M = zeros(geomSize)
    C = zeros(geomSize)
    return Result{typeof(T)}(T, M, C, t, 0)
end

"""
$(TYPEDSIGNATURES)

Create an empty result
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
function Result(geomSize, Tᵢ, Mᵢ, Cᵢ, t, tₚ)
    T = fill(Tᵢ, geomSize)
    M = fill(Mᵢ, geomSize)
    C = fill(Cᵢ, geomSize)
    return Result{typeof(T)}(T, M, C, t, tₚ)
end

"""
    loadSave(loadResultsFolder, loadResults::StructVector{T}) where {T<:AbstractResult}

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
    otherResults(prob<:Problem, file)

Runs at the end of the simulation to save any additional results that only need to be saved once, as
opposed to for every nth time step. The [`Types.Problem`](@ref) type and any of its type parameters
can be dispatched on.

For example, this will run if both the `HSSParams` parameter type, the `MatProp` material property
and `MyOtherResults` are used for the simulation. It will save the maximum melt state of each node
to a field called `MeltMax`, ect. See [`AbstractOtherResults`](@ref) for a place to store random
data, and [Tutorial 4: Saving More Results](@ref) for a detailed guide.

```julia
function Res.otherResults(
    prob::Problem{T,Gh,M,R,OR,P},
    file,
) where {T<:Any,Gh<:Any,M<:MatProp,R<:Any,OR<:MyOtherResults,P<:HSSParams}
    file["MeltMax"] = prob.matProp.Mₘ
    file["CooldownStartTime"] = prob.params.coolStart
    file["myResult"] = prob.otherResults.something_else_interesting
    return
end
```
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
