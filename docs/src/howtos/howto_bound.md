# Boundary Recipes

[`AbstractBoundary`](@ref) and [`boundaryHeatTransferRate`](@ref) are your
places to go for more information.

## A Fixed Heat Flux Boundary

```julia
struct FixedHeatFluxBoundary <: AbstractBoundary
    # Here goes the parameters that we will have access to in this boundaries
    # method for the boundaryHeatTransferRate. We wont actually have any for
    # this boundary
    # heat flux we want to use as the fixed value.

    # Our new boundary has to have a constructor that meets the signature
    # requirements detailed in the AbstractBoundary documentation. For this
    # boundary we don't need any of the inputs so we'll just discard them.
    FixedHeatFluxBoundary(_, _, _, _) = new()
end
```

This boundary needs to implement a method for the
[`boundaryHeatTransferRate`](@ref) function. This is what will be called on each
node of the simulation that is on the boundary. As with the constructor, our
simple boundary can ignore all the fields.

```julia
function Types.boundaryHeatTransferRate(_, _, _::FixedHeatFluxBoundary)
    # Return a floating point representing the heat flux density
    return 10.0
end
```

## A Variable Heat Flux Boundary

Let's raise the stakes a little (but not much), we'll make a new boundary that
has a heat flux density that changes depending only on the current time of the
simulation. We'll have to make a new [`AbstractProblemParams`](@ref) (the one
used here is from [A Variable Heat Flux Parameter Set](@ref) )

```julia
struct FixedHeatFluxBoundary <: Types.AbstractBoundary
    # All we need for this one is the heat flux we want to.
    heatFluxDensity::Float64

    # Our new boundary has to have a constructor that meets the signature
    # requirements detailed in the AbstractBoundary documentation. For this
    # boundary we only actually need two of the inputs, so we'll just discard
    # the rest of them.
    function RecoatCoolBoundary(_, cts, prob::Problem, _)
        # Normally a boundary's constructor would use the params field that we
        # gave to the problem quite a bit, so it's handy to make it easier to
        # access. In this case it will only be used once, but I'll keep this
        # here out of good habit anyway.
        param = prob.params

        # The current time step (cts) is given in, so lets grab its time to use
        # in our heat flux function.
        time = cts.t
        heatflux = param.heatflux(time)

        # Another useful field in prob is the problems geometry. Here we'll use
        # this to find out the area of a node, to convert our heat flux into a
        # heat flux density.
        geom = prob.geometry
        # Finding the area of the face of a node parallel to the y-axis
        area = geom.X * geom.Z
        heatfluxdensity = heatflux / area

        return new(heatfluxdensity)
    end
end
```

```julia
function Types.boundaryHeatTransferRate(_, _, p::FixedHeatFluxBoundary)
    # Return a floating point representing the heat flux density
    return p.heatfluxdensity
end
```

## A Cooling Recoat Boundary

This boundary behaves very similarly to the built-in boundary
[`RecoatBoundary`](@ref), but it uses the temperatures for the air and internal
surfaces. It also conditionally calls [`coolingStart`](@ref) to make sure that
the start time of the cool down stage is set. And the lamp is turned off (even
if there is a recoat lamp power set).

