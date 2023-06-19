@testitem "Aqua" begin
    using Test, Aqua, HSSSimulations
    @testset Aqua.test_ambiguities(HSSSimulations)
    @testset Aqua.test_unbound_args(HSSSimulations)
    @testset Aqua.test_undefined_exports(HSSSimulations)
    @testset Aqua.test_piracy(HSSSimulations)
    @testset Aqua.test_stale_deps(HSSSimulations)
    @testset Aqua.test_deps_compat(HSSSimulations)
    @testset Aqua.test_project_toml_formatting(HSSSimulations)
end
