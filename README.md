# Argus
FPGA Aho-Corasick pattern matcher on an Arty A7-35T. Hardware intrusion detection with a cache
hierarchy that shows analytically derived state placement beats reactive eviction with zero warmup
cost. The argument extends to KV cache eviction in LLM inference and expert weight pinning in MoE
accelerators.

## The Argument
Aho-Corasick automaton access frequencies are fully derivable before any input arrives. State 0
(root) dominates every realistic traffic trace because most bytes don't advance any active pattern.

A Python analysis script computes per-state access frequency from the transition table and selects
preload targets analytically. FIFO, LRU, and random eviction all have to learn this from traffic;
the static policy already knows it at boot. On a 47-byte directed test with an 8-line cache,
optimal static preloading produces 34 hits against LRU's 27 with no warmup, and the gap widens on
longer inputs because the access distribution is fixed while reactive policies keep paying eviction
overhead on states they've already learned.

KV cache eviction in LLM inference is the same problem: when the buffer overflows, the question is
which past token representations to drop, and the answer follows from model architecture and input
distribution rather than runtime behavior.

Expert weight placement in MoE models follows from routing statistics for the same reason. The
argument generalizes to any memory hierarchy where the access distribution is derivable from
structure rather than traffic.

## Highlights
**Aho-Corasick Automaton:** Python build script constructs the automaton from a pattern file,
computes failure links via BFS, and emits `transition.mem` and `match.mem` for `$readmemh`
loading. 47 states, 6-bit state width, 8.8KB transition table.

**Pipelined Memory Hierarchy:** Flip-flop cache with combinational reads and zero-latency hits,
backed by a configurable-latency DDR3 proxy in simulation. Each cache line holds all 256
next-state transitions for one automaton state. The hierarchy is intentionally undersized relative
to on-chip BRAM to model a bandwidth-constrained system where the access pattern question actually
bites.

**Selectable Eviction Policy:** The cache module takes a `POLICY` parameter selecting static
preload, FIFO, LRU, or LFSR-random. All four run through the same UVM testbench with hit/miss
counters wired out as 32-bit ports and logged by the scoreboard at end of test.

**Static Hot-State Placement:** A Python analysis script computes per-state access frequency from
the transition table and selects preload targets before the first byte of traffic arrives.

47-byte directed test, 8-line fully associative cache, DDR3 proxy latency 5 cycles:
| Policy | Hits | Misses |
|--------|------|--------|
| Static, HOT_STATES = state 0 × 8 (default) | 28 | 19 |
| FIFO | 26 | 21 |
| LRU | 27 | 20 |
| Random | 26 | 21 |
| **Static, analytically optimal HOT_STATES** | **34** | **13** |

Optimal static beats LRU by 7 hits on the first pass with no warmup, and the gap widens on longer
inputs because the access distribution is fixed while reactive policies keep paying eviction
overhead on states they've already learned.

**UVM Testbench:** Full UVM environment: driver, monitor, sequencer, scoreboard, agent, env. The
scoreboard checks match correctness against a reference model and logs hit/miss counts. A flat
`argus_if` wraps all DUT I/O for virtual interface access across the hierarchy.

## Stack
| Layer | Tech |
|-------|------|
| FPGA | Xilinx Artix-7 XC7A35T |
| Board | Digilent Arty A7-35T |
| RTL | SystemVerilog |
| Toolchain | Vivado 2025.2 / XSim |
| Verification | UVM 1.2 |
| Automaton Build | Python 3 |

Follow-on to [Hermes](https://github.com/rbala25/Hermes), going deeper on memory hierarchy design
and verification methodology.
