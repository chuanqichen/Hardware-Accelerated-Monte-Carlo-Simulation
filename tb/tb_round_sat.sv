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
    if (fd == 0) begin $error("cannot open %s", VEC_FILE); $finish; end
    while (!$feof(fd) && n_vec < MAX_VEC) begin
      r = $fscanf(fd, "%h %h %h\n", vi, vo, vs);
      if (r != 3) continue;
      in = vi;
      #1 n_vec++;   // settle the combinational DUT, then check
      if (vs) n_sat++;
      if (out !== vo || sat !== vs) begin
        n_err++;
        if (n_err <= 10)
          $error("vec %0d: in=%h got out=%h sat=%b exp out=%h sat=%b", n_vec - 1, vi, out, sat, vo, vs);
      end
    end
    $fclose(fd);
    $display("%s: tb_round_sat IN=%0d OUT=%0d SHIFT=%0d SIGNED=%0d, %0d checked, %0d errors (sat on %0d)",
             n_err ? "FAIL" : "PASS", IN_WIDTH, OUT_WIDTH, SHIFT, SIGNED, n_vec, n_err, n_sat);
    $finish;
  end
endmodule
