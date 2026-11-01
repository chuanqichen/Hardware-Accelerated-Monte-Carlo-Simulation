// Self-checking testbench for round_sat (combinational). Applies every vector in
// tb/vectors/round_sat_i<IN>_o<OUT>_s<SHIFT>_<s|u>.hex and compares out and sat
// against the Python expectation (model/fxp.py round_sat).
//
//   make sim-rs [RS_IN=.. RS_OUT=.. RS_SHIFT=.. RS_SIGNED=..]   (VCS, see Makefile)
`timescale 1ns/1ps
module tb_round_sat;
  parameter int IN_WIDTH  = 34;
  parameter int OUT_WIDTH = 18;
  parameter int SHIFT     = 14;
  parameter bit SIGNED    = 1;
  parameter int MAX_VEC   = 1 << 16;
`ifdef VEC_FILE
  parameter string VEC_FILE = `VEC_FILE;
`else
  parameter string VEC_FILE = "tb/vectors/round_sat_i34_o18_s14_s.hex";
`endif

  logic [IN_WIDTH-1:0]  in;
  logic [OUT_WIDTH-1:0] out;
  logic                 sat;

  round_sat #(.IN_WIDTH(IN_WIDTH), .OUT_WIDTH(OUT_WIDTH), .SHIFT(SHIFT), .SIGNED(SIGNED))
    dut (.in, .out, .sat);

  int n_vec = 0, n_err = 0, n_sat = 0;

  initial begin
    int fd, r;
    logic [IN_WIDTH-1:0] vi; logic [OUT_WIDTH-1:0] vo; logic vs;
    fd = $fopen(VEC_FILE, "r");
    if (fd == 0) $fatal(1, "cannot open %s", VEC_FILE);
    while (!$feof(fd) && n_vec < MAX_VEC) begin
      r = $fscanf(fd, "%h %h %h\n", vi, vo, vs);
      if (r != 3) $fatal(1, "malformed/truncated vector %0d in %s", n_vec, VEC_FILE);
      in = vi;
      #1 n_vec++;   // settle the combinational DUT, then check
      if (vs) n_sat++;
      if (out !== vo || sat !== vs) begin
        n_err++;
        if (n_err <= 10)
          $error("vec %0d: in=%h got out=%h sat=%b exp out=%h sat=%b", n_vec - 1, vi, out, sat, vo, vs);
      end
    end
    if (!$feof(fd)) $fatal(1, "vector limit exceeded: %0d", MAX_VEC);
    $fclose(fd);
    if (n_vec == 0) $fatal(1, "empty vector file: %s", VEC_FILE);
    if (n_err != 0) $fatal(1, "%0d round_sat comparison errors", n_err);
    $display("PASS: tb_round_sat IN=%0d OUT=%0d SHIFT=%0d SIGNED=%0d, %0d checked, 0 errors (sat on %0d)",
             IN_WIDTH, OUT_WIDTH, SHIFT, SIGNED, n_vec, n_sat);
    $finish;
  end
endmodule
