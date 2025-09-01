export read_signal
include("../test/utils.jl")
function read_signal(header::Header)
    # sigs = Vector{}
    sig_info = header_signal(header)
    fnames = filename(sig_info)
    uniquefnames = unique(fnames)
    @assert uniquefnames |> length == 1 #TODO: fix for multi file signals
    format = header_signal(header)[1].format
    samples = read_binary(pop!(fnames), header, DATA_DIR, header_signal(header)[1].format)
    dac!(samples, header)
    return reshape(samples, nsignals(header), :)
end

"""
#8 7 6 5 4 3 2 1 |12 11 10 9 4 3 2 1|12 11 10 9 8 7 6 5 4]
#|----SAMPLE 1--------------|--------SAMPLE 2------------|
"""
# function read_binary(fname::String, header::Header, basedir::String, F::Fmt)
#     error(" not implemented for type: $(typeof(F))")
# end
function read_binary(fname::String, header::Header, basedir::String, ::T) where T>:fmt212
    io = joinpath(basedir, fname) |> open
    #12 bit 
    # bit_resolution = 12
    n_signals = nsignals(header)
    n_samples = n_signals * samples_per_signal(header)

    bytes_per_sample = 3 // 2 #1.5
    n_bytes = Int64(ceil(n_samples * bytes_per_sample))
    data = Vector{UInt8}(undef, n_bytes)
    read!(io, data)
    close(io)
    #read 3 bytes at a time and convert to samples
    samples = []

    # n_iter = Int64(ceil(n_samples/2))
    for i in 1:3:n_bytes
        i + 1 > length(data) && break
        sample_1_lower = data[i] |> UInt16
        sample_1_upper = UInt16(data[i+1] & 0x0F) << 8
        if sample_1_upper & 0x0800 != 0
            sample_1_upper |= 0xF000
        end
        push!(samples, reinterpret(Int16, sample_1_lower | sample_1_upper))

        sample_2_lower = UInt8(data[i+1] & 0xF0)
        sample_2_upper = UInt16(data[i+2]) << 4
        if sample_2_upper & 0x0800 != 0
            sample_2_upper |= 0xF000
        end
        push!(samples, reinterpret(Int16, sample_2_lower | sample_2_upper))
    end
    @assert length(samples) == n_samples
    return samples
end

function dac!(samples, h::Header)
    baselines = baseline(h)
    adcgains = adcgain(h)
    for j in 1:samples_per_signal(h)
        for i in 1:nsignals(h)
            samples[i+(j-1)*i] -= baselines[i]
            samples[i+(j-1)*i] /= adcgains[i]
        end
    end
end
