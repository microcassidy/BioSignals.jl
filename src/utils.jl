function get_extension_symbol(fname::String)::Symbol
    ext = Base.Filesystem.splitext(fname)[end] |> lowercase
    isempty(ext) && error("extension is empty")
    if ext == ".mat"
        return :matlab
    end
    return :wfdb
end

function checksum(samples, h::Header)
    _nsignals = nsignals(h)
    _checksum = checksum(h)
    expanded = Int64.(reshape(samples, _nsignals, :))
    result = sum.(eachrow(expanded))
    return (x -> x .% 65536).(result)
end
