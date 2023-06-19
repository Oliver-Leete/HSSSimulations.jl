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

function densDistributionPlot(
    resultsList;
    partInds=(4:13, 4:13, 241:336),
    nameList=getDesc.(resultsList),
    seriesName="",
    nodesPerLayer=3,
)
    part_dist = boxplot(;
        ylabel="Consolidation State", xlabel=seriesName,
        xticks=(2:2:2*length(nameList), nameList), xgrid=false,
        linewidth=0,
        ylims=(-0.05, 1.05),
        legend=:topright,
    )

    partInds = (
        partInds[1],
        partInds[2],
        (partInds[3][1].÷nodesPerLayer):(partInds[3][end].÷nodesPerLayer),
    )
    for (i, res) in enumerate(resultsList)
        ti = timeList(res)[end]
        cons = meanLayerNodes(volTime(res, "C", ti), nodesPerLayer)
        part = vec(cons[partInds...])
        cake = invertedIndex(cons, partInds)

        violin!(
            part_dist, [2i + 0.3], part;
            side=:right, linewidth=0, color=1,
            label=i == 1 && "Part Region",
        )
        violin!(
            part_dist, [2i - 0.3], cake;
            linewidth=0, color=2, side=:left,
            label=i == 1 && "Cake Region",
        )
        boxplot!(
            part_dist, [2i + 0.1], part;
            label=false, color=1, linecolor=:black,
            whisker_range=0,
            bar_width=0.2,
        )
        boxplot!(
            part_dist, [2i - 0.1], cake;
            label=false, color=2, linecolor=:black,
            whisker_range=0,
            bar_width=0.2,
        )
    end
    return plot(part_dist; size=(600, 300))
end

function multiLayerPlot(
    res,
    firstLayer,
    lastLayer;
    step=1,
    subPlots=false,
    xyCoordList=nothing,
)
    ti = loadFilter(timeList(res); firstLoad="$firstLayer/4", lastLoad="$lastLayer/4")
    times = fullTime(res, ti)

    numNodes = length(firstLayer:step:(lastLayer-step))
    xyCoordList = isnothing(xyCoordList) ? [(8, 8) for _ in 1:numNodes] : xyCoordList

    laytemp = plot(;
        ylabel=L"Temperature ($^\circ$C)",
        xformatter=_ -> "",
        size=(600, 300), legend_columns=8, legend=:outertop,
        xlims=(0, times[end] - times[1]),
        bottom_margin=-15.5mm,
    )
    laymelt = plot(;
        ylabel="Melt State",
        xformatter=_ -> "",
        size=(600, 300), legend=subPlots,
        xlims=(0, times[end] - times[1]), ylims=(-0.05, 1.05),
        top_margin=0mm,
        bottom_margin=-15.5mm,
    )
    laycons = plot(;
        xlabel="Time (s)", ylabel="Consolidation State",
        size=(600, 300), legend=subPlots,
        xlims=(0, times[end] - times[1]), ylims=(-0.05, 1.05),
        top_margin=0mm,
    )
    for (j, l) in enumerate(firstLayer:step:(lastLayer-step))
        i = l * 3
        x, y = xyCoordList[j]
        plot!(laytemp, [170]; label="Node ($x,$y,$i)", c=j)
    end
    for (j, l) in enumerate((lastLayer-step):-step:firstLayer)
        i = l * 3
        x, y = xyCoordList[(numNodes+1)-j]
        til = loadFilter(timeList(res); firstLoad="$l/4", lastLoad="$lastLayer/4")
        timel = fullTime(res, til) .- times[1]
        ttime, temp = deduplicate(timel, fullSeries(res, "T", (x, y, i), til))
        mtime, melt = deduplicate(timel, fullSeries(res, "M", (x, y, i), til))
        ctime, cons = deduplicate(timel, fullSeries(res, "C", (x, y, i), til))
        plot!(laytemp, ttime, temp; label=false, c=(numNodes + 1) - j)
        plot!(laymelt, mtime, melt; c=(numNodes + 1) - j)
        plot!(laycons, ctime, cons; c=(numNodes + 1) - j)
    end
    if subPlots
        return (laytemp, laymelt, laycons)
    else
        return plot(
            laytemp,
            laymelt,
            laycons;
            size=(600, 812),
            layout=@layout([a{0.315h}; b{0.315h}; c{0.37h}])
        )
    end
end

