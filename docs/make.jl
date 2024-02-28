using Revise;
Revise.revise();

using HSSSimulations
using Documenter
using Literate

using HSSSimulations.Types
using HSSSimulations.Material
using HSSSimulations.Results
using HSSSimulations.Boundary
using HSSSimulations.Solver
using HSSSimulations.HSSBound
using HSSSimulations.PostProcessing

latex = haskey(ENV, "LATEX_DOCS")

tutorials = [
    ("Full Build", "full_tut.jl"),
    ("Warm-up and Cool-down only", "basic_tut.jl"),
    ("A Melt Rate Based Material Model", "material_tut.jl"),
    ("Saving More Results", "res_tut.jl"),
]

# Totally stole this logic from the gridap tutorial page
pages_dir = joinpath(@__DIR__, "src", "tutorials")
notebooks_dir = joinpath(@__DIR__, "..", "examples")
script_dir = joinpath(@__DIR__, "..", "test", "tutorial_tests")

repo_src = joinpath(@__DIR__, "lit")

tut_pages = []

binder_logo = "https://mybinder.org/badge_logo.svg"
nbviwer_logo = "https://img.shields.io/badge/show-nbviewer-579ACA.svg"

for (i, (title, filename)) in enumerate(tutorials)
    # Generate strings
    tutorial_title = string("# # Tutorial ", i, ": ", title)
    tutorial_file = string(i, "_", splitext(filename)[1])
    notebook_filename = string(tutorial_file, ".ipynb")

    binder_url = "https://mybinder.org/v2/gh/Oliver-Leete/HSSSimulations.jl/main?filepath=examples/$notebook_filename"
    nbviwer_url = "https://nbviewer.org/github/Oliver-Leete/HSSSimulations.jl/blob/main/examples/$notebook_filename"

    binder_badge = string("# [![](", binder_logo, ")](", binder_url, ")")
    nbviwer_badge = string("# [![](", nbviwer_logo, ")](", nbviwer_url, ")")

    # Generate notebooks
    preprocess_notebook(content) = string(tutorial_title, "\n\n", """
    using Pkg
    Pkg.dev("https://github.com/Oliver-Leete/HSSSimulations.jl.git")
    """, content)
    Literate.notebook(
        joinpath(repo_src, filename),
        notebooks_dir;
        name=tutorial_file,
        preprocess=preprocess_notebook,
        documenter=false,
        execute=false,
    )

    # Generate markdown
    function preprocess_docs(content)
        if latex
            return string(tutorial_title, "\n\n", content)
        else
            return string(tutorial_title, "\n", binder_badge, "\n", nbviwer_badge, "\n\n", content)
        end
    end
    Literate.markdown(
        joinpath(repo_src, filename),
        pages_dir;
        name=tutorial_file,
        preprocess=preprocess_docs,
        codefence="```julia" => "```",
        execute=false,
    )

    # Genrate file for integration tests
    Literate.script(joinpath(repo_src, filename), script_dir; name=tutorial_file, execute=false)

    # Generate navigation menu entries
    push!(tut_pages, string("tutorials/", tutorial_file, ".md"))
end

DocMeta.setdocmeta!(HSSSimulations, :DocTestSetup, :(
        using HSSSimulations;
        using HSSSimulations.Types;
        using HSSSimulations.Material;
        using HSSSimulations.Results;
        using HSSSimulations.Boundary;
        using HSSSimulations.Solver;
        using HSSSimulations.HSSBound;
        using HSSSimulations.PostProcessing
    ); recursive=true)

tut_intro = latex ? "tutorials/intro-pdf.md" : "tutorials/intro.md"
tut_pages = [tut_intro; tut_pages]
api_pages = [
    "reference/api.md",
    "reference/adv_intro.md",
    "reference/types.md",
    "reference/res.md",
    "reference/material.md",
    "reference/boundary.md",
    "reference/hssbound.md",
    "reference/solver.md",
    "reference/postprocessing.md",
]
recipe_pages = [
    "howtos/howto_intro.md",
    "howtos/howto_ink.md",
    "howtos/howto_subsets.md",
    "howtos/howto_mat.md",
    "howtos/howto_matprop.md",
    "howtos/howto_result.md",
    "howtos/howto_load.md",
    "howtos/howto_bound.md",
    "howtos/howto_param.md",
    "howtos/howto_loadset.md",
    "howtos/howto_problem.md",
]

reference_pages = latex ? api_pages : [api_pages[1], "Modules" => api_pages[2:end]]

pages = [
    "index.md",
    "Tutorials" => tut_pages,
    "Reference" => reference_pages,
    "Recipes" => recipe_pages,
    "explanation/faqs.md",
    "doc_index.md",
]
if !haskey(ENV, "DOCTEST_ONLY")
    makedocs(;
        sitename="High Speed Sintering Simulations",
        pages=pages,
        modules=[HSSSimulations],
        format=if latex
            Documenter.LaTeX()
        else
            Documenter.HTML(; prettyurls=get(ENV, "CI", nothing) == "true")
        end,
    )
    if latex
        mv(
            joinpath(@__DIR__, "build/HighSpeedSinteringSimulations.pdf"),
            joinpath(@__DIR__, "../HighSpeedSinteringSimulations.pdf");
            force=true,
        )
    else
        deploydocs(; repo="github.com/Oliver-Leete/HSSSimulations.jl")
    end
else
    doctest(HSSSimulations; fix=haskey(ENV, "DOCTEST_FIX"))
end
