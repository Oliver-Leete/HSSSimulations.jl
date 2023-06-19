# Problem Solver Recipes

## A Problem Solver That Waits For a Bed Temperature Before Starting the Build

For when the default problem solver isn't enough it is always possible to make
your own.

For this example we will make a problem solver that stops the machine's preheat
when a certain top surface temperature has been reached, instead of waiting a
set amount of time. As loads are defined as being a fixed time length this can't
be done with the standard logic.

The new problem solver function:

```julia
function tempWaitProblemSolver(problem::Problem, targetLower, targetUpper)
    G = GVars(problem)
    HSSSimulations.startMetadata(problem)

    prevResult = problem.init
    start = problem.initLay
    finish = problem.geometry.Nₗ

    while targetLower < mean(prevResult.T[:, :, end]) < targetUpper
        prevResult = loadSetSolver!(LayerPreheatLoadSet(problem.preheatLoads, start), prevResult, G)
    end

    for i in start:finish
        prevResult = loadSetSolver!(BuildLoadSet(problem.buildLoads, i), prevResult, G)
    end

    loadSetSolver!(CooldownLoadSet(problem.cooldownLoads, i), prevResult, G)

    return HSSSimulations.startMetadata(problem, G)
end
```

## Breaking It Down

The first thing we need to do is make a [`Types.GVars`](@ref) struct, this is
to store all the global (to the simulation) variables that are passed around
throughout the simulation.

At this point we might want to add some metadata to the results file.
This can be done using any method for saving to `.jld2` files, but here
we will just borrow the internal function that is used in the default
problem solver, [`Solver.startMetadata`](@ref). The matching function
([`Solver.finishMetadata`](@ref))

```julia
G = HSSSimulations.GVars(problem)
HSSSimulations.startMetadata(problem)
```

Each time we want to solve a load set, we just call the
[`Solver.loadSetSolver!`](@ref) function. It takes three arguments, the
[`Types.AbstractLoadSet`](@ref) struct to solve, the initial conditions for the
load set (in the form of a [`Result`](@ref) struct) and the `GVars` struct we
made before.

In reverse order from the function above, we can see calls to solve a single
load set, a load set per layer in the build or repeated calls to solve the same
load set until a condition is met.

```julia
loadSetSolver!(CooldownLoadSet(problem.cooldownLoads, i), prevResult, G)

for i in start:finish
    prevResult = loadSetSolver!(BuildLoadSet(problem.buildLoads, i), prevResult, G)
end

while targetLower < mean(prevResult.T[:, :, end]) < targetUpper
    prevResult = loadSetSolver!(LayerPreheatLoadSet(problem.preheatLoads, start), prevResult, G)
end
```

## A Problem Solver That Waits For a Bed Temperature Before Starting Each Layer

To emulate the behaviour of a machine waiting after each layer until the bed
temperature has stabilised.

This function moves the wait for temperature logic into the layer loop, to
allow for simulations of machines that follow do this. To do this a new
[`Types.AbstractLoadSet`](@ref) needs to be defined (see [Load Set Types](@ref
loadsettype) on how `WaitLoadSet` was made). As there is no default field in the
problem struct to store wait loads, here we are instead passing them straight
into our problem solver function as the `waitLoads` parameter.

```julia
function layerTempWaitProblemSolver(problem::Problem, targetLower, targetUpper, waitLoads)
    G = GVars(problem)
    HSSSimulations.startMetadata(problem)

    start = problem.initLay
    finish = problem.geometry.Nₗ
    prevResult = problem.init

    for i in start:finish
        while targetLower < mean(prevResult.T[:, :, end]) < targetUpper
            prevResult = loadSetSolver!(WaitLoadSet(waitLoads, i), prevResult, G)
        end
        prevResult = loadSetSolver!(BuildLoadSet(problem.buildLoads, i), prevResult, G)
    end

    loadSetSolver!(CooldownLoadSet(problem.cooldownLoads, i), prevResult, G)

    HSSSimulations.startMetadata(problem, G)
    println("Results saved to $(problem.file)")
    return problem.file
end
```
