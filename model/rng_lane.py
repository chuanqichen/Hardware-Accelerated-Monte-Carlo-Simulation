"""Bit-accurate xoshiro128++ 1.0 and the one-stage lane control model.

Algorithm: https://prng.di.unimi.it/xoshiro128plusplus.c (Blackman/Vigna).
State tuples are (s0, s1, s2, s3); packed seed_state is {s3,s2,s1,s0}.
Unsigned arithmetic wraps modulo 2**32, never fixed-point saturates.
"""
from dataclasses import dataclass
from operator import index

MASK32 = (1 << 32) - 1
LAT_RNG = 1
ZERO_STATE = (0, 0, 0, 0)


def _unsigned(value, bits):
    value = index(value)
    if not 0 <= value < (1 << bits):
        raise ValueError(f"expected unsigned {bits}-bit integer")
    return value


def normalize_state(state):
    words = tuple(state)
    if len(words) != 4:
        raise ValueError("state needs four words in (s0,s1,s2,s3) order")
    return tuple(_unsigned(word, 32) for word in words)


def pack_state(state):
    """Return the 128-bit seed bus {s3,s2,s1,s0}."""
    return sum(word << (32 * i) for i, word in enumerate(normalize_state(state)))


def unpack_state(seed_state):
    seed_state = _unsigned(seed_state, 128)
    return tuple((seed_state >> (32 * i)) & MASK32 for i in range(4))


def _rotl32(word, shift):
    return ((word << shift) | (word >> (32 - shift))) & MASK32


def next_word(state):
    """Pure canonical step: (output, next_state), including the zero fixed point.

    Zero is accepted here for algorithm testing; it is illegal as a stream seed.
    The lane wrapper inhibits output until a nonzero seed is loaded.
    """
    s0, s1, s2, s3 = normalize_state(state)
    result = (_rotl32((s0 + s3) & MASK32, 7) + s0) & MASK32
    # Simultaneous equations derived from the canonical sequential XOR updates.
    next_state = (s0 ^ s3 ^ s1, s1 ^ s2 ^ s0,
                  s2 ^ s0 ^ ((s1 << 9) & MASK32), _rotl32(s3 ^ s1, 11))
    return result, next_state


@dataclass
class RngLane:
    """State immediately after a clock edge; reset > load > run > hold.

    reset() also models asynchronous assertion between edges. Reset and zero
    seed load clear u and inhibit output. Pause holds state/u, with u_valid=0.
    A load consumes an edge without generating or advancing, even if run=1.
    """
    state: tuple = ZERO_STATE
    u: int = 0
    u_valid: bool = False

    def __post_init__(self):
        self.state = normalize_state(self.state)
        self.u = _unsigned(self.u, 32)

    def reset(self):
        self.state, self.u, self.u_valid = ZERO_STATE, 0, False

    def tick(self, *, rst_n=True, seed_load=False, seed_state=0, run=False):
        if not rst_n:
            self.reset()
        elif seed_load:
            self.state = unpack_state(seed_state)
            self.u, self.u_valid = 0, False
        elif run and any(self.state):
            self.u, self.state = next_word(self.state)
            self.u_valid = True
        else:
            self.u_valid = False
        return self.u_valid, self.u
