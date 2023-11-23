# Solver

```@docs
Solver
```

All the public functions in this module have been covered already in the [main
API section](@ref main_api_solver), and the [Load Sets](@ref) section.

## Internal

```@docs
Solver.makeLogger
```

### Load Step Solver

```@docs
Solver.loadSolver!
```

### Time Step Solver

```@docs
Solver.timeSolver!
Solver.nanfiller!
Solver.fdmSolver!
```

### Metadata Saving

```@docs
Solver.startMetadata
Solver.finishMetadata
Types.makeDescription
```
