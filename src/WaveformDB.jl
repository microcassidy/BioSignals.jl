module WaveformDB
export get_extension
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
  # validatechecksum
include("header.jl")
include("signal.jl")

export read_signal, read_header
using MAT

end
