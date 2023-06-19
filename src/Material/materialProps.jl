"""
$(TYPEDEF)
The default implementation of [`AbstractMatProp`](@ref) used by the default
[`Material.calcMatProps!`](@ref) method. See [Material Examples](@ref) for some premade materials.
The arguments to its constructor are the same as the matching fields. The only addition is the
geometry argument, which should just be the [`Geometry`](@ref) struct of for the simulation.

!!! warning

    The maximum melt state is never reset, so if a node goes from the melt region to the
    recrystalisation region more than once in a simulation, the behaviour might not be modeled
    properly.

# Fields
$(TFIELDS)
"""
struct MatProp{T1,T2,T3,T4,T5,T6,T7,T8,T9} <: AbstractMatProp
    """ Density.
    Two dimensional interpolations, with inputs in axis 1 = consolidation state, axis 2 = melt state.
    """
    ρ::T1
    """ Specific heat capacity.
    One dimensional interpolations with the node's temperature as it's input.
    """
    c::T2
    """ Thermal conductivity.
    Three dimensional interpolations, with inputs in axis 1 = consolidation state, axis 2 = temperature and axis 3
    = melt state.
    """
    κ::T3
    """ Melting range and temp relationship.
    A 1d interpolation, with the only input axis being the temperature and the output is the melt state.
    """
    Mᵣ::T4
    "The start temperature of the melt range"
    Mₛ::Float64
    "The end temperature of the melt range"
    Mₑ::Float64
    """ Crystallisation range and temp relationship.
    A 2d interpolation, with the first input axis being the node temperature and the second input axis
    being the maximum melt state reached. The output is the melt state.
    """
    Rᵣ::T5
    "The start temperature of the recrystalisation range"
    Rₛ::Float64
    "The end temperature of the recrystalisation range"
    Rₑ::Float64
    "Total specific heat of melting"
    Hf::T6
    """ Total specific heat of fusion.
    A 1d Interpolation where the input is the maximum melt state reached and the output is the total
    heat of fusion.
    """
    Hr::T7
    """ Consolidation rate.
    Either a single value representing a constant consolidation rate, or a 2d interpolation, with the
    first axis being the node temperature and the second being the node melt state. The output is the
    rate of change of sinter state.
    """
    Ċ::T8
    """ Emmisivity of the powder.
    This is the emmisivity relative to the lamp. So the emmisivity over the range of the wavelengths
    that the lamp outputs, scaled by the relative output power of the lamp at those wavelengths.
    """
    eₚ::Float64
    """ Emmisivity of the powder with ink on it.
    This is the emmisivity relative to the lamp. So the emmisivity over the range of the wavelengths
    that the lamp outputs, scaled by the relative output power of the lamp at those wavelengths.
    """
    eᵢ::Float64
    " Black body emmisivity of the powder"
    ε::Float64
    "Just used for future reference"
    name::String
    "Used by the material model to track the maximum melt state reached per node"
    Mₘ::T9
end

"""
$(TYPEDSIGNATURES)

Default constructor for [`MatProp`](@ref).

"""
function MatProp(ρ, c, κ, Mᵣ, Rᵣ, Hf, Hr, Ċ, eₚ, eᵢ, ε, name, geometry)
    geomSize = (geometry.X, geometry.Y, geometry.Z)
    Mₛ, Mₑ = bounds(Mᵣ.itp)[1][1], bounds(Mᵣ.itp)[1][2]
    Rₛ, Rₑ = bounds(Rᵣ.itp)[1][1], bounds(Rᵣ.itp)[1][2]
    Mₘ = zeros(geomSize)

    return MatProp{
        typeof(ρ),typeof(c),typeof(κ),
        typeof(Mᵣ),typeof(Rᵣ),
        typeof(Hf),typeof(Hr),typeof(Ċ),
        typeof(Mₘ),
    }(
        ρ, c, κ,
        Mᵣ, Mₛ, Mₑ,
        Rᵣ, Rₛ, Rₑ,
        Hf, Hr, Ċ,
        eₚ, eᵢ, ε,
        name,
        Mₘ,
    )
end

"""
    calcMatProps!(::AbstractResult, ::AbstractResult, <:Problem, ::Indices)

Updates any of the material properties that change, along with the Fourier number for the current
time step. New methods can be defined by dispatching on `Problem` with a different subtype of
MatProp (for more information on this, see [`Types.AbstractMatProp`](@ref)). The two main functions
called by this one, [`meltUpdate`](@ref) and [`consUpdate`](@ref), are both also dispatched on the
type of the material property struct, so they can be overwritten individually for a new material
property struct if the new material model only needs to change some of the behaviour.

# Arguments

  - `cts`: Current time step results
  - `pts`: Previous time step results
  - `ind`: The indicies to update
"""
function calcMatProps! end

