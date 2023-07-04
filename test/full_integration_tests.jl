@testitem "Full_build_integration" begin
    using JLD2, HSSSimulations

    geometry = Geometry(
        (0.05, 0.05, 0.0022),
        0.01,
        1.5e-3;
        Δz=0.0001,
        Δh=0.0001,
        offset=(0.0975, 0.1475),
        buildSize=(0.200, 0.300),
        name="To simulate a smaller than sample square",
    )
    matProp = PA2200(geometry)
    params = HSSParams(geometry)
    loadSets = HSSLoads(
        5, geometry;
        nrPreheat=2,
        lenPreheat=20.0,
        nrCool=2,
        lenCool=20.0,
    )

    geomSize = (geometry.X, geometry.Y, geometry.Z)
    init = Result(geomSize, 180.0, 0.0, 0.0, 0.0, 0)
    initLay = geometry.Z - 4

    inkArray = fill(matProp.eₚ, geomSize)
    inkArray[4:(end-3), 4:(end-3), (end-3):(end-1)] .= matProp.eᵢ
    ink = Ink(inkArray, "Centre Block")

    description = "A basic simulation to test the solver and material model"

    problem = Problem(;
        geometry=geometry,
        matProp=matProp,
        params=params,
        loadSets=loadSets,
        init=init,
        initLay=initLay,
        ink=ink,
        file=tempname(),
        description=description,
    )

    resultFile, finalResult = problemSolver(problem)

    begin
        testFile = jldopen(problem.file, "r")
        results = testFile["Results"]
        index = testFile["Results_Index"]

        # Check that the input problem has been saved
        @test string(testFile["Description"]) == repr(problem)

        # Check that the powder has melted at all and melt max is within the defined range
        meltMax = results["MeltMax"][:, :, :]
        @test any(map((x -> 0 < x <= 1), meltMax))
        @test all(map((x -> 0 <= x <= 1), meltMax))

        # Check that consolidation has happened and is none zero
        # everywhere that the melt max is none zero
        lastCons = results[index[end]]["C"][:, :, :, end]
        @test any(map((x -> 0 < x <= 1), lastCons))
        @test all(map(>(0), meltMax) .== map(>(0), lastCons))

        # Check that the melt state returns to zero if temp lower than recryst temp
        last = results[index[end]]["T"][:, :, :, end]
        lastMelt = results[index[end]]["M"][:, :, :, end]
        @test all(map(<(125), last) .<= map(iszero, lastMelt))

        # Check that none of the final temperatures are NaN
        @test all(map(!isnan, last))
    end
