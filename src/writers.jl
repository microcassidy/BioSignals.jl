function write_binary(io::IO,header::Header,samples::Vector{T},F::WfdbFormat) where {T <: Integer}
  error(" not implemented for type: $(typeof(F))")
end

function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format8})

    n_signals = nsignals(header) #do I even care about this anymore?
    n_samples = length(samples)
    output = Vector{UInt8}(undef,n_samples)

    # x₁ = y₁ + v₁, x is the converted signal, y is the stream of data on disk, v is the initial_value in the header
    # x_k = x_(k-1) + y_k
    # <=> y_k = x_k - x_k - 1
    #the samples are interleaved so we will need to look back by the number of samples

    initvalues = initial_value(header)
    output = Vector{Int8}(undef,n_samples)
    for i in n_samples:-1:(n_signals + 1)
       output[i] = samples[i] - samples[i - 1]
    end

    for i in 1:n_signals
       output[i] = samples[i] - initvalues[i]
    end

    write(io,output)
end

function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format16})
    write(io,convert(Vector{Int16},samples))
end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format24})
    output = Vector{UInt8}(undef,length(samples) * 3)

    for i in eachindex(samples)
        v = samples[i]
        if v < 0
            v += 2^24
        end
        for j in 1:3
            output[j + 3(i -1)] = v & 0xFF
            v >>= 8
        end
    end
    write(io, output)
end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format32})
    write(io,samples)
end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format61})
    write(io,bswap.(convert(Vector{Int16},samples)))
end

function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format80})
    output = samples
    for i in eachindex(output)
        output[i] += Int32(128)
    end
    write(io,convert(Vector{UInt8},output))
end

function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format160})
    output = Vector{UInt16}(undef, length(samples))

  for idx in eachindex(samples)
      @inbounds output[idx] = samples[idx] + 32_768
  end
    write(io,output)
end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format212})
    n_samples = length(samples)
    buffer_length = n_samples
    r = n_samples % 2
    if r == 1
        resize!(samples,n_samples + 1)
        samples[end] = 0
        buffer_length += 1
    end

    n_bytes = Int64(ceil(1.5 * buffer_length))
    n_bytes_actual = Int64(ceil(1.5 * n_samples))

    output = Vector{UInt8}(undef, n_bytes)
    @inline conv(x::Int32) = x < 0 ? x + 4096 : x
    for i in 1:Int64(buffer_length/2)
        v1 = samples[2i - 1] |> conv |> UInt16
        v2 = samples[2i] |> conv |> UInt16
        b1 = (v1 & 0x00FF)
        b2  = ((v1 & 0x0F00) >> 8) + ((v2 & 0x0F00) >> 4)
        b3 = (v2 & 0x00FF)
        output[3i - 2] = b1
        output[3i - 1] = b2
        output[3i] = b3
    end
    resize!(samples,n_samples)
    resize!(output,n_bytes_actual)
    write(io,output)
end

function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format310})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format311})end
