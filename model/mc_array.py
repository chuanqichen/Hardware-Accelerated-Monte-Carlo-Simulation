"""Host seed delivery and golden aggregation for the 1/2/4-lane top.

Total N is interleaved across lanes, lowest lane first on a partial last beat.
Each stream is separated by the canonical 2^64 jump. Pricing stays in mc_lane.
"""
from mc_lane import LaneConfig, run_lane
from price_study import lane_seeds
from rng_lane import pack_state, unpack_state


def array_seeds(root, lanes):
    if lanes not in (1, 2, 4):
        raise ValueError("lanes must be 1, 2, or 4")
    state = unpack_state(root) if isinstance(root, int) else tuple(root)
    if not any(state):
        raise ValueError("all-zero root seed")
    return [pack_state(s) for s in lane_seeds(state, lanes)]


def run_array(a, b, k, root, n_trials, lanes, cfg=LaneConfig()):
    if not isinstance(n_trials, int) or not 1 <= n_trials <= 0xffffffff:
        raise ValueError("n_trials must be a nonzero uint32")
    seeds = array_seeds(root, lanes)
    result = dict(payoff_sum=0, trial_count=0, sat_x=False, sat_s=False, acc_overflow=False)
    for lane, seed in enumerate(seeds):
        n = (n_trials + lanes - 1 - lane) // lanes
        if n == 0:
            continue
        part = run_lane(a, b, k, seed, n, cfg)
        result["payoff_sum"] += part["payoff_sum"]
        result["trial_count"] += part["trial_count"]
        for flag in ("sat_x", "sat_s", "acc_overflow"):
            result[flag] |= part[flag]
    result["acc_overflow"] |= result["payoff_sum"] >= 1 << 64
    result["payoff_sum"] &= (1 << 64) - 1
    return result
