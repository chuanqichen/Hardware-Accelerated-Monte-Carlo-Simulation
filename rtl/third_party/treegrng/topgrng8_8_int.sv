// GENERATED from topgrng8_8.sv for Design Compiler: real-valued threshold parameters
// replaced by the integers Verilog truncates them to (int(frac * 2^L)). Logic unchanged.
// Module renamed compGRNG_int. See docs/research/treegrng_study.md.
//`include "GRNG/GRNG_pBit_simplified.sv"
//`include "LFSR/LFSR.sv"
//`include "LFSR/LFSR_propability.sv"

module  compGRNG_int #(parameter BITNUMS = 8) (input clk, input LD_seed, 
    output[7:0] result
);


wire pBit7;
wire pBit6;
wire[1:0] pBit5;
wire[3:0] pBit4;
wire[7:0] pBit3;
wire[15:0] pBit2;
wire[15:0] pBit1;
wire[7:0] pBit0;


wire[BITNUMS-1:0] unfilteredLFSR7;
wire LFSR7Done;
LFSR #(.NUM_BITS(BITNUMS)) LFSR7(clk, 1'b1, LD_seed, 8'b10101011, unfilteredLFSR7, LFSR7Done);
propabmaker #(.L2N(BITNUMS),.T(8'd128)) prop71(unfilteredLFSR7,pBit7);

wire[BITNUMS:0] unfilteredLFSR6;
wire LFSR6Done;
LFSR #(.NUM_BITS(BITNUMS+1)) LFSR6(clk, 1'b1, LD_seed, 9'b110011010, unfilteredLFSR6, LFSR6Done);
propabmaker #(.L2N(BITNUMS+1), .T(9'd23)) prob61(unfilteredLFSR6, pBit6);

wire[BITNUMS+1:0] unfilteredLFSR5;
wire LFSR5Done;
LFSR #(.NUM_BITS(BITNUMS+2)) LFSR5(clk, 1'b1, LD_seed, 10'b0010110110, unfilteredLFSR5, LFSR5Done);
propabmaker #(.L2N(BITNUMS+2), .T(10'd291))prob51(unfilteredLFSR5, pBit5[1]);
propabmaker #(.L2N(BITNUMS+2), .T(10'd59)) prob50(unfilteredLFSR5, pBit5[0]);

wire[BITNUMS-2:0] unfilteredLFSR4;
wire LFSR4Done;
LFSR #(.NUM_BITS(BITNUMS-1)) LFSR4(clk, 1'b1, LD_seed, 7'b1010110, unfilteredLFSR4, LFSR4Done);
propabmaker #(.L2N(BITNUMS-1), .T(7'd56)) prob43(unfilteredLFSR4, pBit4[3]);
propabmaker #(.L2N(BITNUMS-1), .T(7'd41)) prob42(unfilteredLFSR4, pBit4[2]);
propabmaker #(.L2N(BITNUMS-1), .T(7'd29)) prob41(unfilteredLFSR4, pBit4[1]);
propabmaker #(.L2N(BITNUMS-1), .T(7'd19)) prob40(unfilteredLFSR4, pBit4[0]);

wire[BITNUMS-1:0] unfilteredLFSR3;
wire LFSR3Done;
LFSR #(.NUM_BITS(BITNUMS)) LFSR3(clk, 1'b1, LD_seed, 8'b11010110, unfilteredLFSR3, LFSR3Done);
propabmaker #(.L2N(BITNUMS), .T(8'd124)) prob37(unfilteredLFSR3, pBit3[7]);
propabmaker #(.L2N(BITNUMS), .T(8'd116)) prob36(unfilteredLFSR3, pBit3[6]);
propabmaker #(.L2N(BITNUMS), .T(8'd108)) prob35(unfilteredLFSR3, pBit3[5]);
propabmaker #(.L2N(BITNUMS), .T(8'd100)) prob34(unfilteredLFSR3, pBit3[4]);
propabmaker #(.L2N(BITNUMS), .T(8'd93)) prob33(unfilteredLFSR3, pBit3[3]);
propabmaker #(.L2N(BITNUMS), .T(8'd85)) prob32(unfilteredLFSR3, pBit3[2]);
propabmaker #(.L2N(BITNUMS), .T(8'd78)) prob31(unfilteredLFSR3, pBit3[1]);
propabmaker #(.L2N(BITNUMS), .T(8'd72)) prob30(unfilteredLFSR3, pBit3[0]);

