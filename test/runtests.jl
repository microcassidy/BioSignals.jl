using Wfdb
using Test
include("utils.jl")
target_record(t) = joinpath(TARGET_OUTPUT, t)
read_target_record(record, T::Type{<:Real}) = read_delimited(target_record(record), T)
read_target_record(record, delimiter, T::Type{<:Real}) = read_delimited(target_record(record), delimiter, T)

@testset "Wfdb.jl" begin
    header = headerfiles() |> first |> read_header
    signalinfo = header_signal(header)
    @info typeof.(signalinfo)
    read_signal(header)
end

@testset "test01_00s.hea" begin
    fname = "test01_00s.hea"
    path = joinpath(DATA_DIR, fname)
    header = read_header(path)
    target = read_target_record("record-1a", Int16)
    signal = read_signal(header)
    signal ≈ target
end

@testset "100.hea" begin
    fname = "100.hea"
    path = joinpath(DATA_DIR, fname)
    header = read_header(path)
    target_path = joinpath(DATA_DIR, "100.csv")
    labels, target = read_delimited(target_path, ",", true, Float16)
    signal = read_signal(header)
    @info samples_per_signal(header)
    signal ≈ target
end
