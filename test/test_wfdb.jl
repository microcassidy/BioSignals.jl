
@testset "header" begin
  fname = "100.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
end

using DelimitedFiles
@testset "format212" begin
  fname = "100.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
  target_path = joinpath(DATA_DIR, "100.csv")
  target  =readdlm(target_path, ',', Float32, '\n';skipstart=1)
  # labels, target = read_delimited(target_path, ",", true, Float16)
  _checksum, signal = rdsignal(header)
  @test all(mod.(checksum(header) - _checksum, 65536) .== 0)
  @test signal ≈ target'
end

@testset "format16" begin
  fname = "test01_00s.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
  @test nsignals(header) == 4
  _checksum, signal = rdsignal(header)
  @test all(mod.(checksum(header) - _checksum, 65536) .== 0)
  @warn "not tested for target output"
  #TODO: target signal for format 16
end

function opengzip!(io::IO,func::T where {T <: Function} )
  readdlm(io, '\t', Int32, '\n';use_mmap=true)' .|> func
end

function fixnans(val::T)::T where T <: Real
  ifelse(val == -32768 , -2^23, val)
end

function test_fmt24()
  targetpath = joinpath(@__DIR__, "target-output", "record-1e.gz")
  target = Matrix{Int32}(undef,(2, 2022144))
  io = GZip.open(targetpath, "r")

  @time target =opengzip!(io,fixnans)
  fname = "n8_evoked_raw_95_F1_R9.hea"
  path = joinpath(DATA_DIR, fname)
  header = rdheader(path)
  _checksum, signal = rdsignal(header, false)
  signal ≈ target
end
@testset "format24" begin
    @test test_fmt24()
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
    signalv = @view signal[1:2, Integer(80 * Fs)+1:end]
    @test signalv ≈ target
end




function test_T(T::Type{U},target::Matrix{Int32}) where U <: AbstractStorageFormat
      idx = lines_mapping[Symbol(T)]
      header = H([WaveformDB.parse_signal_spec_line(spec_lines[idx])])
      _checksum,signal = rdsignal(header,false)
      t = @view target[idx,:]
      signalv = @view signal[1, :]
      @assert signalv ≈ t signalv[1:4],t[1:4]
      signalv ≈ t
end

@testset "all formats" begin
  mt = methods(WaveformDB.read_binary)
  targetpath = joinpath(@__DIR__, "target-output", "record-1f.gz")
  target = Matrix{Int32}(undef,(10, 499))
  io = GZip.open(targetpath, "r")
  target = opengzip!(io,identity)

  #filter to the types with a formatxx subtype
  ty = [m.sig.types[end] for m in mt] |> filter(x-> x !== WaveformDB.WfdbFormat)
  ty = [t.parameters[1] for t in ty]
  s1 = Set(Symbol(t) for t in ty)
  s2 = Set(keys(lines_mapping))
  yettoimplement = setdiff(s2,s1)
  @testset "not implented" begin
    for T in yettoimplement
        @warn "type $(T) not implemented"
    end
  end


  for T in ty
      @testset "$T" begin
      @test test_T(T,target)
      end
  end
end

@testset "StorageFormat constructors" begin
  function sf(i)
      StorageFormat(i)
      true
  end
  for i in [8, 16, 24, 32, 61, 80, 160, 212, 310, 311]
      @test sf(i)
  end
end
