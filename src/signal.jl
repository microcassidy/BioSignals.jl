function get_extension_symbol(fname)
    extension = get_extension(fname) |> lowercase
    if extension === nothing
        error("extension is 'nothing'")
    elseif extension == ".mat"
        return :matlab
    elseif extension == ".dat"
        return :wfdb
    end
    error("extension '$(extension)' unknown")
    return
end

function read_signal(header::Header, physical::Bool)
    @info signal_format(header)
    # sigs = Vector{}
    sig_info = header_signal(header)
    fnames = filename(sig_info)
    uniquefname = unique(fnames)
    #TODO: fix for multi file signals
    @assert uniquefname |> length == 1
    uniquefname = uniquefname[1]
    fileextension = get_extension(uniquefname)
    format = header_signal(header)[1].format #FIXME:abstract out
    extension = get_extension_symbol(uniquefname)

    uniquespf = samples_per_frame(header) |> unique
    uniform = length(uniquespf) == 1 & uniquespf[1] == 1


    if extension === :wfdb
        samples = read_binary(pop!(fnames), header, header.parentdir, header_signal(header)[1].format)
    elseif extension === :matlab
        fname = joinpath(header.parentdir, uniquefname)
        samples = matread(fname) |> values |> collect
        if length(samples) > 1
            error("more than one matrix in .mat file")
        end
        samples = samples[1]
        @info "matlab shape:$(size(samples))"
    end
    @info length(samples)
    if physical
        samples = Float16.(samples)
        dac!(samples, header)
    end
    @info length(samples)
    return reshape(samples, nsignals(header), :)
end

"""
#8 7 6 5 4 3 2 1 |12 11 10 9 4 3 2 1|12 11 10 9 8 7 6 5 4]
#|----SAMPLE 1--------------|--------SAMPLE 2------------|
"""
# function read_binary(fname::String, header::Header, basedir::String, F::WfdbFormat)
function read_binary(fname::String, header::Header, basedir::String, F::WfdbFormat)
    error(" not implemented for type: $(typeof(F))")
end


@inline function _read!(io::IOStream, cb::CircularBuffer{2,UInt16}, ::Type{WfdbFormat{format16}})
    push!(cb, read(io, UInt8))
    push!(cb, read(io, UInt8))
end
@inline _read!(io::IOStream, cb::CircularBuffer{3,UInt8}, ::Type{WfdbFormat{format212}}) = push!(cb, read(io, UInt8))
@inline _read!(io::IOStream, cb::CircularBuffer{3,UInt8}, ::Type{WfdbFormat{format212}}, nb::Integer) = map(_ -> push!(cb, read(io, UInt8)), nb)
function sign_extend(value::UInt16, n::Int)::UInt16
    sign_bit = 1 << (n - 1)
    mask = (1 << n) - 1
    value = value & mask
    return (value ⊻ sign_bit) - sign_bit
end
function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format16})::Vector{Int16}
    n_signals = nsignals(header)
    n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
    bytes_per_sample = 2
    n_bytes = Int64(ceil(n_samples * bytes_per_sample))
    data = Vector{UInt8}(undef, n_bytes)
    io = open(joinpath(basedir, fname))
    @info typeof(io)
    cb = CircularBuffer{2,UInt16}()
    output = Vector{Int16}(undef, n_samples)
    for idx in 1:n_samples
        _read!(io, cb, WfdbFormat{format16})
        lower, upper = UInt16(cb[1]), UInt16(cb[2])
        upper <<= 8
        if upper & 0x0800 != 0
            upper |= 0xF000
        end
        output[idx] = reinterpret(Int16, lower | upper)
    end
    close(io)
    # return data
    # return Matrix{Int16}(undef, nsignals, samples_per_signal(header))
    @info size(output)
    output


end
function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format212})
    io = joinpath(basedir, fname) |> open
    cb = CircularBuffer{3,UInt8}()
    n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
    @info "samples per frame $(samples_per_frame(header))"
    # n_samples = sum(sam)
    n_bytes = Integer(n_samples * 1.5)
    output = Vector{Int16}(undef, n_samples)

    shift = 4
    mask = 0xF0
    # lower = UInt8(0)
    # upper = UInt8(0)


    for idx in 1:n_samples
        isempty(cb) ? _read!(io, cb, WfdbFormat{format212}, 3) : _read!(io, cb, WfdbFormat{format212})
        lower = cb[1]
        upper = cb[2]
        if idx % 2 == 1
            upper = UInt16(upper & mask) << 4
        else
            lower = UInt16(lower & ~mask)
            upper = UInt16(upper) << 8
        end
        if upper & 0x0800 != 0
            upper |= 0xF000
        end
        output[idx] = reinterpret(Int16, lower | upper)
        # _read!(io, cb, WfdbFormat{format212})
    end
    return output
end

function dac!(samples, h::Header)
    baselines = baseline(h)
    adcgains = adcgain(h)
    _samples_per_frame = samples_per_frame(h)
    _nsignals = nsignals(h)

    blocksize = sum(_samples_per_frame)
    nblocks = Integer(length(samples) / blocksize)


    frame_offset = accumulate(+, _samples_per_frame)
    circshift!(frame_offset, 1)
    frame_offset[1] = 0

    for b ∈ 0:nblocks-1, j ∈ 1:_nsignals
        for i in 1:_samples_per_frame[j] #for jagged  indexing
            samples[i+frame_offset[j]+b*blocksize] -= baselines[j]
            samples[i+frame_offset[j]+b*blocksize] /= adcgains[j]
        end
    end
end
