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

function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format16})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format24})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format32})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format61})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format80})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format160})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format212})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format310})end
function write_binary(io::IO,header::Header,samples::Vector{Int32},::WfdbFormat{format311})end
