# Architecture

This document describes how the game is put together. It is written for someone who wants to
read or modify the RTL, not for the original lab report.

## Clock domains

| Clock | Source | Used by |
| --- | --- | --- |
| `clk` | 100 MHz board oscillator (pin E3) | everything except the VGA output stage |
| `pclk` | `clk / 2` (50 MHz) | VGA timing (`DST`), scaling (`DDP`) |
| `PS2_CLK` | keyboard | sampled by the debouncer, not used as a clock |

The distributed-memory tables (`memvmap`, `memscore`, `memsin`, `memmusic`, `memroad`) are
asynchronous; `mammap` is a block RAM with one cycle of read latency. This keeps the 100 MHz
logic and the 50 MHz pixel pipeline independent.

## Top level

`rtl/top/Main.v` instantiates and connects the whole system:

```
PS/2 + BTNC ──► getclicked ──► clear / auto / keep / speed / style
                                   │
switches ──────────────────────────┤
                                   ▼
                    Solve (scheduler + judge) ◄── memroad
                       │        │
                       │        └──► Score (BCD accumulator) ──► 7-segment payload
                       ▼
                    Fresh (frame composer) ◄── mammap, memscore, memsin
                       │
                       ▼
                    DU (DST + DDP) ◄── memvmap (framebuffer) ──► VGA
                       ▲
                       │
                    Music (player) ◄── memmusic ──► audio ──► PWM / SD
```

## Module reference

| File | Module | Role |
| --- | --- | --- |
| `rtl/top/Main.v` | `Main` | Top level, game state machine, timers |
| `rtl/game/Solve.v` | `Solve` | Walks the chart, times hits, drives judging and scoring |
| `rtl/game/Fresh.v` | `Fresh` | Scans the 200×150 canvas and writes pixels to the framebuffer |
| `rtl/game/Judge.v` | `Judge` | Converts a timing error into one of eight judgement levels |
| `rtl/game/Score.v` | `Score` | Accumulates the decimal score through a BCD adder |
| `rtl/game/Calvalid.v` | `Calvalid` | 3-cycle `(x-dx)² + (y-dy)² <= r²` hit test |
| `rtl/game/Getdot.v` | `Getdot` | Draws one 5×7 digit from the font ROM |
| `rtl/game/Getsin.v` | `Getsin` | Reads the sine/cosine table for the track direction |
| `rtl/game/speeder.v` | `speeder` | Maps speed selection to clocks-per-percent |
| `rtl/game/JK.v` | `JK` | JK flip-flop used as a one-shot latch |
| `rtl/game/STreg.v` | `STreg` | Sticky 16-bit register for note time/length |
| `rtl/video/DU.v` | `DU` | Video output unit (framebuffer + timing + scaling) |
| `rtl/video/DST.v` | `DST`, `CntS` | VGA sync generator and reloadable down-counter |
| `rtl/video/DDP.v` | `DDP` | 4× pixel replication and colour styles |
| `rtl/video/Segment.v` | `Segment` | 8-digit 7-segment scanner |
| `rtl/video/transseg.v` | `transseg` | Nibble to active-low segment decoder |
| `rtl/audio/Music.v` | `Music` | Song player (chart ROM → note events) |
| `rtl/audio/audio.v` | `audio`, `sound`, `Music_decoder` | Note → period → PWM |
| `rtl/audio/pwm_gen.v` | `pwm_gen` | PWM carrier with a `pulse` tick |
| `rtl/input/getclicked.v` | `getclicked` | Key decoding and one-shot events |
| `rtl/input/keyboard_top.v` | `keyboard_top` | PS/2 wrapper |
| `rtl/input/PS2Receiver.v` | `PS2Receiver` | 11-bit PS/2 frame decoder |
| `rtl/input/debouncer.v` | `debouncer` | 20-cycle debouncer |
| `rtl/common/Adder8421.v` | `Adder8421` | 4-digit packed-BCD adder |
| `rtl/common/transer.v` | `transer` | Binary → packed BCD for the speed display |
| `rtl/common/Counter.v` | `Counter` | Two-level counter, compile-time divider |
| `rtl/common/CounterW.v` | `CounterW` | Two-level counter, runtime divider |

## Main state machine

`START → WAIT → RUN → STOP → START`

| State | Behaviour |
| --- | --- |
| `START` | Title screen. `Fresh` redraws from `beginphoto`; the first `clear` loads the chart (`inprepare`) and moves to `WAIT`. |
| `WAIT` | Waits for `okpre` (chart loaded). The next `clear` starts the song and moves to `RUN`. |
| `RUN` | Plays. `endpass` (end of song), `WA` (wrong note) or SW2 (restart) leave the state. |
| `STOP` | Shows the result. After two timer ticks, a `clear` returns to `START`. |

`clear` is produced by `getclicked` from a key tap or a BTNC edge, and is suppressed while
auto-play is on.

## Chart and note flow

`Solve` reads the track table from `memroad`:

- Address `0..19` are segment headers; the low 16 bits are the number of notes in that segment.
  Reading a header advances `BLOn` by one background page (200 × 150 pixels).
