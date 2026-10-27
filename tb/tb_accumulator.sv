// Self-checking testbench for accumulator (LANES = 1). Applies one line of
// tb/vectors/accumulator_w<SUM_WIDTH>.hex per cycle and checks the registers
// after that clock edge against the Python expectation.
//
//   make sim-iv   (Icarus, local)       make sim-price   (VCS, lab)
`timescale 1ns/1ps
module tb_accumulator;
  parameter int SUM_WIDTH = 64;
  parameter int MAX_VEC   = 1 << 16;
`ifdef VEC_FILE
  parameter VEC_FILE = `VEC_FILE;
`else
  parameter VEC_FILE = "tb/vectors/accumulator_w64.hex";
`endif

  logic clk = 0, rst_n = 0;
  logic clear = 0;
  logic [0:0] p_valid = 0, sat_x = 0, sat_s = 0;
  logic [0:0][21:0] p = '0;
  logic [SUM_WIDTH-1:0] payoff_sum;
  logic [31:0] trial_count;
  logic acc_overflow, sat_x_seen, sat_s_seen;

  accumulator #(.LANES(1), .SUM_WIDTH(SUM_WIDTH)) dut (
    .clk, .rst_n, .clear, .p_valid, .p, .sat_x, .sat_s,
    .payoff_sum, .trial_count, .acc_overflow, .sat_x_seen, .sat_s_seen);

  always #5 clk = ~clk;

  logic        v_clr [MAX_VEC], v_val [MAX_VEC];
  logic [21:0] v_p   [MAX_VEC];
  logic [1:0]  v_f   [MAX_VEC];
  logic [63:0] e_sum [MAX_VEC];
  logic [31:0] e_cnt [MAX_VEC];
  logic [2:0]  e_flg [MAX_VEC];
  int n_vec = 0, n_err = 0, n_ovf = 0;

  initial begin
    int fd, r;
    logic c, v; logic [21:0] pp; logic [1:0] ff; logic [63:0] ss; logic [31:0] cc; logic [2:0] gg;
    fd = $fopen(VEC_FILE, "r");
    if (fd == 0) begin $display("FAIL: cannot open %s", VEC_FILE); $finish; end
    while (!$feof(fd) && n_vec < MAX_VEC) begin
      r = $fscanf(fd, "%h %h %h %h %h %h %h\n", c, v, pp, ff, ss, cc, gg);
      if (r == 7) begin
        v_clr[n_vec] = c; v_val[n_vec] = v; v_p[n_vec] = pp; v_f[n_vec] = ff;
        e_sum[n_vec] = ss; e_cnt[n_vec] = cc; e_flg[n_vec] = gg; n_vec++;
      end
    end
    $fclose(fd);
    $display("loaded %0d cycles from %s", n_vec, VEC_FILE);

    repeat (2) @(posedge clk);
    @(negedge clk) rst_n = 1;
    for (int i = 0; i < n_vec; i++) begin
      clear = v_clr[i]; p_valid = v_val[i]; p[0] = v_p[i];
      sat_x = v_f[i][0]; sat_s = v_f[i][1];
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
    $display("%s: tb_accumulator SUM_WIDTH=%0d, %0d cycles checked, %0d errors (overflow set on %0d cycles)",
             n_err ? "FAIL" : "PASS", SUM_WIDTH, n_vec, n_err, n_ovf);
    $finish;
  end
endmodule
