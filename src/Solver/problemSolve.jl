"""
Defines all of the propeties of the model, used as an input for the simulation.

See [`problemSolver`](@ref) for how to solve the problem.

# Fields
$(TFIELDS)

The problem load arrays default to nothing, so if they aren't set then that stage of the simulation
is skipped, see [`Types.Load`](@ref) for more information on these fields.

!!! note "Fun Fact"

    As all load sets are optional, you could technically define a problem with no loads, it just
    wouldn't really do anything.
"""
Base.@kwdef struct Problem
    "See [`Geometry`](@ref)"
    geometry::Geometry
    "See [`MatProp`](@ref)"
    matProp::AbstractMatProp
    "See [`Types.AbstractProblemParams`](@ref)"
    params::AbstractProblemParams
    "List of all load sets to run"
    loadSets::Vector{AbstractLoadSet}
    "The initial conditions. See [`Result`](@ref)"
    init::AbstractResult
    "The thickness of powder to use for preheat loads, given in number of layers thick"
    initLay::Int
    "Results struct used to save data only once at the end"
    otherResults::AbstractOtherResults = otherResults()
    "See [`Ink`](@ref)"
    ink::Ink
    "The filepath to save the results to"
    file::String
    "See [`Options`](@ref)"
    options::Options = Options()
    "A short description of what is being simulated. To help remember what the simulation results are about"
    description::String
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

"""
$(TYPEDSIGNATURES)

Make an instance of [`Types.GVars`](@ref) from a [`Problem`](@ref).
"""
function Types.GVars(problem::Problem)
    geomSize = (problem.geometry.X, problem.geometry.Y, problem.geometry.Z)
    Fx = zeros(geomSize)
    Fy = zeros(geomSize)
    Fz = zeros(geomSize)
    κ = zeros(geomSize)
    Tᵗ⁻¹ = OffsetArray(zeros(geomSize .+ 2), -1, -1, -1)
    eᵗ = fill(problem.matProp.eₚ, geomSize)

    resultsIndex = Vector{String}()

    return GVars{
        typeof(Fx),
        typeof(Tᵗ⁻¹),
        typeof(problem.matProp),
        typeof(problem.init),
        typeof(problem.otherResults),
        typeof(problem.params),
    }(;
        geometry     = problem.geometry,
        matProp      = problem.matProp,
        params       = problem.params,
        ink          = problem.ink,
        file         = problem.file,
        init         = problem.init,
        otherResults = problem.otherResults,
        κ            = κ,
        Tᵗ⁻¹         = Tᵗ⁻¹,
        Fx           = Fx,
        Fy           = Fy,
        Fz           = Fz,
        eᵗ           = eᵗ,
        resultsIndex = resultsIndex,
        options      = problem.options,
    )
end

"""
$(TYPEDSIGNATURES)

The main function that is called to solve a simulation and the struct that
defines the problem to simulate.

Takes a fully defined problem and solves it, saving the solution to disk and returning the filename
where it is saved. See [`Problem`](@ref) for how to define the problem.
"""
function problemSolver(problem::Problem)
    log_file = splitext(problem.file)[1] * ".log"
    logger = makeLogger(problem.options.debug, log_file)

    with_logger(logger) do
        @debug "Starting Problem: $(problem)" _group = "core"

        G = GVars(problem)
        println("Starting simulation: Results will be saved to $(problem.file)")

        jldopen(G.file, "a+"; compress=G.options.compress) do file
            startMetadata(problem, file)
            return
        end

        result = problem.init
        layerNum = problem.initLay

        # Solve all of the load sets
        for loadSet in problem.loadSets
            result, layerNum = loadSetSolver!(loadSet, result, layerNum, G)
        end

        # Save the user defined results and some final metadata
        jldopen(G.file, "a+"; compress=G.options.compress) do file
            folder = file["Results"]
            otherResults(G, folder)
            return
        end
        jldopen(G.file, "a+"; compress=G.options.compress) do file
            finishMetadata(G, file)
            return
        end

        println("Results saved to $(problem.file)")
        if G.options.notify
            alert(
                """
                Simulation Finished!
                $(problem.description)
                """,
            )
        end

        return problem.file, result
    end
end

"""
$(TYPEDSIGNATURES)

Adds metadata to the results file. The data added here is stuff that is available at the start of
the simulation, such as the problem description, the problem input and the start time.
"""
function startMetadata(problem, file)
    file["Description"] = makeDescription(problem)
    file["Input"] = problem
    file["Start_Time"] = string(now())
    return
end

"""
$(TYPEDSIGNATURES)

Adds metadata to the results file. The data added here is stuff that is not available until the end
of the simulation, such as the melt max array, the results index array and the simulation end time.
"""
function finishMetadata(G::GVars, file)
    file["Results_Index"] = G.resultsIndex
    file["Finish_Time"] = string(now())
    return
end
