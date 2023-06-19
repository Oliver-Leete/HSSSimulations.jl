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

while targetLower < mean(prevResult.T[:, :, end]) < targetUpper
    prevResult = loadSetSolver!(LayerPreheatLoadSet(problem.preheatLoads, start), prevResult, prob)
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
    for i in start:finish
        while targetLower < mean(prevResult.T[:, :, end]) < targetUpper
            prevResult = loadSetSolver!(WaitLoadSet(waitLoads, i), prevResult, G)
        end
        prevResult = loadSetSolver!(BuildLoadSet(problem.buildLoads, i), prevResult, G)
    end
end
```
