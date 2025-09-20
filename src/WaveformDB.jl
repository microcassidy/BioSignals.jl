"""
Main module for `WaveformDB.jl` -- is a A Julia-native package for reading, writing, processing, and
plotting physiologic signal and annotation data. The core I/O functionality is
based on the [Waveform Database (WFDB) specifications.](https://wfdb.io/).

This package is heavily inspired by the original WFDB Software Package, and
initially aimed to replicate many of its command-line APIs. However, the
projects are independent, and there is no promise of consistency between the
two, beyond each package adhering to the core specifications.

WaveformDB.jl can be used to read an ECG signal e.g.:

```julia
julia> using WaveformDB

julia> rdrecord("foo.hea")

```

"""
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
include("header.jl")
include("signal.jl")

export rdsignal, rdheader
using MAT

end
