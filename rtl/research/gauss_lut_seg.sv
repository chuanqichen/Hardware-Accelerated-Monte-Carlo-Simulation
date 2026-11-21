// gauss_lut_seg: tail-refined segmented inverse-normal table (research; see
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
module gauss_lut_seg #(
  parameter int K         = 12,   // bands
  parameter int B         = 4,    // bits per band
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
  logic [B-1:0]         j;
  logic [OUT_WIDTH-1:0] mag;

  assign sign = u[31];
  assign m    = sign ? ~u[30:0] : u[30:0];

  // leading-zero count over 31 bits (priority encoder)
  always_comb begin
    clz = 5'd31;
    for (int i = 30; i >= 0; i--) if (m[i] && clz == 5'd31) clz = 5'(30 - i);
  end
  assign k = (clz >= K - 1) ? KB'(K - 1) : KB'(clz);

  // B bits below the leading one of band k. For the last band the same positions are
  // used for every clz >= K-1, which indexes the remaining tail uniformly.
  always_comb begin
    automatic int sh = 30 - int'(k) - B;      // position of the lowest of the B bits
    if (sh >= 0) j = B'(m >> sh);
    else         j = B'(m << (-sh));
  end

  gauss_lut_seg_rom #(.K_BITS(KB), .B(B), .OUT_WIDTH(OUT_WIDTH)) u_rom (.addr({k, j}), .mag(mag));

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
