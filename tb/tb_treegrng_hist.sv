// Histogram the TreeGRNG example design's output codes over N cycles (research study).
// Prints "code count" for all 256 INT8 codes; model/treegrng_study.py compares its
// enumerated exact distribution against this.
`timescale 1ns/1ps
module tb_treegrng_hist;
  parameter int N = 1 << 22;
  logic clk = 0, ld = 1;
  logic [7:0] result;
  compGRNG dut (.clk(clk), .LD_seed(ld), .result(result));
  always #5 clk = ~clk;
  longint cnt [256];
  initial begin
    for (int i = 0; i < 256; i++) cnt[i] = 0;
    repeat (2) @(posedge clk);
    ld = 0;
    repeat (16) @(posedge clk);          // let the LFSRs run off the seed
    for (int i = 0; i < N; i++) begin
      @(posedge clk); #1;
      cnt[result]++;
    end
    for (int i = 0; i < 256; i++) $display("HIST %0d %0d", i, cnt[i]);
    $finish;
  end
endmodule
