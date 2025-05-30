using Entropies, Test

@testset "Timescales" begin
    N = 200
    a = 10
    t = LinRange(0, 2*a*π, N)
    x = sin.(t .+  cos.(t/0.1)) .- 0.1;

    @testset "WaveletOverlap" begin
        wl = Entropies.Wavelets.WT.Daubechies{4}()
        est = WaveletOverlap(wl)
        ps = probabilities(x, est)
        @test length(ps) == 8
        @test ps isa Probabilities
        @test entropy(Renyi( q = 1, base = 2), x, WaveletOverlap()) isa Real
    end

    @testset "Fourier Spectrum" begin
        N = 1000
        t = range(0, 10π, N)
        x = sin.(t)
        y = @. sin(t) + sin(sqrt(3)*t)
        z = randn(N)
        est = PowerSpectrum()
        ents = [entropy(Renyi(), w, est) for w in (x,y,z)]
        @test ents[1] < ents[2] < ents[3]
        # Test event stuff (analytically, using sine wave)
        probs, events = probabilities_and_outcomes(x, est)
        @test length(events) == length(probs) == 501
        @test events[1] ≈ 0 atol=1e-16 # 0 frequency, i.e., mean value
        @test probs[1] ≈ 0 atol=1e-16  # sine wave has 0 mean value
        @test events[end] == 0.5 # Nyquist frequency, 1/2 the sampling rate (Which is 1)
    end
end
