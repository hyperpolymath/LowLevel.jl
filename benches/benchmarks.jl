# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for LowLevel.jl.
# Measures the peak_performance_op pattern: vector ops under guardian monitoring.

using BenchmarkTools

include(joinpath(@__DIR__, "..", "..", "SiliconCore.jl", "src", "SiliconCore.jl"))
include(joinpath(@__DIR__, "..", "..", "HardwareResilience.jl", "src", "HardwareResilience.jl"))

println("=== LowLevel.jl Benchmarks ===")

# --- Architecture detection ---

println("\n-- Architecture detection --")

b_arch = @benchmark SiliconCore.detect_arch()
println("detect_arch: ", median(b_arch))

# --- vector_add_asm ---

println("\n-- vector_add_asm (SiliconCore) --")

a_small  = rand(Int, 10)
b_small  = rand(Int, 10)
a_medium = rand(Int, 1_000)
b_medium = rand(Int, 1_000)
a_large  = rand(Int, 100_000)
b_large  = rand(Int, 100_000)

b_vec_small  = @benchmark SiliconCore.vector_add_asm($a_small,  $b_small)
b_vec_medium = @benchmark SiliconCore.vector_add_asm($a_medium, $b_medium)
b_vec_large  = @benchmark SiliconCore.vector_add_asm($a_large,  $b_large)
println("vector_add_asm (n=10):      ", median(b_vec_small))
println("vector_add_asm (n=1000):    ", median(b_vec_medium))
println("vector_add_asm (n=100_000): ", median(b_vec_large))

# --- monitor_kernel overhead ---

println("\n-- monitor_kernel overhead (HardwareResilience) --")

g = HardwareResilience.KernelGuardian("bench_guard", :Healthy)

b_monitor_noop = @benchmark HardwareResilience.monitor_kernel($g, () -> nothing)
b_monitor_small = @benchmark HardwareResilience.monitor_kernel($g, () ->
    SiliconCore.vector_add_asm($a_small, $b_small))
b_monitor_large = @benchmark HardwareResilience.monitor_kernel($g, () ->
    SiliconCore.vector_add_asm($a_large, $b_large))
b_monitor_error = @benchmark HardwareResilience.monitor_kernel($g, () ->
    error("fault"))

println("monitor_kernel noop:             ", median(b_monitor_noop))
println("monitor_kernel vec(n=10):        ", median(b_monitor_small))
println("monitor_kernel vec(n=100_000):   ", median(b_monitor_large))
println("monitor_kernel error recovery:   ", median(b_monitor_error))
