using Documenter
using WaveformDB

@info readdir()

const SRC_PATH = joinpath(@__DIR__,"src")


pages = [
    "Home" => "index.md",
    "Library" => [
      "Contents" => "library/outline.md",
      "Public" => "library/public.md",
      "Private" => "library/internals.md",
      "Function index" => "library/function_index.md"]
]

makedocs(
  modules=[WaveformDB],
  format = Documenter.HTML(),
  sitename="WaveformDB.jl",
  pages = pages,
  authors = "Michael Cassidy",
)
# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/microcassidy/WaveformDB.jl",
    push_preview=true,
)
