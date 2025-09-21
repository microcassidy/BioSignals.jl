"""
    rdsignal(h::Header,physical::Bool = true)::Tuple{Int64, Matrix{Int32}}

read the samples described in the header's `signal_specs` field.
Header - a parsed header (.hea) file

physical - optional (defaults to true)
        Specifies whether to return signals in physical units in the
        `p_signal` field (True), or digital units in the `d_signal`
        field (False).
"""
rdsignal(header::Header) = rdsignal(header::Header, true)
function rdsignal(header::Header, physical::Bool)
    sig_info = signalspecline(header)
    fnames = filename(header)
    uniquefname = unique(fnames)
    #TODO: fix for multi file signals
    @assert length(uniquefname) == 1
    uniquefname = uniquefname[1]
    #TODO: verify whether more than 1 format can live in a single file
    fmt = format(header) #FIXME:abstract out
    length(unique(fmt)) > 1 && error("multi format not implemented $(fmt)")
    extension = get_extension_symbol(uniquefname)

    uniquespf = samples_per_frame(header) |> unique
    uniform = length(uniquespf) == 1 & uniquespf[1] == 1
    !uniform && error("non-unity frame sizes not supported")
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

"""
    wsignal(header::Header, signal::Vector{Int32})

writes a signal file to disk. All of the information required to write the file needs to be specified by the header
"""
function wsignal(header::Header, signal::Vector{Int32})
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

"""
    read_binary(io::IO, header::Header, ::WfdbFormat{<:AbstractStorargeFormat})

reads a WaveformDB sample file
io - IOBuffer for the file ("eg 100.dat")
header - header struct containing the information necessary to *decode* the file
F - the format that the file is in
"""
function read_binary end

"""
    function write_binary(io::IO, header::Header, samples::Vector{Int32}, ::WfdbFormat{<:AbstractStorageFormat})

reads a WaveformDB sample file
io - IOBuffer to write to
header - header struct containing the information necessary to *encode* the file
F - the WaveformDB format to encode the output as
"""
function write_binary end
