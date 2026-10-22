// accumulator: payoff sum, trial count and sticky status flags for LANES lanes.
//
// Bit-accurate reference: model/price_dp.py accumulate().
//
//   clear            -> everything to 0 (has priority over a same-cycle add)
//   any p_valid      -> payoff_sum  += sum of the valid lanes' p
//                       trial_count += popcount(p_valid)   (last beat may be masked)
//                       acc_overflow |= carry out of payoff_sum
//                       sat_*_seen   |= any valid lane's sat_* pulse
//
// Latency LAT_ACC = 1 (the result registers themselves). The lane sum is
// combinational here; for LANES > 1 a registered adder tree goes in front
// (Week 5) and adds ceil(log2 LANES) cycles. Registers load only on a valid
// beat, so DC can clock-gate them when no trial arrives.
// With p <= 2^22 and at most 2^32 trials the 64-bit sum cannot overflow; the
// flag is kept for the contract and is exercised with SUM_WIDTH = 32 in test.
module accumulator #(
  parameter int LANES     = 1,
  parameter int P_WIDTH   = 22,
  parameter int SUM_WIDTH = 64,
  parameter int CNT_WIDTH = 32
) (
  input  logic                              clk,
  input  logic                              rst_n,
  input  logic                              clear,
  input  logic [LANES-1:0]                  p_valid,
  input  logic [LANES-1:0][P_WIDTH-1:0]     p,
  input  logic [LANES-1:0]                  sat_x,
  input  logic [LANES-1:0]                  sat_s,
  output logic [SUM_WIDTH-1:0]              payoff_sum,
  output logic [CNT_WIDTH-1:0]              trial_count,
  output logic                              acc_overflow,
  output logic                              sat_x_seen,
  output logic                              sat_s_seen
);
  localparam int LAT_ACC = 1;
  localparam int LS_W    = P_WIDTH + $clog2(LANES + 1);

  logic [LS_W-1:0]          lane_sum;
  logic [$clog2(LANES+1)-1:0] n_valid;
  logic                     any_sx, any_ss;
  logic [SUM_WIDTH:0]       sum_next;   // one extra bit = carry out

  always_comb begin
    lane_sum = '0;
    n_valid  = '0;
    any_sx   = 1'b0;
    any_ss   = 1'b0;
    for (int i = 0; i < LANES; i++) begin
      if (p_valid[i]) begin
        lane_sum = lane_sum + LS_W'(p[i]);
        n_valid  = n_valid + 1'b1;
        any_sx   = any_sx | sat_x[i];
        any_ss   = any_ss | sat_s[i];
      end
    end
    sum_next = {1'b0, payoff_sum} + (SUM_WIDTH+1)'(lane_sum);
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      payoff_sum   <= '0;
      trial_count  <= '0;
      acc_overflow <= 1'b0;
      sat_x_seen   <= 1'b0;
      sat_s_seen   <= 1'b0;
    end else if (clear) begin
      payoff_sum   <= '0;
      trial_count  <= '0;
      acc_overflow <= 1'b0;
      sat_x_seen   <= 1'b0;
      sat_s_seen   <= 1'b0;
    end else if (|p_valid) begin
      payoff_sum   <= sum_next[SUM_WIDTH-1:0];
      trial_count  <= trial_count + CNT_WIDTH'(n_valid);
      acc_overflow <= acc_overflow | sum_next[SUM_WIDTH];
      sat_x_seen   <= sat_x_seen | any_sx;
      sat_s_seen   <= sat_s_seen | any_ss;
    end
  end
endmodule
