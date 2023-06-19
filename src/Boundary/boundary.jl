function Base.show(io::IO, boundary::AbstractBoundary)
    for field in fieldnames(AbstractBoundary)
        println(io, "  ", string(field), ": ", getfield(boundary, field))
    end
end

"""
$(SIGNATURES)

Calculates a heat flux density (ϕ⃗, in wm⁻²) for a given contact conduction coefficient, h,
between points at temperature T1 (the node on the boundary) and T2 (the wall in contact with the
node).
"""
conductionFlow(T1, T2, h) = h * (T2 - T1)

@testitem "conductionFlow" begin
    using HSSSimulations, Test
    using .Boundary
    @test conductionFlow(150, 150, 10) ≈ 0
    @test conductionFlow(100, 150, 10) ≈ 500
    @test conductionFlow(150, 100, 10) ≈ -500
end

"""
$(SIGNATURES)

Calculates a heat flux density (ϕ⃗, in wm⁻²) for a given convection coefficient, h, between a
point at temperature T1 and a fluid with temperature T∞.
"""
convectionFlow(T1, T∞, h) = h * (T∞ - T1)

@testitem "convectionFlow" begin
    using HSSSimulations, Test
    using .Boundary
    @test convectionFlow(150, 150, 10) ≈ 0
    @test convectionFlow(100, 150, 10) ≈ 500
    @test convectionFlow(150, 100, 10) ≈ -500
end

"""
Stefan-Boltzmann constant
"""
const σ = 5.67e-8

"""
$(SIGNATURES)

Calculates a heat flux density (ϕ⃗, in wm⁻²) for a given emmisivity, ε, between a point at
temperature T1 and infinity at temperature T∞. The temperature arguments should both be in the
units °C.
"""
radiationFlow(T1, T∞, ε) = σ * ε * (((273.15 + T∞)^4) - ((273.15 + T1)^4))

@testitem "radiationFlow" begin
    using HSSSimulations, Test
    using .Boundary
    @test radiationFlow(150, 150, 1) ≈ 0
    @test radiationFlow(100, 300, 0.8) ≈ 4015.4859070819937
    @test radiationFlow(300, 100, 0.8) ≈ -4015.4859070819937
end

"""
$(TYPEDEF)
A boundary for a face that has no heatflow (such as a face on a symetrical boundary). Used as the
default boundary in [`Types.Load`](@ref).
"""
struct SymetryBoundary <: AbstractBoundary
    SymetryBoundary(_, _, _, _) = new()
end

"""
$(TYPEDEF)

A boundary for a face that has a source of contact conductive heat flow.

# Fields
$(TFIELDS)
"""
struct ConductionBoundary <: AbstractBoundary
    "Temperature of object being contacted"
    temp::Float64
    "Coefficient of contact conduction"
    coef::Float64
    function ConductionBoundary(_, cts, prob, _)
        temp = prob.params.condTemp[cts.t]
        coef = prob.params.condCoef
        return new(temp, coef)
    end
end

"""
$(TYPEDEF)
A boundary for a face that has a source of convective heat flow.

# Fields
$(TFIELDS)
"""
struct ConvectionBoundary <: AbstractBoundary
    "Air temperature"
    temp::Float64
    "Convection coefficient"
    coef::Float64
    function ConvectionBoundary(_, cts, prob, _)
        temp = prob.params.convTemp[cts.t]
        coef = prob.params.convCoef
        return new(temp, coef)
    end
end

"$(TYPEDSIGNATURES)"
Types.boundaryHeatTransferRate(_, _, _::SymetryBoundary) = 0.0
"$(TYPEDSIGNATURES)"
Types.boundaryHeatTransferRate(T, _, p::ConductionBoundary) = conductionFlow(T, p.temp, p.coef)
"$(TYPEDSIGNATURES)"
Types.boundaryHeatTransferRate(T, _, p::ConvectionBoundary) = convectionFlow(T, p.temp, p.coef)
