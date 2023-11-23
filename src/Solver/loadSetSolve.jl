"""
    $(FUNCTIONNAME)(
        loadSet<:AbstractLoadSet
        initResult::AbstractResult,
        layerNum::Int,
        prob::Problem{T,Gh,Mp,R,OR,B},
    ) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}

This function is run once for each `LoadSet` passed in to the problem, and dispatched on the type
of that load set. For basic load sets, like [`FixedLoadSet`](@ref), it should basically just pass
the arguments on to the [`innerLoadSetSolver!`](@ref) function, the one exception being the list
of loads being passed in instead of the [`AbstractLoadSet`](@ref) struct. For more complicated
load sets, like [`LayerLoadSet`](@ref), this should include the logic used for that load set.
For [`LayerLoadSet`](@ref) this is a loop that loops over the list of loads once for each layer,
incrementing the layer number as it goes.

For examples see the source code for the two default implementations.
"""
function loadSetSolver! end
# TODO: Fill in the examples list above with the tutorial and recipes when they're done

"""
$(TYPEDEF)
#Fields
$(TYPEDFIELDS)
"""
struct FixedLoadSet <: AbstractLoadSet
    "Name of the load set"
    name::String
    "List of loads for load set"
    loads::Vector{Load}
end

"""
$(TYPEDSIGNATURES)
"""
function loadSetSolver!(
    loadSet::FixedLoadSet,
    initResult::AbstractResult,
    layerNum::Int,
    prob::Problem{T,Gh,Mp,R,OR,B},
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    name = "$(loadSet.name)-$(layerNum)"
    result = innerLoadSetSolver!(loadSet.loads, initResult, layerNum, prob; name=name)
    return result, layerNum
end

"""
$(TYPEDEF)
#Fields
$(TYPEDFIELDS)
"""
struct LayerLoadSet <: AbstractLoadSet
    "Name of the load set"
    name::String
    "The last layer to deposit as part of this load set"
    finishLayer::Int
    "List of loads for load set"
    loads::Vector{Load}
end

"""
$(TYPEDSIGNATURES)
"""
function loadSetSolver!(
    loadSet::LayerLoadSet,
    initResult::AbstractResult,
    initLayerNum::Int,
    prob::Problem{T,Gh,Mp,R,OR,B},
) where {T<:Any,Gh<:Any,Mp<:Any,R<:Any,OR<:Any,B<:Any}
    result = initResult
    for layerNum in (initLayerNum+1):loadSet.finishLayer
        name = "$(loadSet.name)-$(layerNum)"
        result = innerLoadSetSolver!(
            loadSet.loads,
            result,
            layerNum,
            prob;
            name=name,
            recoat=true,
            prevLayerNum=layerNum - 1,
        )
    end
    return result, loadSet.finishLayer
end

"""
$(TYPEDSIGNATURES)

Solves a load set of a problem, iterating over and solving the loads in the given load set in order.
The results for a load is saved to the file after solving it.

If the list of loads passed given include powder deposition, the `recoat` kwarg should be set to
true, with the `layerNum` set to the thickness of the powder bed in layers that is desired at the
end of the loads. If this is more than one layer thicker than the previous value, then the previous
values should also be passed in to `prevLayerNum`.

It also helps to provide a unique name. This is the name that will be used to store the results from
runnning the list of loads in the output file, and also will be used as the label in the progress
meter. If no name is given then the current time is used instead. If the name given is not unique
then you will get a run time error when it tries to save results to a place that is already taken.
"""
function innerLoadSetSolver!(
    loads::Vector{Load},
    initResult::AbstractResult,
    layerNum,
    prob::Problem;
    name=Date.time(),
    recoat=false,
    prevLayerNum=layerNum - recoat,
)
    @debug "Starting Load Set t=$(name)" _group = "core"

    resultSize = (prob.geometry.X, prob.geometry.Y, (layerNum * prob.geometry.ΔH))

    resConstruct = constructorof(typeof(initResult))
    result::typeof(initResult) = resConstruct(resultSize, initResult.t, 0.0)

    zInit = 1:(prevLayerNum*prob.geometry.ΔH)
    result.T[:, :, zInit] = initResult.T[:, :, zInit]
    result.M[:, :, zInit] = initResult.M[:, :, zInit]
    result.C[:, :, zInit] = initResult.C[:, :, zInit]

    inds = Boundary.calcInds(resultSize, prob.Tᵗ⁻¹, prob.geometry.ΔH, recoat)

    for (index, load) in enumerate(loads)
        resultDirectory = "$(name)/$(index)"
        push!(prob.resultsIndex, resultDirectory)

        loadStep = Types.LoadStep(;
            load=load,
            time=Types.LoadTime(result.t, load.tₗ, prob.geometry.Δt, load.skip),
            size=resultSize,
            ind=inds,
            init=result,
            name=string(name, ": ", load.name),
            layerNum=layerNum,
        )

        loadResults = StructArray(
            resConstruct(
                loadStep.size,
                loadStep.time.unskipTimes[i],
                loadStep.time.utₚ[i],
            )
            for i in eachindex(loadStep.time.unskipTimes)
        )

        result = loadSolver!(loadStep, loadResults, prob)

        jldopen(prob.file, "a+"; compress=prob.options.compress) do file
            file["Results/$(resultDirectory)/name"] = loadStep.name
            loadResultsFolder = file["Results/$(resultDirectory)"]
            loadStepSaver(loadResultsFolder, loadResults)
            return
        end
    end

    return result
end
