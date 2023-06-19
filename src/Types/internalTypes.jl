"""
$(TYPEDEF)
An internal struct used for passing the many variables around the different function, it is built
from a given problem struct, using a constructor in the problem module. There is probably a better
way of doing this, but it works.

# Fields
$(TFIELDS)
"""
Base.@kwdef struct GVars{
    T<:AbstractArray,
    Gh<:AbstractArray,
    M<:AbstractMatProp,
    R<:AbstractResult,
    OR<:AbstractOtherResults,
    P<:AbstractProblemParams,
}
    "Simulation geometry"
    geometry::Geometry
    "Simulation material properties"
    matProp::M
    "Parameters used for boundary conditions"
    params::P
    "Matrix of x axis Fourier numbers"
    Fx::T
    "Matrix of y axis Fourier numbers"
    Fy::T
    "Matrix of z axis Fourier numbers"
    Fz::T
    "Matrix of thermal conductivities"
    κ::T
    "Ghost node padded matrix of previous time step"
    Tᵗ⁻¹::Gh
    "Matrix of current emissivities"
    eᵗ::T
    "Matrix of final emissivities"
    ink::Ink
    "File name"
    file::String
    "Initial results"
    init::R
    "Results struct used to save data only once at the end"
    otherResults::OR
    "index of results file"
    resultsIndex::Vector{String}
    "Simulation options"
    options::Options
end

"""
$(TYPEDEF)
Contains all of the time information for a LoadStep.

# Fields
$(TFIELDS)
"""
struct LoadTime
    "Time between time steps"
    Δt::Float64
    "Array of all of the times in the load step"
    times::Vector{Float64}
    "Array of all none skipped times in the load step"
    unskipTimes::Vector{Float64}
    "Array of percentage through timestep, same index as times"
    tₚ::Vector{Float64}
    "Array of percentage through timestep, same index as unskipTimes"
    utₚ::Vector{Float64}
    "The time at the start of the load step"
    tₛ::Float64
    "Time step end time"
    tₑ::Float64
end

"""
$(TYPEDSIGNATURES)

Default Constructor for [`LoadTime`](@ref).

# Arguments

  - `tₛ::Float64`: The time at the start of the load step
  - `tₗ`: The lenght of the load step
  - `Δt::Float64`: Time between time steps
  - `skip`: How often to save results. See [Why We Skip Some Results](@ref)

"""
function LoadTime(tₛ, tₗ, Δt, skip)
    tₑ = tₛ + tₗ
    tₛ = tₛ + Δt
    times = Array(tₛ:Δt:tₑ)
    skipTimes = times[1:skip:end]
    tₚ = [i / length(times) for i in 1:length(times)]
    utₚ = tₚ[1:skip:end]
    return LoadTime(Δt, times, skipTimes, tₚ, utₚ, tₛ, tₑ)
end

"""
$(TYPEDEF)

An internal struct for the propeties that are constant within a load step.

# Fields
$(TFIELDS)
"""
Base.@kwdef struct LoadStep{R<:AbstractResult}
    "See [`LoadTime`](@ref)"
    time::LoadTime
    """The x, y and z size in number of nodes (mostly just used for the z,
    which may have changed from the same value in the `GVars.geometry` variable) """
    size::Tuple{Int,Int,Int}
    "See [`Indices`](@ref)"
    ind::Indices
    "See [`Load`](@ref)"
    load::Load
    "The initial results for the load. See [`AbstractResult`](@ref)"
    init::R
    "Used for the progress meter"
    name::String
    """Used for any `Load` functions that need the layer number. For preheat
    and cooldown load sets this will be the initial thickness or the finial thickness in layers
    respectively."""
    layerNum::Int
end
