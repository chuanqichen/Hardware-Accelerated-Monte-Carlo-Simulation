// Cycle-exact checks after NBA updates: valid, output, state and look-ahead sum.
// Optional +STREAM_FILE=<path> exports valid raw words as one hex word/line.
`timescale 1ns/1ps
module tb_rng_lane;
  parameter string VEC_FILE = "tb/vectors/rng_lane.hex";
  logic clk = 1'b0;
  logic rst_n = 1'b0, seed_load = 1'b0, run = 1'b0;
  logic [127:0] seed_state = '0;
  logic [31:0] u;
  logic u_valid;
  rng_lane dut (.*);
  always #5 clk = ~clk;

  task automatic check_t;
    logic [31:0] expected_t;
    expected_t = dut.s0 + dut.s3;  // Explicit 32-bit modular sum.
    assert (dut.t === expected_t)
      else $fatal(1, "t invariant: got=%h expected=%h", dut.t, expected_t);
  endtask

  // Check after NBA settlement for reset, load, accepted run and hold alike.
  always @(posedge clk or negedge rst_n) begin
    #1;
    check_t();
    if (!rst_n) begin
      assert ({dut.s3, dut.s2, dut.s1, dut.s0, dut.t, u, u_valid} === '0)
        else $fatal(1, "reset failed to clear all registers");
    end
  end

  initial begin : watchdog
    #1000000;
    $fatal(1, "RNG test timeout");
  end

  initial begin : test
    int fd, fields, n_cycles, n_valid, stream_fd, chars;
    logic vec_rst_n, vec_load, vec_run, exp_valid;
    logic [127:0] vec_seed, exp_state;
    logic [31:0] exp_u, held_t, held_u;
    logic [127:0] held_state;
    string stream_file, line;
    n_cycles = 0;
    n_valid = 0;
    stream_fd = 0;
    if (dut.LAT_RNG != 1) $fatal(1, "LAT_RNG must be 1");
    if ($value$plusargs("STREAM_FILE=%s", stream_file)) begin
      stream_fd = $fopen(stream_file, "w");
      if (!stream_fd) $fatal(1, "cannot open stream output %s", stream_file);
    end
    fd = $fopen(VEC_FILE, "r");
    if (!fd) $fatal(1, "cannot open vectors %s", VEC_FILE);

    // Explicit asynchronous reset check BETWEEN edges during active operation.
    @(negedge clk);
    rst_n = 1'b1; seed_load = 1'b1; run = 1'b1;
    seed_state = 128'h00000004000000030000000200000001;
    @(posedge clk); #1;
    if (u_valid !== 1'b0 || u !== '0 ||
        {dut.s3,dut.s2,dut.s1,dut.s0} !== seed_state || dut.t !== 32'd5)
      $fatal(1, "seed load must win over run and initialize t");
    @(negedge clk); seed_load = 1'b0;
    @(posedge clk); #1;
    if (u_valid !== 1'b1 || u !== 32'h00000281)
      $fatal(1, "canonical first sample or load priority failed");
    held_state = {dut.s3,dut.s2,dut.s1,dut.s0};
    held_t = dut.t; held_u = u;
    repeat (3) begin
      @(negedge clk); run = 1'b0; seed_state = '1;
      @(posedge clk); #1;
      if (u_valid !== 1'b0 || u !== held_u || dut.t !== held_t ||
          {dut.s3,dut.s2,dut.s1,dut.s0} !== held_state)
        $fatal(1, "pause failed to hold state, t and u");
    end
    @(negedge clk); run = 1'b1;
    @(posedge clk); #1;
    // Canonical second word: pause must neither skip nor repeat a sample.
    if (u_valid !== 1'b1 || u !== 32'h00180387)
      $fatal(1, "resume skipped or repeated a sample");
    #1; rst_n = 1'b0; seed_load = 1'b1; // run and load still high
    #1;
    if (dut.t !== '0 || u_valid !== 1'b0 || u !== '0 || {dut.s3,dut.s2,dut.s1,dut.s0} !== '0)
      $fatal(1, "asynchronous reset did not clear registers immediately");

    // Read complete rows so EOF cannot masquerade as malformed input.
    while (1) begin
      chars = $fgets(line, fd);
      if (chars == 0) break;
      fields = $sscanf(line, "%h %h %h %h %h %h %h",
                       vec_rst_n, vec_load, vec_run, vec_seed,
                       exp_valid, exp_u, exp_state);
      if (fields != 7) $fatal(1, "malformed vector row %0d (%0d fields)", n_cycles, fields);
      @(negedge clk);
      rst_n = vec_rst_n;
      seed_load = vec_load;
      run = vec_run;
      seed_state = vec_seed;
      @(posedge clk); #1;
      if (u_valid !== exp_valid || u !== exp_u ||
          {dut.s3,dut.s2,dut.s1,dut.s0} !== exp_state)
        $fatal(1, "cycle %0d: valid=%b/%b u=%h/%h state=%h/%h",
               n_cycles, u_valid, exp_valid, u, exp_u,
               {dut.s3,dut.s2,dut.s1,dut.s0}, exp_state);
      check_t();
      if (u_valid) begin
        n_valid++;
        if (stream_fd) $fdisplay(stream_fd, "%08h", u);
      end
      n_cycles++;
    end
    $fclose(fd);
    if (stream_fd) $fclose(stream_fd);
    if (n_cycles == 0 || n_valid == 0) $fatal(1, "empty RNG regression");
    $display("PASS rng_lane: %0d cycles, %0d valid words", n_cycles, n_valid);
    $finish;
  end
endmodule
