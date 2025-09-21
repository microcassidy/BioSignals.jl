function get_extension_symbol(fname)
    extension = get_extension(fname) |> lowercase
    if extension === nothing
        error("extension is 'nothing'")
    end

    if extension == ".mat"
        return :matlab
    end
    return :wfdb
end

function rdsignal(header::Header, physical::Bool)
    sig_info = signalspecline(header)
    fnames = filename(header)
    uniquefname = unique(fnames)
    #TODO: fix for multi file signals
    @assert length(uniquefname) == 1
    uniquefname = uniquefname[1]
    fileextension = get_extension(uniquefname)
    #TODO: verify whether more than 1 format can live in a single file

    fmt = format(header) #FIXME:abstract out
    @assert length(unique(fmt)) == 1 "multi format not implemented $(fmt)"

    extension = get_extension_symbol(uniquefname)

    uniquespf = samples_per_frame(header) |> unique
    uniform = length(uniquespf) == 1 & uniquespf[1] == 1

    if extension === :wfdb
        # -    samples = read_binary(pop!(fnames), header, header.parentdir, signalspecline(header)[1].format)
        open(joinpath(parentdir(header), uniquefname)) do io
            samples = read_binary(io, header, fmt[1])
        end
    elseif extension === :matlab
        fname = joinpath(header.parentdir, uniquefname)
        samples = matread(fname) |> values |> collect
        if length(samples) > 1
            error("more than one matrix in .mat file")
        end
        samples = samples[1]
    end
    _checksum = checksum(samples, header)
    if physical
        samples = Float16.(samples)
        dac!(samples, header)
    end
    return _checksum, reshape(samples, nsignals(header), :)
end

function wsignal(header::Header, signal::Vector{T}) where {T<:Integer}
    fmt = format(header) |> unique
    if length(format) > 1
        error("multi format header writing is not supported")
    end
    fmt = fmt[1]
    parent = parendir(header)
    if !(isdir(parent))
        error("directory '$(parent)' does not exist")
    end
    fnames = filename(header)
    uniquefname = unique(fnames)
    if len(uniquefname) > 1
        error("multi-file writers not supported")
    end
    uniquefname = uniquefname[1]
    full_path = joinpath(parent, uniquefname)
    if isfile(full_path)
        error("file '$(full_path)' already exists")
    end
    open(full_path, 'w') do io
        write_binary(io, header, samples, fmt)
    end
end

function rdsignal(header::Header)
    rdsignal(header::Header, true)
end
