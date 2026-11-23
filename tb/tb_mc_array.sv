`timescale 1ns/1ps
// Interface-only replay: jump-separated seeds, exact aggregate, tails and drain.
module tb_mc_array;
  import mc_pkg::*;
  parameter int LANES = 2, GAUSS_LATENCY = 1, MUL_STAGES = 1;
  parameter int GAUSS_ADDR_BITS = 10, EXP_ADDR_BITS = 10;
  logic clk = 0, rst_n = 0, cfg_we = 0, start = 0;
  logic [7:0] cfg_addr = 0, status;
  logic [31:0] cfg_wdata = 0, trial_count, cycle_count;
  logic busy, done;
  logic [63:0] payoff_sum;
`ifdef MAPPED_MC_TOP
  mc_top dut (.*);
`else
  mc_top #(.LANES(LANES), .GAUSS_LATENCY(GAUSS_LATENCY), .MUL_STAGES(MUL_STAGES),
           .GAUSS_ADDR_BITS(GAUSS_ADDR_BITS), .EXP_ADDR_BITS(EXP_ADDR_BITS)) dut (.*);
`endif
  always #5 clk = ~clk;
  initial begin #3000000; $fatal(1, "array timeout"); end
  task automatic tick; @(posedge clk); #2; endtask
  task automatic reset_dut;
    @(negedge clk); rst_n = 0; start = 0; cfg_we = 0;
    #1;
    if (busy || done || payoff_sum || trial_count || status) $fatal(1, "reset failed");
    @(negedge clk); rst_n = 1;
    repeat (3) tick();
  endtask
  task automatic write_cfg(input logic [7:0] addr, input logic [31:0] value);
    @(negedge clk); cfg_we = 1; cfg_addr = addr; cfg_wdata = value;
    tick(); @(negedge clk); cfg_we = 0;
  endtask
  task automatic pulse_start;
    @(negedge clk); start = 1; tick(); @(negedge clk); start = 0;
  endtask
  task automatic configure(input logic [17:0] a, input logic [15:0] b,
                           input logic [21:0] k, input logic [511:0] seeds,
                           input logic [31:0] n);
    write_cfg(REG_A, {14'b0,a}); write_cfg(REG_B, {16'b0,b});
    write_cfg(REG_K, {10'b0,k}); write_cfg(REG_N_TRIALS,n);
    for (int lane=0; lane<LANES; lane++)
      for (int w=0; w<4; w++) write_cfg(reg_seed(lane,w), seeds[128*lane+32*w +: 32]);
  endtask

  initial begin
    int fd, r, n_cases, total_trials, waited;
    string cases_file;
    logic [17:0] a;
    logic [15:0] b;
    logic [21:0] k;
    logic [511:0] seeds;
    logic [31:0] n;
    logic [63:0] expected_sum;
    logic [7:0] expected_status;
    n_cases=0; total_trials=0;
    if (!$value$plusargs("CASES=%s",cases_file)) $fatal(1,"CASES required");
    fd=$fopen(cases_file,"r");
    if (!fd) $fatal(1,"missing array corpus");
    reset_dut(); pulse_start();
    if (busy || done || !status[ST_BAD_CFG]) $fatal(1,"empty configuration accepted");
    while (!$feof(fd)) begin
      r=$fscanf(fd,"%h %h %h %h %h %h %h\n",a,b,k,seeds,n,expected_sum,expected_status);
      if (r!=7 || n<1 || n>10000) $fatal(1,"malformed array case");
      configure(a,b,k,seeds,n);
      // Every configured lane needs a legal seed, even if N masks it off.
      if (n_cases==0) begin
        for (int lane=0; lane<LANES; lane++) begin
          for (int w=0; w<4; w++) write_cfg(reg_seed(lane,w),0);
          pulse_start();
          if (busy || done || !status[ST_BAD_CFG]) $fatal(1,"zero lane seed accepted");
          for (int w=0; w<4; w++) write_cfg(reg_seed(lane,w),seeds[128*lane+32*w +: 32]);
        end
        write_cfg(REG_N_TRIALS,0); pulse_start();
        if (busy || done || !status[ST_BAD_CFG]) $fatal(1,"zero trials accepted");
        write_cfg(REG_N_TRIALS,n);
      end
      if (n_cases==2) begin
        pulse_start(); repeat (6) tick(); reset_dut();
        configure(a,b,k,seeds,n);
      end
      pulse_start();
      // Busy start is ignored; busy writes flag BAD_CFG without changing N/seeds.
      if (n_cases==3) begin
        pulse_start();
        write_cfg(REG_N_TRIALS,1);
        for (int lane=0; lane<LANES; lane++) write_cfg(reg_seed(lane,0),0);
        expected_status[ST_BAD_CFG]=1;
      end
      waited=0;
      while (!done) begin
        tick(); waited++;
        if (waited > 10000+32) $fatal(1,"drain did not finish");
        if ($isunknown({busy,done,status,trial_count,cycle_count,payoff_sum}))
          $fatal(1,"unknown interface bus");
        if (trial_count > n) $fatal(1,"extra completed trials");
      end
      if (busy || trial_count !== n || payoff_sum !== expected_sum || status !== expected_status)
        $fatal(1,"case %0d got %0d/%h/%h expected %0d/%h/%h",n_cases,
               trial_count,payoff_sum,status,n,expected_sum,expected_status);
      if (cycle_count != (n+LANES-1)/LANES + lat_total(GAUSS_LATENCY,MUL_STAGES,LANES)+2)
        $fatal(1,"wrong busy cycles: %0d",cycle_count);
      repeat (lat_total(GAUSS_LATENCY,MUL_STAGES,LANES)+2) begin
        tick();
        if (done || busy || trial_count !== n || payoff_sum !== expected_sum || status !== expected_status)
          $fatal(1,"late contribution or unstable idle result");
      end
      n_cases++; total_trials+=n;
    end
    if (n_cases != 26+(LANES>1)+(LANES>2)) $fatal(1,"incomplete array corpus");
    if ((LANES==1 && total_trials!=27492) || (LANES==2 && total_trials!=27495) ||
        (LANES==4 && total_trials!=27502)) $fatal(1,"incomplete array trial corpus");
    $fclose(fd);
    $display("PASS: tb_mc_array L=%0d G=%0d M=%0d A=%0d K=%0d cases=%0d trials=%0d",
             LANES,GAUSS_LATENCY,MUL_STAGES,GAUSS_ADDR_BITS,EXP_ADDR_BITS,n_cases,total_trials);
    $finish;
  end
endmodule