wire[BITNUMS:0] unfilteredLFSR2;
wire LFSR2Done;
LFSR #(.NUM_BITS(BITNUMS+1)) LFSR2(clk, 1'b1, LD_seed, 9'b100101001, unfilteredLFSR2, LFSR2Done);
propabmaker #(.L2N(BITNUMS+1), .T(9'd254)) prob215(unfilteredLFSR2, pBit2[15]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd250)) prob214(unfilteredLFSR2, pBit2[14]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd246)) prob213(unfilteredLFSR2, pBit2[13]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd242)) prob212(unfilteredLFSR2, pBit2[12]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd238)) prob211(unfilteredLFSR2, pBit2[11]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd234)) prob210(unfilteredLFSR2, pBit2[10]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd230)) prob29(unfilteredLFSR2, pBit2[9]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd226)) prob28(unfilteredLFSR2, pBit2[8]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd222)) prob27(unfilteredLFSR2, pBit2[7]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd218)) prob26(unfilteredLFSR2, pBit2[6]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd214)) prob25(unfilteredLFSR2, pBit2[5]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd210)) prob24(unfilteredLFSR2, pBit2[4]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd206)) prob23(unfilteredLFSR2, pBit2[3]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd202)) prob22(unfilteredLFSR2, pBit2[2]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd198)) prob21(unfilteredLFSR2, pBit2[1]);
propabmaker #(.L2N(BITNUMS+1), .T(9'd195)) prob20(unfilteredLFSR2, pBit2[0]);

wire[BITNUMS-2:0] unfilteredLFSR1;
wire LFSR1Done;
LFSR #(.NUM_BITS(BITNUMS-1)) LFSR1(clk, 1'b1, LD_seed, 7'b0011010, unfilteredLFSR1, LFSR1Done);
assign pBit1[15] = !unfilteredLFSR1[0];
assign pBit1[14] = pBit1[13];
propabmaker #(.L2N(BITNUMS-1), .T(7'd62)) prob113(unfilteredLFSR1, pBit1[13]);
assign pBit1[12] = pBit1[11];
propabmaker #(.L2N(BITNUMS-1), .T(7'd61)) prob111(unfilteredLFSR1, pBit1[11]);
assign pBit1[10] = pBit1[9];
propabmaker #(.L2N(BITNUMS-1), .T(7'd61)) prob19(unfilteredLFSR1, pBit1[9]);
assign pBit1[8] = pBit1[7];
propabmaker #(.L2N(BITNUMS-1), .T(7'd59)) prob17(unfilteredLFSR1, pBit1[7]);
assign pBit1[6] = pBit1[5];
propabmaker #(.L2N(BITNUMS-1), .T(7'd59)) prob15(unfilteredLFSR1, pBit1[5]);
assign pBit1[4] = pBit1[3];
propabmaker #(.L2N(BITNUMS-1), .T(7'd57)) prob13(unfilteredLFSR1, pBit1[3]);
assign pBit1[2] = pBit1[1];
propabmaker #(.L2N(BITNUMS-1), .T(7'd56)) prob11(unfilteredLFSR1, pBit1[1]);
propabmaker #(.L2N(BITNUMS-1), .T(7'd56)) prob10(unfilteredLFSR1, pBit1[0]);

wire[BITNUMS+1:0] unfilteredLFSR0;
wire LFSR0Done;
LFSR #(.NUM_BITS(BITNUMS+2)) LFSR0(clk, 1'b1, LD_seed, 10'b1001111010, unfilteredLFSR0, LFSR0Done);
assign pBit0[7] = !unfilteredLFSR0[0];
propabmaker #(.L2N(BITNUMS+2), .T(10'd506)) prob06(unfilteredLFSR0, pBit0[6]);
propabmaker #(.L2N(BITNUMS+2), .T(10'd501)) prob05(unfilteredLFSR0, pBit0[5]);
assign pBit0[4] = pBit0[3];
propabmaker #(.L2N(BITNUMS+2), .T(10'd494)) prob03(unfilteredLFSR0, pBit0[3]);
assign pBit0[2] = pBit0[1];
propabmaker #(.L2N(BITNUMS+2), .T(10'd486)) prob01(unfilteredLFSR0, pBit0[1]);
propabmaker #(.L2N(BITNUMS+2), .T(10'd481)) prob00(unfilteredLFSR0, pBit0[0]); 


gaussianSimplified8 gauss(pBit7, pBit6, pBit5, pBit4, pBit3, pBit2, pBit1, pBit0, result);

    
endmodule
