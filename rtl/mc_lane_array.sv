// Production 1/2/4-lane adapter. Host loads root/jump-separated seeds through
// mc_top's existing per-lane registers. Lane zero hierarchy stays stable.
module mc_lane_array #(
  parameter int LANES = 1,
  parameter int GAUSS_LATENCY = 1,
  parameter int MUL_STAGES = 1,
  parameter int GAUSS_ADDR_BITS = 10,   // gauss_lut table: configs D/A/E = 8/10/12
  parameter int EXP_ADDR_BITS = 10      // exp2_unit 2^f table
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
  logic [LANES-1:0] lane_valid, lane_sx, lane_ss;
  logic [LANES-1:0][S_W-1:0] lane_p;

  // Clear flushes downstream valid bits. RNG uses rst_n so that its seed_load
  // on the same LOAD edge is accepted rather than suppressed by reset priority.
  assign pipeline_rst_n = rst_n && !clear_accum;
  rng_lane u_rng (
    .clk, .rst_n, .seed_load, .seed_state(seed_state[0]), .run(run_mask[0]), .u, .u_valid
  );
  gauss_lut #(.ADDR_BITS(GAUSS_ADDR_BITS), .OUT_WIDTH(Z_W), .FRAC_BITS(Z_F), .LATENCY(GAUSS_LATENCY)) u_gauss (
    .clk, .rst_n(pipeline_rst_n), .in_valid(u_valid), .u, .out_valid(z_valid), .z
  );
  price_dp #(.EXP_ADDR_BITS(EXP_ADDR_BITS), .MUL_STAGES(MUL_STAGES)) u_price (
    .clk, .rst_n(pipeline_rst_n), .a, .b, .k, .z_valid, .z, .p_valid, .p, .sat_x(sx), .sat_s(ss)
  );
  assign lane_valid[0] = p_valid;
  assign lane_p[0] = p;
  assign lane_sx[0] = sx;
  assign lane_ss[0] = ss;
  for (genvar lane = 1; lane < LANES; lane++) begin : g_lane
    logic [U_W-1:0] lane_u;
    logic lane_u_valid, lane_z_valid;
    logic signed [Z_W-1:0] lane_z;
    rng_lane u_rng (
      .clk, .rst_n, .seed_load, .seed_state(seed_state[lane]), .run(run_mask[lane]),
      .u(lane_u), .u_valid(lane_u_valid)
    );
    gauss_lut #(.ADDR_BITS(GAUSS_ADDR_BITS), .OUT_WIDTH(Z_W), .FRAC_BITS(Z_F), .LATENCY(GAUSS_LATENCY)) u_gauss (
      .clk, .rst_n(pipeline_rst_n), .in_valid(lane_u_valid), .u(lane_u),
      .out_valid(lane_z_valid), .z(lane_z)
    );
    price_dp #(.EXP_ADDR_BITS(EXP_ADDR_BITS), .MUL_STAGES(MUL_STAGES)) u_price (
      .clk, .rst_n(pipeline_rst_n), .a, .b, .k, .z_valid(lane_z_valid), .z(lane_z),
      .p_valid(lane_valid[lane]), .p(lane_p[lane]), .sat_x(lane_sx[lane]), .sat_s(lane_ss[lane])
    );
  end
  accumulator #(.LANES(LANES), .P_WIDTH(S_W), .SUM_WIDTH(SUM_W), .CNT_WIDTH(CNT_W),
                .REGISTER_TREE(LANES > 1)) u_accumulator (
    .clk, .rst_n, .clear(clear_accum), .p_valid(lane_valid), .p(lane_p), .sat_x(lane_sx), .sat_s(lane_ss),
    .payoff_sum, .trial_count, .acc_overflow, .sat_x_seen(sat_x), .sat_s_seen(sat_s)
  );

  if (LANES != 1 && LANES != 2 && LANES != 4)
    initial $fatal(1, "LANES must be 1, 2, or 4");
  if (GAUSS_LATENCY != 1 && GAUSS_LATENCY != 2)
    initial $fatal(1, "GAUSS_LATENCY must be 1 or 2");
  if (MUL_STAGES != 1 && MUL_STAGES != 2)
    initial $fatal(1, "MUL_STAGES must be 1 or 2");
  // The ROM modules are generated for one table size each; the instance parameter
  // must match the generated file in the compile list (make gen ADDR_BITS=.. /
  // make gen-price EXP_ADDR_BITS=.., or the per-config directories of run_sweep.sh).
  if (GAUSS_ADDR_BITS < 6 || GAUSS_ADDR_BITS > 12)
    initial $fatal(1, "GAUSS_ADDR_BITS must be 6..12 and match rtl/generated/gauss_lut_rom.sv");
  if (EXP_ADDR_BITS < 6 || EXP_ADDR_BITS > 12)
    initial $fatal(1, "EXP_ADDR_BITS must be 6..12 and match rtl/generated/exp2_rom.sv");
endmodule
