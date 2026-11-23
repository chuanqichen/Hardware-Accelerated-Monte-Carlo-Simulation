"""Reject tracked EDA build products, including files added with git add -f."""
from pathlib import Path, PurePosixPath
import subprocess


def build_products(paths):
    return [
        name for name in paths
        if any(part.startswith("simv") or part == "csrc" or part.startswith("csrc_")
               for part in PurePosixPath(name).parts)
        or (name.startswith("reports/syn/") and "work" in PurePosixPath(name).parts)
        or PurePosixPath(name).suffix in (".o", ".so", ".a", ".sdb", ".mr", ".pvl", ".pvk", ".syn")
    ]


def main():
    root = Path(__file__).resolve().parents[1]
    paths = subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "-z", "--", "reports"]
    ).decode().split("\0")
    rejected = build_products(path for path in paths if path)
    if rejected:
        raise SystemExit("Build products must not be archived:\n" + "\n".join(rejected))
    print("Tracked evidence contains no EDA build products.")


if __name__ == "__main__":
    main()
