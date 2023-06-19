"""
$(TYPEDSIGNATURES)

Solves a single load and returns an array of the results.
"""
function loadSolver!(ls::Types.LoadStep, results, G::GVars)
    @debug "Starting loadStep $(ls.name) t=$(ls.time.tₛ)" _group = "core"

    # Obey the progress bar option
    waitTime = if G.options.showProgress == true
        0.5
    elseif G.options.showProgress == false
        Inf
    else
        G.options.showProgress
    end

    pts::typeof(ls.init) = ls.init
    resConstruct = constructorof(typeof(ls.init))

    # Nothing beats a pretty bar to reassure you that something is actually happening
    @showprogress waitTime ls.name for i in eachindex(ls.time.times)
        if ls.time.times[i] in ls.time.unskipTimes
            # for unskipped loads, use the relevant index into the Results struct
            iᵣ = findfirst(==(ls.time.times[i]), ls.time.unskipTimes)
            timeSolver!(results[iᵣ], pts, ls, G)
            pts = results[iᵣ]
        else
            # for skipped nodes simply use an empty Result struct that won't be saved
            cts = resConstruct(ls.size, ls.time.times[i], ls.time.tₚ[i])
            timeSolver!(cts, pts, ls, G)
            pts = cts
        end
    end

    return pts
end
