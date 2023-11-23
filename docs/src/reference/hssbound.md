# HSS Boundary

```@docs
HSSBound
```

## Parameters

```@docs
HSSParams
```

## No Carriage Loads

```@docs
HSSBound.loadOverheads
HSSBound.loadCooldown
```

### Piston Boundaries

```@docs
HSSBound.AbstractPistonBoundary
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.AbstractPistonBoundary)
HSSBound.PistonBoundary
HSSBound.PistonBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.PistonCoolBoundary
HSSBound.PistonCoolBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

### Overhead Boundaries

```@docs
HSSBound.AbstractOverheadsBoundary
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.AbstractOverheadsBoundary)
HSSBound.OverheadsBoundary
HSSBound.OverheadsBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
HSSBound.OverheadsCoolBoundary
HSSBound.OverheadsCoolBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

## Carriage Loads

### Sinter Stroke

```@docs
HSSBound.loadSinterStroke
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.SinterBoundary)
HSSBound.SinterBoundary
HSSBound.SinterBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

### Recoating Stroke

```@docs
HSSBound.loadRecoatStroke
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.RecoatBoundary)
HSSBound.RecoatBoundary
HSSBound.RecoatBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

### Printing Stroke

```@docs
HSSBound.loadInkStroke
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.InkBoundary)
HSSBound.InkBoundary
HSSBound.InkBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

### Printhead Shadow Only Stroke

```@docs
HSSBound.loadBlankStroke
HSSBound.boundaryHeatTransferRate(::Any,::Any,::HSSBound.BlankBoundary)
HSSBound.BlankBoundary
HSSBound.BlankBoundary(::AbstractResult,::AbstractResult,::Problem{T,Gh,Mp,R,OR,B},::Types.LoadStep) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

## Utilities

```@docs
HSSBound.lampMaker
HSSBound.overheadTempFunc
HSSBound.coolingStart
```
