const DEFAULT_FREQUENCY = 250.0f0
export read_header,
    adcgain,
    baseline,
    filename,
    header_record,
    header_signal,
    nsignals,
    samples_per_signal,
    signal_format,
    sampling_frequency
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
struct WfdbFormat{T<:AbstractStorageFormat} end

WfdbFormat(s::StorageFormat) = WfdbFormat(Val{s})
function WfdbFormat(s::WfdbFormat)
    error("constuctor not implemented for $(typeof(s))")
end

WfdbFormat(::Type{Val{_8bit_first_difference}}) = WfdbFormat{format8}()
WfdbFormat(::Type{Val{_16bit_twos_complement}}) = WfdbFormat{format16}()
WfdbFormat(::Type{Val{_24bit_twos_complement_lsb}}) = WfdbFormat{format24}()
WfdbFormat(::Type{Val{_16bit_twos_complement_msb}}) = WfdbFormat{format61}()
WfdbFormat(::Type{Val{_8bit_offset_binary}}) = WfdbFormat{format80}()
WfdbFormat(::Type{Val{_16bit_offset_binary}}) = WfdbFormat{format160}()
WfdbFormat(::Type{Val{_12bit_twos_complement}}) = WfdbFormat{format212}()
WfdbFormat(::Val{_10bit_twos_complement_sets_of_11}) = WfdbFormat{format310}()
WfdbFormat(::Val{_10bit_twos_complement_sets_of_4}) = WfdbFormat{format311}()

struct RecordLine
    record_name::String
    number_of_segments::Union{Nothing,UInt32}
    number_of_signals::UInt32
    sampling_frequency::Float32
    counter_frequency::Float32
    base_counter_value::Float32
    samples_per_signal::Union{Nothing,UInt32}
    base_time::Union{Nothing,String}
    base_date::Union{Nothing,String}
end
struct SignalSpecLine{T<:AbstractStorageFormat}
    filename::String
    format::WfdbFormat{T}
    samples_per_frame::UInt32
    skew::UInt32
    byte_offset::UInt32
    adc_gain::Float32
    baseline::Int32
    units::String
    adc_resolution::UInt32
    adc_zero::UInt32
    initial_value::Int32
    checksum::Int16
    block_size::UInt32
    description::String
end

struct Header
    record::RecordLine
    signal_specs::Vector{SignalSpecLine}
    Header(l, v) = new(l, v)
end
#TODO: refactor?
sampling_frequency(h::Header) = h.record.sampling_frequency
header_record(h::Header) = h.record
header_signal(h::Header) = h.signal_specs
signal_format(s::SignalSpecLine) = s.format
signal_format(s::Vector{SignalSpecLine}) = signal_format.(s)
signal_format(h::Header) = s |> header_signal |> signal_format
filename(s::SignalSpecLine) = s.filename
filename(s::Vector{SignalSpecLine}) = map(filename, s)
samples_per_signal(h::Header) = h.record.samples_per_signal
nsignals(h::Header) = header_signal(h) |> length
baseline(s::SignalSpecLine) = s.baseline
baseline(s::Vector{SignalSpecLine}) = map(baseline, s)
baseline(h::Header) = h |> header_signal |> baseline
adcgain(s::SignalSpecLine) = s.adc_gain
adcgain(s::Vector{SignalSpecLine}) = map(adcgain, s)
adcgain(h::Header) = h |> header_signal |> adcgain

