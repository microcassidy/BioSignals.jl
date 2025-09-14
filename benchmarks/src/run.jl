include("WaveformDBBench.jl")
using .WaveformDBBench
using BenchmarkTools
function (@main)(ARGS)
    results = runner()
    BenchmarkTools.save(ARGS[1], results)
end
