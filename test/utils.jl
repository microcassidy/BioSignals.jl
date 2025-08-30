const DATA_DIR = joinpath(splitdir(@__FILE__) |> first,"..","sample-data")
function headerfiles()
    readdir(DATA_DIR;join=true) |> filter(x -> isfile(x) && endswith(splitdir(x)[end], ".hea"))
end
@info headerfiles()
