using HSSSimulations

geometry = Geometry(
    (0.010, 0.010, 0.030),
    0.0005,
    0.001;
    name="Basic Simulation Tutorial",
)

material = PA2200(geometry)

params = HSSParams(
    geometry;
    overheadPower=300.0,
    name="Overhead heat and cool",
)

skipper = 20
cooldownLoads = vcat(
    [HSSBound.loadOverheads(3.0, skipper) for _ in 1:2],
    [HSSBound.loadCooldown(3.0, skipper) for _ in 1:2],
)

geomSize = (geometry.X, geometry.Y, geometry.Z)
init = Result(geomSize, 25.0, 0.0, 0.0, 0.0, 0)
initLay = geometry.Z

inkArray = fill(material.eₚ, geomSize)
ink = Ink(inkArray, "No ink")

file = tempname()
description = "A basic simulation to teach us how to use this package"
problem = Problem(;
    geometry=geometry,
    matProp=material,
    params=params,
    cooldownLoads=cooldownLoads,
    init=init,
    initLay=geometry.Z,
    ink=ink,
    file=file,
    description=description,
)

resultFile, finalResult = problemSolver(problem)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

