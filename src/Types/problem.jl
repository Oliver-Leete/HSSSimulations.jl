"""
$(TYPEDEF)
An internal struct used for passing the many variables around the different function, it is built
from a given problem struct, using a constructor in the problem module. There is probably a better
way of doing this, but it works.

# Fields
$(TFIELDS)
"""
struct Problem{
    T<:AbstractArray,
    Gh<:AbstractArray,
    M<:AbstractMatProp,
    R<:AbstractResult,
    OR<:AbstractOtherResults,
    P<:AbstractProblemParams,
}
    "Simulation geometry. [`Geometry`](@ref)"
    geometry::Geometry
    "Simulation material properties. [`AbstractMatProp`](@ref)"
    matProp::M
    "Parameters used for boundary conditions. [`AbstractProblemParams`](@ref)"
    params::P
    "List of all load sets to run. [`AbstractLoadSet`](@ref)"
    loadSets::Vector{AbstractLoadSet}
    "Results struct used to save data only once at the end. [`AbstractOtherResults`](@ref)"
    otherResults::OR
    "Initial results. [`AbstractResult`](@ref)"
    init::R
    "The thickness of powder to use for preheat loads, given in number of layers thick"
    initLay::Int

    "Matrix of final emissivities. [`Ink`](@ref)"
    ink::Ink
    "Matrix of current emissivities"
    eᵗ::T

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

    "index of results file"
    resultsIndex::Vector{String}

    "File name"
    file::String
    "A short description of what is being simulated. To help remember what the simulation results are about"
    description::String
    "Simulation options"
    options::Options

    @doc """
    $(TYPEDSIGNATURES)

    Assemble a problem out of its components.

    # Arguments
      - `geometry::`[`Geometry`](@ref): See [Simulation Geometry](@ref)
      - `matProp::`[`AbstractMatProp`](@ref): See [Materials](@ref)
      - `params::`[`AbstractProblemParams`](@ref): See [Boundary Parameters](@ref)
      - `loadSets::Vector{`[`AbstractLoadSet`](@ref)`}`: The list of load sets to simulate, in order
          that the need simulating. See [Boundary Loads](@ref)
      - `ink::`[`Ink`](@ref): The locations for ink deposition. This should be the same size as the
          finial dimension of the simulation. See [Ink Struct](@ref)
      - `init::`[`AbstractResult`](@ref): The initial results struct. This should be the same size
          as the finial dimension of the simulation. See [Time Step Results](@ref)
      - `initLay::Int`: The thickness of powder deposited before the simulation starts, given in
          number of layers thick. This must be greater than zero
      - `file::String`: The file path and name for the output file of the simulation
      - `description::String=""`: A short description of what is being simulated
      - `otherResults::`[`AbstractOtherResults`](@ref)`=`[`OtherResults`](@ref)`()`: The struct to
          save the final results to. See [Other Results](@ref)
      - `options::`[`Options`](@ref)`=Options()`: The options to use for the simulation. See
          [Settings](@ref)
    """
    function Problem(;
        geometry::Geometry,
        matProp::AbstractMatProp,
        params::AbstractProblemParams,
        loadSets::Vector{AbstractLoadSet},
        init::AbstractResult,
        file::String,
        initLay::Int=1,
        ink::Ink=Ink(fill(matProp.eₚ, geometry.size), "Empty"),
        description::String="",
        otherResults::AbstractOtherResults=OtherResults(),
        options::Options=Options(),
    )
        Fx = zeros(geometry.size)
        Fy = zeros(geometry.size)
        Fz = zeros(geometry.size)
        κ = zeros(geometry.size)
        Tᵗ⁻¹ = OffsetArray(zeros(geometry.size .+ 2), -1, -1, -1)
        eᵗ = fill(matProp.eₚ, geometry.size)

        resultsIndex = Vector{String}()

        return new{
            typeof(Fx),
            typeof(Tᵗ⁻¹),
            typeof(matProp),
            typeof(init),
            typeof(otherResults),
            typeof(params),
        }(
            geometry,
            matProp,
            params,
            loadSets,
            otherResults,
            init,
            initLay,
            ink,
            eᵗ,
            Fx,
            Fy,
            Fz,
            κ,
            Tᵗ⁻¹,
            resultsIndex,
            file,
            description,
            options,
        )
    end
end

Base.show(io::IO, problem::Problem) = print(io, makeDescription(problem))
"""
$(TYPEDSIGNATURES)

Primaraly used for the show method for the Problem struct, but seperated into it's own function so
the same formatting can be used for making a string to save to the results file. This is useful
for having a summary of the simulation setup attached to the results for quick reference (The full
problem struct is also saved, but that requires loading the results in a julia instance to read
properly).
"""
function makeDescription(problem::Problem)
    rs = """
    ----------------------
    Simulation $(basename(problem.file))
    ----------------------
    $(problem.description)

    Geometry: $(problem.geometry.name)
    Material Propeties: $(problem.matProp.name)
    Machine Boundaries: $(problem.params.name)
    Ink Pattern: $(problem.ink.name)
    Preheat Thickness in Layers: $(problem.initLay)
    """
    for loadSet in problem.loadSets
        rs *= "\n"
        rs *= "$(loadSet.name) Loads:"
        rs *= "$(loadSet.loads)"
    end
    return rs
end
