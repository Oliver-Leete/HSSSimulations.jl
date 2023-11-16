# Solver

```@docs
Solver
```

## External

```@docs
Solver.makeLogger
Solver.loadSetSolver!
Types.AbstractLoadSet
Solver.loadSetSolver!(::FixedLoadSet,::AbstractResult,::Int,::Problem{T,Gh,Mp,R,OR,B}) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
Solver.loadSetSolver!(::LayerLoadSet,::AbstractResult,::Int,::Problem{T,Gh,Mp,R,OR,B}) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

## Internal

```@docs
innerLoadSetSolver!
Solver.fdmSolver!
Solver.timeSolver!
Solver.nanfiller!
Solver.loadSolver!
Types.makeDescription
Solver.startMetadata
Solver.finishMetadata
```
