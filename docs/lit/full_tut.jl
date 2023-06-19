using HSSSimulations

# This tutorial will cover how to create a simulation problem, solve it, and inspect the results. It
# differs from the [Tutorial 2: Warm-up and Cool-down only](@ref) (which I will assume you have gone
# through) by actually trying to simulate part of a printer build, instead of a contrived situation.
# This means we'll have preheat loads, layers being added and complex boundary conditions. Whilst
# the simulation is more complicated, some setup is actually easier, as this is what the package was
# built for.
#
# ## Defining the Problem
#
# Like before, we'll start by defining the geometry:

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

# There are some additional arguments given here, let's go over them quickly. In
# the basic simulation we specified the node spacing as the second argument, and
# this specified the spacing in all three axis. Here we add a `Δz` argument, when
# this is given it overrides the node spacing for this one axis. This is useful as
# we want the spacing in the z-axis to be the same as the layer height, but using
# the same spacing in all axes would limit the size of the simulation. This leads
# nicely on to `Δh`, which is the layer thickness in meters (100 microns in this
# case).
#
# !!! note
#
#     A `Δy` argument can also be given to override the node spacing in the
#     y-axis. There is no equivalent for the x-axis, instead just give the desired
#     spacing as the default and use the `Δz` and `Δy` overrides to get the desired
#     spacing.
#
# The last two are the `buildSize` and `offset`. It is often useful to simulate a
# subset of the build volume (mostly for memory and computational cost reasons),
# to do this we can specify the true size of the machine (`buildSize`) and where
# the simulation sits within it (`offset`). Both of these are given in meters.
#
# We'll use the other built-in material this time, a version of the PA2200
# material used before that has the rate of change of consolidation state
# dependent on more than just temperature.

material = PA2200(geometry)

# This time around we can just use the load sets provided by
# [`HSSLoads`](@ref), without having to muck about with it
# ourselves. Here we define the skip (in this case lets go for 10), and a few
# extra key word arguments that decide how many preheat and cooldown loads to
# have, along with how long they should be (so preheat time in this case is 90x10,
# for 900 seconds total).
#
# !!! note
#
#     Multiple short loads are used in cases where the load case stays the same
#     for a while. The solver only saves results from memory to disk in between
#     loads, so splitting it up reduces the memory requirement (at the cost of a
#     slight increase in computational cost).

params = HSSParams(geometry)
loadSets = HSSLoads(4, geometry; nrPreheat=90, lenPreheat=10.0, nrCool=90, lenCool=10.0)

# When we specify the initial results, we'll also specify the `initialLayer`, this
# will be used to tell the simulation how many layers worth of powder should be
# already deposited at the start of the simulation. Theses are the layers that
# will be simulated during the preheat load set.

geomsize = (geometry.X, geometry.Y, geometry.Z)
init = Result(geomsize, 25.0, 0.0, 0.0, 0.0, 0)
initialLayer = 30

# The [`Ink`](@ref) struct for this problem is going to have some actual ink in
# it. To do this we will fill a subset of the `inkArray` with a value of `1.0`
# this is making the assumption that our ink is a perfect absorber of our lamp's
# energy. And we'll also change the name of the `Ink` to represent this.

inkArray = fill(material.eₚ, size)
inkArray[5:end-4, 5:end-4, 90:end-30] .= material.eᵢ
ink = Ink(inkArray, "Sample square")

# And like before we will give the problem a name and description and then create
# it.

file = "full_build_simulation_tutorial.jld2"
description = "A full simulation of a sample square"
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

# ## Solving the Problem
#
# Like before, this part is simple for you. But now it is even more complicated
# for the computer.

resultFile, finalResults = problemSolver(problem)

# !!! tip "Performance Tips"
#
#     The simulation will only run on one proccessor, but will run on as many
#     threads as you can give it. So if you haven't already, try starting juila
#     with the `--threads=auto` flag to give the simulation more threads to work
#     with. If you are using a notebook you will need to look into how to make a
#     kernel that uses multiple threads.
#
#     If it is still running too slow you can try playing around with the geometry
#     sizes, the x and y-axis node spacing or the time step (just be aware that
#     changing node spacing and time step can lead to unstable simulations,
#     normally resultsing in an out of bounds error). And if you run into memory
#     issues you can try increasing the value of `skip` ([Why We Skip Some
#     Results](@ref)).

#src TODO: update when I've worked on post processing, include some functions that don't make much
#src sense for the first one
