/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : T-2022.03-SP2
// Date      : Sun Nov  1 06:37:01 2026
/////////////////////////////////////////////////////////////


module gauss_lut_rom_ADDR_BITS8_OUT_WIDTH12 ( j, mag );
  input [6:0] j;
  output [11:0] mag;
  wire   n370, n369, n368, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12,
         n13, n14, n15, n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26,
         n27, n28, n29, n30, n31, n32, n33, n34, n35, n36, n37, n38, n39, n40,
         n41, n42, n43, n44, n45, n46, n47, n48, n49, n50, n51, n52, n53, n54,
         n55, n56, n57, n58, n59, n60, n61, n64, n66, n67, n68, n70, n71, n72,
         n73, n74, n81, n82, n83, n84, n86, n87, n88, n89, n90, n91, n92, n93,
         n94, n95, n96, n97, n98, n99, n100, n101, n102, n103, n104, n106,
         n107, n108, n109, n110, n111, n112, n113, n114, n115, n116, n117,
         n118, n119, n120, n121, n122, n123, n124, n127, n128, n129, n135,
         n136, n137, n138, n139, n140, n141, n142, n143, n149, n155, n156,
         n157, n158, n159, n160, n161, n162, n163, n164, n165, n166, n167,
         n169, n170, n171, n172, n173, n175, n176, n177, n178, n179, n180,
         n181, n182, n183, n184, n185, n186, n187, n188, n189, n190, n192,
         n193, n194, n195, n196, n197, n198, n199, n200, n201, n202, n203,
         n204, n205, n206, n207, n208, n209, n210, n212, n213, n214, n215,
         n216, n217, n218, n219, n220, n221, n222, n223, n224, n225, n226,
         n227, n228, n229, n230, n231, n232, n233, n234, n235, n236, n237,
         n238, n239, n240, n241, n242, n243, n244, n245, n246, n247, n248,
         n249, n250, n251, n252, n254, n255, n256, n257, n258, n259, n260,
         n261, n262, n263, n264, n265, n266, n267, n268, n269, n270, n271,
         n272, n273, n274, n275, n276, n277, n278, n279, n280, n281, n282,
         n283, n284, n285, n286, n287, n288, n289, n290, n291, n292, n293,
         n294, n295, n296, n297, n298, n299, n300, n301, n302, n303, n304,
         n305, n306, n307, n308, n309, n310, n311, n312, n313, n314, n315,
         n316, n317, n318, n319, n320, n321, n322, n323, n324, n325, n326,
         n327, n328, n329, n330, n331, n332, n333, n334, n335, n336, n337,
         n338, n339, n340, n341, n342, n343, n344, n345, n346, n347, n348,
         n349, n350, n351, n352, n353, n354, n355, n356, n357, n358, n359,
         n360, n361, n362, n363, n364, n365, n366, n371, n372, n373, n374,
         n375, n376, n377, n378, n379, n380, n382;

  AND2X1 U3 ( .A(j[6]), .B(n342), .Y(n199) );
  AND2X1 U4 ( .A(j[2]), .B(j[1]), .Y(n214) );
  AND2X1 U5 ( .A(j[6]), .B(j[5]), .Y(n190) );
  AND2X1 U6 ( .A(n119), .B(n157), .Y(n277) );
  AND2X1 U7 ( .A(n117), .B(n142), .Y(n347) );
  AND2X1 U8 ( .A(n297), .B(n128), .Y(n309) );
  OR2X1 U9 ( .A(n345), .B(n169), .Y(n260) );
  AND2X1 U10 ( .A(n345), .B(n118), .Y(n287) );
  OR2X1 U12 ( .A(j[4]), .B(n124), .Y(n285) );
  AND2X1 U13 ( .A(n182), .B(n121), .Y(n297) );
  AND2X1 U14 ( .A(n70), .B(n340), .Y(n343) );
  AND2X1 U16 ( .A(n68), .B(n87), .Y(n346) );
  AND2X1 U17 ( .A(n61), .B(n137), .Y(n283) );
  AND2X1 U18 ( .A(n143), .B(n12), .Y(n230) );
  AND2X1 U19 ( .A(n123), .B(n64), .Y(n337) );
  AND2X1 U20 ( .A(n143), .B(n13), .Y(n352) );
  AND2X1 U23 ( .A(n135), .B(n68), .Y(n306) );
  BUFX2 U24 ( .A(n192), .Y(n1) );
  BUFX2 U25 ( .A(n273), .Y(n2) );
  BUFX2 U26 ( .A(n272), .Y(n3) );
  BUFX2 U27 ( .A(n304), .Y(n4) );
  BUFX2 U28 ( .A(n303), .Y(n5) );
  BUFX2 U29 ( .A(n332), .Y(n6) );
  BUFX2 U30 ( .A(n331), .Y(n7) );
  BUFX2 U31 ( .A(n366), .Y(n8) );
  BUFX2 U32 ( .A(n365), .Y(n9) );
  BUFX2 U33 ( .A(n236), .Y(n10) );
  BUFX2 U34 ( .A(n286), .Y(n11) );
  OR2X1 U39 ( .A(n71), .B(n92), .Y(n91) );
  OR2X1 U40 ( .A(n324), .B(n66), .Y(n92) );
  OR2X1 U41 ( .A(n60), .B(n102), .Y(n100) );
  OR2X1 U42 ( .A(n311), .B(n101), .Y(n102) );
  OR2X1 U45 ( .A(n84), .B(n110), .Y(n109) );
  OR2X1 U46 ( .A(n333), .B(n334), .Y(n110) );
  OR2X1 U49 ( .A(n140), .B(n141), .Y(n139) );
  OR2X1 U50 ( .A(n247), .B(n113), .Y(n141) );
  OR2X1 U55 ( .A(n86), .B(n163), .Y(n162) );
  OR2X1 U56 ( .A(n326), .B(n73), .Y(n163) );
  OR2X1 U59 ( .A(n82), .B(n172), .Y(n170) );
  OR2X1 U60 ( .A(n320), .B(n171), .Y(n172) );
  OR2X1 U61 ( .A(n115), .B(n176), .Y(n175) );
  OR2X1 U62 ( .A(n356), .B(n335), .Y(n176) );
  AND2X1 U63 ( .A(j[1]), .B(n344), .Y(n252) );
  BUFX2 U64 ( .A(n204), .Y(n12) );
  BUFX2 U65 ( .A(n350), .Y(n13) );
  BUFX2 U66 ( .A(n198), .Y(n14) );
  BUFX2 U67 ( .A(n219), .Y(n15) );
  BUFX2 U68 ( .A(n241), .Y(n16) );
  BUFX2 U69 ( .A(n276), .Y(n17) );
  BUFX2 U70 ( .A(n307), .Y(n18) );
  BUFX2 U71 ( .A(n210), .Y(n19) );
  BUFX2 U72 ( .A(n246), .Y(n20) );
  BUFX2 U73 ( .A(n231), .Y(n21) );
  BUFX2 U74 ( .A(n281), .Y(n22) );
  BUFX2 U75 ( .A(n222), .Y(n23) );
  BUFX2 U76 ( .A(n243), .Y(n24) );
  BUFX2 U77 ( .A(n363), .Y(n25) );
  BUFX2 U78 ( .A(n218), .Y(n26) );
  BUFX2 U79 ( .A(n233), .Y(n27) );
  BUFX2 U80 ( .A(n282), .Y(n28) );
  BUFX2 U81 ( .A(n295), .Y(n29) );
  BUFX2 U82 ( .A(n322), .Y(n30) );
  AND2X1 U83 ( .A(n67), .B(n255), .Y(n264) );
  INVX1 U84 ( .A(n264), .Y(n31) );
  AND2X1 U85 ( .A(n127), .B(n348), .Y(n353) );
  INVX1 U86 ( .A(n353), .Y(n32) );
  BUFX2 U87 ( .A(n195), .Y(n33) );
  BUFX2 U88 ( .A(n235), .Y(n34) );
  AND2X1 U89 ( .A(n193), .B(n115), .Y(n280) );
  INVX1 U90 ( .A(n280), .Y(n35) );
  BUFX2 U91 ( .A(n207), .Y(n36) );
  BUFX2 U92 ( .A(n270), .Y(n37) );
  BUFX2 U93 ( .A(n301), .Y(n38) );
  BUFX2 U94 ( .A(n362), .Y(n39) );
  AND2X1 U95 ( .A(n88), .B(n237), .Y(n242) );
  INVX1 U96 ( .A(n242), .Y(n40) );
  BUFX2 U97 ( .A(n196), .Y(n41) );
  BUFX2 U98 ( .A(n232), .Y(n42) );
  BUFX2 U99 ( .A(n263), .Y(n43) );
  BUFX2 U100 ( .A(n321), .Y(n44) );
  INVX1 U101 ( .A(n217), .Y(n45) );
  AND2X1 U102 ( .A(n182), .B(n89), .Y(n217) );
  INVX1 U103 ( .A(n294), .Y(n46) );
  AND2X1 U104 ( .A(n70), .B(n293), .Y(n294) );
  INVX1 U105 ( .A(n352), .Y(n47) );
  BUFX2 U106 ( .A(n261), .Y(n48) );
  BUFX2 U107 ( .A(n250), .Y(n49) );
  INVX1 U108 ( .A(n212), .Y(n50) );
  AND2X1 U109 ( .A(n327), .B(n267), .Y(n212) );
  INVX1 U110 ( .A(n240), .Y(n51) );
  AND2X1 U111 ( .A(n183), .B(n239), .Y(n240) );
  INVX1 U112 ( .A(n268), .Y(n52) );
  AND2X1 U113 ( .A(n214), .B(n267), .Y(n268) );
  INVX1 U114 ( .A(n318), .Y(n53) );
  AND2X1 U115 ( .A(n317), .B(n337), .Y(n318) );
  INVX1 U116 ( .A(n355), .Y(n54) );
  AND2X1 U117 ( .A(n185), .B(n113), .Y(n355) );
  BUFX2 U118 ( .A(n291), .Y(n55) );
  AND2X1 U119 ( .A(n317), .B(n214), .Y(n247) );
  BUFX2 U122 ( .A(n259), .Y(n56) );
  BUFX2 U123 ( .A(n313), .Y(n57) );
  INVX1 U124 ( .A(n187), .Y(n58) );
  AND2X1 U125 ( .A(n306), .B(n182), .Y(n187) );
  INVX1 U126 ( .A(n228), .Y(n59) );
  AND2X1 U127 ( .A(n149), .B(n297), .Y(n228) );
  INVX1 U128 ( .A(n61), .Y(n60) );
  BUFX2 U129 ( .A(n257), .Y(n61) );
  AND2X1 U133 ( .A(n239), .B(n274), .Y(n185) );
  INVX1 U134 ( .A(n193), .Y(n64) );
  AND2X1 U135 ( .A(j[1]), .B(n239), .Y(n193) );
  AND2X1 U137 ( .A(n344), .B(n185), .Y(n205) );
  INVX1 U138 ( .A(n67), .Y(n66) );
  BUFX2 U139 ( .A(n325), .Y(n67) );
  INVX1 U140 ( .A(n234), .Y(n68) );
  AND2X1 U141 ( .A(n186), .B(n185), .Y(n234) );
  BUFX2 U143 ( .A(n341), .Y(n70) );
  BUFX2 U144 ( .A(n323), .Y(n71) );
  INVX1 U145 ( .A(n214), .Y(n72) );
  INVX1 U146 ( .A(n74), .Y(n73) );
  BUFX2 U147 ( .A(n316), .Y(n74) );
  BUFX2 U148 ( .A(n369), .Y(mag[5]) );
  INVX1 U152 ( .A(n199), .Y(n81) );
  BUFX2 U153 ( .A(n292), .Y(n82) );
  AND2X1 U155 ( .A(n181), .B(n138), .Y(n237) );
  INVX1 U156 ( .A(n237), .Y(n86) );
  INVX1 U157 ( .A(n258), .Y(n87) );
  AND2X1 U158 ( .A(n193), .B(n183), .Y(n258) );
  BUFX2 U159 ( .A(n319), .Y(n88) );
  INVX1 U160 ( .A(n216), .Y(n89) );
  AND2X1 U161 ( .A(n267), .B(n185), .Y(n216) );
  BUFX2 U162 ( .A(n300), .Y(n90) );
  INVX1 U163 ( .A(n230), .Y(n93) );
  BUFX2 U165 ( .A(n224), .Y(n95) );
  BUFX2 U166 ( .A(n284), .Y(n96) );
  INVX1 U167 ( .A(n220), .Y(n97) );
  OR2X1 U168 ( .A(n175), .B(n358), .Y(n220) );
  BUFX2 U169 ( .A(n249), .Y(n98) );
  BUFX2 U170 ( .A(n254), .Y(n99) );
  INVX1 U171 ( .A(n10), .Y(n101) );
  INVX1 U172 ( .A(n200), .Y(n103) );
  OR2X1 U173 ( .A(n175), .B(n202), .Y(n200) );
  INVX1 U175 ( .A(n346), .Y(n107) );
  INVX1 U176 ( .A(n305), .Y(n108) );
  AND2X1 U177 ( .A(n183), .B(n274), .Y(n305) );
  INVX1 U178 ( .A(n338), .Y(n111) );
  AND2X1 U179 ( .A(n122), .B(n181), .Y(n338) );
  INVX1 U180 ( .A(n335), .Y(n112) );
  AND2X1 U181 ( .A(n274), .B(n345), .Y(n335) );
  INVX1 U182 ( .A(n114), .Y(n113) );
  BUFX2 U183 ( .A(n215), .Y(n114) );
  INVX1 U184 ( .A(n116), .Y(n115) );
  BUFX2 U185 ( .A(n290), .Y(n116) );
  INVX1 U186 ( .A(n345), .Y(n117) );
  AND2X1 U187 ( .A(j[4]), .B(n328), .Y(n345) );
  INVX1 U188 ( .A(n337), .Y(n118) );
  BUFX2 U189 ( .A(n336), .Y(n119) );
  AND2X1 U190 ( .A(n186), .B(n214), .Y(n358) );
  INVX1 U191 ( .A(n358), .Y(n120) );
  AND2X1 U192 ( .A(n214), .B(n345), .Y(n238) );
  INVX1 U193 ( .A(n238), .Y(n121) );
  AND2X1 U194 ( .A(n115), .B(n214), .Y(n266) );
  INVX1 U195 ( .A(n266), .Y(n122) );
  INVX1 U196 ( .A(n327), .Y(n123) );
  AND2X1 U197 ( .A(j[2]), .B(n274), .Y(n327) );
  AND2X1 U198 ( .A(j[0]), .B(n203), .Y(n328) );
  INVX1 U199 ( .A(n328), .Y(n124) );
  BUFX2 U200 ( .A(n370), .Y(mag[4]) );
  BUFX2 U201 ( .A(n368), .Y(mag[6]) );
  BUFX2 U202 ( .A(n349), .Y(n127) );
  INVX1 U203 ( .A(n296), .Y(n128) );
  AND2X1 U204 ( .A(n327), .B(n113), .Y(n296) );
  INVX1 U205 ( .A(n356), .Y(n129) );
  AND2X1 U206 ( .A(n193), .B(n345), .Y(n356) );
  INVX1 U210 ( .A(n359), .Y(n135) );
  AND2X1 U211 ( .A(n183), .B(n214), .Y(n359) );
  INVX1 U212 ( .A(n269), .Y(n136) );
  AND2X1 U213 ( .A(n327), .B(n183), .Y(n269) );
  INVX1 U214 ( .A(n256), .Y(n137) );
  AND2X1 U215 ( .A(n327), .B(n317), .Y(n256) );
  INVX1 U216 ( .A(n314), .Y(n138) );
  AND2X1 U217 ( .A(n327), .B(n115), .Y(n314) );
  INVX1 U218 ( .A(n189), .Y(n140) );
  INVX1 U219 ( .A(n344), .Y(n142) );
  AND2X1 U220 ( .A(j[0]), .B(n194), .Y(n344) );
  AND2X1 U221 ( .A(n186), .B(n193), .Y(n351) );
  INVX1 U222 ( .A(n351), .Y(n143) );
  BUFX2 U226 ( .A(n312), .Y(n149) );
  AND2X1 U230 ( .A(n193), .B(n113), .Y(n320) );
  INVX1 U231 ( .A(n320), .Y(n155) );
  INVX1 U232 ( .A(n326), .Y(n156) );
  AND2X1 U233 ( .A(n344), .B(n193), .Y(n326) );
  BUFX2 U234 ( .A(n298), .Y(n157) );
  INVX1 U235 ( .A(n361), .Y(n158) );
  OR2X1 U236 ( .A(j[6]), .B(j[5]), .Y(n361) );
  BUFX2 U237 ( .A(n227), .Y(n159) );
  BUFX2 U238 ( .A(n251), .Y(n160) );
  INVX1 U239 ( .A(n343), .Y(n161) );
  BUFX2 U240 ( .A(n279), .Y(n164) );
  INVX1 U241 ( .A(n347), .Y(n165) );
  INVX1 U242 ( .A(n283), .Y(n166) );
  INVX1 U243 ( .A(n277), .Y(n169) );
  INVX1 U244 ( .A(n306), .Y(n171) );
  INVX1 U245 ( .A(n309), .Y(n173) );
  BUFX2 U247 ( .A(n299), .Y(n177) );
  AND2X1 U249 ( .A(n344), .B(n214), .Y(n333) );
  INVX1 U250 ( .A(n333), .Y(n179) );
  INVX1 U251 ( .A(n287), .Y(n180) );
  AND2X1 U252 ( .A(n317), .B(n193), .Y(n324) );
  INVX1 U253 ( .A(n324), .Y(n181) );
  AND2X1 U254 ( .A(n186), .B(n327), .Y(n311) );
  INVX1 U255 ( .A(n311), .Y(n182) );
  INVX1 U256 ( .A(n285), .Y(n183) );
  OR2X1 U257 ( .A(j[6]), .B(n342), .Y(n354) );
  INVX1 U258 ( .A(n354), .Y(n184) );
  AND2X1 U259 ( .A(j[3]), .B(j[4]), .Y(n194) );
  INVX1 U260 ( .A(j[2]), .Y(n239) );
  INVX1 U261 ( .A(j[1]), .Y(n274) );
  INVX1 U262 ( .A(j[5]), .Y(n342) );
  INVX1 U263 ( .A(j[3]), .Y(n203) );
  INVX1 U264 ( .A(j[0]), .Y(n278) );
  NAND3X1 U265 ( .A(n203), .B(n278), .C(j[4]), .Y(n290) );
  INVX1 U266 ( .A(j[4]), .Y(n188) );
  NAND3X1 U267 ( .A(j[3]), .B(j[0]), .C(n188), .Y(n336) );
  INVX1 U268 ( .A(n119), .Y(n186) );
  NOR3X1 U269 ( .A(n351), .B(n178), .C(n58), .Y(n189) );
  NAND3X1 U270 ( .A(n188), .B(n278), .C(j[3]), .Y(n215) );
  NOR3X1 U271 ( .A(j[3]), .B(j[4]), .C(j[0]), .Y(n317) );
  AOI22X1 U272 ( .A(n317), .B(n274), .C(n183), .D(n239), .Y(n312) );
  NAND3X1 U273 ( .A(n149), .B(n136), .C(n181), .Y(n224) );
  OR2X1 U274 ( .A(n139), .B(n95), .Y(n202) );
  AOI22X1 U275 ( .A(n199), .B(n103), .C(n190), .D(n94), .Y(n192) );
  INVX1 U276 ( .A(n1), .Y(mag[8]) );
  INVX1 U277 ( .A(n202), .Y(n197) );
  NAND3X1 U278 ( .A(j[4]), .B(j[3]), .C(n278), .Y(n298) );
  INVX1 U279 ( .A(n157), .Y(n267) );
  AOI21X1 U280 ( .A(n267), .B(n337), .C(n106), .Y(n195) );
  NAND3X1 U281 ( .A(n97), .B(n33), .C(n121), .Y(n196) );
  AOI22X1 U282 ( .A(n184), .B(n197), .C(n190), .D(n41), .Y(n198) );
  OAI21X1 U283 ( .A(n103), .B(n81), .C(n14), .Y(mag[7]) );
  OAI21X1 U284 ( .A(n185), .B(n157), .C(n142), .Y(n201) );
  AOI22X1 U285 ( .A(n184), .B(n202), .C(n158), .D(n201), .Y(n210) );
  OAI21X1 U286 ( .A(n175), .B(n139), .C(n199), .Y(n209) );
  NAND3X1 U287 ( .A(n179), .B(n128), .C(n89), .Y(n292) );
  AOI21X1 U288 ( .A(n203), .B(n214), .C(n170), .Y(n204) );
  AOI21X1 U289 ( .A(n113), .B(n337), .C(n205), .Y(n299) );
  OAI21X1 U290 ( .A(n344), .B(n183), .C(n327), .Y(n206) );
  NAND3X1 U291 ( .A(n297), .B(n177), .C(n206), .Y(n207) );
  OAI21X1 U292 ( .A(n93), .B(n36), .C(n190), .Y(n208) );
  NAND3X1 U293 ( .A(n19), .B(n209), .C(n208), .Y(n368) );
  AOI21X1 U294 ( .A(n113), .B(j[2]), .C(n351), .Y(n349) );
  NAND3X1 U295 ( .A(n127), .B(n149), .C(n180), .Y(n249) );
  NOR3X1 U296 ( .A(n86), .B(n98), .C(n106), .Y(n213) );
  NAND3X1 U297 ( .A(n213), .B(n155), .C(n50), .Y(n222) );
  AOI21X1 U298 ( .A(n117), .B(n114), .C(n72), .Y(n218) );
  OR2X1 U299 ( .A(n190), .B(n158), .Y(n308) );
  AOI22X1 U300 ( .A(n158), .B(n26), .C(n308), .D(n45), .Y(n219) );
  OAI21X1 U301 ( .A(j[5]), .B(n97), .C(n15), .Y(n221) );
  AOI21X1 U302 ( .A(n190), .B(n23), .C(n221), .Y(n227) );
  OAI21X1 U303 ( .A(n157), .B(n239), .C(n136), .Y(n289) );
  INVX1 U304 ( .A(n289), .Y(n262) );
  OAI21X1 U305 ( .A(n239), .B(n142), .C(n262), .Y(n223) );
  OAI21X1 U306 ( .A(n139), .B(n223), .C(n184), .Y(n226) );
  OAI21X1 U307 ( .A(n333), .B(n95), .C(n199), .Y(n225) );
  NAND3X1 U308 ( .A(n159), .B(n226), .C(n225), .Y(n369) );
  AOI21X1 U309 ( .A(n267), .B(n239), .C(n178), .Y(n284) );
  AND2X1 U310 ( .A(n127), .B(n156), .Y(n275) );
  NOR3X1 U311 ( .A(n205), .B(n111), .C(n59), .Y(n229) );
  NAND3X1 U312 ( .A(n96), .B(n275), .C(n229), .Y(n233) );
  AOI21X1 U313 ( .A(n185), .B(n113), .C(n93), .Y(n231) );
  NAND3X1 U314 ( .A(n21), .B(n180), .C(n138), .Y(n232) );
  AOI22X1 U315 ( .A(n184), .B(n27), .C(n158), .D(n42), .Y(n246) );
  AOI22X1 U316 ( .A(n327), .B(n344), .C(n193), .D(n115), .Y(n257) );
  AOI21X1 U317 ( .A(n327), .B(n345), .C(n107), .Y(n235) );
  NAND3X1 U318 ( .A(n177), .B(n34), .C(n137), .Y(n254) );
  AOI21X1 U319 ( .A(n185), .B(n345), .C(n99), .Y(n236) );
  AOI21X1 U320 ( .A(n267), .B(n327), .C(n238), .Y(n316) );
  OAI21X1 U321 ( .A(n100), .B(n162), .C(n190), .Y(n245) );
  NAND3X1 U322 ( .A(n180), .B(n122), .C(n51), .Y(n243) );
  NAND3X1 U323 ( .A(n262), .B(n275), .C(n137), .Y(n241) );
  AOI21X1 U324 ( .A(j[3]), .B(n327), .C(n16), .Y(n319) );
  OAI21X1 U325 ( .A(n24), .B(n40), .C(n199), .Y(n244) );
  NAND3X1 U326 ( .A(n20), .B(n245), .C(n244), .Y(n370) );
  AOI21X1 U327 ( .A(j[1]), .B(n115), .C(n98), .Y(n250) );
  NAND3X1 U328 ( .A(n306), .B(n83), .C(n49), .Y(n251) );
  AOI22X1 U329 ( .A(n190), .B(n160), .C(n320), .D(n342), .Y(n273) );
  AOI21X1 U330 ( .A(n267), .B(n214), .C(n320), .Y(n325) );
  NOR3X1 U331 ( .A(n104), .B(n99), .C(n178), .Y(n255) );
  NAND3X1 U332 ( .A(n128), .B(n143), .C(n87), .Y(n259) );
  NOR3X1 U333 ( .A(n238), .B(n166), .C(n56), .Y(n357) );
  AOI22X1 U334 ( .A(n115), .B(n337), .C(n185), .D(n260), .Y(n261) );
  NAND3X1 U335 ( .A(n262), .B(n357), .C(n48), .Y(n263) );
  AOI22X1 U336 ( .A(n184), .B(n31), .C(n158), .D(n43), .Y(n272) );
  NAND3X1 U338 ( .A(n360), .B(n136), .C(n52), .Y(n270) );
  OAI21X1 U339 ( .A(n100), .B(n37), .C(n199), .Y(n271) );
  NAND3X1 U340 ( .A(n275), .B(n237), .C(n108), .Y(n276) );
  AOI21X1 U341 ( .A(n214), .B(n169), .C(n17), .Y(n281) );
  NAND3X1 U342 ( .A(j[3]), .B(n185), .C(n278), .Y(n279) );
  NAND3X1 U343 ( .A(n22), .B(n35), .C(n164), .Y(n282) );
  AOI22X1 U344 ( .A(n158), .B(n28), .C(n335), .D(n308), .Y(n304) );
  NAND3X1 U345 ( .A(n283), .B(n96), .C(n135), .Y(n323) );
  AOI21X1 U346 ( .A(n183), .B(n185), .C(n71), .Y(n300) );
  NAND3X1 U347 ( .A(n182), .B(n156), .C(n155), .Y(n286) );
  INVX1 U348 ( .A(n11), .Y(n288) );
  NAND3X1 U349 ( .A(n90), .B(n288), .C(n180), .Y(n295) );
  AOI21X1 U350 ( .A(j[1]), .B(n113), .C(n289), .Y(n341) );
  NAND3X1 U351 ( .A(n306), .B(n116), .C(n181), .Y(n291) );
  NOR3X1 U352 ( .A(n82), .B(n55), .C(n167), .Y(n293) );
  AOI22X1 U353 ( .A(n184), .B(n29), .C(n199), .D(n46), .Y(n303) );
  NAND3X1 U354 ( .A(n90), .B(n177), .C(n157), .Y(n301) );
  OAI21X1 U355 ( .A(n173), .B(n38), .C(n190), .Y(n302) );
  NAND3X1 U356 ( .A(n306), .B(n283), .C(n108), .Y(n307) );
  OR2X1 U357 ( .A(n104), .B(n18), .Y(n310) );
  AOI22X1 U358 ( .A(n190), .B(n310), .C(n173), .D(n308), .Y(n332) );
  NAND3X1 U359 ( .A(n149), .B(n182), .C(n129), .Y(n313) );
  NOR3X1 U360 ( .A(n84), .B(n170), .C(n57), .Y(n315) );
  NAND3X1 U361 ( .A(n74), .B(n315), .C(n138), .Y(n322) );
  NAND3X1 U362 ( .A(n155), .B(n88), .C(n53), .Y(n321) );
  AOI22X1 U363 ( .A(n184), .B(n30), .C(n199), .D(n44), .Y(n331) );
  OAI21X1 U364 ( .A(n124), .B(n123), .C(n156), .Y(n329) );
  OAI21X1 U365 ( .A(n91), .B(n329), .C(n158), .Y(n330) );
  OAI21X1 U366 ( .A(n118), .B(n119), .C(n112), .Y(n339) );
  NOR3X1 U367 ( .A(n109), .B(n339), .C(n111), .Y(n340) );
  AOI22X1 U368 ( .A(n190), .B(n161), .C(n205), .D(n342), .Y(n366) );
  NOR3X1 U369 ( .A(n109), .B(n165), .C(n107), .Y(n348) );
  AOI21X1 U370 ( .A(n328), .B(n185), .C(n91), .Y(n350) );
  AOI22X1 U371 ( .A(n184), .B(n32), .C(n199), .D(n47), .Y(n365) );
  NAND3X1 U372 ( .A(n357), .B(n129), .C(n54), .Y(n363) );
  NAND3X1 U373 ( .A(n360), .B(n135), .C(n120), .Y(n362) );
  OAI21X1 U374 ( .A(n25), .B(n39), .C(n158), .Y(n364) );
  INVX1 U11 ( .A(n94), .Y(n371) );
  AND2X1 U15 ( .A(n190), .B(n371), .Y(mag[9]) );
  INVX1 U21 ( .A(n194), .Y(n372) );
  OR2X1 U22 ( .A(n372), .B(n185), .Y(n94) );
  INVX1 U35 ( .A(n373), .Y(mag[2]) );
  AND2X1 U36 ( .A(n4), .B(n379), .Y(n373) );
  INVX1 U37 ( .A(n374), .Y(mag[0]) );
  AND2X1 U38 ( .A(n8), .B(n378), .Y(n374) );
  INVX1 U43 ( .A(n375), .Y(mag[1]) );
  AND2X1 U44 ( .A(n6), .B(n377), .Y(n375) );
  INVX1 U47 ( .A(n376), .Y(mag[3]) );
  AND2X1 U48 ( .A(n2), .B(n380), .Y(n376) );
  AND2X1 U51 ( .A(n330), .B(n7), .Y(n377) );
  AND2X1 U52 ( .A(n364), .B(n9), .Y(n378) );
  AND2X1 U53 ( .A(n302), .B(n5), .Y(n379) );
  AND2X1 U54 ( .A(n271), .B(n3), .Y(n380) );
  OR2X2 U57 ( .A(n333), .B(n205), .Y(n106) );
  INVX1 U58 ( .A(n83), .Y(n84) );
  NOR3X1 U120 ( .A(n248), .B(n247), .C(n326), .Y(n83) );
  INVX1 U121 ( .A(n360), .Y(n167) );
  NOR3X1 U130 ( .A(n265), .B(n266), .C(n334), .Y(n360) );
  AND2X1 U131 ( .A(n185), .B(n317), .Y(n334) );
  INVX1 U132 ( .A(n382), .Y(n104) );
  NOR3X1 U136 ( .A(n86), .B(n265), .C(n252), .Y(n382) );
  AND2X1 U142 ( .A(n267), .B(n193), .Y(n265) );
  AND2X1 U149 ( .A(n185), .B(n115), .Y(n248) );
  OR2X2 U150 ( .A(n248), .B(n358), .Y(n178) );
