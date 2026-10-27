// price_dp: one trial per cycle, z -> payoff p = max(e^(A + B*z) - K, 0).
//
// Bit-accurate reference: model/price_dp.py price_dp() (per-trial trace has
// acc, x, n, addr, rom, s_t, p for waveform debugging).
//
//   S1  acc = (A <<< 14) + B * z      fused multiply-add, Q5.26, MUL_STAGES registers
//                                     (DC retiming moves them into the multiplier tree)
//   S2  x   = sat(round_even(acc, 14))  Q5.12, one rounding of the whole sum; sat_x
//   S3-S5   S_T = e^x                 exp2_unit (range reduction), UQ14.8; sat_s
//   S6  p   = S_T > K ? S_T - K : 0   UQ14.8, exact
//
// A, B, K are configuration: latched by the controller on start and constant for
// a run, so they are not pipelined. Latency LAT_DP = MUL_STAGES + 5; one result
// per cycle (II = 1). sat_x / sat_s are single-cycle pulses qualified by p_valid;
// the accumulator makes them sticky. Data registers load only on a valid stage.
module price_dp #(
  parameter int EXP_ADDR_BITS = 10,
  parameter int MUL_STAGES    = 1
) (
  input  logic               clk,
  input  logic               rst_n,
  input  logic signed [17:0] a,        // Q5.12
  input  logic        [15:0] b,        // UQ2.14
  input  logic        [21:0] k,        // UQ14.8
  input  logic               z_valid,
  input  logic signed [15:0] z,        // Q3.12
  output logic               p_valid,
  output logic        [21:0] p,        // UQ14.8
  output logic               sat_x,
  output logic               sat_s
);
  localparam int LAT_EXP = 3;
  localparam int LAT_DP  = MUL_STAGES + 1 + LAT_EXP + 1;
  localparam logic signed [19:0] X_MAX = 20'sd131071;    // 2^17 - 1
  localparam logic signed [19:0] X_MIN = -20'sd131072;   // -2^17

  // ---- S1: fused multiply-add ---------------------------------------------------
  // A's binary point (12 fraction bits) is moved to the product's (26) by << 14.
  logic signed [33:0] mac;
  assign mac = $signed({{2{a[17]}}, a, 14'b0}) + $signed({1'b0, b}) * z;

  logic signed [33:0] acc_r [MUL_STAGES];
  logic               v_mul [MUL_STAGES];
  always_ff @(posedge clk) if (z_valid) acc_r[0] <= mac;
  for (genvar i = 1; i < MUL_STAGES; i++) begin : g_mul
    always_ff @(posedge clk) if (v_mul[i-1]) acc_r[i] <= acc_r[i-1];
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) for (int i = 0; i < MUL_STAGES; i++) v_mul[i] <= 1'b0;
    else begin
      v_mul[0] <= z_valid;
      for (int i = 1; i < MUL_STAGES; i++) v_mul[i] <= v_mul[i-1];
    end
  end
  logic signed [33:0] acc1;
  logic               v1;
  assign acc1 = acc_r[MUL_STAGES-1];
  assign v1   = v_mul[MUL_STAGES-1];

  // ---- S2: round half to even (drop 14 bits), then saturate to 18 bits -------------
  // TODO: replace with Chuanqi's shared round_sat module once it is merged.
  logic signed [19:0] q2, xr;
  logic        [13:0] rem2;
  logic               up2;
  assign q2   = acc1[33:14];                                   // floor(acc / 2^14)
  assign rem2 = acc1[13:0];
  assign up2  = (rem2 > 14'h2000) || (rem2 == 14'h2000 && q2[0]);
  assign xr   = q2 + 20'(up2);

  logic signed [17:0] x2;
  logic               sx2, v2;
  always_ff @(posedge clk) if (v1) begin
    x2  <= (xr > X_MAX) ? X_MAX[17:0] : (xr < X_MIN) ? X_MIN[17:0] : xr[17:0];
    sx2 <= (xr > X_MAX) || (xr < X_MIN);
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) v2 <= 1'b0;
    else        v2 <= v1;
  end

  // ---- S3-S5: e^x ---------------------------------------------------------------------
  logic        v5, ss5, sx5;
  logic [21:0] st5;
  exp2_unit #(.EXP_ADDR_BITS(EXP_ADDR_BITS)) u_exp (
    .clk, .rst_n, .in_valid(v2), .x(x2), .out_valid(v5), .s_t(st5), .sat_s(ss5));
  pipe #(.W(1), .N(LAT_EXP)) u_sx (.clk, .rst_n, .d(sx2), .q(sx5));   // keep sat_x beside its trial

  // ---- S6: payoff ---------------------------------------------------------------------
  logic sx6, ss6;
  always_ff @(posedge clk) if (v5) begin
    p   <= (st5 > k) ? st5 - k : '0;
    sx6 <= sx5;
    ss6 <= ss5;
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) p_valid <= 1'b0;
    else        p_valid <= v5;
  end
  assign sat_x = p_valid & sx6;
  assign sat_s = p_valid & ss6;
endmodule
