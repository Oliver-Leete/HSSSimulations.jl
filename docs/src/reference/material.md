# Material Model

```@docs
Material
```

## PA2200

Provided is an example material property structs based on EOS's PA2200 powder.
Calling it with no arguments will return the relevant [`MatProp`](@ref) struct.

The sources of the data used are summarized below. For more details, check the
material model chapter of my thesis.

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

The default material model behaviour can be used to simulate similar
materials by simply changing the contents of the [`MatProp`](@ref) struct. The
[PA2200](@ref) section should provide some ideas on how to measure these values.

```@docs
MatProp
MatProp(::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any,::Any)
Material.PA_Ċ_maker
```

## Modifying the Current Material Model

The melt state updater and consolidation state updater of the default material
model can be modified separately from the [`Material.calcMatProps!`](@ref)
function itself. The default methods are shown below. An example of this can be
seen in [Tutorial 3: A Melt Rate Based Material Model](@ref).

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

If more customisation is needed, the entire [`Material.calcMatProps!`](@ref)
function can be replaced. [A Basic Material Model](@ref) gives an example of
this.

```@docs
Types.AbstractMatProp
Material.calcMatProps!
```
