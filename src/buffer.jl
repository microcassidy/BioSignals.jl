mutable struct CircularBuffer{N,T}
    buffer::NTuple{N,T}
    length::Integer
    first::Integer
    write_index::Integer
    CircularBuffer{N,T}() where {N,T} = new{N,T}(ntuple(_ -> zero(T), N), 0, 1, 1)
end


Base.@propagate_inbounds function Base.first(cb::CircularBuffer)
    @boundscheck (cb.length == 0) && throw(BoundsError(cb, 1))
    return cb.buffer[cb.first]
end

Base.@propagate_inbounds function Base.last(cb::CircularBuffer)
    @boundscheck (cb.length == 0) && throw(BoundsError(cb, 1))
    return cb.buffer[_buffer_index(cb, cb.length)]
end



@inline Base.isempty(buf::CircularBuffer) = buf.length == 0
@inline isfull(buf::CircularBuffer{N,T}) where {N,T} = buf.length == N

export _buffer_index
@inline function _buffer_index(cb::CircularBuffer{N,T}, i::Int) where {N,T}
    @boundscheck (i < 1 || i > N) && throw(BoundsError(cb, i))
    #convert to zero based indexing and then switch back after modulo
    offset = cb.first - 1
    idx = i - 1
    return (idx + offset) % N + 1
end

@inline function push!(cb::CircularBuffer{N,T}, data) where {N,T}
    converted_data = convert(T, data)
    if isfull(cb)
        cb.first %= N
        cb.first += 1
    else
        cb.length += 1
    end
    Base.setindex!(cb, converted_data, cb.write_index)
    cb.write_index %= N
    cb.write_index += 1
    return cb
end


export getindex, setindex!
Base.@propagate_inbounds function Base.getindex(cb::CircularBuffer{N,T}, i::Int) where {N,T}
    idx = _buffer_index(cb, i)
    if isbitstype(T)
        return GC.@preserve cb unsafe_load(Base.unsafe_convert(Ptr{T}, pointer_from_objref(cb)), idx)
    end
    getfield(cb, :buffer)[idx]
end

Base.@propagate_inbounds function Base.setindex!(cb::CircularBuffer{N,T}, val, i::Int) where {N,T}
    @boundscheck checkbounds(eachindex(cb.buffer), i)
    if isbitstype(T)
        GC.@preserve cb unsafe_store!(Base.unsafe_convert(Ptr{T}, pointer_from_objref(cb)), convert(T, val), i)
    else
        # This one is unsafe (#27)
        # unsafe_store!(Base.unsafe_convert(Ptr{Ptr{Nothing}}, pointer_from_objref(v.data)), pointer_from_objref(val), i)
        error("setindex!() with non-isbitstype eltype is not supported ")
    end
    return cb
end
