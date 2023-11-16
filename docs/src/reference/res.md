# Simulation Results

```@docs
Results
```

## Time/Load Step Results

```@docs
Types.AbstractResult
Results.loadStepSaver
Results.loadStepSaver(::Any, ::StructVector{T}) where {T<:Result}
```

## End of Simulation Results

```@docs
Types.AbstractOtherResults
Results.otherResults
Results.otherResults(::Problem{T,Gh,Mp,R,OR,B}, ::Any) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
```
