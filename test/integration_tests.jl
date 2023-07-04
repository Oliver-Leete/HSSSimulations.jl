@testitem "Basic_integration" begin
    using JLD2, HSSSimulations
    include("tutorial_tests/2_basic_tut.jl")

    @testset begin
        testFile = jldopen(problem.file, "r")
        results = testFile["Results"]
        index = testFile["Results_Index"]

        # Check that the input problem has been saved
        # This will no longer work due to the potential mutability of
        # @test testFile["Input"] == problem broken = true
        @test string(testFile["Description"]) == repr(problem)

        # Check that the powder has melted at all and melt max is within the defined range
        meltMax = results["MeltMax"][:, :, :]
        @test all(map((x -> 0 <= x <= 1), meltMax))

        firstLoad = results[index[1]]
        lastLoad = results[index[end]]
        # Check that none of the final temperatures are NaN
        @test all(map(!isnan, lastLoad["T"]))

        # Check that consolidation is none zero everywhere that the powder has melted
        @test map((>(0)), meltMax) ==
              map((>(0)), lastLoad["C"][:, :, :, end])

        # Check that the melt state returns to zero if temp lower than recryst temp
        lastTemp = lastLoad["T"][:, :, :, end]
        lastMelt = lastLoad["M"][:, :, :, end]
        @test all(map(<(125), lastTemp) .<= map(iszero, lastMelt))
    end
end
