## Model available here
[Released here on printables](https://www.printables.com/model/1854921-star-activity-tracker)

## Building the STLs

Requires [OpenSCAD](https://openscad.org) and GNU Make. OpenSCAD is not on
PATH by default on Windows; point the Makefile at your install with
`OPENSCAD="C:\...\openscad.exe"` if needed.

- `make` - builds one case for each size from 1 to 10 tokens, plus a token
- `make clean` - removes the generated STLs

## Geometry regression check

`tests/verify.py` renders a few configurations with OpenSCAD, reduces each
STL to a fingerprint (triangle count, mesh volume, bounding box, hash of the
sorted vertex list) and compares it against `tests/baseline.json`:

- `make verify` - check the current model against the recorded baseline
- `make verify-save` - re-record the baseline after intentionally changing
  the geometry

## Parameters

Everything interesting lives at the top of `ActivityTracker.scad`:

| Parameter | Default | Meaning |
| --- | --- | --- |
| `token_width` | 30 | Square footprint of a token window (mm) |
| `token_height` | 35 | Token length (mm) |
| `token_depth` | 6 | Window cavity depth (mm) |
| `thickness` | 3 | Window floor and rear panel thickness (mm) |
| `spacing` | 3 | Gap between windows (mm) |
| `tokens` | 3 | Number of windows in the case |
| `case_or_token` | "case" | `"case"` renders the display case, `"token"` a single token |