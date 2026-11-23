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
// Latency LAT_ACC = 1 (the result registers themselves). REGISTER_TREE adds
// ceil(log2 LANES) registered reduction stages for power-of-two lane counts.
// Its sum, population count and qualified flags travel together. Default zero
// preserves the standalone block's original combinational reduction. The result
// registers load only when a reduced beat is valid.
// With p <= 2^22 and at most 2^32 trials the 64-bit sum cannot overflow; the
// flag is kept for the contract and is exercised with SUM_WIDTH = 32 in test.
module accumulator #(
  parameter int LANES     = 1,
  parameter int P_WIDTH   = 22,
  parameter int SUM_WIDTH = 64,
  parameter int CNT_WIDTH = 32,
  parameter bit REGISTER_TREE = 0
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

  if (REGISTER_TREE && LANES > 1) begin : g_tree
    localparam int LEVELS = $clog2(LANES);
    localparam int COUNT_W = $clog2(LANES+1);
    wire [LS_W-1:0] sums [0:LEVELS][0:LANES-1];
    wire [COUNT_W-1:0] counts [0:LEVELS][0:LANES-1];
    wire sx [0:LEVELS][0:LANES-1];
    wire ss [0:LEVELS][0:LANES-1];
    for (genvar lane = 0; lane < LANES; lane++) begin : g_leaf
      assign sums[0][lane] = p_valid[lane] ? LS_W'(p[lane]) : '0;
      assign counts[0][lane] = COUNT_W'(p_valid[lane]);
      assign sx[0][lane] = p_valid[lane] && sat_x[lane];
      assign ss[0][lane] = p_valid[lane] && sat_s[lane];
    end
    for (genvar level = 1; level <= LEVELS; level++) begin : g_level
      for (genvar node = 0; node < (LANES >> level); node++) begin : g_node
        logic [LS_W-1:0] sum_q;
        logic [COUNT_W-1:0] count_q;
        logic sx_q, ss_q;
        always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            sum_q <= '0; count_q <= '0; sx_q <= 0; ss_q <= 0;
          end else if (clear) begin
            sum_q <= '0; count_q <= '0; sx_q <= 0; ss_q <= 0;
          end else begin
            sum_q <= sums[level-1][2*node] + sums[level-1][2*node+1];
            count_q <= counts[level-1][2*node] + counts[level-1][2*node+1];
            sx_q <= sx[level-1][2*node] | sx[level-1][2*node+1];
            ss_q <= ss[level-1][2*node] | ss[level-1][2*node+1];
          end
        end
        assign sums[level][node] = sum_q;
        assign counts[level][node] = count_q;
        assign sx[level][node] = sx_q;
        assign ss[level][node] = ss_q;
      end
    end
    assign lane_sum = sums[LEVELS][0];
    assign n_valid = counts[LEVELS][0];
    assign any_sx = sx[LEVELS][0];
    assign any_ss = ss[LEVELS][0];
    if ((LANES & (LANES-1)) != 0)
      initial $fatal(1, "REGISTER_TREE requires power-of-two LANES");
  end else begin : g_comb
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
    end
  end
  assign sum_next = {1'b0, payoff_sum} + (SUM_WIDTH+1)'(lane_sum);

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
    end else if (n_valid != 0) begin
      payoff_sum   <= sum_next[SUM_WIDTH-1:0];
      trial_count  <= trial_count + CNT_WIDTH'(n_valid);
      acc_overflow <= acc_overflow | sum_next[SUM_WIDTH];
      sat_x_seen   <= sat_x_seen | any_sx;
      sat_s_seen   <= sat_s_seen | any_ss;
    end
  end
endmodule
