#!/usr/bin/env python3
r"""List every lab file of one run tag with its size, SHA-256 and repository status.

Standard library only. It reads the lab checkout and writes nothing there.
A file is "committed" when the same path in a checkout of the reference commit
has identical bytes; otherwise it is "lab-only". A symbolic link is listed with
its target and the target's size and digest. Verify a retained copy with:
  awk -F'\t' 'NR>1 {print $1"  "$5}' files.tsv | sha256sum -c --quiet
"""
import argparse
import hashlib
import os
import re
import sys

CATEGORIES = [
    ("innovus_database", r"\.enc\.dat/|\.enc$"),
    ("vcs_build", r"/(simv|simv\.daidir|csrc)(/|$)|/ucli\.key$|/vc_hdrs\.h$"),
    ("waveform", r"\.(vcd|fsdb|saif)(\.gz)?$"),
    ("layout", r"\.(def|gds|gds2|oas)(\.gz)?$"),
    ("parasitics", r"\.spef(\.gz)?$"),
    ("netlist", r"\.v(\.gz)?$"),
    ("constraints", r"\.sdc$"),
    ("timing_report", r"\.(rpt|tarpt|summary|cap|fanout|length|tran)(\.gz)?$"),
    ("log", r"\.(log|out|cmd\d*)$"),
    ("script", r"\.(tcl|sh|py)$"),
    ("metadata", r"\.(txt|csv|json|hex|md)$"),
]
TAB = "\t"
NL = "\n"


def category(path):
    for name, pattern in CATEGORIES:
        if re.search(pattern, path):
            return name
    return "other"


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", required=True, help="lab checkout that holds the run")
    ap.add_argument("--tag", required=True, help="run tag contained in every listed path")
    ap.add_argument("--reference", required=True, help="checkout of the reference commit")
    ap.add_argument("--extra", nargs="*", default=[], help="additional root-relative files")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    root = os.path.abspath(args.root)
    paths = set()
    for dirpath, dirnames, filenames in os.walk(root):
        if os.path.relpath(dirpath, root).split(os.sep)[0] == ".git":
            dirnames[:] = []
            continue
        for name in filenames:
            rel = os.path.relpath(os.path.join(dirpath, name), root)
            if args.tag in rel:
                paths.add(rel)
    for rel in args.extra:
        if not os.path.isfile(os.path.join(root, rel)):
            sys.exit("missing extra file: " + rel)
        paths.add(rel)
    rows = []
    for rel in sorted(paths):
        full = os.path.join(root, rel)
        target = os.readlink(full) if os.path.islink(full) else ""
        if target and not os.path.isfile(full):
            sys.exit("dangling symbolic link: " + rel)
        digest = sha256(full)
        ref = os.path.join(args.reference, rel)
        committed = (not target and os.path.isfile(ref) and not os.path.islink(ref)
                     and sha256(ref) == digest)
        status = "committed" if committed else "lab-only"
        cat = "symlink" if target else category(rel)
        rows.append((digest, os.path.getsize(full), status, cat, rel, target))
    with open(args.out, "w", newline=NL) as f:
        f.write(TAB.join(["sha256", "bytes", "status", "category", "path", "link_target"]) + NL)
        for digest, size, status, cat, rel, target in rows:
            f.write(TAB.join([digest, str(size), status, cat, rel, target]) + NL)
    totals = {}
    for digest, size, status, cat, rel, target in rows:
        n, b = totals.get((status, cat), (0, 0))
        totals[(status, cat)] = (n + 1, b + size)
    for (status, cat), (n, b) in sorted(totals.items()):
        print("%-9s %-17s %5d files %13d bytes" % (status, cat, n, b))
    print("total %d files %d bytes" % (len(rows), sum(r[1] for r in rows)))


if __name__ == "__main__":
    main()
