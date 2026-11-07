# Legacy generators

These are the original data-generator programs from the course project. They are kept for
reference only: their input files were not archived and the programs were written for a
specific Windows machine (hard-coded paths, `<io.h>`).

| File | Output | Input | Notes |
| --- | --- | --- | --- |
| `tranp.cpp` | `putd.coe` | built-in 5×7 digit table | Still runnable; no external input |
| `tran4.cpp` | `sin.coe`, `road2.coe`, `music2.txt` | `data3.txt` | Track/sine generator; input format only partly recoverable from the code |
| `tranmusic.cpp` | `music.coe` | `musicmodi.txt` | Note-chart generator |

The shipped data uses later file names (`road6.coe`, `music3.coe`), so the outputs of these
programs are earlier revisions rather than the archived data.

## What the code reveals

`tran4.cpp`:

- reads `R`, `r` (sine radius parameters), then a segment list (`p`, `dx`, `dy`);
- writes a 360-entry sine table as `{cos[31:16], sin[15:0]}`;
- then generates 1,000 64-bit track words from 20 segment headers and per-note `(x, y)`,
  direction and timing values.

`tranmusic.cpp` converts `(time, pitch)` pairs into 24-bit chart words
(`time[23:4]`, `note[3:0]`) and writes `music.coe`.

## Removed

The original `1.py` image converter is gone: it contained a hard-coded local path with a
student ID. Use [`../image2coe.py`](../image2coe.py) instead.
