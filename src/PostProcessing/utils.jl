# TODO : move general post processing (non plottng) stuff in to their own file
# TODO : split up the plotting functions into subfiles, and generalise them a bit better
# TODO : find a way to conditionally load the plotting stuff, don't want to have plots as a dep
# TODO : Refactor to use loadsets and steps seperatly
struct TI
    loadStep::String
    timeStep::Int
end

isLoad(load) = t::TI -> contains(t.loadStep, load)
isLoad(t::TI, load) = contains(t.loadStep, load)

function timeList(resultsFile; useIndex=true)::Vector{TI}
    results = resultsFile["Results"]
    index = useIndex ? resultsFile["Results_Index"] : makeIndex(results)
    ret = []
    for i in index[1:end]
        len = length(results[i]["time"])
        for j in 1:len
            push!(ret, TI(i, j))
        end
    end
    return ret
end

"""
    makeIndex(group)

!!! warning

    This function is hard coded to only make an index for two levels deep, this is meant to work
    with the loadsets and loads as the two levels.
"""
function makeIndex(group)
    index = []
    keylist = collect(keys(group))

    for k in keylist
        inner_group = group[k]
        inner_keys = collect(keys(inner_group))
        for ik in inner_keys
            push!(index, "$k/$ik")
        end
    end
    return index
end

function deduplicate(xvec::AbstractVector{T}, dupvec::AbstractVector{T}) where {T}
    xveco = Vector{T}()
    yveco = Vector{T}()
    cur_con = false
    push!(xveco, xvec[1])
    push!(yveco, dupvec[1])
    for i in 2:length(dupvec)-1
        if dupvec[i] == dupvec[i+1] && cur_con
            continue
        elseif dupvec[i] == dupvec[i+1]
            cur_con = true
            push!(xveco, xvec[i])
            push!(yveco, dupvec[i])
        else
            cur_con = false
            push!(xveco, xvec[i])
            push!(yveco, dupvec[i])
        end
    end
    push!(xveco, xvec[length(dupvec)])
    push!(yveco, dupvec[length(dupvec)])
    return xveco, yveco
end

function volTime(resultsFile, field, ti::TI)
    return resultsFile["Results"][ti.loadStep][field][:, :, :, ti.timeStep]
end

notnan(results, x, y, z, ti::TI) =
    if !isnan(results[x, y, z, ti.timeStep])
        results[x, y, z, ti.timeStep]
    else
        notnan(results, x, y, z - 1, ti)
    end

function topSurfaceTime(resultsFile, field, ti::TI)
    results = resultsFile["Results"][ti.loadStep][field]
    z = size(results)[3]
    return [
        notnan(results, x, y, z, ti)
        for x in 1:size(results)[1],
        y in 1:size(results)[2]
    ]
end

function realRange(resultsFile; absolute=false)
    geom = resultsFile["Input"].geometry
    if absolute
        xind = [(i * geom.Δx) + geom.xoffset for i in 0:(geom.X-1)]
        yind = [(i * geom.Δy) + geom.yoffset for i in 0:(geom.Y-1)]
    else
        xrange = range(; start=-floor(geom.X), length=geom.X)
        yrange = range(; start=-floor(geom.Y), length=geom.Y)
        xind = [i * geom.Δx for i in xrange]
        yind = [i * geom.Δy for i in yrange]
    end
    zind = [i * geom.Δz for i in 0:(geom.Z-1)]

    return xind, yind, zind
end

function fullTime(resultsFile, timeList::Vector{TI}=timeList(resultsFile))
    return [resultsFile["Results"][t.loadStep]["time"][t.timeStep] for t in timeList]
end

getTime(resultsFile, ti::TI) = resultsFile["Results"][ti.loadStep]["time"][ti.timeStep]
function getTime(resultsFile, load; timeList::Vector{TI}=timeList(resultsFile), start=true)
    loadIndex = findfirst(isLoad(load), timeList)
    return resultsFile["Results"][timeList[loadIndex].loadStep]["time"][start ? 1 : end]
end

function fullSeries(resultsFile, field, index, timeList::Vector{TI}=timeList(resultsFile))
    return [
        resultsFile["Results"][t.loadStep][field][index..., t.timeStep]
        for t in timeList
    ]
end

function fullSeries(
    resultsFile,
    field,
    filter::T,
    timeList::Vector{TI}=timeList(resultsFile),
) where {T<:Function}
    return [
        filter(resultsFile["Results"][t.loadStep][field][:, :, :, t.timeStep]) for t in timeList
    ]
end

function fullSeries(
    resultsFile,
    filter::T,
    timeList::Vector{TI}=timeList(resultsFile),
) where {T<:Function}
    return [filter(resultsFile, t) for t in timeList]
end

function fullTopSurface(
    resultsFile, field, filter::T,
    timeList::Vector{TI}=timeList(resultsFile),
) where {T<:Function}
    return [filter(topSurfaceTime(resultsFile, field, ti)) for ti in timeList]
end

function fullTopSurface(
    resultsFile, field, index,
    timeList::Vector{TI}=timeList(resultsFile),
)
    return [topSurfaceTime(resultsFile, field, ti)[index...] for ti in timeList]
