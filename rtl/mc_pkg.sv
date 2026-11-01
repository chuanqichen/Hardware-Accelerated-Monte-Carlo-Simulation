// mc_pkg: the lane's shared constants. One source of truth for the fixed-point
// formats, block latencies, status-flag bit positions and the configuration
// register map, so that mc_top, the controller, the testbenches and the Python
// reference (model/fxp.py formats) agree without re-typing numbers.
//
// Authoritative definitions: docs/Lane_Interface_Spec.md Sections 3, 4 and 6.
// Nothing here is a tuning knob. Per-experiment parameters (ADDR_BITS,
// EXP_ADDR_BITS, MUL_STAGES, LANES, gauss_lut LATENCY) stay as module parameters
// so one synthesis run per configuration still works; this package records how
// the derived quantities (latencies, widths) depend on them.
//
// Usage:  import mc_pkg::*;   (compile this file first)
package mc_pkg;

  // ---- fixed-point formats (Spec Sec. 3): width, fraction bits -------------------
  // Qi.f = signed, UQi.f = unsigned; i excludes the sign bit.
  localparam int U_W   = 32;                 // u        uint32   uniform word
  localparam int Z_W   = 16, Z_F   = 12;     // z        Q3.12    standard normal
  localparam int A_W   = 18, A_F   = 12;     // A        Q5.12    ln S0 + (r - sigma^2/2) T
  localparam int B_W   = 16, B_F   = 14;     // B        UQ2.14   sigma sqrt(T)
  localparam int ACC_W = 34, ACC_F = 26;     // (A<<14) + B*z   Q5.26  price_dp S1 internal
  localparam int X_W   = 18, X_F   = 12;     // x        Q5.12    exp input
  localparam int S_W   = 22, S_F   = 8;      // S_T, K, p   UQ14.8
  localparam int SUM_W = 64, SUM_F = 8;      // payoff_sum  UQ46.8 (54 bits used)
  localparam int CNT_W = 32;                 // trial_count, cycle_count  uint32
  localparam int SEED_W = 128;               // xoshiro128 state {s3, s2, s1, s0}

  // round_sat instance in price_dp S2: ACC (Q5.26) -> X (Q5.12)
  localparam int X_SHIFT = ACC_F - X_F;      // 14 fraction bits dropped

  // ---- block latencies (Spec Sec. 6, measured 2026-10-31 under VCS) --------------
  // Every block exports LAT_<BLOCK> = cycles from in_valid to out_valid.
  localparam int LAT_RNG = 1;                // rng_lane: registered output
  localparam int LAT_EXP = 3;                // exp2_unit S3-S5 (inside price_dp)
  localparam int LAT_ACC = 1;                // accumulator result registers

  // Blocks whose latency depends on a module parameter record the formula here.
  function automatic int lat_gauss(int latency);          // gauss_lut LATENCY = 1 | 2
    return latency;
  endfunction
  function automatic int lat_dp(int mul_stages);          // price_dp: S1..S6
    return mul_stages + 1 + LAT_EXP + 1;                  // = 6 at MUL_STAGES = 1
  endfunction
  function automatic int lat_tree(int lanes);             // registered adder tree, LANES > 1
    return (lanes > 1) ? $clog2(lanes) : 0;
  endfunction
  // Controller drain bound: cycles from the last issued trial to its p_valid.
  function automatic int lat_total(int gauss_latency, int mul_stages, int lanes);
    return LAT_RNG + lat_gauss(gauss_latency) + lat_dp(mul_stages) + lat_tree(lanes) + LAT_ACC;
  endfunction

  // ---- status[7:0] sticky flags (Spec Sec. 4) --------------------------------------
  localparam int ST_W       = 8;
  localparam int ST_DONE    = 0;             // run finished; cleared on start
  localparam int ST_SAT_X   = 1;             // round_sat saturated x in some trial
  localparam int ST_SAT_S   = 2;             // exp clamped S_T in some trial
  localparam int ST_ACC_OVF = 3;             // payoff_sum carry-out
  localparam int ST_BAD_CFG = 4;             // zero seed, N_TRIALS = 0, write while busy
  // bits 7:5 reserved, read as 0

  // ---- configuration register map (Spec Sec. 4): 32-bit words, right-aligned ------
  localparam int CFG_ADDR_W = 8;
  localparam int CFG_DATA_W = 32;
  localparam logic [CFG_ADDR_W-1:0] REG_A        = 8'h00;   // A        [A_W-1:0]
  localparam logic [CFG_ADDR_W-1:0] REG_B        = 8'h01;   // B        [B_W-1:0]
  localparam logic [CFG_ADDR_W-1:0] REG_K        = 8'h02;   // K        [S_W-1:0]
  localparam logic [CFG_ADDR_W-1:0] REG_N_TRIALS = 8'h03;   // uint32, total across lanes
  localparam logic [CFG_ADDR_W-1:0] REG_SEED_BASE = 8'h10;  // SEED[i][w] at 0x10 + 4*i + w
  function automatic logic [CFG_ADDR_W-1:0] reg_seed(int lane, int word);
    return REG_SEED_BASE + CFG_ADDR_W'(4 * lane + word);
  endfunction

endpackage
