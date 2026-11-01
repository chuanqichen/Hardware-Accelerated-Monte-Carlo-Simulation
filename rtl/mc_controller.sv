// Control only. trial_count comes from Eric's registered accumulator.
// LOAD clears the backend and loads seeds before any ISSUE edge.
module mc_controller #(
  parameter int LANES = 1
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic cfg_ok,
  input  logic [31:0] n_trials,
  input  logic [31:0] trial_count,
  output logic busy,
  output logic done,
  output logic clear_accum,
  output logic seed_load,
  output logic [LANES-1:0] run_mask,
  output logic [31:0] cycle_count
);
  typedef enum logic [1:0] {IDLE, LOAD, ISSUE, DRAIN} state_t;
  state_t state;
  logic [31:0] target_trials;
  logic [32:0] issued, remaining, issue_count;

  assign busy = state != IDLE;
  assign clear_accum = state == LOAD;
  assign seed_load = state == LOAD;
  assign remaining = {1'b0, target_trials} - issued;

  always_comb begin
    run_mask = '0;
    issue_count = '0;
    for (int lane = 0; lane < LANES; lane++) begin
      if ((state == ISSUE) && ($unsigned(33'(lane)) < remaining)) begin
        run_mask[lane] = 1'b1;
        issue_count = issue_count + 33'd1;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      target_trials <= '0;
      issued <= '0;
      done <= 1'b0;
      cycle_count <= '0;
    end else begin
      done <= 1'b0;
      if (busy) cycle_count <= cycle_count + 32'd1;
      case (state)
        IDLE: if (start && cfg_ok && (n_trials != 0)) begin
          target_trials <= n_trials;
          issued <= '0;
          cycle_count <= 32'd1; // Includes the accepting start edge.
          state <= LOAD;
        end
        LOAD: state <= ISSUE;
        ISSUE: begin
          issued <= issued + issue_count;
          if (issued + issue_count == {1'b0, target_trials}) state <= DRAIN;
        end
        DRAIN: if (trial_count == target_trials) begin
          state <= IDLE;
          done <= 1'b1;
        end
        default: state <= IDLE;
      endcase
    end
  end

`ifndef SYNTHESIS
  initial begin
    a_supported_lanes: assert (LANES == 1 || LANES == 2 || LANES == 4)
      else $fatal(1, "LANES must be 1, 2, or 4");
  end
  always @(posedge clk) if (rst_n && busy) begin
    a_issued_bound: assert (issued <= {1'b0, target_trials}) else $fatal(1, "over-issued trials");
    // LOAD still exposes the previous run's result until the clear edge.
    if (state == ISSUE || state == DRAIN)
      a_completed_bound: assert (trial_count <= target_trials) else $fatal(1, "extra backend trials");
  end
`endif
endmodule
