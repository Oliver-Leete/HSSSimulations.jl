"""
$(TYPEDSIGNATURES)

Returns a list of loads for the preheat, build and cooldown loadsets for a default build for the HSS
example. The same `skip` is used for all load steps (See [Why We Skip Some Results](@ref) for more
information on `skip`).

```jldoctest
julia> HSSLoads(10, Geometry((1,1,1),1,1); nrPreheat=5, lenPreheat=60.0, nrCool=5, lenCool=60.0, sinterSpeed=0.160)
3-element Vector{AbstractLoadSet}:
   name : Preheat
  loads
----------------------

  Name: Overheads Only
  For 5 loads



   name : Layer
  finishLayer : 0
  loads
----------------------

  Name: Overheads Only
  Name: Sintering
  Name: Overheads Only
  Name: Recoating
  Name: Overheads Only
  Name: No Inking
  Name: Overheads Only
  Name: Inking



   name : Cooldown
  loads
----------------------

  Name: Overheads Off
  For 5 loads
```
"""
function HSSLoads(
    skip, geometry;
    nrPreheat=5,
    lenPreheat=60.0,
    nrCool=5,
    lenCool=60.0,
    sinterSpeed=0.160,
    lcAndBedWidth=0.605,
)
    sinterDuration = lcAndBedWidth / sinterSpeed
    return [
        FixedLoadSet("Preheat", [
            loadOverheads(lenPreheat, skip)
            for _ in 1:nrPreheat
        ]),
        LayerLoadSet(
            "Layer",
            geometry.Nₗ,
            [
                loadOverheads(4.84, skip),
                loadSinterStroke(sinterDuration, skip),
                loadOverheads(1.6, skip),
                loadRecoatStroke(7.92, skip),
                loadOverheads(6.72, skip),
                loadBlankStroke(1.28, skip),
                loadOverheads(1.2, skip),
                loadInkStroke(1.28, skip),
            ],
        ),
        FixedLoadSet("Cooldown", [
            loadCooldown(lenCool, skip)
            for _ in 1:nrCool
        ]),
    ]
end
