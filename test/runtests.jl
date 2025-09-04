using Test, BioSignals
include(joinpath(@__DIR__, "utils.jl"))
target_record(t) = joinpath(TARGET_OUTPUT, t)
read_target_record(record, T::Type{<:Real}) = read_delimited(target_record(record), T)
read_target_record(record, delimiter, T::Type{<:Real}) = read_delimited(target_record(record), delimiter, T)

@testset "BioSignals.jl" begin
    @testset "extension" begin
        @test get_extension("foo.bar") == ".bar"
        @test get_extension("foo.bar.baz") == ".bar.baz"
    end
    include("test_buffer.jl")
    include("test_wfdb.jl")
end

