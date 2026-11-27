"""Package only this validation's compact evidence; leave raw lab outputs intact."""
import argparse
import gzip
import hashlib
from pathlib import Path
import shutil
import tarfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--write", action="store_true")
args = parser.parse_args()
root = Path.cwd()
session = root / "build/tyler_rng_20261127"
stage = session / "evidence"
excluded_suffixes = {".ddc", ".svf", ".gds", ".vcd", ".fsdb", ".o", ".so", ".a", ".sdb", ".mr", ".pvl", ".pvk", ".syn", ".key"}
selected = []
for path in sorted((root / "reports").rglob("*")):
    rel = path.relative_to(root)
    if not any(part.startswith(("tyler_rng_20261127_rtl", "tyler_rng_syn_20261127",
                                "tyler_rng_syn24_20261127", "tyler_rng_closure_20261127"))
               for part in rel.parts):
        continue
    if any(part.startswith(("simv", "csrc")) or part == "work" or part.endswith((".enc.dat", ".enc"))
           for part in rel.parts):
        continue
    if path.is_symlink() or not path.is_file() or path.suffix in excluded_suffixes:
        continue
    selected.append(path)
print("Compact source files:", len(selected), "uncompressed bytes:", sum(p.stat().st_size for p in selected))
if not args.write:
    raise SystemExit(0)
if stage.exists():
    raise SystemExit("Refusing an existing evidence staging directory: " + str(stage))
stage.mkdir()
for path in selected:
    rel = path.relative_to(root)
    compress = path.suffix in {".def", ".spef"}
    target = stage / (str(rel) + (".gz" if compress else ""))
    target.parent.mkdir(parents=True, exist_ok=True)
    if compress:
        with path.open("rb") as source, target.open("wb") as output:
            with gzip.GzipFile(fileobj=output, mode="wb", filename="", mtime=0) as encoded:
                shutil.copyfileobj(source, encoded, 1 << 20)
    else:
        shutil.copyfile(path, target)
paths = [p for p in stage.rglob("*") if p.is_file()]
manifest = session / "compact_sha256.txt"
with manifest.open("w", newline="\n") as stream:
    for path in sorted(paths):
        digest = hashlib.file_digest(path.open("rb"), "sha256").hexdigest()
        stream.write(digest + "  " + path.relative_to(stage).as_posix() + "\n")
archive = session / "compact_evidence.tar.gz"
with tarfile.open(archive, "w:gz") as bundle:
    for path in sorted(paths):
        bundle.add(path, arcname=path.relative_to(stage).as_posix(), recursive=False)
print("Archive bytes:", archive.stat().st_size)
print("Archive SHA-256:", hashlib.file_digest(archive.open("rb"), "sha256").hexdigest())