- Address `20 + n` is note `n`: `x[63:48]`, `y[47:32]`, direction[31], duration[30:16],
  angle offset[15:0].

For each note the state machine waits for a hit, runs the circle hit tests (`Calvalid` ×4 with
different radii), asks `Judge` for a level, and lets `Score` add the points. The renderer gets
the note position, HUD colour and score through `Main`.

The position inside the song is a percentage: `CounterW` with `MAX=360` counts 0..359 once every
`cpp` clocks, where `cpp` comes from `speeder`. A second `CounterW` with `MAX=1000000` measures
the note length.

## Frame composer

`Fresh` is a pixel-scanning state machine:

| State | Behaviour |
| --- | --- |
| `SWITCH` | Advances `x`/`y` over the 200×150 canvas, updates the note positions, starts the hit tests. |
| `RUN` | Waits for the hit tests, then decides between background, note, HUD or menu pixels. |
| `README` | Reads one pixel from the background ROM (`mammap`). |
| `WRITEME` | Writes one pixel into the framebuffer through the `DU` write port. |

The HUD zones (speed buttons, pause, score, dots, state box) are simple on-screen rectangles in
`Fresh`. `Getdot` reads the 5×7 font ROM (`memscore`) and reports whether the current pixel
belongs to the digit; `transer` converts the speed value to BCD for the same font.

## Video path

- `DU` divides `clk` by two to get the 50 MHz pixel clock.
- `DST` generates the 800×600 @ 72 Hz timing. The reload values are one less than the phase
  length (see `rtl/video/DST.v`): H = 120 + 64 + 800 + 56 = 1040 pixels,
  V = 6 + 23 + 600 + 37 = 666 lines; 50 MHz / 1040 / 666 ≈ 72.2 Hz.
- `DDP` reads the 200×150 framebuffer four times per pixel (4× replication) and applies one of
  four colour styles selected with key `9`.
- `memvmap` is a 32768×12 dual-port RAM: one write port for `Fresh`, one read port for `DDP`.
  The read is asynchronous, so the pixel data is available in the same cycle as the address.

## Audio path

`Music` reads one 24-bit word from `memmusic` per note:

- `data[23:4]` = note start time in units of `WIDTH` clocks (the current clocks-per-percent value)
- `data[3:0]` = note number (0 = rest, 1..7 = do..si, bit 3 = high octave)

When the song timer matches, the note is pushed to `audio`. `audio` adds seven to the decoder
index for the high octave, `Music_decoder` maps the index to a 12-bit period, and `sound` slowly
sweeps the PWM duty cycle to make an envelope. `Music` also drives `sd` (amplifier enable) and
gates the PWM output while the player is idle.

## Memory map

| Instance | IP type | Ports used | Size | Init file | Read latency |
| --- | --- | --- | --- | --- | --- |
| `mammap` | block memory generator (ROM) | `clka`, `addra[17:0]`, `douta[11:0]` | 262144 × 12 | `r1.coe` | 1 cycle |
| `memvmap` | distributed memory (dual-port RAM) | `a[14:0]`, `d[11:0]`, `dpra[14:0]`, `we`, `dpo[11:0]` | 32768 × 12 | `beginphoto.coe` | asynchronous |
| `memscore` | distributed memory (ROM) | `a[9:0]`, `spo[11:0]` | 1024 × 12 | `putd.coe` | asynchronous |
| `memsin` | distributed memory (ROM) | `a[8:0]`, `spo[31:0]` | 512 × 32 | `sin.coe` | asynchronous |
| `memmusic` | distributed memory (ROM) | `a[8:0]`, `spo[23:0]` | 512 × 24 | `music3.coe` | asynchronous |
| `memroad` | distributed memory (single-port RAM used as ROM) | `a[9:0]`, `d[63:0]`, `we`, `spo[63:0]` | 1024 × 64 | `road6.coe` | asynchronous |

The IP cores are not part of this repository; their recreation is described in
[`rebuilding.md`](rebuilding.md).

## Display and debug

- The 8-digit 7-segment display scans one digit every 250,000 clocks (2.5 ms) and shows the
  32-bit payload built by `Solve` (score, judgement, or a debug word selected with SW8/SW7).
- The 16 LEDs show `state`, `auto`, `keep`, the SW11–SW14 debug selector and a colour/debug
  byte. SW15 selects between the HUD colour byte and the debug byte.

## Known quirks

These are preserved on purpose because the prebuilt bitstream is the reference:

- Power-on state comes from `initial` blocks (Xilinx GSR initialises flops to zero). `nrst` only
  resets the video/audio units; it does not restart the game state machine.
- The LED concatenation in `Main` is 18 bits wide and is truncated to 16 bits; the top two bits
  of the colour byte are therefore lost.
- `Getdot` takes an 8-bit `x` and a 4-bit `y`; `Fresh` passes 16-bit expressions and relies on
  truncation.
- Some modules (e.g. `audio`) use a data signal as a clock (`posedge note_en`).
- There are no testbenches. The RTL was elaboration-checked with Yosys after the 2026 cleanup.
