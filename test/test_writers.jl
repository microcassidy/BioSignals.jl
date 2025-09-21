using WaveformDB: write_binary
function setup_writer_tests(fmts)
    D = Dict()

    for fmt in fmts
        ln = lines_mapping[Symbol(fmt)]

        spec_line = [WaveformDB.parse_signal_spec_line(spec_lines[ln])]
        D[fmt] = H(spec_line)
    end

    function writer_test(fmt)
        header = D[fmt]
        fmt = format(header)[1]

        checksum, samples = rdsignal(header, false)
        fname = unique(filename(header))
        path = joinpath(parentdir(header), fname[1])
        expectations = read(path)
        io = IOBuffer()
        write_binary(io, header, vec(samples), fmt)
        seekstart(io)
        reality = read(io)
        close(io)
        @test expectations == reality
    end
    return writer_test
end

@testset "writers" begin
    mt = methods(WaveformDB.read_binary)
    fmts = [m.sig.types[end] for m in mt] |> filter(x -> x !== WaveformDB.WfdbFormat)
    fmts = [t.parameters[1] for t in fmts]
    writertest = setup_writer_tests(fmts)
    for fmt in fmts
        @testset "$fmt" begin
            writertest(fmt)
        end
    end
end
