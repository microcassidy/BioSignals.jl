include("WaveformDBBench.jl")
using .WaveformDBBench
using BenchmarkTools
function (@main)(ARGS)
    # results = runner()
    old_results = BenchmarkTools.load(String(ARGS[1]))[1]
    results = run(WaveformDBBench.SUITE;verbose=true)
    judgement = BenchmarkTools.judge(minimum(results), minimum(old_results))
    print(judgement)
    # BenchmarkTools.save(ARGS[1], results)
end
