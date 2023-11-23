"""
Defines all of the propeties of the model, used as an input for the simulation.

See [`problemSolver`](@ref) for how to solve the problem.

# Fields
$(TYPEDFIELDS)

The problem load arrays default to nothing, so if they aren't set then that stage of the simulation
is skipped, see [`Types.Load`](@ref) for more information on these fields.

!!! note "Fun Fact"

    As all load sets are optional, you could technically define a problem with no loads, it just
    wouldn't really do anything.
"""

"""
$(TYPEDSIGNATURES)

The main function that is called to solve a simulation and the struct that
defines the problem to simulate.

Takes a fully defined problem and solves it, saving the solution to disk and returning the filename
where it is saved. See [`Problem`](@ref Problem(; kwargs...)) for how to define the problem.
"""
function problemSolver(problem::Problem)
    log_file = splitext(problem.file)[1] * ".log"
    logger = makeLogger(problem.options.debug, log_file)

    with_logger(logger) do
        @debug "Starting Problem: $(problem)" _group = "core"

        println("Starting simulation: Results will be saved to $(problem.file)")

        jldopen(problem.file, "a+"; compress=problem.options.compress) do file
            startMetadata(problem, file)
            return
        end

        result = problem.init
        layerNum = problem.initLay

        # Solve all of the load sets
        for loadSet in problem.loadSets
            result, layerNum = loadSetSolver!(loadSet, result, layerNum, problem)
        end

        # Save the user defined results and some final metadata
        jldopen(problem.file, "a+"; compress=problem.options.compress) do file
            folder = file["Results"]
            otherResults(problem, folder)
            return
        end
        jldopen(problem.file, "a+"; compress=problem.options.compress) do file
            finishMetadata(problem, file)
            return
        end

        println("Results saved to $(problem.file)")
        if problem.options.notify
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
    file["Description"] = Types.makeDescription(problem)
    file["Input"] = problem
    file["Start_Time"] = string(now())
    return
end

"""
$(TYPEDSIGNATURES)

Adds metadata to the results file. The data added here is stuff that is not available until the end
of the simulation, such as the melt max array, the results index array and the simulation end time.
"""
function finishMetadata(problem::Problem, file)
    file["Results_Index"] = problem.resultsIndex
    file["Finish_Time"] = string(now())
    return
end
