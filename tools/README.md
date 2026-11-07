# Tools

## `image2coe.py`

Converts one or more images into an RGB444 `.coe` file (3 hex digits per pixel, 4 bits per
channel), matching the format used by the `mammap` background ROM and the `memvmap`
framebuffer.

```bash
pip install -r tools/requirements.txt

# three background pages, padded to 102,400 words (as in data/coe/r1.coe)
python tools/image2coe.py data/images/r1.png data/images/r2.png data/images/r3.png \
    -o data/coe/r1.coe --width 200 --height 150 --pad 102400

# one title screen
python tools/image2coe.py docs/images/title.png -o data/coe/beginphoto.coe \
    --width 200 --height 150
```

Options:

| Option | Meaning |
| --- | --- |
| `--width`, `--height` | Output size in pixels (default 200 × 150) |
| `--pad N` | Pad with zero words up to N total words |
| `--background RRGGBB` | Matte colour for transparent pixels (default `000000`) |
| `--comment TEXT` | Extra text for the first line of the COE file |

The archived background PNGs are RGBA and have a transparent background, while the shipped
`.coe` files were generated from the original opaque images. Re-running the converter therefore
produces a valid but not byte-identical file; use `--background` if you need a solid matte.

## `requirements.txt`

[`requirements.txt`](requirements.txt) contains the only dependency (`Pillow`).

## Legacy generators

The chart, track, font and sine tables were produced by four small programs that are kept in
[`legacy/`](legacy) for reference. Their input files were not archived, so they cannot
reproduce the shipped charts. See [`legacy/README.md`](legacy/README.md).
