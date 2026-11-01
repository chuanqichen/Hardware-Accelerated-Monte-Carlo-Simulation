`timescale 1ns/1ps
// The top controller deliberately issues continuously. This test drives the
// production adapter directly to verify pause/resume and valid bubble alignment.
module tb_mc_lane_bubbles;
  import mc_pkg::*;
  localparam int G = 2, M = 2;
  localparam int LAT_P = LAT_RNG + G + lat_dp(M);
  logic clk = 0, rst_n = 0, clear_accum = 0, seed_load = 0;
  logic [0:0] run_mask = 0;
  logic [0:0][127:0] seed_state;
  logic signed [17:0] a;
  logic [15:0] b;
  logic [21:0] k;
  logic [63:0] payoff_sum;
  logic [31:0] trial_count;
  logic sat_x, sat_s, acc_overflow;
  logic [21:0] expected_p[100];
  logic [31:0] expected_u[100];
  logic [LAT_P-1:0] tag = '0;
  logic checking = 0;
  int checked = 0, checked_u = 0;
  mc_lane_array #(.GAUSS_LATENCY(G), .MUL_STAGES(M)) dut (.*);
  always #5 clk = ~clk;
  initial begin #100000; $fatal(1, "bubble test timeout"); end
  task automatic tick; @(posedge clk); #2; endtask

  always @(posedge clk) begin
    if (!rst_n || clear_accum) tag = '0;
    else tag = {tag[LAT_P-2:0], run_mask[0]};
    #1;
    if (checking) begin
      if (dut.p_valid !== tag[LAT_P-1]) $fatal(1, "bubble latency mismatch");
      if (dut.u_valid) begin
        if (checked_u >= 100 || dut.u !== expected_u[checked_u]) $fatal(1, "pause skipped RNG sample");
        checked_u++;
      end
      if (dut.p_valid) begin
        if (checked >= 100 || dut.p !== expected_p[checked]) $fatal(1, "bubble payoff mismatch");
        checked++;
      end
    end
  end
  initial begin
    int mf, tf, r;
    logic [31:0] n;
    logic [63:0] expected_sum;
    logic [7:0] expected_status;
    logic [15:0] dummy_z;
    logic [17:0] dummy_x;
    logic [21:0] dummy_s;
    logic dummy_sx, dummy_ss;
    mf=$fopen("tb/vectors/mc_top_cases.hex","r"); tf=$fopen("tb/vectors/mc_top_trace.hex","r");
    if (!mf || !tf) $fatal(1, "missing vectors");
    // Select the second corpus case (100 trials), skipping the first trial.
    for (int c=0; c<2; c++) begin
      r=$fscanf(mf,"%h %h %h %h %h %h %h\n",a,b,k,seed_state,n,expected_sum,expected_status);
      if (r!=7 || n>100) $fatal(1, "malformed bubble case");
      for (int i=0; i<n; i++) begin
        r=$fscanf(tf,"%h %h %h %h %h %h %h\n",expected_u[i],dummy_z,dummy_x,dummy_s,expected_p[i],dummy_sx,dummy_ss);
        if (r!=7) $fatal(1, "malformed bubble trace");
      end
    end
    if (n!=100) $fatal(1, "incorrect bubble corpus");
    $fclose(mf); $fclose(tf);
    tick(); @(negedge clk); rst_n=1;
    @(negedge clk); clear_accum=1; seed_load=1;
    tick(); @(negedge clk); clear_accum=0; seed_load=0; checking=1;
    for (int i=0; i<100; i++) begin
      if (i%3==1) begin
        @(negedge clk); run_mask=0;
        repeat (2) tick();
      end
      @(negedge clk); run_mask=1;
      tick();
    end
    @(negedge clk); run_mask=0;
    while (trial_count!=100) tick();
    if (checked!=100 || checked_u!=100 || payoff_sum!==expected_sum || sat_x || sat_s || acc_overflow)
      $fatal(1, "bubble totals/flags mismatch");
    repeat (3) tick();
    $display("PASS: tb_mc_lane_bubbles 100 exact trials, pause/resume, valid latency=%0d",LAT_P);
    $finish;
  end
endmodule
