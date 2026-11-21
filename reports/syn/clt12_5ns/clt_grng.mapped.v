/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : T-2022.03-SP2
// Date      : Sat Nov 21 15:51:19 2026
/////////////////////////////////////////////////////////////


module clt_grng ( clk, rst_n, in_valid, words, out_valid, z );
  input [143:0] words;
  output [15:0] z;
  input clk, rst_n, in_valid;
  output out_valid;
  wire   n122, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29, n30,
         n31, n32, n33, intadd_0_A_11_, intadd_0_A_10_, intadd_0_A_9_,
         intadd_0_A_8_, intadd_0_A_7_, intadd_0_A_6_, intadd_0_A_5_,
         intadd_0_A_4_, intadd_0_A_3_, intadd_0_A_2_, intadd_0_A_1_,
         intadd_0_B_4_, intadd_0_B_3_, intadd_0_B_2_, intadd_0_B_1_,
         intadd_0_B_0_, intadd_0_CI, intadd_0_SUM_11_, intadd_0_SUM_10_,
         intadd_0_SUM_9_, intadd_0_SUM_8_, intadd_0_SUM_7_, intadd_0_SUM_6_,
         intadd_0_SUM_5_, intadd_0_SUM_4_, intadd_0_SUM_3_, intadd_0_SUM_2_,
         intadd_0_SUM_1_, intadd_0_SUM_0_, intadd_0_n12, intadd_0_n11,
         intadd_0_n10, intadd_0_n9, intadd_0_n8, intadd_0_n7, intadd_0_n6,
         intadd_0_n5, intadd_0_n4, intadd_0_n3, intadd_0_n2, intadd_0_n1,
         intadd_1_A_5_, intadd_1_A_4_, intadd_1_A_3_, intadd_1_A_2_,
         intadd_1_A_1_, intadd_1_B_5_, intadd_1_B_3_, intadd_1_B_2_,
         intadd_1_B_1_, intadd_1_SUM_5_, intadd_1_SUM_4_, intadd_1_SUM_3_,
         intadd_1_SUM_2_, intadd_1_SUM_1_, intadd_1_SUM_0_, intadd_1_n6,
         intadd_1_n5, intadd_1_n4, intadd_1_n3, intadd_1_n2, intadd_1_n1,
         intadd_2_A_4_, intadd_2_A_3_, intadd_2_A_2_, intadd_2_A_1_,
         intadd_2_B_4_, intadd_2_B_2_, intadd_2_B_1_, intadd_2_SUM_3_,
         intadd_2_SUM_2_, intadd_2_SUM_1_, intadd_2_SUM_0_, intadd_2_n5,
         intadd_2_n4, intadd_2_n3, intadd_2_n2, intadd_2_n1, intadd_3_A_3_,
         intadd_3_A_1_, intadd_3_B_4_, intadd_3_B_2_, intadd_3_B_1_,
         intadd_3_SUM_3_, intadd_3_SUM_2_, intadd_3_SUM_1_, intadd_3_SUM_0_,
         intadd_3_n5, intadd_3_n4, intadd_3_n3, intadd_3_n2, intadd_3_n1,
         intadd_4_A_3_, intadd_4_A_1_, intadd_4_B_2_, intadd_4_B_1_,
         intadd_4_SUM_3_, intadd_4_SUM_2_, intadd_4_SUM_1_, intadd_4_SUM_0_,
         intadd_4_n5, intadd_4_n4, intadd_4_n3, intadd_4_n2, intadd_4_n1,
         intadd_5_A_3_, intadd_5_A_1_, intadd_5_B_2_, intadd_5_B_1_,
         intadd_5_SUM_3_, intadd_5_SUM_2_, intadd_5_SUM_1_, intadd_5_SUM_0_,
         intadd_5_n5, intadd_5_n4, intadd_5_n3, intadd_5_n2, intadd_5_n1,
         intadd_6_A_3_, intadd_6_A_1_, intadd_6_B_2_, intadd_6_B_1_,
         intadd_6_SUM_3_, intadd_6_SUM_2_, intadd_6_SUM_1_, intadd_6_SUM_0_,
         intadd_6_n5, intadd_6_n4, intadd_6_n3, intadd_6_n2, intadd_6_n1,
         intadd_7_A_3_, intadd_7_A_1_, intadd_7_B_2_, intadd_7_B_1_,
         intadd_7_SUM_3_, intadd_7_SUM_0_, intadd_7_n5, intadd_7_n4,
         intadd_7_n3, intadd_7_n2, intadd_7_n1, intadd_8_A_3_, intadd_8_A_2_,
         intadd_8_A_1_, intadd_8_B_3_, intadd_8_B_2_, intadd_8_B_1_,
         intadd_8_SUM_2_, intadd_8_SUM_1_, intadd_8_SUM_0_, intadd_8_n5,
         intadd_8_n4, intadd_8_n3, intadd_8_n2, intadd_8_n1, intadd_9_A_2_,
         intadd_9_B_1_, intadd_9_SUM_0_, intadd_9_n5, intadd_9_n4, intadd_9_n3,
         intadd_9_n2, intadd_9_n1, intadd_10_A_3_, intadd_10_A_1_,
         intadd_10_B_3_, intadd_10_B_0_, intadd_10_CI, intadd_10_SUM_3_,
         intadd_10_SUM_2_, intadd_10_SUM_1_, intadd_10_SUM_0_, intadd_10_n4,
         intadd_10_n3, intadd_10_n2, intadd_10_n1, intadd_11_A_2_,
         intadd_11_A_1_, intadd_11_B_2_, intadd_11_SUM_2_, intadd_11_SUM_1_,
         intadd_11_SUM_0_, intadd_11_n4, intadd_11_n3, intadd_11_n2,
         intadd_11_n1, intadd_12_A_2_, intadd_12_A_1_, intadd_12_B_2_,
         intadd_12_B_1_, intadd_12_SUM_0_, intadd_12_n3, intadd_12_n2,
         intadd_12_n1, intadd_13_A_2_, intadd_13_A_1_, intadd_13_B_2_,
         intadd_13_B_1_, intadd_13_n3, intadd_13_n2, intadd_13_n1,
         intadd_14_A_2_, intadd_14_B_1_, intadd_14_n3, intadd_14_n2,
         intadd_14_n1, intadd_15_A_2_, intadd_15_A_1_, intadd_15_B_1_,
         intadd_15_SUM_0_, intadd_15_n3, intadd_15_n2, intadd_15_n1,
         intadd_16_A_2_, intadd_16_A_1_, intadd_16_B_1_, intadd_16_n3,
         intadd_16_n2, intadd_16_n1, intadd_17_A_2_, intadd_17_A_1_,
         intadd_17_B_1_, intadd_17_n3, intadd_17_n2, intadd_17_n1,
         intadd_18_A_2_, intadd_18_A_1_, intadd_18_B_1_, intadd_18_n3,
         intadd_18_n2, intadd_18_n1, intadd_19_A_2_, intadd_19_A_1_,
         intadd_19_B_1_, intadd_19_n3, intadd_19_n2, intadd_19_n1,
         intadd_20_A_2_, intadd_20_A_1_, intadd_20_B_2_, intadd_20_B_1_,
         intadd_20_n3, intadd_20_n2, intadd_20_n1, n35, n36, n37, n38, n39,
         n40, n41, n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52, n53,
         n54, n55, n56, n57, n58, n60, n61, n62, n63, n64, n65, n66, n67, n68,
         n69, n70, n71, n72, n73, n74, n75, n76, n77, n78, n79, n80, n81, n82,
         n83, n84, n85, n86, n87, n88, n89, n90, n91, n92, n93, n94, n95, n96,
         n97, n98, n99, n100, n101, n102, n103, n104, n105, n106, n107, n108,
         n109, n110, n111, n112, n113, n114, n115, n116, n117, n118, n119,
         n120, n121;

  DFFSR out_valid_reg ( .D(in_valid), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n122)
         );
  DFFPOSX1 z_reg_15_ ( .D(n36), .CLK(clk), .Q(z[15]) );
  DFFPOSX1 z_reg_14_ ( .D(n32), .CLK(clk), .Q(z[14]) );
  DFFPOSX1 z_reg_13_ ( .D(n39), .CLK(clk), .Q(z[13]) );
  DFFPOSX1 z_reg_12_ ( .D(n30), .CLK(clk), .Q(z[12]) );
  DFFPOSX1 z_reg_11_ ( .D(n29), .CLK(clk), .Q(z[11]) );
  DFFPOSX1 z_reg_10_ ( .D(n28), .CLK(clk), .Q(z[10]) );
  DFFPOSX1 z_reg_9_ ( .D(n27), .CLK(clk), .Q(z[9]) );
  DFFPOSX1 z_reg_8_ ( .D(n26), .CLK(clk), .Q(z[8]) );
  DFFPOSX1 z_reg_7_ ( .D(n25), .CLK(clk), .Q(z[7]) );
  DFFPOSX1 z_reg_6_ ( .D(n24), .CLK(clk), .Q(z[6]) );
  DFFPOSX1 z_reg_5_ ( .D(n23), .CLK(clk), .Q(z[5]) );
  DFFPOSX1 z_reg_4_ ( .D(n42), .CLK(clk), .Q(z[4]) );
  DFFPOSX1 z_reg_3_ ( .D(n21), .CLK(clk), .Q(z[3]) );
  DFFPOSX1 z_reg_2_ ( .D(n43), .CLK(clk), .Q(z[2]) );
  DFFPOSX1 z_reg_1_ ( .D(n44), .CLK(clk), .Q(z[1]) );
  DFFPOSX1 z_reg_0_ ( .D(n18), .CLK(clk), .Q(z[0]) );
  FAX1 intadd_0_U13 ( .A(intadd_0_B_0_), .B(words[37]), .C(intadd_0_CI), .YC(
        intadd_0_n12), .YS(intadd_0_SUM_0_) );
  FAX1 intadd_0_U12 ( .A(intadd_0_B_1_), .B(intadd_0_A_1_), .C(intadd_0_n12), 
        .YC(intadd_0_n11), .YS(intadd_0_SUM_1_) );
  FAX1 intadd_0_U11 ( .A(intadd_0_B_2_), .B(intadd_0_A_2_), .C(intadd_0_n11), 
        .YC(intadd_0_n10), .YS(intadd_0_SUM_2_) );
  FAX1 intadd_0_U10 ( .A(intadd_0_B_3_), .B(intadd_0_A_3_), .C(intadd_0_n10), 
        .YC(intadd_0_n9), .YS(intadd_0_SUM_3_) );
  FAX1 intadd_0_U9 ( .A(intadd_0_B_4_), .B(intadd_0_A_4_), .C(intadd_0_n9), 
        .YC(intadd_0_n8), .YS(intadd_0_SUM_4_) );
  FAX1 intadd_0_U8 ( .A(intadd_8_n1), .B(intadd_0_A_5_), .C(intadd_0_n8), .YC(
        intadd_0_n7), .YS(intadd_0_SUM_5_) );
  FAX1 intadd_0_U7 ( .A(intadd_7_n1), .B(intadd_0_A_6_), .C(intadd_0_n7), .YC(
        intadd_0_n6), .YS(intadd_0_SUM_6_) );
  FAX1 intadd_0_U6 ( .A(intadd_6_n1), .B(intadd_0_A_7_), .C(intadd_0_n6), .YC(
        intadd_0_n5), .YS(intadd_0_SUM_7_) );
  FAX1 intadd_0_U5 ( .A(intadd_5_n1), .B(intadd_0_A_8_), .C(intadd_0_n5), .YC(
        intadd_0_n4), .YS(intadd_0_SUM_8_) );
  FAX1 intadd_0_U4 ( .A(intadd_4_n1), .B(intadd_0_A_9_), .C(intadd_0_n4), .YC(
        intadd_0_n3), .YS(intadd_0_SUM_9_) );
  FAX1 intadd_0_U3 ( .A(intadd_3_n1), .B(intadd_0_A_10_), .C(intadd_0_n3), 
        .YC(intadd_0_n2), .YS(intadd_0_SUM_10_) );
  FAX1 intadd_0_U2 ( .A(intadd_2_n1), .B(intadd_0_A_11_), .C(intadd_0_n2), 
        .YC(intadd_0_n1), .YS(intadd_0_SUM_11_) );
  FAX1 intadd_1_U7 ( .A(words[129]), .B(words[81]), .C(words[105]), .YC(
        intadd_1_n6), .YS(intadd_1_SUM_0_) );
  FAX1 intadd_1_U6 ( .A(intadd_1_B_1_), .B(intadd_1_A_1_), .C(intadd_1_n6), 
        .YC(intadd_1_n5), .YS(intadd_1_SUM_1_) );
  FAX1 intadd_1_U5 ( .A(intadd_1_B_2_), .B(intadd_1_A_2_), .C(intadd_1_n5), 
        .YC(intadd_1_n4), .YS(intadd_1_SUM_2_) );
  FAX1 intadd_1_U4 ( .A(intadd_1_B_3_), .B(intadd_1_A_3_), .C(intadd_1_n4), 
        .YC(intadd_1_n3), .YS(intadd_1_SUM_3_) );
  FAX1 intadd_1_U3 ( .A(intadd_20_n1), .B(intadd_1_A_4_), .C(intadd_1_n3), 
        .YC(intadd_1_n2), .YS(intadd_1_SUM_4_) );
  FAX1 intadd_1_U2 ( .A(intadd_1_B_5_), .B(intadd_1_A_5_), .C(intadd_1_n2), 
        .YC(intadd_1_n1), .YS(intadd_1_SUM_5_) );
  FAX1 intadd_2_U6 ( .A(words[55]), .B(words[31]), .C(words[139]), .YC(
        intadd_2_n5), .YS(intadd_2_SUM_0_) );
  FAX1 intadd_2_U5 ( .A(intadd_2_B_1_), .B(intadd_2_A_1_), .C(intadd_2_n5), 
        .YC(intadd_2_n4), .YS(intadd_2_SUM_1_) );
  FAX1 intadd_2_U4 ( .A(intadd_2_B_2_), .B(intadd_2_A_2_), .C(intadd_2_n4), 
        .YC(intadd_2_n3), .YS(intadd_2_SUM_2_) );
  FAX1 intadd_2_U3 ( .A(intadd_19_n1), .B(intadd_2_A_3_), .C(intadd_2_n3), 
        .YC(intadd_2_n2), .YS(intadd_2_SUM_3_) );
  FAX1 intadd_2_U2 ( .A(intadd_2_B_4_), .B(intadd_2_A_4_), .C(intadd_2_n2), 
        .YC(intadd_2_n1), .YS(intadd_0_A_10_) );
  FAX1 intadd_3_U6 ( .A(words[54]), .B(words[30]), .C(words[138]), .YC(
        intadd_3_n5), .YS(intadd_3_SUM_0_) );
  FAX1 intadd_3_U5 ( .A(intadd_3_B_1_), .B(intadd_3_A_1_), .C(intadd_3_n5), 
        .YC(intadd_3_n4), .YS(intadd_3_SUM_1_) );
  FAX1 intadd_3_U4 ( .A(intadd_3_B_2_), .B(intadd_2_SUM_1_), .C(intadd_3_n4), 
        .YC(intadd_3_n3), .YS(intadd_3_SUM_2_) );
  FAX1 intadd_3_U3 ( .A(intadd_18_n1), .B(intadd_3_A_3_), .C(intadd_3_n3), 
        .YC(intadd_3_n2), .YS(intadd_3_SUM_3_) );
  FAX1 intadd_3_U2 ( .A(intadd_3_B_4_), .B(intadd_2_SUM_3_), .C(intadd_3_n2), 
        .YC(intadd_3_n1), .YS(intadd_0_A_9_) );
  FAX1 intadd_4_U6 ( .A(words[53]), .B(words[29]), .C(words[137]), .YC(
        intadd_4_n5), .YS(intadd_4_SUM_0_) );
  FAX1 intadd_4_U5 ( .A(intadd_4_B_1_), .B(intadd_4_A_1_), .C(intadd_4_n5), 
        .YC(intadd_4_n4), .YS(intadd_4_SUM_1_) );
  FAX1 intadd_4_U4 ( .A(intadd_4_B_2_), .B(intadd_3_SUM_1_), .C(intadd_4_n4), 
        .YC(intadd_4_n3), .YS(intadd_4_SUM_2_) );
  FAX1 intadd_4_U3 ( .A(intadd_17_n1), .B(intadd_4_A_3_), .C(intadd_4_n3), 
        .YC(intadd_4_n2), .YS(intadd_4_SUM_3_) );
  FAX1 intadd_4_U2 ( .A(intadd_2_SUM_2_), .B(intadd_3_SUM_3_), .C(intadd_4_n2), 
        .YC(intadd_4_n1), .YS(intadd_0_A_8_) );
  FAX1 intadd_5_U6 ( .A(words[52]), .B(words[28]), .C(words[136]), .YC(
        intadd_5_n5), .YS(intadd_5_SUM_0_) );
  FAX1 intadd_5_U5 ( .A(intadd_5_B_1_), .B(intadd_5_A_1_), .C(intadd_5_n5), 
        .YC(intadd_5_n4), .YS(intadd_5_SUM_1_) );
  FAX1 intadd_5_U4 ( .A(intadd_5_B_2_), .B(intadd_4_SUM_1_), .C(intadd_5_n4), 
        .YC(intadd_5_n3), .YS(intadd_5_SUM_2_) );
  FAX1 intadd_5_U3 ( .A(intadd_16_n1), .B(intadd_5_A_3_), .C(intadd_5_n3), 
        .YC(intadd_5_n2), .YS(intadd_5_SUM_3_) );
  FAX1 intadd_5_U2 ( .A(intadd_3_SUM_2_), .B(intadd_4_SUM_3_), .C(intadd_5_n2), 
        .YC(intadd_5_n1), .YS(intadd_0_A_7_) );
  FAX1 intadd_6_U6 ( .A(words[27]), .B(words[3]), .C(words[87]), .YC(
        intadd_6_n5), .YS(intadd_6_SUM_0_) );
  FAX1 intadd_6_U5 ( .A(intadd_6_B_1_), .B(intadd_6_A_1_), .C(intadd_6_n5), 
        .YC(intadd_6_n4), .YS(intadd_6_SUM_1_) );
  FAX1 intadd_6_U4 ( .A(intadd_6_B_2_), .B(intadd_5_SUM_1_), .C(intadd_6_n4), 
        .YC(intadd_6_n3), .YS(intadd_6_SUM_2_) );
  FAX1 intadd_6_U3 ( .A(intadd_15_n1), .B(intadd_6_A_3_), .C(intadd_6_n3), 
        .YC(intadd_6_n2), .YS(intadd_6_SUM_3_) );
  FAX1 intadd_6_U2 ( .A(intadd_4_SUM_2_), .B(intadd_5_SUM_3_), .C(intadd_6_n2), 
        .YC(intadd_6_n1), .YS(intadd_0_A_6_) );
  FAX1 intadd_7_U6 ( .A(words[50]), .B(words[26]), .C(words[134]), .YC(
        intadd_7_n5), .YS(intadd_7_SUM_0_) );
  FAX1 intadd_7_U5 ( .A(intadd_7_B_1_), .B(intadd_7_A_1_), .C(intadd_7_n5), 
        .YC(intadd_7_n4), .YS(intadd_0_B_2_) );
  FAX1 intadd_7_U4 ( .A(intadd_7_B_2_), .B(intadd_6_SUM_1_), .C(intadd_7_n4), 
        .YC(intadd_7_n3), .YS(intadd_0_B_3_) );
  FAX1 intadd_7_U3 ( .A(intadd_14_n1), .B(intadd_7_A_3_), .C(intadd_7_n3), 
        .YC(intadd_7_n2), .YS(intadd_7_SUM_3_) );
  FAX1 intadd_7_U2 ( .A(intadd_5_SUM_2_), .B(intadd_6_SUM_3_), .C(intadd_7_n2), 
        .YC(intadd_7_n1), .YS(intadd_0_A_5_) );
  FAX1 intadd_8_U6 ( .A(words[73]), .B(words[25]), .C(words[49]), .YC(
        intadd_8_n5), .YS(intadd_8_SUM_0_) );
  FAX1 intadd_8_U5 ( .A(intadd_8_B_1_), .B(intadd_8_A_1_), .C(intadd_8_n5), 
        .YC(intadd_8_n4), .YS(intadd_8_SUM_1_) );
  FAX1 intadd_8_U4 ( .A(intadd_8_B_2_), .B(intadd_8_A_2_), .C(intadd_8_n4), 
        .YC(intadd_8_n3), .YS(intadd_8_SUM_2_) );
  FAX1 intadd_8_U3 ( .A(intadd_8_B_3_), .B(intadd_8_A_3_), .C(intadd_8_n3), 
        .YC(intadd_8_n2), .YS(intadd_0_A_3_) );
  FAX1 intadd_8_U2 ( .A(intadd_6_SUM_2_), .B(intadd_7_SUM_3_), .C(intadd_8_n2), 
        .YC(intadd_8_n1), .YS(intadd_0_A_4_) );
  FAX1 intadd_9_U6 ( .A(words[56]), .B(words[32]), .C(words[140]), .YC(
        intadd_9_n5), .YS(intadd_9_SUM_0_) );
  FAX1 intadd_9_U5 ( .A(intadd_9_B_1_), .B(intadd_1_SUM_0_), .C(intadd_9_n5), 
        .YC(intadd_9_n4), .YS(intadd_2_A_2_) );
  FAX1 intadd_9_U4 ( .A(intadd_1_SUM_1_), .B(intadd_9_A_2_), .C(intadd_9_n4), 
        .YC(intadd_9_n3), .YS(intadd_3_B_4_) );
  FAX1 intadd_9_U3 ( .A(intadd_13_n1), .B(intadd_1_SUM_2_), .C(intadd_9_n3), 
        .YC(intadd_9_n2), .YS(intadd_2_A_4_) );
  FAX1 intadd_9_U2 ( .A(intadd_12_n1), .B(intadd_1_SUM_3_), .C(intadd_9_n2), 
        .YC(intadd_9_n1), .YS(intadd_0_A_11_) );
  FAX1 intadd_10_U5 ( .A(intadd_10_B_0_), .B(words[132]), .C(intadd_10_CI), 
        .YC(intadd_10_n4), .YS(intadd_10_SUM_0_) );
  FAX1 intadd_10_U4 ( .A(intadd_0_SUM_0_), .B(intadd_10_A_1_), .C(intadd_10_n4), .YC(intadd_10_n3), .YS(intadd_10_SUM_1_) );
  FAX1 intadd_10_U3 ( .A(intadd_8_SUM_1_), .B(intadd_0_SUM_1_), .C(
        intadd_10_n3), .YC(intadd_10_n2), .YS(intadd_10_SUM_2_) );
  FAX1 intadd_10_U2 ( .A(n56), .B(intadd_10_A_3_), .C(intadd_10_n2), .YC(
        intadd_10_n1), .YS(intadd_10_SUM_3_) );
  FAX1 intadd_11_U5 ( .A(words[60]), .B(words[108]), .C(words[84]), .YC(
        intadd_11_n4), .YS(intadd_11_SUM_0_) );
  FAX1 intadd_11_U4 ( .A(intadd_8_SUM_0_), .B(intadd_11_A_1_), .C(intadd_11_n4), .YC(intadd_11_n3), .YS(intadd_11_SUM_1_) );
  FAX1 intadd_11_U3 ( .A(intadd_11_B_2_), .B(intadd_11_A_2_), .C(intadd_11_n3), 
        .YC(intadd_11_n2), .YS(intadd_11_SUM_2_) );
  FAX1 intadd_11_U2 ( .A(intadd_8_SUM_2_), .B(intadd_0_SUM_2_), .C(
        intadd_11_n2), .YC(intadd_11_n1), .YS(intadd_10_A_3_) );
  FAX1 intadd_12_U4 ( .A(words[57]), .B(words[33]), .C(words[141]), .YC(
        intadd_12_n3), .YS(intadd_12_SUM_0_) );
  FAX1 intadd_12_U3 ( .A(intadd_12_B_1_), .B(intadd_12_A_1_), .C(intadd_12_n3), 
        .YC(intadd_12_n2), .YS(intadd_9_A_2_) );
  FAX1 intadd_12_U2 ( .A(intadd_12_B_2_), .B(intadd_12_A_2_), .C(intadd_12_n2), 
        .YC(intadd_12_n1), .YS(intadd_2_B_4_) );
  FAX1 intadd_13_U4 ( .A(words[128]), .B(words[80]), .C(words[104]), .YC(
        intadd_13_n3), .YS(intadd_2_A_1_) );
  FAX1 intadd_13_U3 ( .A(intadd_13_B_1_), .B(intadd_13_A_1_), .C(intadd_13_n3), 
        .YC(intadd_13_n2), .YS(intadd_2_B_2_) );
  FAX1 intadd_13_U2 ( .A(intadd_13_B_2_), .B(intadd_13_A_2_), .C(intadd_13_n2), 
        .YC(intadd_13_n1), .YS(intadd_2_A_3_) );
  FAX1 intadd_14_U4 ( .A(words[122]), .B(words[74]), .C(words[98]), .YC(
        intadd_14_n3), .YS(intadd_0_B_1_) );
  FAX1 intadd_14_U3 ( .A(intadd_14_B_1_), .B(words[63]), .C(intadd_14_n3), 
        .YC(intadd_14_n2), .YS(intadd_8_A_2_) );
  FAX1 intadd_14_U2 ( .A(intadd_5_SUM_0_), .B(intadd_14_A_2_), .C(intadd_14_n2), .YC(intadd_14_n1), .YS(intadd_8_A_3_) );
  FAX1 intadd_15_U4 ( .A(words[75]), .B(words[51]), .C(words[15]), .YC(
        intadd_15_n3), .YS(intadd_15_SUM_0_) );
  FAX1 intadd_15_U3 ( .A(intadd_15_B_1_), .B(intadd_15_A_1_), .C(intadd_15_n3), 
        .YC(intadd_15_n2), .YS(intadd_8_B_3_) );
  FAX1 intadd_15_U2 ( .A(intadd_4_SUM_0_), .B(intadd_15_A_2_), .C(intadd_15_n2), .YC(intadd_15_n1), .YS(intadd_7_A_3_) );
  FAX1 intadd_16_U4 ( .A(words[124]), .B(words[76]), .C(words[100]), .YC(
        intadd_16_n3), .YS(intadd_6_B_1_) );
  FAX1 intadd_16_U3 ( .A(intadd_16_B_1_), .B(intadd_16_A_1_), .C(intadd_16_n3), 
        .YC(intadd_16_n2), .YS(intadd_6_B_2_) );
  FAX1 intadd_16_U2 ( .A(intadd_3_SUM_0_), .B(intadd_16_A_2_), .C(intadd_16_n2), .YC(intadd_16_n1), .YS(intadd_6_A_3_) );
  FAX1 intadd_17_U4 ( .A(words[125]), .B(words[77]), .C(words[101]), .YC(
        intadd_17_n3), .YS(intadd_5_A_1_) );
  FAX1 intadd_17_U3 ( .A(intadd_17_B_1_), .B(intadd_17_A_1_), .C(intadd_17_n3), 
        .YC(intadd_17_n2), .YS(intadd_5_B_2_) );
  FAX1 intadd_17_U2 ( .A(intadd_2_SUM_0_), .B(intadd_17_A_2_), .C(intadd_17_n2), .YC(intadd_17_n1), .YS(intadd_5_A_3_) );
  FAX1 intadd_18_U4 ( .A(words[126]), .B(words[78]), .C(words[102]), .YC(
        intadd_18_n3), .YS(intadd_4_A_1_) );
  FAX1 intadd_18_U3 ( .A(intadd_18_B_1_), .B(intadd_18_A_1_), .C(intadd_18_n3), 
        .YC(intadd_18_n2), .YS(intadd_4_B_2_) );
  FAX1 intadd_18_U2 ( .A(intadd_9_SUM_0_), .B(intadd_18_A_2_), .C(intadd_18_n2), .YC(intadd_18_n1), .YS(intadd_4_A_3_) );
  FAX1 intadd_19_U4 ( .A(words[127]), .B(words[79]), .C(words[103]), .YC(
        intadd_19_n3), .YS(intadd_3_A_1_) );
  FAX1 intadd_19_U3 ( .A(intadd_19_B_1_), .B(intadd_19_A_1_), .C(intadd_19_n3), 
        .YC(intadd_19_n2), .YS(intadd_3_B_2_) );
  FAX1 intadd_19_U2 ( .A(intadd_12_SUM_0_), .B(intadd_19_A_2_), .C(
        intadd_19_n2), .YC(intadd_19_n1), .YS(intadd_3_A_3_) );
  FAX1 intadd_20_U4 ( .A(words[130]), .B(words[82]), .C(words[106]), .YC(
        intadd_20_n3), .YS(intadd_12_A_1_) );
  FAX1 intadd_20_U3 ( .A(intadd_20_B_1_), .B(intadd_20_A_1_), .C(intadd_20_n3), 
        .YC(intadd_20_n2), .YS(intadd_12_B_2_) );
  FAX1 intadd_20_U2 ( .A(intadd_20_B_2_), .B(intadd_20_A_2_), .C(intadd_20_n2), 
        .YC(intadd_20_n1), .YS(intadd_1_A_3_) );
  INVX1 U37 ( .A(n37), .Y(n35) );
  INVX1 U38 ( .A(n35), .Y(n36) );
  BUFX2 U39 ( .A(n33), .Y(n37) );
  INVX1 U40 ( .A(n40), .Y(n38) );
  INVX1 U41 ( .A(n38), .Y(n39) );
  BUFX2 U42 ( .A(n31), .Y(n40) );
  AND2X1 U43 ( .A(intadd_9_n1), .B(intadd_0_n1), .Y(n86) );
  INVX1 U44 ( .A(n94), .Y(n119) );
  OR2X1 U45 ( .A(n109), .B(n61), .Y(n81) );
  BUFX2 U46 ( .A(n121), .Y(n41) );
  BUFX2 U47 ( .A(n22), .Y(n42) );
  BUFX2 U48 ( .A(n20), .Y(n43) );
  BUFX2 U49 ( .A(n19), .Y(n44) );
  BUFX2 U50 ( .A(n105), .Y(n45) );
  INVX1 U51 ( .A(n45), .Y(n21) );
  INVX1 U52 ( .A(n82), .Y(n46) );
  OR2X1 U53 ( .A(intadd_11_n1), .B(intadd_10_n1), .Y(n82) );
  INVX1 U54 ( .A(n83), .Y(n47) );
  OR2X1 U55 ( .A(intadd_9_n1), .B(intadd_0_n1), .Y(n83) );
  BUFX2 U56 ( .A(n85), .Y(n48) );
  INVX1 U57 ( .A(n48), .Y(n32) );
  BUFX2 U58 ( .A(n91), .Y(n49) );
  INVX1 U59 ( .A(n49), .Y(n30) );
  BUFX2 U60 ( .A(n92), .Y(n50) );
  INVX1 U61 ( .A(n50), .Y(n29) );
  BUFX2 U62 ( .A(n93), .Y(n51) );
  INVX1 U63 ( .A(n51), .Y(n28) );
  BUFX2 U64 ( .A(n95), .Y(n52) );
  INVX1 U65 ( .A(n52), .Y(n27) );
  BUFX2 U66 ( .A(n96), .Y(n53) );
  INVX1 U67 ( .A(n53), .Y(n26) );
  BUFX2 U68 ( .A(n97), .Y(n54) );
  INVX1 U69 ( .A(n54), .Y(n25) );
  BUFX2 U70 ( .A(n98), .Y(n55) );
  INVX1 U71 ( .A(n55), .Y(n24) );
  BUFX2 U72 ( .A(intadd_10_B_3_), .Y(n56) );
  INVX1 U73 ( .A(n86), .Y(n57) );
  AND2X1 U74 ( .A(intadd_11_n1), .B(intadd_10_n1), .Y(n100) );
  INVX1 U75 ( .A(n100), .Y(n58) );
  BUFX2 U76 ( .A(n122), .Y(out_valid) );
  BUFX2 U77 ( .A(n99), .Y(n60) );
  INVX1 U78 ( .A(n60), .Y(n23) );
  BUFX2 U79 ( .A(n106), .Y(n61) );
  FAX1 U81 ( .A(words[35]), .B(words[59]), .C(words[143]), .YC(intadd_20_B_2_), 
        .YS(intadd_1_A_2_) );
  FAX1 U82 ( .A(words[70]), .B(words[46]), .C(words[94]), .YC(intadd_20_B_1_), 
        .YS(intadd_1_A_1_) );
  FAX1 U83 ( .A(words[23]), .B(words[11]), .C(words[119]), .YC(n64), .YS(
        intadd_1_B_2_) );
  FAX1 U84 ( .A(words[71]), .B(words[47]), .C(words[95]), .YC(n62), .YS(
        intadd_20_A_1_) );
  FAX1 U85 ( .A(n64), .B(n63), .C(n62), .YC(intadd_1_A_5_), .YS(intadd_1_B_3_)
         );
  FAX1 U86 ( .A(words[83]), .B(words[131]), .C(words[107]), .YC(n63), .YS(n67)
         );
  FAX1 U87 ( .A(n67), .B(n66), .C(n65), .YC(intadd_20_A_2_), .YS(
        intadd_12_A_2_) );
  FAX1 U88 ( .A(words[22]), .B(words[10]), .C(words[118]), .YC(n65), .YS(
        intadd_13_A_2_) );
  FAX1 U89 ( .A(words[69]), .B(words[45]), .C(words[93]), .YC(intadd_1_B_1_), 
        .YS(intadd_13_A_1_) );
  FAX1 U90 ( .A(words[34]), .B(words[58]), .C(words[142]), .YC(n66), .YS(
        intadd_13_B_2_) );
  FAX1 U91 ( .A(words[21]), .B(words[9]), .C(words[117]), .YC(intadd_12_B_1_), 
        .YS(intadd_19_A_2_) );
  FAX1 U92 ( .A(words[68]), .B(words[44]), .C(words[92]), .YC(intadd_13_B_1_), 
        .YS(intadd_19_A_1_) );
  FAX1 U93 ( .A(words[20]), .B(words[8]), .C(words[116]), .YC(intadd_9_B_1_), 
        .YS(intadd_18_A_2_) );
  FAX1 U94 ( .A(words[67]), .B(words[43]), .C(words[91]), .YC(intadd_19_B_1_), 
        .YS(intadd_18_A_1_) );
  FAX1 U95 ( .A(words[19]), .B(words[7]), .C(words[115]), .YC(intadd_2_B_1_), 
        .YS(intadd_17_A_2_) );
  FAX1 U96 ( .A(words[66]), .B(words[42]), .C(words[90]), .YC(intadd_18_B_1_), 
        .YS(intadd_17_A_1_) );
  FAX1 U97 ( .A(words[18]), .B(words[6]), .C(words[114]), .YC(intadd_3_B_1_), 
        .YS(intadd_16_A_2_) );
  FAX1 U98 ( .A(words[65]), .B(words[41]), .C(words[89]), .YC(intadd_17_B_1_), 
        .YS(intadd_16_A_1_) );
  FAX1 U99 ( .A(words[17]), .B(words[5]), .C(words[113]), .YC(intadd_4_B_1_), 
        .YS(intadd_15_A_2_) );
  AND2X1 U100 ( .A(words[99]), .B(words[123]), .Y(intadd_15_B_1_) );
  FAX1 U101 ( .A(words[64]), .B(words[40]), .C(words[88]), .YC(intadd_16_B_1_), 
        .YS(intadd_6_A_1_) );
  FAX1 U102 ( .A(words[16]), .B(words[4]), .C(words[112]), .YC(intadd_5_B_1_), 
        .YS(intadd_14_A_2_) );
  INVX1 U103 ( .A(intadd_15_B_1_), .Y(n68) );
  OAI21X1 U104 ( .A(words[99]), .B(words[123]), .C(n68), .Y(n69) );
  INVX1 U105 ( .A(n69), .Y(intadd_14_B_1_) );
  FAX1 U106 ( .A(words[111]), .B(words[135]), .C(words[39]), .YC(
        intadd_15_A_1_), .YS(intadd_7_A_1_) );
  AND2X1 U107 ( .A(words[97]), .B(words[121]), .Y(intadd_8_B_1_) );
  FAX1 U108 ( .A(intadd_6_SUM_0_), .B(n70), .C(intadd_15_SUM_0_), .YC(
        intadd_7_B_2_), .YS(intadd_0_A_2_) );
  FAX1 U109 ( .A(words[14]), .B(words[2]), .C(words[110]), .YC(n70), .YS(
        intadd_0_A_1_) );
  INVX1 U110 ( .A(intadd_8_B_1_), .Y(n71) );
  OAI21X1 U111 ( .A(words[97]), .B(words[121]), .C(n71), .Y(n72) );
  INVX1 U112 ( .A(n72), .Y(intadd_0_B_0_) );
  AND2X1 U113 ( .A(words[96]), .B(words[72]), .Y(intadd_0_CI) );
  FAX1 U114 ( .A(words[62]), .B(words[38]), .C(words[86]), .YC(intadd_7_B_1_), 
        .YS(n74) );
  FAX1 U115 ( .A(n74), .B(n73), .C(intadd_7_SUM_0_), .YC(intadd_8_B_2_), .YS(
        intadd_11_A_2_) );
  FAX1 U116 ( .A(words[109]), .B(words[1]), .C(words[133]), .YC(intadd_8_A_1_), 
        .YS(intadd_11_A_1_) );
  FAX1 U117 ( .A(words[61]), .B(words[85]), .C(words[13]), .YC(n73), .YS(n77)
         );
  FAX1 U118 ( .A(n77), .B(n76), .C(n75), .YC(intadd_11_B_2_), .YS(
        intadd_10_A_1_) );
  FAX1 U119 ( .A(words[24]), .B(words[120]), .C(words[48]), .YC(n76), .YS(
        intadd_10_B_0_) );
  INVX1 U120 ( .A(intadd_0_CI), .Y(n78) );
  OAI21X1 U121 ( .A(words[96]), .B(words[72]), .C(n78), .Y(n79) );
  INVX1 U122 ( .A(n79), .Y(intadd_10_CI) );
  INVX1 U123 ( .A(intadd_11_SUM_2_), .Y(n109) );
  FAX1 U124 ( .A(words[36]), .B(words[0]), .C(words[12]), .YC(n75), .YS(n118)
         );
  OR2X1 U125 ( .A(intadd_10_SUM_1_), .B(intadd_11_SUM_1_), .Y(n80) );
  AOI22X1 U126 ( .A(intadd_10_SUM_1_), .B(intadd_11_SUM_1_), .C(n112), .D(n80), 
        .Y(n106) );
  INVX1 U127 ( .A(intadd_10_SUM_2_), .Y(n107) );
  AOI22X1 U128 ( .A(n109), .B(n61), .C(n107), .D(n81), .Y(intadd_10_B_3_) );
  INVX1 U129 ( .A(intadd_0_SUM_3_), .Y(n102) );
  OAI21X1 U130 ( .A(n46), .B(n102), .C(n58), .Y(intadd_0_B_4_) );
  INVX1 U131 ( .A(intadd_1_A_5_), .Y(intadd_1_A_4_) );
  INVX1 U132 ( .A(intadd_1_SUM_4_), .Y(n88) );
  OAI21X1 U133 ( .A(n47), .B(n88), .C(n57), .Y(intadd_1_B_5_) );
  BUFX2 U134 ( .A(in_valid), .Y(n94) );
  INVX1 U135 ( .A(z[15]), .Y(n84) );
  AOI22X1 U136 ( .A(n94), .B(intadd_1_n1), .C(n84), .D(n119), .Y(n33) );
  AOI22X1 U137 ( .A(n94), .B(intadd_1_SUM_5_), .C(z[14]), .D(n119), .Y(n85) );
  OAI21X1 U138 ( .A(intadd_9_n1), .B(intadd_0_n1), .C(n57), .Y(n87) );
  MUX2X1 U139 ( .B(n88), .A(intadd_1_SUM_4_), .S(n87), .Y(n90) );
  INVX1 U140 ( .A(z[13]), .Y(n89) );
  AOI22X1 U141 ( .A(n94), .B(n90), .C(n89), .D(n119), .Y(n31) );
  AOI22X1 U142 ( .A(n94), .B(intadd_0_SUM_11_), .C(z[12]), .D(n119), .Y(n91)
         );
  AOI22X1 U143 ( .A(n94), .B(intadd_0_SUM_10_), .C(z[11]), .D(n119), .Y(n92)
         );
  AOI22X1 U144 ( .A(n94), .B(intadd_0_SUM_9_), .C(z[10]), .D(n119), .Y(n93) );
  AOI22X1 U145 ( .A(n94), .B(intadd_0_SUM_8_), .C(z[9]), .D(n119), .Y(n95) );
  AOI22X1 U146 ( .A(in_valid), .B(intadd_0_SUM_7_), .C(z[8]), .D(n119), .Y(n96) );
  AOI22X1 U147 ( .A(in_valid), .B(intadd_0_SUM_6_), .C(z[7]), .D(n119), .Y(n97) );
  AOI22X1 U148 ( .A(in_valid), .B(intadd_0_SUM_5_), .C(z[6]), .D(n119), .Y(n98) );
  AOI22X1 U149 ( .A(in_valid), .B(intadd_0_SUM_4_), .C(z[5]), .D(n119), .Y(n99) );
  OAI21X1 U150 ( .A(intadd_11_n1), .B(intadd_10_n1), .C(n58), .Y(n101) );
  MUX2X1 U151 ( .B(n102), .A(intadd_0_SUM_3_), .S(n101), .Y(n104) );
  INVX1 U152 ( .A(z[4]), .Y(n103) );
  AOI22X1 U153 ( .A(in_valid), .B(n104), .C(n103), .D(n119), .Y(n22) );
  AOI22X1 U154 ( .A(in_valid), .B(intadd_10_SUM_3_), .C(z[3]), .D(n119), .Y(
        n105) );
  MUX2X1 U155 ( .B(n107), .A(intadd_10_SUM_2_), .S(n61), .Y(n108) );
  MUX2X1 U156 ( .B(n109), .A(intadd_11_SUM_2_), .S(n108), .Y(n111) );
  INVX1 U157 ( .A(z[2]), .Y(n110) );
  AOI22X1 U158 ( .A(in_valid), .B(n111), .C(n110), .D(n119), .Y(n20) );
  INVX1 U159 ( .A(intadd_10_SUM_1_), .Y(n115) );
  INVX1 U160 ( .A(n112), .Y(n113) );
  MUX2X1 U161 ( .B(n113), .A(n112), .S(intadd_11_SUM_1_), .Y(n114) );
  MUX2X1 U162 ( .B(intadd_10_SUM_1_), .A(n115), .S(n114), .Y(n117) );
  INVX1 U163 ( .A(z[1]), .Y(n116) );
  AOI22X1 U164 ( .A(in_valid), .B(n117), .C(n116), .D(n119), .Y(n19) );
  FAX1 U165 ( .A(intadd_10_SUM_0_), .B(n118), .C(intadd_11_SUM_0_), .YC(n112), 
        .YS(n120) );
  AOI22X1 U166 ( .A(in_valid), .B(n120), .C(z[0]), .D(n119), .Y(n121) );
  INVX1 U167 ( .A(n41), .Y(n18) );
endmodule

