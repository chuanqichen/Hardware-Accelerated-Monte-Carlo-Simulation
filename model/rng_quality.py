"""Reproducible RNG screening (NumPy; optional Matplotlib plot).

Six-sigma limits are engineering screens, not calibrated p-values or proof of
independence. Model results are not RTL measurements. Imported hex streams are
checked word-for-word against an independent canonical xoshiro128++ oracle.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
import subprocess
import numpy as np

from price_study import lane_seeds
from rng_canonical_reference import canonical_next
from rng_lane import MASK32, next_word, pack_state, unpack_state

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ROOT = 0x0123456789ABCDEF0FEDCBA987654321
LAGS = (1, 2, 4, 8, 16)


def model_stream(seed, count):
    if count < 2 or not any(seed):
        raise ValueError("need at least two words and a nonzero seed")
    def words():
        state = seed
        for _ in range(count):
            word, state = next_word(state)
            yield word
    return np.fromiter(words(), dtype=np.uint32, count=count)


def read_stream(path, count, seed):
    """Reject truncated, extra, malformed or noncanonical stream data."""
    words = np.empty(count, dtype=np.uint32)
    state, seen = seed, 0
    with Path(path).open(encoding="ascii") as stream:
        for seen, line in enumerate(stream, 1):
            value = line.strip()
            if seen > count:
                raise ValueError(f"{path}: more than {count} words")
            if len(value) != 8 or any(c not in "0123456789abcdefABCDEF" for c in value):
                raise ValueError(f"{path}: malformed word on line {seen}")
            expected, state = canonical_next(state)
            if int(value, 16) != expected:
                raise ValueError(f"{path}: canonical mismatch on word {seen}")
            words[seen - 1] = expected
    if seen != count:
        raise ValueError(f"{path}: expected {count} words, got {seen}")
    return words


def correlation(left, right):
    left, right = np.asarray(left, dtype=float), np.asarray(right, dtype=float)
    left, right = left - left.mean(), right - right.mean()
    denominator = math.sqrt(float(left @ left) * float(right @ right))
    return float(left @ right) / denominator if denominator else float("nan")


def analyze_words(words, addr_bits=10, lags=LAGS, sigma=6.0):
    words = np.asarray(words)
    if (words.ndim != 1 or words.size < 2 or words.dtype.kind not in "ui"
            or np.any(words < 0) or np.any(words > MASK32)):
        raise ValueError("words must be a one-dimensional array of uint32 values")
    if not 1 <= addr_bits <= 16 or not math.isfinite(sigma) or sigma <= 0:
        raise ValueError("invalid address width or screening limit")
    if not lags or any(lag < 1 or lag >= words.size for lag in lags):
        raise ValueError("lags must be positive and less than the stream length")
    words = words.astype(np.uint32, copy=False)
    n = words.size
    scaled = words.astype(float) / 2**32
    # Exact moments for a discrete uniform uint32 divided by 2**32.
    expected_mean, expected_variance = (2**32 - 1) / 2**33, (1 - 2**-64) / 12
    mean_z = (float(scaled.mean()) - expected_mean) / math.sqrt(expected_variance / n)
    ones = np.array([np.count_nonzero((words >> bit) & 1) for bit in range(32)])
    bit_z = (ones - n / 2) / math.sqrt(n / 4)
    counts = np.bincount((words >> (32 - addr_bits)).astype(np.int64),
                         minlength=1 << addr_bits)
    expected_count, df = n / counts.size, counts.size - 1
    chi2 = float(np.sum((counts - expected_count)**2 / expected_count))
    chi2_limit = df + sigma * math.sqrt(2 * df)
    lag_rows = [dict(lag=lag, correlation=correlation(scaled[:-lag], scaled[lag:]),
                     screen_limit=sigma / math.sqrt(n - lag)) for lag in lags]
    passed = (expected_count >= 20 and abs(mean_z) <= sigma
              and float(np.max(np.abs(bit_z))) <= sigma and chi2 <= chi2_limit
              and all(math.isfinite(r["correlation"])
                      and abs(r["correlation"]) <= r["screen_limit"] for r in lag_rows))
    summary = dict(words=n, addr_bits=addr_bits, mean=float(scaled.mean()),
                   expected_mean=expected_mean, variance=float(scaled.var(ddof=1)),
                   expected_variance=expected_variance, mean_z=mean_z,
                   max_abs_bit_z=float(np.max(np.abs(bit_z))), chi2=chi2,
                   chi2_df=df, chi2_screen_limit=chi2_limit,
                   expected_bin_count=expected_count, sigma=sigma,
                   screening_pass=bool(passed))
    return summary, counts, ones, lag_rows


def write_csv(path, rows):
    rows = list(rows)
    if not rows:
        raise ValueError("refusing to write empty evidence")
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def artifact_path(prefix, suffix):
    return prefix.parent / (prefix.name + suffix)


def plot_study(prefix, hist, bits, lags, summaries):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axes = plt.subplots(3, 1, figsize=(10, 9))
    for stream in range(len(summaries)):
        h, b, lag = ([r for r in rows if r["stream"] == stream] for rows in (hist, bits, lags))
        axes[0].plot([r["bin"] for r in h], [r["count"] / r["expected_count"] for r in h],
                     lw=0.7, alpha=0.7, label=f"stream {stream}")
        axes[1].plot([r["bit"] for r in b], [r["z_score"] for r in b], ".-")
        axes[2].plot([r["lag"] for r in lag], [r["correlation"] for r in lag], ".-")
    axes[0].axhline(1, color="black", ls="--", lw=0.7)
    axes[0].set(xlabel="Top-bit LUT address", ylabel="Observed / expected count")
    axes[0].legend()
    for sign in (-1, 1):
        axes[1].axhline(sign * summaries[0]["sigma"], color="black", ls="--", lw=0.7)
        first = [r for r in lags if r["stream"] == 0]
        axes[2].plot([r["lag"] for r in first], [sign * r["screen_limit"] for r in first],
                     "k--", lw=0.7)
    axes[1].set(xlabel="Output bit (0 = LSB)", ylabel="Bit-balance z score")
    axes[2].set(xlabel="Lag (words)", ylabel="Serial correlation")
    fig.suptitle(f"{summaries[0]['origin']}: {len(summaries)} streams, "
                 f"{summaries[0]['words']:,} words each")
    fig.tight_layout()
    fig.savefig(artifact_path(prefix, "_quality.png"), dpi=180)
    plt.close(fig)


def run_study(streams, seeds, origin, prefix, addr_bits=10, sigma=6.0, plot=False,
              input_paths=()):
    if not streams or len(streams) != len(seeds):
        raise ValueError("need one seed per stream")
    prefix = Path(prefix)
    summaries, hist, bits, lags, pairs = [], [], [], [], []
    for index, (words, seed) in enumerate(zip(streams, seeds)):
        summary, counts, ones, lag_rows = analyze_words(words, addr_bits, sigma=sigma)
        common = dict(origin=origin, stream=index, seed_bus=f"{pack_state(seed):032x}")
        summaries.append(dict(common, **summary))
        hist.extend(dict(common, bin=i, count=int(c), expected_count=summary["expected_bin_count"])
                    for i, c in enumerate(counts))
        bits.extend(dict(common, bit=i, ones=int(c), fraction=float(c / len(words)),
                         z_score=float((c - len(words) / 2) / math.sqrt(len(words) / 4)))
                    for i, c in enumerate(ones))
        lags.extend(dict(common, **row) for row in lag_rows)
    for i in range(len(streams)):
        for j in range(i + 1, len(streams)):
            n = min(len(streams[i]), len(streams[j]))
            corr, limit = correlation(streams[i][:n], streams[j][:n]), sigma / math.sqrt(n)
            pairs.append(dict(origin=origin, stream_a=i, stream_b=j, words=n,
                              correlation=corr, screen_limit=limit,
                              screening_pass=bool(math.isfinite(corr) and abs(corr) <= limit)))
    passed = all(row["screening_pass"] for row in summaries + pairs)
    tables = dict(summary=summaries, histogram=hist, bits=bits, lags=lags)
    if pairs:
        tables["cross_stream"] = pairs
    for suffix, rows in tables.items():
        write_csv(artifact_path(prefix, f"_{suffix}.csv"), rows)
    sources = ["model/rng_quality.py", "model/rng_lane.py", "model/price_study.py",
               "model/rng_canonical_reference.py", "rtl/mc_pkg.sv", "rtl/rng_lane.sv"]
    hashes = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in sources}
    try:
        revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT,
                                           text=True, stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.CalledProcessError):
        revision = "unavailable"
    metadata = dict(origin=origin, git_revision=revision, source_sha256=hashes,
                    seed_order="packed {s3,s2,s1,s0}; root then successive canonical 2^64 jumps",
                    seeds=[f"{pack_state(seed):032x}" for seed in seeds],
                    words_per_stream=[len(w) for w in streams], addr_bits=addr_bits,
                    lags=list(LAGS), sigma=sigma, screening_pass=passed,
                    interpretation="Heuristic screens; no calibrated p-values or independence "
                    "proof. Model results are not RTL measurements.",
                    input_sha256={str(p): hashlib.sha256(Path(p).read_bytes()).hexdigest()
                                  for p in input_paths})
    artifact_path(prefix, "_manifest.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    if plot:
        plot_study(prefix, hist, bits, lags, summaries)
    for row in summaries:
        print(f"stream {row['stream']}: n={row['words']} mean_z={row['mean_z']:.3f} "
              f"max_bit_z={row['max_abs_bit_z']:.3f} chi2={row['chi2']:.2f} "
              f"screen={'PASS' if row['screening_pass'] else 'FAIL'}")
    print(f"{origin}: {'PASS' if passed else 'FAIL'} RNG screening; outputs: {prefix}_*")
    return passed


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--words", type=int, default=1 << 20)
    p.add_argument("--streams", type=int, default=3)
    p.add_argument("--root", type=lambda s: int(s, 0), default=DEFAULT_ROOT)
    p.add_argument("--addr-bits", type=int, default=10)
    p.add_argument("--sigma", type=float, default=6)
    p.add_argument("--stream", action="append", type=Path, default=[],
                   help="one canonical hex stream file per jump-separated seed")
    p.add_argument("--out-prefix", type=Path, default=ROOT / "results/rng_model")
    p.add_argument("--plot", action="store_true")
    a = p.parse_args()
    if not 1 <= a.addr_bits <= 16 or a.words < max(17, 20 * (1 << a.addr_bits)):
        p.error("need at least 20 samples per histogram bin and more than 16 words")
    if a.streams < 1 or not 0 < a.root < 2**128:
        p.error("need positive streams and a nonzero 128-bit root seed")
    if not math.isfinite(a.sigma) or a.sigma <= 0:
        p.error("--sigma must be finite and positive")
    if a.stream and len(a.stream) != a.streams:
        p.error("--stream count must equal --streams")
    seeds = lane_seeds(unpack_state(a.root), a.streams)
    if a.stream:
        streams = [read_stream(path, a.words, seed) for path, seed in zip(a.stream, seeds)]
        origin = "imported_hex_canonical_checked"
    else:
        streams, origin = [model_stream(seed, a.words) for seed in seeds], "python_model"
    return 0 if run_study(streams, seeds, origin, a.out_prefix, a.addr_bits,
                          a.sigma, a.plot, a.stream) else 1


if __name__ == "__main__":
    raise SystemExit(main())
