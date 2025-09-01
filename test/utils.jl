const DATA_DIR = joinpath(@__DIR__, "..", "sample-data")
const TARGET_OUTPUT = joinpath(@__DIR__, "target-output")
function headerfiles()
    readdir(DATA_DIR; join=true) |> filter(x -> isfile(x) &&
        endswith(splitdir(x)[end], ".hea"))
end
function read_delimited(path::String, delimiter::String, as::Type{<:Real})
    readlines(path) .|>
    strip .|>
    split(delimiter) |>
    vec -> reduce(hcat, vec) .|> #stack each vector as a column
           x_n -> parse(as, x_n)
end
function read_delimited(path::String, as::Type{<:Real})
    readlines(path) .|>
    strip .|>
    split |>
    vec -> reduce(hcat, vec) .|> #stack each vector as a column
           x_n -> parse(as, x_n)
end
