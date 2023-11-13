# Boundary Model

```@docs
Boundary
```

## External

```@docs
Types.AbstractProblemParams
Types.boundaryHeatTransferRate
Boundary.boundaryHeatTransferRate(::Any,::Any,::SymetryBoundary)
Boundary.boundaryHeatTransferRate(::Any,::Any,::ConductionBoundary)
Boundary.boundaryHeatTransferRate(::Any,::Any,::ConvectionBoundary)
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.AbstractPistonBoundary)
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.AbstractOverheadsBoundary)
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.SinterBoundary)
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.RecoatBoundary)
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.InkBoundary)
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.BlankBoundary)
Types.AbstractBoundary
Boundary.conductionFlow
Boundary.convectionFlow
Boundary.radiationFlow
HSSBound.AbstractPistonBoundary
HSSBound.PistonBoundary
HSSBound.PistonBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.PistonCoolBoundary
HSSBound.PistonCoolBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.AbstractOverheadsBoundary
HSSBound.OverheadsBoundary
HSSBound.OverheadsBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.OverheadsCoolBoundary
HSSBound.OverheadsCoolBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.SinterBoundary
HSSBound.SinterBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.RecoatBoundary
HSSBound.RecoatBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.InkBoundary
HSSBound.InkBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.BlankBoundary
HSSBound.BlankBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.loadOverheads
```

```@docs
Boundary.Load()
Types.Load
```

### Basic Boundaries

```@docs
Boundary.SymetryBoundary
Boundary.ConductionBoundary
Boundary.ConvectionBoundary
```

### Utilities

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
