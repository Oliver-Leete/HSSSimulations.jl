"""
$(TYPEDEF)
This is the parent type of all of the simulation property types. It exists mostly to define a show
method for all of it's subtype. This just makes things nicer to look at the.
"""
abstract type AbstractSimProperty end

function Base.show(io::IO, simProp::T) where {T<:AbstractSimProperty}
    for fieldName in fieldnames(T)
        field = getfield(simProp, fieldName)
        fieldType = typeof(field)
        #!format: off
        if hasfield(fieldType, :name) && fieldType != DataType
            # If the field has it's own name field then use that for a one line print
            println(io, "  ", string(fieldName), " : ", getfield(field, :name))
        elseif any(fieldType <: T for T in (AbstractString, Real, DataType))
            # If the field is a simple variable then use that for a one line print
            println(io, "  ", string(fieldName), " : ", field)
        else
            # If not then use it's own show function to print it over multiple lines
            println(io, "  ", string(fieldName))
            println(io, "----------------------")
            println(io, field)
            println(io, "")
        #!format: on
        end
    end
end

"""
$(TYPEDEF)

This as the abstract type for the results from a single simulation time step. These are save at the
end of every load step for each of the time steps in that load step (ignoring time steps that are
skipped over based on the load steps skip value).

See [Tutorial 4: Saving More Results](@ref) and [Result Type Recipes](@ref) for how to make your own
subtype.

!!! warning

    As this struct is what stores the data during the simulation, all subtypes **MUST** have the
    `T`, `t` and `tₚ` fields, and if used with the default material model it will also need the
    `M` and `C` fields.

"""
abstract type AbstractResult <: AbstractSimProperty end

"""
$(TYPEDEF)

This as the abstract type for the results that are saved only at the end of the simulation. This
is useful to store things that do not change every time step, without requiring any changes to the
material property or params structs. However those structs can also be used to store such things,
such as is done for Mₘ in the `MatProp` struct.

As the default implementation does nothing, and nothing normally dispatches on it, it can
be replaced by another empty type to use a new method for any function that dispatches on
[`Problem`](@ref) (I think that's all of the user facing API).

See [Tutorial 4: Saving More Results](@ref) and [Result Type Recipes](@ref) for how to make your own
subtype.
"""
abstract type AbstractOtherResults <: AbstractSimProperty end

"""
$(TYPEDEF)

The default struct stores no additional data and only acts as a placeholder. When used, the
simulation will store the maximum melt state to `Results` folder of the output file and no other
final results (time step results are still saved each load step).
"""
struct OtherResults <: AbstractOtherResults end

"""
$(TYPEDEF)

Defines the volume of the ink placement within that (and therefore hopefully the part to be made).
See [Ink Pattern Recipes](@ref) for some example patterns.

# Fields
$(TFIELDS)

This is the emmisivity relative to the lamp. So the emmisivity of the ink over the range of the
wavelengths that the lamp outputs, scaled by the relative output power of the lamp at those
wavelengths.
"""
struct Ink{T}
    "The emmisivity of the models nodes, set to eₚ for nodes without ink."
    nodes::Array{T,3}
    "Just used for future reference of results"
    name::String
    "For making empty inks"
    function Ink(size::Tuple, eₚ::Real)
        nodes = fill(eₚ, size)
        return new{typeof(eₚ)}(nodes, "Empty")
    end
    Ink(nodes::Array, name::String) = new{eltype(nodes)}(nodes, name)
end

"""
$(TYPEDEF)

The abstract type that any material property struct needs to be a subtype of. These are for storing
the values used to define the properties of a material, and those used to calculate the changes in
material properties due to the build. The default struct used is `MatProp`, however new subtypes
can be defined and used by defining a new `Material.calcMatProps!` function. This allows for the
simplificiation (or complication) of the material model used in the simulation to fit your needs.

Any new subtype will need it's own method writen for `calcMatProps!` and if the example boundaries
are being used some of them might need to be updated to use the new material properties. If melt
state or consolidation state are beind removed from the material model then it might be worth
implementing a new [`AbstractResult`](@ref) to save on memory. If an additional property that needs
to be tracked is added to the material model then it will be necissary to implement a new subtype of
those to track this.

See [Material Model Recipes](@ref) and [Tutorial 3: A Melt Rate Based Material Model](@ref) for more
information on implementing your own.
"""
abstract type AbstractMatProp <: AbstractSimProperty end

"""
A list of all of the log groups used in this package. They log the following things:

  - `core`: the start of a problem, loadstep, load or timestep has started
  - `solver`: the fdm solver
  - `mat`: material model
  - `bound`: boundary condition
  - `b_adv`: recoating and moving object boundaries
  - `hss`: HSS example functions
"""
const package_groups = ["core", "solver", "mat", "bound", "b_adv", "hss"]

"""
$(TYPEDEF)
# Fields
$(TFIELDS)

The `debug` option is passed to the logGroups option of `Solver.makeLogger`, check that out
for more information and [`package_groups`](@ref) for what log groups are available by default.

!!! note

    Depending on settings, the debug option might log a lot of things, the log file could end up
    somewhere in the region of 4x the size of the compressed results file, so make sure you clean
    them up after you're done.
"""
Base.@kwdef struct Options
    """How to compress the results file, can be set to true (to compress),
    false (to leave uncompressed) or to a specific compression algorithm (see [the JLD2
    documentation](https://juliaio.github.io/JLD2.jl/dev/compression/ @ref) for more details)"""
    compress::Union{Bool,supertype(CodecZlib.CompressorCodec)} = true

    """Whether or not to log debug information, can accept a list of strings to select only some
    debugging groups, see [`package_groups`](@ref)"""
    debug::Union{Bool,Vector{String}} = false

    """Whether or not to show the progres meter, if a number is given that is used as the
    update interval"""
    showProgress::Union{Bool,Float64} = true

    "If true, simulations finishing will send a system notification using Alert.jl"
    notify::Bool = true
end