function singleLayComparePlot(
    resList,
    layer;
    numLayers=3,
    nameList=getDesc.(resList),
    subPlots=false,
    nodesPerLayer=3,
)
    times = []
    for res in resList
        ti = loadFilter(timeList(res); firstLoad="$layer/4", lastLoad="$(layer+numLayers)/4")
        ti = fullTime(res, ti)
        if length(ti) > length(times)
            times = ti
        end
    end

    laytemp = plot(;
        xformatter=_ -> "", ylabel=L"Temperature ($^\circ$C)",
        size=(600, 300), legend_columns=8, legend=:outertop,
        xlims=(0, times[end] - times[1]),
        bottom_margin=-15.5mm,
    )
    laymelt = plot(;
        xformatter=_ -> "", ylabel="Melt State",
        size=(600, 300), legend=subPlots,
        xlims=(0, times[end] - times[1]), ylims=(-0.05, 1.05),
        bottom_margin=-15.5mm,
        top_margin=0mm,
    )
    laycons = plot(;
        xlabel="Time (s)", ylabel="Consolidation State",
        size=(600, 300), legend=subPlots,
        xlims=(0, times[end] - times[1]), ylims=(-0.05, 1.05),
        top_margin=0mm,
    )
    for (i, res) in enumerate(resList)
        timestart = getTime(res, "$layer/4")
        til = loadFilter(timeList(res); firstLoad="$layer/4", lastLoad="$(layer+numLayers)/4")
        timel = fullTime(res, til) .- timestart
        ttime, temp = deduplicate(timel, fullSeries(res, "T", (8, 8, layer * nodesPerLayer), til))
        mtime, melt = deduplicate(timel, fullSeries(res, "M", (8, 8, layer * nodesPerLayer), til))
        ctime, cons = deduplicate(timel, fullSeries(res, "C", (8, 8, layer * nodesPerLayer), til))
        plot!(laytemp, ttime, temp; label=nameList[i])
        plot!(laymelt, mtime, melt)
        plot!(laycons, ctime, cons)
    end
    if subPlots
        return plot(laytemp, laymelt, laycons)
    else
        return plot(
            laytemp,
            laymelt,
            laycons;
            size=(600, 812),
            layout=@layout([a{0.315h}; b{0.315h}; c{0.37h}])
        )
    end
end

function meltConsComparePlot(res; name=getDesc(res), kwargs...)
    return meltConsComparePlot([res]; nameList=[name], kwargs...)
end
function meltConsComparePlot(res, blankIndex; name=getDesc(res), kwargs...)
    return meltConsComparePlot([res], blankIndex; nameList=[name], kwargs...)
end

function meltConsComparePlot(
    resList::AbstractArray;
    nameList=getDesc.(resList),
)
    maxlist = []
    for (i, res) in enumerate(resList)
        ti = timeList(res)[end]
        push!(
            maxlist,
            heatmap(
                (142.5):1:(142+(15.5)), 0.05:0.1:12.15,
                meanLayerNodes(res["Results/MeltMax"], 3)[8, :, :]';
                xlabel="Y Position (mm)", ylabel="Z Position (mm)",
                xlims=(142, 158), ylims=(0, 12.2), clims=(0, 1),
                colorbar_title=i == 1 ? "Maximum Melt State" : false,
                colorbar=i == 1 ? :top : false,
                aspect_ratio=:equal, right_margin=0.0mm,
                annotations=length(resList) > 1 ? [
                    (150, 1.5, nameList[i], :white),
                ] : [],
            ),
        )
        push!(
            maxlist,
            heatmap(
                (142.5):1:(142+(15.5)), 0.05:0.1:12.15,
                meanLayerNodes(volTime(res, "C", ti), 3)[8, :, :]';
                xlabel="Y Position (mm)", ylabel="Z Position (mm)",
                xlims=(142, 158), ylims=(0, 12.2), clims=(0, 1),
                colorbar_title=i == 1 ? "Consolidation State" : false,
                colorbar=i == 1 ? :top : false,
                aspect_ratio=:equal, right_margin=0.0mm,
                annotations=length(resList) > 1 ? [
                    (150, 1.5, nameList[i], :white),
                ] : [],
            ),
        )
    end
    return plot(
        maxlist...;
        size=(600, 300 * (12 / 16) * length(resList)),
        layout=@layout([grid(1, 2) for _ in 1:length(resList)])
    )
end

