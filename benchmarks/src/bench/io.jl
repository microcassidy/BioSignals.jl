io_group = addgroup!(SUITE, "io")
# io_group["find_contours"] = @benchmarkable find_contours!(x) setup=(x=copy($X))
# io_group["draw_contours"] = @benchmarkable draw_contours!(image,$color,C) setup = ( image=copy($image), C=copy($C) )

#filter to the types with a formatxx subtype
function implementedtypes()
    mt = methods(WaveformDB.read_binary)
    ty = [m.sig.types[end] for m in mt] |> filter(x->x !== WaveformDB.WfdbFormat)
    return t[t.parameters[1] for t in ty]
end
function io_headersetup()
    bindata_recordline = "binformats 10 200 499"
    spec_lines = [
        "binformats.d0 8 200/mV 12 0 -2047 -31143 0 sig 0, fmt 8",
        "binformats.d1 16 200/mV 16 0 -32766 -750 0 sig 1, fmt 16",
        "binformats.d2 61 200/mV 16 0 -32765 -251 0 sig 2, fmt 61",
        "binformats.d3 80 200/mV 8 0 -124 -517 0 sig 3, fmt 80",
        "binformats.d4 160 200/mV 16 0 -32763 747 0 sig 4, fmt 160",
        "binformats.d5 212 200/mV 12 0 -2042 -6824 0 sig 5, fmt 212",
        "binformats.d6 310 200/mV 10 0 -505 -1621 0 sig 6, fmt 310",
        "binformats.d7 311 200/mV 10 0 -504 -2145 0 sig 7, fmt 311",
        "binformats.d8 24 200/mV 24 0 -8388599 11715 0 sig 8, fmt 24",
        "binformats.d9 32 200/mV 32 0 -2147483638 19035 0 sig 9, fmt 32",
    ]
    recordline = WaveformDB.parse_record_line(bindata_recordline)
    spec_lines = WaveformDB.parse_signal_spec_line.(spec_lines)
    H(sl) = WaveformDB.Header(
        recordline[:record_name],
        recordline[:number_of_segments],
        recordline[:number_of_signals],
        recordline[:sampling_frequency],
        recordline[:counter_frequency],
        recordline[:base_counter_value],
        recordline[:samples_per_signal],
        recordline[:base_time],
        recordline[:base_date],
        DATA_DIR,
        sl,
    )
    return [H([s]) for s in spec_lines]
end

const lines_mapping = Dict([
    :format8 => 1,
    :format16 => 2,
    :format61 => 3,
    :format80 => 4,
    :format160 => 5,
    :format212 => 6,
    :format310 => 7,
    :format311 => 8,
    :format24 => 9,
    :format32 => 10,
])

headers = io_headersetup()
# for (k,v) in lines_mapping
#     h[Symbol(k)]
# end
for (k, l) in lines_mapping
    h = headers[l]
    io_group[k] = @benchmarkable rdsignal(header, false) setup = (header = $h)
end