end
#
# @testitem "Fullest_integration" tags = [:skipci] begin
#     using JLD2, HSSSimulations
#     geometry = Geometry(
#         (0.015, 0.015, 0.0122),
#         0.0005,
#         1.5e-3;
#         Δz=0.0001,
#         Δh=0.0001,
#         offset=(0.0925, 0.1425),
#         buildSize=(0.200, 0.300),
#         name="30 layers preheat, 50 pre square pad layers 32 layer thich square and 10 post square padding layers",
#     )
#     material = PA2200(geometry)
#     params = HSSParams(geometry;)
#     preheatLoads, buildLoads, cooldownLoads = HSSLoads(
#         4; nrPreheat=200, lenPreheat=10.0, nrCool=90, lenCool=10.0,
#     )
#
#     geomSize = (geometry.X, geometry.Y, geometry.Z)
#     init = Result(geomSize, 25.0, 0.0, 0.0, 0.0, 0)
#     initLay = 30
#
#     inkArray = fill(material.eₚ, geomSize)
#     inkArray[5:(end-4), 5:(end-4), 60:(end-9)] .= material.eᵢ
#     ink = Ink(inkArray, "Sample square")
#
#     if isfile("test/test_outputs/full_out.jld2")
#         rm("test/test_outputs/full_out.jld2")
#     end
#     if isfile("test/test_outputs/full_out.log")
#         rm("test/test_outputs/full_out.log")
#     end
#
#     file = "test/test_outputs/full_out.jld2"
#     description = "A full simulation of a sample square"
#
#     problem = Problem(;
#         geometry=geometry,
#         matProp=material,
#         params=params,
#         preheatLoads=preheatLoads,
#         buildLoads=buildLoads,
#         cooldownLoads=cooldownLoads,
#         init=init,
#         initLay=initLay,
#         ink=ink,
#         file=file,
#         description=description,
#     )
#
#     resultFile, finalResult = problemSolver(problem)
#
#     begin
#         testFile = jldopen(problem.file, "r")
#         results = testFile["Results"]
#         index = testFile["Results_Index"]
#
#         # Check that the input problem has been saved
#         @test string(testFile["Description"]) == repr(problem)
#
#         # Check that the powder has melted at all and melt max is within the defined range
#         meltMax = results["MeltMax"][:, :, :]
#         @test any(map((x -> 0 < x <= 1), meltMax))
#         @test all(map((x -> 0 <= x <= 1), meltMax))
#
#         # Check that consolidation is none zero everywhere that the powder has melted
#         @test map((x -> 0 < x), meltMax) ==
#               map((x -> 0 < x), results[index[end]]["C"][:, :, :, end])
#
#         # Check that the temperature increases everywhere during heating
#         lastHeatIndex = index[findlast(x -> occursin(r"^\d*/\d*$", x), index)]
#         lastHeat = results[lastHeatIndex]["T"][:, :, :, end]
#         firstRes = results[index[1]]["T"][:, :, :, end]
#         @test all([firstRes[i] <= lastHeat[i] for i in CartesianIndices(firstRes)])
#
#         # Check that the melt state returns to zero if temp lower than recryst temp
#         last = results[index[end]]["T"][:, :, :, end]
#         lastMelt = results[index[end]]["M"][:, :, :, end]
#         @test all(map(x -> x < 125, last) .<= map(iszero, lastMelt))
#
#         # Check that none of the final temperatures are NaN
#         @test all(map(!isnan, last))
#     end
# end
#
# @testitem "Thick_layer_integration" tags = [:skipci] begin
#     using JLD2, HSSSimulations
#     geometry = Geometry(
#         (0.015, 0.015, 0.0061),
#         0.0005,
#         1.5e-3;
#         Δz=0.00005,
#         Δh=0.0001,
#         offset=(0.0925, 0.1425),
#         buildSize=(0.200, 0.300),
#         name="30 layers preheat, 50 pre square pad layers 32 layer thich square and 10 post square padding layers",
#     )
#     material = PA2200(geometry)
#     params = HSSParams(geometry;)
#     preheatLoads, buildLoads, cooldownLoads = HSSLoads(
#         20; nrPreheat=5, lenPreheat=20.0, nrCool=5, lenCool=20.0,
#     )
#
#     geomSize = (geometry.X, geometry.Y, geometry.Z)
#     init = Result(geomSize, 155.0, 0.0, 0.0, 2000.0, 0)
#     initLay = 30
#
#     inkArray = fill(material.eₚ, geomSize)
#     inkArray[5:(end-4), 5:(end-4), 60:(end-19)] .= material.eᵢ
#     ink = Ink(inkArray, "Sample square")
#
#     if isfile("test/test_outputs/full_out.jld2")
#         rm("test/test_outputs/full_out.jld2")
#     end
#     if isfile("test/test_outputs/full_out.log")
#         rm("test/test_outputs/full_out.log")
#     end
#
#     file = "test/test_outputs/full_out.jld2"
#     description = "A full simulation of a sample square"
#
#     problem = Problem(;
#         geometry=geometry,
#         matProp=material,
#         params=params,
#         preheatLoads=preheatLoads,
#         buildLoads=buildLoads,
#         cooldownLoads=cooldownLoads,
#         init=init,
#         initLay=initLay,
#         ink=ink,
#         file=file,
#         description=description,
#     )
#
#     resultFile, finalResult = problemSolver(problem)
#
#     begin
#         testFile = jldopen(problem.file, "r")
#         results = testFile["Results"]
#         index = testFile["Results_Index"]
#
#         # Check that the input problem has been saved
#         @test string(testFile["Description"]) == repr(problem)
#
#         # Check that the powder has melted at all and melt max is within the defined range
#         meltMax = results["MeltMax"][:, :, :]
#         @test any(map((x -> 0 < x <= 1), meltMax))
#         @test all(map((x -> 0 <= x <= 1), meltMax))
#
#         # Check that consolidation is none zero everywhere that the powder has melted
#         @test map((x -> 0 < x), meltMax) ==
#               map((x -> 0 < x), results[index[end]]["C"][:, :, :, end])
#
#         # Check that the temperature increases everywhere during heating
#         lastHeatIndex = index[findlast(x -> occursin(r"^\d*/\d*$", x), index)]
#         lastHeat = results[lastHeatIndex]["T"][:, :, :, end]
#         firstRes = results[index[1]]["T"][:, :, :, end]
#         @test all([firstRes[i] <= lastHeat[i] for i in CartesianIndices(firstRes)])
#
#         # Check that the melt state returns to zero if temp lower than recryst temp
#         last = results[index[end]]["T"][:, :, :, end]
#         lastMelt = results[index[end]]["M"][:, :, :, end]
#         @test all(map(x -> x < 125, last) .<= map(iszero, lastMelt))
#
#         # Check that none of the final temperatures are NaN
#         @test all(map(!isnan, last))
#     end
# end
