// Self-checking testbench for accumulator (LANES = 1, 2, 4, ...). Applies one line
// per cycle and checks the registers after that clock edge against the Python
// expectation (which already includes the adder-tree latency).
//
//   LANES = 1: tb/vectors/accumulator_w<SUM_WIDTH>.hex
//   LANES > 1: tb/vectors/accumulator_l<LANES>_w<SUM_WIDTH>.hex
//
// Line (hex): clear vmask p_packed f_packed exp_sum exp_cnt exp_flags
//   vmask     LANES bits, bit i = lane i valid
//   p_packed  LANES*22 bits, lane i in bits [22*i +: 22]
//   f_packed  2*LANES bits, lane i: bit 2*i = sat_x, bit 2*i+1 = sat_s
//   exp_flags {sat_s_seen, sat_x_seen, acc_overflow}
// For LANES = 1 this is the original one-lane format.
//
//   make sim-iv   (Icarus, local)       make sim-price   (VCS, lab)
`timescale 1ns/1ps
module tb_accumulator;
  parameter int LANES     = 1;
  parameter int SUM_WIDTH = 64;
  parameter int MAX_VEC   = 1 << 16;
`ifdef VEC_FILE
  parameter VEC_FILE = `VEC_FILE;
`else
  parameter VEC_FILE = "";           // empty: derive the name from LANES and SUM_WIDTH
`endif

  logic clk = 0, rst_n = 0;
  logic clear = 0;
  logic [LANES-1:0] p_valid = '0, sat_x = '0, sat_s = '0;
  logic [LANES-1:0][21:0] p = '0;
  logic [SUM_WIDTH-1:0] payoff_sum;
  logic [31:0] trial_count;
  logic acc_overflow, sat_x_seen, sat_s_seen;

  accumulator #(.LANES(LANES), .SUM_WIDTH(SUM_WIDTH), .REGISTER_TREE(LANES > 1)) dut (
    .clk, .rst_n, .clear, .p_valid, .p, .sat_x, .sat_s,
    .payoff_sum, .trial_count, .acc_overflow, .sat_x_seen, .sat_s_seen);

  always #5 clk = ~clk;

  logic                 v_clr [MAX_VEC];
  logic [LANES-1:0]     v_val [MAX_VEC];
  logic [22*LANES-1:0]  v_p   [MAX_VEC];
  logic [2*LANES-1:0]   v_f   [MAX_VEC];
  logic [63:0] e_sum [MAX_VEC];
  logic [31:0] e_cnt [MAX_VEC];
  logic [2:0]  e_flg [MAX_VEC];
  int n_vec = 0, n_err = 0, n_ovf = 0;

  initial begin
    int fd, r;
    string fname;
    logic c; logic [LANES-1:0] v; logic [22*LANES-1:0] pp; logic [2*LANES-1:0] ff;
    logic [63:0] ss; logic [31:0] cc; logic [2:0] gg;
    fname = VEC_FILE;
    if (fname == "") begin
      if (LANES == 1) fname = $sformatf("tb/vectors/accumulator_w%0d.hex", SUM_WIDTH);
      else            fname = $sformatf("tb/vectors/accumulator_l%0d_w%0d.hex", LANES, SUM_WIDTH);
    end
    fd = $fopen(fname, "r");
    if (fd == 0) begin $display("FAIL: cannot open %s", fname); $finish; end
    while (!$feof(fd) && n_vec < MAX_VEC) begin
      r = $fscanf(fd, "%h %h %h %h %h %h %h\n", c, v, pp, ff, ss, cc, gg);
      if (r == 7) begin
        v_clr[n_vec] = c; v_val[n_vec] = v; v_p[n_vec] = pp; v_f[n_vec] = ff;
        e_sum[n_vec] = ss; e_cnt[n_vec] = cc; e_flg[n_vec] = gg; n_vec++;
      end
    end
    $fclose(fd);
    $display("loaded %0d cycles from %s", n_vec, fname);

    repeat (2) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int i = 0; i < n_vec; i++) begin
      clear = v_clr[i]; p_valid = v_val[i];
      for (int l = 0; l < LANES; l++) begin
        p[l]     = v_p[i][22*l +: 22];
        sat_x[l] = v_f[i][2*l];
        sat_s[l] = v_f[i][2*l+1];
      end
      @(negedge clk);                    // registers updated on the posedge in between
      if (payoff_sum !== e_sum[i][SUM_WIDTH-1:0] || trial_count !== e_cnt[i] ||
          {sat_s_seen, sat_x_seen, acc_overflow} !== e_flg[i]) begin
        n_err++;
        if (n_err <= 10)
          $display("ERROR cycle %0d: got sum=%h cnt=%0d flags=%b, exp sum=%h cnt=%0d flags=%b",
                   i, payoff_sum, trial_count, {sat_s_seen, sat_x_seen, acc_overflow},
                   e_sum[i][SUM_WIDTH-1:0], e_cnt[i], e_flg[i]);
      end
      if (acc_overflow) n_ovf++;
    end
    $display("%s: tb_accumulator LANES=%0d SUM_WIDTH=%0d, %0d cycles checked, %0d errors (overflow set on %0d cycles)",
             (n_err || n_vec == 0) ? "FAIL" : "PASS", LANES, SUM_WIDTH, n_vec, n_err, n_ovf);
    $finish;
  end
endmodule
