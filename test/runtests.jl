using GZip

using Test, WaveformDB
using WaveformDB:
    format8,
    format16,
    format24,
    format32,
    format61,
    format80,
    format160,
    format212,
    format310,
    format311,
    StorageFormat,
    AbstractStorageFormat
include(joinpath(@__DIR__, "utils.jl"))

target_record(t) = joinpath(TARGET_OUTPUT, t)
read_target_record(record, T::Type{<:Real}) = read_delimited(target_record(record), T)
function read_target_record(record, delimiter, T::Type{<:Real})
    read_delimited(target_record(record), delimiter, T)
end

const lines_mapping = Dict([
    :format8 => 1,
    :format16 => 2,
    :format61 => 3,
    :format80 => 4,
    :format160 => 5,
    :format212 => 6,
    :format310 => 7,
    :format311 => 8,
    :format24 => 9,
    :format32 => 10,
])

const bindata_recordline = "binformats 10 200 499"
const spec_lines = [
    "binformats.d0 8 200/mV 12 0 -2047 -31143 0 sig 0, fmt 8",
    "binformats.d1 16 200/mV 16 0 -32766 -750 0 sig 1, fmt 16",
    "binformats.d2 61 200/mV 16 0 -32765 -251 0 sig 2, fmt 61",
    "binformats.d3 80 200/mV 8 0 -124 -517 0 sig 3, fmt 80",
    "binformats.d4 160 200/mV 16 0 -32763 747 0 sig 4, fmt 160",
    "binformats.d5 212 200/mV 12 0 -2042 -6824 0 sig 5, fmt 212",
    "binformats.d6 310 200/mV 10 0 -505 -1621 0 sig 6, fmt 310",
    "binformats.d7 311 200/mV 10 0 -504 -2145 0 sig 7, fmt 311",
    "binformats.d8 24 200/mV 24 0 -8388599 11715 0 sig 8, fmt 24",
    "binformats.d9 32 200/mV 32 0 -2147483638 19035 0 sig 9, fmt 32",
]
const recordline = WaveformDB.parse_record_line(bindata_recordline)

function H(sl)
    WaveformDB.Header(
        recordline[:record_name],
        recordline[:number_of_segments],
        recordline[:number_of_signals],
        recordline[:sampling_frequency],
        recordline[:counter_frequency],
        recordline[:base_counter_value],
        recordline[:samples_per_signal],
        recordline[:base_time],
        recordline[:base_date],
        DATA_DIR,
        sl,
    )
end

@testset "WaveformDB.jl" begin
    include("test_readers.jl")
    include("test_writers.jl")
end
