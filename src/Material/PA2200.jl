"""
Values from Yaun 2014 used for consolidation state of 0 and 1 (at a melt state of 0). And values
from Riedlbaur 2015 (I think originally from Rietzel 2011, but my German isn't good enough to
confirm) used for a melt state of 1.
"""
function PA_κ()
    return linear_interpolation(
        (0:1, 30:10:190, 0:1),
        cat(
            [
                0.092 0.09762 0.10047 0.10162 0.10368 0.10438 0.10566 0.10455 0.10648 0.10817 0.10953 0.10962 0.11299 0.11567 0.11765 0.24 0.3
                0.26  0.26395 0.27448 0.27417 0.27757 0.27138 0.26828 0.26457 0.25404 0.24196 0.24939 0.24877 0.24413 0.24072 0.23825 0.27 0.3
            ],
            [
                0.3 for i in 1:2, j in 1:17
            ];
            dims=3,
        );
        extrapolation_bc=(Flat(), (Line(), Flat()), Flat()),
    )
end

"""
Assumes density is constant across temperatures and at data sheet values for maximum consolidation
state. For consolidation and melt state zero, the measured value of the powder in the machine is
used. The melted density is based on observations while taking dilatometry measurments.
"""
PA_ρ() = linear_interpolation(
    (0:1, 0:1),
    [
        463 463
        950 706
    ];
    extrapolation_bc=Flat(),
)

cPath() = jldopen(joinpath(artifact"PA2200", "PA2200_c.jld2"))
"""
Data taken from stepscan of PA2200, processed by perkin-elmer dsc software. Melt region is interpolated over to avoide issuse with .
"""
PA_c() = linear_interpolation(
    cPath()["Temperature"],
    cPath()["Heat"];
    extrapolation_bc=Line(),
)

meltPath() = jldopen(joinpath(artifact"PA2200", "PA2200_Melt.jld2"))
"""
A normalized cumulative integral of the energy in to a system during melting from a DSC
curves.
"""
function PA_Mᵣ()
    return linear_interpolation(
        [175; meltPath()["Temperature"][2:end]],
        [0; meltPath()["Melt Ratio"][2:end]];
        extrapolation_bc=Flat(),
    )
end

"""
The difference between the energy in to the system during melting (from a DSC curve), and an
interpolated line drawn between the sections of heating outside of the melt region.
"""
PA_Hf() = meltPath()["Total Heat of Melting"]

coolPath() = jldopen(joinpath(artifact"PA2200", "PA2200_Cool.jld2"))
coolKeys() = Vector{Float64}(coolPath()["Keys"])
"""
A normalized cumulative integral of the energy out of a system during recrystallization from DSC
curves. With each curve taken from increasing melt states.
"""
function PA_Rᵣ()
    temp = coolPath()["Temperature"]
    return linear_interpolation(
        (temp, [0; coolKeys()[2:end]]),
        [
            [0 for i in 1:length(temp)] [coolPath()["$(i)/Melt Ratio"] for i in coolKeys()[2:end]]...
        ];
        extrapolation_bc=Flat(),
    )
end

"""
The difference between the energy out of the system during crystallization (from a DSC curve), and
an interpolated line drawn between the sections of cooling outside of the recrystallization region.
"""
function PA_Hr()
    return linear_interpolation(
        vcat(0.0, coolKeys()),
        vcat(0.0, [coolPath()["$(i)/Total Heat of Recrystallization"] for i in coolPath()["Keys"]]);
        extrapolation_bc=Flat(),
    )
end

"""
Based on model from Childs and Tontowi 2001. Modified to work off of consolidation and melt states .
Takes three coefficients (``βₛ, Aₛ, nₛ``) and returns a consolidation rate calculator that  .
follows the equation below                                                                         .

``
\\dot{C} = (1-C^{t-1}) A_s \\exp{\\left(-\\frac{E_s}{RT^{t-1}} - \\beta_s (1-M^{t-1})^{n_s}\\right)}
``

Where ``C^{t-1}`` is the previous consolidation state, ``M^{t-1}`` is the previous melt state, and
``T^{t-1}`` is the previous temperature.
"""
PA_Ċ_maker(βₛ, Aₛ, nₛ) = (C, T, M) -> (1 - C) * Aₛ * exp(-((12_400 / (273.15 + T)) + βₛ * (1 - M)^nₛ))

"""
Based on model from Childs and Tontowi 2001. Modified to work off of consolidation and melt states.
Calibrated from dilatometry data.
See [`Material.PA_Ċ_maker`](@ref) for how to make your own.
"""
PA_Ċ(C, T, M) = (1 - C) * 2.11138e10 * exp(-((12_400 / (273.15 + T)) + 4.5 * (1 - M)^4.0))

"""
Taken from near ir experiments.
"""
PA_eₚ = 0.203
"""
Taken from near ir experiments.
"""
PA_eᵢ = 0.833

"""
Taken from pyrometer calibrations.
"""
PA_ε = 0.92

"""
$(TYPEDSIGNATURES)

An example material based on PA2200, using a rate of consolidation based on melt state. With eyeball
correction to consolidation rate. See [PA2200](@ref) for information on each of the fields.
"""
function PA2200(geometry::Geometry)
    return MatProp(
        PA_ρ(),
        PA_c(),
        PA_κ(),
        PA_Mᵣ(),
        PA_Rᵣ(),
        PA_Hf(),
        PA_Hr(),
        PA_Ċ,
        PA_eₚ,
        PA_eᵢ,
        PA_ε,
        "PA2200",
        geometry,
    )
end
