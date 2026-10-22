// pipe: delay a signal by N clock cycles (N = 0 is a plain wire).
//
// Use it for everything that has to stay lined up with the datapath (valid
// bits, flags): change a stage count once and every side signal follows, so
// valid can never drift a cycle away from its data. Registers reset to 0, which
// is what valid bits need; the cost of resetting a few side-band flops is nil.
module pipe #(
  parameter int W = 1,
  parameter int N = 1
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [W-1:0] d,
  output logic [W-1:0] q
);
  generate
    if (N == 0) begin : g_wire
      assign q = d;
    end else begin : g_regs
      logic [W-1:0] r [N];
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          for (int i = 0; i < N; i++) r[i] <= '0;
        end else begin
          r[0] <= d;
          for (int i = 1; i < N; i++) r[i] <= r[i-1];
        end
      end
      assign q = r[N-1];
    end
  endgenerate
endmodule
