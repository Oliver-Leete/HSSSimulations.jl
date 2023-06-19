# Advanced API

```@meta
DocTestSetup = quote
    using HSSSimulations
end
```

These APIs are exported by their module, but not exported by the package, so to
use them you will need to either use their full address:

```@repl
using HSSSimulations
Solver.loadSetSolver!
```

or by using the module it is in:

```@repl
using HSSSimulations
using .Solver
loadSetSolver!
```

* * *

## Custom Load Sets

```@docs
Solver.loadSetSolver!
Types.AbstractLoadSet
Solver.FixedLoadSet
Solver.loadSetSolver!(::FixedLoadSet,::AbstractResult,::Int,::Problem{T,Gh,Mp,R,OR,B}) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
Solver.LayerLoadSet
Solver.loadSetSolver!(::LayerLoadSet,::AbstractResult,::Int,::Problem{T,Gh,Mp,R,OR,B}) where { T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

```@docs
innerLoadSetSolver!
```

```@docs
```

```@docs
```

## Custom Materials

```@docs
MatProp
MatProp(::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any)
```

### Custom Material Models

```@docs
Types.AbstractMatProp
Material.calcMatProps!
Material.calcMatProps!(::AbstractResult, ::AbstractResult, ::Problem{T,Gh,Mp,R,OR,B}, ::Any) where {
    T<:Any,Gh<:Any,Mp<:AbstractMatProp,R<:Any,OR<:Any,B<:Any,
}
Material.meltUpdate
Material.meltUpdate(::Any,::Any,::Any,::Any,::AbstractMatProp)
Material.consUpdate
Material.consUpdate(::Any,::Any,::Any,::Any,::AbstractMatProp)
Material.PA_Ċ_maker
```

## Custom Results

```@docs
Types.AbstractResult
Res.loadStepSaver
Res.loadStepSaver(::Any, ::StructVector{T}) where {T<:Result}
Types.AbstractOtherResults
Types.OtherResults
Res.otherResults
Res.otherResults(::Problem{T,Gh,Mp,R,OR,B}, ::Any) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```

## Custom Boundaries

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

## Logging

```@docs
Solver.makeLogger
```
