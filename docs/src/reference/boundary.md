# Boundary Model

```@docs
Boundary
```

## Parameters

```@docs
Types.AbstractProblemParams
```

## Load Sets

These are not actually memebers of the [`Boundary`](@ref) module, but they are
an integral part of how the boundary conditions are set up for a simulation so
they are included here instead of in the [`Solver`](@ref) documentation.

```@docs
Types.AbstractLoadSet
Solver.loadSetSolver!
Solver.loadSetSolver!(::FixedLoadSet,::AbstractResult,::Int,::Problem{T,Gh,Mp,R,OR,B}) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
Solver.loadSetSolver!(::LayerLoadSet,::AbstractResult,::Int,::Problem{T,Gh,Mp,R,OR,B}) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
innerLoadSetSolver!
```

## Loads

```@docs
Boundary.Load()
Types.Load
```

## Boundary

```@docs
Types.boundaryHeatTransferRate
Types.AbstractBoundary
```

### Symmetry

```@docs
Boundary.SymetryBoundary
Boundary.boundaryHeatTransferRate(::Any,::Any,::SymetryBoundary)
```

### Conduction

```@docs
Boundary.ConductionBoundary
Boundary.boundaryHeatTransferRate(::Any,::Any,::ConductionBoundary)
Boundary.conductionFlow
```

### Convection

```@docs
Boundary.ConvectionBoundary
Boundary.boundaryHeatTransferRate(::Any,::Any,::ConvectionBoundary)
Boundary.convectionFlow
```

### Radiation

```@docs
Boundary.radiationFlow
```

## Utilities

```@docs
Boundary.movingObjOverlap
Boundary.recoating!
```

## Internals

```@docs
Boundary.calcInds
Boundary.padWithGhost!
Boundary.updateInds!
Boundary.ghostCalc!
Boundary.boundaryTemp
Boundary.σ
```
