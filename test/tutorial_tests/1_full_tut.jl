using HSSSimulations

geometry = Geometry(
    (0.016, 0.016, 0.0122),
    0.001,
    1.5e-3;
    Δz=0.003 / 90,
    Δh=0.0001,
    offset=(0.0925, 0.1425),
    buildSize=(0.200, 0.300),
    name="30 layers preheat, 50 pre square pad layers 32 layer thich square and 10 post square padding layers",
)

material = PA2200(geometry)

params = HSSParams(geometry)
loadSets = HSSLoads(4, geometry; nrPreheat=90, lenPreheat=10.0, nrCool=90, lenCool=10.0)

geomsize = (geometry.X, geometry.Y, geometry.Z)
init = Result(geomsize, 25.0, 0.0, 0.0, 0.0, 0)
initialLayer = 30

inkArray = fill(material.eₚ, size)
inkArray[5:end-4, 5:end-4, 90:end-30] .= material.eᵢ
ink = Ink(inkArray, "Sample square")

file = "full_build_simulation_tutorial.jld2"
description = "A full simulation of a sample square"
problem = Problem(;
    geometry=geometry,
    matProp=material,
    params=params,
    preheatLoads=preheatLoads,
    buildLoads=buildLoads,
    cooldownLoads=cooldownLoads,
    init=init,
    initLay=initialLayer,
    ink=ink,
    file=file,
    description=description,
)

resultFile, finalResults = problemSolver(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl
