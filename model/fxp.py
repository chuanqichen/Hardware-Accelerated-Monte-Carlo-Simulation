"""Fixed-point helpers shared by the bit-accurate Python reference.

Convention: a value is stored as a Python int / numpy int64 holding the raw
two's-complement word. `Fxp(width, frac)` describes the format; there is one
rounding policy (round-half-to-even) and one saturation policy, used everywhere
a wider quantity is narrowed. Silent truncation is not allowed in the model so
that it cannot be allowed in the RTL either.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class Fxp:
    width: int
    frac: int
    signed: bool = True

    @property
    def int_bits(self) -> int:
        return self.width - self.frac - (1 if self.signed else 0)

    @property
    def scale(self) -> int:
        return 1 << self.frac

    @property
    def min_raw(self) -> int:
        return -(1 << (self.width - 1)) if self.signed else 0

    @property
    def max_raw(self) -> int:
        return (1 << (self.width - 1)) - 1 if self.signed else (1 << self.width) - 1

    @property
    def lsb(self) -> float:
        return 1.0 / self.scale

    def __str__(self) -> str:
        s = "Q" if self.signed else "UQ"
        return f"{s}{self.int_bits}.{self.frac} ({self.width}b)"

    def quantize(self, x, saturate: bool = True):
        """Real -> raw int word. Round-half-to-even, then saturate."""
        raw = np.rint(np.asarray(x, dtype=np.float64) * self.scale).astype(np.int64)
        if saturate:
            raw = np.clip(raw, self.min_raw, self.max_raw)
        else:
            bad = (raw < self.min_raw) | (raw > self.max_raw)
            if np.any(bad):
                raise OverflowError(f"{np.count_nonzero(bad)} value(s) overflow {self}")
        return raw

    def to_real(self, raw):
        return np.asarray(raw, dtype=np.int64) / self.scale

    def to_hex(self, raw: int) -> str:
        return format(int(raw) & ((1 << self.width) - 1), f"0{(self.width + 3) // 4}x")

    def check(self, raw) -> None:
        raw = np.asarray(raw, dtype=np.int64)
        if raw.min() < self.min_raw or raw.max() > self.max_raw:
            raise OverflowError(f"raw word outside {self}")

    def saturate(self, raw):
        """Clamp a wider raw int to this format. Returns (raw, saturated_flag)."""
        raw = np.asarray(raw, dtype=np.int64)
        sat = (raw < self.min_raw) | (raw > self.max_raw)
        return np.clip(raw, self.min_raw, self.max_raw), sat


def round_shift_even(x, shift: int):
    """Raw int -> raw int with `shift` fewer fraction bits, round-half-to-even.

    This is the integer narrowing step (the RTL's round_sat before the saturate):
    keep x >> shift and add 1 when the dropped bits are above half, or exactly
    half and the kept LSB is odd. `>>` floors, so negative values work too.
    """
    x = np.asarray(x, dtype=np.int64)
    if shift == 0:
        return x
    q = x >> shift
    rem = x - (q << shift)
    half = 1 << (shift - 1)
    up = (rem > half) | ((rem == half) & ((q & 1) == 1))
    return q + up.astype(np.int64)
