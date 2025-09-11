@testset "header" begin
  fname = "100.hea"
  path = joinpath(DATA_DIR, fname)
  header = read_header(path)
end

@testset "format212" begin
  fname = "100.hea"
  path = joinpath(DATA_DIR, fname)
  header = read_header(path)
  target_path = joinpath(DATA_DIR, "100.csv")
  labels, target = read_delimited(target_path, ",", true, Float16)
  _checksum, signal = read_signal(header, true)
  @test checksum(header) == _checksum
  @test signal ≈ target
end

@testset "format16" begin
  fname = "test01_00s.hea"
  path = joinpath(DATA_DIR, fname)
  header = read_header(path)
  @test nsignals(header) == 4
  _checksum, signal = read_signal(header, false)
  @test checksum(header) == _checksum
end

# @testset "matlab" begin
#     """
#     The magic numbers replicate the command found in the python version
#     tests/test_record.py:119:68:            rdsamp -r sample-data/a103l -f 80 -s 0 1 | cut -f 2- > record-1c
#     """
#     fname = "a103l.hea"
#     path = joinpath(DATA_DIR, fname)
#     header = read_header(path)
#     Fs = sampling_frequency(header)
#     target = read_target_record("record-1c", Int16)
#     signal = read_signal(header, false)
#     signal = signal[2:end, Integer(80 * Fs)+1:end]
#     @test signal ≈ target
# end

# @testset "variable segment" begin
#     """
#     The magic numbers replicate the command found in the python version
#     tests/test_record.py:119:68:            rdsamp -r sample-data/a103l -f 80 -s 0 1 | cut -f 2- > record-1c

#     probably a pointless test, more for sanity
#     """
#     target_path = joinpath(DATA_DIR, "wave_4.edf")
#     @test isfile(target_path)
#     io = open(target_path)
#     file = EDF.File(io)
#     EDF.read_signals!(file)
#     target_lengths = [length(x.samples) for x in file.signals] |> sort

#     target_map = Dict(record.header.label => record.samples for record in file.signals)

#     header = read_header(joinpath(DATA_DIR, "wave_4.hea"))
#     signals = read_signal(header, false)
#     signal_map = Dict(label => signal for (label, signal) in zip(signal_description(header), signals))
#     signal_lengths = length.(signals) |> sort


#     @test set(keys(target_map)) == set(keys(signal_map))

#     @test target_lengths ≈ signal_lengths


#     for (k, v) in signal_map
#         @test v == target_map[k]
#     end
# end
