# SPDX-License-Identifier: MPL-2.0
using Test
using LowLevel

@testset "LowLevel.jl" begin

    @testset "SiliconCore sub-module accessible" begin
        @test isdefined(SiliconCore, :detect_arch)
        @test isdefined(SiliconCore, :vector_add_asm)
        @test SiliconCore.detect_arch() isa Symbol
    end

    @testset "HardwareResilience sub-module accessible" begin
        @test isdefined(HardwareResilience, :KernelGuardian)
        @test isdefined(HardwareResilience, :monitor_kernel)
    end

    @testset "peak_performance_op with integers" begin
        result = peak_performance_op([1, 2, 3], [4, 5, 6])
        @test result == [5, 7, 9]
    end

    @testset "peak_performance_op with floats" begin
        result = peak_performance_op([1.0, 2.0], [3.0, 4.0])
        @test result == [4.0, 6.0]
    end

    @testset "peak_performance_op with error recovery" begin
        # Incompatible dimensions fail inside the monitored vector operation.
        result = peak_performance_op([1, 2], [3, 4, 5])
        @test result === nothing
    end

    @testset "peak_performance_op with empty vectors" begin
        result = peak_performance_op(Int[], Int[])
        @test result == Int[]
    end

end

include("e2e_test.jl")
include("property_test.jl")
