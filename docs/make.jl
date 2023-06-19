using Revise;
Revise.revise();

using HSSSimulations
using Documenter
using Literate

using HSSSimulations.Types
using HSSSimulations.Material
using HSSSimulations.Res
using HSSSimulations.Boundary
using HSSSimulations.Solver
using HSSSimulations.HSSBound
using HSSSimulations.PostProcessing

tutorials = [
    # ("Partial Build", "part_tut")
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
    binder_url = joinpath("@__BINDER_ROOT_URL__", "..", "examples", notebook_filename)
    nbviwer_url = joinpath("@__NBVIEWER_ROOT_URL__", "..", "examples", notebook_filename)
    binder_badge = string("# [![](", binder_logo, ")](", binder_url, ")")
    nbviwer_badge = string("# [![](", nbviwer_logo, ")](", nbviwer_url, ")")

    # Generate notebooks
    preprocess_notebook(content) = string(tutorial_title, "\n\n", content)
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
        return string(tutorial_title, "\n", binder_badge, "\n", nbviwer_badge, "\n\n", content)
        # return string(tutorial_title, "\n\n", content)
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
    push!(tut_pages, (string(i, " ", title) => string("tutorials/", tutorial_file, ".md")))
end

DocMeta.setdocmeta!(HSSSimulations, :DocTestSetup, :(
        using HSSSimulations;
        using HSSSimulations.Types;
        using HSSSimulations.Material;
        using HSSSimulations.Res;
        using HSSSimulations.Boundary;
        using HSSSimulations.Solver;
        using HSSSimulations.HSSBound;
        using HSSSimulations.PostProcessing
    ); recursive=true)

makedocs(;
    sitename="Powder Model Documentation",
    modules=[
        HSSSimulations,
    ],
    pages=[
        "Home" => "index.md",
        "Tutorials" => tut_pages,
        "Reference" => [
            "Public API" => [
                "Main API" => "reference/api.md",
                "Advanced API" => "reference/api_adv.md",
                "HSS Boundary" => "reference/BoundaryExamples.md",
                "Post proccessing" => "reference/PostProcessing.md",
            ],
            "Internals" => [
                "Internal APIs" => "reference/internal_api.md",
                "Private Internals" => "reference/internals.md",
            ],
        ],
        "Recipes" => [
            "Ink Patterns" => "howtos/howto_ink.md",
            "Simulate Subsets of a Build" => "howtos/howto_subsets.md",
            "Materials" => "howtos/howto_mat.md",
            "Material Models" => "howtos/howto_matprop.md",
            "Results" => "howtos/howto_result.md",
            "Loads and Load Sets" => "howtos/howto_load.md",
            "Boundaries" => "howtos/howto_bound.md",
            "Problem Parameters" => "howtos/howto_param.md",
            "Load Set Types" => "howtos/howto_loadset.md",
            "Problem Solvers" => "howtos/howto_problem.md",
        ],
        "Explanation" => [
            "HSS Boundary" => "explanation/HSSBoundary.md",
            "Material examples" => "reference/MaterialExamples.md",
            "FAQs" => "explanation/faqs.md",
        ],
        "Index" => "doc_index.md",
    ],
    format=Documenter.HTML(),
    # format = Documenter.LaTeX()
)
deploydocs(;
    repo="github.com/Oliver-Leete/HSSSimulations.jl",
)