function parse_record_line(record_line::String)::RecordLine
    signal_regex = r"
        [\" \t]* (?<record_name>[-\w]+)
        /?(?<number_of_segments>\d*)
        [ \t]+ (?<number_of_signals>\d+)
        [ \t]* (?<sampling_frequency>\d*\.?\d*)
        /*(?<counter_frequency>-?\d*\.?\d*)
        \(?(?<base_counter_value>-?\d*\.?\d*)\)?
        [ \t]* (?<samples_per_signal>\d*)
        [ \t]* (?<base_time>\d{0,2}:?\d{0,2}:?\d{0,2}\.?\d{0,6})
        [ \t]* (?<base_date>\d{0,2}/?\d{0,2}/?\d{0,4})
    "x
    m = match(signal_regex, record_line)
    @assert !isnothing(m) "NO MATCH:$header_line"
    names = fieldnames(RecordLine)
    types = fieldtypes(RecordLine)
    struct_symbols = zip(names, types)
    type_lookup = Dict(name => type for (name, type) in struct_symbols)

    data::Dict{Symbol,Union{Nothing,String}} = Dict(name => nothing for (name, type) in struct_symbols)
    #set defaults
    breaking_symbol = nothing

    for symbol in keys(type_lookup)
        if isempty(m[symbol]) && symbol != :number_of_segments
            breaking_symbol = symbol
            break
        end
        data[symbol] = isempty(m[symbol]) ? nothing : m[symbol]
    end

    if isnothing(data[:record_name]) || isnothing(data[:number_of_signals])
        @assert false, "record name and number of sigs are compulsary"
    end

    #TODO: validations of headerfiles
    _number_of_segments = data[:number_of_segments] !== nothing ? parse(UInt32, data[:number_of_segments]) : nothing
    _number_of_signals = parse(UInt32, data[:number_of_signals])
    _sampling_frequency = data[:sampling_frequency] !== nothing ?
                          parse(Float32, data[:sampling_frequency]) :
                          DEFAULT_FREQUENCY
    _counter_frequency = data[:counter_frequency] !== nothing ?
                         parse(Float32, data[:counter_frequency]) :
                         DEFAULT_FREQUENCY
    _base_counter_value = data[:base_counter_value] !== nothing ?
                          parse(Float32, data[:base_counter_value]) :
                          zero(type_lookup[:base_counter_value])
    _samples_per_signal = data[:samples_per_signal] !== nothing ?
                          parse(UInt32, data[:samples_per_signal]) :
                          nothing
    if _number_of_signals isa Integer && _number_of_signals == 0
        _number_of_signals = nothing
    end
    _base_time = data[:base_time] !== nothing ? String(data[:base_time]) : nothing
    _base_date = data[:base_date] !== nothing ? String(data[:base_date]) : nothing

    RecordLine(data[:record_name], _number_of_segments, _number_of_signals, _sampling_frequency, _counter_frequency, _base_counter_value, _samples_per_signal, _base_time, _base_date)
end


function parse_signal_spec_line(signal_line::String)::SignalSpecLine

    signal_regex = r"
        [ \t]* (?<filename>[-\w]+\.?\w*)
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
        "x

    m = match(signal_regex, signal_line)
    @assert !isnothing(m) "invalid signal line:\n$signal_line"

    names = fieldnames(SignalSpecLine)
    types = fieldtypes(SignalSpecLine)

    struct_symbols = zip(names, types)
    type_lookup = Dict(n => T for (n, T) in struct_symbols)
    data::Dict{Symbol,Any} = Dict(name => nothing for name in names)

    # TODO: validation of signal lines
    for (symbol, T) in type_lookup
        isempty(m[symbol]) && continue
        if T === WfdbFormat
            data[symbol] = WfdbFormat(StorageFormat(parse(Int, m[symbol])))
        elseif T !== String
            data[symbol] = parse(T, m[symbol])
        else
            data[symbol] = String(m[symbol])
        end
    end
    if isnothing(data[:filename]) || isnothing(data[:format])
        @assert false "missing required fields"
    end

    defaults = Dict(
        :samples_per_frame => UInt32(1),
        :skew => UInt32(0),
        :byte_offset => UInt32(0),
        :adc_gain => Float32(200),
        :baseline => Int32(0),
        :units => "mV",
        :adc_resolution => UInt32(12),
        :adc_zero => UInt32(0),
        :initial_value => nothing, #Equal to adc zero if missing
        :checksum => nothing,
        :block_size => UInt32(0),
        :description => "",
    )
    for (k, v) in defaults
        if k == :initial_value
            continue
        end
        data[k] = isnothing(data[k]) ? v : data[k]
    end
    if isnothing(data[:initial_value])
        data[:initial_value] = data[:adc_zero]
    end
    SignalSpecLine(data[:filename],
        data[:format],
        data[:samples_per_frame],
        data[:skew],
        data[:byte_offset],
        data[:adc_gain],
        data[:baseline],
        data[:units],
        data[:adc_resolution],
        data[:adc_zero],
        data[:initial_value],
        data[:checksum],
        data[:block_size],
        data[:description])
end

function read_header(path)
    @assert isfile(path)
    f = open(path)
    lines = readlines(f) .|> strip |> filter(!isempty) .|> String
    close(f)
    comments = lines |> filter(contains(r"#.*"))
    lines = lines |> filter(!contains(r"#.*"))
    header = parse_record_line(popfirst!(lines))
    signal_spec_lines = Vector{SignalSpecLine}(undef, length(lines))
    for (idx, line) in enumerate(lines)
        signal_spec_lines[idx] = parse_signal_spec_line(line)
    end
    return Header(header, signal_spec_lines)
end
