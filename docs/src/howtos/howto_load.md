# Load Recipes

You might want to check out [`Load`](@ref)

## A Cooling Recoat Load and Load Set

This load will and load set use the boundary that we created in [A Cooling
Recoat Boundary](@ref)

### Loads

When making a load, we only need to define the boundaries that are
different from the default, any undefined boundaries are left as
[`SymetryBoundary`](@ref)s.

Well make a function to create a new [`Load`](@ref) that takes a time length and
a skip ([Why We Skip Some Results]@ref).

```julia
function loadRecoatCoolStroke(tₗ, skip)
    return Load(;
        # Lets give it a name we'll be able to recognise later
        name = "Cooldown Recoat",
        tₗ   = tₗ,
        skip = skip,
        # Set the bottom boundary
        z₁=PistonCoolBoundary,
        # Set the top boundary
        z₂=RecoatCoolBoundary,
    )
end
```

Well also make a matching load to go with the matching boundary from [A Cooling
Recoat Return Boundary](@ref).

```julia
function loadRecoatCoolReturnStroke(tₗ, skip)
    return Load(;
        name = "Cooldown Return",
        tₗ   = tₗ,
        skip = skip,
        z₁   = PistonCoolBoundary,
        z₂   = RecoatCoolReturnBoundary,
    )
end
```

### Load Set

The load sets that are given to the solver are actually just a list of loads.
So here we'll just make a function that returns a list of the loads we want.
This one works for a recoater that spends 7 seconds over the bed with one second
between each time it's over the bed.

```julia
function cooldownLoadSet(skip)
    return [
        # A load without any carriage movement to represent when the carriage
        # isn't above the bed
        loadCooldown(1.0, skip),
        loadRecoatStroke(7.0, skip),
        loadCooldown(1.0, skip),
        loadRecoatReturnStroke(7.0, skip),
        loadCooldown(1.0, skip),
    ]
end
```

If we wanted this to have custom behaviour in the problem we might want to
define a new [LoadSet type](@ref loadsettype) or if you want even more
complicated behaviour, have a look at [Problem Solver Recipes](@ref).
