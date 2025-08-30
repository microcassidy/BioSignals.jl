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
abstract type fmt8 <: AbstractStorageFormat end
abstract type fmt16 <: AbstractStorageFormat end
abstract type fmt24 <: AbstractStorageFormat end
abstract type fmt32 <: AbstractStorageFormat end
abstract type fmt61 <: AbstractStorageFormat end
abstract type fmt80 <: AbstractStorageFormat end
abstract type fmt160 <: AbstractStorageFormat end
abstract type fmt212 <: AbstractStorageFormat end
abstract type fmt310 <: AbstractStorageFormat end
abstract type fmt311 <: AbstractStorageFormat end

Fmt(s::StorageFormat) = Fmt(Val{s})
Fmt(::Val{_8bit_first_difference}) = fmt8()
Fmt(::Val{_16bit_twos_complement}) = fmt16()
Fmt(::Val{_24bit_twos_complement_lsb}) = fmt24()
Fmt(::Val{_32bit_twos_complement_lsb}) = fmt32()
Fmt(::Val{_16bit_twos_complement_msb}) = fmt61()
Fmt(::Val{_8bit_offset_binary}) = fmt80()
Fmt(::Val{_16bit_offset_binary}) = fmt160()
Fmt(::Val{_12bit_twos_complement}) = fmt212()
Fmt(::Val{_10bit_twos_complement_sets_of_11}) = fmt310()
Fmt(::Val{_10bit_twos_complement_sets_of_4}) = fmt311()

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
    format::T
    samples_per_frame::UInt32
    skew::UInt32
    byte_offset::UInt32
    adc_gain::Float32
    baseline::UInt32
    units::String
    adc_resolution::UInt32
    adc_zero::UInt32
    initial_value::UInt32
    checksum::Int16
    block_size::UInt32
    description::String
end

struct Header
    record::RecordLine
    signal_specs::Vector{SignalSpecLine}
end

function parse_record_line(record_line::String)::RecordLine
    record_regex = r"
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
    m = match(record_regex, record_line)
    @assert !isnothing(m)
    names = fieldnames(RecordLine)
    types = fieldtypes(RecordLine)
    struct_symbols = zip(names, types)
    type_lookup = Dict(name => type for (name, type) in struct_symbols)
    
        data::Dict{Symbol,Union{Nothing,String}}= Dict(name => nothing for (name, type) in struct_symbols)
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
        @assert false
    end
    depenency_chain = [:sampling_frequency, :counter_frequency, :base_counter_value, :samples_per_signal, :base_time, :base_date]
    if !isnothing(breaking_symbol)
        idx = findfirst(x -> x == breaking_symbol, depenency_chain)
        if !isnothing(idx)
            for s in depenency_chain[idx:end]
                @assert data[s] === nothing
            end
        end
    end

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
    _base_time = data[:base_time] !== nothing ? parse(String, data[:base_time]) : nothing
    _base_date = data[:base_date] !== nothing ? parse(String, data[:base_date]) : nothing

    RecordLine(data[:record_name],_number_of_segments, _number_of_signals, _sampling_frequency, _counter_frequency, _base_counter_value, _samples_per_signal, _base_time, _base_date)
end
