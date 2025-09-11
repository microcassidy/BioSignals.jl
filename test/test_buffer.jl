@testset "buffer" begin
  buffer = WaveformDB.CircularBuffer{2,UInt8}()
  for i in 1:5
    WaveformDB.push!(buffer, i)
    if buffer.length == 2
      @test buffer[2] > buffer[1]
    end
  end
end
