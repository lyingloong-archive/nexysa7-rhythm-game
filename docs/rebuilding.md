# Rebuilding the bitstream

> **Status.** The original Vivado project (`.xpr`) and the six memory IP cores were not
> archived. The RTL and the complete pin constraints are in this repository, but a new
> bitstream needs those memory cores recreated first. This page records everything that is
> known about them. The depths below are inferred from the address widths in the RTL; the
> original IP configuration was not preserved.

## What is known

- Vivado **2024.1** built the shipped bitstream (`bitstream/Main.bit`, dated 2024-12-29), for
  **xc7a100tcsg324** (Nexys A7-100T).
- Top module: `Main`.
- Clock constraint: 100 MHz (`create_clock -period 10.000` on `clk`).
- All 69 top-level ports are constrained in [`../constraints/nexys_a7.xdc`](../constraints/nexys_a7.xdc).
- The design uses no other Xilinx primitives or IP cores; the only missing pieces are the six
  memories below.

## Memory cores

The RTL instantiates them by name (`mammap`, `memvmap`, `memscore`, `memsin`, `memmusic`,
`memroad`). The port names in the RTL identify the IP type:

| Instance | IP type | Ports | Width × depth | Init file | Read latency |
| --- | --- | --- | --- | --- | --- |
| `mammap` | Block Memory Generator (single-port ROM) | `clka`, `addra[17:0]`, `douta[11:0]` | 12 × 262,144 | `r1.coe` | 1 clock |
| `memvmap` | Distributed Memory Generator (dual-port RAM, one write / one read) | `a[14:0]`, `d[11:0]`, `dpra[14:0]`, `we`, `clk`, `dpo[11:0]` | 12 × 32,768 | `beginphoto.coe` | asynchronous |
| `memscore` | Distributed Memory Generator (ROM) | `a[9:0]`, `spo[11:0]` | 12 × 1,024 | `putd.coe` | asynchronous |
| `memsin` | Distributed Memory Generator (ROM) | `a[8:0]`, `spo[31:0]` | 32 × 512 | `sin.coe` | asynchronous |
| `memmusic` | Distributed Memory Generator (ROM) | `a[8:0]`, `spo[23:0]` | 24 × 512 | `music3.coe` | asynchronous |
| `memroad` | Distributed Memory Generator (single-port RAM, used as ROM) | `a[9:0]`, `d[63:0]`, `we`, `clk`, `spo[63:0]` | 64 × 1,024 | `road6.coe` | asynchronous |

Notes:

- The `douta` port of `mammap` is registered (block RAM minimum latency), which is why
  `Fresh` reads it two cycles before using the data.
- The `spo`/`dpo` outputs of the distributed memories are asynchronous; the RTL relies on this
  (for example `Music` compares the chart word in the same cycle the address is presented).
- `memroad` exposes a write port because the instantiation in `Solve` connects `.d(64'd0)` and
  `.we(1'b0)`. A single-port RAM with those ports keeps the RTL unchanged; if you change the
  instantiation to a ROM (`a`/`spo` only), the runtime behaviour is the same.
- The initialisation files are shorter than the memories; enable *fill remaining memory
  locations* (or the equivalent) so the unused words are zero.

## Steps (Vivado 2024.1)

1. Create a project for **xc7a100tcsg324-1** (Nexys A7-100T).
2. Add all files under `rtl/` as design sources and set `Main` as the top module.
3. Add `constraints/nexys_a7.xdc` as a constraint file.
4. Recreate the six cores above with the IP catalog (`Block Memory Generator` and
   `Distributed Memory Generator`). Point each *coe file* field at the corresponding file in
   `data/coe/`; use an absolute path or regenerate the project on the machine that builds it.
5. Run synthesis, implementation and `write_bitstream`.
6. Program the board with the Hardware Manager and compare against the released `Main.bit`.
   The cleaned RTL has only been elaboration-checked, so this is the first real verification.

## Alternative: inferred memories

The six cores could be replaced by portable RTL (`reg [11:0] mem [0:N]` plus `$readmemh`) so the
design builds without the IP catalog and can be simulated. That is a larger change than the
2026 cleanup and would need a hardware test, because the read latencies and the 32,768-word
framebuffer inference have to match exactly. It is left as future work.

## What was not verified

- The cleaned RTL has **not** been synthesised or placed and routed.
- No timing report or resource utilisation was archived.
- No testbench exists; the only executable reference is the released bitstream.
