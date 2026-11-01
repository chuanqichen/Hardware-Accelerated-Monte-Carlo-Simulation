`timescale 1ns/1ps
// Control acceptance tests only. The backend is explicitly a test double.
module tb_mc_control;
  parameter int LANES = 1;
  logic clk = 0, rst_n = 0, cfg_we = 0, start = 0;
  logic [7:0] cfg_addr = 0;
  logic [31:0] cfg_wdata = 0;
  logic busy, done;
  logic [63:0] payoff_sum;
  logic [31:0] trial_count, cycle_count;
  logic [7:0] status;
  int completed_runs = 0;
  mc_top #(.LANES(LANES)) dut (.*);
  always #5 clk = ~clk;
  initial begin
    #2000000;
    $fatal(1, "control regression timed out");
  end

  task automatic tick;
    @(posedge clk); #1;
  endtask
  task automatic reset_dut;
    @(negedge clk); rst_n = 0; cfg_we = 0; start = 0;
    #1;
    if (busy || done || status || payoff_sum || trial_count || cycle_count)
      $fatal(1, "asynchronous reset did not clear state/results");
    @(negedge clk); rst_n = 1;
    repeat (3) tick();
    if (busy || done || status) $fatal(1, "reset release");
  endtask
  task automatic write_cfg(input logic [7:0] addr, input logic [31:0] value);
    @(negedge clk); cfg_we = 1; cfg_addr = addr; cfg_wdata = value;
    tick();
    @(negedge clk); cfg_we = 0;
  endtask
  task automatic pulse_start;
    @(negedge clk); start = 1;
    tick();
    @(negedge clk); start = 0;
  endtask
  task automatic configure(input int unsigned n);
    write_cfg(0, 32'h0003f000); // -1.0 in zero-extended Q5.12 storage.
    write_cfg(1, 32'h00002000);
    write_cfg(2, 32'd25600);
    write_cfg(3, n);
    for (int lane = 0; lane < LANES; lane++) begin
      write_cfg(8'(16+4*lane), 32'(lane+1));
      for (int word_index = 1; word_index < 4; word_index++)
        write_cfg(8'(16+4*lane+word_index), 0);
    end
  endtask
  task automatic finish_run(input int unsigned n, input logic [7:0] expected_status);
    longint unsigned expected_sum;
    int expected_cycles;
    expected_sum = 0;
    // Independent trial-order oracle: each beat assigns lanes from zero upward.
    for (int trial = 0; trial < n; trial++) expected_sum += 256*((trial % LANES)+1);
    expected_cycles = ((n+LANES-1)/LANES) + 3 + 3; // mock latency + start/load/drain
    while (!done) begin
      tick();
      if ($isunknown({busy,done,status,trial_count,cycle_count,payoff_sum}))
        $fatal(1, "unknown control/result bus");
    end
    if (busy || trial_count != n || payoff_sum != expected_sum || status != expected_status)
      $fatal(1, "N=%0d: count=%0d sum=%0d status=%h", n, trial_count, payoff_sum, status);
    if (cycle_count != expected_cycles)
      $fatal(1, "N=%0d: cycles=%0d expected=%0d", n, cycle_count, expected_cycles);
    tick();
    if (done || status != expected_status) $fatal(1, "done pulse/sticky status");
    repeat (3) tick();
    if (trial_count != n || payoff_sum != expected_sum || cycle_count != expected_cycles)
      $fatal(1, "idle changed results");
    completed_runs++;
  endtask

  initial begin
    reset_dut();
    pulse_start();
    if (busy || done || status != 8'h10) $fatal(1, "unconfigured start accepted");
    configure(0);
    pulse_start();
    if (busy || done || status != 8'h10) $fatal(1, "zero trials accepted");
    configure(1);
    write_cfg(8'h10, 0);
    pulse_start();
    if (busy || done || status != 8'h10) $fatal(1, "zero seed accepted");
    configure(1);
    pulse_start(); finish_run(1, 8'h01);
    configure(100);
    pulse_start(); finish_run(100, 8'h01);
    configure(1000);
    pulse_start(); finish_run(1000, 8'h01);
    configure(10000);
    pulse_start(); finish_run(10000, 8'h01);
    configure(101);
    pulse_start(); finish_run(101, 8'h01);
    // Repeat without rewriting registers: same configuration and cycle count.
    pulse_start(); finish_run(101, 8'h01);

    configure(101);
    pulse_start();
    if (!busy) $fatal(1, "valid start not accepted");
    write_cfg(3, 1); // Must be ignored for both current and following run.
    pulse_start(); // Busy start must not clear/restart the current run.
    @(negedge clk);
    dut.u_lanes.inject_sat_x = 1;
    dut.u_lanes.inject_sat_s = 1;
    dut.u_lanes.inject_overflow = 1;
    tick();
    @(negedge clk);
    dut.u_lanes.inject_sat_x = 0;
    dut.u_lanes.inject_sat_s = 0;
    dut.u_lanes.inject_overflow = 0;
    finish_run(101, 8'h1f);
    pulse_start(); finish_run(101, 8'h01);

    write_cfg(8'hff, 0);
    if (status != 8'h11) $fatal(1, "unknown address not flagged");
    write_cfg(1, 32'h00010000);
    if (dut.cfg_b != 16'h2000) $fatal(1, "invalid width write changed B");
    // cfg_we/start collision rejects start but permits a valid idle write.
    @(negedge clk); cfg_we = 1; cfg_addr = 3; cfg_wdata = 101; start = 1;
    tick();
    if (busy || !status[4]) $fatal(1, "ambiguous config/start accepted");
    @(negedge clk); cfg_we = 0; start = 0;
    pulse_start(); finish_run(101, 8'h01);

    configure(10000); pulse_start(); repeat (5) tick();
    reset_dut(); // Discards every in-flight trial and clears configuration.
    pulse_start();
    if (busy || !status[4]) $fatal(1, "reset retained valid configuration");
    configure(1); pulse_start(); finish_run(1, 8'h01);
    $display("PASS: mc_top control shell LANES=%0d, %0d runs (TEST BACKEND ONLY)", LANES, completed_runs);
    $finish;
  end
endmodule
