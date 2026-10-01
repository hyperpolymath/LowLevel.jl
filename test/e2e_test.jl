# SPDX-License-Identifier: MPL-2.0
# (MPL-2.0 preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for LowLevel.jl.
# Tests the coordinated pipeline: SiliconCore vector operation wrapped in
# HardwareResilience monitoring through peak_performance_op.

using Test
using LowLevel

@testset "E2E Pipeline Tests" begin

    @testset "Full pipeline: detect arch → vector add → monitored execution" begin
        # Step 1: detect architecture (SiliconCore).
        arch = SiliconCore.detect_arch()
        @test arch isa Symbol

        # Step 2: perform guarded vector addition through the package API.
        result = peak_performance_op([10, 20, 30], [1, 2, 3])
        @test result == [11, 22, 33]
    end

    @testset "Full pipeline: bulk vector operations under guardian monitoring" begin
        n = 100
        a = collect(1:n)
        b = collect(n:-1:1)
        result = peak_performance_op(a, b)
        # a[i] + b[i] == n+1 for all i.
        @test all(r == n + 1 for r in result)
        @test length(result) == n
    end

    @testset "Full pipeline: empty vector round-trip" begin
        result = peak_performance_op(Int[], Int[])
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
        a = [1.5, 2.5, 3.5]
        b = [0.5, 0.5, 0.5]
        result = peak_performance_op(a, b)
        @test result ≈ [2.0, 3.0, 4.0]
    end

    @testset "Round-trip consistency: guardian degrades and recovers" begin
        g = KernelGuardian("e2e_status"; retry_delay_ms=0)
        @test g.status === :active
        @test monitor_kernel(g, () -> [1] + [2]) == [3]
        @test g.status === :active
        @test monitor_kernel(g, () -> error("fault")) === nothing
        @test g.status === :degraded
        @test length(g.failure_log) == g.max_retries
        @test monitor_kernel(g, () -> [1] + [2]) == [3]
        @test g.status === :active
    end

end
