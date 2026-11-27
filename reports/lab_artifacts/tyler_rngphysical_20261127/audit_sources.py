"""Audit archived PR #27 inputs against their Git versions, without EDA tools."""
import hashlib
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[3]
versions = {"main": "f137a6c", "proto1": "30caa47", "proto2": "9a0dda5"}
for variant, revision in versions.items():
    folder = root / "reports/sim" / ("t_update_Dbhsv3Oy_" + variant)
    manifest = json.loads((folder / "manifest.json").read_text())
    normalized = []
    for name, expected in manifest["source_sha256"].items():
        blob = subprocess.check_output(["git", "show", revision + ":" + name], cwd=root)
        if hashlib.sha256(blob).hexdigest() == expected:
            continue
        lf = blob.replace(b"\r\n", b"\n")
        if b"\0" not in blob and any(hashlib.sha256(value).hexdigest() == expected
                                      for value in (lf, lf.replace(b"\n", b"\r\n"))):
            normalized.append(name)
            continue
        snapshot = folder / "source_snapshot" / name
        if not snapshot.is_file():
            raise SystemExit("No exact snapshot for mismatching source: " + name)
        archived = snapshot.read_bytes()
        if hashlib.sha256(archived).hexdigest() != expected:
            raise SystemExit("Archived snapshot digest mismatch: " + name)
        if b"\0" in archived or archived.replace(b"\r\n", b"\n") != blob.replace(b"\r\n", b"\n"):
            raise SystemExit("Source content differs from Git: " + name)
        normalized.append(name)
    print(variant, revision, "PASS", len(manifest["source_sha256"]),
          "inputs; newline-only:", len(normalized))

for name in ("constraints/lane_5ns.sdc", "scripts/syn/config.tcl", "scripts/syn/dc_synth.tcl",
             "tech/gscl45nm/setup_fixed_v1/gscl45nm.lib", "tech/gscl45nm/setup_fixed_v1/gscl45nm.db"):
    blobs = [subprocess.check_output(["git", "show", rev + ":" + name], cwd=root) for rev in versions.values()]
    assert all(blob == blobs[0] for blob in blobs), name
print("PASS identical constraints, flow and paired libraries across all three versions")
