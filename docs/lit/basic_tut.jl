using HSSSimulations

# This tutorial will cover how to create a basic simulation problem, solve it, and
# inspect the results. This basic simulation will only simulate a solid block
# without, no layers or anything else fancy.
#
# ## Defining the Problem
#
# ### Geometry
#
# First we'll start by defining the finite difference geometry for the problem.
# This is done by creating an instance of [`Geometry`](@ref) as shown below. The
# first argument is the size of the simulation in meters (here it is 10 mm x
# 10 mm x 30 mm), the second is the spacing between the finite difference nodes,
# and the third is the time step. Finally, a name has been given to make it easier
# to figure out what we're looking at if we come back to this in the future.

geometry = Geometry(
    (0.010, 0.010, 0.030),
    0.0005,
    0.001;
    name="Basic Simulation Tutorial",
)

# ### Material
#
# For the material we will use the default material model along with the example material,
# [`PA2200`](@ref) (for information on defining a new material or material model see [Material
# Recipes](@ref).

material = PA2200(geometry)

# ### Boundary and Loads
#
# For the boundary conditions we will borrow some things from the boundary example
# module [HSS Boundary](@ref).

params = HSSParams(
    geometry;
    overheadPower=300.0,
    name="Overhead heat and cool",
)

# First we make the [`Types.AbstractProblemParams`](@ref) we will be using, a
# [`HSSParams`](@ref) struct (This includes way more than we need here, but it
# will still work. If you want to define a simpler struct have a look at [Problem
# Solver Recipes](@ref)).

skipper = 20
cooldownLoads = vcat(
    [HSSBound.loadOverheads(3.0, skipper) for _ in 1:2],
    [HSSBound.loadCooldown(3.0, skipper) for _ in 1:2],
)

# Next we make an array of the load conditions we want to simulate. For this
# example we will be putting all of our loads in the cooldown loads, as we aren't
# dealing with layers we don't need the build loads, and the preheat loads are run
# before any layers are deposited, so they can't really be used here.
#
# Put simply, this will simulate 1.5 minutes (3x30 seconds) of heating from the
# overhead heaters ([`HSSBound.loadOverheads`](@ref)) followed by 15 minutes
# of cooling ([`HSSBound.loadCooldown`](@ref)). The `skipper` is how often the
# results will be saved, here we are saying to only save one result for every 20
# time steps (See [Why We Skip Some Results](@ref) for more information on why).
#
# ### Initial Conditions
#
# Next up is the initial results. Before we define them, we'll make life a little
# easier for ourselves by making a tuple to represent the simulation size (unlike
# the one we used earlier, this one is the simulation size in number of nodes,
# instead of in meters).

geomSize = (geometry.X, geometry.Y, geometry.Z)
init = Result(geomSize, 25.0, 0.0, 0.0, 0.0, 0)
initLay = geometry.Z

# The initial condition (made as a [`Result`](@ref)) here will set all the
# simulation to 25 °C and set the melt state and consolidation state to zero.
#
# ### Ink

inkArray = fill(material.eₚ, geomSize)
ink = Ink(inkArray, "No ink")

# We'll use the size tuple again to make an array to hold our [`Ink`](@ref)
# values. This array stores the emissivity for all the points in the simulation,
# as we are not printing any ink for this simulation we will just set it all to
# the powder's emissivity.

# ### Construct The Problem
#
# With everything set up the last step is to give it a little description, decide where to save the
# results to and then create the [`Problem`](@ref) (ignore the `geometry.Z`, we'll cover that in the
# [Tutorial 1: Full Build](@ref)).
#
# !!! note
#
#     The file path given here will save the results to the temporary directory on a Unix based
#     system. If you are using windows, or want to save the file elsewhere then you should change
#     the path.

file = tempname()
description = "A basic simulation to teach us how to use this package"
problem = Problem(;
    geometry=geometry,
    matProp=material,
    params=params,
    cooldownLoads=cooldownLoads,
    init=init,
    initLay=geometry.Z,
    ink=ink,
    file=file,
    description=description,
)

# ## Solving the Problem
#
# Now the complicated bit. We need to run the following:

resultFile, finalResult = problemSolver(problem)

# No really, that's it. That one line will solve your problems for you (well, your
# simulation problems). It might take a while, but once it starts solving the
# loads you should get some nice progress bars to reassure you that it hasn't just
# crashed.
#
# The `resultFile` returned is just the file path to read the results from, as the
# simulation results can get quite big in their uncompressed form they aren't all
# kept in memory (also why we set the skip to 20 earlier, otherwise the results
# would be 20x as big). However, the final time step is returned, captured here in
# the `finalResult` variable. Just in case you quickly need the end results.
#
# ## Inspecting the Results
#
# Now we have solved the problem, we should probably have a look at what the
# results were. Firstly we can get a good overview of the results using the

#src TODO: update when I've worked on post processing
