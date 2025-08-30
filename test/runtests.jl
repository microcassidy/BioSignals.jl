using Wfdb
using Test

@testset "Wfdb.jl" begin
    _ = Wfdb.parse_record_line("100 2 360 650000")
end
