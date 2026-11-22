/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : T-2022.03-SP2
// Date      : Sun Nov 22 08:03:58 2026
/////////////////////////////////////////////////////////////


module accumulator ( clk, rst_n, clear, p_valid, p, sat_x, sat_s, payoff_sum, 
        trial_count, acc_overflow, sat_x_seen, sat_s_seen );
  input [1:0] p_valid;
  input [43:0] p;
  input [1:0] sat_x;
  input [1:0] sat_s;
  output [63:0] payoff_sum;
  output [31:0] trial_count;
  input clk, rst_n, clear;
  output acc_overflow, sat_x_seen, sat_s_seen;
  wire   n1022, n1023, n1024, n1025, n1026, n1027, n1028, n1029, n1030, n1031,
         n1032, n1033, n1034, n1035, n1036, n1037, n1038, n1039, n1040, n1041,
         n1042, n1043, n1044, n1045, n1046, n1047, n1048, n1049, n1050, n1051,
         n1052, n1053, n1054, n1055, n1056, n1057, n1058, n1059, n1060, n1061,
         n1062, n1063, n1064, n1065, n1066, n1067, n1068, n1069, n1070, n1071,
         n1072, n1073, n1074, n1075, n1076, n1077, n1078, n1079, n1080, n1081,
         n1082, n1083, n1084, n1085, n1086, n1087, n1088, n1089, n1090, n1091,
         n1092, n1093, n1094, n1095, n1096, n1097, n1098, n1099, n1100, n1101,
         n1102, n1103, n1104, n1105, n1106, n1107, n1108, n1109, n1110, n1111,
         n1112, n1113, n1114, n1115, n1116, n1117, n1118, n1119, n1120,
         g_tree_sx_1__0_, g_tree_ss_1__0_, N36, N37, N55, N56, N57, N58, N59,
         N60, n111, n112, n113, n114, n115, n116, n117, n118, n119, n120, n121,
         n122, n123, n124, n125, n126, n127, n128, n129, n130, n131, n132,
         n133, n134, n135, n136, n137, n138, n139, n140, n141, n142, n143,
         n144, n145, n146, n147, n148, n149, n150, n151, n152, n153, n154,
         n155, n156, n157, n158, n159, n160, n161, n162, n163, n164, n165,
         n166, n167, n168, n169, n170, n171, n172, n173, n174, n175, n176,
         n177, n178, n179, n180, n181, n182, n183, n184, n185, n186, n187,
         n188, n189, n190, n191, n192, n193, n194, n195, n196, n197, n198,
         n199, n200, n201, n202, n203, n204, n205, n206, n207, n208, n209,
         intadd_0_CI, intadd_0_SUM_20_, intadd_0_SUM_19_, intadd_0_SUM_18_,
         intadd_0_SUM_17_, intadd_0_SUM_16_, intadd_0_SUM_15_,
         intadd_0_SUM_14_, intadd_0_SUM_13_, intadd_0_SUM_12_,
         intadd_0_SUM_11_, intadd_0_SUM_10_, intadd_0_SUM_9_, intadd_0_SUM_8_,
         intadd_0_SUM_7_, intadd_0_SUM_6_, intadd_0_SUM_5_, intadd_0_SUM_4_,
         intadd_0_SUM_3_, intadd_0_SUM_2_, intadd_0_SUM_1_, intadd_0_SUM_0_,
         intadd_0_n21, intadd_0_n20, intadd_0_n19, intadd_0_n18, intadd_0_n17,
         intadd_0_n16, intadd_0_n15, intadd_0_n14, intadd_0_n13, intadd_0_n12,
         intadd_0_n11, intadd_0_n10, intadd_0_n9, intadd_0_n8, intadd_0_n7,
         intadd_0_n6, intadd_0_n5, intadd_0_n4, intadd_0_n3, intadd_0_n2,
         intadd_0_n1, intadd_1_A_19_, intadd_1_A_18_, intadd_1_A_17_,
         intadd_1_A_16_, intadd_1_A_15_, intadd_1_A_14_, intadd_1_A_13_,
         intadd_1_A_12_, intadd_1_A_11_, intadd_1_A_10_, intadd_1_A_9_,
         intadd_1_A_8_, intadd_1_A_7_, intadd_1_A_6_, intadd_1_A_5_,
         intadd_1_A_4_, intadd_1_A_3_, intadd_1_A_2_, intadd_1_A_1_,
         intadd_1_A_0_, intadd_1_B_19_, intadd_1_B_18_, intadd_1_B_17_,
         intadd_1_B_16_, intadd_1_B_15_, intadd_1_B_14_, intadd_1_B_13_,
         intadd_1_B_12_, intadd_1_B_11_, intadd_1_B_10_, intadd_1_B_9_,
         intadd_1_B_8_, intadd_1_B_7_, intadd_1_B_6_, intadd_1_B_5_,
         intadd_1_B_4_, intadd_1_B_3_, intadd_1_B_2_, intadd_1_B_1_,
         intadd_1_B_0_, intadd_1_CI, intadd_1_SUM_19_, intadd_1_SUM_18_,
         intadd_1_SUM_17_, intadd_1_SUM_16_, intadd_1_SUM_15_,
         intadd_1_SUM_14_, intadd_1_SUM_13_, intadd_1_SUM_12_,
         intadd_1_SUM_11_, intadd_1_SUM_10_, intadd_1_SUM_9_, intadd_1_SUM_8_,
         intadd_1_SUM_7_, intadd_1_SUM_6_, intadd_1_SUM_5_, intadd_1_SUM_4_,
         intadd_1_SUM_3_, intadd_1_SUM_2_, intadd_1_SUM_1_, intadd_1_SUM_0_,
         intadd_1_n20, intadd_1_n19, intadd_1_n18, intadd_1_n17, intadd_1_n16,
         intadd_1_n15, intadd_1_n14, intadd_1_n13, intadd_1_n12, intadd_1_n11,
         intadd_1_n10, intadd_1_n9, intadd_1_n8, intadd_1_n7, intadd_1_n6,
         intadd_1_n5, intadd_1_n4, intadd_1_n3, intadd_1_n2, intadd_1_n1, n210,
         n211, n212, n213, n214, n215, n216, n217, n218, n219, n220, n221,
         n222, n223, n224, n225, n226, n227, n228, n229, n230, n231, n232,
         n233, n234, n235, n236, n237, n238, n239, n240, n241, n242, n243,
         n244, n245, n246, n247, n248, n249, n250, n251, n252, n253, n254,
         n255, n256, n257, n258, n259, n260, n261, n262, n263, n264, n265,
         n266, n267, n268, n269, n270, n271, n272, n273, n274, n275, n276,
         n277, n278, n279, n280, n281, n282, n283, n285, n286, n287, n288,
         n289, n290, n291, n292, n293, n294, n295, n296, n297, n298, n299,
         n300, n301, n302, n303, n304, n306, n307, n309, n310, n312, n313,
         n315, n316, n318, n319, n321, n322, n324, n325, n327, n328, n330,
         n331, n333, n334, n336, n337, n339, n340, n342, n343, n345, n346,
         n348, n349, n351, n352, n354, n355, n356, n357, n358, n359, n360,
         n361, n362, n363, n364, n365, n366, n367, n368, n369, n370, n371,
         n372, n373, n374, n375, n376, n377, n378, n379, n380, n381, n382,
         n383, n384, n385, n386, n387, n388, n389, n390, n391, n392, n393,
         n394, n395, n396, n397, n398, n399, n400, n401, n402, n403, n404,
         n405, n406, n407, n408, n409, n410, n411, n412, n413, n414, n415,
         n416, n417, n418, n419, n420, n421, n422, n423, n427, n428, n429,
         n430, n431, n432, n433, n434, n435, n436, n437, n438, n439, n440,
         n441, n442, n443, n444, n445, n446, n447, n448, n449, n450, n451,
         n452, n453, n454, n455, n456, n457, n458, n459, n460, n461, n462,
         n463, n464, n465, n466, n467, n468, n469, n470, n471, n472, n473,
         n474, n475, n476, n477, n478, n479, n480, n481, n482, n483, n484,
         n485, n486, n487, n488, n489, n490, n491, n492, n493, n494, n495,
         n496, n497, n498, n499, n500, n501, n502, n503, n504, n505, n506,
         n507, n508, n509, n510, n511, n512, n513, n514, n515, n516, n517,
         n518, n519, n520, n521, n522, n523, n524, n525, n526, n527, n528,
         n529, n530, n531, n532, n533, n534, n535, n537, n538, n540, n541,
         n542, n543, n544, n545, n546, n547, n548, n549, n550, n551, n552,
         n553, n554, n653, n654, n655, n656, n657, n658, n659, n660, n661,
         n662, n663, n664, n665, n666, n667, n668, n669, n670, n671, n672,
         n673, n674, n675, n676, n677, n678, n679, n680, n681, n682, n683,
         n684, n685, n686, n687, n688, n689, n690, n691, n692, n693, n694,
         n695, n696, n697, n698, n699, n700, n701, n702, n703, n704, n705,
         n706, n707, n708, n709, n710, n711, n712, n713, n714, n715, n716,
         n717, n718, n719, n720, n721, n722, n723, n724, n725, n726, n727,
         n728, n729, n730, n731, n732, n733, n734, n735, n736, n737, n738,
         n739, n740, n741, n742, n743, n744, n745, n746, n747, n748, n749,
         n750, n751, n752, n753, n754, n755, n756, n757, n758, n759, n760,
         n761, n762, n763, n764, n765, n766, n767, n768, n769, n770, n771,
         n772, n773, n774, n775, n776, n777, n778, n779, n780, n781, n782,
         n783, n784, n785, n786, n787, n788, n789, n790, n791, n792, n793,
         n794, n795, n796, n797, n798, n799, n800, n801, n802, n803, n804,
         n805, n806, n807, n808, n809, n810, n811, n812, n813, n814, n815,
         n816, n817, n818, n819, n820, n821, n822, n823, n824, n825, n826,
         n827, n828, n829, n830, n831, n832, n833, n834, n835, n836, n837,
         n838, n839, n840, n841, n842, n843, n844, n845, n846, n847, n848,
         n849, n850, n851, n852, n853, n854, n855, n856, n857, n858, n859,
         n860, n861, n862, n863, n864, n865, n866, n867, n868, n869, n870,
         n871, n872, n873, n874, n875, n876, n877, n878, n879, n880, n881,
         n882, n883, n884, n885, n886, n887, n888, n889, n890, n891, n892,
         n893, n894, n895, n896, n897, n898, n899, n900, n901, n902, n903,
         n904, n905, n906, n907, n908, n909, n910, n911, n912, n913, n914,
         n915, n916, n917, n918, n919, n920, n921, n922, n923, n924, n925,
         n926, n927, n928, n929, n930, n931, n932, n933, n934, n935, n936,
         n937, n938, n939, n940, n941, n942, n943, n944, n945, n946, n947,
         n948, n949, n950, n951, n952, n953, n954, n955, n956, n957, n958,
         n959, n960, n961, n962, n963, n964, n965, n966, n967, n968, n969,
         n970, n971, n972, n973, n974, n975, n976, n977, n978, n979, n980,
         n981, n982, n983, n984, n985, n986, n987, n988, n989, n990, n991,
         n992, n993, n994, n995, n996, n997, n998, n999, n1000, n1001, n1002,
         n1003, n1004, n1005, n1006, n1007, n1008, n1009, n1010, n1011, n1012,
         n1013, n1014, n1015, n1016, n1017, n1018, n1019, n1020, n1021, n1121;
  wire   [22:0] g_tree_g_level_1__g_node_0__sum_q;
  wire   [1:0] g_tree_g_level_1__g_node_0__count_q;

  DFFSR g_tree_g_level_1__g_node_0__ss_q_reg ( .D(n283), .CLK(clk), .R(n1013), 
        .S(1'b1), .Q(g_tree_ss_1__0_) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_22_ ( .D(n357), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[22]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_21_ ( .D(n356), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[21]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_20_ ( .D(n355), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[20]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_19_ ( .D(n354), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[19]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_18_ ( .D(n352), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[18]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_17_ ( .D(n349), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[17]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_16_ ( .D(n346), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[16]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_15_ ( .D(n343), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[15]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_14_ ( .D(n340), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[14]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_13_ ( .D(n337), .CLK(clk), .R(
        n1013), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[13]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_12_ ( .D(n334), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[12]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_11_ ( .D(n331), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[11]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_10_ ( .D(n328), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[10]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_9_ ( .D(n325), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[9]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_8_ ( .D(n322), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[8]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_7_ ( .D(n319), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[7]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_6_ ( .D(n316), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[6]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_5_ ( .D(n313), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[5]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_4_ ( .D(n310), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[4]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_3_ ( .D(n307), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[3]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_2_ ( .D(n304), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[2]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_1_ ( .D(n292), .CLK(clk), .R(
        n1014), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[1]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_0_ ( .D(n289), .CLK(clk), .R(
        n1015), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[0]) );
  DFFSR g_tree_g_level_1__g_node_0__count_q_reg_1_ ( .D(N60), .CLK(clk), .R(
        n1015), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__count_q[1]) );
  DFFSR g_tree_g_level_1__g_node_0__count_q_reg_0_ ( .D(n286), .CLK(clk), .R(
        n1015), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__count_q[0]) );
  DFFSR g_tree_g_level_1__g_node_0__sx_q_reg ( .D(n537), .CLK(clk), .R(n1013), 
        .S(1'b1), .Q(g_tree_sx_1__0_) );
  DFFSR sat_s_seen_reg ( .D(n208), .CLK(clk), .R(n1015), .S(1'b1), .Q(n1120)
         );
  DFFSR payoff_sum_reg_63_ ( .D(n280), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1022) );
  DFFSR payoff_sum_reg_62_ ( .D(n389), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1023) );
  DFFSR payoff_sum_reg_61_ ( .D(n113), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1024) );
  DFFSR payoff_sum_reg_60_ ( .D(n388), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1025) );
  DFFSR payoff_sum_reg_59_ ( .D(n115), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1026) );
  DFFSR payoff_sum_reg_58_ ( .D(n387), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1027) );
  DFFSR payoff_sum_reg_57_ ( .D(n117), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1028) );
  DFFSR payoff_sum_reg_56_ ( .D(n386), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1029) );
  DFFSR payoff_sum_reg_55_ ( .D(n119), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1030) );
  DFFSR payoff_sum_reg_54_ ( .D(n385), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1031) );
  DFFSR payoff_sum_reg_53_ ( .D(n121), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1032) );
  DFFSR payoff_sum_reg_52_ ( .D(n384), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1033) );
  DFFSR payoff_sum_reg_51_ ( .D(n123), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1034) );
  DFFSR payoff_sum_reg_50_ ( .D(n383), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1035) );
  DFFSR payoff_sum_reg_49_ ( .D(n125), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1036) );
  DFFSR payoff_sum_reg_48_ ( .D(n382), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1037) );
  DFFSR payoff_sum_reg_47_ ( .D(n127), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1038) );
  DFFSR payoff_sum_reg_46_ ( .D(n381), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1039) );
  DFFSR payoff_sum_reg_45_ ( .D(n129), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1040) );
  DFFSR payoff_sum_reg_44_ ( .D(n380), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1041) );
  DFFSR payoff_sum_reg_43_ ( .D(n131), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1042) );
  DFFSR payoff_sum_reg_42_ ( .D(n379), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1043) );
  DFFSR payoff_sum_reg_41_ ( .D(n133), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1044) );
  DFFSR payoff_sum_reg_40_ ( .D(n378), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1045) );
  DFFSR payoff_sum_reg_39_ ( .D(n135), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1046) );
  DFFSR payoff_sum_reg_38_ ( .D(n377), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1047) );
  DFFSR payoff_sum_reg_37_ ( .D(n137), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1048) );
  DFFSR payoff_sum_reg_36_ ( .D(n376), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1049) );
  DFFSR payoff_sum_reg_35_ ( .D(n139), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1050) );
  DFFSR payoff_sum_reg_34_ ( .D(n375), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1051) );
  DFFSR payoff_sum_reg_33_ ( .D(n141), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1052) );
  DFFSR payoff_sum_reg_32_ ( .D(n374), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1053) );
  DFFSR payoff_sum_reg_31_ ( .D(n143), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1054) );
  DFFSR payoff_sum_reg_30_ ( .D(n373), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1055) );
  DFFSR payoff_sum_reg_29_ ( .D(n145), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1056) );
  DFFSR payoff_sum_reg_28_ ( .D(n372), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1057) );
  DFFSR payoff_sum_reg_27_ ( .D(n147), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1058) );
  DFFSR payoff_sum_reg_26_ ( .D(n148), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1059) );
  DFFSR payoff_sum_reg_25_ ( .D(n149), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1060) );
  DFFSR payoff_sum_reg_24_ ( .D(n277), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1061) );
  DFFSR payoff_sum_reg_23_ ( .D(n274), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1062) );
  DFFSR payoff_sum_reg_22_ ( .D(n152), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1063) );
  DFFSR payoff_sum_reg_21_ ( .D(n153), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1064) );
  DFFSR payoff_sum_reg_20_ ( .D(n154), .CLK(clk), .R(n1018), .S(1'b1), .Q(
        n1065) );
  DFFSR payoff_sum_reg_19_ ( .D(n155), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1066) );
  DFFSR payoff_sum_reg_18_ ( .D(n156), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1067) );
  DFFSR payoff_sum_reg_17_ ( .D(n157), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1068) );
  DFFSR payoff_sum_reg_16_ ( .D(n158), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1069) );
  DFFSR payoff_sum_reg_15_ ( .D(n159), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1070) );
  DFFSR payoff_sum_reg_14_ ( .D(n160), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1071) );
  DFFSR payoff_sum_reg_13_ ( .D(n161), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1072) );
  DFFSR payoff_sum_reg_12_ ( .D(n162), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1073) );
  DFFSR payoff_sum_reg_11_ ( .D(n163), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1074) );
  DFFSR payoff_sum_reg_10_ ( .D(n164), .CLK(clk), .R(n1019), .S(1'b1), .Q(
        n1075) );
  DFFSR payoff_sum_reg_9_ ( .D(n165), .CLK(clk), .R(n1019), .S(1'b1), .Q(n1076) );
  DFFSR payoff_sum_reg_8_ ( .D(n166), .CLK(clk), .R(n1019), .S(1'b1), .Q(n1077) );
  DFFSR payoff_sum_reg_7_ ( .D(n167), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n1078) );
  DFFSR payoff_sum_reg_6_ ( .D(n168), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n1079) );
  DFFSR payoff_sum_reg_5_ ( .D(n169), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n1080) );
  DFFSR payoff_sum_reg_4_ ( .D(n170), .CLK(clk), .R(n1020), .S(1'b1), .Q(n1081) );
  DFFSR payoff_sum_reg_3_ ( .D(n171), .CLK(clk), .R(n1021), .S(1'b1), .Q(n1082) );
  DFFSR payoff_sum_reg_2_ ( .D(n172), .CLK(clk), .R(n1019), .S(1'b1), .Q(n1083) );
  DFFSR payoff_sum_reg_1_ ( .D(n301), .CLK(clk), .R(n1013), .S(1'b1), .Q(n1084) );
  DFFSR payoff_sum_reg_0_ ( .D(n298), .CLK(clk), .R(n1018), .S(1'b1), .Q(n1085) );
  DFFSR trial_count_reg_31_ ( .D(n175), .CLK(clk), .R(n1016), .S(1'b1), .Q(
        n1086) );
  DFFSR trial_count_reg_30_ ( .D(n176), .CLK(clk), .R(n1015), .S(1'b1), .Q(
        n1087) );
  DFFSR trial_count_reg_29_ ( .D(n371), .CLK(clk), .R(n1017), .S(1'b1), .Q(
        n1088) );
  DFFSR trial_count_reg_28_ ( .D(n178), .CLK(clk), .R(n1014), .S(1'b1), .Q(
        n1089) );
  DFFSR trial_count_reg_27_ ( .D(n370), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1090) );
  DFFSR trial_count_reg_26_ ( .D(n180), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1091) );
  DFFSR trial_count_reg_25_ ( .D(n369), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1092) );
  DFFSR trial_count_reg_24_ ( .D(n182), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1093) );
  DFFSR trial_count_reg_23_ ( .D(n368), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1094) );
  DFFSR trial_count_reg_22_ ( .D(n184), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1095) );
  DFFSR trial_count_reg_21_ ( .D(n367), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1096) );
  DFFSR trial_count_reg_20_ ( .D(n186), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1097) );
  DFFSR trial_count_reg_19_ ( .D(n366), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1098) );
  DFFSR trial_count_reg_18_ ( .D(n188), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1099) );
  DFFSR trial_count_reg_17_ ( .D(n365), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1100) );
  DFFSR trial_count_reg_16_ ( .D(n190), .CLK(clk), .R(n1020), .S(1'b1), .Q(
        n1101) );
  DFFSR trial_count_reg_15_ ( .D(n364), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1102) );
  DFFSR trial_count_reg_14_ ( .D(n192), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1103) );
  DFFSR trial_count_reg_13_ ( .D(n363), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1104) );
  DFFSR trial_count_reg_12_ ( .D(n194), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1105) );
  DFFSR trial_count_reg_11_ ( .D(n362), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1106) );
  DFFSR trial_count_reg_10_ ( .D(n196), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1107) );
  DFFSR trial_count_reg_9_ ( .D(n361), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1108) );
  DFFSR trial_count_reg_8_ ( .D(n198), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1109) );
  DFFSR trial_count_reg_7_ ( .D(n360), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1110) );
  DFFSR trial_count_reg_6_ ( .D(n200), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1111) );
  DFFSR trial_count_reg_5_ ( .D(n359), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1112) );
  DFFSR trial_count_reg_4_ ( .D(n202), .CLK(clk), .R(n1021), .S(1'b1), .Q(
        n1113) );
  DFFSR trial_count_reg_3_ ( .D(n271), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1114) );
  DFFSR trial_count_reg_2_ ( .D(n268), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1115) );
  DFFSR trial_count_reg_1_ ( .D(n295), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1116) );
  DFFSR trial_count_reg_0_ ( .D(n358), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1117) );
  DFFSR acc_overflow_reg ( .D(n207), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n1118)
         );
  DFFSR sat_x_seen_reg ( .D(n209), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n1119)
         );
  FAX1 intadd_0_U22 ( .A(n501), .B(payoff_sum[2]), .C(n479), .YC(intadd_0_n21), 
        .YS(intadd_0_SUM_0_) );
  FAX1 intadd_0_U21 ( .A(n502), .B(payoff_sum[3]), .C(intadd_0_n21), .YC(
        intadd_0_n20), .YS(intadd_0_SUM_1_) );
  FAX1 intadd_0_U20 ( .A(n503), .B(payoff_sum[4]), .C(intadd_0_n20), .YC(
        intadd_0_n19), .YS(intadd_0_SUM_2_) );
  FAX1 intadd_0_U19 ( .A(n504), .B(payoff_sum[5]), .C(intadd_0_n19), .YC(
        intadd_0_n18), .YS(intadd_0_SUM_3_) );
  FAX1 intadd_0_U18 ( .A(n505), .B(payoff_sum[6]), .C(intadd_0_n18), .YC(
        intadd_0_n17), .YS(intadd_0_SUM_4_) );
  FAX1 intadd_0_U17 ( .A(n506), .B(payoff_sum[7]), .C(intadd_0_n17), .YC(
        intadd_0_n16), .YS(intadd_0_SUM_5_) );
  FAX1 intadd_0_U16 ( .A(n507), .B(payoff_sum[8]), .C(intadd_0_n16), .YC(
        intadd_0_n15), .YS(intadd_0_SUM_6_) );
  FAX1 intadd_0_U15 ( .A(n508), .B(payoff_sum[9]), .C(intadd_0_n15), .YC(
        intadd_0_n14), .YS(intadd_0_SUM_7_) );
  FAX1 intadd_0_U14 ( .A(n509), .B(payoff_sum[10]), .C(intadd_0_n14), .YC(
        intadd_0_n13), .YS(intadd_0_SUM_8_) );
  FAX1 intadd_0_U13 ( .A(n510), .B(payoff_sum[11]), .C(intadd_0_n13), .YC(
        intadd_0_n12), .YS(intadd_0_SUM_9_) );
  FAX1 intadd_0_U12 ( .A(n511), .B(payoff_sum[12]), .C(intadd_0_n12), .YC(
        intadd_0_n11), .YS(intadd_0_SUM_10_) );
  FAX1 intadd_0_U11 ( .A(n512), .B(payoff_sum[13]), .C(intadd_0_n11), .YC(
        intadd_0_n10), .YS(intadd_0_SUM_11_) );
  FAX1 intadd_0_U10 ( .A(n513), .B(payoff_sum[14]), .C(intadd_0_n10), .YC(
        intadd_0_n9), .YS(intadd_0_SUM_12_) );
  FAX1 intadd_0_U9 ( .A(n514), .B(payoff_sum[15]), .C(intadd_0_n9), .YC(
        intadd_0_n8), .YS(intadd_0_SUM_13_) );
  FAX1 intadd_0_U8 ( .A(n515), .B(payoff_sum[16]), .C(intadd_0_n8), .YC(
        intadd_0_n7), .YS(intadd_0_SUM_14_) );
  FAX1 intadd_0_U7 ( .A(n516), .B(payoff_sum[17]), .C(intadd_0_n7), .YC(
        intadd_0_n6), .YS(intadd_0_SUM_15_) );
  FAX1 intadd_0_U6 ( .A(n517), .B(payoff_sum[18]), .C(intadd_0_n6), .YC(
        intadd_0_n5), .YS(intadd_0_SUM_16_) );
  FAX1 intadd_0_U5 ( .A(n518), .B(payoff_sum[19]), .C(intadd_0_n5), .YC(
        intadd_0_n4), .YS(intadd_0_SUM_17_) );
  FAX1 intadd_0_U4 ( .A(n519), .B(payoff_sum[20]), .C(intadd_0_n4), .YC(
        intadd_0_n3), .YS(intadd_0_SUM_18_) );
  FAX1 intadd_0_U3 ( .A(n520), .B(payoff_sum[21]), .C(intadd_0_n3), .YC(
        intadd_0_n2), .YS(intadd_0_SUM_19_) );
  FAX1 intadd_0_U2 ( .A(n521), .B(payoff_sum[22]), .C(intadd_0_n2), .YC(
        intadd_0_n1), .YS(intadd_0_SUM_20_) );
  FAX1 intadd_1_U21 ( .A(n554), .B(n481), .C(n480), .YC(intadd_1_n20), .YS(
        intadd_1_SUM_0_) );
  FAX1 intadd_1_U20 ( .A(n553), .B(n482), .C(intadd_1_n20), .YC(intadd_1_n19), 
        .YS(intadd_1_SUM_1_) );
  FAX1 intadd_1_U19 ( .A(n522), .B(n483), .C(intadd_1_n19), .YC(intadd_1_n18), 
        .YS(intadd_1_SUM_2_) );
  FAX1 intadd_1_U18 ( .A(n523), .B(n484), .C(intadd_1_n18), .YC(intadd_1_n17), 
        .YS(intadd_1_SUM_3_) );
  FAX1 intadd_1_U17 ( .A(n524), .B(n485), .C(intadd_1_n17), .YC(intadd_1_n16), 
        .YS(intadd_1_SUM_4_) );
  FAX1 intadd_1_U16 ( .A(n525), .B(n486), .C(intadd_1_n16), .YC(intadd_1_n15), 
        .YS(intadd_1_SUM_5_) );
  FAX1 intadd_1_U15 ( .A(n526), .B(n487), .C(intadd_1_n15), .YC(intadd_1_n14), 
        .YS(intadd_1_SUM_6_) );
  FAX1 intadd_1_U14 ( .A(n527), .B(n488), .C(intadd_1_n14), .YC(intadd_1_n13), 
        .YS(intadd_1_SUM_7_) );
  FAX1 intadd_1_U13 ( .A(n552), .B(n489), .C(intadd_1_n13), .YC(intadd_1_n12), 
        .YS(intadd_1_SUM_8_) );
  FAX1 intadd_1_U12 ( .A(n551), .B(n490), .C(intadd_1_n12), .YC(intadd_1_n11), 
        .YS(intadd_1_SUM_9_) );
  FAX1 intadd_1_U11 ( .A(n550), .B(n491), .C(intadd_1_n11), .YC(intadd_1_n10), 
        .YS(intadd_1_SUM_10_) );
  FAX1 intadd_1_U10 ( .A(n549), .B(n492), .C(intadd_1_n10), .YC(intadd_1_n9), 
        .YS(intadd_1_SUM_11_) );
  FAX1 intadd_1_U9 ( .A(n548), .B(n493), .C(intadd_1_n9), .YC(intadd_1_n8), 
        .YS(intadd_1_SUM_12_) );
  FAX1 intadd_1_U8 ( .A(n547), .B(n494), .C(intadd_1_n8), .YC(intadd_1_n7), 
        .YS(intadd_1_SUM_13_) );
  FAX1 intadd_1_U7 ( .A(n546), .B(n495), .C(intadd_1_n7), .YC(intadd_1_n6), 
        .YS(intadd_1_SUM_14_) );
  FAX1 intadd_1_U6 ( .A(n545), .B(n496), .C(intadd_1_n6), .YC(intadd_1_n5), 
        .YS(intadd_1_SUM_15_) );
  FAX1 intadd_1_U5 ( .A(n544), .B(n497), .C(intadd_1_n5), .YC(intadd_1_n4), 
        .YS(intadd_1_SUM_16_) );
  FAX1 intadd_1_U4 ( .A(n543), .B(n498), .C(intadd_1_n4), .YC(intadd_1_n3), 
        .YS(intadd_1_SUM_17_) );
  FAX1 intadd_1_U3 ( .A(n542), .B(n499), .C(intadd_1_n3), .YC(intadd_1_n2), 
        .YS(intadd_1_SUM_18_) );
  FAX1 intadd_1_U2 ( .A(n541), .B(n500), .C(intadd_1_n2), .YC(intadd_1_n1), 
        .YS(intadd_1_SUM_19_) );
  BUFX2 U284 ( .A(n674), .Y(n210) );
  BUFX2 U285 ( .A(n675), .Y(n211) );
  BUFX2 U286 ( .A(n680), .Y(n212) );
  BUFX2 U287 ( .A(n695), .Y(n213) );
  BUFX2 U288 ( .A(n703), .Y(n214) );
  BUFX2 U289 ( .A(n711), .Y(n215) );
  BUFX2 U290 ( .A(n719), .Y(n216) );
  BUFX2 U291 ( .A(n727), .Y(n217) );
  BUFX2 U292 ( .A(n735), .Y(n218) );
  BUFX2 U293 ( .A(n743), .Y(n219) );
  BUFX2 U294 ( .A(n751), .Y(n220) );
  BUFX2 U295 ( .A(n759), .Y(n221) );
  BUFX2 U296 ( .A(n767), .Y(n222) );
  BUFX2 U297 ( .A(n775), .Y(n223) );
  BUFX2 U298 ( .A(n783), .Y(n224) );
  BUFX2 U299 ( .A(n791), .Y(n225) );
  BUFX2 U300 ( .A(n799), .Y(n226) );
  BUFX2 U301 ( .A(n814), .Y(n227) );
  BUFX2 U302 ( .A(n815), .Y(n228) );
  BUFX2 U303 ( .A(n816), .Y(n229) );
  BUFX2 U304 ( .A(n817), .Y(n230) );
  BUFX2 U305 ( .A(n818), .Y(n231) );
  BUFX2 U306 ( .A(n820), .Y(n232) );
  BUFX2 U307 ( .A(n821), .Y(n233) );
  BUFX2 U308 ( .A(n822), .Y(n234) );
  BUFX2 U309 ( .A(n823), .Y(n235) );
  BUFX2 U310 ( .A(n824), .Y(n236) );
  BUFX2 U311 ( .A(n825), .Y(n237) );
  BUFX2 U312 ( .A(n826), .Y(n238) );
  BUFX2 U313 ( .A(n827), .Y(n239) );
  BUFX2 U314 ( .A(n828), .Y(n240) );
  BUFX2 U315 ( .A(n829), .Y(n241) );
  BUFX2 U316 ( .A(n830), .Y(n242) );
  BUFX2 U317 ( .A(n831), .Y(n243) );
  BUFX2 U318 ( .A(n832), .Y(n244) );
  BUFX2 U319 ( .A(n833), .Y(n245) );
  BUFX2 U320 ( .A(n834), .Y(n246) );
  BUFX2 U321 ( .A(n837), .Y(n247) );
  BUFX2 U322 ( .A(n854), .Y(n248) );
  BUFX2 U323 ( .A(n862), .Y(n249) );
  BUFX2 U324 ( .A(n870), .Y(n250) );
  BUFX2 U325 ( .A(n878), .Y(n251) );
  BUFX2 U326 ( .A(n886), .Y(n252) );
  BUFX2 U327 ( .A(n894), .Y(n253) );
  BUFX2 U328 ( .A(n902), .Y(n254) );
  BUFX2 U329 ( .A(n910), .Y(n255) );
  BUFX2 U330 ( .A(n919), .Y(n256) );
  BUFX2 U331 ( .A(n928), .Y(n257) );
  BUFX2 U332 ( .A(n936), .Y(n258) );
  BUFX2 U333 ( .A(n944), .Y(n259) );
  BUFX2 U334 ( .A(n952), .Y(n260) );
  BUFX2 U335 ( .A(n960), .Y(n261) );
  BUFX2 U336 ( .A(n969), .Y(n262) );
  BUFX2 U337 ( .A(n978), .Y(n263) );
  BUFX2 U338 ( .A(n988), .Y(n264) );
  BUFX2 U339 ( .A(n999), .Y(n265) );
  BUFX2 U340 ( .A(n661), .Y(n266) );
  INVX1 U341 ( .A(n269), .Y(n267) );
  INVX1 U342 ( .A(n267), .Y(n268) );
  BUFX2 U343 ( .A(n204), .Y(n269) );
  INVX1 U344 ( .A(n272), .Y(n270) );
  INVX1 U345 ( .A(n270), .Y(n271) );
  BUFX2 U346 ( .A(n203), .Y(n272) );
  INVX1 U347 ( .A(n275), .Y(n273) );
  INVX1 U348 ( .A(n273), .Y(n274) );
  BUFX2 U349 ( .A(n151), .Y(n275) );
  INVX1 U350 ( .A(n278), .Y(n276) );
  INVX1 U351 ( .A(n276), .Y(n277) );
  BUFX2 U352 ( .A(n150), .Y(n278) );
  INVX1 U353 ( .A(n281), .Y(n279) );
  INVX1 U354 ( .A(n279), .Y(n280) );
  BUFX2 U355 ( .A(n111), .Y(n281) );
  INVX1 U357 ( .A(n282), .Y(n283) );
  INVX1 U359 ( .A(n287), .Y(n285) );
  INVX1 U360 ( .A(n285), .Y(n286) );
  BUFX2 U361 ( .A(N59), .Y(n287) );
  INVX1 U362 ( .A(n290), .Y(n288) );
  INVX1 U363 ( .A(n288), .Y(n289) );
  BUFX2 U364 ( .A(N36), .Y(n290) );
  INVX1 U365 ( .A(n293), .Y(n291) );
  INVX1 U366 ( .A(n291), .Y(n292) );
  BUFX2 U367 ( .A(N37), .Y(n293) );
  INVX1 U368 ( .A(n296), .Y(n294) );
  INVX1 U369 ( .A(n294), .Y(n295) );
  BUFX2 U370 ( .A(n205), .Y(n296) );
  INVX1 U371 ( .A(n299), .Y(n297) );
  INVX1 U372 ( .A(n297), .Y(n298) );
  BUFX2 U373 ( .A(n174), .Y(n299) );
  INVX1 U374 ( .A(n302), .Y(n300) );
  INVX1 U375 ( .A(n300), .Y(n301) );
  BUFX2 U376 ( .A(n173), .Y(n302) );
  INVX1 U378 ( .A(n303), .Y(n304) );
  INVX1 U382 ( .A(n306), .Y(n307) );
  INVX1 U386 ( .A(n309), .Y(n310) );
  INVX1 U390 ( .A(n312), .Y(n313) );
  INVX1 U394 ( .A(n315), .Y(n316) );
  INVX1 U398 ( .A(n318), .Y(n319) );
  INVX1 U402 ( .A(n321), .Y(n322) );
  INVX1 U406 ( .A(n324), .Y(n325) );
  INVX1 U410 ( .A(n327), .Y(n328) );
  INVX1 U414 ( .A(n330), .Y(n331) );
  INVX1 U418 ( .A(n333), .Y(n334) );
  INVX1 U422 ( .A(n336), .Y(n337) );
  INVX1 U426 ( .A(n339), .Y(n340) );
  INVX1 U430 ( .A(n342), .Y(n343) );
  INVX1 U434 ( .A(n345), .Y(n346) );
  INVX1 U438 ( .A(n348), .Y(n349) );
  INVX1 U442 ( .A(n351), .Y(n352) );
  AND2X1 U445 ( .A(n696), .B(trial_count[4]), .Y(n702) );
  AND2X1 U446 ( .A(n704), .B(trial_count[6]), .Y(n710) );
  AND2X1 U447 ( .A(n712), .B(trial_count[8]), .Y(n718) );
  AND2X1 U448 ( .A(n720), .B(trial_count[10]), .Y(n726) );
  AND2X1 U449 ( .A(n728), .B(trial_count[12]), .Y(n734) );
  AND2X1 U450 ( .A(n736), .B(trial_count[14]), .Y(n742) );
  AND2X1 U451 ( .A(n744), .B(trial_count[16]), .Y(n750) );
  AND2X1 U452 ( .A(n752), .B(trial_count[18]), .Y(n758) );
  AND2X1 U453 ( .A(n760), .B(trial_count[20]), .Y(n766) );
  AND2X1 U454 ( .A(n768), .B(trial_count[22]), .Y(n774) );
  AND2X1 U455 ( .A(n776), .B(trial_count[24]), .Y(n782) );
  AND2X1 U456 ( .A(n784), .B(trial_count[26]), .Y(n790) );
  AND2X1 U457 ( .A(n792), .B(trial_count[28]), .Y(n798) );
  AND2X1 U458 ( .A(n853), .B(payoff_sum[27]), .Y(n855) );
  AND2X1 U459 ( .A(n861), .B(payoff_sum[29]), .Y(n863) );
  AND2X1 U460 ( .A(n869), .B(payoff_sum[31]), .Y(n871) );
  AND2X1 U461 ( .A(n877), .B(payoff_sum[33]), .Y(n879) );
  AND2X1 U462 ( .A(n885), .B(payoff_sum[35]), .Y(n887) );
  AND2X1 U463 ( .A(n893), .B(payoff_sum[37]), .Y(n895) );
  AND2X1 U464 ( .A(n901), .B(payoff_sum[39]), .Y(n903) );
  AND2X1 U465 ( .A(n909), .B(payoff_sum[41]), .Y(n911) );
  AND2X1 U466 ( .A(n918), .B(payoff_sum[43]), .Y(n920) );
  AND2X1 U467 ( .A(n927), .B(payoff_sum[45]), .Y(n929) );
  AND2X1 U468 ( .A(n935), .B(payoff_sum[47]), .Y(n937) );
  AND2X1 U469 ( .A(n943), .B(payoff_sum[49]), .Y(n945) );
  AND2X1 U470 ( .A(n951), .B(payoff_sum[51]), .Y(n953) );
  AND2X1 U471 ( .A(n959), .B(payoff_sum[53]), .Y(n961) );
  AND2X1 U472 ( .A(n968), .B(payoff_sum[55]), .Y(n970) );
  AND2X1 U473 ( .A(n977), .B(payoff_sum[57]), .Y(n979) );
  AND2X1 U474 ( .A(n987), .B(payoff_sum[59]), .Y(n989) );
  AND2X1 U475 ( .A(n998), .B(payoff_sum[61]), .Y(n1000) );
  AND2X1 U476 ( .A(trial_count[5]), .B(n702), .Y(n704) );
  AND2X1 U477 ( .A(trial_count[7]), .B(n710), .Y(n712) );
  AND2X1 U478 ( .A(trial_count[9]), .B(n718), .Y(n720) );
  AND2X1 U479 ( .A(trial_count[11]), .B(n726), .Y(n728) );
  AND2X1 U480 ( .A(trial_count[13]), .B(n734), .Y(n736) );
  AND2X1 U481 ( .A(trial_count[15]), .B(n742), .Y(n744) );
  AND2X1 U482 ( .A(trial_count[17]), .B(n750), .Y(n752) );
  AND2X1 U483 ( .A(trial_count[19]), .B(n758), .Y(n760) );
  AND2X1 U484 ( .A(trial_count[21]), .B(n766), .Y(n768) );
  AND2X1 U485 ( .A(trial_count[23]), .B(n774), .Y(n776) );
  AND2X1 U486 ( .A(trial_count[25]), .B(n782), .Y(n784) );
  AND2X1 U487 ( .A(trial_count[27]), .B(n790), .Y(n792) );
  AND2X1 U488 ( .A(trial_count[29]), .B(n798), .Y(n800) );
  AND2X1 U489 ( .A(n441), .B(payoff_sum[26]), .Y(n853) );
  AND2X1 U490 ( .A(n855), .B(payoff_sum[28]), .Y(n861) );
  AND2X1 U491 ( .A(n863), .B(payoff_sum[30]), .Y(n869) );
  AND2X1 U492 ( .A(n871), .B(payoff_sum[32]), .Y(n877) );
  AND2X1 U493 ( .A(n879), .B(payoff_sum[34]), .Y(n885) );
  AND2X1 U494 ( .A(n887), .B(payoff_sum[36]), .Y(n893) );
  AND2X1 U495 ( .A(n895), .B(payoff_sum[38]), .Y(n901) );
  AND2X1 U496 ( .A(n903), .B(payoff_sum[40]), .Y(n909) );
  AND2X1 U497 ( .A(n911), .B(payoff_sum[42]), .Y(n918) );
  AND2X1 U498 ( .A(n920), .B(payoff_sum[44]), .Y(n927) );
  AND2X1 U499 ( .A(n929), .B(payoff_sum[46]), .Y(n935) );
  AND2X1 U500 ( .A(n937), .B(payoff_sum[48]), .Y(n943) );
  AND2X1 U501 ( .A(n945), .B(payoff_sum[50]), .Y(n951) );
  AND2X1 U502 ( .A(n953), .B(payoff_sum[52]), .Y(n959) );
  AND2X1 U503 ( .A(n961), .B(payoff_sum[54]), .Y(n968) );
  AND2X1 U504 ( .A(n970), .B(payoff_sum[56]), .Y(n977) );
  AND2X1 U505 ( .A(n979), .B(payoff_sum[58]), .Y(n987) );
  AND2X1 U506 ( .A(n989), .B(payoff_sum[60]), .Y(n998) );
  OR2X1 U507 ( .A(n443), .B(n444), .Y(n665) );
  AND2X1 U508 ( .A(n530), .B(trial_count[0]), .Y(n683) );
  AND2X1 U509 ( .A(payoff_sum[0]), .B(n440), .Y(n807) );
  OR2X1 U510 ( .A(clear), .B(intadd_1_SUM_17_), .Y(N55) );
  INVX1 U511 ( .A(N55), .Y(n354) );
  OR2X1 U512 ( .A(n679), .B(intadd_1_SUM_18_), .Y(N56) );
  INVX1 U513 ( .A(N56), .Y(n355) );
  OR2X1 U514 ( .A(n679), .B(intadd_1_SUM_19_), .Y(N57) );
  INVX1 U515 ( .A(N57), .Y(n356) );
  OR2X1 U516 ( .A(clear), .B(intadd_1_n1), .Y(N58) );
  INVX1 U517 ( .A(N58), .Y(n357) );
  OR2X1 U518 ( .A(n679), .B(n678), .Y(n206) );
  INVX1 U519 ( .A(n206), .Y(n358) );
  AND2X1 U520 ( .A(n393), .B(n700), .Y(n201) );
  INVX1 U521 ( .A(n201), .Y(n359) );
  AND2X1 U522 ( .A(n394), .B(n708), .Y(n199) );
  INVX1 U523 ( .A(n199), .Y(n360) );
  AND2X1 U524 ( .A(n395), .B(n716), .Y(n197) );
  INVX1 U525 ( .A(n197), .Y(n361) );
  AND2X1 U526 ( .A(n396), .B(n724), .Y(n195) );
  INVX1 U527 ( .A(n195), .Y(n362) );
  AND2X1 U528 ( .A(n397), .B(n732), .Y(n193) );
  INVX1 U529 ( .A(n193), .Y(n363) );
  AND2X1 U530 ( .A(n398), .B(n740), .Y(n191) );
  INVX1 U531 ( .A(n191), .Y(n364) );
  AND2X1 U532 ( .A(n399), .B(n748), .Y(n189) );
  INVX1 U533 ( .A(n189), .Y(n365) );
  AND2X1 U534 ( .A(n400), .B(n756), .Y(n187) );
  INVX1 U535 ( .A(n187), .Y(n366) );
  AND2X1 U536 ( .A(n401), .B(n764), .Y(n185) );
  INVX1 U537 ( .A(n185), .Y(n367) );
  AND2X1 U538 ( .A(n402), .B(n772), .Y(n183) );
  INVX1 U539 ( .A(n183), .Y(n368) );
  AND2X1 U540 ( .A(n403), .B(n780), .Y(n181) );
  INVX1 U541 ( .A(n181), .Y(n369) );
  AND2X1 U542 ( .A(n404), .B(n788), .Y(n179) );
  INVX1 U543 ( .A(n179), .Y(n370) );
  AND2X1 U544 ( .A(n405), .B(n796), .Y(n177) );
  INVX1 U545 ( .A(n177), .Y(n371) );
  AND2X1 U546 ( .A(n406), .B(n859), .Y(n146) );
  INVX1 U547 ( .A(n146), .Y(n372) );
  AND2X1 U548 ( .A(n407), .B(n867), .Y(n144) );
  INVX1 U549 ( .A(n144), .Y(n373) );
  AND2X1 U550 ( .A(n408), .B(n875), .Y(n142) );
  INVX1 U551 ( .A(n142), .Y(n374) );
  AND2X1 U552 ( .A(n409), .B(n883), .Y(n140) );
  INVX1 U553 ( .A(n140), .Y(n375) );
  AND2X1 U554 ( .A(n410), .B(n891), .Y(n138) );
  INVX1 U555 ( .A(n138), .Y(n376) );
  AND2X1 U556 ( .A(n411), .B(n899), .Y(n136) );
  INVX1 U557 ( .A(n136), .Y(n377) );
  AND2X1 U558 ( .A(n412), .B(n907), .Y(n134) );
  INVX1 U559 ( .A(n134), .Y(n378) );
  AND2X1 U560 ( .A(n413), .B(n915), .Y(n132) );
  INVX1 U561 ( .A(n132), .Y(n379) );
  AND2X1 U562 ( .A(n414), .B(n924), .Y(n130) );
  INVX1 U563 ( .A(n130), .Y(n380) );
  AND2X1 U564 ( .A(n415), .B(n933), .Y(n128) );
  INVX1 U565 ( .A(n128), .Y(n381) );
  AND2X1 U566 ( .A(n416), .B(n941), .Y(n126) );
  INVX1 U567 ( .A(n126), .Y(n382) );
  AND2X1 U568 ( .A(n417), .B(n949), .Y(n124) );
  INVX1 U569 ( .A(n124), .Y(n383) );
  AND2X1 U570 ( .A(n418), .B(n957), .Y(n122) );
  INVX1 U571 ( .A(n122), .Y(n384) );
  AND2X1 U572 ( .A(n419), .B(n965), .Y(n120) );
  INVX1 U573 ( .A(n120), .Y(n385) );
  AND2X1 U574 ( .A(n420), .B(n974), .Y(n118) );
  INVX1 U575 ( .A(n118), .Y(n386) );
  AND2X1 U576 ( .A(n421), .B(n983), .Y(n116) );
  INVX1 U577 ( .A(n116), .Y(n387) );
  AND2X1 U578 ( .A(n422), .B(n994), .Y(n114) );
  INVX1 U579 ( .A(n114), .Y(n388) );
  AND2X1 U580 ( .A(n423), .B(n1005), .Y(n112) );
  INVX1 U581 ( .A(n112), .Y(n389) );
  BUFX2 U582 ( .A(n850), .Y(n390) );
  AND2X1 U583 ( .A(acc_overflow), .B(n685), .Y(n677) );
  INVX1 U584 ( .A(n677), .Y(n391) );
  AND2X1 U585 ( .A(payoff_sum[25]), .B(n847), .Y(n844) );
  INVX1 U586 ( .A(n844), .Y(n392) );
  BUFX2 U587 ( .A(n701), .Y(n393) );
  BUFX2 U588 ( .A(n709), .Y(n394) );
  BUFX2 U589 ( .A(n717), .Y(n395) );
  BUFX2 U590 ( .A(n725), .Y(n396) );
  BUFX2 U591 ( .A(n733), .Y(n397) );
  BUFX2 U592 ( .A(n741), .Y(n398) );
  BUFX2 U593 ( .A(n749), .Y(n399) );
  BUFX2 U594 ( .A(n757), .Y(n400) );
  BUFX2 U595 ( .A(n765), .Y(n401) );
  BUFX2 U596 ( .A(n773), .Y(n402) );
  BUFX2 U597 ( .A(n781), .Y(n403) );
  BUFX2 U598 ( .A(n789), .Y(n404) );
  BUFX2 U599 ( .A(n797), .Y(n405) );
  BUFX2 U600 ( .A(n860), .Y(n406) );
  BUFX2 U601 ( .A(n868), .Y(n407) );
  BUFX2 U602 ( .A(n876), .Y(n408) );
  BUFX2 U603 ( .A(n884), .Y(n409) );
  BUFX2 U604 ( .A(n892), .Y(n410) );
  BUFX2 U605 ( .A(n900), .Y(n411) );
  BUFX2 U606 ( .A(n908), .Y(n412) );
  BUFX2 U607 ( .A(n916), .Y(n413) );
  BUFX2 U608 ( .A(n925), .Y(n414) );
  BUFX2 U609 ( .A(n934), .Y(n415) );
  BUFX2 U610 ( .A(n942), .Y(n416) );
  BUFX2 U611 ( .A(n950), .Y(n417) );
  BUFX2 U612 ( .A(n958), .Y(n418) );
  BUFX2 U613 ( .A(n966), .Y(n419) );
  BUFX2 U614 ( .A(n975), .Y(n420) );
  BUFX2 U615 ( .A(n984), .Y(n421) );
  BUFX2 U616 ( .A(n995), .Y(n422) );
  BUFX2 U617 ( .A(n1006), .Y(n423) );
  AND2X1 U618 ( .A(sat_s[1]), .B(n672), .Y(n655) );
  AND2X1 U620 ( .A(sat_x[1]), .B(n672), .Y(n658) );
  AND2X1 U622 ( .A(n673), .B(sat_x[0]), .Y(n659) );
  BUFX2 U624 ( .A(n691), .Y(n427) );
  BUFX2 U625 ( .A(n843), .Y(n428) );
  BUFX2 U626 ( .A(n1012), .Y(n429) );
  BUFX2 U627 ( .A(g_tree_sx_1__0_), .Y(n430) );
  BUFX2 U628 ( .A(g_tree_ss_1__0_), .Y(n431) );
  BUFX2 U629 ( .A(n804), .Y(n432) );
  BUFX2 U630 ( .A(n851), .Y(n433) );
  AND2X1 U631 ( .A(n1009), .B(n848), .Y(n845) );
  INVX1 U632 ( .A(n845), .Y(n434) );
  BUFX2 U633 ( .A(n690), .Y(n435) );
  BUFX2 U634 ( .A(n842), .Y(n436) );
  AND2X1 U635 ( .A(n689), .B(n1009), .Y(n686) );
  INVX1 U636 ( .A(n686), .Y(n437) );
  AND2X1 U637 ( .A(n1009), .B(intadd_0_n1), .Y(n838) );
  INVX1 U638 ( .A(n838), .Y(n438) );
  AND2X1 U639 ( .A(n532), .B(n533), .Y(n684) );
  INVX1 U640 ( .A(n684), .Y(n439) );
  BUFX2 U641 ( .A(g_tree_g_level_1__g_node_0__sum_q[0]), .Y(n440) );
  OR2X1 U642 ( .A(n529), .B(n848), .Y(n849) );
  INVX1 U643 ( .A(n849), .Y(n441) );
  BUFX2 U644 ( .A(n694), .Y(n442) );
  AND2X1 U645 ( .A(n672), .B(p[22]), .Y(n663) );
  INVX1 U646 ( .A(n663), .Y(n443) );
  AND2X1 U647 ( .A(n673), .B(p[0]), .Y(n664) );
  INVX1 U648 ( .A(n664), .Y(n444) );
  AND2X1 U649 ( .A(n1000), .B(payoff_sum[62]), .Y(n1008) );
  INVX1 U650 ( .A(n1008), .Y(n445) );
  OR2X1 U651 ( .A(trial_count[4]), .B(n976), .Y(n699) );
  INVX1 U652 ( .A(n699), .Y(n446) );
  OR2X1 U653 ( .A(trial_count[6]), .B(n967), .Y(n707) );
  INVX1 U654 ( .A(n707), .Y(n447) );
  OR2X1 U655 ( .A(trial_count[8]), .B(n967), .Y(n715) );
  INVX1 U656 ( .A(n715), .Y(n448) );
  OR2X1 U657 ( .A(trial_count[10]), .B(n967), .Y(n723) );
  INVX1 U658 ( .A(n723), .Y(n449) );
  OR2X1 U659 ( .A(trial_count[12]), .B(n976), .Y(n731) );
  INVX1 U660 ( .A(n731), .Y(n450) );
  OR2X1 U661 ( .A(trial_count[14]), .B(n976), .Y(n739) );
  INVX1 U662 ( .A(n739), .Y(n451) );
  OR2X1 U663 ( .A(trial_count[16]), .B(n976), .Y(n747) );
  INVX1 U664 ( .A(n747), .Y(n452) );
  OR2X1 U665 ( .A(trial_count[18]), .B(n976), .Y(n755) );
  INVX1 U666 ( .A(n755), .Y(n453) );
  OR2X1 U667 ( .A(trial_count[20]), .B(n976), .Y(n763) );
  INVX1 U668 ( .A(n763), .Y(n454) );
  OR2X1 U669 ( .A(trial_count[22]), .B(n996), .Y(n771) );
  INVX1 U670 ( .A(n771), .Y(n455) );
  OR2X1 U671 ( .A(trial_count[24]), .B(n976), .Y(n779) );
  INVX1 U672 ( .A(n779), .Y(n456) );
  OR2X1 U673 ( .A(trial_count[26]), .B(n926), .Y(n787) );
  INVX1 U674 ( .A(n787), .Y(n457) );
  OR2X1 U675 ( .A(trial_count[28]), .B(n926), .Y(n795) );
  INVX1 U676 ( .A(n795), .Y(n458) );
  OR2X1 U677 ( .A(payoff_sum[27]), .B(n976), .Y(n858) );
  INVX1 U678 ( .A(n858), .Y(n459) );
  OR2X1 U679 ( .A(payoff_sum[29]), .B(n976), .Y(n866) );
  INVX1 U680 ( .A(n866), .Y(n460) );
  OR2X1 U681 ( .A(payoff_sum[31]), .B(n976), .Y(n874) );
  INVX1 U682 ( .A(n874), .Y(n461) );
  OR2X1 U683 ( .A(payoff_sum[33]), .B(n976), .Y(n882) );
  INVX1 U684 ( .A(n882), .Y(n462) );
  OR2X1 U685 ( .A(payoff_sum[35]), .B(n976), .Y(n890) );
  INVX1 U686 ( .A(n890), .Y(n463) );
  OR2X1 U687 ( .A(payoff_sum[37]), .B(n976), .Y(n898) );
  INVX1 U688 ( .A(n898), .Y(n464) );
  OR2X1 U689 ( .A(payoff_sum[39]), .B(n976), .Y(n906) );
  INVX1 U690 ( .A(n906), .Y(n465) );
  OR2X1 U691 ( .A(payoff_sum[41]), .B(n976), .Y(n914) );
  INVX1 U692 ( .A(n914), .Y(n466) );
  OR2X1 U693 ( .A(payoff_sum[43]), .B(n967), .Y(n923) );
  INVX1 U694 ( .A(n923), .Y(n467) );
  OR2X1 U695 ( .A(payoff_sum[45]), .B(n967), .Y(n932) );
  INVX1 U696 ( .A(n932), .Y(n468) );
  OR2X1 U697 ( .A(payoff_sum[47]), .B(n967), .Y(n940) );
  INVX1 U698 ( .A(n940), .Y(n469) );
  OR2X1 U699 ( .A(payoff_sum[49]), .B(n967), .Y(n948) );
  INVX1 U700 ( .A(n948), .Y(n470) );
  OR2X1 U701 ( .A(payoff_sum[51]), .B(n967), .Y(n956) );
  INVX1 U702 ( .A(n956), .Y(n471) );
  OR2X1 U703 ( .A(payoff_sum[53]), .B(n967), .Y(n964) );
  INVX1 U704 ( .A(n964), .Y(n472) );
  OR2X1 U705 ( .A(payoff_sum[55]), .B(n996), .Y(n973) );
  INVX1 U706 ( .A(n973), .Y(n473) );
  INVX1 U707 ( .A(n982), .Y(n474) );
  OR2X1 U708 ( .A(payoff_sum[57]), .B(n976), .Y(n982) );
  INVX1 U709 ( .A(n993), .Y(n475) );
  OR2X1 U710 ( .A(payoff_sum[59]), .B(n996), .Y(n993) );
  INVX1 U711 ( .A(n1004), .Y(n476) );
  OR2X1 U712 ( .A(payoff_sum[61]), .B(n996), .Y(n1004) );
  INVX1 U713 ( .A(n812), .Y(n477) );
  AND2X1 U714 ( .A(n810), .B(n809), .Y(n812) );
  INVX1 U715 ( .A(n801), .Y(n478) );
  OR2X1 U716 ( .A(trial_count[30]), .B(n926), .Y(n801) );
  BUFX2 U717 ( .A(intadd_0_CI), .Y(n479) );
  INVX1 U718 ( .A(intadd_1_CI), .Y(n480) );
  AND2X1 U719 ( .A(n672), .B(p[24]), .Y(intadd_1_CI) );
  BUFX2 U720 ( .A(intadd_1_A_0_), .Y(n481) );
  INVX1 U721 ( .A(intadd_1_A_1_), .Y(n482) );
  AND2X1 U722 ( .A(n673), .B(p[3]), .Y(intadd_1_A_1_) );
  INVX1 U723 ( .A(intadd_1_A_2_), .Y(n483) );
  AND2X1 U724 ( .A(n673), .B(p[4]), .Y(intadd_1_A_2_) );
  INVX1 U725 ( .A(intadd_1_A_3_), .Y(n484) );
  AND2X1 U726 ( .A(n673), .B(p[5]), .Y(intadd_1_A_3_) );
  INVX1 U727 ( .A(intadd_1_A_4_), .Y(n485) );
  AND2X1 U728 ( .A(n673), .B(p[6]), .Y(intadd_1_A_4_) );
  INVX1 U729 ( .A(intadd_1_A_5_), .Y(n486) );
  AND2X1 U730 ( .A(n673), .B(p[7]), .Y(intadd_1_A_5_) );
  INVX1 U731 ( .A(intadd_1_A_6_), .Y(n487) );
  AND2X1 U732 ( .A(n673), .B(p[8]), .Y(intadd_1_A_6_) );
  INVX1 U733 ( .A(intadd_1_A_7_), .Y(n488) );
  AND2X1 U734 ( .A(n673), .B(p[9]), .Y(intadd_1_A_7_) );
  INVX1 U735 ( .A(intadd_1_A_8_), .Y(n489) );
  AND2X1 U736 ( .A(n673), .B(p[10]), .Y(intadd_1_A_8_) );
  INVX1 U737 ( .A(intadd_1_A_9_), .Y(n490) );
  AND2X1 U738 ( .A(p_valid[0]), .B(p[11]), .Y(intadd_1_A_9_) );
  INVX1 U739 ( .A(intadd_1_A_10_), .Y(n491) );
  AND2X1 U740 ( .A(p_valid[0]), .B(p[12]), .Y(intadd_1_A_10_) );
  INVX1 U741 ( .A(intadd_1_A_11_), .Y(n492) );
  AND2X1 U742 ( .A(p_valid[0]), .B(p[13]), .Y(intadd_1_A_11_) );
  INVX1 U743 ( .A(intadd_1_A_12_), .Y(n493) );
  AND2X1 U744 ( .A(p_valid[0]), .B(p[14]), .Y(intadd_1_A_12_) );
  INVX1 U745 ( .A(intadd_1_A_13_), .Y(n494) );
  AND2X1 U746 ( .A(p_valid[0]), .B(p[15]), .Y(intadd_1_A_13_) );
  INVX1 U747 ( .A(intadd_1_A_14_), .Y(n495) );
  AND2X1 U748 ( .A(p_valid[0]), .B(p[16]), .Y(intadd_1_A_14_) );
  INVX1 U749 ( .A(intadd_1_A_15_), .Y(n496) );
  AND2X1 U750 ( .A(p_valid[0]), .B(p[17]), .Y(intadd_1_A_15_) );
  INVX1 U751 ( .A(intadd_1_A_16_), .Y(n497) );
  AND2X1 U752 ( .A(p_valid[0]), .B(p[18]), .Y(intadd_1_A_16_) );
  INVX1 U753 ( .A(intadd_1_A_17_), .Y(n498) );
  AND2X1 U754 ( .A(p_valid[0]), .B(p[19]), .Y(intadd_1_A_17_) );
  INVX1 U755 ( .A(intadd_1_A_18_), .Y(n499) );
  AND2X1 U756 ( .A(p_valid[0]), .B(p[20]), .Y(intadd_1_A_18_) );
  INVX1 U757 ( .A(intadd_1_A_19_), .Y(n500) );
  AND2X1 U758 ( .A(p_valid[0]), .B(p[21]), .Y(intadd_1_A_19_) );
  BUFX2 U759 ( .A(g_tree_g_level_1__g_node_0__sum_q[2]), .Y(n501) );
  BUFX2 U760 ( .A(g_tree_g_level_1__g_node_0__sum_q[3]), .Y(n502) );
  BUFX2 U761 ( .A(g_tree_g_level_1__g_node_0__sum_q[4]), .Y(n503) );
  BUFX2 U762 ( .A(g_tree_g_level_1__g_node_0__sum_q[5]), .Y(n504) );
  BUFX2 U763 ( .A(g_tree_g_level_1__g_node_0__sum_q[6]), .Y(n505) );
  BUFX2 U764 ( .A(g_tree_g_level_1__g_node_0__sum_q[7]), .Y(n506) );
  BUFX2 U765 ( .A(g_tree_g_level_1__g_node_0__sum_q[8]), .Y(n507) );
  BUFX2 U766 ( .A(g_tree_g_level_1__g_node_0__sum_q[9]), .Y(n508) );
  BUFX2 U767 ( .A(g_tree_g_level_1__g_node_0__sum_q[10]), .Y(n509) );
  BUFX2 U768 ( .A(g_tree_g_level_1__g_node_0__sum_q[11]), .Y(n510) );
  BUFX2 U769 ( .A(g_tree_g_level_1__g_node_0__sum_q[12]), .Y(n511) );
  BUFX2 U770 ( .A(g_tree_g_level_1__g_node_0__sum_q[13]), .Y(n512) );
  BUFX2 U771 ( .A(g_tree_g_level_1__g_node_0__sum_q[14]), .Y(n513) );
  BUFX2 U772 ( .A(g_tree_g_level_1__g_node_0__sum_q[15]), .Y(n514) );
  BUFX2 U773 ( .A(g_tree_g_level_1__g_node_0__sum_q[16]), .Y(n515) );
  BUFX2 U774 ( .A(g_tree_g_level_1__g_node_0__sum_q[17]), .Y(n516) );
  BUFX2 U775 ( .A(g_tree_g_level_1__g_node_0__sum_q[18]), .Y(n517) );
  BUFX2 U776 ( .A(g_tree_g_level_1__g_node_0__sum_q[19]), .Y(n518) );
  BUFX2 U777 ( .A(g_tree_g_level_1__g_node_0__sum_q[20]), .Y(n519) );
  BUFX2 U778 ( .A(g_tree_g_level_1__g_node_0__sum_q[21]), .Y(n520) );
  BUFX2 U779 ( .A(g_tree_g_level_1__g_node_0__sum_q[22]), .Y(n521) );
  INVX1 U780 ( .A(intadd_1_B_2_), .Y(n522) );
  AND2X1 U781 ( .A(n672), .B(p[26]), .Y(intadd_1_B_2_) );
  INVX1 U782 ( .A(intadd_1_B_3_), .Y(n523) );
  AND2X1 U783 ( .A(n672), .B(p[27]), .Y(intadd_1_B_3_) );
  INVX1 U784 ( .A(intadd_1_B_4_), .Y(n524) );
  AND2X1 U785 ( .A(n672), .B(p[28]), .Y(intadd_1_B_4_) );
  INVX1 U786 ( .A(intadd_1_B_5_), .Y(n525) );
  AND2X1 U787 ( .A(n672), .B(p[29]), .Y(intadd_1_B_5_) );
  INVX1 U788 ( .A(intadd_1_B_6_), .Y(n526) );
  AND2X1 U789 ( .A(n672), .B(p[30]), .Y(intadd_1_B_6_) );
  INVX1 U790 ( .A(intadd_1_B_7_), .Y(n527) );
  AND2X1 U791 ( .A(n672), .B(p[31]), .Y(intadd_1_B_7_) );
  INVX1 U792 ( .A(n529), .Y(n528) );
  BUFX2 U793 ( .A(n846), .Y(n529) );
  BUFX2 U794 ( .A(g_tree_g_level_1__g_node_0__count_q[0]), .Y(n530) );
  INVX1 U795 ( .A(n807), .Y(n531) );
  INVX1 U796 ( .A(n683), .Y(n532) );
  INVX1 U797 ( .A(n534), .Y(n533) );
  BUFX2 U798 ( .A(g_tree_g_level_1__g_node_0__count_q[1]), .Y(n534) );
  INVX1 U799 ( .A(payoff_sum[24]), .Y(n535) );
  BUFX2 U800 ( .A(n1061), .Y(payoff_sum[24]) );
  AND2X1 U802 ( .A(n665), .B(n685), .Y(n662) );
  INVX1 U803 ( .A(n662), .Y(n538) );
  AND2X1 U804 ( .A(p_valid[0]), .B(sat_s[0]), .Y(n656) );
  BUFX2 U806 ( .A(g_tree_g_level_1__g_node_0__sum_q[1]), .Y(n540) );
  AND2X1 U807 ( .A(p_valid[1]), .B(p[43]), .Y(intadd_1_B_19_) );
  INVX1 U808 ( .A(intadd_1_B_19_), .Y(n541) );
  AND2X1 U809 ( .A(p_valid[1]), .B(p[42]), .Y(intadd_1_B_18_) );
  INVX1 U810 ( .A(intadd_1_B_18_), .Y(n542) );
  AND2X1 U811 ( .A(p_valid[1]), .B(p[41]), .Y(intadd_1_B_17_) );
  INVX1 U812 ( .A(intadd_1_B_17_), .Y(n543) );
  AND2X1 U813 ( .A(p_valid[1]), .B(p[40]), .Y(intadd_1_B_16_) );
  INVX1 U814 ( .A(intadd_1_B_16_), .Y(n544) );
  AND2X1 U815 ( .A(p_valid[1]), .B(p[39]), .Y(intadd_1_B_15_) );
  INVX1 U816 ( .A(intadd_1_B_15_), .Y(n545) );
  AND2X1 U817 ( .A(p_valid[1]), .B(p[38]), .Y(intadd_1_B_14_) );
  INVX1 U818 ( .A(intadd_1_B_14_), .Y(n546) );
  AND2X1 U819 ( .A(p_valid[1]), .B(p[37]), .Y(intadd_1_B_13_) );
  INVX1 U820 ( .A(intadd_1_B_13_), .Y(n547) );
  AND2X1 U821 ( .A(p_valid[1]), .B(p[36]), .Y(intadd_1_B_12_) );
  INVX1 U822 ( .A(intadd_1_B_12_), .Y(n548) );
  AND2X1 U823 ( .A(p_valid[1]), .B(p[35]), .Y(intadd_1_B_11_) );
  INVX1 U824 ( .A(intadd_1_B_11_), .Y(n549) );
  AND2X1 U825 ( .A(p_valid[1]), .B(p[34]), .Y(intadd_1_B_10_) );
  INVX1 U826 ( .A(intadd_1_B_10_), .Y(n550) );
  AND2X1 U827 ( .A(p_valid[1]), .B(p[33]), .Y(intadd_1_B_9_) );
  INVX1 U828 ( .A(intadd_1_B_9_), .Y(n551) );
  AND2X1 U829 ( .A(p_valid[1]), .B(p[32]), .Y(intadd_1_B_8_) );
  INVX1 U830 ( .A(intadd_1_B_8_), .Y(n552) );
  AND2X1 U831 ( .A(n672), .B(p[25]), .Y(intadd_1_B_1_) );
  INVX1 U832 ( .A(intadd_1_B_1_), .Y(n553) );
  AND2X1 U833 ( .A(n673), .B(p[2]), .Y(intadd_1_B_0_) );
  INVX1 U834 ( .A(intadd_1_B_0_), .Y(n554) );
  BUFX2 U835 ( .A(n1084), .Y(payoff_sum[1]) );
  BUFX2 U836 ( .A(n1118), .Y(acc_overflow) );
  BUFX2 U837 ( .A(n1120), .Y(sat_s_seen) );
  BUFX2 U838 ( .A(n1119), .Y(sat_x_seen) );
  BUFX2 U839 ( .A(n1060), .Y(payoff_sum[25]) );
  BUFX2 U840 ( .A(n1059), .Y(payoff_sum[26]) );
  BUFX2 U841 ( .A(n1022), .Y(payoff_sum[63]) );
  BUFX2 U842 ( .A(n1114), .Y(trial_count[3]) );
  BUFX2 U843 ( .A(n1086), .Y(trial_count[31]) );
  BUFX2 U844 ( .A(n1117), .Y(trial_count[0]) );
  BUFX2 U845 ( .A(n1023), .Y(payoff_sum[62]) );
  BUFX2 U846 ( .A(n1088), .Y(trial_count[29]) );
  BUFX2 U847 ( .A(n1090), .Y(trial_count[27]) );
  BUFX2 U848 ( .A(n1092), .Y(trial_count[25]) );
  BUFX2 U849 ( .A(n1094), .Y(trial_count[23]) );
  BUFX2 U850 ( .A(n1096), .Y(trial_count[21]) );
  BUFX2 U851 ( .A(n1098), .Y(trial_count[19]) );
  BUFX2 U852 ( .A(n1100), .Y(trial_count[17]) );
  BUFX2 U853 ( .A(n1102), .Y(trial_count[15]) );
  BUFX2 U854 ( .A(n1104), .Y(trial_count[13]) );
  BUFX2 U855 ( .A(n1106), .Y(trial_count[11]) );
  BUFX2 U856 ( .A(n1108), .Y(trial_count[9]) );
  BUFX2 U857 ( .A(n1110), .Y(trial_count[7]) );
  BUFX2 U858 ( .A(n1112), .Y(trial_count[5]) );
  BUFX2 U859 ( .A(n1025), .Y(payoff_sum[60]) );
  BUFX2 U860 ( .A(n1027), .Y(payoff_sum[58]) );
  BUFX2 U861 ( .A(n1029), .Y(payoff_sum[56]) );
  BUFX2 U862 ( .A(n1031), .Y(payoff_sum[54]) );
  BUFX2 U863 ( .A(n1033), .Y(payoff_sum[52]) );
  BUFX2 U864 ( .A(n1035), .Y(payoff_sum[50]) );
  BUFX2 U865 ( .A(n1037), .Y(payoff_sum[48]) );
  BUFX2 U866 ( .A(n1039), .Y(payoff_sum[46]) );
  BUFX2 U867 ( .A(n1041), .Y(payoff_sum[44]) );
  BUFX2 U868 ( .A(n1043), .Y(payoff_sum[42]) );
  BUFX2 U869 ( .A(n1045), .Y(payoff_sum[40]) );
  BUFX2 U870 ( .A(n1047), .Y(payoff_sum[38]) );
  BUFX2 U871 ( .A(n1049), .Y(payoff_sum[36]) );
  BUFX2 U872 ( .A(n1051), .Y(payoff_sum[34]) );
  BUFX2 U873 ( .A(n1053), .Y(payoff_sum[32]) );
  BUFX2 U874 ( .A(n1055), .Y(payoff_sum[30]) );
  BUFX2 U875 ( .A(n1057), .Y(payoff_sum[28]) );
  BUFX2 U876 ( .A(n1115), .Y(trial_count[2]) );
  BUFX2 U877 ( .A(n1063), .Y(payoff_sum[22]) );
  BUFX2 U878 ( .A(n1064), .Y(payoff_sum[21]) );
  BUFX2 U879 ( .A(n1065), .Y(payoff_sum[20]) );
  BUFX2 U880 ( .A(n1066), .Y(payoff_sum[19]) );
  BUFX2 U881 ( .A(n1067), .Y(payoff_sum[18]) );
  BUFX2 U882 ( .A(n1068), .Y(payoff_sum[17]) );
  BUFX2 U883 ( .A(n1069), .Y(payoff_sum[16]) );
  BUFX2 U884 ( .A(n1070), .Y(payoff_sum[15]) );
  BUFX2 U885 ( .A(n1071), .Y(payoff_sum[14]) );
  BUFX2 U886 ( .A(n1072), .Y(payoff_sum[13]) );
  BUFX2 U887 ( .A(n1073), .Y(payoff_sum[12]) );
  BUFX2 U888 ( .A(n1074), .Y(payoff_sum[11]) );
  BUFX2 U889 ( .A(n1075), .Y(payoff_sum[10]) );
  BUFX2 U890 ( .A(n1076), .Y(payoff_sum[9]) );
  BUFX2 U891 ( .A(n1077), .Y(payoff_sum[8]) );
  BUFX2 U892 ( .A(n1078), .Y(payoff_sum[7]) );
  BUFX2 U893 ( .A(n1079), .Y(payoff_sum[6]) );
  BUFX2 U894 ( .A(n1080), .Y(payoff_sum[5]) );
  BUFX2 U895 ( .A(n1081), .Y(payoff_sum[4]) );
  BUFX2 U896 ( .A(n1082), .Y(payoff_sum[3]) );
  BUFX2 U897 ( .A(n1083), .Y(payoff_sum[2]) );
  BUFX2 U898 ( .A(n1024), .Y(payoff_sum[61]) );
  BUFX2 U899 ( .A(n1026), .Y(payoff_sum[59]) );
  BUFX2 U900 ( .A(n1028), .Y(payoff_sum[57]) );
  BUFX2 U901 ( .A(n1030), .Y(payoff_sum[55]) );
  BUFX2 U902 ( .A(n1032), .Y(payoff_sum[53]) );
  BUFX2 U903 ( .A(n1034), .Y(payoff_sum[51]) );
  BUFX2 U904 ( .A(n1036), .Y(payoff_sum[49]) );
  BUFX2 U905 ( .A(n1038), .Y(payoff_sum[47]) );
  BUFX2 U906 ( .A(n1040), .Y(payoff_sum[45]) );
  BUFX2 U907 ( .A(n1042), .Y(payoff_sum[43]) );
  BUFX2 U908 ( .A(n1044), .Y(payoff_sum[41]) );
  BUFX2 U909 ( .A(n1046), .Y(payoff_sum[39]) );
  BUFX2 U910 ( .A(n1048), .Y(payoff_sum[37]) );
  BUFX2 U911 ( .A(n1050), .Y(payoff_sum[35]) );
  BUFX2 U912 ( .A(n1052), .Y(payoff_sum[33]) );
  BUFX2 U913 ( .A(n1054), .Y(payoff_sum[31]) );
  BUFX2 U914 ( .A(n1056), .Y(payoff_sum[29]) );
  BUFX2 U915 ( .A(n1058), .Y(payoff_sum[27]) );
  BUFX2 U916 ( .A(n1089), .Y(trial_count[28]) );
  BUFX2 U917 ( .A(n1091), .Y(trial_count[26]) );
  BUFX2 U918 ( .A(n1093), .Y(trial_count[24]) );
  BUFX2 U919 ( .A(n1095), .Y(trial_count[22]) );
  BUFX2 U920 ( .A(n1097), .Y(trial_count[20]) );
  BUFX2 U921 ( .A(n1099), .Y(trial_count[18]) );
  BUFX2 U922 ( .A(n1101), .Y(trial_count[16]) );
  BUFX2 U923 ( .A(n1103), .Y(trial_count[14]) );
  BUFX2 U924 ( .A(n1105), .Y(trial_count[12]) );
  BUFX2 U925 ( .A(n1107), .Y(trial_count[10]) );
  BUFX2 U926 ( .A(n1109), .Y(trial_count[8]) );
  BUFX2 U927 ( .A(n1111), .Y(trial_count[6]) );
  BUFX2 U928 ( .A(n1113), .Y(trial_count[4]) );
  BUFX2 U929 ( .A(n1085), .Y(payoff_sum[0]) );
  BUFX2 U930 ( .A(n1087), .Y(trial_count[30]) );
  BUFX2 U931 ( .A(n1116), .Y(trial_count[1]) );
  BUFX2 U932 ( .A(n1062), .Y(payoff_sum[23]) );
  INVX1 U933 ( .A(rst_n), .Y(n653) );
  INVX1 U934 ( .A(n653), .Y(n1013) );
  INVX1 U935 ( .A(n653), .Y(n1014) );
  INVX1 U936 ( .A(n653), .Y(n1017) );
  INVX1 U937 ( .A(n653), .Y(n1015) );
  INVX1 U938 ( .A(n653), .Y(n1016) );
  INVX1 U939 ( .A(n653), .Y(n1018) );
  INVX1 U940 ( .A(n653), .Y(n1019) );
  INVX1 U941 ( .A(n653), .Y(n1021) );
  INVX1 U942 ( .A(n653), .Y(n1020) );
  INVX1 U943 ( .A(p_valid[1]), .Y(n654) );
  INVX1 U944 ( .A(n654), .Y(n672) );
  INVX1 U945 ( .A(clear), .Y(n685) );
  INVX1 U946 ( .A(n685), .Y(n679) );
  INVX1 U948 ( .A(p_valid[0]), .Y(n657) );
  INVX1 U949 ( .A(n657), .Y(n673) );
  OAI21X1 U951 ( .A(p_valid[1]), .B(p_valid[0]), .C(n685), .Y(n660) );
  AOI21X1 U952 ( .A(n672), .B(n673), .C(n660), .Y(N59) );
  NAND3X1 U953 ( .A(n685), .B(p_valid[1]), .C(p_valid[0]), .Y(n661) );
  INVX1 U954 ( .A(n266), .Y(N60) );
  AOI21X1 U955 ( .A(n444), .B(n443), .C(n538), .Y(N36) );
  AND2X1 U956 ( .A(p_valid[1]), .B(p[23]), .Y(n671) );
  INVX1 U957 ( .A(n665), .Y(n670) );
  AND2X1 U958 ( .A(p_valid[0]), .B(p[1]), .Y(n669) );
  MUX2X1 U959 ( .B(n665), .A(n670), .S(n669), .Y(n667) );
  OAI21X1 U960 ( .A(n671), .B(n667), .C(n685), .Y(n666) );
  AOI21X1 U961 ( .A(n671), .B(n667), .C(n666), .Y(N37) );
  OR2X1 U962 ( .A(n671), .B(n670), .Y(n668) );
  AOI22X1 U963 ( .A(n671), .B(n670), .C(n669), .D(n668), .Y(intadd_1_A_0_) );
  OR2X1 U964 ( .A(n530), .B(n534), .Y(n810) );
  AND2X1 U965 ( .A(n685), .B(n810), .Y(n836) );
  INVX1 U966 ( .A(n836), .Y(n967) );
  INVX1 U967 ( .A(n967), .Y(n819) );
  INVX1 U968 ( .A(n819), .Y(n986) );
  INVX1 U969 ( .A(n986), .Y(n1009) );
  AOI22X1 U970 ( .A(n430), .B(n1009), .C(sat_x_seen), .D(n685), .Y(n674) );
  INVX1 U971 ( .A(n210), .Y(n209) );
  AOI22X1 U972 ( .A(n431), .B(n1009), .C(sat_s_seen), .D(n685), .Y(n675) );
  INVX1 U973 ( .A(n211), .Y(n208) );
  INVX1 U974 ( .A(payoff_sum[1]), .Y(n813) );
  INVX1 U975 ( .A(n540), .Y(n808) );
  OR2X1 U976 ( .A(n813), .B(n531), .Y(n676) );
  AOI22X1 U977 ( .A(n813), .B(n531), .C(n808), .D(n676), .Y(intadd_0_CI) );
  INVX1 U978 ( .A(n819), .Y(n926) );
  NAND3X1 U979 ( .A(payoff_sum[23]), .B(payoff_sum[24]), .C(intadd_0_n1), .Y(
        n846) );
  INVX1 U980 ( .A(payoff_sum[25]), .Y(n848) );
  OR2X1 U981 ( .A(n926), .B(n445), .Y(n1011) );
  INVX1 U982 ( .A(payoff_sum[63]), .Y(n1010) );
  OAI21X1 U983 ( .A(n1011), .B(n1010), .C(n391), .Y(n207) );
  OAI21X1 U984 ( .A(n530), .B(trial_count[0]), .C(n532), .Y(n678) );
  AOI22X1 U985 ( .A(n534), .B(n532), .C(n683), .D(n533), .Y(n680) );
  INVX1 U986 ( .A(n212), .Y(n682) );
  OAI21X1 U987 ( .A(trial_count[1]), .B(n682), .C(n685), .Y(n681) );
  AOI21X1 U988 ( .A(trial_count[1]), .B(n682), .C(n681), .Y(n205) );
  AOI22X1 U989 ( .A(n683), .B(n534), .C(trial_count[1]), .D(n439), .Y(n694) );
  INVX1 U990 ( .A(n442), .Y(n689) );
  INVX1 U991 ( .A(n836), .Y(n996) );
  AND2X1 U992 ( .A(n685), .B(n996), .Y(n835) );
  INVX1 U993 ( .A(n835), .Y(n985) );
  INVX1 U994 ( .A(n985), .Y(n1007) );
  INVX1 U995 ( .A(n1007), .Y(n997) );
  OAI21X1 U996 ( .A(n926), .B(n689), .C(n997), .Y(n688) );
  INVX1 U997 ( .A(n688), .Y(n687) );
  INVX1 U998 ( .A(trial_count[2]), .Y(n693) );
  AOI22X1 U999 ( .A(trial_count[2]), .B(n687), .C(n437), .D(n693), .Y(n204) );
  AOI21X1 U1000 ( .A(n1009), .B(n693), .C(n688), .Y(n691) );
  NAND3X1 U1001 ( .A(n1009), .B(trial_count[2]), .C(n689), .Y(n690) );
  INVX1 U1002 ( .A(trial_count[3]), .Y(n692) );
  AOI22X1 U1003 ( .A(trial_count[3]), .B(n427), .C(n435), .D(n692), .Y(n203)
         );
  NOR3X1 U1004 ( .A(n442), .B(n693), .C(n692), .Y(n696) );
  INVX1 U1005 ( .A(n836), .Y(n976) );
  OAI21X1 U1006 ( .A(n696), .B(n926), .C(n997), .Y(n698) );
  AOI22X1 U1007 ( .A(n696), .B(n446), .C(trial_count[4]), .D(n698), .Y(n695)
         );
  INVX1 U1008 ( .A(n213), .Y(n202) );
  INVX1 U1009 ( .A(trial_count[5]), .Y(n697) );
  NAND3X1 U1010 ( .A(n697), .B(n702), .C(n819), .Y(n701) );
  OAI21X1 U1011 ( .A(n446), .B(n698), .C(trial_count[5]), .Y(n700) );
  OAI21X1 U1012 ( .A(n704), .B(n926), .C(n997), .Y(n706) );
  AOI22X1 U1013 ( .A(n704), .B(n447), .C(trial_count[6]), .D(n706), .Y(n703)
         );
  INVX1 U1014 ( .A(n214), .Y(n200) );
  INVX1 U1015 ( .A(trial_count[7]), .Y(n705) );
  NAND3X1 U1016 ( .A(n705), .B(n710), .C(n819), .Y(n709) );
  OAI21X1 U1017 ( .A(n447), .B(n706), .C(trial_count[7]), .Y(n708) );
  OAI21X1 U1018 ( .A(n712), .B(n926), .C(n997), .Y(n714) );
  AOI22X1 U1019 ( .A(n712), .B(n448), .C(trial_count[8]), .D(n714), .Y(n711)
         );
  INVX1 U1020 ( .A(n215), .Y(n198) );
  INVX1 U1021 ( .A(trial_count[9]), .Y(n713) );
  NAND3X1 U1022 ( .A(n713), .B(n718), .C(n819), .Y(n717) );
  OAI21X1 U1023 ( .A(n448), .B(n714), .C(trial_count[9]), .Y(n716) );
  OAI21X1 U1024 ( .A(n720), .B(n967), .C(n997), .Y(n722) );
  AOI22X1 U1025 ( .A(n720), .B(n449), .C(trial_count[10]), .D(n722), .Y(n719)
         );
  INVX1 U1026 ( .A(n216), .Y(n196) );
  INVX1 U1027 ( .A(trial_count[11]), .Y(n721) );
  NAND3X1 U1028 ( .A(n721), .B(n726), .C(n819), .Y(n725) );
  OAI21X1 U1029 ( .A(n449), .B(n722), .C(trial_count[11]), .Y(n724) );
  OAI21X1 U1030 ( .A(n728), .B(n926), .C(n997), .Y(n730) );
  AOI22X1 U1031 ( .A(n728), .B(n450), .C(trial_count[12]), .D(n730), .Y(n727)
         );
  INVX1 U1032 ( .A(n217), .Y(n194) );
  INVX1 U1033 ( .A(trial_count[13]), .Y(n729) );
  NAND3X1 U1034 ( .A(n729), .B(n734), .C(n819), .Y(n733) );
  OAI21X1 U1035 ( .A(n450), .B(n730), .C(trial_count[13]), .Y(n732) );
  OAI21X1 U1036 ( .A(n736), .B(n926), .C(n997), .Y(n738) );
  AOI22X1 U1037 ( .A(n736), .B(n451), .C(trial_count[14]), .D(n738), .Y(n735)
         );
  INVX1 U1038 ( .A(n218), .Y(n192) );
  INVX1 U1039 ( .A(trial_count[15]), .Y(n737) );
  NAND3X1 U1040 ( .A(n737), .B(n742), .C(n819), .Y(n741) );
  OAI21X1 U1041 ( .A(n451), .B(n738), .C(trial_count[15]), .Y(n740) );
  OAI21X1 U1042 ( .A(n744), .B(n926), .C(n997), .Y(n746) );
  AOI22X1 U1043 ( .A(n744), .B(n452), .C(trial_count[16]), .D(n746), .Y(n743)
         );
  INVX1 U1044 ( .A(n219), .Y(n190) );
  INVX1 U1045 ( .A(trial_count[17]), .Y(n745) );
  NAND3X1 U1046 ( .A(n745), .B(n750), .C(n819), .Y(n749) );
  OAI21X1 U1047 ( .A(n452), .B(n746), .C(trial_count[17]), .Y(n748) );
  OAI21X1 U1048 ( .A(n752), .B(n996), .C(n997), .Y(n754) );
  AOI22X1 U1049 ( .A(n752), .B(n453), .C(trial_count[18]), .D(n754), .Y(n751)
         );
  INVX1 U1050 ( .A(n220), .Y(n188) );
  INVX1 U1051 ( .A(trial_count[19]), .Y(n753) );
  NAND3X1 U1052 ( .A(n753), .B(n758), .C(n819), .Y(n757) );
  OAI21X1 U1053 ( .A(n453), .B(n754), .C(trial_count[19]), .Y(n756) );
  OAI21X1 U1054 ( .A(n760), .B(n926), .C(n997), .Y(n762) );
  AOI22X1 U1055 ( .A(n760), .B(n454), .C(trial_count[20]), .D(n762), .Y(n759)
         );
  INVX1 U1056 ( .A(n221), .Y(n186) );
  INVX1 U1057 ( .A(trial_count[21]), .Y(n761) );
  NAND3X1 U1058 ( .A(n761), .B(n766), .C(n819), .Y(n765) );
  OAI21X1 U1059 ( .A(n454), .B(n762), .C(trial_count[21]), .Y(n764) );
  OAI21X1 U1060 ( .A(n768), .B(n967), .C(n997), .Y(n770) );
  AOI22X1 U1061 ( .A(n768), .B(n455), .C(trial_count[22]), .D(n770), .Y(n767)
         );
  INVX1 U1062 ( .A(n222), .Y(n184) );
  INVX1 U1063 ( .A(trial_count[23]), .Y(n769) );
  INVX1 U1064 ( .A(n986), .Y(n990) );
  NAND3X1 U1065 ( .A(n769), .B(n774), .C(n990), .Y(n773) );
  OAI21X1 U1066 ( .A(n455), .B(n770), .C(trial_count[23]), .Y(n772) );
  OAI21X1 U1067 ( .A(n776), .B(n986), .C(n997), .Y(n778) );
  AOI22X1 U1068 ( .A(n776), .B(n456), .C(trial_count[24]), .D(n778), .Y(n775)
         );
  INVX1 U1069 ( .A(n223), .Y(n182) );
  INVX1 U1070 ( .A(trial_count[25]), .Y(n777) );
  NAND3X1 U1071 ( .A(n777), .B(n782), .C(n819), .Y(n781) );
  OAI21X1 U1072 ( .A(n456), .B(n778), .C(trial_count[25]), .Y(n780) );
  OAI21X1 U1073 ( .A(n784), .B(n986), .C(n997), .Y(n786) );
  AOI22X1 U1074 ( .A(n784), .B(n457), .C(trial_count[26]), .D(n786), .Y(n783)
         );
  INVX1 U1075 ( .A(n224), .Y(n180) );
  INVX1 U1076 ( .A(trial_count[27]), .Y(n785) );
  NAND3X1 U1077 ( .A(n785), .B(n790), .C(n819), .Y(n789) );
  OAI21X1 U1078 ( .A(n457), .B(n786), .C(trial_count[27]), .Y(n788) );
  INVX1 U1079 ( .A(n1007), .Y(n917) );
  OAI21X1 U1080 ( .A(n792), .B(n996), .C(n917), .Y(n794) );
  AOI22X1 U1081 ( .A(n792), .B(n458), .C(trial_count[28]), .D(n794), .Y(n791)
         );
  INVX1 U1082 ( .A(n225), .Y(n178) );
  INVX1 U1083 ( .A(trial_count[29]), .Y(n793) );
  NAND3X1 U1084 ( .A(n793), .B(n798), .C(n819), .Y(n797) );
  OAI21X1 U1085 ( .A(n458), .B(n794), .C(trial_count[29]), .Y(n796) );
  OAI21X1 U1086 ( .A(n800), .B(n986), .C(n917), .Y(n802) );
  AOI22X1 U1087 ( .A(trial_count[30]), .B(n802), .C(n478), .D(n800), .Y(n799)
         );
  INVX1 U1088 ( .A(n226), .Y(n176) );
  NAND3X1 U1089 ( .A(n1009), .B(trial_count[30]), .C(n800), .Y(n804) );
  OAI21X1 U1090 ( .A(n802), .B(n478), .C(trial_count[31]), .Y(n803) );
  OAI21X1 U1091 ( .A(trial_count[31]), .B(n432), .C(n803), .Y(n175) );
  AND2X1 U1092 ( .A(n440), .B(n810), .Y(n806) );
  OAI21X1 U1093 ( .A(payoff_sum[0]), .B(n806), .C(n685), .Y(n805) );
  AOI21X1 U1094 ( .A(payoff_sum[0]), .B(n806), .C(n805), .Y(n174) );
  MUX2X1 U1095 ( .B(n540), .A(n808), .S(n531), .Y(n809) );
  OAI21X1 U1096 ( .A(n813), .B(n477), .C(n685), .Y(n811) );
  AOI21X1 U1097 ( .A(n813), .B(n477), .C(n811), .Y(n173) );
  INVX1 U1098 ( .A(n986), .Y(n1001) );
  AOI22X1 U1099 ( .A(n1001), .B(intadd_0_SUM_0_), .C(n1007), .D(payoff_sum[2]), 
        .Y(n814) );
  INVX1 U1100 ( .A(n227), .Y(n172) );
  AOI22X1 U1101 ( .A(n1001), .B(intadd_0_SUM_1_), .C(n835), .D(payoff_sum[3]), 
        .Y(n815) );
  INVX1 U1102 ( .A(n228), .Y(n171) );
  AOI22X1 U1103 ( .A(n836), .B(intadd_0_SUM_2_), .C(n835), .D(payoff_sum[4]), 
        .Y(n816) );
  INVX1 U1104 ( .A(n229), .Y(n170) );
  AOI22X1 U1105 ( .A(n1001), .B(intadd_0_SUM_3_), .C(n835), .D(payoff_sum[5]), 
        .Y(n817) );
  INVX1 U1106 ( .A(n230), .Y(n169) );
  AOI22X1 U1107 ( .A(n836), .B(intadd_0_SUM_4_), .C(n835), .D(payoff_sum[6]), 
        .Y(n818) );
  INVX1 U1108 ( .A(n231), .Y(n168) );
  AOI22X1 U1109 ( .A(n819), .B(intadd_0_SUM_5_), .C(n1007), .D(payoff_sum[7]), 
        .Y(n820) );
  INVX1 U1110 ( .A(n232), .Y(n167) );
  AOI22X1 U1111 ( .A(n1001), .B(intadd_0_SUM_6_), .C(n835), .D(payoff_sum[8]), 
        .Y(n821) );
  INVX1 U1112 ( .A(n233), .Y(n166) );
  AOI22X1 U1113 ( .A(n990), .B(intadd_0_SUM_7_), .C(n835), .D(payoff_sum[9]), 
        .Y(n822) );
  INVX1 U1114 ( .A(n234), .Y(n165) );
  AOI22X1 U1115 ( .A(n836), .B(intadd_0_SUM_8_), .C(n835), .D(payoff_sum[10]), 
        .Y(n823) );
  INVX1 U1116 ( .A(n235), .Y(n164) );
  AOI22X1 U1117 ( .A(n1001), .B(intadd_0_SUM_9_), .C(n835), .D(payoff_sum[11]), 
        .Y(n824) );
  INVX1 U1118 ( .A(n236), .Y(n163) );
  AOI22X1 U1119 ( .A(n1009), .B(intadd_0_SUM_10_), .C(n835), .D(payoff_sum[12]), .Y(n825) );
  INVX1 U1120 ( .A(n237), .Y(n162) );
  AOI22X1 U1121 ( .A(n836), .B(intadd_0_SUM_11_), .C(n1007), .D(payoff_sum[13]), .Y(n826) );
  INVX1 U1122 ( .A(n238), .Y(n161) );
  AOI22X1 U1123 ( .A(n1009), .B(intadd_0_SUM_12_), .C(n835), .D(payoff_sum[14]), .Y(n827) );
  INVX1 U1124 ( .A(n239), .Y(n160) );
  AOI22X1 U1125 ( .A(n1009), .B(intadd_0_SUM_13_), .C(n835), .D(payoff_sum[15]), .Y(n828) );
  INVX1 U1126 ( .A(n240), .Y(n159) );
  AOI22X1 U1127 ( .A(n1001), .B(intadd_0_SUM_14_), .C(n1007), .D(
        payoff_sum[16]), .Y(n829) );
  INVX1 U1128 ( .A(n241), .Y(n158) );
  AOI22X1 U1129 ( .A(n1009), .B(intadd_0_SUM_15_), .C(n835), .D(payoff_sum[17]), .Y(n830) );
  INVX1 U1130 ( .A(n242), .Y(n157) );
  AOI22X1 U1131 ( .A(n1001), .B(intadd_0_SUM_16_), .C(n1007), .D(
        payoff_sum[18]), .Y(n831) );
  INVX1 U1132 ( .A(n243), .Y(n156) );
  AOI22X1 U1133 ( .A(n1001), .B(intadd_0_SUM_17_), .C(n1007), .D(
        payoff_sum[19]), .Y(n832) );
  INVX1 U1134 ( .A(n244), .Y(n155) );
  AOI22X1 U1135 ( .A(n1001), .B(intadd_0_SUM_18_), .C(n835), .D(payoff_sum[20]), .Y(n833) );
  INVX1 U1136 ( .A(n245), .Y(n154) );
  AOI22X1 U1137 ( .A(n836), .B(intadd_0_SUM_19_), .C(n835), .D(payoff_sum[21]), 
        .Y(n834) );
  INVX1 U1138 ( .A(n246), .Y(n153) );
  AOI22X1 U1139 ( .A(n836), .B(intadd_0_SUM_20_), .C(n835), .D(payoff_sum[22]), 
        .Y(n837) );
  INVX1 U1140 ( .A(n247), .Y(n152) );
  OAI21X1 U1141 ( .A(intadd_0_n1), .B(n986), .C(n917), .Y(n840) );
  INVX1 U1142 ( .A(n840), .Y(n839) );
  INVX1 U1143 ( .A(payoff_sum[23]), .Y(n841) );
  AOI22X1 U1144 ( .A(payoff_sum[23]), .B(n839), .C(n438), .D(n841), .Y(n151)
         );
  AOI21X1 U1145 ( .A(n1009), .B(n841), .C(n840), .Y(n843) );
  NAND3X1 U1146 ( .A(n1009), .B(payoff_sum[23]), .C(intadd_0_n1), .Y(n842) );
  AOI22X1 U1147 ( .A(payoff_sum[24]), .B(n428), .C(n436), .D(n535), .Y(n150)
         );
  OAI21X1 U1148 ( .A(n528), .B(n996), .C(n917), .Y(n847) );
  OAI21X1 U1149 ( .A(n529), .B(n434), .C(n392), .Y(n149) );
  INVX1 U1150 ( .A(payoff_sum[26]), .Y(n852) );
  AOI21X1 U1151 ( .A(n1009), .B(n848), .C(n847), .Y(n851) );
  NAND3X1 U1152 ( .A(n441), .B(n990), .C(n852), .Y(n850) );
  OAI21X1 U1153 ( .A(n852), .B(n433), .C(n390), .Y(n148) );
  OAI21X1 U1154 ( .A(n853), .B(n996), .C(n917), .Y(n857) );
  AOI22X1 U1155 ( .A(n853), .B(n459), .C(payoff_sum[27]), .D(n857), .Y(n854)
         );
  INVX1 U1156 ( .A(n248), .Y(n147) );
  INVX1 U1157 ( .A(payoff_sum[28]), .Y(n856) );
  NAND3X1 U1158 ( .A(n856), .B(n990), .C(n855), .Y(n860) );
  OAI21X1 U1159 ( .A(n459), .B(n857), .C(payoff_sum[28]), .Y(n859) );
  OAI21X1 U1160 ( .A(n861), .B(n986), .C(n917), .Y(n865) );
  AOI22X1 U1161 ( .A(n861), .B(n460), .C(payoff_sum[29]), .D(n865), .Y(n862)
         );
  INVX1 U1162 ( .A(n249), .Y(n145) );
  INVX1 U1163 ( .A(payoff_sum[30]), .Y(n864) );
  NAND3X1 U1164 ( .A(n864), .B(n990), .C(n863), .Y(n868) );
  OAI21X1 U1165 ( .A(n460), .B(n865), .C(payoff_sum[30]), .Y(n867) );
  OAI21X1 U1166 ( .A(n869), .B(n996), .C(n917), .Y(n873) );
  AOI22X1 U1167 ( .A(n869), .B(n461), .C(payoff_sum[31]), .D(n873), .Y(n870)
         );
  INVX1 U1168 ( .A(n250), .Y(n143) );
  INVX1 U1169 ( .A(payoff_sum[32]), .Y(n872) );
  NAND3X1 U1170 ( .A(n872), .B(n990), .C(n871), .Y(n876) );
  OAI21X1 U1171 ( .A(n461), .B(n873), .C(payoff_sum[32]), .Y(n875) );
  OAI21X1 U1172 ( .A(n877), .B(n926), .C(n917), .Y(n881) );
  AOI22X1 U1173 ( .A(n877), .B(n462), .C(payoff_sum[33]), .D(n881), .Y(n878)
         );
  INVX1 U1174 ( .A(n251), .Y(n141) );
  INVX1 U1175 ( .A(payoff_sum[34]), .Y(n880) );
  NAND3X1 U1176 ( .A(n880), .B(n1001), .C(n879), .Y(n884) );
  OAI21X1 U1177 ( .A(n462), .B(n881), .C(payoff_sum[34]), .Y(n883) );
  OAI21X1 U1178 ( .A(n885), .B(n986), .C(n917), .Y(n889) );
  AOI22X1 U1179 ( .A(n885), .B(n463), .C(payoff_sum[35]), .D(n889), .Y(n886)
         );
  INVX1 U1180 ( .A(n252), .Y(n139) );
  INVX1 U1181 ( .A(payoff_sum[36]), .Y(n888) );
  NAND3X1 U1182 ( .A(n888), .B(n990), .C(n887), .Y(n892) );
  OAI21X1 U1183 ( .A(n463), .B(n889), .C(payoff_sum[36]), .Y(n891) );
  OAI21X1 U1184 ( .A(n893), .B(n926), .C(n917), .Y(n897) );
  AOI22X1 U1185 ( .A(n893), .B(n464), .C(payoff_sum[37]), .D(n897), .Y(n894)
         );
  INVX1 U1186 ( .A(n253), .Y(n137) );
  INVX1 U1187 ( .A(payoff_sum[38]), .Y(n896) );
  NAND3X1 U1188 ( .A(n896), .B(n1001), .C(n895), .Y(n900) );
  OAI21X1 U1189 ( .A(n464), .B(n897), .C(payoff_sum[38]), .Y(n899) );
  OAI21X1 U1190 ( .A(n901), .B(n996), .C(n917), .Y(n905) );
  AOI22X1 U1191 ( .A(n901), .B(n465), .C(payoff_sum[39]), .D(n905), .Y(n902)
         );
  INVX1 U1192 ( .A(n254), .Y(n135) );
  INVX1 U1193 ( .A(payoff_sum[40]), .Y(n904) );
  NAND3X1 U1194 ( .A(n904), .B(n1001), .C(n903), .Y(n908) );
  OAI21X1 U1195 ( .A(n465), .B(n905), .C(payoff_sum[40]), .Y(n907) );
  OAI21X1 U1196 ( .A(n909), .B(n926), .C(n917), .Y(n913) );
  AOI22X1 U1197 ( .A(n909), .B(n466), .C(payoff_sum[41]), .D(n913), .Y(n910)
         );
  INVX1 U1198 ( .A(n255), .Y(n133) );
  INVX1 U1199 ( .A(payoff_sum[42]), .Y(n912) );
  NAND3X1 U1200 ( .A(n912), .B(n990), .C(n911), .Y(n916) );
  OAI21X1 U1201 ( .A(n466), .B(n913), .C(payoff_sum[42]), .Y(n915) );
  OAI21X1 U1202 ( .A(n918), .B(n996), .C(n917), .Y(n922) );
  AOI22X1 U1203 ( .A(n918), .B(n467), .C(payoff_sum[43]), .D(n922), .Y(n919)
         );
  INVX1 U1204 ( .A(n256), .Y(n131) );
  INVX1 U1205 ( .A(payoff_sum[44]), .Y(n921) );
  NAND3X1 U1206 ( .A(n921), .B(n1001), .C(n920), .Y(n925) );
  OAI21X1 U1207 ( .A(n467), .B(n922), .C(payoff_sum[44]), .Y(n924) );
  OAI21X1 U1208 ( .A(n927), .B(n926), .C(n985), .Y(n931) );
  AOI22X1 U1209 ( .A(n927), .B(n468), .C(payoff_sum[45]), .D(n931), .Y(n928)
         );
  INVX1 U1210 ( .A(n257), .Y(n129) );
  INVX1 U1211 ( .A(payoff_sum[46]), .Y(n930) );
  NAND3X1 U1212 ( .A(n930), .B(n990), .C(n929), .Y(n934) );
  OAI21X1 U1213 ( .A(n468), .B(n931), .C(payoff_sum[46]), .Y(n933) );
  OAI21X1 U1214 ( .A(n935), .B(n967), .C(n985), .Y(n939) );
  AOI22X1 U1215 ( .A(n935), .B(n469), .C(payoff_sum[47]), .D(n939), .Y(n936)
         );
  INVX1 U1216 ( .A(n258), .Y(n127) );
  INVX1 U1217 ( .A(payoff_sum[48]), .Y(n938) );
  NAND3X1 U1218 ( .A(n938), .B(n1001), .C(n937), .Y(n942) );
  OAI21X1 U1219 ( .A(n469), .B(n939), .C(payoff_sum[48]), .Y(n941) );
  OAI21X1 U1220 ( .A(n943), .B(n967), .C(n985), .Y(n947) );
  AOI22X1 U1221 ( .A(n943), .B(n470), .C(payoff_sum[49]), .D(n947), .Y(n944)
         );
  INVX1 U1222 ( .A(n259), .Y(n125) );
  INVX1 U1223 ( .A(payoff_sum[50]), .Y(n946) );
  NAND3X1 U1224 ( .A(n946), .B(n990), .C(n945), .Y(n950) );
  OAI21X1 U1225 ( .A(n470), .B(n947), .C(payoff_sum[50]), .Y(n949) );
  OAI21X1 U1226 ( .A(n951), .B(n986), .C(n985), .Y(n955) );
  AOI22X1 U1227 ( .A(n951), .B(n471), .C(payoff_sum[51]), .D(n955), .Y(n952)
         );
  INVX1 U1228 ( .A(n260), .Y(n123) );
  INVX1 U1229 ( .A(payoff_sum[52]), .Y(n954) );
  NAND3X1 U1230 ( .A(n954), .B(n1001), .C(n953), .Y(n958) );
  OAI21X1 U1231 ( .A(n471), .B(n955), .C(payoff_sum[52]), .Y(n957) );
  OAI21X1 U1232 ( .A(n959), .B(n986), .C(n985), .Y(n963) );
  AOI22X1 U1233 ( .A(n959), .B(n472), .C(payoff_sum[53]), .D(n963), .Y(n960)
         );
  INVX1 U1234 ( .A(n261), .Y(n121) );
  INVX1 U1235 ( .A(payoff_sum[54]), .Y(n962) );
  NAND3X1 U1236 ( .A(n962), .B(n990), .C(n961), .Y(n966) );
  OAI21X1 U1237 ( .A(n472), .B(n963), .C(payoff_sum[54]), .Y(n965) );
  OAI21X1 U1238 ( .A(n968), .B(n967), .C(n985), .Y(n972) );
  AOI22X1 U1239 ( .A(n968), .B(n473), .C(payoff_sum[55]), .D(n972), .Y(n969)
         );
  INVX1 U1240 ( .A(n262), .Y(n119) );
  INVX1 U1241 ( .A(payoff_sum[56]), .Y(n971) );
  NAND3X1 U1242 ( .A(n971), .B(n990), .C(n970), .Y(n975) );
  OAI21X1 U1243 ( .A(n473), .B(n972), .C(payoff_sum[56]), .Y(n974) );
  OAI21X1 U1244 ( .A(n977), .B(n986), .C(n985), .Y(n981) );
  AOI22X1 U1245 ( .A(n977), .B(n474), .C(payoff_sum[57]), .D(n981), .Y(n978)
         );
  INVX1 U1246 ( .A(n263), .Y(n117) );
  INVX1 U1247 ( .A(payoff_sum[58]), .Y(n980) );
  NAND3X1 U1248 ( .A(n980), .B(n990), .C(n979), .Y(n984) );
  OAI21X1 U1249 ( .A(n474), .B(n981), .C(payoff_sum[58]), .Y(n983) );
  OAI21X1 U1250 ( .A(n987), .B(n986), .C(n985), .Y(n992) );
  AOI22X1 U1251 ( .A(n987), .B(n475), .C(payoff_sum[59]), .D(n992), .Y(n988)
         );
  INVX1 U1252 ( .A(n264), .Y(n115) );
  INVX1 U1253 ( .A(payoff_sum[60]), .Y(n991) );
  NAND3X1 U1254 ( .A(n991), .B(n990), .C(n989), .Y(n995) );
  OAI21X1 U1255 ( .A(n475), .B(n992), .C(payoff_sum[60]), .Y(n994) );
  OAI21X1 U1256 ( .A(n998), .B(n967), .C(n997), .Y(n1003) );
  AOI22X1 U1257 ( .A(n998), .B(n476), .C(payoff_sum[61]), .D(n1003), .Y(n999)
         );
  INVX1 U1258 ( .A(n265), .Y(n113) );
  INVX1 U1259 ( .A(payoff_sum[62]), .Y(n1002) );
  NAND3X1 U1260 ( .A(n1002), .B(n1001), .C(n1000), .Y(n1006) );
  OAI21X1 U1261 ( .A(n476), .B(n1003), .C(payoff_sum[62]), .Y(n1005) );
  AOI21X1 U1262 ( .A(n1009), .B(n445), .C(n1007), .Y(n1012) );
  AOI22X1 U1263 ( .A(payoff_sum[63]), .B(n429), .C(n1011), .D(n1010), .Y(n111)
         );
  INVX1 U356 ( .A(n1121), .Y(n537) );
  OAI21X1 U358 ( .A(n659), .B(n658), .C(n685), .Y(n1121) );
  OR2X1 U377 ( .A(intadd_1_SUM_0_), .B(n679), .Y(n303) );
  OR2X1 U379 ( .A(intadd_1_SUM_10_), .B(n679), .Y(n333) );
  OR2X1 U380 ( .A(intadd_1_SUM_9_), .B(n679), .Y(n330) );
  OR2X1 U381 ( .A(intadd_1_SUM_8_), .B(n679), .Y(n327) );
  OR2X1 U383 ( .A(intadd_1_SUM_7_), .B(n679), .Y(n324) );
  OR2X1 U384 ( .A(intadd_1_SUM_6_), .B(n679), .Y(n321) );
  OR2X1 U385 ( .A(intadd_1_SUM_5_), .B(n679), .Y(n318) );
  OR2X1 U387 ( .A(intadd_1_SUM_4_), .B(n679), .Y(n315) );
  OR2X1 U388 ( .A(intadd_1_SUM_3_), .B(n679), .Y(n312) );
  OR2X1 U389 ( .A(intadd_1_SUM_2_), .B(n679), .Y(n309) );
  OR2X1 U391 ( .A(intadd_1_SUM_1_), .B(n679), .Y(n306) );
  OR2X1 U392 ( .A(intadd_1_SUM_16_), .B(clear), .Y(n351) );
  OR2X1 U393 ( .A(intadd_1_SUM_15_), .B(clear), .Y(n348) );
  OR2X1 U395 ( .A(intadd_1_SUM_14_), .B(clear), .Y(n345) );
  OR2X1 U396 ( .A(intadd_1_SUM_13_), .B(clear), .Y(n342) );
  OR2X1 U397 ( .A(intadd_1_SUM_12_), .B(clear), .Y(n339) );
  OR2X1 U399 ( .A(intadd_1_SUM_11_), .B(clear), .Y(n336) );
  OAI21X1 U400 ( .A(n656), .B(n655), .C(n685), .Y(n282) );
endmodule

