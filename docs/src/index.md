# Modelling of HSS (and related technologies)

This is the package created as a part of my (Oliver Leete) PhD thesis. Its goal
is as the title suggests, to create a simulation of a High Speed Sintering (HSS)
build by approximating the build volume as a single solid object. This is done
by having a complex material model to approximate the thermal behaviour of the
powder and how it changes when the powder starts to become part of a part.

This documentation will try its best to follow the [Diátaxis Documentation
Framework](https://diataxis.fr/).

If you are new to the package and want a guide on how to get started running
simulations, check out the tutorials section. These tutorials are also available
as notebooks in the example folder of the repo.

Once you have a grip on the basics, you can check out the recipes section for
how-to guides on making larger changes to the simulations. The top of the page
should have links to the parts of the API that it's helpful to have familiarised
yourself with. The examples on each page will typically build up in complexity,
so if you are struggling to follow a later example, have a look at the previous
ones to see if it helps.

The API is available in the references section, it's split into three levels.
The main API contains everything required for a normal simulation. The advanced
API covers functions and types that can be useful for getting some more control
over your simulations (like in the ways shown in some of the recipes). Post
processing shows the included tools to help process the simulation output.
And the internals cover the functions that are intended to be used purely
internally, for if you want to have a crack at modifying the codebase itself.

Finally, if you want to know more about what is being simulated, why you'd want
to simulate it, and why some of the choices have been made, check out the
explanations section (and my thesis). There should also be a brief overview of
the structure of the code to help if you want to modify the code to do things
that aren't possible with the API alone. Although, as always, documentation can
fall behind code, so trust what the code says more than the docs.

## Contribution

If you are reading this I have probably finished my PhD, so it is unlikely I
will be making any major improvements to this codebase. However, I will try to
keep an eye on the original repository (the one on my personal GitHub account),
so if you add any cool new features feel free to open a pull request there.
