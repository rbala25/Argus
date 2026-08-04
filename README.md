# Argus

FPGA Aho-Corasick pattern matcher on an Arty A7-35T. Hardware intrusion detection with a cache hierarchy built to show that analytically-derived memory placement beats reactive eviction policies with zero warmup cost.

## Highlights

**Aho-Corasick Automaton:** Python build script constructs the automaton from a pattern file, computes failure links via BFS, and emits `transition.mem` and `match.mem` for `$readmemh` loading. 47 states, 6-bit state width, 8.8KB transition table.

**Pipelined Memory Hierarchy:** Flip-flop cache with combinational reads and zero-latency hits, backed by a configurable-latency DDR3 proxy in simulation. Each cache line holds all 256 next-state transitions for one automaton state. The hierarchy is intentionally undersized relative to on-chip BRAM to model a bandwidth-constrained system where the access pattern question actually bites.

**Selectable Eviction Policy:** The cache module takes a `POLICY` parameter selecting static preload, FIFO, LRU, or LFSR-random. All four run through the same UVM testbench with hit/miss counters wired out as 32-bit ports and logged by the scoreboard at end of test.

**Static Hot-State Placement and why it wins:** Aho-Corasick automaton access frequencies are derivable before any input arrives. State 0 (root) dominates every realistic traffic trace because most bytes don't advance any pattern. A Python analysis script computes per-state access frequency directly from the transition table and selects preload targets analytically. The reactive policies have to learn this from traffic; the static policy already knows it at boot.

47-byte directed test, 8-line fully associative cache, DDR3 proxy latency 5 cycles:

| Policy | Hits | Misses |
|--------|------|--------|
| Static, HOT_STATES = state 0 × 8 (default) | 28 | 19 |
| FIFO | 26 | 21 |
| LRU | 27 | 20 |
| Random | 26 | 21 |
| **Static, analytically optimal HOT_STATES** | **34** | **13** |

Optimal static beats the best reactive policy by 7 hits on the first pass with no warmup. The gap would widen on longer inputs because the access distribution stays the same while reactive policies keep paying eviction overhead on states they've already learned.

**UVM Testbench:** Full UVM environment: driver, monitor, sequencer, scoreboard, agent, env. The scoreboard checks match correctness against a reference model and logs hit/miss counts. A flat `argus_if` wraps all DUT I/O for virtual interface access across the hierarchy.

**The broader claim:** The same argument applies to KV cache eviction in LLM inference (which past tokens to retain when the KV buffer overflows) and MoE expert placement (which expert weight matrices to pin in fast memory). In both cases access patterns are determined by model structure and input distribution rather than runtime behavior, which makes reactive eviction the wrong tool when structural prediction is available. Argus is the concrete vehicle; the claim is general.

## Stack

| Layer | Tech |
|-------|------|
| FPGA | Xilinx Artix-7 XC7A35T |
| Board | Digilent Arty A7-35T |
| RTL | SystemVerilog |
| Toolchain | Vivado 2025.2 / XSim |
| Verification | UVM 1.2 |
| Automaton Build | Python 3 |

Follow-on to [Hermes](https://github.com/rishib09/hermes), going deeper on memory hierarchy design and verification methodology.
