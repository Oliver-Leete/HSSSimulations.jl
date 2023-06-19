# Internal APIs

These are things exported from modules, but not intended for external use.

```@meta
DocTestSetup = quote
    using HSSSimulations
end
```

## Types

```@docs
Types.AbstractSimProperty
Types.Problem
Types.LoadTime
Types.LoadTime(::Any,::Any,::Any,::Any)
Types.LoadStep
Types.Indices
Types.Geometry
```

## Boundary

```@docs
Boundary.calcInds
Boundary.padWithGhost!
```
