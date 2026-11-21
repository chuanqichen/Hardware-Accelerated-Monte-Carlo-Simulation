// Histogram the TreeGRNG example design's output codes over N cycles (research study).
// Prints "code count" for all 256 INT8 codes; model/treegrng_study.py compares its
// enumerated exact distribution against this.
`timescale 1ns/1ps
module tb_treegrng_hist;
  parameter int N = 1 << 22;
  parameter int W = 8;                 // output width of the design under test
  logic clk = 0, ld = 1;
  logic [W-1:0] result;
`ifdef TOP
  `TOP dut (.clk(clk), .LD_seed(ld), .result(result));
`else
  compGRNG dut (.clk(clk), .LD_seed(ld), .result(result));
`endif
  always #5 clk = ~clk;
  longint cnt [1 << W];
  initial begin
    for (int i = 0; i < (1 << W); i++) cnt[i] = 0;
    repeat (2) @(posedge clk);
    ld = 0;
    repeat (16) @(posedge clk);          // let the LFSRs run off the seed
    for (int i = 0; i < N; i++) begin
      @(posedge clk); #1;
      cnt[result]++;
    end
    for (int i = 0; i < (1 << W); i++) if (cnt[i] != 0) $display("HIST %0d %0d", i, cnt[i]);
    $finish;
  end
endmodule
