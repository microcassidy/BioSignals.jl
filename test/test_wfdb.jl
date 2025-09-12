using GZip
using WaveformDB: format8,
format16,
format24,
format32,
format61,
format80,
format160,
format212,
format310,
format311

@testset "header" begin
  fname = "100.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
end

@testset "format212" begin
  fname = "100.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
  target_path = joinpath(DATA_DIR, "100.csv")
  labels, target = read_delimited(target_path, ",", true, Float16)
  _checksum, signal = rdsignal(header)
  @test all(mod.(checksum(header) - _checksum, 65536) .== 0)
  @test signal ≈ target
end

@testset "format16" begin
  fname = "test01_00s.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
  @test nsignals(header) == 4
  _checksum, signal = rdsignal(header)
  # @test checksum(header) == _checksum
  # @info checksum(header) - _checksum
  @test all(mod.(checksum(header) - _checksum, 65536) .== 0)
  @warn "not tested for target output"
  #TODO: target signal for format 16
end

@testset "format24" begin
  fname = "n8_evoked_raw_95_F1_R9.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
  _checksum, signal = rdsignal(header, false)
  targetpath = joinpath(@__DIR__, "target-output", "record-1e.gz")
  io = GZip.open(targetpath, "r")
  target = readlines(io) .|> strip .|> x -> split(x, "\t")
  target = reduce(hcat, target) .|> x -> parse(Int32, x)
  close(io)

  target[target.==-32768] .= -(2^23)
  @test signal ≈ target
  # target = reduce(hcat,target)
end
@testset "format32" begin
  @warn "not tested"
end

@testset "matlab" begin
    """
    The magic numbers replicate the command found in the python version
    tests/test_record.py:119:68:            rdsamp -r sample-data/a103l -f 80 -s 0 1 | cut -f 2- > record-1c
    """
    fname = "a103l.hea"
    path = joinpath(DATA_DIR, fname)
    header = rdheader(path)
    Fs = sampling_frequency(header)
    target = read_target_record("record-1c", Int16)
    _checksum, signal = rdsignal(header,false)
    @info "signal shape $(size(signal))"
    signal = signal[1:2, Integer(80 * Fs)+1:end]
    @test signal ≈ target
end

# using Base.Cartesian
# @testset "all-formats" begin
#   fname = "binformats.hea"
#   path = joinpath(DATA_DIR, fname)
#   header = rdheader(path)
#   _checksum, signal = rdsignal(header, false)

#   targetpath = joinpath(@__DIR__, "target-output", "record-1f.gz")
#   io = GZip.open(targetpath, "r")
#   target = readlines(io) .|> strip .|> x -> split(x, "\t")
#   target = reduce(hcat, target) .|> x -> parse(Int32, x)
# end

const lines_mapping = Dict([:format8 => 1,
                      :format16 => 2,
                      :format61 => 3,
                      :format80 => 4,
                      :format160 => 5,
                      :format212 => 6,
                      :format310 => 7,
                      :format311 => 8,
                      :format24 => 9,
                      :format32 => 10])

bindata_recordline = "binformats 10 200 499"
spec_lines = ["binformats.d0 8 200/mV 12 0 -2047 -31143 0 sig 0, fmt 8",
              "binformats.d1 16 200/mV 16 0 -32766 -750 0 sig 1, fmt 16",
              "binformats.d2 61 200/mV 16 0 -32765 -251 0 sig 2, fmt 61",
              "binformats.d3 80 200/mV 8 0 -124 -517 0 sig 3, fmt 80",
              "binformats.d4 160 200/mV 16 0 -32763 747 0 sig 4, fmt 160",
              "binformats.d5 212 200/mV 12 0 -2042 -6824 0 sig 5, fmt 212",
              "binformats.d6 310 200/mV 10 0 -505 -1621 0 sig 6, fmt 310",
              "binformats.d7 311 200/mV 10 0 -504 -2145 0 sig 7, fmt 311",
              "binformats.d8 24 200/mV 24 0 -8388599 11715 0 sig 8, fmt 24",
              "binformats.d9 32 200/mV 32 0 -2147483638 19035 0 sig 9, fmt 32"]

@testset "all formats" begin
  mt = methods(WaveformDB.read_binary)
  targetpath = joinpath(@__DIR__, "target-output", "record-1f.gz")
  io = GZip.open(targetpath, "r")
  target = readlines(io) .|> strip .|> x -> split(x, "\t")
  target = reduce(hcat, target) .|> x -> parse(Int32, x)

  #filter to the types with a formatxx subtype
  ty = [m.sig.types[end] for m in mt] |> filter(x-> x !== WaveformDB.WfdbFormat)
  ty = [t.parameters[1] for t in ty]

  recordline = WaveformDB.parse_record_line(bindata_recordline)
  #filter to the types with a formatxx subtype
  H(sl) = WaveformDB.Header(recordline[:record_name],
    recordline[:number_of_segments],
    recordline[:number_of_signals],
    recordline[:sampling_frequency],
    recordline[:counter_frequency],
    recordline[:base_counter_value],
    recordline[:samples_per_signal],
    recordline[:base_time],
    recordline[:base_date],
    DATA_DIR,
    sl)
  for T in ty
      @testset "$T" begin
        idx = lines_mapping[Symbol(T)]
        spec_line = [WaveformDB.parse_signal_spec_line(spec_lines[idx])]
        header = H(spec_line)
        _checksum,signal = rdsignal(header,false)
        t = target[idx,:]
        @test signal[1,:] ≈ t
      end
  end
end