function meltConsComparePlot(
    resList::AbstractArray,
    blankIndex;
    nameList=getDesc.(resList),
    variableCLims=true,
)
    if variableCLims
        Mm = 0
        Cm = 0
        for res in resList
            ti = timeList(res)[end]
            meltmax = res["Results/MeltMax"]
            meltmax[blankIndex...] .= 0
            consmax = volTime(res, "C", ti)
            consmax[blankIndex...] .= 0
            Mm = max(maximum(meltmax), Mm)
            Cm = max(maximum(consmax), Cm)
        end
    else
        Mm = 1
        Cm = 1
    end
    maxlist = []
    for (i, res) in enumerate(resList)
        ti = timeList(res)[end]
        meltmax = copy(res["Results/MeltMax"])
        meltmax[blankIndex...] .= 0
        consmax = copy(volTime(res, "C", ti))
        consmax[blankIndex...] .= 0
        push!(
            maxlist,
            heatmap(
                (142.5):1:(142+(15.5)), 0.05:0.1:12.15, meanLayerNodes(meltmax, 3)[8, :, :]';
                xlabel="Y Position (mm)", ylabel="Z Position (mm)",
                xlims=(142, 158), ylims=(0, 12.2), clims=(0, Mm),
                colorbar_title=i == 1 ? "Maximum Melt State" : false,
                colorbar=i == 1 ? :top : false,
                aspect_ratio=:equal, right_margin=0.0mm,
                annotations=length(resList) > 1 ? [
                    (150, 1.5, nameList[i], :white),
                ] : [],
            ),
        )
        push!(
            maxlist,
            heatmap(
                (142.5):1:(142+(15.5)), 0.05:0.1:12.15, meanLayerNodes(consmax, 3)[8, :, :]';
                xlabel="Y Position (mm)", ylabel="Z Position (mm)",
                xlims=(142, 158), ylims=(0, 12.2), clims=(0, Cm),
                colorbar_title=i == 1 ? "Consolidation State" : false,
                colorbar=i == 1 ? :top : false,
                aspect_ratio=:equal, right_margin=0.0mm,
                annotations=length(resList) > 1 ? [
                    (150, 1.5, nameList[i], :white),
                ] : [],
            ),
        )
    end
    return plot(
        maxlist...;
        size=(600, 300 * (12 / 16) * length(resList)),
        layout=@layout([grid(1, 2) for _ in 1:length(resList)])
    )
end

function loadTopTempPlots(res, load, steps)
    til = loadFilter(timeList(res), load)
    timestart = getTime(res, til[1])
    plotlist = []
    for (i, ti) in enumerate(til[steps])
        temps = topSurfaceTime(res, "T", ti)
        push!(
            plotlist,
            heatmap(
                (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), temps;
                xlabel="Y Position (mm)",
                ylabel="X Position (mm)",
                xlims=(142, 158), ylims=(92, 108), clims=(minimum(temps), maximum(temps)),
                colorbar_title=L"Temperature ($^\circ$C)", colorbar=iseven(i) ? :right : :left,
                aspect_ratio=:equal, margins=0.0mm,
                annotations=[
                    (150, 93, "$(round(getTime(res, ti) - timestart, digits=2)) s", :white),
                ],
            ),
        )
    end
    return plot(
        plotlist...;
        size=(600, 300 * length(steps)),
        layout=@layout([grid(1, 2) for _ in 1:length(steps)])
    )
end

