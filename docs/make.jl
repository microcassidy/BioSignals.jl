using Documenter
using WaveformDB

makedocs(
  sitename="WaveformDB",
  format=Documenter.HTML(prettyurls=get(ENV, "CI", nothing) == "true"),
  modules=[WaveformDB],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