end

function fullTopSurface(
    resultsFile, field,
    timeList::Vector{TI}=timeList(resultsFile),
)
    return [topSurfaceTime(resultsFile, field, ti) for ti in timeList]
end

function timeFilter(resultsFile, timeList::Vector{TI}; start=nothing, finish=nothing)
    if isnothing(finish)
        lastTime = length(timeList)
    else
        lastTime =
            findfirst(
                (t -> resultsFile["Results"][t.loadStep]["t"][t.timeStep] >= finish),
                timeList,
            )
    end
    if isnothing(start)
        firstTime = 1
    else
        firstTime =
            findfirst((t -> resultsFile["Results"][t.loadStep]["t"][t.timeStep] >= start), timeList)
    end
    return timeList[firstTime:lastTime]
end

function timeFilter(resultsFile, timeList::Vector{TI}, time)
    firstTime =
        findfirst((t -> resultsFile["Results"][t.loadStep]["t"][t.timeStep] >= time), timeList)
    return timeList[firstTime]
end

function loadFilter(timeList::Vector{TI}; firstLoad=nothing, lastLoad=nothing)
    start = isnothing(firstLoad) ? 1 : findfirst(isLoad(firstLoad), timeList)
    finish = isnothing(lastLoad) ? length(timeList) : findlast(isLoad(lastLoad), timeList)
    return timeList[start:finish]
end

function loadFilter(timeList::Vector{TI}, load)
    start = findfirst(isLoad(load), timeList)
    finish = findlast(isLoad(load), timeList)
    return timeList[start:finish]
end

function meanLayerNodes(volume, nodesPerLayer)
    x, y, z = size(volume)

    return [
        mean(volume[i, j, k:(k-1+nodesPerLayer)])
        for i in 1:x, j in 1:y, k in 1:nodesPerLayer:z
    ]
end

function diffusivityVol(res, ti::TI, index, mp)
    T = volTime(res, "T", ti)[index...]
    M = volTime(res, "M", ti)[index...]
    C = volTime(res, "C", ti)[index...]
    α(T, M, C) = mp.κ(C, T, M) / (mp.ρ(C, M) * mp.c(T))
    return map(α, T, M, C)
end

function notnan(alpha, T, M, C, x, y, z, ti::TI)
    a = alpha(T[x, y, z], M[x, y, z], C[x, y, z])
    if !isnan(a)
        a
    else
        notnan(alpha, T, M, C, x, y, z - 1, ti)
    end
end

function diffusivityTopSurface(res, ti::TI, mp)
    α(T, M, C) = mp.κ(C, T, M) / (mp.ρ(C, M) * mp.c(T))
    T = res["Results"][ti.loadStep]["T"][:, :, :, ti.timeStep]
    M = res["Results"][ti.loadStep]["M"][:, :, :, ti.timeStep]
    C = res["Results"][ti.loadStep]["C"][:, :, :, ti.timeStep]
    z = size(T)[3]
    return [
        notnan(α, T, M, C, x, y, z, ti)
        for x in 1:size(T)[1],
        y in 1:size(T)[2]
    ]
end

function heatflow(res, ti, mp, Δx, Δy, Δz, index=(:, :, :))
    α = diffusivityVol(res, ti, index, mp)
    Fx = α ./ (Δx^2)
    Fy = α ./ (Δy^2)
    Fz = α ./ (Δz^2)

    T = volTime(res, "T", ti)[index]

    # Get the size of the input array
    n, m, l = size(T)

    heat_flow_x = zeros(Float64, (n, m, l))
    heat_flow_y = zeros(Float64, (n, m, l))
    heat_flow_z = zeros(Float64, (n, m, l))

    # Loop over each node in the input array
    for i in 1:n, j in 1:m, k in 1:l
        # Calculate the heat flow vector for this node
        flow_x, flow_y, flow_z = 0.0, 0.0, 0.0
        if i > 1
            flow_x += T[i, j, k] - T[i-1, j, k]
        end
        if i < l
            flow_x -= T[i+1, j, k] - T[i, j, k]
        end
        if j > 1
            flow_y += T[i, j, k] - T[i, j-1, k]
        end
        if j < m
            flow_y -= T[i, j+1, k] - T[i, j, k]
        end
        if k > 1
            flow_z += T[i, j, k] - T[i, j, k-1]
        end
        if k < l
            flow_z -= T[i, j, k+1] - T[i, j, k]
        end

        # Set the heat flow vector for this node in the output array
        heat_flow_z[i, j, k] = flow_z * Fx[i, j, k]
        heat_flow_y[i, j, k] = flow_y * Fy[i, j, k]
        heat_flow_z[i, j, k] = flow_z * Fz[i, j, k]
    end

    return heat_flow_x, heat_flow_y, heat_flow_z
end

getDesc(res) = res["Input"].description

function invertedIndex(result, index; toFill=false)
    outputRes = copy(result)
    if toFill
        outputRes[index] .= toFill
        return outputRes
    else
        inds = CartesianIndices(result)
        return vec(result[setdiff(vec(inds), vec(inds[index...]))])
    end
end
