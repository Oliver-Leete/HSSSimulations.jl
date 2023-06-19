# High Speed Sintering Boundary Explanation

Here we will cover the details on exactly what it is that the example boundary
is replicating. We will cover this one boundary at a time. As the simulation is
a cuboid, it has six external surfaces, each of which must have defined boundary
conditions.

The simulation is to be compared to an array of identical, symmetrical
parts being printed. Assuming that this array is infinite results in
a symmetrical boundary condition. This means that the four conditions
representing the side walls (x₁, x₂, y₁ and y₂ in the notation used in
[`Types.Load`](@ref)), can all use the default boundary condition provided by
[`Boundary.SymetryBoundary`](@ref).

The bottom boundary (z₁) is where the build bed is in contact with the piston.
As the piston is one of the few consistent things on our machine, this can
be simulated as a constant temperature boundary with a contact conduction
coefficient. This is done using [`HSSBound.PistonBoundary`](@ref).

The final boundary, the top surface of the powder (z₂) is by far the most
complicated. It changes constantly throughout the build as new layers are added
and sintered.

## Overhead Heaters

In the default state with nothing happening the top boundary has heat loss due
to convection to the forced air draft over the surface and loss from radiation
to the surrounding surfaces. In addition, there is a stationary overhead
heater. During preheating (when the [`LoadSet`](@ref Types.AbstractLoadSet) `= PreheatLoadSet`) the overhead heater is set to a fixed power (Simulated using
[`HSSBound.loadOverheads`](@ref)).

Once the build starts, the overhead power is adjusted, starting at a set
amount (usually around 60% (of a 300W heater)) and changing by a set amount
(usually 1 percentile point) every set number of layers (usually every 3
layers) with the goal of reaching the target temperature of the top surface
(Simulated using [`HSSBound.loadOverheads`](@ref)). Once the build is finished
(when the [`LoadSet`](@ref Types.AbstractLoadSet) `= CooldownLoadSet`) the
overhead is turned off (set to 0W power) and left to cool down (Simulated using
[`HSSBound.loadCooldown`](@ref)).

The overhead heater boundary is implemented as a radiation boundary condition,
because of this the overhead temperature is needed (not the power, which is all
we defined above). For this, the [`HSSBound.overheadTempFunc`](@ref) is used to
calculate the change in temperature.

## Carriages

Most of this change comes from the movement of two carriages, the lamp carriage
and the print carriage. The first contains both the powder hopper (for
recoating) and the sinter lamp. The second contains the print heads used to
deposit the absorptive ink.

During each layer the following happens (described as if looking from the front
of the machine, with the x-axis going front to back, and slightly confusingly
the y-axis going right to left (don't ask, I regret this choice)):

  - The lamp carriage moves from left to right with the lamp set at sinter power
  - The lamp carriage moves from right to left with the lamp set to recoat power
    and the powder hopper deposits a layer of powder
  - The print carriage moves from right to left whilst doing nothing special
  - The print carriage moves from left to right as the print heads deposit the ink

In between each of the above steps are brief moments of simplicity, where the
only boundary conditions are those covered in previous sections. These gaps use
the aforementioned [`HSSBound.loadOverheads`](@ref). The carriage boundaries are
only actually used when the carriages are over the build bed, it is assumed that
if they are moving but not over the bed then they have no impact on the boundary
conditions so the [`HSSBound.loadOverheads`](@ref) can be used instead.

It is also worth noting, that when a carriage is in over the top of the build
bed, the build bed is shadowed from the overheads.
