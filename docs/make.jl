using Documenter
using WaveformDB

makedocs(
  modules=[WaveformDB],
  sitename="WaveformDB.jl",
authors = "Michael Cassidy",
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/microcassidy/WaveformDB.jl",
    push_preview=true
)
