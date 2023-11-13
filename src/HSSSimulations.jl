module HSSSimulations
using TestItems
using Reexport
using DocStringExtensions

module DocExt
    using Reexport
    @reexport using DocStringExtensions
    include("docextensions.jl")
    export TFIELDS
end

"""
Contains the main types used in the simulation, along with the abstract types used to extend the
simulation's functionality.
"""
module Types
    using ..DocExt: TFIELDS, TYPEDEF, TYPEDSIGNATURES
    using CodecZlib
    using OffsetArrays

    include("Types/types.jl")
    include("Types/geometry.jl")
    include("Types/boundaryTypes.jl")
    include("Types/internalTypes.jl")
    include("Types/problem.jl")

    # Advanced
    export AbstractResult, AbstractOtherResults
    export AbstractMatProp
    export AbstractBoundary, Load, AbstractLoadSet, AbstractProblemParams
    export boundaryHeatTransferRate

    # Reexported
    export Problem
    export Geometry, Ink
    export Options, package_groups
    export OtherResults
end
@reexport using .Types: Problem, Ink, Geometry, Options, package_groups
export Types

"""
Contains a concrete time step and final results type and the functions needed to process the results
for these types.
"""
module Res
    using ..DocExt: TFIELDS, TYPEDEF, TYPEDSIGNATURES
    using ..Types
    using Reexport
    @reexport using StructArrays

    include("results.jl")

    # Advanced
    export loadStepSaver
    export otherResults

    # Reexported
    export Result
end
@reexport using .Res: Result
export Res

"""
Contains a concrete material property type, the functions for running the material model, and an
example material using this model and data collected from measuring PA2200.
"""
module Material
    using ..DocExt: TFIELDS, TYPEDEF, TYPEDSIGNATURES
    using ..Types
    using Interpolations: Flat, Line, bounds, linear_interpolation
    using JLD2
    using Pkg.Artifacts
    using TestItems: @testitem

    include("Material/materialProps.jl")
    include("Material/PA2200.jl")

    # Advanced
    export calcMatProps!
    export meltUpdate, consUpdate
    export PA_κ, PA_ρ, PA_c
    export PA_Mᵣ, PA_Hf, PA_Rᵣ, PA_Hr
    export PA_Ċ, PA_Ċ_maker
    export PA_eₚ, PA_eᵢ

    # Reexported
    export MatProp
    export PA2200
end
@reexport using .Material: MatProp, PA2200
export Material

"""
The functions for calculating the ghost nodes needed to solve the boundary conditions. Basic
boundary conditions are also included.
"""
module Boundary
    using ..DocExt: SIGNATURES, TFIELDS, TYPEDEF, TYPEDSIGNATURES
    using ..Material: calcMatProps!
    using ..Types
    using TestItems: @testitem

    include("Boundary/indices.jl")
    include("Boundary/boundary.jl")
    include("Boundary/loads.jl")
    include("Boundary/ghosts.jl")
    include("Boundary/boundary_adv.jl")

    # Advanced
    export conductionFlow, convectionFlow, radiationFlow
    export SymetryBoundary, ConductionBoundary, ConvectionBoundary
    export recoating!, movingObjOverlap

    # Reexported
    export basicLoad, BasicProblemParams
end
@reexport using .Boundary: basicLoad, BasicProblemParams
export Boundary

"""
The core logic for setting up and solving a simulation, including the heat transfer solver.
"""
module Solver
    using ..Boundary
    using ..DocExt: SIGNATURES, TFIELDS, TYPEDEF, TYPEDSIGNATURES
    using ..Material
    using ..Res
    using ..Types
    using ..Types: package_groups
    using Alert
    using ConstructionBase
    using Dates
    using JLD2: jldopen
    using LoggingExtras
    using ProgressMeter: @showprogress
    using StructArrays
    using TestItems: @testitem

    include("Solver/logging.jl")
    include("Solver/timeSolve.jl")
    include("Solver/loadSolve.jl")
    include("Solver/loadSetSolve.jl")
    include("Solver/problemSolve.jl")

    # Advanced
    export loadSetSolver!, innerLoadSetSolver!
    export FixedLoadSet, LayerLoadSet
    export makeLogger, with_logger

    # Reexported
    export Problem, problemSolver
end
@reexport using .Solver: Problem, problemSolver
export Solver

"""
All additional boundary conditions requried to simulate a HSS build that are not already included in
[`Boundary`](@ref).
"""
module HSSBound
    using ..Boundary
    using ..DocExt
    using ..DocExt: SIGNATURES, TFIELDS, TYPEDEF, TYPEDSIGNATURES
    using ..Solver
    using ..Types
    using Interpolations: AbstractInterpolation, Flat, bounds, linear_interpolation
    using JLD2
    using LoggingExtras
    using Pkg.Artifacts
    using TestItems: @testitem

    include("HSSBound/piston.jl")
    include("HSSBound/overheads.jl")
    include("HSSBound/sinterStroke.jl")
    include("HSSBound/recoatStroke.jl")
    include("HSSBound/blankStroke.jl")
    include("HSSBound/inkStroke.jl")
    include("HSSBound/HSSLoads.jl")

    include("HSSBound/utils.jl")
    include("HSSBound/HSSParams.jl")

    # Advanced
    export PistonBoundary, OverheadsBoundary, loadOverheads
    export PistonCoolBoundary, OverheadsCoolBoundary, loadCooldown
    export SinterBoundary, loadSinterStroke
    export RecoatBoundary, loadRecoatStroke
    export BlankBoundary, loadBlankStroke
    export InkBoundary, loadInkStroke
    export lampMaker, overheadTempFunc, coolingStart

    # Reexported
    export HSSParams, HSSLoads
end
@reexport using .HSSBound: HSSParams, HSSLoads
export HSSBound

"""
Some functions to ease the post processing of the simulation results.
"""
module PostProcessing
    using ..DocExt: SIGNATURES, TFIELDS, TYPEDEF, TYPEDSIGNATURES
    using CodecZlib
    using JLD2
    using Statistics
    using TestItems: @testitem
    include("PostProcessing/utils.jl")
    export timeList, timeFilter, loadFilter
    export realRange
    export topSurfaceTime, volTime
    export fullSeries, fullTime
    export fullTopSurface
    export meanLayerNodes
    export diffusivityVol
    export getTime
    export getDesc
    export invertedIndex
    export deduplicate
    export diffusivityTopSurface
    export TI
end
@reexport using .PostProcessing
export PostProcessing

end
