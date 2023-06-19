# HSSSimulations.jl

[![Stable docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Oliver-Leete.github.io/HSSSimulations.jl)
[![Dev docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Oliver-Leete.github.io/HSSSimulations.jl/dev)

A package to simulate High Speed Sintering (HSS) by treating the powder bed as
a bulk material, using the finite difference method and a quasi-solid material
model.

As this is not in the Julia general registry, you will need to dev the package
using:

```julia
using Pkg
Pkg.dev("https://github.com/Oliver-Leete/HSSSimulations.jl.git")
```

If you are new to Julia, I'd recommend [checking out the getting started
documentation](https://docs.julialang.org/en/v1/manual/getting-started/)
