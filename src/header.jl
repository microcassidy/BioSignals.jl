const DEFAULT_FREQUENCY = 250.0f0
@enum StorageFormat begin
  _8bit_first_difference = 8
  _16bit_twos_complement = 16
  _24bit_twos_complement_lsb = 24

  _32bit_twos_complement_lsb = 32
  _16bit_twos_complement_msb = 61
  _8bit_offset_binary = 80
  _16bit_offset_binary = 160
  _12bit_twos_complement = 212
  _10bit_twos_complement_sets_of_11 = 310
  _10bit_twos_complement_sets_of_4 = 311
end
abstract type AbstractStorageFormat end
abstract type format8 <: AbstractStorageFormat end
abstract type format16 <: AbstractStorageFormat end
abstract type format24 <: AbstractStorageFormat end
abstract type format32 <: AbstractStorageFormat end
abstract type format61 <: AbstractStorageFormat end
abstract type format80 <: AbstractStorageFormat end
abstract type format160 <: AbstractStorageFormat end
abstract type format212 <: AbstractStorageFormat end
abstract type format310 <: AbstractStorageFormat end
abstract type format311 <: AbstractStorageFormat end
struct WfdbFormat{T<:AbstractStorageFormat}
  digitalNaN::Union{Nothing,Int32}
end

WfdbFormat(s::StorageFormat) = WfdbFormat(Val{s})
function WfdbFormat(s::WfdbFormat)
  error("constuctor not implemented for $(typeof(s))")
end

WfdbFormat(::Type{Val{_8bit_first_difference}}) = WfdbFormat{format8}(nothing)
WfdbFormat(::Type{Val{_16bit_twos_complement}}) = WfdbFormat{format16}(-2^15)
WfdbFormat(::Type{Val{_24bit_twos_complement_lsb}}) = WfdbFormat{format24}(-2^23)
WfdbFormat(::Type{Val{_16bit_twos_complement_msb}}) = WfdbFormat{format61}(-2^15)
WfdbFormat(::Type{Val{_8bit_offset_binary}}) = WfdbFormat{format80}(-2^7)
WfdbFormat(::Type{Val{_16bit_offset_binary}}) = WfdbFormat{format160}(-2^15)
WfdbFormat(::Type{Val{_12bit_twos_complement}}) = WfdbFormat{format212}(-2^11)
WfdbFormat(::Val{_10bit_twos_complement_sets_of_11}) = WfdbFormat{format310}(-2^9)
WfdbFormat(::Val{_10bit_twos_complement_sets_of_4}) = WfdbFormat{format311}(-2^9)

WfdbFormat(s::String) = parse(Int64,s) |> StorageFormat |> WfdbFormat

struct SignalSpecLine{T<:AbstractStorageFormat}
  filename::String
  format::WfdbFormat{T}
  samples_per_frame::Int32
  skew::UInt32
  byte_offset::UInt32
  adc_gain::Float32
  baseline::Int32
  units::String
  adc_resolution::UInt32
  adc_zero::Int32
  initial_value::Int32
  checksum::Union{Nothing, Int16}
  block_size::UInt32
  description::String
end

filename(s::SignalSpecLine) = getfield(s,:filename)
format(s::SignalSpecLine) = getfield(s,:format)
samples_per_frame(s::SignalSpecLine) = getfield(s,:samples_per_frame)
skew(s::SignalSpecLine) = getfield(s,:skew)
byte_offset(s::SignalSpecLine) = getfield(s,:byte_offset)
adc_gain(s::SignalSpecLine) = getfield(s,:adc_gain)
baseline(s::SignalSpecLine) = getfield(s,:baseline)
units(s::SignalSpecLine) = getfield(s,:units)
adc_resolution(s::SignalSpecLine) = getfield(s,:adc_resolution)
adc_zero(s::SignalSpecLine) = getfield(s,:adc_zero)
initial_value(s::SignalSpecLine) = getfield(s,:initial_value)
checksum(s::SignalSpecLine) = getfield(s,:checksum)
block_size(s::SignalSpecLine) = getfield(s,:block_size)
description(s::SignalSpecLine) = getfield(s,:description)

struct Header

  record_name::String
  number_of_segments::Union{Nothing,UInt32}
  number_of_signals::UInt32
  sampling_frequency::Float32
  counter_frequency::Float32
  base_counter_value::Float32
  samples_per_signal::Union{Nothing,UInt32}
  base_time::Union{Nothing,String}
  base_date::Union{Nothing,String}
  parentdir::String
  signal_specs::Vector{SignalSpecLine}

  function Header(record_name, number_of_segments, number_of_signals, sampling_frequency,
                  counter_frequency, base_counter_value, samples_per_signal, base_time, base_date,
                  parentdir, signal_specs)

    new(record_name, number_of_segments,
        number_of_signals, sampling_frequency,
        counter_frequency, base_counter_value,
        samples_per_signal, base_time, base_date,
        parentdir, signal_specs)
  end
