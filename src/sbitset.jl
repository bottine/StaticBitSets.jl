

struct SBitSet{N}
    pieces::NTuple{N,UInt64}
end


@inline function SBitSet(s::SBitSet{N}) where N
    SBitSet{N}(s.pieces)
end


@inline function Base.length(s::SBitSet{N}) where N
    sum(count_ones.(s.pieces))
end

@inline function Base.isempty(s::SBitSet{N}) where N
    all(==(0), s.pieces)
end

@inline function Base.:(==)(s1::SBitSet{N},s2::SBitSet{N}) where N
    s1.pieces == s2.pieces
end

@inline function Base.:(&)(s1::SBitSet{N},s2::SBitSet{N}) where N
    SBitSet{N}((&).(s1.pieces,s2.pieces))
end
Base.:(∩)(s1::SBitSet{N},s2::SBitSet{N}) where N = s1 & s2

@inline function Base.:(|)(s1::SBitSet{N},s2::SBitSet{N}) where N
    SBitSet{N}((|).(s1.pieces,s2.pieces))
end
Base.:(∪)(s1::SBitSet{N},s2::SBitSet{N}) where N = s1 | s2

@inline function Base.:(~)(s1::SBitSet{N}) where N
    SBitSet{N}((~).(s1.pieces))
end
Base.:(~)(s1::SBitSet{N},s2::SBitSet{N}) where N = s1 ∩ ~s2

@inline function Base.:(⊆)(s1::SBitSet{N},s2::SBitSet{N}) where N
   s1 ∩ s2 == s1 
end

@inline function isdisjoint(s1::SBitSet{N},s2::SBitSet{N}) where N
    @inbounds @simd for i in 1:N
        (s1.pieces[i]&s2.pieces[i]) ≠ 0 && return false
    end
    return true
end

⟂(s1::SBitSet{N},s2::SBitSet{N}) where N = isdisjoint(s1,s2)

@inline function singleton_intersection(s1::SBitSet{N},s2::SBitSet{N}) where N
    ones_tot = 0
    @inbounds for i in 1:N
        ones_tot += count_ones(s1.pieces[i]&s2.pieces[i])
        ones_tot > 1 && return false
    end
    return Bool(ones_tot)
end


@inline function SBitSet{N}() where N
    SBitSet{N}(ntuple(x->UInt64(0),N))
end

"""
    _divrem64(n,N)

For ``1≤n≤N*64``, return ``d,r`` with ``1≤r≤64`` and ``64*(d-1)+r=n``.

"""
@inline function _divrem64(n::Integer,N::Integer)
   @assert 1 ≤ n ≤ N*64
   (d,r) = divrem(n,64)
    if r == 0
        (d,r) = (d,64)
    else
        (d,r) = (d+1,r)
    end
    return (d,r)
end

@inline function SBitSet{N}(n::Integer) where N
    (d,r) = _divrem64(n,N)
    SBitSet{N}(ntuple(x-> x == d ? (UInt64(1) << (r-1)) : UInt64(0),N))
end

@inline function SBitSet{N}(v::Vector) where N
    s = SBitSet{N}()
    for i in v
        s = push(s,i)
    end
    return s
end

@inline function push(s::SBitSet{N},n::Integer) where N
    (d,r) = _divrem64(n,N)
    SBitSet{N}(ntuple(x-> x == d ? (@inbounds s.pieces[x]) | (UInt64(1) << (r-1)) : (@inbounds s.pieces[x]),N))
end

@inline function pop(s::SBitSet{N},n::Integer) where N
    (d,r) = _divrem64(n,N)
    SBitSet{N}(ntuple(x-> x == d ? (@inbounds s.pieces[x]) & ~(UInt64(1) << (r-1)) : (@inbounds s.pieces[x]),N))
end

@inline function Base.iterate(s::SBitSet{N}) where N
    Base.iterate(s,(1,1,1, @inbounds s.pieces[1]))
end

@inline function Base.iterate(s::SBitSet{N},(d,r,current,current_block)) where N
    while d ≤ N
        if current_block ≠ UInt64(0)
            tz = trailing_zeros(current_block)
            return (current+tz, (d,r+tz+1,current+tz+1,current_block>>(tz+1)))
        end
        d += 1
        r = 1
        current = 64*(d-1)+1
        d > N && return nothing
        @inbounds current_block = s.pieces[d]
    end
    
    return nothing 
end

Base.eltype(::Type{SBitSet}) = UInt64

function Base.show(io::IO, s::SBitSet{N}) where N
    print(io,"{")
    for n in s
        print(io,n,",")
    end
    print(io,"}")
end