```julia
struct RecoatCoolBoundary <: Types.AbstractBoundary
    # All of the parameters we need to pass into the boundaryHeatTransferRate function
    overheadTemp::Float64
    surfaceTemp::Float64
    eₗ::Array{Float64,3}
    ε::Float64
    airTemp::Float64
    h::Float64
    shadow::Vector{Bool}
    Po::Float64

    function RecoatCoolBoundary(pts, cts, prob::Problem, ls::Types.LoadStep)
        param = prob.params

        # Use an overhead power of 0 w
        param.overheadTemp = overheadTemp = param.overheadHeatupFunc(0.0, param.overheadTemp, cts)

        # If the coolStart hasn't been set, set it
        if isnan(prob.params.coolStart)
            coolingStart(pts.t, cts.t, prob.params)
        end

        # Find how far through the cooling parameters the current time step is
        tAir = (cts.t - param.coolStart) + param.airCoolStart
        tSurface = (cts.t - param.surfaceCoolStart)

        # Use the Cool parameters to find the air and surface temperatures
        airTemp = param.airCool(tAir)
        surfaceTemp = param.surfaceCool(tSurface)

        # Get the other parameters to pass through
        eₗ = prob.eᵗ
        ε = prob.matProp.ε
        h = param.convectionCoef
        Po = param.percentOverhead

        # Calculate the position of the carriage and therefor its shadow
        pos = ceil(Int, (param.carriageWidth + prob.geometry.Y_BUILD) * cts.tₚ)
        shadowPos = (pos - param.carriageWidth, pos)
        shadow = movingObjOverlap(prob.geometry, true, shadowPos)

        # Calculate the distance across the bed the recoater has traveled, and
        # use it to set the new nodes
        recoatDist = pos - param.recoatOffset
        if prob.geometry.Y_OFFSET < recoatDist <= prob.geometry.Y_OFFSET + prob.geometry.Y
            recoatDist = recoatDist - prob.geometry.Y_OFFSET
            recoating!(pts, cts, prob, ls, recoatDist, surfaceTemp)
        end

        # Any new powder put down is set to have the machines ambient air
        # temperature as it's initial temperature
        z₂ᵣ = map(first, ls.ind.z₂)
        for i in z₂ᵣ
            if pts.T[i] == prob.init.T[i]
                pts.T[i] = airTemp
            end
        end

        return new(overheadTemp, surfaceTemp, eₗ, ε, airTemp, h, shadow, Po)
    end
end
```

The new method for the [`boundaryHeatTransferRate`](@ref) is the same as the
method use for the [`RecoatBoundary`](@ref) but without the lamp logic.

```julia
function Types.boundaryHeatTransferRate(T, i, p::RecoatCoolBoundary)
    shadow = p.shadow[i[2]]
    eₗ = p.eₗ[i]
    return (
        convectionFlow(T, p.airTemp, p.h) +
        radiationFlow(T, p.surfaceTemp, p.ε) * (shadow || (1 - p.Po)) +
        radiationFlow(T, p.overheadTemp, p.ε) * !shadow * p.Po
    )
end
```

Have a look at [A Cooling Recoat Load and Load Set](@ref) to see how to use this in a load.

## A Cooling Recoat Return Boundary

To make use of the above boundary, it would be handy to have a load that represents
the recoat carriage returning to its initial position (going in the other
direction to the above load).

```julia
struct RecoatCoolReturnBoundary <: AbstractBoundary
    overheadTemp::Float64
    surfaceTemp::Float64
    eₗ::Array{Float64,3}
    ε::Float64
    airTemp::Float64
    h::Float64
    shadow::Vector{Bool}
    Po::Float64

    function RecoatCoolReturnBoundary(pts, cts, prob::Problem, ls::Types.LoadStep)
        param = prob.params
        param.overheadTemp = overheadTemp = param.overheadHeatupFunc(0.0, param.overheadTemp, cts)

        # We'll still call this, in case we want to use this boundary before the previous one
        if isnan(param.coolStart)
            coolingStart(pts.t, cts.t, param)
        end

        tAir = (cts.t - param.coolStart) + param.airCoolStart
        tSurface = (cts.t - param.coolStart) + param.surfaceCoolStart
        airTemp = param.airCool(tAir)
        surfaceTemp = param.surfaceCool(tSurface)
        eₗ = prob.eᵗ
        ε = prob.matProp.ε
        h = param.convectionCoef
        Po = param.percentOverhead

        # Calculate the position of the carriage on its return stroke
        pos = ceil(Int, (param.carriageWidth + prob.geometry.Y_BUILD) * (1 - cts.tₚ))
        shadowPos = (pos - param.carriageWidth, pos)
        shadow = movingObjOverlap(prob.geometry, true, shadowPos)

        # No need to run any of the recoat logic for this one
        return new(overheadTemp, surfaceTemp, eₗ, ε, airTemp, h, shadow, Po)
    end
end

function Types.boundaryHeatTransferRate(T, i, p::RecoatCoolReturnBoundary)
    shadow = p.shadow[i[2]]
    eₗ = p.eₗ[i]
    return (
        convectionFlow(T, p.airTemp, p.h) +
        radiationFlow(T, p.surfaceTemp, p.ε) * (shadow || (1 - p.Po)) +
        radiationFlow(T, p.overheadTemp, p.ε) * !shadow * p.Po
    )
end
```
