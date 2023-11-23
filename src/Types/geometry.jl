# NOTE : While it might be useful to make a new Geometry type for non-rectangular machines if they
# ever become available, it would require a rewrite of most functions. So I would only recomend
# undertaking that if you have a good understanding of the entire codebase (hence why I havn't
# included an AbstractGeometry). This is because most functions that use the geometry don't dispatch
# on the geometry type, and a lot of functions need at least some of the geometry fields. Try
# grepping for geom to see how much it's used.

"""
$(TYPEDEF)

Defines the geometry of the build volume (and the simulation volume within that (if only a subset of
a build is being simulated).

# Fields
$(TYPEDFIELDS)
"""
struct Geometry <: AbstractSimProperty
    "The size of the x axis of the model in meters"
    x::Float64
    "The size of the y axis of the model in meters"
    y::Float64
    "The size of the z axis of the model in meters"
    z::Float64
    "The size of the x axis of the model in nodes"
    X::Int
    "The size of the y axis of the model in nodes"
    Y::Int
    "The size of the z axis of the model in nodes"
    Z::Int
    "Tuple of the XYZ sizes"
    size::Tuple{Int,Int,Int}

    "The x axis offset of the model from the machines datum in meters"
    xoffset::Float64
    "The y axis offset of the model from the machines datum in meters"
    yoffset::Float64
    "The x axis offset of the model from the machines datum in nodes"
    X_OFFSET::Int
    "The y axis offset of the model from the machines datum in nodes"
    Y_OFFSET::Int

    "The total x axis size of the machine from which the subset is taken in meters"
    xbuild::Float64
    "The total y axis size of the machine from which the subset is taken in meters"
    ybuild::Float64
    "The total x axis size of the machine from which the subset is taken in nodes"
    X_BUILD::Int
    "The total y axis size of the machine from which the subset is taken in nodes"
    Y_BUILD::Int

    "The spacing of the nodes in meters in the x axis"
    Δx::Float64
    "The spacing of the nodes in meters in the y axis"
    Δy::Float64
    "The spacing of the nodes in meters in the z axis"
    Δz::Float64
    "The spacing of timesteps in seconds"
    Δt::Float64

    "The number of layers in the model"
    Nₗ::Int
    "The layer height in nodes"
    Δh::Float64
    "The layer height in meters"
    ΔH::Int

    "Just used for future reference of results"
    name::String
end

"""
    $(FUNCTIONNAME)(
        simSize, Δx, Δt;
        Δy=Δx, Δz=Δx, name="NA", Δh=0,
        offset=(0.0, 0.0), buildSize=nothing,
        force=false,
    )

Constructor for the [`Geometry`](@ref) type that is is used to store all of the geometry information
(and time step length for some reason) for a rectangular build volume of the machine being simulated
(given as the `buildSize`). It also saves the information for the subset of the build volume to
actually be simulated (of size `simSize`, offset form the machine origin by `offset`), if the full
build volume is not being simulated. If no `buildSize` is given then it is assumed to be just big
enougth to fit the `simSize` with the given `offset`.

`Δh` is the layer height in meters. If it is given as `0` (or not given) then it is assumed
that the simulation isn't representing a full build, but instead something like the preheat or
cooldown phase. In this case no layer recoat logic can be run (make sure not to include a recoating
[`Types.Load`](@ref)).

`Δt` is the time step (in seconds) and `Δx, Δy and Δz` are the node spacing (in meters). If not
given then `Δy and Δz` default to the same as `Δx`. The timestep is included in the geometry as
it is tied to the node spacing when it comes to making a stable simulation for the explicit finite
difference method used in this model.

If the `force` argement is given then the divisible errors will be suppressed, this will result in
the geometry not being properly represented.

!!! danger "Use With Caution"

    Use the `force` argument with great caution. It was only added to allow for the creation of
    geometries that were blocked due to floating point math errors. If it is used when things aren't
    actually divisible then it will result in the geometry not being properly represented, and a
    disconnect between what you think you are simulating and what is actually being simulated.
"""
function Geometry(
    simSize, Δx, Δt;
    Δy=Δx, Δz=Δx, name="NA", Δh=0,
    offset=(0.0, 0.0), buildSize=nothing,
    force=false, tolerance=0.0001,
)

    # If the force option is given anything that isn't properly divisible will just give a
    # warning instead of an error
    notDivFun = force ? (x -> @warn(x)) : (x -> throw(AssertionError(x)))

    x, y, z = simSize
    atol = tolerance

    # Checks for divisibility of the simulation size by the node spacing
    (isapprox(x % Δx, Δx; atol=atol) || isapprox(x % Δx, 0; atol=atol)) ||
        notDivFun("x must be divisible by Δx")
    (isapprox(y % Δy, Δy; atol=atol) || isapprox(y % Δy, 0; atol=atol)) ||
        notDivFun("y must be divisible by Δy")
    (isapprox(z % Δz, Δz; atol=atol) || isapprox(z % Δz, 0; atol=atol)) ||
        notDivFun("z must be divisible by Δz")

    # Convert mm dimensions to number of nodes
    X = Int(div(x, Δx, RoundNearest))
    Y = Int(div(y, Δy, RoundNearest))
    Z = Int(div(z, Δz, RoundNearest))
    sizes = (X, Y, Z)

    if Δh != 0
        (isapprox(Δh % Δz, Δz; atol=atol) || isapprox(Δh % Δz, 0; atol=atol)) ||
            notDivFun("Δh must be divisible by Δz")

        # Check the z axis of the simulation size is divisible by the layer height
        (isapprox(z % Δh, Δh; atol=atol) || isapprox(z % Δh, 0; atol=atol)) ||
            notDivFun("z must be divisible by Δh")
        Nₗ = Int(div(z, Δh, RoundNearest))
    else
        Nₗ = 0
    end

    ΔH = div(Δh, Δz, RoundNearest)

    # calculate the buildsize (if not given), and then set the x and y variables for it (and the
    # node distance equivalent variables).
    if isnothing(buildSize)
        buildSize = (offset[1] + x, offset[2] + y)
    end
    xbuild, ybuild = buildSize
    X_BUILD = ceil(Int, xbuild / Δx)
    Y_BUILD = ceil(Int, ybuild / Δy)

    # check the bounds of the offset/simsize/buildsize combination
    xoffset, yoffset = offset
    if xoffset + x > xbuild || yoffset + y > ybuild
        throw(
            AssertionError(
                "Your offset puts some of your simulation outside of the build area",
            ),
        )
    end
    # calculate the offsets in number of nodes
    X_OFFSET = ceil(Int, xoffset / Δx)
    Y_OFFSET = ceil(Int, yoffset / Δy)

    return Geometry(
        x, y, z,
        X, Y, Z,
        sizes,
        xoffset, yoffset,
        X_OFFSET, Y_OFFSET,
        xbuild, ybuild,
        X_BUILD, Y_BUILD,
        Δx, Δy, Δz, Δt,
        Nₗ, Δh, ΔH,
        name,
    )
end
