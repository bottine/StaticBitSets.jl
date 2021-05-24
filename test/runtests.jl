using Test
using Random
using StaticBitSets




@testset "SBitSet{$N}, to and from" for N in 1:4
    for round in 1:100
        content = Set()
        bs = SBitSet{N}()
        for i in rand(1:N*64,N*N)
            push!(content,i)
            bs = push(bs,i)
            @test Set(collect(bs)) == content
        end
        for i in rand(1:N*64,N*N)
            pop!(content,i,nothing)
            bs = pop(bs,i)
            @test Set(collect(bs)) == content
        end
    end
end
@testset "SBitSet{$N}, bitwise ops, empty, isdisjoint and length" for N in 1:4
    
    data = Vector{Vector{UInt64}}(collect(eachrow(rand(1:64*N,100,4*N))))
    sets = Set.(data)
    bitsets = SBitSet{N}.(data)
    
    @test sets == Set.(collect.(bitsets)) 

    for i in 1:100, j in 1:100
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