"""
$(TYPEDSIGNATURES)

The default material model, designed to be used with [`MatProp`](@ref), but should work with any
[`Types.AbstractMatProp`](@ref) that shares [`MatProp`](@ref)'s `ρ`, `c`, `κ` and `Mₘ` fields. 

Updates melt and consolidation state, and then uses those to update the density, heat capacity and
conductivity. These are then used to calculate the Fourier number for each axis for this time step.
"""
function calcMatProps!(
    pts::AbstractResult,
    cts::AbstractResult,
    prob::Problem{T,Gh,Mp,R,OR,B},
    ind,
) where {T<:Any,Gh<:Any,Mp<:AbstractMatProp,R<:Any,OR<:Any,B<:Any}
    mp = prob.matProp
    (; Δx, Δy, Δz, Δt) = prob.geometry
    (; M, C) = cts

    Threads.@threads for i in ind
        # Update melt state and consolidation states
        M[i], mp.Mₘ[i], Δh = meltUpdate(pts.M[i], pts.T[i], mp.Mₘ[i], Δt, mp)
        C[i] = consUpdate(pts.C[i], M[i], pts.T[i], Δt, mp)

        # Update the material properties for the node
        ρ = mp.ρ(C[i], M[i])
        prob.κ[i] = mp.κ(C[i], pts.T[i], M[i])
        c = mp.c(pts.T[i])

        # Adjust the temperature of the node at the previous time step based on the change in melt
        # state. When this function is called as part of the recoating, the temperatures that are
        # used for the calculation have already been copied, so this change doesn't effect anything.
        ΔT = Δh / c
        pts.T[i] = pts.T[i] - ΔT

        # Calculate the Fourier number (via diffusivity)
        α = prob.κ[i] / (ρ * c)
        prob.Fx[i] = α * (Δt / (Δx^2))
        prob.Fy[i] = α * (Δt / (Δy^2))
        prob.Fz[i] = α * (Δt / (Δz^2))
    end
    @debug "material properties" _group = "mat" prob.Fx[ind[end]] prob.Fy[ind[end]] prob.Fz[ind[end]] prob.κ[ind[end]] cts.M[ind[end]] cts.C[ind[end]]
    return
end

"""
    meltUpdate(Mᵗ⁻¹, T, Mₘ, Δt, mp::AbstractMatProp) -> Mᵗ, Mₘ, Δh

Calculates the new melt state of a single node. It is given the melt state and temperature of the
node in the previous time step, the maximum melt state the node has reached so far, the duration of
the current time step and the material property struct.

It should return the new melt state for the node, the new maximum melt state, and the specific
enthalpy change due to fusion or recrystalisation that is associated with the change in melt state.
"""
function meltUpdate end

"""
$(TYPEDSIGNATURES)

Updates the melt state of a node if the temperature of the node is in the melting or crystalisation
termperature range if not the existing value is returned. This uses a basic time independent model
that associates a single melt state to a given combination of temperature and maximum melt state
reached so far.
"""
function meltUpdate(Mᵗ⁻¹, T, Mₘ, _, mp::AbstractMatProp)
    Δh = 0.0
    Mᵗ = Mᵗ⁻¹

    if T > mp.Mₛ
        Mᵗ = mp.Mᵣ(T) ∨ Mᵗ⁻¹
        Δh = (Mᵗ - Mᵗ⁻¹) * mp.Hf
        Mₘ = Mᵗ ∨ Mₘ
    end

    if Mᵗ > 0.0 && T < mp.Rₑ
        M = mp.Rᵣ(T, Mₘ)
        if M < Mᵗ
            Mᵗ = M
            Δh = (Mᵗ - Mᵗ⁻¹) * mp.Hr(Mₘ)
        end
    end

    return Mᵗ, Mₘ, Δh
end

"""
    consUpdate(C, M, T, Δt, mp::AbstractMatProp) -> C

Calculates the new consolidation state of a single node. It is given the current consolidation
state, melt state and temperature of the node, the duration of the current time step and the
material property struct.
"""
function consUpdate end

"""
$(TYPEDSIGNATURES)

Updates the consolidation state of a node by adding the change in consolidation state (rate * time)
to the previous consolidation state. Only applies if the material is melted and not already fully
consolidated.

This finds the consolidation rate by calling `mp.Ċ` with `C`, `T` and `M` as arguments.

The returned values maximum is limited to 1.
"""
consUpdate(C, M, T, Δt, mp::AbstractMatProp) =
    if M == 0 || C == 1
        C
    else
        C = C + Δt * mp.Ċ(C, T, M)
        C ∧ 1.0
    end