endmodule


module gauss_lut ( clk, rst_n, in_valid, u, out_valid, z );
  input [31:0] u;
  output [11:0] z;
  input clk, rst_n, in_valid;
  output out_valid;
  wire   n158, N12, n51, n52, n53, n54, n55, n56, n57, n58, n59, n60, n61, n62,
         n64, n65, n66, n67, n68, n69, n70, n71, n72, n73, n74, n75, n76, n77,
         n78, n79, n80, n81, n82, n83, n84, n85, n86, n87, n88, n89, n90, n91,
         n92, n93, n94, n95, n96, n97, n98, n99, n100, n101, n102, n103, n104,
         n105, n107, n108, n109, n110, n111, n112, n113, n114, n115, n116,
         n117, n118, n119, n120, n121, n122, n123, n124, n125, n126, n127,
         n128, n129, n130, n131, n132, n133, n134, n135, n136, n137, n138,
         n139, n140, n141, n142, n143, n144, n145, n146, n147, n148, n149,
         n150, n151, n152, n153, n154, n155, n156, n157,
         SYNOPSYS_UNCONNECTED_1, SYNOPSYS_UNCONNECTED_2;
  wire   [6:0] j;
  wire   [9:1] mag;

  gauss_lut_rom_ADDR_BITS8_OUT_WIDTH12 u_rom ( .j(j), .mag({
        SYNOPSYS_UNCONNECTED_1, SYNOPSYS_UNCONNECTED_2, mag, N12}) );
  DFFSR out_valid_reg ( .D(in_valid), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n158)
         );
  DFFPOSX1 z_reg_11_ ( .D(n62), .CLK(clk), .Q(z[11]) );
  DFFPOSX1 z_reg_10_ ( .D(n61), .CLK(clk), .Q(z[10]) );
  DFFPOSX1 z_reg_9_ ( .D(n65), .CLK(clk), .Q(z[9]) );
  DFFPOSX1 z_reg_8_ ( .D(n68), .CLK(clk), .Q(z[8]) );
  DFFPOSX1 z_reg_7_ ( .D(n71), .CLK(clk), .Q(z[7]) );
  DFFPOSX1 z_reg_6_ ( .D(n74), .CLK(clk), .Q(z[6]) );
  DFFPOSX1 z_reg_5_ ( .D(n77), .CLK(clk), .Q(z[5]) );
  DFFPOSX1 z_reg_4_ ( .D(n80), .CLK(clk), .Q(z[4]) );
  DFFPOSX1 z_reg_3_ ( .D(n83), .CLK(clk), .Q(z[3]) );
  DFFPOSX1 z_reg_2_ ( .D(n86), .CLK(clk), .Q(z[2]) );
  DFFPOSX1 z_reg_1_ ( .D(n89), .CLK(clk), .Q(z[1]) );
  DFFPOSX1 z_reg_0_ ( .D(n92), .CLK(clk), .Q(z[0]) );
  OR2X1 U73 ( .A(mag[8]), .B(n116), .Y(n111) );
  OR2X1 U74 ( .A(mag[7]), .B(n121), .Y(n116) );
  INVX1 U75 ( .A(n66), .Y(n64) );
  INVX1 U76 ( .A(n64), .Y(n65) );
  BUFX2 U77 ( .A(n60), .Y(n66) );
  INVX1 U78 ( .A(n69), .Y(n67) );
  INVX1 U79 ( .A(n67), .Y(n68) );
  BUFX2 U80 ( .A(n59), .Y(n69) );
  INVX1 U81 ( .A(n72), .Y(n70) );
  INVX1 U82 ( .A(n70), .Y(n71) );
  BUFX2 U83 ( .A(n58), .Y(n72) );
  INVX1 U84 ( .A(n75), .Y(n73) );
  INVX1 U85 ( .A(n73), .Y(n74) );
  BUFX2 U86 ( .A(n57), .Y(n75) );
  INVX1 U87 ( .A(n78), .Y(n76) );
  INVX1 U88 ( .A(n76), .Y(n77) );
  BUFX2 U89 ( .A(n56), .Y(n78) );
  INVX1 U90 ( .A(n81), .Y(n79) );
  INVX1 U91 ( .A(n79), .Y(n80) );
  BUFX2 U92 ( .A(n55), .Y(n81) );
  INVX1 U93 ( .A(n84), .Y(n82) );
  INVX1 U94 ( .A(n82), .Y(n83) );
  BUFX2 U95 ( .A(n54), .Y(n84) );
  INVX1 U96 ( .A(n87), .Y(n85) );
  INVX1 U97 ( .A(n85), .Y(n86) );
  BUFX2 U98 ( .A(n53), .Y(n87) );
  INVX1 U99 ( .A(n90), .Y(n88) );
  INVX1 U100 ( .A(n88), .Y(n89) );
  BUFX2 U101 ( .A(n52), .Y(n90) );
  INVX1 U102 ( .A(n93), .Y(n91) );
  INVX1 U103 ( .A(n91), .Y(n92) );
  BUFX2 U104 ( .A(n51), .Y(n93) );
  OR2X1 U105 ( .A(mag[6]), .B(n102), .Y(n121) );
  INVX1 U106 ( .A(u[31]), .Y(n150) );
  OR2X1 U107 ( .A(mag[4]), .B(n101), .Y(n131) );
  INVX1 U108 ( .A(n112), .Y(n94) );
  AND2X1 U109 ( .A(n150), .B(n111), .Y(n112) );
  INVX1 U110 ( .A(n117), .Y(n95) );
  AND2X1 U111 ( .A(n150), .B(n116), .Y(n117) );
  INVX1 U112 ( .A(n122), .Y(n96) );
  AND2X1 U113 ( .A(n150), .B(n121), .Y(n122) );
  INVX1 U114 ( .A(n127), .Y(n97) );
  AND2X1 U115 ( .A(n150), .B(n102), .Y(n127) );
  INVX1 U116 ( .A(n132), .Y(n98) );
  OR2X1 U117 ( .A(u[31]), .B(n105), .Y(n132) );
  INVX1 U118 ( .A(n137), .Y(n99) );
  AND2X1 U119 ( .A(n150), .B(n101), .Y(n137) );
  INVX1 U120 ( .A(n151), .Y(n100) );
  AND2X1 U121 ( .A(N12), .B(n150), .Y(n151) );
  INVX1 U122 ( .A(n136), .Y(n101) );
  AND2X1 U123 ( .A(n141), .B(n143), .Y(n136) );
  INVX1 U124 ( .A(n126), .Y(n102) );
  AND2X1 U125 ( .A(n105), .B(n133), .Y(n126) );
  OR2X1 U126 ( .A(u[31]), .B(n141), .Y(n142) );
  INVX1 U127 ( .A(n142), .Y(n103) );
  BUFX2 U128 ( .A(n109), .Y(n104) );
  OR2X1 U129 ( .A(n111), .B(mag[9]), .Y(n107) );
  INVX1 U130 ( .A(n131), .Y(n105) );
  BUFX2 U131 ( .A(n158), .Y(out_valid) );
  MUX2X1 U132 ( .B(u[31]), .A(n150), .S(u[24]), .Y(j[0]) );
  MUX2X1 U133 ( .B(u[31]), .A(n150), .S(u[25]), .Y(j[1]) );
  MUX2X1 U134 ( .B(u[31]), .A(n150), .S(u[26]), .Y(j[2]) );
  MUX2X1 U135 ( .B(u[31]), .A(n150), .S(u[27]), .Y(j[3]) );
  MUX2X1 U136 ( .B(u[31]), .A(n150), .S(u[28]), .Y(j[4]) );
  MUX2X1 U137 ( .B(u[31]), .A(n150), .S(u[29]), .Y(j[5]) );
  MUX2X1 U138 ( .B(u[31]), .A(n150), .S(u[30]), .Y(j[6]) );
  INVX1 U140 ( .A(z[11]), .Y(n108) );
  NOR3X1 U141 ( .A(mag[2]), .B(N12), .C(mag[1]), .Y(n141) );
  INVX1 U142 ( .A(mag[3]), .Y(n143) );
  INVX1 U143 ( .A(mag[5]), .Y(n133) );
  NAND3X1 U144 ( .A(n150), .B(in_valid), .C(n107), .Y(n109) );
  OAI21X1 U145 ( .A(in_valid), .B(n108), .C(n104), .Y(n62) );
  INVX1 U146 ( .A(z[10]), .Y(n110) );
  OAI21X1 U147 ( .A(in_valid), .B(n110), .C(n104), .Y(n61) );
  INVX1 U148 ( .A(mag[9]), .Y(n113) );
  MUX2X1 U149 ( .B(n113), .A(mag[9]), .S(n94), .Y(n115) );
  INVX1 U150 ( .A(z[9]), .Y(n114) );
  INVX1 U151 ( .A(in_valid), .Y(n155) );
  AOI22X1 U152 ( .A(in_valid), .B(n115), .C(n114), .D(n155), .Y(n60) );
  INVX1 U153 ( .A(mag[8]), .Y(n118) );
  MUX2X1 U154 ( .B(n118), .A(mag[8]), .S(n95), .Y(n120) );
  INVX1 U155 ( .A(z[8]), .Y(n119) );
  AOI22X1 U156 ( .A(in_valid), .B(n120), .C(n119), .D(n155), .Y(n59) );
  INVX1 U157 ( .A(mag[7]), .Y(n123) );
  MUX2X1 U158 ( .B(n123), .A(mag[7]), .S(n96), .Y(n125) );
  INVX1 U159 ( .A(z[7]), .Y(n124) );
  AOI22X1 U160 ( .A(in_valid), .B(n125), .C(n124), .D(n155), .Y(n58) );
  INVX1 U161 ( .A(mag[6]), .Y(n128) );
  MUX2X1 U162 ( .B(n128), .A(mag[6]), .S(n97), .Y(n130) );
  INVX1 U163 ( .A(z[6]), .Y(n129) );
  AOI22X1 U164 ( .A(in_valid), .B(n130), .C(n129), .D(n155), .Y(n57) );
  MUX2X1 U165 ( .B(mag[5]), .A(n133), .S(n98), .Y(n135) );
  INVX1 U166 ( .A(z[5]), .Y(n134) );
  AOI22X1 U167 ( .A(in_valid), .B(n135), .C(n134), .D(n155), .Y(n56) );
  INVX1 U168 ( .A(mag[4]), .Y(n138) );
  MUX2X1 U169 ( .B(n138), .A(mag[4]), .S(n99), .Y(n140) );
  INVX1 U170 ( .A(z[4]), .Y(n139) );
  AOI22X1 U171 ( .A(in_valid), .B(n140), .C(n139), .D(n155), .Y(n55) );
  MUX2X1 U172 ( .B(mag[3]), .A(n143), .S(n103), .Y(n145) );
  INVX1 U173 ( .A(z[3]), .Y(n144) );
  AOI22X1 U174 ( .A(in_valid), .B(n145), .C(n144), .D(n155), .Y(n54) );
  INVX1 U175 ( .A(mag[2]), .Y(n147) );
  OAI21X1 U176 ( .A(N12), .B(mag[1]), .C(n150), .Y(n146) );
  MUX2X1 U177 ( .B(n147), .A(mag[2]), .S(n146), .Y(n149) );
  INVX1 U178 ( .A(z[2]), .Y(n148) );
  AOI22X1 U179 ( .A(in_valid), .B(n149), .C(n148), .D(n155), .Y(n53) );
  INVX1 U180 ( .A(mag[1]), .Y(n152) );
  MUX2X1 U181 ( .B(n152), .A(mag[1]), .S(n100), .Y(n154) );
  INVX1 U182 ( .A(z[1]), .Y(n153) );
  AOI22X1 U183 ( .A(in_valid), .B(n154), .C(n153), .D(n155), .Y(n52) );
  INVX1 U184 ( .A(N12), .Y(n157) );
  INVX1 U185 ( .A(z[0]), .Y(n156) );
  AOI22X1 U186 ( .A(in_valid), .B(n157), .C(n156), .D(n155), .Y(n51) );
endmodule

