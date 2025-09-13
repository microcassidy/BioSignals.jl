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

function rdsignal(header::Header,physical::Bool)
  # sigs = Vector{}
  sig_info = signalspecline(header)
  fnames = filename(header)
  uniquefname = unique(fnames)
  #TODO: fix for multi file signals
  @assert length(uniquefname) == 1
  uniquefname = uniquefname[1]
  fileextension = get_extension(uniquefname)
  format = signalspecline(header)[1].format #FIXME:abstract out
  extension = get_extension_symbol(uniquefname)

  uniquespf = samples_per_frame(header) |> unique
  uniform = length(uniquespf) == 1 & uniquespf[1] == 1


  if extension === :wfdb
    samples = read_binary(pop!(fnames), header, header.parentdir, signalspecline(header)[1].format)
  elseif extension === :matlab
    fname = joinpath(header.parentdir, uniquefname)
    samples = matread(fname) |> values |> collect
    if length(samples) > 1
      error("more than one matrix in .mat file")
    end
    samples = samples[1]
    @info "matlab shape: $(size(samples))"
  end
  _checksum = checksum(samples,header)
  if physical
    samples = Float16.(samples)
    dac!(samples, header)
  end
  return _checksum, reshape(samples, nsignals(header), :)
end

function rdsignal(header::Header)
    rdsignal(header::Header,true)
end

function read_binary(fname::String, header::Header, basedir::String, F::WfdbFormat)
  error(" not implemented for type: $(typeof(F))")
end

function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format16})::Vector{Int16}
  n_signals = nsignals(header)
  n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
  bytes_per_sample = 2
  n_bytes = Int64(n_samples * bytes_per_sample)
  io = open(joinpath(basedir, fname))
  output = Vector{Int16}(undef, n_samples)
  read!(io,output)
  return output
end

function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format24})::Vector{Int32}
  nsamples = sum(samples_per_frame(header) * samples_per_signal(header))

  bytespersample = 3
  nbytes = nsamples * bytespersample

  io = open(joinpath(basedir, fname))

  buffer = zeros(UInt8, 4)
  vbuffer = @view buffer[1:3] #create view that is used for filling 3bytes at a time
  output = Vector{Int32}(undef, nsamples)

  for idx in eachindex(output)
      read!(io, vbuffer)
      o = reinterpret(Int32,buffer)[begin]
      if o & 0x800000 != 0
        o -= 2^24
      end
      @inbounds output[idx] = o
  end
  output
end

function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format80})::Vector{Int16}
  n_signals = nsignals(header)
  n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
  bytes_per_sample = 1
  io = open(joinpath(basedir, fname))
  output = Vector{Int16}(undef, n_samples)
  data = read(io,n_samples;all=false)
  for idx in eachindex(output)
      @inbounds output[idx] = data[idx] - Int16(128)
  end
  return output
end

function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format61})::Vector{Int32}
  n_signals = nsignals(header)
  n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
  bytes_per_sample = 2
  n_bytes = Int64(n_samples * bytes_per_sample)
  io = open(joinpath(basedir, fname))
  output = Vector{Int16}(undef, n_samples)
  read!(io,output)
  close(io)
  return bswap.(output)
end

function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format32})::Vector{Int32}
  n_signals = nsignals(header)
  n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
  bytes_per_sample = 4
  n_bytes = Int64(n_samples * bytes_per_sample)
  io = open(joinpath(basedir, fname))
  output = Vector{Int32}(undef, n_samples)
  read!(io,output)
  close(io)
  return output
end

function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format212})
  n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
  n_bytes = Int64(ceil(n_samples * 3//2))
  output = Vector{Int16}(undef, n_samples)

  data_buffer = zeros(UInt8,n_bytes)
  io = open(joinpath(basedir, fname))
  # read!(io,data_buffer)
  # data_buffer = data_buffer

  N = Int64(floor(n_samples / 2))
  m = n_samples % 2
  @inline p1(x0,x1) = muladd(x1 & 0x0F, 256, x0)
  @inline p2(x1,x2) = muladd(x1 & 0xF0, 16,  x2)
  @inline twos_complement(p) = p > 2047 ? p - 4096 : p
  buf = Vector{UInt8}(undef,3)
  for idx in 1:N
      read!(io,buf)
      x0,x1,x2 = Int16.(buf)
      _p1 = p1(x0,x1) |> twos_complement
      _p2 = p2(x1,x2) |> twos_complement
      @inbounds output[ 2*idx - 1 ] = _p1
      @inbounds output[ 2*idx ] = _p2
  end
  #cleanup for odd lengths
  if m == 1
    v = @view buf[1:2]
    read!(io, v)
    x0,x1 = Int16.(v)
    _p1 = p1(x0,x1) |> twos_complement
    @inbounds output[end] = _p1
  end
  return output
end

function checksum(samples,h::Header)
  _nsignals = nsignals(h)
  _checksum = checksum(h)
  expanded  = Int64.(reshape(samples, _nsignals,:))
  result = sum.(eachrow(expanded))
  return (x -> x .% 65536).(result)
end


function dac!(samples, h::Header)
  baselines = baseline(h)
  initialvalues = initial_value(h)

  adcgains = adc_gain(h)
  _samples_per_frame = samples_per_frame(h)
  _nsignals = nsignals(h)

  @assert all(_samples_per_frame .== 1)
  samples_per_signal = Int64(length(samples) / _nsignals)
  linearindex = LinearIndices(reshape(samples,_nsignals,:))
  nrow,ncol = size(linearindex)
  for j in 1:ncol
    for i in 1:nrow
        @inbounds idx = linearindex[i,j]
        @inbounds samples[idx] -= baselines[i]
        @inbounds samples[idx] /= adcgains[i]
    end
  end
end
