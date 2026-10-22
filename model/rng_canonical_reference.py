"""Independent test oracle: literal sequential canonical next() transcription.

Source: David Blackman / Sebastiano Vigna, xoshiro128++ 1.0 (2019),
https://prng.di.unimi.it/xoshiro128plusplus.c, next() and rotl().
The original code is dedicated to the public domain (CC0).
This oracle intentionally imports no production RNG helpers and uses ctypes
uint32_t-like conversions at the C assignment/argument boundaries. It models
only the algorithm, not lane control. A compiled C comparison is not implied.
"""
from ctypes import c_uint32


def canonical_next(state):
    s = [c_uint32(word).value for word in state]

    def rotl(x, k):
        x = c_uint32(x).value
        return c_uint32((x << k) | (x >> (32 - k))).value

    result = c_uint32(rotl(s[0] + s[3], 7) + s[0]).value
    t = c_uint32(s[1] << 9).value
    s[2] ^= s[0]
    s[3] ^= s[1]
    s[1] ^= s[2]
    s[0] ^= s[3]
    s[2] ^= t
    s[3] = rotl(s[3], 11)
    return result, tuple(s)
