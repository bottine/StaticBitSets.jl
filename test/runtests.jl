using Test
using Random
using StaticBitSets


@testset "Out of Bounds" begin

    for N in 1:10, T in (UInt8,UInt16,UInt32,UInt64,UInt128)
        x = SBitSet{N,T}()
        min = 1
        max = N*8*sizeof(T)
        @test_throws AssertionError push(x,max+1) 
        @test_throws AssertionError push(x,max+10) 
        @test_throws AssertionError push(x,min-1) 
        @test_throws AssertionError push(x,-10) 
    end

end

@testset "Type compatibilities" begin

    combinations = [(1,UInt128),(2,UInt64),(4,UInt32),(8,UInt16),(16,UInt8)]
    max = 128

    data = Vector{Vector{UInt64}}(collect(eachrow(rand(1:max,100,max÷2))))
    bitsets = [SBitSet{N,T}.(data) for (N,T) in combinations]

    for i in 1:length(combinations)-1
        @test collect.(bitsets[i]) == collect.(bitsets[i+1])
    end
   
end

@testset "SBitSet{$N,$T}, to, from, push, pop and membership" for N in 1:4, T in (UInt8,UInt16,UInt32,UInt64,UInt128)

    max = N*8*sizeof(T)
    for round in 1:100
        content = Set()
        bs = SBitSet{N,T}()
        for i in rand(1:max,N*N)
            push!(content,i)
            bs = push(bs,i)
            @test i ∈ bs
            @test Set(collect(bs)) == content
        end
        for i in rand(1:max,N*N)
            pop!(content,i,nothing)
            bs = pop(bs,i)
            @test i ∉ bs
            @test Set(collect(bs)) == content
        end
    end
end

@testset "SBitSet{$N,$T}, bitwise ops, empty, isdisjoint and length" for N in 1:4, T in (UInt8,UInt16,UInt32,UInt64,UInt128)
   
    max = N*8*sizeof(T)
    
    data = Vector{Vector{UInt64}}(collect(eachrow(rand(1:max,100,4*N))))
    sets = Set.(data)
    bitsets = SBitSet{N,T}.(data)
    
    @test sets == Set.(collect.(bitsets)) 
    
    for (i,j) in collect(Iterators.product(1:length(data), 1:length(data)))
        @test sets[i] ∩ sets[j] == Set(bitsets[i] ∩ bitsets[j])
        @test isempty(sets[i] ∩ sets[j]) == isempty(Set(bitsets[i] ∩ bitsets[j]))
        @test isempty(sets[i] ∩ sets[j]) == isdisjoint(sets[i],sets[j])
        @test (length(sets[i] ∩ sets[j]) == 1) == singleton_intersection(bitsets[i],bitsets[j])
        @test length(sets[i] ∩ sets[j]) == length(Set(bitsets[i] ∩ bitsets[j]))
        @test sets[i] ∪ sets[j] == Set(bitsets[i] ∪ bitsets[j])
        @test isempty(sets[i] ∪ sets[j]) == isempty(Set(bitsets[i] ∪ bitsets[j]))
        @test length(sets[i] ∪ sets[j]) == length(Set(bitsets[i] ∪ bitsets[j]))
        @test setdiff(sets[i],sets[j]) == Set(bitsets[i] ~ bitsets[j])
        @test (sets[i] ⊆ sets[j]) == (bitsets[i] ⊆  bitsets[j])
    end

end

