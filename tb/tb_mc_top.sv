`timescale 1ns/1ps
module tb_mc_top;
  import mc_pkg::*;
  parameter int GAUSS_LATENCY = 1;
  parameter int MUL_STAGES = 1;
  localparam int MAX_TRIALS = 10000;
  logic clk = 1'b0, rst_n = 1'b0, cfg_we = 1'b0, start = 1'b0;
  logic [7:0] cfg_addr = '0;
  logic [31:0] cfg_wdata = '0;
  logic busy, done;
  logic [63:0] payoff_sum;
  logic [31:0] trial_count, cycle_count;
  logic [7:0] status;
  mc_top #(.GAUSS_LATENCY(GAUSS_LATENCY), .MUL_STAGES(MUL_STAGES)) dut (.*);
  always #5 clk = ~clk;
  initial begin #3000000; $fatal(1, "integrated top timeout"); end

  logic [31:0] eu[MAX_TRIALS];
  logic [15:0] ez[MAX_TRIALS];
  logic [17:0] ex[MAX_TRIALS];
  logic [21:0] es[MAX_TRIALS], ep[MAX_TRIALS];
  logic esx[MAX_TRIALS], ess[MAX_TRIALS];
  int nu, nz, nx, ns, np, expected_n, last_payoff_cycle, monitor_cycle = 0;
  int total_trials = 0, n_cases = 0;
  bit checking = 0;

  // Check after NBA, before the driver's #2 sampling. Only qualified data is
  // meaningful; every pipeline boundary is compared against its own trace index.
  always @(posedge clk) begin
    #1;
    monitor_cycle++;
    if (checking && dut.core_rst_n) begin
      if ($isunknown({busy,done,status,trial_count,cycle_count,payoff_sum,
                      dut.u_lanes.u_valid,dut.u_lanes.z_valid,dut.u_lanes.p_valid}))
        $fatal(1, "unknown control/result bus");
      if (dut.u_lanes.u_valid) begin
        if (nu >= expected_n || dut.u_lanes.u !== eu[nu]) $fatal(1, "u mismatch trial %0d", nu);
        nu++;
      end
      if (dut.u_lanes.z_valid) begin
        if (nz >= expected_n || dut.u_lanes.z !== ez[nz]) $fatal(1, "z mismatch trial %0d", nz);
        nz++;
      end
      if (dut.u_lanes.u_price.v2) begin
        if (nx >= expected_n || dut.u_lanes.u_price.x2 !== ex[nx]) $fatal(1, "x mismatch trial %0d", nx);
        nx++;
      end
      if (dut.u_lanes.u_price.u_exp.out_valid) begin
        if (ns >= expected_n || dut.u_lanes.u_price.u_exp.s_t !== es[ns]) $fatal(1, "S_T mismatch trial %0d", ns);
        ns++;
      end
      if (dut.u_lanes.p_valid) begin
        if (np >= expected_n || dut.u_lanes.p !== ep[np] ||
            dut.u_lanes.sx !== esx[np] || dut.u_lanes.ss !== ess[np])
          $fatal(1, "payoff/flags mismatch trial %0d", np);
        if (np > 0 && monitor_cycle != last_payoff_cycle+1)
          $fatal(1, "sustained II=1 violated");
        last_payoff_cycle = monitor_cycle;
        np++;
      end
    end
  end

  task automatic tick; @(posedge clk); #2; endtask
  task automatic reset_dut;
    checking = 0;
    @(negedge clk); rst_n = 1'b0; start = 1'b0; cfg_we = 1'b0;
    #1;
    if (busy || done || payoff_sum || trial_count || status) $fatal(1, "reset failed");
    @(negedge clk); rst_n = 1'b1;
    repeat (3) tick();
  endtask
  task automatic write_cfg(input logic [7:0] addr, input logic [31:0] value);
    @(negedge clk); cfg_we = 1'b1; cfg_addr = addr; cfg_wdata = value;
    tick();
    @(negedge clk); cfg_we = 1'b0;
  endtask
  task automatic pulse_start;
    @(negedge clk); start = 1'b1;
    tick();
    @(negedge clk); start = 1'b0;
  endtask

  initial begin
    int mf, tf, r;
    logic [17:0] a;
    logic [15:0] b;
    logic [21:0] k;
    logic [127:0] seed;
    logic [31:0] n;
    logic [63:0] expected_sum;
    logic [7:0] expected_status;
    mf = $fopen("tb/vectors/mc_top_cases.hex", "r");
    tf = $fopen("tb/vectors/mc_top_trace.hex", "r");
    if (!mf || !tf) $fatal(1, "missing integrated vectors; run make gen-top");
    reset_dut();
    pulse_start();
    if (busy || done || !status[ST_BAD_CFG]) $fatal(1, "unconfigured start accepted");
    while (!$feof(mf)) begin
      r = $fscanf(mf, "%h %h %h %h %h %h %h\n", a,b,k,seed,n,expected_sum,expected_status);
      if (r != 7 || n < 1 || n > MAX_TRIALS) $fatal(1, "malformed/unsupported case");
      for (int i = 0; i < n; i++) begin
        r = $fscanf(tf, "%h %h %h %h %h %h %h\n", eu[i],ez[i],ex[i],es[i],ep[i],esx[i],ess[i]);
        if (r != 7) $fatal(1, "truncated/malformed trace");
      end
      checking = 0;
      write_cfg(REG_A, {14'b0,a}); write_cfg(REG_B, {16'b0,b});
      write_cfg(REG_K, {10'b0,k}); write_cfg(REG_N_TRIALS,n);
      for (int w = 0; w < 4; w++) write_cfg(reg_seed(0,w),seed[32*w +: 32]);
      // Abort real in-flight work once, then restart from the same seed. Any
      // stale pipeline output or accumulator contribution corrupts this trace.
      if (n_cases == 2) begin
        pulse_start(); repeat (6) tick();
        reset_dut();
        write_cfg(REG_A, {14'b0,a}); write_cfg(REG_B, {16'b0,b});
        write_cfg(REG_K, {10'b0,k}); write_cfg(REG_N_TRIALS,n);
        for (int w = 0; w < 4; w++) write_cfg(reg_seed(0,w),seed[32*w +: 32]);
      end
      expected_n = n; nu=0; nz=0; nx=0; ns=0; np=0;
      checking = 1;
      pulse_start();
      while (!done) tick();
      if (busy || trial_count !== n || payoff_sum !== expected_sum || status !== expected_status)
        $fatal(1, "case %0d: count=%0d sum=%h status=%h expected=%0d/%h/%h", n_cases,
               trial_count,payoff_sum,status,n,expected_sum,expected_status);
      if (nu!=n || nz!=n || nx!=n || ns!=n || np!=n) $fatal(1, "stage count mismatch");
      if (cycle_count != n + lat_total(GAUSS_LATENCY,MUL_STAGES,1) + 2)
        $fatal(1, "unexpected run cycles: %0d",cycle_count);
      tick();
      if (done || status !== expected_status) $fatal(1, "done/sticky status failed");
      repeat (2) tick(); // Extra valid outputs during idle are still checked.
      checking = 0;
      n_cases++; total_trials += n;
    end
    if (n_cases != 22 || total_trials != 26457) $fatal(1, "empty/incomplete regression corpus");
    $fclose(mf); $fclose(tf);
    $display("PASS: tb_mc_top G=%0d M=%0d cases=%0d trials=%0d, exact traces/results, sustained II=1",
             GAUSS_LATENCY,MUL_STAGES,n_cases,total_trials);
    $finish;
  end
endmodule
