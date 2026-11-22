// Synthesis-only wrapper for the z-width study (Lane_Interface_Spec decision D-4).
// Not part of the design and never simulated as a product block.
//
// price_dp takes z as Q3.12 (16 bits). A Q3.(12 - Z_DROP) sample has its low
// Z_DROP fraction bits equal to zero, so tying those bits to 0 here lets Design
// Compiler shrink the B*z multiplier to the narrower width while everything
// after it stays the same. Z_DROP = 0 is the 16-bit baseline through the same
// wrapper; Z_DROP = 4 is the 12-bit Q3.8 option.
//
//   DESIGN=price_dp_zstudy PARAMS="Z_DROP=4" RTL_FILES="rtl/mc_pkg.sv rtl/round_sat.sv
//     rtl/pipe.sv rtl/generated/exp2_rom.sv rtl/exp2_unit.sv rtl/price_dp.sv
//     scripts/syn/study/price_dp_zstudy.sv" dc_shell -f scripts/syn/dc_synth.tcl
module price_dp_zstudy #(
  parameter int Z_DROP = 0
) (
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic signed [17:0]        a,
  input  logic        [15:0]        b,
  input  logic        [21:0]        k,
  input  logic                      z_valid,
  input  logic signed [15-Z_DROP:0] z,
  output logic                      p_valid,
  output logic        [21:0]        p,
  output logic                      sat_x,
  output logic                      sat_s
);
  logic signed [15:0] z16;
  assign z16 = $signed({z, {Z_DROP{1'b0}}});
  price_dp u_dp (.clk, .rst_n, .a, .b, .k, .z_valid, .z(z16), .p_valid, .p, .sat_x, .sat_s);
endmodule