function tmcaTopPlot(res, ti::TI)
    temps = topSurfaceTime(res, "T", ti)
    tempPlot = heatmap(
        (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), temps;
        xlabel="Y Position (mm)", ylabel="X Position (mm)",
        xlims=(142, 158), ylims=(92, 108), clims=(minimum(temps), maximum(temps)),
        colorbar_title=L"Temperature ($^\circ$C)", colorbar=:top,
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    meltPlot = heatmap(
        (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), topSurfaceTime(res, "M", ti);
        xlabel="Y Position (mm)", ylabel="X Position (mm)",
        xlims=(142, 158), ylims=(92, 108), clims=(0, 1),
        colorbar_title="Melt State", colorbar=:top,
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    consPlot = heatmap(
        (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), topSurfaceTime(res, "C", ti);
        xlabel="Y Position (mm)", ylabel="X Position (mm)",
        xlims=(142, 158), ylims=(92, 108), clims=(0, 1),
        colorbar=:top, colorbar_title="Consolidation State",
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    return plot(tempPlot, meltPlot, consPlot; size=(600, 190), layout=(1, 3))
end

function tmcaTopPlot(res, ti::TI, mp)
    temps = topSurfaceTime(res, "T", ti)
    alphas = diffusivityTopSurface(res, ti, mp) .* 1000_000
    tempPlot = heatmap(
        (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), temps;
        xlabel="Y Position (mm)", ylabel="X Position (mm)",
        xlims=(142, 158), ylims=(92, 108), clims=(minimum(temps), maximum(temps)),
        colorbar_title=L"Temperature ($^\circ$C)", colorbar=:left,
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    meltPlot = heatmap(
        (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), topSurfaceTime(res, "M", ti);
        xlabel="Y Position (mm)", ylabel="X Position (mm)",
        xlims=(142, 158), ylims=(92, 108), clims=(0, 1),
        colorbar_title="Melt State", colorbar=:right,
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    consPlot = heatmap(
        (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), topSurfaceTime(res, "C", ti);
        xlabel="Y Position (mm)", ylabel="X Position (mm)",
        xlims=(142, 158), ylims=(92, 108), clims=(0, 1),
        colorbar=:left, colorbar_title="Consolidation State",
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    alphaPlot = heatmap(
        (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), alphas;
        xlabel="Y Position (mm)", ylabel="X Position (mm)",
        xlims=(142, 158), ylims=(92, 108), clims=(minimum(alphas), maximum(alphas)),
        colorbar=:right, colorbar_title=L"Thermal Diffusivity (mm$^2$/s)",
        aspect_ratio=:equal,
        right_margin=0.0mm,
    )
    return plot(tempPlot, meltPlot, consPlot, alphaPlot; size=(600, 600), layout=(2, 2))
end

function tmcaSidePlot(res, ti::TI, mp, layerNum, x; nodesPerLayer=3)
    temps = meanLayerNodes(volTime(res, "T", ti), nodesPerLayer)[x, :, :]'
    melts = meanLayerNodes(volTime(res, "M", ti), nodesPerLayer)[x, :, :]'
    conss = meanLayerNodes(volTime(res, "C", ti), nodesPerLayer)[x, :, :]'
    alphas =
        meanLayerNodes(diffusivityVol(res, ti, (:, :, :), mp), nodesPerLayer)[x, :, :]' .* 1000_000
    tempPlot = heatmap(
        (142.5):1:(142+(15.5)), 0.05:0.1:(layerNum/10)-0.05, temps;
        xlabel="Y Position (mm)", ylabel="Z Position (mm)",
        xlims=(142, 158), ylims=(0, layerNum / 10), clims=(minimum(temps), maximum(temps)),
        colorbar_title=L"Temperature ($^\circ$C)", colorbar=:left,
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    meltPlot = heatmap(
        (142.5):1:(142+(15.5)), 0.05:0.1:(layerNum/10)-0.05, melts;
        xlabel="Y Position (mm)", ylabel="Z Position (mm)",
        xlims=(142, 158), ylims=(0, layerNum / 10), clims=(0, 1),
        colorbar_title="Melt State", colorbar=:right,
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    consPlot = heatmap(
        (142.5):1:(142+(15.5)), 0.05:0.1:(layerNum/10)-0.05, conss;
        xlabel="Y Position (mm)", ylabel="Z Position (mm)",
        xlims=(142, 158), ylims=(0, layerNum / 10), clims=(0, 1),
        colorbar=:left, colorbar_title="Consolidation State",
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    alphaPlot = heatmap(
        (142.5):1:(142+(15.5)), 0.05:0.1:(layerNum/10)-0.05, alphas;
        xlabel="Y Position (mm)", ylabel="Z Position (mm)",
        xlims=(142, 158), ylims=(0, layerNum / 10), clims=(minimum(alphas), maximum(alphas)),
        colorbar=:right, colorbar_title=L"Thermal Diffusivity (mm$^2$/s)",
        aspect_ratio=:equal, right_margin=0.0mm,
    )
    return plot(tempPlot, meltPlot, consPlot, alphaPlot; size=(600, 600), layout=(2, 2))
end

function fieldToName(field)
    return Dict(
        "T" => L"Temperature ($^\circ$C)",
        "M" => "Melt State",
        "C" => "Consolidation State",
    )[field]
end

function zSlicePlot(res, zslices, ti::TI; field="T", subPlots=false, kwargs...)
    plotlist = []
    if field == "T"
        cmin = 500
        cmax = 0
        for z in zslices
            slice = copy(vec(volTime(res, "T", ti)[:, :, z]))
            for val in slice
                if !isnan(val)
                    cmin = min(val, cmin)
                    cmax = max(val, cmax)
                end
            end
        end
        clims = (cmin, cmax)
    else
        clims = (0, 1)
    end
    for (i, z) in enumerate(zslices)
        slice = volTime(res, "T", ti)[:, :, z]
        push!(
            plotlist,
            heatmap(
                (142.5):1:(142+(15.5)), (92.5):1:(92+(15.5)), slice;
                xlabel="Y Position (mm)", ylabel="X Position (mm)",
                xlims=(142, 158), ylims=(92, 108), clims=clims,
                colorbar=i % 3 == 0,
                colorbar_title=i % 3 == 0 ? fieldToName(field) : "",
                aspect_ratio=:equal,
                kwargs...,
            ),
        )
    end
    numRows = cld(length(zslices), 3)
    if subPlots
        return plotlist
    else
        return plot(
            plotlist...;
            size=(600, 200 * numRows),
            layout=@layout([grid(1, 3) for _ in 1:numRows])
        )
    end
end
