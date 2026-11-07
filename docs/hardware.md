# Hardware

## Board

| Item | Value |
| --- | --- |
| Board | Digilent **Nexys A7-100T** |
| FPGA | XC7A100T-1CSG324C (Artix-7) |
| Clock | 100 MHz on pin `E3` |
| Video | On-board VGA connector, 12-bit colour (4 bits per channel) |
| Keyboard | On-board PS/2 connector (`PS2_CLK` F4, `PS2_DATA` B2) |
| Audio | PWM audio output (`AUD_PWM` A11) + amplifier enable (`AUD_SD` D12) |
| Display | 16 LEDs, 8-digit 7-segment, 5 push buttons, 16 switches |
| Storage | 16 MiB QSPI flash (not used by the game) |

The pin assignment follows the official Digilent master XDC
([Nexys-A7-100T-Master.xdc](https://github.com/Digilent/digilent-xdc)).
Only the pins used by `Main` are enabled in
[`../constraints/nexys_a7.xdc`](../constraints/nexys_a7.xdc); all 69 top-level ports are mapped.

## What to connect

1. USB cable to the **USB-JTAG** port (programming and power).
2. VGA monitor to the VGA connector.
3. PS/2 keyboard to the PS/2 connector.
4. Headphones or powered speakers to the mono audio jack.
5. Optionally, a second USB cable to the USB-UART port (not needed by the game).

## Clocking

- `clk` is the 100 MHz board oscillator.
- The VGA pixel clock is `clk / 2` = 50 MHz, generated inside `DU` by toggling a flip-flop.

## Video mode

The game renders a 200×150 canvas and scales it 4× to 800×600:

| Parameter | Value |
| --- | --- |
| Pixel clock | 50 MHz |
| Horizontal | 120 + 64 + 800 + 56 = 1040 pixels |
| Vertical | 6 + 23 + 600 + 37 = 666 lines |
| Refresh | ≈ 72.2 Hz |
| Colour | 12-bit RGB444 (4 bits per channel) |

Most monitors accept 800×600 @ 72 Hz. If yours does not, the timing constants are in
`rtl/video/DST.v`; they were tuned on the lab monitor and should be changed with care.

## Controls

### Front panel

| Input | Function |
| --- | --- |
| BTNC | Confirm / hit (same as a key tap) |
| CPU_RESETN | Reset the video and audio units |
| SW0 | Invincible mode |
| SW2 | Return to the title screen while playing |
| SW3–SW5 | Fixed speed 1–7 (`000` = keyboard fine-tuning) |
| SW6 | Auto-play |
| SW7 | LED debug view |
| SW8 | 7-segment debug view |
| SW10–SW14 | Debug data selector |
| SW15 | LED source (colour mixer or HUD) |

### Keyboard

| Key | Function |
| --- | --- |
| `1` | Toggle auto-play |
| `2` | Toggle invincible mode |
| `4` | Faster |
| `5` | Slower |
| `6` | Default speed |
| `9` | Cycle the picture style |
| any other key | Hit / confirm |

The keyboard is scanned by `PS2Receiver` (scan code set 2). Modifier keys and the extended
`0xE0` prefix are not decoded; the game only needs the last scan code and a press event.

## Notes

- The game state is initialised at configuration time. Re-programming the bitstream is the
  reliable way to restart; during play, SW2 returns to the title screen.
- Auto-play should be enabled **after** the song starts, because it also suppresses manual hits
  (used for the start/confirm press).
- The audio amplifier enable (`sd`) is driven by the music player and is low while idle.
- The 7-segment display is multiplexed at 2.5 ms per digit; it may flicker on camera but not to
  the eye.
