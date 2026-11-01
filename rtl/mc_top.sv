// Integrated one-lane pricer. Compile mc_pkg first and use the production
// mc_lane_array; the separate control-only target selects tb/mocks instead.
// Configuration concurrency rules remain candidates for team signoff.
module mc_top #(
  parameter int LANES = 1,
  parameter int GAUSS_LATENCY = 1,
  parameter int MUL_STAGES = 1
) (
  input  logic clk,
  input  logic rst_n,
  input  logic cfg_we,
  input  logic [7:0] cfg_addr,
  input  logic [31:0] cfg_wdata,
  input  logic start,
  output logic busy,
  output logic done,
  output logic [63:0] payoff_sum,
  output logic [31:0] trial_count,
  output logic [31:0] cycle_count,
  output logic [7:0] status
);
  import mc_pkg::*;

  logic core_rst_n;
  logic signed [17:0] cfg_a, active_a;
  logic [15:0] cfg_b, active_b;
  logic [21:0] cfg_k, active_k;
  logic [31:0] cfg_trials;
  logic [LANES-1:0][127:0] cfg_seeds, active_seeds;
  logic cfg_ok, accept_start, write_ok;
  logic [7:0] status_q;
  logic clear_accum, seed_load;
  logic [LANES-1:0] run_mask;
  logic sat_x, sat_s, acc_overflow;

  rst_sync #(.STAGES(2)) u_reset (.clk, .rst_in_n(rst_n), .rst_sync_n(core_rst_n));

  always_comb begin
    cfg_ok = cfg_trials != 0;
    for (int lane = 0; lane < LANES; lane++)
      if (cfg_seeds[lane] == 0) cfg_ok = 1'b0;
    // Draft clarification: simultaneous cfg_we/start is rejected, not reordered.
    cfg_ok = cfg_ok && !cfg_we;
    write_ok = 1'b0;
    case (cfg_addr)
      REG_A: write_ok = cfg_wdata[31:18] == 0;
      REG_B: write_ok = cfg_wdata[31:16] == 0;
      REG_K: write_ok = cfg_wdata[31:22] == 0;
      REG_N_TRIALS: write_ok = 1'b1;
      default: begin
        for (int lane = 0; lane < LANES; lane++)
          for (int word_index = 0; word_index < 4; word_index++)
            if (cfg_addr == reg_seed(lane, word_index)) write_ok = 1'b1;
      end
    endcase
  end
  assign accept_start = start && !busy && cfg_ok;
  assign status = status_q | (done ? (8'b1 << ST_DONE) : 8'h00);

  always_ff @(posedge clk or negedge core_rst_n) begin
    if (!core_rst_n) begin
      cfg_a <= '0; cfg_b <= '0; cfg_k <= '0; cfg_trials <= '0;
      cfg_seeds <= '0;
      active_a <= '0; active_b <= '0; active_k <= '0; active_seeds <= '0;
      status_q <= '0;
    end else begin
      if (accept_start) begin
        active_a <= cfg_a; active_b <= cfg_b; active_k <= cfg_k;
        active_seeds <= cfg_seeds;
        status_q <= '0;
      end else begin
        if (done) status_q[ST_DONE] <= 1'b1;
        // The accumulator still holds the prior run flags before the LOAD clear edge.
        if (busy && !clear_accum) begin
          if (sat_x) status_q[ST_SAT_X] <= 1'b1;
          if (sat_s) status_q[ST_SAT_S] <= 1'b1;
          if (acc_overflow) status_q[ST_ACC_OVF] <= 1'b1;
        end
        if ((cfg_we && (busy || !write_ok)) || (start && !busy && !cfg_ok))
          status_q[ST_BAD_CFG] <= 1'b1;
      end
      if (cfg_we && !busy && write_ok) begin
        case (cfg_addr)
          REG_A: cfg_a <= $signed(cfg_wdata[17:0]);
          REG_B: cfg_b <= cfg_wdata[15:0];
          REG_K: cfg_k <= cfg_wdata[21:0];
          REG_N_TRIALS: cfg_trials <= cfg_wdata;
          default: begin
            for (int lane = 0; lane < LANES; lane++)
              for (int word_index = 0; word_index < 4; word_index++)
                if (cfg_addr == reg_seed(lane, word_index))
                  cfg_seeds[lane][32*word_index +: 32] <= cfg_wdata;
          end
        endcase
      end
    end
  end

  mc_controller #(.LANES(LANES)) u_controller (
    .clk, .rst_n(core_rst_n), .start, .cfg_ok, .n_trials(cfg_trials),
    .trial_count, .busy, .done, .clear_accum, .seed_load, .run_mask, .cycle_count
  );

  // Eric owns accumulation; this boundary returns registered totals and sticky flags.
  mc_lane_array #(.LANES(LANES), .GAUSS_LATENCY(GAUSS_LATENCY), .MUL_STAGES(MUL_STAGES)) u_lanes (
    .clk, .rst_n(core_rst_n), .clear_accum, .seed_load, .run_mask,
    .seed_state(active_seeds), .a(active_a), .b(active_b), .k(active_k),
    .payoff_sum, .trial_count, .sat_x, .sat_s, .acc_overflow
  );
endmodule
