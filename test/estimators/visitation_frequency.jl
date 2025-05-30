using Entropies
using Entropies.DelayEmbeddings, Test
using Random

@testset "Rectangular binning" begin
    x = Dataset(rand(Random.MersenneTwister(1234), 100_000, 2))
    push!(x, SVector(0, 0)) # ensure both 0 and 1 have values in, exactly.
    push!(x, SVector(1, 1))
    # All these binnings should give approximately same probabilities
    n = 10 # boxes cover 0 - 1 in steps of slightly more than 0.1
    ε = nextfloat(0.1) # this guarantees that we get the same as the `n` above!

    binnings = [
        RectangularBinning(n),
        RectangularBinning(ε),
        RectangularBinning([n, n]),
        RectangularBinning([ε, ε])
    ]

    for bin in binnings
        @testset "ϵ = $(bin.ϵ)" begin
            est = ValueHistogram(bin)
            p = probabilities(x, est)
            @test length(p) == 100
            @test all(e -> 0.009 ≤ e ≤ 0.011, p)
        end
    end

    @testset "Check rogue 1s" begin
        b = RectangularBinning(0.1) # no `nextfloat` here, so the rogue (1, 1) is in extra bin!
        p = probabilities(x, ValueHistogram(b))
        @test length(p) == 100 + 1
        @test p[end] ≈ 1/100_000 atol = 1e-5
    end

    @testset "vector" begin
        x = rand(Random.MersenneTwister(1234), 100_000)
        push!(x, 0, 1)
        n = 10 # boxes cover 0 - 1 in steps of slightly more than 0.1
        ε = nextfloat(0.1) # this guarantees that we get the same as the `n` above!
        binnings = RectangularBinning.((n, ε))
        for bin in binnings
            p = probabilities(x, ValueHistogram(bin))
            @test length(p) == 10
            @test all(e -> 0.09 ≤ e ≤ 0.11, p)
        end
    end

    # An extra bin might appear due to roundoff error after using nextfloat when
    # constructing `RectangularBinEncoding`s.
    # The following tests ensure with *some* certainty that this does not occur.
    @testset "Rogue extra bins" begin
        rng = MersenneTwister(1234)
        xs1D = [rand(rng, 20) for i = 1:10000];
        xs2D = [rand(rng, 1000, 2) |> Dataset for i = 1:10000] # more points to fill all bins
        est = ValueHistogram(RectangularBinning(10))
        ps1D = [probabilities(x, est) for x in xs1D];
        ps2D = [probabilities(x, est) for x in xs2D];
        n_rogue_extrabin_1D = count(length.(ps1D) .> est.binning.ϵ)
        n_rogue_extrabin_2D = count(length.(ps2D) .> est.binning.ϵ^2)
        @test n_rogue_extrabin_1D == 0
        @test n_rogue_extrabin_2D == 0

        # Concrete examples where a rogue extra bin has appeared.
        x1 = [0.5213236385155418, 0.03516318860292644, 0.5437726723245310, 0.52598710966469610, 0.34199879802511246, 0.6017129426606275, 0.6972844365031351, 0.89163995617220900, 0.39009862510518045, 0.06296038912844315, 0.9897176284081909, 0.7935001082966890, 0.890198448900077700, 0.11762640519877565, 0.7849413168095061, 0.13768932585886573, 0.50869900547793430, 0.18042178201388548, 0.28507312391861270, 0.96480406570924970]
        x2 = [0.4125754262679051, 0.52844411982339560, 0.4535277505543355, 0.25502420827802674, 0.77862522996085940, 0.6081939026664078, 0.2628674795466387, 0.18846258495465185, 0.93320375283233840, 0.40093871561247874, 0.8032730760974603, 0.3531608285217499, 0.018436525139752136, 0.55541857934068420, 0.9907521337888632, 0.15382361136212420, 0.01774321666660561, 0.67569337507728300, 0.06130971689608822, 0.31417161558476836]
        N = 10
        b = RectangularBinning(N)
        rb1 = RectangularBinEncoding(x1, b, n_eps = 1)
        rb2 = RectangularBinEncoding(x1, b, n_eps = 2)
        @test Entropies.encode_as_bin(maximum(x1), rb1) == 10 # shouldn't occur, but does when tolerance is too low
        @test Entropies.encode_as_bin(maximum(x1), rb2) == 9

        rb1 = RectangularBinEncoding(x2, b, n_eps = 1)
        rb2 = RectangularBinEncoding(x2, b, n_eps = 2)
        @test Entropies.encode_as_bin(maximum(x2), rb1) == 10 # shouldn't occur, but does when tolerance is too low
        @test Entropies.encode_as_bin(maximum(x2), rb2) == 9
    end

    @testset "interface" begin
        x = ones(3)
        p = probabilities(x, ValueHistogram(0.1))
        @test p isa Probabilities
        @test_throws MethodError entropy(x, 0.1)
    end
end