end



#---HEADER ACCESS
record_name(h::Header) = getfield(h,:record_name)
number_of_segments(h::Header) = getfield(h,:number_of_segments)
number_of_signals(h::Header) = getfield(h,:number_of_signals)
sampling_frequency(h::Header) = getfield(h,:sampling_frequency)
counter_frequency(h::Header) = getfield(h,:counter_frequency)
base_counter_value(h::Header) = getfield(h,:base_counter_value)
samples_per_signal(h::Header) = getfield(h,:samples_per_signal)
base_time(h::Header) = getfield(h,:base_time)
base_date(h::Header) = getfield(h,:base_date)
parentdir(h::Header) = getfield(h,:parentdir)
signalspecline(h::Header) = getfield(h,:signal_specs)

#HEADER -> signal specs access
adc_gain(h::Header) = h.signal_specs .|> adc_gain
adc_resolution(h::Header) = h.signal_specs .|> adc_resolution
adc_zero(h::Header) = h.signal_specs .|> adc_zero
baseline(h::Header) = h.signal_specs .|> baseline
block_size(h::Header) = h.signal_specs .|> block_size
byte_offset(h::Header) = h.signal_specs .|> byte_offset
checksum(h::Header) = h.signal_specs .|> checksum
description(h::Header) = h.signal_specs .|> description
filename(h::Header) = h.signal_specs .|> filename
format(h::Header) = h.signal_specs .|> format
initial_value(h::Header) = h.signal_specs .|> initial_value
samples_per_frame(h::Header) = h.signal_specs .|> samples_per_frame
skew(h::Header) = h.signal_specs .|> skew
units(h::Header) = h.signal_specs .|> units

nsignals(h::Header) = length(h.signal_specs)

@inline function _parse(T,v)
    if T === String && v isa SubString
        return String(v)
    end
    I = T
    if T isa Union
        I = I.a === Nothing ? I.b : I.a
    end
    parse(I,v)
end

