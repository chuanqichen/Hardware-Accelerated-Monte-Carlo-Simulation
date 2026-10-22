// Self-checking testbench for price_dp. Reads tb/vectors/price_dp_k<K>.hex:
//   "0 aaaaa bbbb kkkkkk"  new configuration -> drain the pipeline, then load A, B, K
//   "1 zzzz pppppp f"      trial -> drive z, expect p and flags {sat_s, sat_x}
// Trials are streamed with random valid gaps. Every output is checked in order
// for p, both flags and exact latency (LAT_DP); sat pulses are counted and the
// totals compared with the vector file.
//
//   make sim-iv   (Icarus, local)       make sim-price   (VCS, lab)
`timescale 1ns/1ps
module tb_price_dp;
  parameter int EXP_ADDR_BITS = 10;
  parameter int MUL_STAGES    = 1;
  parameter int MAX_VEC       = 1 << 15;
`ifdef VEC_FILE
  parameter VEC_FILE = `VEC_FILE;
`else
  parameter VEC_FILE = "tb/vectors/price_dp_k10.hex";
`endif
  localparam int LAT_DP = MUL_STAGES + 5;

  logic clk = 0, rst_n = 0;
  logic signed [17:0] a = 0;
  logic [15:0] b = 0;
  logic [21:0] k = 0;
  logic z_valid = 0;
  logic signed [15:0] z = 0;
  logic p_valid, sat_x, sat_s;
  logic [21:0] p;

  price_dp #(.EXP_ADDR_BITS(EXP_ADDR_BITS), .MUL_STAGES(MUL_STAGES)) dut (
    .clk, .rst_n, .a, .b, .k, .z_valid, .z, .p_valid, .p, .sat_x, .sat_s);

  always #5 clk = ~clk;

  logic        v_tag [MAX_VEC];
  logic [21:0] v_f1  [MAX_VEC], v_f2 [MAX_VEC], v_f3 [MAX_VEC];
  logic [21:0] e_p   [MAX_VEC];
  logic [1:0]  e_f   [MAX_VEC];
  logic [15:0] t_z   [MAX_VEC];
  int issue_cyc [MAX_VEC];
  int n_line = 0, n_trial = 0, n_chk = 0, n_err = 0, cyc = 0, seed = 382;
  int n_sx = 0, n_ss = 0, n_sx_exp = 0, n_ss_exp = 0;

  always @(posedge clk) cyc <= cyc + 1;

  initial begin
    int fd, r, t; logic tg; logic [21:0] f1, f2, f3;
    fd = $fopen(VEC_FILE, "r");
    if (fd == 0) begin $display("FAIL: cannot open %s", VEC_FILE); $finish; end
    while (!$feof(fd) && n_line < MAX_VEC) begin
      r = $fscanf(fd, "%h %h %h %h\n", tg, f1, f2, f3);
      if (r == 4) begin v_tag[n_line] = tg; v_f1[n_line] = f1; v_f2[n_line] = f2; v_f3[n_line] = f3; n_line++; end
    end
    $fclose(fd);
    $display("loaded %0d lines from %s", n_line, VEC_FILE);

    repeat (2) @(posedge clk);
    @(negedge clk) rst_n = 1;
    t = 0;
    for (int i = 0; i < n_line; i++) begin
      if (v_tag[i] == 0) begin
        @(negedge clk) z_valid = 0; z = 'x;
        repeat (LAT_DP + 1) @(negedge clk);      // drain: config is static during a run
        a = v_f1[i][17:0]; b = v_f2[i][15:0]; k = v_f3[i];
      end else begin
        while (($random(seed) & 7) == 0) begin   // ~1 in 8 cycles idle, with garbage on z
          @(negedge clk) z_valid = 0; z = 'x;
        end
        @(negedge clk) z_valid = 1; z = v_f1[i][15:0];
        t_z[t] = v_f1[i][15:0]; e_p[t] = v_f2[i]; e_f[t] = v_f3[i][1:0];
        n_sx_exp += v_f3[i][0]; n_ss_exp += v_f3[i][1];
        issue_cyc[t] = cyc;
        t++;
      end
    end
    n_trial = t;
    @(negedge clk) z_valid = 0;
    repeat (LAT_DP + 2) @(posedge clk);
    if (n_chk != n_trial) begin n_err++; $display("ERROR: %0d outputs for %0d trials", n_chk, n_trial); end
    if (n_sx != n_sx_exp || n_ss != n_ss_exp) begin
      n_err++; $display("ERROR: sat counts x=%0d s=%0d, expected x=%0d s=%0d", n_sx, n_ss, n_sx_exp, n_ss_exp);
    end
    $display("%s: tb_price_dp k=%0d MUL_STAGES=%0d LAT_DP=%0d, %0d trials checked, %0d errors",
             n_err ? "FAIL" : "PASS", EXP_ADDR_BITS, MUL_STAGES, LAT_DP, n_chk, n_err);
    $display("      saturation events: sat_x %0d (expected %0d), sat_s %0d (expected %0d)",
             n_sx, n_sx_exp, n_ss, n_ss_exp);
    $finish;
  end

  always @(posedge clk) if (rst_n) begin
    if (!p_valid && (sat_x || sat_s)) begin
      n_err++; $display("ERROR: sat pulse without p_valid at cycle %0d", cyc);
    end
    if (p_valid) begin
      if (p !== e_p[n_chk] || {sat_s, sat_x} !== e_f[n_chk] || cyc - issue_cyc[n_chk] != LAT_DP) begin
        n_err++;
        if (n_err <= 10)
          $display("ERROR trial %0d: a=%h b=%h k=%h z=%h got p=%h f=%b, exp p=%h f=%b, latency %0d",
                   n_chk, a, b, k, t_z[n_chk], p, {sat_s, sat_x}, e_p[n_chk], e_f[n_chk],
                   cyc - issue_cyc[n_chk]);
      end
      n_sx += sat_x;
      n_ss += sat_s;
      n_chk++;
    end
  end
endmodule
