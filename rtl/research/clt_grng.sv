// clt_grng: CLT-12 Gaussian baseline (research). z = (sum of 12 uniform W-bit words - 6*2^W),
// interpreted as Q3.12 when W = 12 (mean 0, variance 1, |z| <= 6). The uniform words come
// from the environment (twelve 12-bit slices of RNG output); the block is the adder tree
// and offset, which is the architecture-specific cost. Reference: model/clt_grng.py.
module clt_grng #(
  parameter int W = 12
) (
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic                 in_valid,
  input  logic [12*W-1:0]      words,
  output logic                 out_valid,
  output logic signed [15:0]   z
);
  logic [W+3:0] sum;
  always_comb begin
    sum = '0;
    for (int i = 0; i < 12; i++) sum = sum + words[i*W +: W];
  end
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) out_valid <= 1'b0; else out_valid <= in_valid;
  always_ff @(posedge clk)
    if (in_valid) z <= 16'($signed({1'b0, sum}) - $signed(17'(6 << W)));
endmodule
