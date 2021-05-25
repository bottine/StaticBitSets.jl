

struct SBitSet{N,T<:Unsigned}
    pieces::NTuple{N,T}
end


@inline function SBitSet(s::SBitSet{N,T}) where {N,T<:Unsigned}
    SBitSet{N,T}(s.pieces)
end


@inline function Base.length(s::SBitSet{N,T}) where {N,T<:Unsigned}
    sum(count_ones.(s.pieces))
end

@inline function Base.isempty(s::SBitSet{N,T}) where {N,T<:Unsigned}
    all(==(0), s.pieces)
end

@inline function Base.:(==)(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned}
    s1.pieces == s2.pieces
end

@inline function Base.:(&)(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned}
    SBitSet{N,T}((&).(s1.pieces,s2.pieces))
end
Base.:(∩)(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned} = s1 & s2

@inline function Base.:(|)(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned}
    SBitSet{N,T}((|).(s1.pieces,s2.pieces))
end
Base.:(∪)(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned} = s1 | s2

@inline function Base.:(~)(s1::SBitSet{N,T}) where {N,T<:Unsigned}
    SBitSet{N,T}((~).(s1.pieces))
end
Base.:(~)(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned} = s1 ∩ ~s2

@inline function Base.:(⊆)(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned}
   s1 ∩ s2 == s1 
end

@inline function Base.in(x::Integer,s::SBitSet{N,T}) where {N,T<:Unsigned}
    (d,r) = _divrem(x,N,8*sizeof(T))
    Bool((s.pieces[d] >> (r-1)) & T(1))
end

@inline function Base.isdisjoint(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned}
    @inbounds @simd for i in 1:N
        (s1.pieces[i]&s2.pieces[i]) ≠ 0 && return false
    end
    return true
end
⟂(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned} = isdisjoint(s1,s2) # WARNING: ⟂ is \perp, not \bot

@inline function singleton_intersection(s1::SBitSet{N,T},s2::SBitSet{N,T}) where {N,T<:Unsigned}
    ones_tot = 0
    @inbounds for i in 1:N
        ones_tot += count_ones(s1.pieces[i]&s2.pieces[i])
        ones_tot > 1 && return false
    end
    return Bool(ones_tot)
end


@inline function SBitSet{N,T}() where {N,T<:Unsigned}
    SBitSet{N,T}(ntuple(x->T(0),N))
end

"""
    _divrem(n,N,)

For ``1≤n≤N*W``, return ``d,r`` with ``1≤r≤W`` and ``W*(d-1)+r=n``.

"""
@inline function _divrem(n::Integer,N::Integer,W::Integer)
   @assert 1 ≤ n ≤ N*W
   (d,r) = divrem(n,W)
    if r == 0
        (d,r) = (d,W)
    else
        (d,r) = (d+1,r)
    end
    return (d,r)
end

@inline function SBitSet{N,T}(n::Integer) where {N,T<:Unsigned}
    (d,r) = _divrem(n,N,8*sizeof(T))
    SBitSet{N,T}(ntuple(x-> x == d ? (T(1) << (r-1)) : T(0),N))
end

@inline function SBitSet{N,T}(nn::Integer...) where {N,T<:Unsigned}
    s = SBitSet{N,T}()
    for i in nn
        s = push(s,i)
    end
    return s
end

@inline function SBitSet{N,T}(v::Vector) where {N,T<:Unsigned}
    s = SBitSet{N,T}()
    for i in v
        s = push(s,i)
    end
    return s
end

@inline function push(s::SBitSet{N,T},n::Integer) where {N,T<:Unsigned}
    (d,r) = _divrem(n,N,8*sizeof(T))
    SBitSet{N,T}(ntuple(x-> x == d ? (@inbounds s.pieces[x]) | (T(1) << (r-1)) : (@inbounds s.pieces[x]),N))
end

@inline function pop(s::SBitSet{N,T},n::Integer) where {N,T<:Unsigned}
    (d,r) = _divrem(n,N,8*sizeof(T))
    SBitSet{N,T}(ntuple(x-> x == d ? (@inbounds s.pieces[x]) & ~(T(1) << (r-1)) : (@inbounds s.pieces[x]),N))
end

@inline function Base.iterate(s::SBitSet{N,T}) where {N,T<:Unsigned}
    Base.iterate(s,(1,1,1, @inbounds s.pieces[1]))
end

@inline function Base.iterate(s::SBitSet{N,T},(d,r,current,current_block)) where {N,T<:Unsigned}
    while d ≤ N
        if current_block ≠ T(0)
            tz = trailing_zeros(current_block)
            return (current+tz, (d,r+tz+1,current+tz+1,current_block>>(tz+1)))
        end
        d += 1
        r = 1
        current = (8*sizeof(T))*(d-1)+1
        d > N && return nothing
        @inbounds current_block = s.pieces[d]
    end
    
    return nothing 
end

Base.eltype(::Type{SBitSet{N,T}}) where {N,T<:Unsigned} = T

function Base.show(io::IO, s::SBitSet{N,T}) where {N,T<:Unsigned}
    print(io,"SBitSet{$N,$T}{")
    for n in s
        print(io,n,",")
    end
    print(io,"}")
end
