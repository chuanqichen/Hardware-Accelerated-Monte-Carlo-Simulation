`timescale 1ns/1ps
// Interface-only replay of the golden corpus against the default mapped top.
// No RTL hierarchy, internal stage names, timing annotation, or retiming assumed.
module tb_mc_top_gate;
  import mc_pkg::*;
  logic clk = 0, rst_n = 0, cfg_we = 0, start = 0;
  logic [7:0] cfg_addr = 0;
  logic [31:0] cfg_wdata = 0;
  logic busy, done;
  logic [63:0] payoff_sum;
  logic [31:0] trial_count, cycle_count;
  logic [7:0] status;
  mc_top dut (.*);
  always #5 clk = ~clk;
  initial begin #3000000; $fatal(1, "mapped top timeout"); end

  task automatic tick; @(posedge clk); #2; endtask
  task automatic reset_dut;
    @(negedge clk); rst_n = 0; cfg_we = 0; start = 0;
    #1;
    if ({busy,done,payoff_sum,trial_count,status} !== '0)
      $fatal(1, "mapped reset failed");
    @(negedge clk); rst_n = 1;
    repeat (3) tick();
  endtask
  task automatic write_cfg(input logic [7:0] addr, input logic [31:0] value);
    @(negedge clk); cfg_we = 1; cfg_addr = addr; cfg_wdata = value;
    tick(); @(negedge clk); cfg_we = 0;
  endtask
  task automatic pulse_start;
    @(negedge clk); start = 1;
    tick(); @(negedge clk); start = 0;
  endtask
  task automatic configure(input logic [17:0] a, input logic [15:0] b,
                           input logic [21:0] k, input logic [127:0] seed,
                           input logic [31:0] n);
    write_cfg(REG_A, {14'b0,a}); write_cfg(REG_B, {16'b0,b});
    write_cfg(REG_K, {10'b0,k}); write_cfg(REG_N_TRIALS,n);
    for (int w = 0; w < 4; w++) write_cfg(reg_seed(0,w),seed[32*w +: 32]);
  endtask

  initial begin
    int fd, csv, fields, cases = 0, trials = 0;
    logic [17:0] a;
    logic [15:0] b;
    logic [21:0] k;
    logic [127:0] seed;
    logic [31:0] n;
    logic [63:0] expected_sum;
    logic [7:0] expected_status;
    string vectors = "tb/vectors/mc_top_cases.hex", cycle_file;
    if ($value$plusargs("cases=%s", vectors)) begin end
    if (!$value$plusargs("cycle_csv=%s", cycle_file))
      $fatal(1, "cycle_csv path is required");
    fd = $fopen(vectors,"r"); csv = $fopen(cycle_file,"w");
    if (!fd || !csv) $fatal(1, "missing case corpus or cycle output");
    $fdisplay(csv,"case_id,trials,cycles,payoff_sum,status");
    reset_dut(); pulse_start();
    if (busy !== 0 || done !== 0 || status[ST_BAD_CFG] !== 1)
      $fatal(1, "unconfigured mapped start accepted");
    while (!$feof(fd)) begin
      fields = $fscanf(fd,"%h %h %h %h %h %h %h\n",a,b,k,seed,n,expected_sum,expected_status);
      if (fields != 7 || n < 1 || n > 10000) $fatal(1, "malformed/unsupported case");
      configure(a,b,k,seed,n);
      if (cases == 2) begin
        pulse_start(); repeat (6) tick(); reset_dut(); configure(a,b,k,seed,n);
      end
      pulse_start();
      while (done !== 1) begin
        if ($isunknown({busy,done,status,trial_count,cycle_count,payoff_sum}))
          $fatal(1, "unknown mapped control/results");
        tick();
      end
      if (busy !== 0 || trial_count !== n || payoff_sum !== expected_sum || status !== expected_status)
        $fatal(1, "mapped case %0d: result/count/status mismatch", cases);
      if (cycle_count !== n + lat_total(1,1,1) + 2)
        $fatal(1, "mapped case %0d: cycle count mismatch", cases);
      $fdisplay(csv,"%0d,%0d,%0d,%0d,%0d",cases,n,cycle_count,payoff_sum,status);
      repeat (3) begin
        tick();
        if (done !== 0 || busy !== 0 || payoff_sum !== expected_sum ||
            trial_count !== n || status !== expected_status)
          $fatal(1, "mapped idle/done/sticky result mismatch");
      end
      cases++; trials += n;
    end
    if (cases != 22 || trials != 26457) $fatal(1, "empty/incomplete mapped corpus");
    $fclose(fd); $fclose(csv);
    $display("PASS: tb_mc_top_gate cases=22 trials=26457, exact results/status/cycles, zero-delay cells");
    $finish;
  end
endmodule
