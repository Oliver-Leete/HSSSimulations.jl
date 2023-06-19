"""
    Types.Load(;
        name="default", tₗ=1, skip=1,
        x₁=SymetryBoundary, x₂=SymetryBoundary,
        y₁=SymetryBoundary, y₂=SymetryBoundary,
        z₁=SymetryBoundary, z₂=SymetryBoundary,
    )

Default constructor for [`Types.Load`](@ref). All of the boundaries defaults to symetry boundaries
(see [`Boundary.SymetryBoundary`](@ref)). See [`Boundary.ConductionBoundary`](@ref) and
[`Boundary.ConvectionBoundary`](@ref), for some more built in loads. And [High Speed Sintering
Boundary Example](@ref) for more complicated loads.

The `z₂` load is run before any others, so any calculations that need to be done first should be
put there, such as recoating.

# Examples

```jldoctest
julia> Load(; name="test", tₗ=1, skip=1, x₁=ConductionBoundary, y₂=ConvectionBoundary)
  x₁ : ConductionBoundary
  x₂ : SymetryBoundary
  y₁ : SymetryBoundary
  y₂ : ConvectionBoundary
  z₁ : SymetryBoundary
  z₂ : SymetryBoundary
  name : test
  tₗ : 1.0
  skip : 1
```
"""
function Types.Load(;
    name="NA", tₗ=1, skip=1,
    x₁=SymetryBoundary, x₂=SymetryBoundary,
    y₁=SymetryBoundary, y₂=SymetryBoundary,
    z₁=SymetryBoundary, z₂=SymetryBoundary,
)
    return Load(name, tₗ, skip, x₁, x₂, y₁, y₂, z₁, z₂)
end

@testitem "Load" begin
    using Test, HSSSimulations
    using .Types
    @testset "catch_no_constructor_error" begin
        struct BrokenBoundary <: AbstractBoundary
            BrokenBoundary(_, _, _, _, _) = new()
        end
        Types.boundaryHeatTransferRate(_, _, _::BrokenBoundary) = 0.0
        @test_throws MethodError Load(x₁=BrokenBoundary)
    end
    @testset "catch_no_heattransfer_method_error" begin
        struct BrokenBoundary2 <: AbstractBoundary
            BrokenBoundary2(_, _, _, _) = new()
        end
        @test_throws MethodError Load(x₁=BrokenBoundary2)
    end
    @testset "passing_type" begin
        struct PassingBoundary <: AbstractBoundary
            PassingBoundary(_, _, _, _) = new()
        end
        Types.boundaryHeatTransferRate(_, _, x::PassingBoundary) = 0.0
        @test_nowarn Load(x₁=PassingBoundary)
    end
end

"""
$(TYPEDSIGNATURES)

A basic [`Types.Load`](@ref) with a conduction boundary on the bottom surface and a convection
boundary on the top. All other surfaces are symetrical boundaries.

# Examples

```jldoctest
julia> loadStep = basicLoad(5, 2)
  x₁ : SymetryBoundary
  x₂ : SymetryBoundary
  y₁ : SymetryBoundary
  y₂ : SymetryBoundary
  z₁ : ConductionBoundary
  z₂ : ConvectionBoundary
  name : NA
  tₗ : 5.0
  skip : 2
```

This returns a single `Load`, for a single load step. To make a load set you will need an
array of `Load`s.
"""
basicLoad(tₗ, skip) = Load(; tₗ=tₗ, skip=skip, z₁=ConductionBoundary, z₂=ConvectionBoundary)

"""
A basic implementation of a [`Types.AbstractProblemParams`](@ref) struct to go along with
[`basicLoad`](@ref). For a more elaborate example see `HSSParams`

# Fields
$(TFIELDS)

"""
struct BasicProblemParams{T1,T2} <: AbstractProblemParams
    "The contact conduction coefficent for the bottom face"
    condCoef::Float64
    "The temperature of the surface in contact with the bottom face"
    condTemp::T1
    "The convection coefficent for the top face to the air above"
    convCoef::Float64
    "The temperature of the air in contact with the top face"
    convTemp::T2
end