function parse_record_line(record_line::String)
    record_regex= r"[\" \t]* (?<record_name>[-\w]+)
        /?(?<number_of_segments>\d*)
        [ \t]+ (?<number_of_signals>\d+)
        [ \t]* (?<sampling_frequency>\d*\.?\d*)
        /*(?<counter_frequency>-?\d*\.?\d*)
        \(?(?<base_counter_value>-?\d*\.?\d*)\)?
        [ \t]* (?<samples_per_signal>\d*)
        [ \t]* (?<base_time>\d{0,2}:?\d{0,2}:?\d{0,2}\.?\d{0,6})
        [ \t]* (?<base_date>\d{0,2}/?\d{0,2}/?\d{0,4})"x
  m = match(record_regex, record_line)
  @assert !isnothing(m) error("invalid record line $(record_line)")
  names = fieldnames(Header)
  types = fieldtypes(Header)
  typelookup = Dict{Symbol,Type}()
    for (name, type) in zip(names, types)
        if type isa Union
            t = type.a !== Nothing ? type.a : type.b
        else
            t = type
        end
        typelookup[name] = t
    end

  parse_errors = Vector{String}[]

  isempty(m[:record_name]) && push!(parse_errors,"missing record name from: $(record_line)")
  isempty(m[:number_of_signals]) && push!(parse_errors,"missing record name from: $(record_line)")
  if !isempty(parse_errors)
      pushfirst!("record line error:")
      push!("record_line")
      error(join(parse_errors,"\n"))
  end
  record_name = String(m[:record_name])
  number_of_segments = isempty(m[:number_of_segments]) ? nothing : _parse(typelookup[:number_of_segments], m[:number_of_segments])
  number_of_signals = isempty(m[:number_of_signals]) ? nothing : _parse(typelookup[:number_of_signals], m[:number_of_signals])
  sampling_frequency = isempty(m[:sampling_frequency]) ? DEFAULT_FREQUENCY : _parse(typelookup[:sampling_frequency], m[:sampling_frequency])
  counter_frequency = isempty(m[:counter_frequency]) ? sampling_frequency : _parse(typelookup[:counter_frequency], m[:counter_frequency])
  base_counter_value = isempty(m[:base_counter_value]) ? typelookup[:base_counter_value](0) : _parse(typelookup[:base_counter_value], m[:base_counter_value])
  samples_per_signal = (isempty(m[:samples_per_signal]) || m[:samples_per_signal] == "0" ) ?
      nothing :
      _parse(typelookup[:samples_per_signal], m[:samples_per_signal])
  base_time = isempty(m[:base_time]) ? nothing : String(m[:base_time])
  base_date = isempty(m[:base_date]) ? nothing : String(m[:base_date])

  NamedTuple([:record_name => record_name,
    :number_of_segments => number_of_segments,
    :number_of_signals => number_of_signals,
    :sampling_frequency => sampling_frequency,
    :counter_frequency => counter_frequency,
    :base_counter_value => base_counter_value,
    :samples_per_signal => samples_per_signal,
    :base_time => base_time,
    :base_date => base_date])
end


function parse_signal_spec_line(signal_line::String)::SignalSpecLine

  rx_signal = r"""
      [ \t]* (?<filename>~?[-\w]*\.?[\w]*)
      [ \t]+ (?<format>\d+)
             x?(?<samples_per_frame>\d*)
             :?(?<skew>\d*)
             \+?(?<byte_offset>\d*)
      [ \t]* (?<adc_gain>-?\d*\.?\d*e?[\+-]?\d*)
             \(?(?<baseline>-?\d*)\)?
             /?(?<units>[\w\^\-\?%\/]*)
      [ \t]* (?<adc_resolution>\d*)
      [ \t]* (?<adc_zero>-?\d*)
      [ \t]* (?<initial_value>-?\d*)
      [ \t]* (?<checksum>-?\d*)
      [ \t]* (?<block_size>\d*)
      [ \t]* (?<description>[\S]?[^\t\n\r\f\v]*)
      """x


  m = match(rx_signal, signal_line)
  @assert !isnothing(m) "invalid signal line:\n$signal_line"

  names = fieldnames(SignalSpecLine)
  types = fieldtypes(SignalSpecLine)

  struct_symbols = zip(names, types)
  typelookup = Dict(n => T for (n, T) in struct_symbols)
  data::Dict{Symbol,Any} = Dict(name => nothing for name in names)

  if isempty(m[:filename]) || isempty(m[:format])
    @assert false "missing required fields"
  end

  filename=String(m[:filename])
  format=WfdbFormat(StorageFormat(_parse(Int64,m[:format])))
  samples_per_frame = isempty(m[:samples_per_frame]) ? typelookup[:samples_per_frame](1) : _parse(typelookup[:samples_per_frame],m[:samples_per_frame])
  skew = isempty(m[:skew]) ? typelookup[:skew](0) : _parse(typelookup[:skew],m[:skew])
  byte_offset = isempty(m[:byte_offset]) ? typelookup[:byte_offset](0) : _parse(typelookup[:byte_offset],m[:byte_offset])
  adc_gain = isempty(m[:adc_gain]) ? typelookup[:adc_gain](200) : _parse(typelookup[:adc_gain],m[:adc_gain])
  units = isempty(m[:units]) ? "mV" : _parse(typelookup[:units],m[:units])
  adc_resolution = isempty(m[:adc_resolution]) ? typelookup[:adc_resolution](12) : _parse(typelookup[:adc_resolution],m[:adc_resolution])

  adc_zero = isempty(m[:adc_zero]) ? typelookup[:adc_zero](0) : _parse(typelookup[:adc_zero],m[:adc_zero])
  baseline = isempty(m[:baseline]) ? adc_zero : _parse(typelookup[:baseline],m[:baseline])

  initial_value = isempty(m[:initial_value]) ? adc_zero : _parse(typelookup[:initial_value],m[:initial_value])

  checksum = isempty(m[:checksum]) ? nothing : _parse(typelookup[:checksum],m[:checksum])

  block_size = isempty(m[:block_size]) ? typelookup[:block_size](0) : _parse(typelookup[:block_size],m[:block_size])

  description = String(m[:description])


  SignalSpecLine(filename, format, samples_per_frame, skew, byte_offset, adc_gain, baseline, units, adc_resolution, adc_zero, initial_value, checksum, block_size, description)
end



function rdheader(path)
  @assert isfile(path)
  f = open(path)
  lines = readlines(f) .|> strip |> filter(!isempty) .|> String
  close(f)
  comments = lines |> filter(contains(r"#.*"))
  lines = lines |> filter(!contains(r"#.*"))
  recordline = parse_record_line(popfirst!(lines))

  signal_spec_lines = Vector{SignalSpecLine}(undef, length(lines))
  for (idx, line) in enumerate(lines)
    signal_spec_lines[idx] = parse_signal_spec_line(line)
  end

  parentdir = splitdir(path)[1]
  Header(recordline[:record_name],
    recordline[:number_of_segments],
    recordline[:number_of_signals],
    recordline[:sampling_frequency],
    recordline[:counter_frequency],
    recordline[:base_counter_value],
    recordline[:samples_per_signal],
    recordline[:base_time],
    recordline[:base_date],
    parentdir,
    signal_spec_lines)
end
