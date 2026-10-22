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
  // Exported latency contract; no shared mc_pkg exists yet.
  /* verilator lint_off UNUSEDPARAM */
  localparam int LAT_RNG = 1;
  /* verilator lint_on UNUSEDPARAM */
  logic [31:0] s0, s1, s2, s3;
  logic [31:0] sum03, xor31, xor20, shifted1;
  logic [31:0] result;

  // Every intermediate is a 32-bit unsigned word: intentional wrap, no sat.
  assign sum03    = s0 + s3;
  assign result   = {sum03[24:0], sum03[31:25]} + s0;
  assign xor31    = s3 ^ s1;
  assign xor20    = s2 ^ s0;
  assign shifted1 = s1 << 9;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s0 <= '0; s1 <= '0; s2 <= '0; s3 <= '0;
      u <= '0;
      u_valid <= 1'b0;
    end else if (seed_load) begin
      s0 <= seed_state[31:0];
      s1 <= seed_state[63:32];
      s2 <= seed_state[95:64];
      s3 <= seed_state[127:96];
      u <= '0;
      u_valid <= 1'b0;
    end else if (run && (|{s3, s2, s1, s0})) begin
      u <= result;                   // output computed from OLD state
      s0 <= s0 ^ xor31;
      s1 <= s1 ^ xor20;
      s2 <= xor20 ^ shifted1;
      s3 <= {xor31[20:0], xor31[31:21]}; // rotl(...,11)
      u_valid <= 1'b1;
    end else begin
      // Pause/unseeded: retain state and u, insert a valid bubble.
      u_valid <= 1'b0;
    end
  end
endmodule
