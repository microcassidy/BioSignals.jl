# @testset "test01_00s.hea" begin
#     fname = "test01_00s.hea"
#     path = joinpath(DATA_DIR, fname)
#     header = read_header(path)
#     target = read_target_record("record-1a", Int16)
#     signal = read_signal(header, false)
#     @test signal ≈ target
# end

function dharness(testname, filename, target_filename, _target_path, target_callback, target_callback_args, physical, tests)
    testname =>
        Dict(
            :filename => filename,
            :target_filename => target_filename,
            :_target_path => _target_path,
            :target_callback => target_callback,
            :target_callback_args => target_callback_args,
            :physical => physical,
            :tests => tests
        )
end
macro tset(t)

    expr =
        test_block = quote
            @testset $(testname) begin
                filename = d[:filename]
                path = joinpath(DATA_DIR, filename)
                header = read_header(path)
                target_path = joinpath(d[:_target_path], d[:target_filename])
                labels, target = $target_callback(d[:target_callback_args]...)
                signal = read_signal(header, d[:physical])
                @test signal ≈ target
            end
        end
end
tests = []
temp = dharness("100.hea", "100.hea", "100.csv", DATA_DIR, read_delimited, [",", Float16], true, "foo")
eval(tset(temp))

# @foolish tests







# @testset "100.hea" begin
#     fname = "100.hea"
#     path = joinpath(DATA_DIR, fname)
#     header = read_header(path)
#     target_path = joinpath(DATA_DIR, "100.csv")
#     labels, target = read_delimited(target_path, ",", true, Float16)
#     signal = read_signal(header, true)
#     @test signal ≈ target
# end

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
