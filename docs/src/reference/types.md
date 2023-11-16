# Types

```@docs
Types
```

## External

Most of the types that are intended for external use (other than those in the
main API) have instead been included with the modules that they are used in.
The types listed here under external are often passed into functions on the
public interface, so it is useful to understand their fields to know what can be
accessed when making new functions for these interfaces.

```@docs
Types.Geometry
Types.Problem
Types.LoadStep
Types.LoadTime
Types.Indices
```

## Internal

The methods and types listed below are only used within the simulation and
should not be needed when using any of the public API, basic or advanced.

```@docs
Types.AbstractSimProperty
Types.LoadTime(::Any,::Any,::Any,::Any)
```
