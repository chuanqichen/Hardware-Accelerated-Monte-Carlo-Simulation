"""Reproduce and verify the versioned, four-entry DFFPOSX1 approximation.

Only Python's standard library is required. --write regenerates Liberty and its
manifest; --record-build records a successful LC compilation; --check verifies
the complete source/binary pair. Timing validation is a separate experiment.
"""
import argparse
from decimal import Decimal, localcontext, ROUND_HALF_EVEN
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
TECH = ROOT / "tech/gscl45nm"
FIXED = TECH / "setup_fixed_v1"
ORIGINAL_LIB_SHA = "69c0641df1dc737e5c8dbd3950f2daf3b52c6e7767aa081e35e9b0739bf62d6f"
ORIGINAL_DB_SHA = "4968d1dba7ff9911cc51dfac7d8ea8b94fbab59d2f862f0531d7c774fb0a5791"
NOTICE = """/*
 Project modification by Chuanqi Chen, 2026-11-23: setup_fixed_v1.
 Four DFFPOSX1 setup values reconstructed from same-row clean neighbours.
 This is a documented project approximation, not SPICE recharacterization.
 See ../README.md, manifest.json and ../LICENSE.txt (Apache-2.0).
 All original library content follows, apart from those four values.
*/
"""
EDITS = (
    ("rise_constraint", "0.3", "0.06", "6.2", "0.24", "0.48"),
    ("rise_constraint", "0.3", "0.9", "5.125", "0.48", "1.2"),
    ("rise_constraint", "0.6", "0.06", "3.075", "0.24", "0.48"),
    ("fall_constraint", "0.3", "0.48", "5.85", "0.24", "0.9"),
)
NUMBER = r"-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def block(text, pattern, start=0, stop=None):
    """Locate a group in the hash-pinned upstream Liberty source."""
    match = re.search(pattern, text[start:stop])
    if not match:
        raise ValueError("Missing Liberty group: " + pattern)
    opening = text.index("{", start + match.end())
    depth = 1
    for index in range(opening + 1, len(text) if stop is None else stop):
        depth += (text[index] == "{") - (text[index] == "}")
        if depth == 0:
            return opening + 1, index
    raise ValueError("Unclosed Liberty group")


def repair(original):
    if sha(original) != ORIGINAL_LIB_SHA:
        raise ValueError("Unexpected original Liberty SHA-256; refusing to patch")
    text = original.decode("utf-8")
    cell = block(text, r"\bcell\s*\(\s*DFFPOSX1\s*\)")
    pin = block(text, r"\bpin\s*\(\s*D\s*\)", *cell)
    setup = re.search(r"\btiming_type\s*:\s*setup_rising\s*;", text[pin[0]:pin[1]])
    if not setup:
        raise ValueError("Missing DFFPOSX1/D setup_rising")
    setup_start = pin[0] + setup.end()
    replacements, changes = [], []
    for kind, clock, data, old, left, right in EDITS:
        begin, end = block(text, r"\b" + kind + r"\s*\(setup_template_3x6\)", setup_start, pin[1])
        content = text[begin:end]
        axes = [[Decimal(v.strip()) for v in re.search(
            r'index_' + str(i) + r'\s*\("([^"]+)"\)', content)[1].split(",")]
            for i in (1, 2)]
        values_start = re.search(r"\bvalues\s*\(", content).end()
        rows = list(re.finditer(r'"([^"]+)"', content[values_start:]))
        if len(rows) != len(axes[0]):
            raise ValueError("Unexpected constraint table shape")
        row = rows[axes[0].index(Decimal(clock))]
        tokens = list(re.finditer(NUMBER, row[1]))
        if len(tokens) != len(axes[1]):
            raise ValueError("Unexpected constraint row shape")
        target = tokens[axes[1].index(Decimal(data))]
        if Decimal(target[0]) != Decimal(old):
            raise ValueError("Unexpected constraint value")
        x, x0, x1 = map(Decimal, (data, left, right))
        y0, y1 = [Decimal(tokens[axes[1].index(v)][0]) for v in (x0, x1)]
        with localcontext() as ctx:
            ctx.prec = 50
            value = y0 + (x - x0) * (y1 - y0) / (x1 - x0)
            value = value.quantize(Decimal("0.000000000001"), rounding=ROUND_HALF_EVEN)
        new = format(value, "f").rstrip("0").rstrip(".")
        offset = begin + values_start + row.start(1) + target.start()
        replacements.append((offset, offset + len(target[0]), new))
        changes.append(dict(
            cell="DFFPOSX1", pin="D", related_pin="CLK", timing_type="setup_rising",
            constraint=kind, clock_transition_ns=clock, data_transition_ns=data,
            old_ns=old, new_ns=new,
            operation="interpolation" if x0 <= x <= x1 else "linear_extrapolation",
            donors=[dict(data_transition_ns=left, setup_ns=str(y0)),
                    dict(data_transition_ns=right, setup_ns=str(y1))]))
    for start, stop, new in sorted(replacements, reverse=True):
        text = text[:start] + new + text[stop:]
    return (NOTICE + text).encode("utf-8"), changes


