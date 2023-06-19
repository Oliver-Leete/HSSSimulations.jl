# Problem Parameters Recipes

## A Variable Heat Flux Parameter Set

This parameter set is about as basic as it gets. It's made to be used alongside
the boundary defined in [A Variable Heat Flux Boundary](@ref) it just needs the
heat flux field to be set to a something that is callable.

```julia
struct VariableHeatFluxParams{T1} <: AbstractProblemParams
    heatflux::T1
end
```

As an example, here we make the parameter set with a function that defines the
heat flux to be 3 watts times the current time (so 10 seconds in, the heat flux would
be 30 watts).

```julia
VariableHeatFluxParams(t -> t * 3)
```
