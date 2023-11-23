using HSSSimulations

struct MatPropTD{T1,T2,T3,T4,T5,T6,T7,T8,T9} <: Types.AbstractMatProp
    ρ::T1
    c::T2
    κ::T3
    """ Melting rate to temp and melt state relationship.
    A 2d interpolation, with the first input axis being the temperature and the
    second the current melt state. The output is the melt rate.
    """
    Ḟ::T4
    """ Crystallisation rate to temp, melt state and maximum melt state relationship.
    A 3d interpolation, with the first input axis being the node temperature,
    the second the current melt state and the third the maximum melt state
    reached. The output is the recrystalisation rate.
    """
    Ṙ::T5
    Hf::T6
    Hr::T7
    Ċ::T8
    eₚ::Float64
    eᵢ::Float64
    ε::Float64
    name::String
    Mₘ::T9
end

function MatPropTD(ρ, c, κ, Ṁ, Ṙ, Hf, Hr, Ċ, eₚ, eᵢ, ε, name, geometry)
    geomSize = (geometry.X, geometry.Y, geometry.Z)
    Mₘ = zeros(geomSize)

    return MatPropTD{
        typeof(ρ),typeof(c),typeof(κ),
        typeof(Ṁ),typeof(Ṙ),typeof(Hf),typeof(Hr),
        typeof(Ċ),typeof(Mₘ),
    }(
        ρ, c, κ,
        Ṁ, Ṙ, Hf, Hr,
        Ċ,
        eₚ, eᵢ, ε,
        name, Mₘ,
    )
end

function Material.meltUpdate(Mᵗ⁻¹, T, Mₘ, Δt, mp::MatPropTD)
    ṀF = mp.Ḟ(T, Mᵗ⁻¹)
    ṀR = mp.Ṙ(T, Mᵗ⁻¹, Mₘ)

    if ṀF > -ṀR
        ΔM = ṀF * Δt
        ΔH = ΔM * mp.Hf
    else
        ΔM = ṀR * Δt
        ΔH = ΔM * mp.Hr(Mₘ)
    end
    Mᵗ = clamp(Mᵗ⁻¹ + ΔM, 0, 1)
    Mₘ = max(Mᵗ, Mₘ)

    return Mᵗ, Mₘ, Δh
end

using Interpolations

melt_temps = [170, 180, 190]

melt_state = [0, 1]

melt_rate = [
    0 0.02 0.03
    0 0.01 0.02
]

PA_Ṁ = linear_interpolation(
    (melt_temps, melt_state),
    melt_rate;
    extrapolation_bc=Flat(),
)

PA_Ṁ[175, 0.5]

recryst_temps = [150, 180]
melt_state = [0, 1]
melt_max = [0, 1]

recryst_rate = [
    0.1 0;
    0.5 0
    ;;;
    0.2 0;
    0.8 0
]

PA_Ṙ = linear_interpolation(
    (recryst_temps, melt_state, melt_max),
    recryst_rate;
    extrapolation_bc=Flat(),
)

PA_Ṙ[160, 0.2, 0.733]

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

material = MatPropTD(
    Material.PA_ρ(),
    Material.PA_c(),
    Material.PA_κ(),
    PA_TD_M,
    PA_TD_R,
    Material.PA_Hf(),
    Material.PA_Hr(),
    Material.PA_Ċ,
    Material.PA_eₚ,
    Material.PA_eᵢ,
    Material.PA_ε,
    "Time dependent PA2200",
    geometry,
)

params = HSSParams(geometry)
loadSets = HSSLoads(4, geometry; nrPreheat=90, lenPreheat=10.0, nrCool=90, lenCool=10.0)

size = (geometry.X, geometry.Y, geometry.Z)
init = Result(size, 25.0, 0.0, 0.0)
initialLayer = 10

inkArray = fill(material.eₚ, size)
inkArray[5:end-4, 5:end-4, 60:end-10] .= material.eᵢ
ink = Ink(inkArray, "Sample square")

file = "material_model_tutorial.jld2"
description = "A simulation to test a time dependent melt model"

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
