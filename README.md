# Basic immutable static bitset implementation

I wanted to use [this](https://raw.githubusercontent.com/chethega/StaticArrays.jl/fb0350012f01db4021d60906357e949333ec5d93/src/SBitSet.jl) but since there is no licence attached, I wrote my own implementation.

## Summary

The only type is `SBitSet{N,T}` where `N` should be a strictly positive integer, and `T` either of `UInt8,UInt16,UInt32,UInt64,UInt128`.
An element of type `SBitSet{N,T}` can store the integers `1:8*sizeof(T)*N`.

```julia
    
    using StaticBitSets
    
    x = SBitSet{2,UInt8}(1,2,8)
    y = SBitSet{2,UInt8}([1,2])
    z = push(y,8)
    
    for i in z
        println(i)
    end
    
    println(y∩x)
    println(y∪x)
    println(x~y)
    println(y⊆x)
    println(y⟂x)
    println(8∈y)
    println(8∈z)

```
