# Material Model

```@docs
Material
```

## PA2200

```@docs
Material.PA_κ
Material.PA_ρ
Material.PA_c
Material.PA_Mᵣ
Material.PA_Rᵣ
Material.PA_Hf
Material.PA_Hr
Material.PA_Ċ
Material.PA_eₚ
Material.PA_eᵢ
Material.PA_ε
```

## New Materials Using the Default Model

```@docs
MatProp
MatProp(::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any)
Material.Ċ_maker
```

## Modifying the Current Material Model

```@docs
Material.calcMatProps!(::AbstractResult, ::AbstractResult, ::Problem{T,Gh,Mp,R,OR,B}, ::Any) where {
    T<:Any,Gh<:Any,Mp<:AbstractMatProp,R<:Any,OR<:Any,B<:Any,
}
Material.meltUpdate
Material.meltUpdate(::Any,::Any,::Any,::Any,::AbstractMatProp)
Material.consUpdate
Material.consUpdate(::Any,::Any,::Any,::Any,::AbstractMatProp)
```

## Making a New Material Model

```@docs
Types.AbstractMatProp
Material.calcMatProps!
```
