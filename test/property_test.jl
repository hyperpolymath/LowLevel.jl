# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# Property-based invariant tests for LowLevel.jl.

using Test

include(joinpath(@__DIR__, "..", "..", "SiliconCore.jl", "src", "SiliconCore.jl"))
include(joinpath(@__DIR__, "..", "..", "HardwareResilience.jl", "src", "HardwareResilience.jl"))

@testset "Property-Based Tests" begin

    @testset "vector_add_asm is commutative" begin
        for _ in 1:50
            n = rand(1:20)
            a = rand(Int, n)
            b = rand(Int, n)
            @test SiliconCore.vector_add_asm(a, b) == SiliconCore.vector_add_asm(b, a)
        end
    end

    @testset "vector_add_asm preserves length" begin
        for _ in 1:50
            n = rand(0:50)
            a = rand(Int, n)
            b = rand(Int, n)
            result = SiliconCore.vector_add_asm(a, b)
            @test length(result) == n
        end
    end

    @testset "vector_add_asm is element-wise correct" begin
        for _ in 1:50
            n = rand(1:20)
            a = rand(-100:100, n)
            b = rand(-100:100, n)
            result = SiliconCore.vector_add_asm(a, b)
            for i in 1:n
                @test result[i] == a[i] + b[i]
            end
        end
    end

    @testset "vector_add_asm: zero vector is identity" begin
        for _ in 1:50
            n = rand(1:20)
            a = rand(Int, n)
            z = zeros(Int, n)
            @test SiliconCore.vector_add_asm(a, z) == a
            @test SiliconCore.vector_add_asm(z, a) == a
        end
    end

    @testset "monitor_kernel: non-throwing op always returns op value" begin
        g = HardwareResilience.KernelGuardian("prop_ll", :Healthy)
        for _ in 1:50
            n = rand(1:10)
            a = rand(Int, n)
            b = rand(Int, n)
            result = HardwareResilience.monitor_kernel(g, () ->
                SiliconCore.vector_add_asm(a, b)
            )
            @test result == a .+ b
        end
    end

    @testset "monitor_kernel: always returns nothing on error" begin
        g = HardwareResilience.KernelGuardian("prop_ll_err", :Healthy)
        for _ in 1:50
            result = HardwareResilience.monitor_kernel(g, () -> error("fault"))
            @test result === nothing
        end
    end

    @testset "detect_arch always returns a Symbol" begin
        for _ in 1:20
            arch = SiliconCore.detect_arch()
            @test arch isa Symbol
            @test arch !== :unknown_invalid  # Should be a valid arch name.
        end
    end

end
