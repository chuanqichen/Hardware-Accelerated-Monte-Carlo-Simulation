// Production one-lane adapter. Each owner's arithmetic/control remains in its
// original module. No multi-lane reduction or seed-jump policy is claimed here.
module mc_lane_array #(
  parameter int LANES = 1,
  parameter int GAUSS_LATENCY = 1,
  parameter int MUL_STAGES = 1
) (
  input logic clk, rst_n, clear_accum, seed_load,
  input logic [LANES-1:0] run_mask,
  input logic [LANES-1:0][127:0] seed_state,
  input logic signed [17:0] a,
  input logic [15:0] b,
  input logic [21:0] k,
  output logic [63:0] payoff_sum,
  output logic [31:0] trial_count,
  output logic sat_x, sat_s, acc_overflow
);
  import mc_pkg::*;
  logic pipeline_rst_n;
  logic [U_W-1:0] u;
  logic u_valid, z_valid, p_valid, sx, ss;
  logic signed [Z_W-1:0] z;
  logic [S_W-1:0] p;

  // Clear flushes downstream valid bits. RNG uses rst_n so that its seed_load
  // on the same LOAD edge is accepted rather than suppressed by reset priority.
  assign pipeline_rst_n = rst_n && !clear_accum;
  rng_lane u_rng (
    .clk, .rst_n, .seed_load, .seed_state(seed_state[0]), .run(run_mask[0]), .u, .u_valid
  );
  gauss_lut #(.ADDR_BITS(10), .OUT_WIDTH(Z_W), .FRAC_BITS(Z_F), .LATENCY(GAUSS_LATENCY)) u_gauss (
    .clk, .rst_n(pipeline_rst_n), .in_valid(u_valid), .u, .out_valid(z_valid), .z
  );
  price_dp #(.EXP_ADDR_BITS(10), .MUL_STAGES(MUL_STAGES)) u_price (
    .clk, .rst_n(pipeline_rst_n), .a, .b, .k, .z_valid, .z, .p_valid, .p, .sat_x(sx), .sat_s(ss)
  );
  accumulator #(.LANES(1), .P_WIDTH(S_W), .SUM_WIDTH(SUM_W), .CNT_WIDTH(CNT_W)) u_accumulator (
    .clk, .rst_n, .clear(clear_accum), .p_valid(p_valid), .p(p), .sat_x(sx), .sat_s(ss),
    .payoff_sum, .trial_count, .acc_overflow, .sat_x_seen(sat_x), .sat_s_seen(sat_s)
  );

  // Synthesis is also gated to one lane by scripts/syn/config.tcl. The interface
  // retains the array shape so the control-only mock can still test 1/2/4 masks.
  if (LANES != 1) initial $fatal(1, "production mc_lane_array currently supports LANES=1 only");
  if (GAUSS_LATENCY != 1 && GAUSS_LATENCY != 2)
    initial $fatal(1, "GAUSS_LATENCY must be 1 or 2");
  if (MUL_STAGES != 1 && MUL_STAGES != 2)
    initial $fatal(1, "MUL_STAGES must be 1 or 2");
endmodule
