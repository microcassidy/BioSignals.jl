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

# Exports:

"""
module WaveformDB
using MAT: matread
include("packagedef.jl")
end
