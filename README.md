# Argus

Aho-Corasick pattern matcher on an Arty A7-35T, written in SystemVerilog and verified with UVM. It scans a byte stream against a set of patterns (think IDS signatures like "cmd.exe") and flags matches in hardware.

Follow-on to [Hermes](https://github.com/rbala25/Hermes), another project I did involving a market-making engine with a full Ethernet/TCP/IP stack. Where Hermes was more so about getting packets through a pipeline with minimal latency, this project was more focused on verification methodology and memory hierarchy.

## Caching

The matcher itself is a fairly standard algorithm, but the interesting part is what sits in front of it.

The automaton's transition table is too big to keep entirely in fast memory, so hot states get cached. The usual answer is a reactive policy like LRU. But an Aho-Corasick automaton is a fixed structure: which states get hit most is computable *before any traffic arrives*. State 0 dominates because most bytes don't advance any pattern. So rather than letting the cache learn at runtime, an analysis script derives per-state access frequency from the transition table offline and picks the preload set at boot.

On a directed test with an 8-line cache:

| Policy | Hits | Misses |
|--------|------|--------|
| Static (root only) | 28 | 19 |
| FIFO | 26 | 21 |
| LRU | 27 | 20 |
| Random | 26 | 21 |
| **Static (analyzed placement)** | **34** | **13** |

Static placement wins with zero warmup, and the gap grows on longer inputs since reactive policies keep paying for evictions on states they've already seen. The same reasoning shows up in LLM inference hardware: KV cache eviction and MoE expert placement are also cases where the access pattern is knowable ahead of time, so guessing at runtime is the wrong abstraction.

## Verification

My previous projects were verified with directed testbenches and HIL testing, but this time the whole design runs through one UVM environment. The scoreboard checks matches against a reference model and logs hit/miss counts, which means all four eviction policies get judged by the same testbench, and swapping between them is a one-parameter change with zero testbench edits.

## Components

- Python build script that constructs the automaton from a pattern file and emits `.mem` files for the RTL
- FSM matcher, flip-flop cache with a `POLICY` parameter (static / FIFO / LRU / random), and a fake DDR3 model with configurable latency
- Full UVM testbench with a scoreboard that checks matches against a reference model and logs hit/miss counts
- Analysis script that computes access frequencies and selects the preload set

## Stack

Vivado 2025.2 / XSim, SystemVerilog, UVM 1.2, Python 3, Digilent Arty A7-35T.
