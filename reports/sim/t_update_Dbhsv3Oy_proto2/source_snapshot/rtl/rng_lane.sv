// xoshiro128++ 1.0: https://prng.di.unimi.it/xoshiro128plusplus.c
// One registered output/state update per accepted run edge, modulo 2^32.
// Proposed control policy: reset > seed_load > run > hold. No back-pressure.
// Zero seed/reset leave the lane inactive; controller must flag bad_cfg.
module rng_lane (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         seed_load,
  input  logic [127:0] seed_state,  // {s3,s2,s1,s0}
  input  logic         run,
  output logic [31:0]  u,
  output logic         u_valid
);
  // Export the shared latency contract for block-level users.
  /* verilator lint_off UNUSEDPARAM */
  localparam int LAT_RNG = mc_pkg::LAT_RNG;
  /* verilator lint_on UNUSEDPARAM */
  logic [31:0] s0, s1, s2, s3;
  logic [31:0] t, xor31, xor20, shifted1;
  logic [31:0] s0_next, s3_next;
  logic [31:0] result;
  logic [31:0] t_seed_sum, t_next_sum;

  // Four 8-bit carry-select blocks, with modulo-2^32 overflow discarded.
  // Unlike the 32-bit seed addition, this has no full-width '+' operation
  // for DC to share ahead of the run-dependent register enable.
  function automatic logic [31:0] add_t_next(
    input logic [31:0] a, b
  );
    logic [8:0] sum_zero, sum_one, selected;
    logic [31:0] sum;
    logic carry;
    sum_zero = {1'b0, a[7:0]} + {1'b0, b[7:0]};
    sum[7:0] = sum_zero[7:0];
    carry = sum_zero[8];
    for (int block_index = 1; block_index < 4; block_index++) begin
      sum_zero = {1'b0, a[8*block_index +: 8]} +
                 {1'b0, b[8*block_index +: 8]};
      sum_one = {1'b0, a[8*block_index +: 8]} +
                {1'b0, b[8*block_index +: 8]} + 9'd1;
      selected = carry ? sum_one : sum_zero;
      sum[8*block_index +: 8] = selected[7:0];
      carry = selected[8];
    end
    return sum;
  endfunction

  // Every intermediate is a 32-bit unsigned word: intentional wrap, no sat.
  // Look-ahead invariant: t == (s0 + s3) mod 2^32 for the CURRENT state.
  // This removes one serial adder from the output path without another stage.
  assign result   = {t[24:0], t[31:25]} + s0;
  assign s0_next  = s0 ^ xor31;
  assign s3_next  = {xor31[20:0], xor31[31:21]};
  assign xor31    = s3 ^ s1;
  assign xor20    = s2 ^ s0;
  assign shifted1 = s1 << 9;
  // Both arithmetic cones are independent of run and seed_load in the RTL.
  // Control selects the completed sum at the t register; mapping must be checked.
  assign t_seed_sum = seed_state[31:0] + seed_state[127:96];
  assign t_next_sum = add_t_next(s0_next, s3_next);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s0 <= '0; s1 <= '0; s2 <= '0; s3 <= '0;
      t <= '0;
      u <= '0;
      u_valid <= 1'b0;
    end else if (seed_load) begin
      s0 <= seed_state[31:0];
      s1 <= seed_state[63:32];
      s2 <= seed_state[95:64];
      s3 <= seed_state[127:96];
      t <= t_seed_sum;
      u <= '0;
      u_valid <= 1'b0;
    end else if (run && (|{s3, s2, s1, s0})) begin
      u <= result;                   // output computed from OLD state
      t <= t_next_sum;
      s0 <= s0_next;
      s1 <= s1 ^ xor20;
      s2 <= xor20 ^ shifted1;
      s3 <= s3_next;                 // rotl(...,11)
      u_valid <= 1'b1;
    end else begin
      // Pause/unseeded: retain state, t and u, insert a valid bubble.
      u_valid <= 1'b0;
    end
  end
endmodule
