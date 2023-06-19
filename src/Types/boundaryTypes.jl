"""
$(TYPEDEF)

Stores the indices of the nodes, taking into account if the node represents a volume that contains
powder or not. And also stores the node pais for the boundaries.

`iᵣ` are indices of real nodes, this is all nodes that represent space where there is currently
powder. This will normally include every node, however before and during the recoat load it will not
include all of the top layer, as powder has not been deposited there yet. `iᵢ` are the indices of
'imaginary' nodes, these are nodes that represent locations that do not currently contain powder.
These is the same as the indices of all of the nodes minus the indicies of the real nodes (`iᵣ`).

Fields with a subscript 1 (`₁`) denote the boundary at the start of that axis, and subscript
2 (`₂`) dentoes the end of that boundary. eg. `x₂` is the boundary [end,:,:] and `y₁` is
y[:,1,:]. z₂ is a special case where it always represents the top surface of the build, even if a
layer has not been compleatly deposited yet. y₂ is another special case, where it represents its
normal face, but also represents the leading edge of deposited powder.

The first element of the tuple in the boundary indices is the index (of the array without the ghost
cells) for the real node and the second element is the index (of the array with the ghost cells) of
the matching ghost node.

# Fields
$(TFIELDS)
"""
mutable struct Indices
    "List of currently real nodes"
    iᵣ::Vector{CartesianIndex{3}}
    "List of currently imaginary nodes"
    iᵢ::Vector{CartesianIndex{3}}
    "List of real/ghost node pairs for `[1,:,:]"
    const x₁::Matrix{Tuple{CartesianIndex{3},CartesianIndex{3}}}
    "List of real/ghost node pairs for `[end,:,:]"
    const x₂::Matrix{Tuple{CartesianIndex{3},CartesianIndex{3}}}
    "List of real/ghost node pairs for `[:,1,:]"
    const y₁::Matrix{Tuple{CartesianIndex{3},CartesianIndex{3}}}
    "List of real/ghost node pairs for `[:,end,:]"
    y₂::Matrix{Tuple{CartesianIndex{3},CartesianIndex{3}}}
    "List of real/ghost node pairs for `[:,:,1]"
    const z₁::Matrix{Tuple{CartesianIndex{3},CartesianIndex{3}}}
    "List of real/ghost node pairs for `[:,:,end]"
    z₂::Matrix{Tuple{CartesianIndex{3},CartesianIndex{3}}}
    "The middle point of z₂, and it is currently only used for debugging/logging."
    iₘ::CartesianIndex{3}
    "The same as it is in [`Geometry`](@ref), it is just copied over for convenience."
    ΔH::Int
end

"""
Subtypes of this define a boundary for a single face of the model. An instance of the subtype is
created per boundary each time step.

The fields of the subtype should contain all of the information needed to calculate the heatflow on
that boundary (except for the information already passed in to `Types.boundaryHeatTransferRate`).

Each subtype of this should have a constructor that satisfies the following signature:

    <Boundary>(pts::AbstractResult, cts::AbstractResult, G::GVars, ls::LoadStep)

## Arguments

  - `pts`  : The results from the previous timestep. See `Result`
  - `cts`  : The results from the current timestep. See `Result`
  - `G`    : The 'global' variables of the simulation. See [`GVars`](@ref)
  - `ls`   : The per load step variables. See [`LoadStep`](@ref)

For examples see the default subtypes, and their constructors. [Boundary Recipes](@ref) has examples
of some of the extra things that can be done with new `AbstractBoundary`s.

!!! warning

    The constructor for z₂ is the only one that is run before the indices lists are set for that
    load. So any updating of the indices, such as that done by `recoating!`, should be done in that
    boundary constructor.

!!! warning

    `cts.T` is unknown when this function is called, use the temperature from the previous time step
    insted (`pts.T`).
"""
abstract type AbstractBoundary <: AbstractSimProperty end

"""
    boundaryHeatTransferRate(T, i, p<:AbstractBoundary) -> ϕ⃗::Float64

Used to calculate the heat flux denstity (ϕ⃗, in wm⁻²) into the model at a node on the
relavant face for a given boundary condition. They are run per node, for each node on the face. The
function should return a single numeric value that represents the heat flux density into the model.

## Arguments

  - `T`     : The temperature of the node for which the ghost node is being calculated
  - `i`     : The cartesian index of the node for which the ghost node is being calculated
  - `p`     : The boundary struct for the current boundary (see [`AbstractBoundary`](@ref))

See the implementations of this for examples, and [Boundary Recipes](@ref) for some additional
examples along with the relevant boundary structs.

!!! note

    A positive heat flow equates to heat flowing into the model and negative out of the model.

!!! warning

    As this is run for every node on the face every time step, try to avoid complex computations.
    Where possible, put them in the constructor of the [`AbstractBoundary`](@ref) instead, as that
    is only run once per face per timestep.
"""
function boundaryHeatTransferRate end

