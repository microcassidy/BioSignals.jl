module BioSignals
export get_extension
include("utils.jl")

import Base: push!, setindex!, getindex
export CircularBuffer
# export push!, setindex!, getindex

include("buffer.jl")

export read_header,
    adcgain,
    baseline,
    filename,
    header_record,
    header_signal,
    nsignals,
    samples_per_signal,
    sampling_frequency,
    signal_description,
    signal_format
include("header.jl")

export read_signal, read_header
using MAT
include("signal.jl")

end
