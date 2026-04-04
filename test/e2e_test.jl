# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for LowLevel.jl.
# Tests the coordinated pipeline: SiliconCore vector operation wrapped in
# HardwareResilience monitoring — the peak_performance_op pattern.

using Test

include(joinpath(@__DIR__, "..", "..", "SiliconCore.jl", "src", "SiliconCore.jl"))
include(joinpath(@__DIR__, "..", "..", "HardwareResilience.jl", "src", "HardwareResilience.jl"))

@testset "E2E Pipeline Tests" begin

    @testset "Full pipeline: detect arch → vector add → monitored execution" begin
        # Step 1: detect architecture (SiliconCore).
        arch = SiliconCore.detect_arch()
        @test arch isa Symbol

        # Step 2: perform guarded vector addition (peak_performance_op pattern).
        g = HardwareResilience.KernelGuardian("e2e_lowlevel", :Healthy)
        result = HardwareResilience.monitor_kernel(g, () ->
            SiliconCore.vector_add_asm([10, 20, 30], [1, 2, 3])
        )
        @test result == [11, 22, 33]
    end

    @testset "Full pipeline: bulk vector operations under guardian monitoring" begin
        g = HardwareResilience.KernelGuardian("e2e_bulk", :Healthy)
        n = 100
        a = collect(1:n)
        b = collect(n:-1:1)
        result = HardwareResilience.monitor_kernel(g, () ->
            SiliconCore.vector_add_asm(a, b)
        )
        # a[i] + b[i] == n+1 for all i.
        @test all(r == n + 1 for r in result)
        @test length(result) == n
    end

    @testset "Full pipeline: empty vector round-trip" begin
        g = HardwareResilience.KernelGuardian("e2e_empty", :Healthy)
        result = HardwareResilience.monitor_kernel(g, () ->
            SiliconCore.vector_add_asm(Int[], Int[])
        )
        @test result == Int[]
    end

    @testset "Error handling: hardware fault in vector op returns nothing" begin
        g = HardwareResilience.KernelGuardian("e2e_fault", :Healthy)
        result = HardwareResilience.monitor_kernel(g, () ->
            error("simulated hardware fault in vector unit")
        )
        @test result === nothing
    end

    @testset "Error handling: BoundsError during operation returns nothing" begin
        g = HardwareResilience.KernelGuardian("e2e_bounds", :Healthy)
        result = HardwareResilience.monitor_kernel(g, () ->
            [1, 2, 3][999]
        )
        @test result === nothing
    end

    @testset "Round-trip consistency: float vector addition" begin
        g = HardwareResilience.KernelGuardian("e2e_float", :Healthy)
        a = [1.5, 2.5, 3.5]
        b = [0.5, 0.5, 0.5]
        result = HardwareResilience.monitor_kernel(g, () ->
            SiliconCore.vector_add_asm(a, b)
        )
        @test result ≈ [2.0, 3.0, 4.0]
    end

    @testset "Round-trip consistency: guardian status independent of op result" begin
        g = HardwareResilience.KernelGuardian("e2e_status", :Healthy)
        @test g.status === :Healthy
        HardwareResilience.monitor_kernel(g, () -> [1] + [2])
        @test g.status === :Healthy  # Success does not alter status.
        HardwareResilience.monitor_kernel(g, () -> error("fault"))
        # Error handling is silent — status unchanged (guardian manages it externally).
        @test g.status === :Healthy
    end

end
