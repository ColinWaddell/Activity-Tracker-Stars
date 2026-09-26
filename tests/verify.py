"""Geometry regression check for ActivityTracker.scad.

Renders the model with OpenSCAD for a few ``-D`` configurations, reduces each
STL to a handful of numbers (triangle count, mesh volume, bounding box and a
hash of the sorted vertex list) and compares them against a recorded
baseline in ``tests/baseline.json``.

Usage::

    python tests/verify.py save    # render the current file, record baseline
    python tests/verify.py check   # render the current file, diff vs baseline

The OpenSCAD executable is resolved from the ``OPENSCAD`` environment
variable, falling back to the default Windows install path (mirroring the
Makefile).
"""

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAD = ROOT / "ActivityTracker.scad"
BASELINE = Path(__file__).with_name("baseline.json")
OPENSCAD = Path(os.environ.get("OPENSCAD", r"C:\Program Files\OpenSCAD\openscad.com"))

TOLERANCE = 1e-3

# name -> (token count, part value)
CASES = {
    "case_1": (1, "case"),
    "case_2": (2, "case"),
    "case_3": (3, "case"),
    "case_10": (10, "case"),
    "token": (3, "token"),
}


def render(case_name, tokens, part):
    """Render one configuration to an STL next to the baseline."""
    stl = BASELINE.with_name(f"{case_name}.stl")
    cmd = [
        str(OPENSCAD),
        "-o", str(stl),
        "-D", f"tokens={tokens}",
        "-D", f'case_or_token="{part}"',
        str(SCAD),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"OpenSCAD failed for {case_name}:\n{result.stderr}")
    return stl


def stl_stats(path):
    """Reduce an ASCII STL to comparison-friendly numbers."""
    vertices = []
    with path.open(encoding="ascii") as fh:
        for line in fh:
            fields = line.split()
            if fields[:1] == ["vertex"]:
                vertices.append([float(c) for c in fields[1:4]])
    if not vertices or len(vertices) % 3:
        raise ValueError(f"{path}: not a well-formed ASCII STL")

    mins = [min(v[axis] for v in vertices) for axis in range(3)]
    maxs = [max(v[axis] for v in vertices) for axis in range(3)]

    # Six times the signed volume, via the divergence theorem.
    volume6 = 0.0
    for i in range(0, len(vertices), 3):
        a, b, c = vertices[i : i + 3]
        volume6 += (
            a[0] * (b[1] * c[2] - b[2] * c[1])
            - a[1] * (b[0] * c[2] - b[2] * c[0])
            + a[2] * (b[0] * c[1] - b[1] * c[0])
        )

    # Order-independent fingerprint of the exact vertex positions.
    digest = hashlib.sha256(
        "\n".join(
            ",".join(f"{c:.5f}" for c in v) for v in sorted(vertices)
        ).encode("ascii")
    ).hexdigest()

    return {
        "triangles": len(vertices) // 3,
        "volume": abs(volume6) / 6,
        "bbox_min": mins,
        "bbox_max": maxs,
        "vertex_sha256": digest,
    }


def render_all():
    return {name: stl_stats(render(name, *case)) for name, case in CASES.items()}


def save():
    stats = render_all()
    BASELINE.write_text(json.dumps(stats, indent=2) + "\n", encoding="ascii")
    print(f"Baseline recorded: {BASELINE}")
    print(json.dumps(stats, indent=2))
    return 0


def close(a, b):
    return abs(a - b) <= TOLERANCE


def check():
    if not BASELINE.exists():
        print(f"No baseline at {BASELINE}; run 'save' first.")
        return 2
    recorded = json.loads(BASELINE.read_text(encoding="ascii"))
    stats = render_all()

    failures = []
    for name in CASES:
        for key, value in stats[name].items():
            expected = recorded.get(name, {}).get(key)
            if expected is None:
                failures.append(f"{name}.{key}: missing from baseline")
            elif key == "vertex_sha256":
                if value != expected:
                    failures.append(f"{name}.{key}: vertices differ")
            elif isinstance(value, list):
                if not all(close(a, b) for a, b in zip(value, expected)):
                    failures.append(f"{name}.{key}: {expected} -> {value}")
            elif isinstance(value, float):
                if not close(value, expected):
                    failures.append(f"{name}.{key}: {expected} -> {value}")
            elif value != expected:
                failures.append(f"{name}.{key}: {expected} -> {value}")

    if failures:
        print("Geometry regression check FAILED:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print(f"Geometry regression check passed ({len(CASES)} configurations).")
    return 0


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "check"
    if mode == "save":
        return save()
    if mode == "check":
        return check()
    print(f"Unknown mode {mode!r}; expected 'save' or 'check'.")
    return 2


if __name__ == "__main__":
    sys.exit(main())