"""
$(TYPEDEF)

# Fields
$(TFIELDS)

Each of the boundaries given must satisfy `Boundary isa Type{T} where T <: AbstractBoundary`. This
is to say that they should be the type itself, not an instance of that type. Additionally it should
be a subtype of [`AbstractBoundary`](@ref) and meet all of the requirements outlined in the that
documentation.

!!! note

    If the `Load` is in a [`BuildLoadSet`](@ref Types.AbstractLoadSet) then one of the boundaries
    in one of the loads in the set should call the recoating logic so that new powder is actuall
    being layed down. This should always be done in the z₂ boundary, as it is a special case that
    ensures the indicies are updated for all other boundaries.
"""
struct Load{
    X₁<:AbstractBoundary,X₂<:AbstractBoundary,
    Y₁<:AbstractBoundary,Y₂<:AbstractBoundary,
    Z₁<:AbstractBoundary,Z₂<:AbstractBoundary,
} <: AbstractSimProperty
    "The boundary condition for the start of the x axis (`[1,:,:]`)"
    x₁::Type{X₁}
    "The boundary condition for the end of the x axis (`[end,:,:]`)"
    x₂::Type{X₂}
    "The boundary condition for the start of the y axis (`[:,1,:]`)"
    y₁::Type{Y₁}
    "The boundary condition for the end of the y axis (`[:,end,:]`)"
    y₂::Type{Y₂}
    "The boundary condition for the start of the z axis (`[:,:,1]`)"
    z₁::Type{Z₁}
    "The boundary condition for the end of the z axis (`[:,:,end]`)"
    z₂::Type{Z₂}
    "Used to annotate the results"
    name::String
    "The duration of the load in seconds"
    tₗ::Float64
    "The distance between results to save (see [Why We Skip Some Results](@ref))"
    skip::Int

    function Load(name, tₗ, skip, x₁, x₂, y₁, y₂, z₁, z₂)
        # This is checked now as you don't want to get to the cooldown loads of a long simulation
        # only to find that one of your cooldown loads doesn't have an implementation of
        # boundaryHeatTransferRate and the whole thing fails.
        # Also do the same check for if the boundary has a constructor with the
        # correct number of arguments
        for l in [x₁, x₂, y₁, y₂, z₁, z₂]
            if !hasmethod(boundaryHeatTransferRate, Tuple{Any,Any,l})
                throw(MethodError(boundaryHeatTransferRate, Tuple{Any,Any,l}))
            end
            if !hasmethod(l, Tuple{AbstractResult,AbstractResult,GVars,LoadStep})
                throw(MethodError(l, Tuple{AbstractResult,AbstractResult,GVars,LoadStep}))
            end
        end
        return new{x₁,x₂,y₁,y₂,z₁,z₂}(x₁, x₂, y₁, y₂, z₁, z₂, name, tₗ, skip)
    end
end

Base.display(io::IO, loadVec::Vector{T}) where {T<:Load} = show(io, loadVec)
function Base.show(io::IO, loadVec::Vector{T}) where {T<:Load}
    println(io, "")
    if all(map(load -> load.name == loadVec[1].name, loadVec))
        println(io, "  ", "Name: ", getfield(loadVec[1], :name))
        println(io, "  ", "For ", length(loadVec), " loads")
    else
        for load in loadVec
            println(io, "  ", "Name: ", getfield(load, :name))
        end
    end
end

"""
$(TYPEDEF)
This struct holds the information for a load set, primarily the list of loads, but also some
extra bits. Subtypes should implement a method for the `Solver.loadSetSolver!` function.
"""
abstract type AbstractLoadSet <: AbstractSimProperty end

"""
$(TYPEDEF)
The `Problem` struct contains a field called boundary that is of this type. The purpose of this
field is to store any boundary condition inputs that changes over the course of a build, such as
the air temperature in the machine. As this is an abstract type a new struct can be made, that is
a subtype of AbstractProblemParams, to contain the required variables for a given simulation. An
example of this is given in `HSSParams`.

Any new subtype will need it's own boundaries written (the examples given are only meant to work
with the `HSSParams` example).

See the [Problem Parameters Recipes](@ref) for some insperation for implementing your own.
"""
abstract type AbstractProblemParams <: AbstractSimProperty end
