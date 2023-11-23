module StatsPlottingExt

# TODO : split up the plotting functions into subfiles, and generalise them a bit better

using HSSSimulations

using LaTeXStrings
using Measures
using Plots
using StatsPlots
using ProgressMeter

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

export densDistributionPlot
end
