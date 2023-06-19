"""
$(TYPEDSIGNATURES)

Returns a vector of heat flux density coefficients representing the lamp, with the same node spacing
as the simulation. The returned vector can be multiplied by the lamp power, in watts, to get a
vector of heat flux densities of the lamp.

# Arguments

  - `lampVector::Vector` : A vector represeting the heat distribution of the lamp in the y axis
  - `lampWidth` : The total width represented by the lamp vector (in the y axis, in nodes).
  - `geometry::Geometry` : The simulation geometry

!!! note

    If the lamp width divided by the length of the lamp vector is not equal to the Δy then linear
    interpolation is used to fill in the values.

!!! warn

    This uses the Δx and Δy node spacings to calculate the area used to convert to heat flux
    density, because of this it is only applicable to the z₁ and z₂ boundaries.
"""
function lampMaker(lampVector::Vector, lampWidth, geometry::Geometry)
    # The all caps version is the width in number of nodes
    # Take a shortcut if the vector is the right length, interpolate the values if not
    if lampWidth == length(lampVector)
        adjustedVector = lampVector
    else
        tmpRange = range(1, lampWidth, length(lampVector))
        interpolation = linear_interpolation(tmpRange, lampVector)
        adjustedVector = [interpolation(i) for i in 1:lampWidth]
    end

    # Divide by the sum of the total weighted array. So if it was expanded to a 2d array the width
    # of the build it would total to 1.
    vector_sum = sum(adjustedVector) * geometry.X_BUILD
    normLampVec = adjustedVector ./ vector_sum

    # Divide by the area of the nodes area on the top surface to convert from a heat flow
    # coefficient to a heat flux coefficient
    area = geometry.Δx * geometry.Δy
    lampq = normLampVec ./ area

    return lampq
end

"""
$(TYPEDSIGNATURES)

Calculates the new temperature of a an overhead heater that has a given power output and is set to a
given power (`powerIn`) values.

# Arguments

  - `powerOut` : A function that takes the temperatu of the heater and returns the power output
  - `overheadHeatCapacity` : The heat capacity of the overhead heater
  - `prevOverheadTemp` : The previous temperature of the overhead heaters
"""
function overheadTempFunc(powerIn, powerOut, overheadHeatCapacity, Δt, prevOverheadTemp)
    powerOut = powerOut(prevOverheadTemp)
    energy = (powerIn - powerOut) * Δt
    ΔT = energy / overheadHeatCapacity
    currOverheadTemp = prevOverheadTemp + ΔT

    return currOverheadTemp
end

"""
$(TYPEDSIGNATURES)

Sets the time that the cooling starts, to be used to calculate how far into the cooling the
simulation is during future time steps.

It also finds how far into the cooling curves of the different components to start based on the
current temperature of that component. If the current temperature is less than any temperature in
the cooling curve it will default to starting at the end of the curve.

This requires the type of `pistonCool`, `airCool` and `surfaceHeat` have methods for `findfirst`
"""
function coolingStart(tₚ, t, params::AbstractProblemParams)
    params.coolStart = t

    pc = params.pistonCool
    pistonOld = params.pistonHeat(tₚ)
    pb = bounds(pc.itp)[1][1]:bounds(pc.itp)[1][2]
    pistonCoolStart = findfirst(x -> pc(x) <= pistonOld, pb)
    params.pistonCoolStart = isnothing(pistonCoolStart) ? 0 : pistonCoolStart - 1

    ac = params.airCool
    airOld = params.airHeat(tₚ)
    ab = bounds(ac.itp)[1][1]:bounds(ac.itp)[1][2]
    airCoolStart = findfirst(x -> ac(x) <= airOld, ab)
    params.airCoolStart = isnothing(airCoolStart) ? 0 : airCoolStart - 1

    sc = params.surfaceCool
    surfaceOld = params.surfaceHeat(tₚ)
    sb = bounds(sc.itp)[1][1]:bounds(sc.itp)[1][2]
    surfaceCoolStart = findfirst(x -> sc(x) <= surfaceOld, sb)
    params.surfaceCoolStart = isnothing(surfaceCoolStart) ? 0 : surfaceCoolStart - 1
    @debug "coolingStart" _group = "hss" t params.coolStart params.pistonCoolStart params.airCoolStart params.surfaceCoolStart
end
