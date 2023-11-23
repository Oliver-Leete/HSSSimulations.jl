# Simulating Subsets of a Build

## A Single Layer

This simulates a single layer deposited on top of a uniformly preheated powder
bed.

```julia
geometry = Geometry(
    (0.016, 0.016, 0.031),
    0.001,
    1.5e-3;
    Δz=0.003 / 90,
    Δh=0.0001,
    offset=(0.0925, 0.1425),
    buildSize=(0.200, 0.300),
    name="30 layers preheat, 1 layer of build",
)
material = PA2200(geometry)
params = HSSParams(geometry)
loadSets = HSSLoads(1, geometry; nrPreheat=0, lenPreheat=0.0, nrCool=0, lenCool=0.0)

geomsize = (geometry.X, geometry.Y, geometry.Z)
init = Result(geomsize, 160.0, 0.0, 0.0, 1000.0)
initialLayer = 30

inkArray = fill(material.eₚ, size)
ink = Ink(inkArray, "Empty")

file = tempname()
description = "A single layer simulation with no ink"
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
```
