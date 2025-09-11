using Test, WaveformDB
include(joinpath(@__DIR__, "utils.jl"))
target_record(t) = joinpath(TARGET_OUTPUT, t)
read_target_record(record, T::Type{<:Real}) = read_delimited(target_record(record), T)
read_target_record(record, delimiter, T::Type{<:Real}) = read_delimited(target_record(record), delimiter, T)

@testset "WaveformDB.jl"  begin
    include("test_wfdb.jl")
end

# julia-repl--script-buffer
