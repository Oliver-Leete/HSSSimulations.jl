# Material Model Recipes

## A Basic Material Model

This material model just acts like a normal temperature dependent solid. Useful
for comparing against to see the impact of your model. As it does not save the
melt or consolidation state it can be combined with [Basic Results](@ref) to
save on storage space.

```julia
"""
A basic material model that doesn't include any melting or consolidation.

# Fields

  - `ρ, c, κ`: Density, Specific heat capacity and Thermal conductivity
  - `eₚ`: Emmisivity of the powder
    This is the emmisivity relative to the lamp. So the emmisivity over the range of the wavelengths
    that the lamp outputs, scaled by the relative output power of the lamp at those wavelengths.
  - `eₚ`: Emmisivity of the powder with ink on it
    This is the emmisivity relative to the lamp. So the emmisivity over the range of the wavelengths
    that the lamp outputs, scaled by the relative output power of the lamp at those wavelengths.
  - `Mₘ`: Used by the material model to track the maximum melt state reached per node.
"""
struct BasicMatProp{T1,T2,T3} <: Material.AbstractMatProp
    ρ::T1
    c::T2
    κ::T3
    eₚ::Float64
    eᵢ::Float64
    name::String
    Mₘ::Array{Float64,3}
end
```

```julia
function Material.calcMatProps!(
    pts::AbstractResult,
    cts::AbstractResult,
    prob::Problem{T,Gh,Mp,R,OR,B},
    ind,
) where {T<:Any,Gh<:Any,Mp<:BasicMatProp,OR<:Any,R<:Any,B<:Any}
    mp = prob.matProp
    (; Δx, Δy, Δz, Δt) = prob.geometry

    Threads.@threads for i in ind
        ρ = mp.ρ(0, 0)
        prob.κ[i] = mp.κ(0, pts.T[i], 0)
        c = mp.c(pts.T[i])

        α = prob.κ[i] / (ρ * c)
        prob.Fx[i] = α * (Δt / (Δx^2))
        prob.Fy[i] = α * (Δt / (Δy^2))
        prob.Fz[i] = α * (Δt / (Δz^2))
    end
    @debug "material properties" _group = "mat" prob.Fx[ind[end]] prob.Fy[ind[end]] prob.Fz[ind[end]] prob.κ[ind[end]]
    return
end
```
