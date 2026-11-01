// TEST ONLY. Constant artificial payoffs, no RNG/Gaussian/exp or pricing model.
// Never include this file in a synthesis or production source list.
module mc_lane_array #(
  parameter int LANES = 1,
  parameter int GAUSS_LATENCY = 1,
  parameter int MUL_STAGES = 1,
  parameter int TEST_LATENCY = 3
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
  logic [LANES-1:0] pipe [TEST_LATENCY];
  logic inject_sat_x = 0, inject_sat_s = 0, inject_overflow = 0;
  logic [63:0] beat_payoff;
  logic [31:0] beat_count;
  assign sat_x = inject_sat_x;
  assign sat_s = inject_sat_s;
  assign acc_overflow = inject_overflow;

  always_comb begin
    beat_count = '0;
    beat_payoff = '0;
    for (int lane = 0; lane < LANES; lane++) if (pipe[TEST_LATENCY-1][lane]) begin
      beat_count = beat_count + 32'd1;
      beat_payoff = beat_payoff + 64'(lane+1)*64'd256;
    end
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int stage = 0; stage < TEST_LATENCY; stage++) pipe[stage] <= '0;
      trial_count <= '0;
      payoff_sum <= '0;
    end else if (clear_accum) begin
      for (int stage = 0; stage < TEST_LATENCY; stage++) pipe[stage] <= '0;
      trial_count <= '0;
      payoff_sum <= '0;
    end else begin
      pipe[0] <= run_mask;
      for (int stage = 1; stage < TEST_LATENCY; stage++) pipe[stage] <= pipe[stage-1];
      trial_count <= trial_count + beat_count;
      payoff_sum <= payoff_sum + beat_payoff;
    end
  end
  always @(posedge clk) if (rst_n) begin
    if (seed_load && |run_mask) $fatal(1, "seed_load overlaps run");
    if (seed_load) begin
      for (int lane = 0; lane < LANES; lane++)
        if (seed_state[lane] == 0) $fatal(1, "zero active seed");
      if ($isunknown({a,b,k})) $fatal(1, "unknown active configuration");
    end
  end
endmodule
