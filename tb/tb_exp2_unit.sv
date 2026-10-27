// Exhaustive self-checking testbench for exp2_unit: every one of the 2^18 x
// values from tb/vectors/exp2_k<K>.hex, streamed with random valid gaps, checked
// in order against the Python expectation (S_T and sat_s) and the latency.
//
//   make sim-iv   (Icarus, local)       make sim-price   (VCS, lab)
`timescale 1ns/1ps
module tb_exp2_unit;
  parameter int EXP_ADDR_BITS = 10;
  parameter int N_VEC = 1 << 18;
`ifdef VEC_FILE
  parameter VEC_FILE = `VEC_FILE;
`else
  parameter VEC_FILE = "tb/vectors/exp2_k10.hex";
`endif
  localparam int LAT_EXP = 3;

  logic clk = 0, rst_n = 0;
  logic in_valid = 0;
  logic signed [17:0] x = 0;
  logic out_valid, sat_s;
  logic [21:0] s_t;

  exp2_unit #(.EXP_ADDR_BITS(EXP_ADDR_BITS)) dut (.clk, .rst_n, .in_valid, .x, .out_valid, .s_t, .sat_s);

  always #5 clk = ~clk;

  logic [17:0] v_x  [N_VEC];
  logic [21:0] e_st [N_VEC];
  logic        e_sat[N_VEC];
  int issue_cyc [N_VEC];
  int n_vec = 0, n_chk = 0, n_err = 0, n_sat = 0, n_sat_exp = 0, cyc = 0;
  int seed = 382;

  always @(posedge clk) cyc <= cyc + 1;

  initial begin
    int fd, r; logic [17:0] xx; logic [21:0] ss; logic ff;
    fd = $fopen(VEC_FILE, "r");
    if (fd == 0) begin $display("FAIL: cannot open %s", VEC_FILE); $finish; end
    while (!$feof(fd) && n_vec < N_VEC) begin
      r = $fscanf(fd, "%h %h %h\n", xx, ss, ff);
      if (r == 3) begin v_x[n_vec] = xx; e_st[n_vec] = ss; e_sat[n_vec] = ff; n_sat_exp += ff; n_vec++; end
    end
    $fclose(fd);
    $display("loaded %0d vectors from %s", n_vec, VEC_FILE);

    repeat (2) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int i = 0; i < n_vec; i++) begin
      while (($random(seed) & 7) == 0) begin   // ~1 in 8 cycles idle
        @(negedge clk) in_valid = 0; x = 'x;   // invalid cycles carry garbage
      end
      @(negedge clk) in_valid = 1; x = v_x[i];
      issue_cyc[i] = cyc;
    end
    @(negedge clk) in_valid = 0;
    repeat (LAT_EXP + 2) @(posedge clk);
    if (n_chk != n_vec) begin n_err++; $display("ERROR: %0d outputs for %0d inputs", n_chk, n_vec); end
    if (n_sat != n_sat_exp) begin n_err++; $display("ERROR: sat_s count %0d, expected %0d", n_sat, n_sat_exp); end
    $display("%s: tb_exp2_unit k=%0d, %0d checked, %0d errors, sat_s pulses %0d (expected %0d)",
             n_err ? "FAIL" : "PASS", EXP_ADDR_BITS, n_chk, n_err, n_sat, n_sat_exp);
    $finish;
  end

  always @(posedge clk) if (rst_n && out_valid) begin
    if (s_t !== e_st[n_chk] || sat_s !== e_sat[n_chk] || cyc - issue_cyc[n_chk] != LAT_EXP) begin
      n_err++;
      if (n_err <= 10)
        $display("ERROR vec %0d: x=%h got S_T=%h sat=%b, exp S_T=%h sat=%b, latency %0d",
                 n_chk, v_x[n_chk], s_t, sat_s, e_st[n_chk], e_sat[n_chk], cyc - issue_cyc[n_chk]);
    end
    n_sat += sat_s;
    n_chk++;
  end
endmodule
