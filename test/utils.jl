const DATA_DIR = joinpath(@__DIR__, "..", "sample-data")
const TARGET_OUTPUT = joinpath(@__DIR__, "target-output")
function headerfiles()
    readdir(DATA_DIR; join=true) |> filter(x -> isfile(x) &&
        endswith(splitdir(x)[end], ".hea"))
end
function read_delimited(path::String, delimiter::String, has_header::Bool, as::Type{<:Real})
    lines = readlines(path) .|> strip |> filter(!isempty)
    ncol = length(lines)
    endi = ncol
    starti = 1
    firstline = first(lines)
    firstelements = split(firstline, delimiter)
    nrow = length(firstelements)
    offset = 0
    if has_header
        starti = 2
        offset += 1
        labels = firstelements
    end

    output = Matrix{as}(undef, nrow, ncol - offset)

    for idx in starti+offset:endi
        l = strip(lines[idx])
        l = split(l, delimiter)
        try
            output[:, idx-offset] = parse.(as, l)
        catch e
            @error l
            e
        end
    end
    return labels, output
end
function read_delimited(path::String, as::Type{<:Real})
    #@info "running default"
    #@info path
    readlines(path) .|>
    strip |>
    filter(!isempty) .|>
    split |>
    vec -> reduce(hcat, vec) .|> #stack each vector as a column
           x_n -> parse(as, x_n)
end
