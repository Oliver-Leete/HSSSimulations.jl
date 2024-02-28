julia := "julia"
project-name := file_name(justfile_directory())
project-arg := " --project=" + project-name
docs-project := "docs"
docs-arg := " --project=" + docs-project
threads := "auto"
threads-arg := " --threads=" + threads
sysimage-arg := if path_exists("JuliaSysimage.so") == "true" { " --sysimage=JuliaSysimage.so" } else { "" }
julia-with-args := julia + project-arg + threads-arg + sysimage-arg + " "

# Run a live test server to run unit tests in without constantly reloading
test-server:
    {{ julia-with-args }} --eval 'using Revise, DaemonMode; print("Running test server"); serve(print_stack=true)'

# Run package tests
test:
    {{ julia-with-args }} test/runtests.jl

# Run the package tests and save the coverage report
test-coverage:
    {{ julia-with-args }} --code-coverage=user test/runtests.jl

# Run a live documentation server
serve-docs:
    {{ julia + threads-arg + docs-project }} --print '{{ """
        using Revise, """ + project-name + """, LiveServer
        servedocs(
            launch_browser=true;
            literate=joinpath("docs","lit"),
            include_dirs = ["src", "data"],
        )
    """ }}'

# Build the html documentation
build-html-docs:
    {{ julia-with-args }} docs/make.jl

# Build a pdf of the documentation
build-pdf-docs $LATEX_DOCS="true":
    just build-html-docs

# Open the html documentation
[linux]
open-html-docs:
    xdg-open ./docs/build/index.html

# Open the pdf documentation
[linux]
open-pdf-docs:
    xdg-open ./HighSpeedSinteringSimulations.pdf

# Run the doctests
doc-tests $DOCTEST_ONLY="true":
    just build-html-docs

# Update the doctest output
fix-doc-tests $DOCTEST_ONLY="true" $DOCTEST_FIX="true":
    just build-html-docs

# Run the formatter on all files
format:
    {{ julia }} --eval 'using JuliaFormatter, {{ project-name }}; format({{ project-name }}, format_markdown=true, verbose=true)'

# Run the package benchmarks
benchmark:
    {{ julia-with-args }} --eval 'using PkgBenchmark; benchmarkpkg("{{ project-name }}")'

# Tune the package benchmarks
tune-benchmark:
    {{ julia-with-args }} --eval 'using PkgBenchmark; benchmarkpkg("{{ project-name }}", retune=true)'

# Profile package imports
profile-imports:
    {{ julia }} --eval 'using InteractiveUtils; @time_imports using {{ project-name }}'

# Run the package's build
build:
    {{ julia-with-args }} --eval 'using Pkg; Pkg.build({{ project-name }})'

# Precompile the package
precompile:
    {{ julia-with-args }} --eval 'using Pkg; Pkg.precompile()'

# Build a sysimage for the project
compile:
    {{ julia + threads-arg + project-arg }} --eval '{{ """
        import Pkg
        version_specific_env_path = joinpath(@__DIR__, "..", "environments", "sysimagecompile", "v$(VERSION.major).$(VERSION.minor)")
        if isdir(version_specific_env_path)
            Pkg.activate(version_specific_env_path)
        else
            Pkg.activate(joinpath(@__DIR__, "..", "environments", "sysimagecompile", "fallback"))
        end


        import Libdl, PackageCompiler
        import TOML


        const config_fname = "./.vscode/JuliaSysimage.toml"

        function find_dev_packages(envdir::AbstractString)
            fname = joinpath(envdir, "Manifest.toml")
            !isfile(fname) && return Symbol[]
            devpkgs = Symbol[]
            parsed = TOML.parse(read(fname, String))
            deps = if parse(VersionNumber, get(parsed, "manifest_format", "1.0")) >= v"2.0"
                parsed["deps"]
            else
                parsed
            end
            for (key, sub) in deps
                "path" in keys(sub[1]) && push!(devpkgs, Symbol(key))
            end
            devpkgs
        end


        function read_configuration(envdir)
            fname = joinpath(envdir, config_fname)
            output = Dict(
                :precompile_execution_file=>String[],
                :precompile_statements_file=>String[],
                :excluded_packages=>Symbol[],
            )
            !isfile(fname) && return output

            parsed = get(TOML.parse(read(fname, String)), "sysimage", Dict{Any, Any}())
            output[:precompile_execution_file] = String[joinpath(envdir, x) for x in get(parsed, "execution_files", String[])]
            output[:precompile_statements_file] = String[joinpath(envdir, x) for x in get(parsed, "statements_files", String[])]
            output[:excluded_packages] = Symbol.(get(parsed, "exclude", Symbol[]))

            output
        end

        env_to_precompile = \"""" + justfile_directory() + """\"

        sysimage_path = joinpath(env_to_precompile, "JuliaSysimage.$(Libdl.dlext)")

        project_filename = isfile(joinpath(env_to_precompile, "JuliaProject.toml")) ? joinpath(env_to_precompile, "JuliaProject.toml") : joinpath(env_to_precompile, "Project.toml")

        project = Pkg.API.read_project(project_filename)

        # Read the configuration file
        config = read_configuration(env_to_precompile)
        dev_packages = find_dev_packages(env_to_precompile)

        # Assemble the arguments for the `create_sysimage` function
        used_packages = filter(x -> !(x in dev_packages || x in config[:excluded_packages]), Symbol.(collect(keys(project.deps))))
        precompile_statements = config[:precompile_statements_file]
        precompile_execution = config[:precompile_execution_file]

        used_pkg_string = join(String.(used_packages), "\n      - ")
        @info "Included packages: \n      - $(used_pkg_string)"
        @info "Precompile statement files: $precompile_statements"
        @info "Precompile execution files: $precompile_execution"

        PackageCompiler.create_sysimage(used_packages, sysimage_path = sysimage_path, project = env_to_precompile,
                                        precompile_statements_file=precompile_statements, precompile_execution_file=precompile_execution)
    """ }}' 
