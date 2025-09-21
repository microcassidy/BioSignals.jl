include("utils.jl")

export adc_gain,
    adc_resolution,
    adc_zero,
    base_counter_value,
    base_date,
    base_time,
    baseline,
    block_size,
    byte_offset,
    checksum,
    counter_frequency,
    description,
    filename,
    format,
    initial_value,
    number_of_segments,
    number_of_signals,
    parentdir,
    record,
    record_name,
    samples_per_frame,
    samples_per_signal,
    sampling_frequency,
    signal_spec,
    skew,
    units,
    nsignals
include("header.jl")

export rdsignal, rdheader
include("interface.jl")
include("readers.jl")
include("writers.jl")
