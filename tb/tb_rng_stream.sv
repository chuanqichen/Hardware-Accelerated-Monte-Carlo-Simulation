// Long continuous stream with an independent sequential xoshiro128++ oracle.
// +SEED=<128-bit hex>, +STREAM_FILE=<path>, optional +VCD_FILE=<path>.
// Only the first 32 accepted words are captured in the VCD.
`timescale 1ns/1ps
module tb_rng_stream;
  parameter int N_WORDS = 1048576;
  logic clk = 0, rst_n = 0, seed_load = 0, run = 0;
  logic [127:0] seed_state = '0;
  logic [31:0] u;
  logic u_valid;
  rng_lane dut (.*);
  always #5 clk = ~clk;

  function automatic logic [31:0] rotl32(input logic [31:0] x, input int k);
    return (x << k) | (x >> (32-k));
  endfunction

  initial begin : watchdog
    #(10.0 * (N_WORDS + 32));
    $fatal(1, "long RNG stream timed out");
  end

  initial begin : test
    logic [31:0] s0, s1, s2, s3, t, expected;
    int fd;
    string stream_file, vcd_file;
    if (N_WORDS < 2) $fatal(1, "N_WORDS must be at least 2");
    if (mc_pkg::LAT_RNG != 1) $fatal(1, "stream checker requires LAT_RNG=1");
    if (!$value$plusargs("SEED=%h", seed_state) || seed_state == '0)
      $fatal(1, "a nonzero +SEED is required");
    if (!$value$plusargs("STREAM_FILE=%s", stream_file))
      $fatal(1, "+STREAM_FILE is required");
    fd = $fopen(stream_file, "w");
    if (!fd) $fatal(1, "cannot open %s", stream_file);
    if ($value$plusargs("VCD_FILE=%s", vcd_file)) begin
      $dumpfile(vcd_file);
      $dumpvars(0, tb_rng_stream);
    end
    // Reset remains asserted across a rising edge before seed load.
    @(negedge clk);
    rst_n = 1;
    seed_load = 1;
    run = 1;  // Load wins over run.
    {s3, s2, s1, s0} = seed_state;
    @(posedge clk); #1;
    if (u_valid !== 1'b0) $fatal(1, "seed load generated a word");
    @(negedge clk);
    seed_load = 0;
    for (int i = 0; i < N_WORDS; i++) begin
      // Literal canonical sequential equations, distinct from the DUT.
      expected = rotl32(s0 + s3, 7) + s0;
      t = s1 << 9;
      s2 = s2 ^ s0;
      s3 = s3 ^ s1;
      s1 = s1 ^ s2;
      s0 = s0 ^ s3;
      s2 = s2 ^ t;
      s3 = rotl32(s3, 11);
      @(posedge clk); #1;
      if (u_valid !== 1'b1 || u !== expected ||
          {dut.s3, dut.s2, dut.s1, dut.s0} !== {s3, s2, s1, s0})
        $fatal(1, "word %0d: valid=%b got=%h expected=%h", i, u_valid, u, expected);
      $fdisplay(fd, "%08h", u);
      if (i == 31 && vcd_file != "") $dumpoff;
    end
    @(negedge clk);
    run = 0;
    @(posedge clk); #1;
    if (u_valid !== 1'b0 || u !== expected)
      $fatal(1, "pause did not clear valid and hold output");
    $fclose(fd);
    $display("PASS rng_stream: %0d consecutive words, II=1, seed=%032h", N_WORDS, seed_state);
    $finish;
  end
endmodule
