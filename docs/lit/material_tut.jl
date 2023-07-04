using HSSSimulations

# ## Overview
#
# This tutorial will cover how to implement the time dependent melt state model introduced in
# my thesis. To do this, this tutorial builds on top of the full build tutorial by adding a new
# material property type.
#
# This is a proposed solution for the poor results of the melt state results found in my thesis
# is to model the melt state similarly to how the default material model treats the Consolidation
# state, making it time dependent. This has not been implemented as the default model as I don't
# currently have the required data, but if you have the data then you can use this implementation
# (my thesis should include an idea for how to get the data).
#
# ## Making the Material Property Struct
#
# First up is the addition of a new material property struct and constructor. This is the same as
# the default one with the only change being the name (for dispatch reasons), and changing the
# `Mᵣ` and `Rᵣ` fields to `Ṁ` and `Ṙ`.
#
# !!! note
#
#     There is not actually any functional difference (for this use case, some of the fields have
#     been removed so this struct wouldn't work with the normal `meltUpdate` function) between this
#     and the built in [`MatProp`](@ref) type, other than the change of documentation. But by having
#     a new type we can dispatch on it later on, to allow for our custom logic.

struct MatPropTD{T1,T2,T3,T4,T5,T6,T7,T8,T9} <: Types.AbstractMatProp
    ρ::T1
    c::T2
    κ::T3
    """ Melting rate to temp and melt state relationship.
    A 2d interpolation, with the first input axis being the temperature adn the
    second the current melt state. The output is the melt rate.
    """
    Ḟ::T4
    """ Crystallisation rate to temp, melt state and maximum melt state relationship.
    A 3d interpolation, with the first input axis being the node temperature,
    the second the current melt state and the third the maximum melt state
    reached. The output is the recrystalisation rate.
    """
    Ṙ::T5
    Hf::T6
    Hr::T7
    Ċ::T8
    eₚ::Float64
    eᵢ::Float64
    ε::Float64
    name::String
    Mₘ::T9
end

# As well as copying the old type, we'll also copy its constructor, to give us a more convineient
# way of constructing it from our experimental data. Again, this is the same as before, just with a
# change of name.

function MatPropTD(ρ, c, κ, Ṁ, Ṙ, Hf, Hr, Ċ, eₚ, eᵢ, ε, name, geometry)
    geomSize = (geometry.X, geometry.Y, geometry.Z)
    Mₘ = zeros(geomSize)

    return MatPropTD{
        typeof(ρ),typeof(c),typeof(κ),
        typeof(Ṁ),typeof(Ṙ),typeof(Hf),typeof(Hr),
        typeof(Ċ),typeof(Mₘ),
    }(
        ρ, c, κ,
        Ṁ, Ṙ, Hf, Hr,
        Ċ,
        eₚ, eᵢ, ε,
        name, Mₘ,
    )
end

# ## Adding The New Logic

# Now we have the new type, we can use it with julia's multiple dispatch to change what method
# is called when the simulation goes to update the melt state. This is done by making a new
# method for [`Material.meltUpdate`](@ref) that specifies our new type in place of the default
# [`MatProp`](@ref) type. Refer to my thesis if you would like an explanation as to what has changed
# here from the default method.

function Material.meltUpdate(Mᵗ⁻¹, T, Mₘ, Δt, mp::MatPropTD)
    ṀF = mp.Ḟ(T, Mᵗ⁻¹)
    ṀR = mp.Ṙ(T, Mᵗ⁻¹, Mₘ)

    if ṀF > -ṀR
        ΔM = ṀF * Δt
        ΔH = ΔM * mp.Hf
    else
        ΔM = ṀR * Δt
        ΔH = ΔM * mp.Hr(Mₘ)
    end
    Mᵗ = min(max(Mᵗ⁻¹ + ΔM, 0), 1)
    Mₘ = max(Mᵗ, Mₘ)

    return Mᵗ, Mₘ, Δh
end

# If we needed more arguments to be passed in to this function, or wanted to change other properties
# of the material model, we could define a new method for [`Material.calcMatProps!`](@ref). For an
# example of this, you can check out [A Basic Material Model](@ref). [`Material.consUpdate`](@ref)
# is also dispatched on the material property struct, so that can also be modified sepreatly without
# having to rewrite the entire material model.

