module Benchmarks
const DATA_DIR = joinpath(@__DIR__, "..", "sample-data")
using VibrationAnalysis

using BenchmarkTools

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0
BenchmarkTools.DEFAULT_PARAMETERS.samples = 10000
BenchmarkTools.DEFAULT_PARAMETERS.time_tolerance = 0.15
BenchmarkTools.DEFAULT_PARAMETERS.memory_tolerance = 0.01

const SUITE = BenchmarkGroup()


for file in readdir(joinpath(@__DIR__,"bench"),true)
    Core.eval(Benchmarks,:(include($file)))
end



runner() = run(Benchmarks.SUITE;evals=100,seconds =5,samples =1000)
_ = runner()

function display_results()
    # results = runner() 
    # display(results)
    # return
    # @info methods(results)
    # return
    for (subj,ks) in runner()
        @info "foo"
        print("$subj:\n")
        for (fun_name,result) in pairs(ks) 
            print("\t$fun_name\n")
            display(result)
        end
    end
end

end #MODULE END
