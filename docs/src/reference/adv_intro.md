# Introduction

This section covers the reference documentation for all things not included in
the main API, split into the packages modules. The first part of each modules
documentation contains the documentation for the external 'advanced' API, these
are things that are intended for use to extend customise simulations beyond the
default behaviour. The second part are the internal functions not intended for
external use.

The external APIs are exported by their module, but not exported by the package,
so to use them you will need to either use their full address:

```@repl
using HSSSimulations
Solver.loadSetSolver!
```

or by using the module it is in:

```@repl
using HSSSimulations
using .Solver
loadSetSolver!
```
