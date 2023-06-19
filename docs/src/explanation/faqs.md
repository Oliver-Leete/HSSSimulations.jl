# FAQs

Well, no-one has actually asked me questions, but I imagine this is what people
might ask.

!!! tip
    
    For more in-depth explanations on anything, or for anything not covered here,
    you might be able to find more detailed answers in my thesis. Worst case,
    try emailing me.

## Why We Skip Some Results

The underlying solver used is an explicit time finite difference solver. This
is used as it is very cheap per time step solved (and things like the complex
boundaries and the material model work best with lots of time steps), however it
does have the issue of requiring lots of time steps to be stable.

While the quantity and computational cost sort of balance out to make it take a
reasonable time to solve, there is an issue that is caused by the solver choice.
As there are lots of time steps, this means there are lots of results, and
trying to find space for all of these is challenging.

To prevent the results files from filling up all your hard drive or from
crashing the simulation due to a lack of available memory, a `skip` parameter
was introduced. This parameter defines how often we want to save the results,
with a value of `1` not skipping any results, `2` only saving every second
result, `3` saving every third result and so on, the rest are thrown away as
soon as they are done with (after the following load).

It might seem a little strange to throw away results from a simulation, but as
long as you don't make the skip too big you will see that very little useful
information is lost.

## Why Use Explicit Time Finite Difference Method

Yeah I know, it's not the flashiest technique ever, and originally I only used
it to make a quick proof of concept as it is so easy to implement (of this
entire codebase, only about 6 lines of it are the actual FDM solver).

However, the more I tried to move away from it the more I realised it might
actually be the best method to use.
