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
over your simulations (like in the ways shown in some of the recipes).

One major deviation from the Diátaxis framework is the explanations section.
The normal contents of this section are instead partially provided in the other
sections, and my thesis is provided as a contiguous explanation of what is going
on. There is also a small FAQ section to provide brief explanation of some
things that come up often.

## Tutorials

```@contents
Pages = Main.tut_pages
Depth=1
```

## API

```@contents
Pages = api_pages
Depth=1
```

## Recipes

```@contents
Pages = Main.recipe_pages
Depth=1
```

## Other Pages

```@contents
Pages = ["explanation/faqs.md", "doc_index.md"]
Depth=1
```

## Contribution

If you are reading this I have probably finished my PhD, so it is unlikely I
will be making any major improvements to this codebase. However, I will try to
keep an eye on the original repository (the one on my personal GitHub account),
so if you add any cool new features feel free to open a pull request there.
