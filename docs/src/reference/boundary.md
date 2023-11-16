# Boundary Model

```@docs
Boundary
```

## External

```@docs
Types.AbstractProblemParams
Types.boundaryHeatTransferRate
Types.AbstractBoundary
Boundary.SymetryBoundary
Boundary.boundaryHeatTransferRate(::Any,::Any,::SymetryBoundary)
Boundary.ConductionBoundary
Boundary.boundaryHeatTransferRate(::Any,::Any,::ConductionBoundary)
Boundary.conductionFlow
Boundary.ConvectionBoundary
Boundary.boundaryHeatTransferRate(::Any,::Any,::ConvectionBoundary)
Boundary.convectionFlow
Boundary.radiationFlow
```

```@docs
Boundary.Load()
Types.Load
```

## Utilities

```@docs
Boundary.movingObjOverlap
Boundary.recoating!
```

## Internal

```@docs
Boundary.calcInds
Boundary.padWithGhost!
Boundary.updateInds!
Boundary.ghostCalc!
Boundary.boundaryTemp
Boundary.σ
```
