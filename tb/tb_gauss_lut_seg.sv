// Self-checking testbench for gauss_lut_seg (research). Streams every vector in
// tb/vectors/gauss_lut_a<ADDR_BITS>_w<OUT_WIDTH>_f<FRAC_BITS>.hex one per
// cycle and compares against the Python expectation after LATENCY cycles.
//
//   make sim [ADDR_BITS=.. OUT_WIDTH=.. FRAC_BITS=.. LATENCY=..]   (VCS, see Makefile)
`timescale 1ns/1ps
module tb_gauss_lut_seg;
  parameter int K = 12;
  parameter int OUT_WIDTH = 16;
  parameter int B = 4;
  parameter int LATENCY   = 1;
  parameter int MAX_VEC   = 1 << 16;
`ifdef VEC_FILE
  parameter string VEC_FILE = `VEC_FILE;
`else
  parameter string VEC_FILE = "tb/vectors/gauss_lut_seg_K12_B4.hex";
`endif

  logic clk = 0, rst_n = 0;
  logic in_valid = 0;
  logic [31:0] u = 0;
  logic out_valid;
  logic signed [OUT_WIDTH-1:0] z;

  gauss_lut_seg #(.K(K), .B(B), .OUT_WIDTH(OUT_WIDTH), .LATENCY(LATENCY))
    dut (.clk, .rst_n, .in_valid, .u, .out_valid, .z);

  always #5 clk = ~clk;

  logic [31:0]          vec_u [MAX_VEC];
  logic [OUT_WIDTH-1:0] vec_z [MAX_VEC];
  logic [OUT_WIDTH-1:0] exp_q [$];
  int n_vec = 0, n_chk = 0, n_err = 0;

  initial begin
    int fd, r; logic [31:0] uu; logic [OUT_WIDTH-1:0] zz;
    fd = $fopen(VEC_FILE, "r");
    if (fd == 0) begin $error("cannot open %s", VEC_FILE); $finish; end
    while (!$feof(fd) && n_vec < MAX_VEC) begin
      r = $fscanf(fd, "%h %h\n", uu, zz);
      if (r == 2) begin vec_u[n_vec] = uu; vec_z[n_vec] = zz; n_vec++; end
    end
    $fclose(fd);
    $display("loaded %0d vectors", n_vec);

    repeat (2) @(posedge clk);
    rst_n = 1;
    for (int i = 0; i < n_vec; i++) begin
      @(negedge clk);
      in_valid = 1; u = vec_u[i]; exp_q.push_back(vec_z[i]);
    end
    @(negedge clk); in_valid = 0;
    repeat (LATENCY + 2) @(posedge clk);
    $display("%s: tb_gauss_lut_seg K=%0d B=%0d L=%0d, %0d checked, %0d errors", n_err ? "FAIL" : "PASS", K, B, LATENCY, n_chk, n_err);
    $finish;
  end

  always @(posedge clk) if (rst_n && out_valid) begin
    logic [OUT_WIDTH-1:0] e;
    e = exp_q.pop_front();
    n_chk++;
    if (z !== $signed(e)) begin
      n_err++;
      if (n_err <= 10) $error("vec %0d: u=%h got z=%h exp %h", n_chk - 1, vec_u[n_chk - 1], z, e);
    end
  end
endmodule
