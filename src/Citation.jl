module Citation

export deps, cite

using HTTP

import Pkg
PackageSpec = Pkg.Types.PackageSpec

JULIA_CITATION = """
@article{Julia-2017,
    title={Julia: A fresh approach to numerical computing},
    author={Bezanson, Jeff and Edelman, Alan and Karpinski, Stefan and Shah, Viral B},
    journal={SIAM {R}eview},
    volume={59},
    number={1},
    pages={65--98},
    year={2017},
    publisher={SIAM},
    doi={10.1137/141000671}
}
"""

function doi2bib(doi::AbstractString)
    return String(HTTP.get("http://data.crossref.org/$doi", ["Accept" => "application/x-bibtex"]).body)
end

function deps()
    ctx = Pkg.Types.Context()
    pkgs = PackageSpec[]
    Pkg.Operations.load_direct_deps!(ctx, pkgs)
    return pkgs
end

function collect_citations(paths)
    entries = String[]
    for path in paths
        isdir(path) || continue
        project = Pkg.Types.read_project(Pkg.Types.projectfile_path(path))
        if haskey(project.other, "metadata") && haskey(project.other["metadata"], "cite")
            cite = project.other["metadata"]["cite"]
            push!(entries, doi2bib(cite))
        elseif isfile(joinpath(path, "CITATION.bib"))
            cite = read(String, joinpath(path, "CITATION.bib"))
            push!(entries, cite)
        end
    end
    return entries
end

function cite(;cite_julia=false)
    paths = map(Pkg.Operations.source_path, deps())
    entries = collect_citations(paths)
    cite_julia && push!(entries, JULIA_CITATION)
    print(join(entries, "\n"))
end # module

end