# ## Making a New Material
#
# We'll use PA2200 as our material, using most of the values from the default type. The only changes
# will be our two melt rate relationship fields. To fill in the values for these fields we'll use
# interpolated arrays, so first lets add the interpolations package:

using Interpolations

# Then we can use this to create a 2D interpolation for `Ṁ` that does what we said we want it to
# do.
#
# !!! note
#
#     The data presented here is totally fictional and should be replaced with actual data.
#
# To do this you will need the values corrisponding to the inputs of the data, so for example if we
# recorded the melt rate at temperatures of 170°C, 180°C and 190°C then we could define

melt_temps = [170, 180, 190]

# And if we made those measurements at melt states of 0 and 1

melt_state = [0, 1]

# We can then define the outputs, what the value of the melt rates measured for each of those
# states, where the x-axis of the array is the temperature and the y-axis is the melt state. So for
# this example, we have a melt rate of `0.03` at `M=0` at a temperature of 190°C.

melt_rate = [
    0 0.02 0.03
    0 0.01 0.02
]

# Then we can use these to make the linear interpolation that will be used in the simulation.
# Where the first argument is a tuple of our inputs and the second is our outputs. The
# key word argument defines how the values should be extrapolated if an input is given
# outside of the range of the inputs we've provided. Check out [the Interpolations.jl
# docs](https://juliamath.github.io/Interpolations.jl/latest/extrapolation/) for more info on these.

PA_Ṁ = linear_interpolation(
    (melt_temps, melt_state),
    melt_rate;
    extrapolation_bc=Flat(),
)

# You can test out what this does by trying to index into it with values other than those given, it
# should return values linearly interpolated between the ones you gave.

PA_Ṁ[175, 0.5]

# Then we can do a similar thing for the recrystalisation rate. Although here we need an extra
# input, the maximum melt state that was reached before recrystalisation began.

recryst_temps = [150, 180]
melt_state = [0, 1]
melt_max = [0, 1]

# And because we have an extra input, the output needs to have an extra dimension. The triple
# semicolon is used to concatinate in the 3rd dimension. So the 2×2 array befor the triple
# semicolon is the melt rate for a melt max of 0 and the one after is for a melt max of 1.

recryst_rate = [
    0.1 0;
    0.5 0
    ;;;
    0.2 0;
    0.8 0
]

PA_Ṙ = linear_interpolation(
    (recryst_temps, melt_state, melt_max),
    recryst_rate;
    extrapolation_bc=Flat(),
)

# And like before, we can gives this a go.

PA_Ṙ[160, 0.2, 0.733]

# And finally this can all go together to make our material, but like before we need to make a
# geometry to pass in to the material propetry constructor.

geometry = Geometry(
    (0.016, 0.016, 0.0122),
    0.001,
    1.5e-3;
    Δz=0.003 / 90,
    Δh=0.0001,
    offset=(0.0925, 0.1425),
    buildSize=(0.200, 0.300),
    name="30 layers preheat, 50 pre square pad layers 32 layer thich square and 10 post square padding layers",
)

material = MatPropTD(
    Material.PA_ρ(),
    Material.PA_c(),
    Material.PA_κ(),
    PA_TD_M,
    PA_TD_R,
    Material.PA_Hf(),
    Material.PA_Hr(),
    Material.PA_Ċ,
    Material.PA_eₚ,
    Material.PA_eᵢ,
    Material.PA_ε,
    "Time dependent PA2200",
    geometry,
)

# ## The Rest of the Setup
#
# From here on it's just the same as our other simulations.

params = HSSParams(geometry)
loadSets = HSSLoads(4, geometry; nrPreheat=90, lenPreheat=10.0, nrCool=90, lenCool=10.0)

size = (geometry.X, geometry.Y, geometry.Z)
init = Result(size, 25.0, 0.0, 0.0, 0.0, 0)
initialLayer = 10

inkArray = fill(material.eₚ, size)
inkArray[5:end-4, 5:end-4, 60:end-10] .= material.eᵢ
ink = Ink(inkArray, "Sample square")

file = "material_model_tutorial.jld2"
description = "A simulation to test a time dependent melt model"

problem = Problem(;
    geometry=geometry,
    matProp=material,
    params=params,
    preheatLoads=preheatLoads,
    buildLoads=buildLoads,
    cooldownLoads=cooldownLoads,
    init=init,
    initLay=initialLayer,
    ink=ink,
    file=file,
    description=description,
)

resultFile, finalResults = problemSolver(problem)
