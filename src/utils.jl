function get_extension(path)
    _, fname = splitdir(path)
    idx = findfirst(".", fname)
    if isnothing(idx)
        return nothing
    end
    return fname[idx[1]:end]
end