def expected():
    original = (TECH / "original/gscl45nm.lib").read_bytes()
    if sha((TECH / "original/gscl45nm.db").read_bytes()) != ORIGINAL_DB_SHA:
        raise ValueError("Unexpected original compiled library")
    fixed, changes = repair(original)
    manifest = dict(
        revision="setup_fixed_v1", original_lib_sha256=ORIGINAL_LIB_SHA,
        original_db_sha256=ORIGINAL_DB_SHA, fixed_lib_sha256=sha(fixed),
        method="Same-row linear interpolation; nearest two clean points extrapolated at boundaries",
        formula="y0 + (x - x0) * (y1 - y0) / (x1 - x0)",
        rounding="12 decimal places in ns, round-half-to-even",
        qualification="Project approximation, not physical recharacterization",
        changes=changes)
    return fixed, manifest


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n")


def check_source():
    fixed, manifest = expected()
    if (FIXED / "gscl45nm.lib").read_bytes() != fixed:
        raise ValueError("Corrected Liberty does not match the four-entry reconstruction")
    if json.loads((FIXED / "manifest.json").read_text()) != manifest:
        raise ValueError("Correction manifest differs from its source")
    return manifest


def checksums(lib_sha, db_sha):
    return f"{lib_sha}  gscl45nm.lib\n{db_sha}  gscl45nm.db\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write", action="store_true")
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--record-build", type=Path, metavar="LC_METADATA")
    args = parser.parse_args()
    try:
        if args.write:
            fixed, manifest = expected()
            FIXED.mkdir(parents=True, exist_ok=True)
            (FIXED / "gscl45nm.lib").write_bytes(fixed)
            write_json(FIXED / "manifest.json", manifest)
            for entry in manifest["changes"]:
                print(entry["constraint"], entry["clock_transition_ns"],
                      entry["data_transition_ns"], entry["old_ns"], "->", entry["new_ns"])
            return
        manifest = check_source()
        db_sha = sha((FIXED / "gscl45nm.db").read_bytes())
        if args.record_build:
            metadata = dict(line.split("=", 1) for line in
                            args.record_build.read_text().splitlines() if line.strip())
            if metadata["source_sha256"] != manifest["fixed_lib_sha256"] or \
                    metadata["db_sha256"] != db_sha:
                raise ValueError("LC build metadata does not match the source/binary pair")
            write_json(FIXED / "compiled.json", metadata)
            (FIXED / "SHA256SUMS").write_text(checksums(manifest["fixed_lib_sha256"], db_sha))
        compiled = json.loads((FIXED / "compiled.json").read_text())
        if compiled["source_sha256"] != manifest["fixed_lib_sha256"] or compiled["db_sha256"] != db_sha:
            raise ValueError("Stale or mismatched compiled library")
        if (FIXED / "SHA256SUMS").read_text() != checksums(manifest["fixed_lib_sha256"], db_sha):
            raise ValueError("Runtime library checksums differ from build provenance")
        print("LIBRARY_CHECK_DONE setup_fixed_v1: source, four edits, compiled DB and checksums match")
    except (OSError, ValueError, KeyError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    main()
