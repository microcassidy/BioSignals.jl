using Wfdb
using Test
include("utils.jl")
include("../src/utils.jl")
target_record(t) = joinpath(TARGET_OUTPUT, t)
read_target_record(record, T::Type{<:Real}) = read_delimited(target_record(record), T)
read_target_record(record, delimiter, T::Type{<:Real}) = read_delimited(target_record(record), delimiter, T)

# @testset "Wfdb.jl" begin
#     header = headerfiles() |> first |> read_header
#     signalinfo = header_signal(header,)
#     read_signal(header)
# end

@testset "test01_00s.hea" begin
    fname = "test01_00s.hea"
    path = joinpath(DATA_DIR, fname)
    header = read_header(path)
    target = read_target_record("record-1a", Int16)
    signal = read_signal(header, false)
    signal ≈ target
end

@testset "extension" begin
    @test get_extension("foo.bar") == ".bar"
    @test get_extension("foo.bar.baz") == ".bar.baz"
end

@testset "100.hea" begin
    fname = "100.hea"
    path = joinpath(DATA_DIR, fname)
    header = read_header(path)
    target_path = joinpath(DATA_DIR, "100.csv")
    labels, target = read_delimited(target_path, ",", true, Float16)
    signal = read_signal(header, true)
    signal ≈ target
end
@testset "matlab" begin
    """
    The magic numbers replicate the command found in the python version
    tests/test_record.py:119:68:            rdsamp -r sample-data/a103l -f 80 -s 0 1 | cut -f 2- > record-1c

    probably a pointless test, more for sanity
    """
    fname = "a103l.hea"
    path = joinpath(DATA_DIR, fname)
    header = read_header(path)
    Fs = sampling_frequency(header)
    target = read_target_record("record-1c", Int16)
    signal = read_signal(header, false)
    signal = signal[2:end, Integer(80 * Fs)+1:end]
    @info typeof(signal)
    @info "target $(size(target)) signal $(size(signal))"
    signal ≈ target
end
