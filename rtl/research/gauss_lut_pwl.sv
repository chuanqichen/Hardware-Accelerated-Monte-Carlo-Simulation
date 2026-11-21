// gauss_lut_pwl: Giles & Sheridan-Methven piecewise-linear dyadic table in hardware form (research; see
// docs/research/treegrng_study.md). Bit-accurate reference: model/gauss_lut_seg.py.
//
//   sign = u[31];  m = sign ? ~u[30:0] : u[30:0]           tail-side magnitude, [0, 2^31)
//   k    = min(clz31(m), K-1)                               dyadic band in tail probability
//   j    = the B bits of m just below the leading one       cell within the band
//   mag  = ROM[{k, j}];  z = sign ? +mag : -mag              Q3.12
//
// Entries are spent evenly in log2(tail probability), so z reaches
// Phi^-1(1 - 2^-(K+B+1)) with K*2^B entries. Latency 1 (clz + ROM + negate in one
// stage) or 2 (register after the ROM). Only out_valid is reset (spec D-2).
module gauss_lut_pwl #(
  parameter int K         = 12,   // bands
  parameter int F         = 12,   // fraction bits multiplied by the slope
  parameter int OUT_WIDTH = 16,
  parameter int LATENCY   = 1
) (
  input  logic                        clk,
  input  logic                        rst_n,
  input  logic                        in_valid,
  input  logic [31:0]                 u,
  output logic                        out_valid,
  output logic signed [OUT_WIDTH-1:0] z
);
  localparam int KB = (K <= 1) ? 1 : $clog2(K);

  logic                 sign;
  logic [30:0]          m;
  logic [4:0]           clz;          // 0..31
  logic [KB-1:0]        k;
  logic [F-1:0]         f;
  logic [15:0]          alpha, beta;
  logic [OUT_WIDTH-1:0] mag;
  logic [F+15:0]        prod;
  logic [F+15:0]        q;
  logic signed [17:0]   diff;

  assign sign = u[31];
  assign m    = sign ? ~u[30:0] : u[30:0];

  // leading-zero count over 31 bits (priority encoder)
  always_comb begin
    clz = 5'd31;
    for (int i = 30; i >= 0; i--) if (m[i] && clz == 5'd31) clz = 5'(30 - i);
  end
  assign k = (clz >= K - 1) ? KB'(K - 1) : KB'(clz);

  // F fraction bits below the leading one of band k (position within the band, UQ0.F)
  always_comb begin
    automatic int sh = 30 - int'(k) - F;
    if (sh >= 0) f = F'(m >> sh);
    else         f = F'(m << (-sh));
  end

  gauss_lut_pwl_rom #(.K_BITS(KB)) u_rom (.k(k), .alpha(alpha), .beta(beta));

  // mag = alpha - round_half_even(beta * f / 2^(14+F-12)), saturated to [0, 2^15-1]
  localparam int SH = 14 + F - 12;
  assign prod = beta * f;
  always_comb begin
    q = prod >> SH;
    if (prod[SH-1:0] > (1 << (SH-1)) || (prod[SH-1:0] == (1 << (SH-1)) && q[0])) q = q + 1;
    diff = $signed({2'b00, alpha}) - $signed({1'b0, q[16:0]});
    mag  = (diff < 0) ? '0 : (diff > 18'sd32767) ? 16'h7FFF : OUT_WIDTH'(diff);
  end

  generate
    if (LATENCY == 1) begin : g_lat1
      always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) out_valid <= 1'b0; else out_valid <= in_valid;
      always_ff @(posedge clk)
        if (in_valid) z <= sign ? $signed(mag) : -$signed(mag);
    end else begin : g_lat2
      logic                 v_q, sign_q;
      logic [OUT_WIDTH-1:0] mag_q;
      always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) {v_q, out_valid} <= '0; else {v_q, out_valid} <= {in_valid, v_q};
      always_ff @(posedge clk) begin
        if (in_valid) begin sign_q <= sign; mag_q <= mag; end
        if (v_q)      z <= sign_q ? $signed(mag_q) : -$signed(mag_q);
      end
    end
  endgenerate

`ifndef SYNTHESIS
  always_ff @(posedge clk) if (rst_n && in_valid) a_mag_positive: assert (mag[OUT_WIDTH-1] == 1'b0);
`endif
endmodule
