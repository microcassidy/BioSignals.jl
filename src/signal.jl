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

function rdsignal(header::Header,physical::Bool)
  # sigs = Vector{}
  sig_info = signalspecline(header)
  fnames = filename(header)
  uniquefname = unique(fnames)
  #TODO: fix for multi file signals
  @assert uniquefname |> length == 1
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

function read_binary(fname::String, header::Header, basedir::String, ::WfdbFormat{format212})
  n_samples = sum(samples_per_frame(header) * samples_per_signal(header))
  n_bytes = Int64(n_samples * 3//2)
  output = Vector{Int16}(undef, n_samples)

  data_buffer = zeros(UInt8,n_bytes)
  io = open(joinpath(basedir, fname))
  read!(io,data_buffer)
  data_buffer = Int16.(data_buffer)

  for idx in 1:n_samples
    m = (idx - 1) % 2
    b1 = popfirst!(data_buffer)
    if m == 0
      b2 = data_buffer[1]
      b2 &= 0x000F
      b2 <<= 8
    else
      b2 = popfirst!(data_buffer)
      b1 >>= 4
      b1 &= 0x000F
      b1 <<= 8
    end
    val = b1 + b2
    if val > 2047
        val -= 4096
    end
    output[idx] = val
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
        idx = linearindex[i,j]
        samples[idx] -= baselines[i]
        samples[idx] /= adcgains[i]
    end
  end
end
