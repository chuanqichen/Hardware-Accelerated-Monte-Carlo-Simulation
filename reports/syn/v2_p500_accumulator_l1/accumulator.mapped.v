/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : T-2022.03-SP2
// Date      : Sun Nov 22 08:03:51 2026
/////////////////////////////////////////////////////////////


module accumulator ( clk, rst_n, clear, p_valid, p, sat_x, sat_s, payoff_sum, 
        trial_count, acc_overflow, sat_x_seen, sat_s_seen );
  input [0:0] p_valid;
  input [21:0] p;
  input [0:0] sat_x;
  input [0:0] sat_s;
  output [63:0] payoff_sum;
  output [31:0] trial_count;
  input clk, rst_n, clear;
  output acc_overflow, sat_x_seen, sat_s_seen;
  wire   n1045, n1046, n1047, n1048, n1049, n1050, n1051, n1052, n1053, n1054,
         n1055, n1056, n1057, n1058, n1059, n1060, n1061, n1062, n1063, n1064,
         n1065, n1066, n1067, n1068, n1069, n1070, n1071, n1072, n1073, n1074,
         n1075, n1076, n1077, n1078, n1079, n1080, n1081, n1082, n1083, n1084,
         n1085, n1086, n1087, n1088, n1089, n1090, n1091, n1092, n1093, n1094,
         n1095, n1096, n1097, n1098, n1099, n1100, n1101, n1102, n1103, n1104,
         n1105, n1106, n1107, n1108, n1109, n1110, n1111, n1112, n1113, n1114,
         n1115, n1116, n1117, n1118, n1119, n1120, n1121, n1122, n1123, n1124,
         n1125, n1126, n1127, n1128, n1129, n1130, n1131, n1132, n1133, n1134,
         n1135, n1136, n1137, n1138, n1139, n1140, n1141, n1142, n1143, n104,
         n105, n106, n107, n108, n109, n110, n111, n112, n113, n114, n115,
         n116, n117, n118, n119, n120, n121, n122, n123, n124, n125, n126,
         n127, n128, n129, n130, n131, n132, n133, n134, n135, n136, n137,
         n138, n139, n140, n141, n142, n143, n144, n145, n146, n147, n148,
         n149, n150, n151, n152, n153, n154, n155, n156, n157, n158, n159,
         n160, n161, n162, n163, n164, n165, n166, n167, n168, n169, n170,
         n171, n172, n173, n174, n175, n176, n177, n178, n179, n180, n181,
         n182, n183, n184, n185, n186, n187, n188, n189, n190, n191, n192,
         n193, n194, n195, n196, n197, n198, n199, n200, n201, n202, n205,
         n206, n208, n209, n210, n212, n213, n214, n215, n216, n217, n218,
         n219, n220, n221, n222, n223, n224, n225, n226, n227, n228, n229,
         n230, n231, n232, n233, n234, n237, n238, n239, n240, n241, n242,
         n243, n244, n245, n246, n250, n251, n253, n254, n255, n256, n257,
         n258, n259, n260, n261, n262, n263, n264, n265, n266, n267, n268,
         n269, n270, n271, n272, n273, n274, n275, n276, n277, n278, n279,
         n280, n281, n282, n283, n284, n285, n286, n287, n288, n289, n290,
         n291, n292, n293, n294, n295, n296, n297, n298, n299, n300, n301,
         n302, n303, n304, n305, n306, n307, n308, n309, n310, n311, n312,
         n313, n314, n315, n316, n317, n318, n319, n320, n321, n322, n323,
         n324, n325, n326, n327, n328, n329, n330, n331, n332, n333, n334,
         n335, n342, n343, n344, n345, n346, n347, n348, n349, n350, n351,
         n352, n353, n354, n355, n356, n357, n358, n359, n360, n361, n362,
         n363, n364, n365, n366, n367, n368, n369, n370, n372, n373, n374,
         n375, n376, n377, n378, n379, n380, n381, n382, n383, n384, n385,
         n386, n387, n388, n389, n390, n391, n392, n393, n394, n395, n396,
         n397, n398, n399, n400, n401, n402, n406, n407, n408, n409, n410,
         n411, n413, n415, n416, n417, n419, n420, n421, n422, n423, n424,
         n425, n426, n427, n428, n429, n430, n431, n432, n433, n434, n435,
         n436, n437, n438, n439, n440, n441, n442, n443, n444, n445, n446,
         n447, n448, n449, n450, n451, n452, n453, n454, n455, n456, n457,
         n458, n459, n460, n461, n462, n463, n464, n465, n466, n467, n468,
         n469, n470, n471, n472, n473, n474, n475, n476, n477, n478, n479,
         n480, n481, n485, n486, n488, n490, n492, n494, n496, n498, n500,
         n502, n504, n506, n508, n510, n512, n514, n516, n518, n520, n521,
         n522, n523, n524, n525, n526, n527, n528, n608, n611, n612, n613,
         n614, n615, n616, n617, n618, n619, n620, n621, n622, n623, n625,
         n626, n627, n628, n629, n630, n631, n634, n635, n636, n637, n638,
         n639, n641, n642, n643, n644, n645, n646, n647, n648, n649, n650,
         n651, n652, n653, n654, n655, n656, n657, n658, n659, n660, n661,
         n662, n663, n664, n665, n666, n667, n668, n669, n670, n671, n672,
         n673, n674, n675, n676, n677, n678, n679, n680, n681, n682, n683,
         n684, n685, n686, n687, n688, n689, n690, n691, n692, n693, n694,
         n695, n696, n697, n698, n699, n700, n701, n702, n703, n704, n705,
         n706, n707, n708, n709, n710, n711, n712, n713, n714, n715, n716,
         n717, n718, n719, n720, n721, n722, n723, n724, n725, n726, n727,
         n728, n729, n730, n731, n732, n733, n734, n735, n736, n737, n738,
         n739, n740, n741, n742, n743, n744, n745, n746, n747, n748, n749,
         n750, n751, n752, n753, n754, n755, n756, n757, n758, n759, n760,
         n761, n762, n763, n764, n765, n766, n767, n768, n769, n770, n772,
         n773, n774, n775, n776, n777, n778, n780, n781, n782, n783, n784,
         n785, n786, n787, n789, n790, n791, n792, n793, n794, n795, n796,
         n797, n798, n799, n800, n801, n802, n803, n804, n805, n806, n807,
         n809, n810, n811, n812, n813, n814, n816, n817, n818, n819, n820,
         n821, n822, n823, n824, n825, n826, n828, n829, n830, n831, n832,
         n833, n834, n835, n836, n837, n838, n840, n841, n842, n843, n844,
         n845, n846, n847, n848, n849, n850, n851, n852, n853, n854, n855,
         n856, n857, n858, n859, n860, n861, n862, n863, n864, n865, n866,
         n867, n868, n869, n870, n871, n872, n873, n874, n875, n876, n877,
         n878, n879, n880, n881, n882, n883, n884, n885, n886, n887, n888,
         n889, n890, n891, n892, n893, n894, n895, n896, n897, n898, n899,
         n900, n901, n902, n903, n904, n905, n906, n907, n908, n909, n910,
         n911, n912, n914, n915, n916, n917, n918, n919, n921, n922, n923,
         n924, n925, n926, n927, n928, n929, n930, n931, n932, n933, n934,
         n935, n936, n937, n938, n939, n940, n941, n942, n943, n944, n945,
         n946, n947, n948, n949, n950, n951, n952, n953, n954, n955, n956,
         n957, n958, n959, n960, n961, n962, n963, n964, n965, n966, n967,
         n968, n969, n970, n971, n972, n973, n974, n975, n976, n977, n978,
         n979, n980, n981, n982, n983, n984, n985, n986, n987, n988, n989,
         n990, n991, n992, n993, n994, n995, n996, n997, n998, n999, n1000,
         n1001, n1002, n1003, n1004, n1005, n1006, n1007, n1008, n1009, n1010,
         n1011, n1012, n1013, n1014, n1015, n1016, n1017, n1018, n1019, n1020,
         n1021, n1022, n1023, n1024, n1025, n1026, n1027, n1028, n1029, n1030,
         n1031, n1032, n1033, n1034, n1035, n1036, n1037, n1038, n1039, n1040,
         n1041, n1042, n1043, n1044, n1144, n1145, n1146, n1147, n1148, n1149,
         n1150, n1151, n1152, n1153;

  DFFSR sat_s_seen_reg ( .D(n201), .CLK(clk), .R(n1038), .S(1'b1), .Q(n1143)
         );
  DFFSR payoff_sum_reg_63_ ( .D(n104), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1045) );
  DFFSR payoff_sum_reg_62_ ( .D(n105), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1046) );
  DFFSR payoff_sum_reg_61_ ( .D(n106), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1047) );
  DFFSR payoff_sum_reg_60_ ( .D(n107), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1048) );
  DFFSR payoff_sum_reg_59_ ( .D(n108), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1049) );
  DFFSR payoff_sum_reg_58_ ( .D(n109), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1050) );
  DFFSR payoff_sum_reg_57_ ( .D(n110), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1051) );
  DFFSR payoff_sum_reg_56_ ( .D(n111), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1052) );
  DFFSR payoff_sum_reg_55_ ( .D(n112), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1053) );
  DFFSR payoff_sum_reg_54_ ( .D(n113), .CLK(clk), .R(n1038), .S(1'b1), .Q(
        n1054) );
  DFFSR payoff_sum_reg_53_ ( .D(n114), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1055) );
  DFFSR payoff_sum_reg_52_ ( .D(n115), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1056) );
  DFFSR payoff_sum_reg_51_ ( .D(n116), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1057) );
  DFFSR payoff_sum_reg_50_ ( .D(n117), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1058) );
  DFFSR payoff_sum_reg_49_ ( .D(n118), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1059) );
  DFFSR payoff_sum_reg_48_ ( .D(n119), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1060) );
  DFFSR payoff_sum_reg_47_ ( .D(n120), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1061) );
  DFFSR payoff_sum_reg_46_ ( .D(n121), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1062) );
  DFFSR payoff_sum_reg_45_ ( .D(n122), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1063) );
  DFFSR payoff_sum_reg_44_ ( .D(n123), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1064) );
  DFFSR payoff_sum_reg_43_ ( .D(n124), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1065) );
  DFFSR payoff_sum_reg_42_ ( .D(n125), .CLK(clk), .R(n1039), .S(1'b1), .Q(
        n1066) );
  DFFSR payoff_sum_reg_41_ ( .D(n126), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1067) );
  DFFSR payoff_sum_reg_40_ ( .D(n127), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1068) );
  DFFSR payoff_sum_reg_39_ ( .D(n128), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1069) );
  DFFSR payoff_sum_reg_38_ ( .D(n129), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1070) );
  DFFSR payoff_sum_reg_37_ ( .D(n130), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1071) );
  DFFSR payoff_sum_reg_36_ ( .D(n131), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1072) );
  DFFSR payoff_sum_reg_35_ ( .D(n132), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1073) );
  DFFSR payoff_sum_reg_34_ ( .D(n133), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1074) );
  DFFSR payoff_sum_reg_33_ ( .D(n134), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1075) );
  DFFSR payoff_sum_reg_32_ ( .D(n135), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1076) );
  DFFSR payoff_sum_reg_31_ ( .D(n136), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1077) );
  DFFSR payoff_sum_reg_30_ ( .D(n137), .CLK(clk), .R(n1040), .S(1'b1), .Q(
        n1078) );
  DFFSR payoff_sum_reg_29_ ( .D(n138), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1079) );
  DFFSR payoff_sum_reg_28_ ( .D(n139), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1080) );
  DFFSR payoff_sum_reg_27_ ( .D(n140), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1081) );
  DFFSR payoff_sum_reg_26_ ( .D(n141), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1082) );
  DFFSR payoff_sum_reg_25_ ( .D(n142), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1083) );
  DFFSR payoff_sum_reg_24_ ( .D(n143), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1084) );
  DFFSR payoff_sum_reg_23_ ( .D(n144), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1085) );
  DFFSR payoff_sum_reg_22_ ( .D(n145), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1086) );
  DFFSR payoff_sum_reg_21_ ( .D(n146), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1087) );
  DFFSR payoff_sum_reg_20_ ( .D(n147), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1088) );
  DFFSR payoff_sum_reg_19_ ( .D(n148), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1089) );
  DFFSR payoff_sum_reg_18_ ( .D(n149), .CLK(clk), .R(n1041), .S(1'b1), .Q(
        n1090) );
  DFFSR payoff_sum_reg_17_ ( .D(n150), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1091) );
  DFFSR payoff_sum_reg_16_ ( .D(n151), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1092) );
  DFFSR payoff_sum_reg_15_ ( .D(n152), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1093) );
  DFFSR payoff_sum_reg_14_ ( .D(n153), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1094) );
  DFFSR payoff_sum_reg_13_ ( .D(n154), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1095) );
  DFFSR payoff_sum_reg_12_ ( .D(n155), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1096) );
  DFFSR payoff_sum_reg_11_ ( .D(n156), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1097) );
  DFFSR payoff_sum_reg_10_ ( .D(n157), .CLK(clk), .R(n1042), .S(1'b1), .Q(
        n1098) );
  DFFSR payoff_sum_reg_9_ ( .D(n158), .CLK(clk), .R(n1042), .S(1'b1), .Q(n1099) );
  DFFSR payoff_sum_reg_8_ ( .D(n159), .CLK(clk), .R(n1042), .S(1'b1), .Q(n1100) );
  DFFSR payoff_sum_reg_7_ ( .D(n160), .CLK(clk), .R(n1042), .S(1'b1), .Q(n1101) );
  DFFSR payoff_sum_reg_6_ ( .D(n161), .CLK(clk), .R(n1042), .S(1'b1), .Q(n1102) );
  DFFSR payoff_sum_reg_5_ ( .D(n162), .CLK(clk), .R(n1043), .S(1'b1), .Q(n1103) );
  DFFSR payoff_sum_reg_4_ ( .D(n163), .CLK(clk), .R(n1043), .S(1'b1), .Q(n1104) );
  DFFSR payoff_sum_reg_3_ ( .D(n164), .CLK(clk), .R(n1043), .S(1'b1), .Q(n1105) );
  DFFSR payoff_sum_reg_2_ ( .D(n165), .CLK(clk), .R(n1043), .S(1'b1), .Q(n1106) );
  DFFSR payoff_sum_reg_1_ ( .D(n166), .CLK(clk), .R(n1043), .S(1'b1), .Q(n1107) );
  DFFSR payoff_sum_reg_0_ ( .D(n167), .CLK(clk), .R(n1043), .S(1'b1), .Q(n1108) );
  DFFSR trial_count_reg_31_ ( .D(n168), .CLK(clk), .R(n1043), .S(1'b1), .Q(
        n1109) );
  DFFSR trial_count_reg_30_ ( .D(n169), .CLK(clk), .R(n1043), .S(1'b1), .Q(
        n1110) );
  DFFSR trial_count_reg_29_ ( .D(n170), .CLK(clk), .R(n1043), .S(1'b1), .Q(
        n1111) );
  DFFSR trial_count_reg_28_ ( .D(n171), .CLK(clk), .R(n1043), .S(1'b1), .Q(
        n1112) );
  DFFSR trial_count_reg_27_ ( .D(n172), .CLK(clk), .R(n1043), .S(1'b1), .Q(
        n1113) );
  DFFSR trial_count_reg_26_ ( .D(n173), .CLK(clk), .R(n1043), .S(1'b1), .Q(
        n1114) );
  DFFSR trial_count_reg_25_ ( .D(n174), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1115) );
  DFFSR trial_count_reg_24_ ( .D(n175), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1116) );
  DFFSR trial_count_reg_23_ ( .D(n176), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1117) );
  DFFSR trial_count_reg_22_ ( .D(n177), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1118) );
  DFFSR trial_count_reg_21_ ( .D(n178), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1119) );
  DFFSR trial_count_reg_20_ ( .D(n179), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1120) );
  DFFSR trial_count_reg_19_ ( .D(n180), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1121) );
  DFFSR trial_count_reg_18_ ( .D(n181), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1122) );
  DFFSR trial_count_reg_17_ ( .D(n182), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1123) );
  DFFSR trial_count_reg_16_ ( .D(n183), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1124) );
  DFFSR trial_count_reg_15_ ( .D(n184), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1125) );
  DFFSR trial_count_reg_14_ ( .D(n185), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1126) );
  DFFSR trial_count_reg_13_ ( .D(n186), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1127) );
  DFFSR trial_count_reg_12_ ( .D(n187), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1128) );
  DFFSR trial_count_reg_11_ ( .D(n188), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1129) );
  DFFSR trial_count_reg_10_ ( .D(n189), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1130) );
  DFFSR trial_count_reg_9_ ( .D(n190), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1131) );
  DFFSR trial_count_reg_8_ ( .D(n191), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1132) );
  DFFSR trial_count_reg_7_ ( .D(n192), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1133) );
  DFFSR trial_count_reg_6_ ( .D(n193), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1134) );
  DFFSR trial_count_reg_5_ ( .D(n194), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1135) );
  DFFSR trial_count_reg_4_ ( .D(n195), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1136) );
  DFFSR trial_count_reg_3_ ( .D(n196), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1137) );
  DFFSR trial_count_reg_2_ ( .D(n197), .CLK(clk), .R(n1044), .S(1'b1), .Q(
        n1138) );
  DFFSR trial_count_reg_1_ ( .D(n344), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1139) );
  DFFSR trial_count_reg_0_ ( .D(n343), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1140) );
  DFFSR acc_overflow_reg ( .D(n200), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n1141)
         );
  DFFSR sat_x_seen_reg ( .D(n202), .CLK(clk), .R(n1038), .S(1'b1), .Q(n1142)
         );
  AND2X1 U228 ( .A(n753), .B(payoff_sum[28]), .Y(n750) );
  AND2X1 U229 ( .A(n243), .B(p[12]), .Y(n630) );
  OR2X1 U230 ( .A(n435), .B(n474), .Y(n629) );
  AND2X1 U232 ( .A(n242), .B(p[11]), .Y(n627) );
  OR2X1 U233 ( .A(n464), .B(n475), .Y(n622) );
  INVX1 U234 ( .A(n902), .Y(n485) );
  OR2X1 U235 ( .A(n612), .B(payoff_sum[1]), .Y(n895) );
  AND2X1 U236 ( .A(payoff_sum[1]), .B(n612), .Y(n896) );
  AND2X1 U237 ( .A(n237), .B(p[1]), .Y(n612) );
  OR2X1 U238 ( .A(n618), .B(payoff_sum[5]), .Y(n871) );
  AND2X1 U239 ( .A(n241), .B(p[5]), .Y(n618) );
  OR2X1 U240 ( .A(n626), .B(payoff_sum[9]), .Y(n843) );
  AND2X1 U241 ( .A(n238), .B(p[8]), .Y(n625) );
  BUFX2 U244 ( .A(n231), .Y(n205) );
  BUFX2 U245 ( .A(n231), .Y(n206) );
  INVX1 U247 ( .A(n231), .Y(n208) );
  INVX1 U248 ( .A(n231), .Y(n209) );
  INVX1 U249 ( .A(n231), .Y(n210) );
  INVX1 U251 ( .A(n231), .Y(n212) );
  INVX1 U252 ( .A(n205), .Y(n213) );
  INVX1 U253 ( .A(n205), .Y(n214) );
  INVX1 U254 ( .A(n205), .Y(n215) );
  INVX1 U255 ( .A(n205), .Y(n216) );
  INVX1 U256 ( .A(n205), .Y(n217) );
  INVX1 U257 ( .A(n206), .Y(n218) );
  INVX1 U258 ( .A(n206), .Y(n219) );
  INVX1 U259 ( .A(n206), .Y(n220) );
  INVX1 U260 ( .A(n206), .Y(n221) );
  INVX1 U261 ( .A(n206), .Y(n222) );
  INVX1 U262 ( .A(n231), .Y(n223) );
  INVX1 U263 ( .A(n231), .Y(n224) );
  INVX1 U264 ( .A(n231), .Y(n225) );
  INVX1 U265 ( .A(n231), .Y(n226) );
  INVX1 U267 ( .A(p_valid[0]), .Y(n229) );
  INVX1 U270 ( .A(n227), .Y(n232) );
  INVX1 U271 ( .A(n227), .Y(n233) );
  INVX1 U272 ( .A(n227), .Y(n234) );
  INVX1 U275 ( .A(n228), .Y(n237) );
  INVX1 U276 ( .A(n228), .Y(n238) );
  INVX1 U277 ( .A(n228), .Y(n239) );
  INVX1 U278 ( .A(n229), .Y(n240) );
  INVX1 U279 ( .A(n229), .Y(n241) );
  INVX1 U280 ( .A(n229), .Y(n242) );
  INVX1 U281 ( .A(n229), .Y(n243) );
  INVX1 U282 ( .A(n230), .Y(n244) );
  INVX1 U283 ( .A(n230), .Y(n245) );
  INVX1 U284 ( .A(n230), .Y(n246) );
  INVX1 U288 ( .A(n231), .Y(n250) );
  INVX1 U289 ( .A(n231), .Y(n251) );
  AND2X1 U290 ( .A(p_valid[0]), .B(p[9]), .Y(n626) );
  AND2X2 U291 ( .A(n905), .B(payoff_sum[63]), .Y(n906) );
  AND2X2 U294 ( .A(n232), .B(p[0]), .Y(n900) );
  BUFX2 U296 ( .A(n644), .Y(n253) );
  BUFX2 U297 ( .A(n648), .Y(n254) );
  BUFX2 U298 ( .A(n651), .Y(n255) );
  BUFX2 U299 ( .A(n654), .Y(n256) );
  BUFX2 U300 ( .A(n657), .Y(n257) );
  BUFX2 U301 ( .A(n660), .Y(n258) );
  BUFX2 U302 ( .A(n663), .Y(n259) );
  BUFX2 U303 ( .A(n666), .Y(n260) );
  BUFX2 U304 ( .A(n669), .Y(n261) );
  BUFX2 U305 ( .A(n672), .Y(n262) );
  BUFX2 U306 ( .A(n675), .Y(n263) );
  BUFX2 U307 ( .A(n678), .Y(n264) );
  BUFX2 U308 ( .A(n681), .Y(n265) );
  BUFX2 U309 ( .A(n684), .Y(n266) );
  BUFX2 U310 ( .A(n687), .Y(n267) );
  BUFX2 U311 ( .A(n908), .Y(n268) );
  BUFX2 U314 ( .A(n690), .Y(n270) );
  BUFX2 U315 ( .A(n693), .Y(n271) );
  BUFX2 U316 ( .A(n696), .Y(n272) );
  BUFX2 U317 ( .A(n699), .Y(n273) );
  BUFX2 U318 ( .A(n703), .Y(n274) );
  BUFX2 U319 ( .A(n706), .Y(n275) );
  BUFX2 U320 ( .A(n710), .Y(n276) );
  BUFX2 U321 ( .A(n713), .Y(n277) );
  BUFX2 U322 ( .A(n718), .Y(n278) );
  BUFX2 U323 ( .A(n721), .Y(n279) );
  BUFX2 U324 ( .A(n725), .Y(n280) );
  BUFX2 U325 ( .A(n728), .Y(n281) );
  BUFX2 U326 ( .A(n731), .Y(n282) );
  BUFX2 U327 ( .A(n734), .Y(n283) );
  BUFX2 U328 ( .A(n737), .Y(n284) );
  BUFX2 U329 ( .A(n740), .Y(n285) );
  BUFX2 U330 ( .A(n743), .Y(n286) );
  BUFX2 U331 ( .A(n746), .Y(n287) );
  BUFX2 U332 ( .A(n749), .Y(n288) );
  BUFX2 U333 ( .A(n752), .Y(n289) );
  BUFX2 U334 ( .A(n755), .Y(n290) );
  BUFX2 U335 ( .A(n758), .Y(n291) );
  BUFX2 U336 ( .A(n761), .Y(n292) );
  BUFX2 U337 ( .A(n764), .Y(n293) );
  BUFX2 U338 ( .A(n767), .Y(n294) );
  BUFX2 U339 ( .A(n770), .Y(n295) );
  BUFX2 U340 ( .A(n773), .Y(n296) );
  BUFX2 U341 ( .A(n778), .Y(n297) );
  BUFX2 U342 ( .A(n782), .Y(n298) );
  BUFX2 U343 ( .A(n787), .Y(n299) );
  BUFX2 U344 ( .A(n792), .Y(n300) );
  BUFX2 U345 ( .A(n797), .Y(n301) );
  BUFX2 U346 ( .A(n801), .Y(n302) );
  BUFX2 U347 ( .A(n807), .Y(n303) );
  BUFX2 U348 ( .A(n812), .Y(n304) );
  BUFX2 U349 ( .A(n818), .Y(n305) );
  BUFX2 U350 ( .A(n824), .Y(n306) );
  BUFX2 U351 ( .A(n833), .Y(n307) );
  BUFX2 U352 ( .A(n842), .Y(n308) );
  BUFX2 U353 ( .A(n848), .Y(n309) );
  BUFX2 U354 ( .A(n854), .Y(n310) );
  BUFX2 U355 ( .A(n863), .Y(n311) );
  BUFX2 U356 ( .A(n869), .Y(n312) );
  BUFX2 U357 ( .A(n876), .Y(n313) );
  BUFX2 U358 ( .A(n881), .Y(n314) );
  BUFX2 U359 ( .A(n888), .Y(n315) );
  BUFX2 U360 ( .A(n894), .Y(n316) );
  BUFX2 U361 ( .A(n899), .Y(n317) );
  BUFX2 U362 ( .A(n904), .Y(n318) );
  BUFX2 U363 ( .A(n909), .Y(n319) );
  BUFX2 U364 ( .A(n910), .Y(n320) );
  BUFX2 U365 ( .A(n1031), .Y(n321) );
  AND2X1 U367 ( .A(n410), .B(n843), .Y(n845) );
  AND2X1 U368 ( .A(n407), .B(n883), .Y(n885) );
  AND2X1 U369 ( .A(n406), .B(n895), .Y(n897) );
  OR2X1 U370 ( .A(n417), .B(n476), .Y(n857) );
  OR2X1 U371 ( .A(p[10]), .B(payoff_sum[10]), .Y(n837) );
  OR2X1 U373 ( .A(n467), .B(n506), .Y(n927) );
  OR2X1 U374 ( .A(n468), .B(n510), .Y(n977) );
  OR2X1 U375 ( .A(n469), .B(n514), .Y(n991) );
  OR2X1 U376 ( .A(n473), .B(n518), .Y(n1006) );
  OR2X1 U377 ( .A(n611), .B(payoff_sum[13]), .Y(n813) );
  OR2X1 U380 ( .A(n783), .B(payoff_sum[19]), .Y(n636) );
  AND2X1 U381 ( .A(trial_count[29]), .B(n431), .Y(n1032) );
  AND2X1 U382 ( .A(n408), .B(n871), .Y(n873) );
  AND2X1 U383 ( .A(n409), .B(n858), .Y(n860) );
  AND2X1 U385 ( .A(n411), .B(n828), .Y(n830) );
  AND2X1 U387 ( .A(n322), .B(n1021), .Y(n919) );
  AND2X1 U388 ( .A(n323), .B(n1021), .Y(n926) );
  AND2X1 U389 ( .A(n324), .B(n1021), .Y(n934) );
  AND2X1 U390 ( .A(n325), .B(n1021), .Y(n943) );
  AND2X1 U391 ( .A(n326), .B(n1021), .Y(n952) );
  AND2X1 U392 ( .A(n327), .B(n1021), .Y(n961) );
  AND2X1 U393 ( .A(n328), .B(n1021), .Y(n969) );
  AND2X1 U394 ( .A(n329), .B(n1021), .Y(n976) );
  AND2X1 U395 ( .A(n330), .B(n1021), .Y(n983) );
  AND2X1 U396 ( .A(n331), .B(n1021), .Y(n990) );
  AND2X1 U397 ( .A(n332), .B(n1021), .Y(n998) );
  AND2X1 U398 ( .A(n333), .B(n608), .Y(n1005) );
  AND2X1 U399 ( .A(n334), .B(n608), .Y(n1014) );
  AND2X1 U400 ( .A(n335), .B(n608), .Y(n1027) );
  AND2X1 U401 ( .A(trial_count[23]), .B(n429), .Y(n1003) );
  AND2X1 U402 ( .A(trial_count[19]), .B(n428), .Y(n988) );
  AND2X1 U403 ( .A(trial_count[15]), .B(n427), .Y(n974) );
  AND2X1 U404 ( .A(trial_count[27]), .B(n430), .Y(n1024) );
  AND2X1 U405 ( .A(n415), .B(n819), .Y(n821) );
  AND2X1 U406 ( .A(trial_count[13]), .B(n426), .Y(n967) );
  AND2X1 U407 ( .A(trial_count[11]), .B(n425), .Y(n959) );
  AND2X1 U408 ( .A(trial_count[9]), .B(n424), .Y(n950) );
  AND2X1 U409 ( .A(trial_count[7]), .B(n423), .Y(n941) );
  AND2X1 U410 ( .A(trial_count[3]), .B(n422), .Y(n924) );
  BUFX2 U411 ( .A(n916), .Y(n322) );
  BUFX2 U412 ( .A(n923), .Y(n323) );
  BUFX2 U413 ( .A(n930), .Y(n324) );
  BUFX2 U414 ( .A(n939), .Y(n325) );
  BUFX2 U415 ( .A(n948), .Y(n326) );
  BUFX2 U416 ( .A(n957), .Y(n327) );
  BUFX2 U417 ( .A(n966), .Y(n328) );
  BUFX2 U418 ( .A(n973), .Y(n329) );
  BUFX2 U419 ( .A(n980), .Y(n330) );
  BUFX2 U420 ( .A(n987), .Y(n331) );
  BUFX2 U421 ( .A(n995), .Y(n332) );
  BUFX2 U422 ( .A(n1002), .Y(n333) );
  BUFX2 U423 ( .A(n1010), .Y(n334) );
  BUFX2 U424 ( .A(n1022), .Y(n335) );
  AND2X1 U425 ( .A(payoff_sum[21]), .B(n774), .Y(n641) );
  AND2X1 U427 ( .A(payoff_sum[19]), .B(n783), .Y(n638) );
  AND2X1 U429 ( .A(payoff_sum[17]), .B(n793), .Y(n635) );
  BUFX2 U439 ( .A(n199), .Y(n343) );
  BUFX2 U440 ( .A(n198), .Y(n344) );
  BUFX2 U441 ( .A(n623), .Y(n345) );
  BUFX2 U442 ( .A(n918), .Y(n346) );
  BUFX2 U443 ( .A(n921), .Y(n347) );
  BUFX2 U444 ( .A(n925), .Y(n348) );
  BUFX2 U445 ( .A(n928), .Y(n349) );
  BUFX2 U446 ( .A(n933), .Y(n350) );
  BUFX2 U447 ( .A(n937), .Y(n351) );
  BUFX2 U448 ( .A(n942), .Y(n352) );
  BUFX2 U449 ( .A(n946), .Y(n353) );
  BUFX2 U450 ( .A(n951), .Y(n354) );
  BUFX2 U451 ( .A(n955), .Y(n355) );
  BUFX2 U452 ( .A(n960), .Y(n356) );
  BUFX2 U453 ( .A(n964), .Y(n357) );
  BUFX2 U454 ( .A(n971), .Y(n358) );
  BUFX2 U455 ( .A(n975), .Y(n359) );
  BUFX2 U456 ( .A(n978), .Y(n360) );
  BUFX2 U457 ( .A(n982), .Y(n361) );
  BUFX2 U458 ( .A(n985), .Y(n362) );
  BUFX2 U459 ( .A(n989), .Y(n363) );
  BUFX2 U460 ( .A(n993), .Y(n364) );
  BUFX2 U461 ( .A(n1000), .Y(n365) );
  BUFX2 U462 ( .A(n1004), .Y(n366) );
  BUFX2 U463 ( .A(n1008), .Y(n367) );
  BUFX2 U464 ( .A(n1013), .Y(n368) );
  BUFX2 U465 ( .A(n1019), .Y(n369) );
  BUFX2 U466 ( .A(n1026), .Y(n370) );
  INVX1 U469 ( .A(n629), .Y(n372) );
  OR2X1 U470 ( .A(n465), .B(n477), .Y(n616) );
  INVX1 U471 ( .A(n616), .Y(n373) );
  BUFX2 U473 ( .A(n922), .Y(n375) );
  BUFX2 U474 ( .A(n929), .Y(n376) );
  BUFX2 U475 ( .A(n938), .Y(n377) );
  BUFX2 U476 ( .A(n947), .Y(n378) );
  BUFX2 U477 ( .A(n956), .Y(n379) );
  BUFX2 U478 ( .A(n965), .Y(n380) );
  BUFX2 U479 ( .A(n972), .Y(n381) );
  BUFX2 U480 ( .A(n979), .Y(n382) );
  BUFX2 U481 ( .A(n986), .Y(n383) );
  BUFX2 U482 ( .A(n994), .Y(n384) );
  BUFX2 U483 ( .A(n1001), .Y(n385) );
  BUFX2 U484 ( .A(n1009), .Y(n386) );
  BUFX2 U485 ( .A(n1020), .Y(n387) );
  BUFX2 U486 ( .A(n1037), .Y(n388) );
  INVX1 U487 ( .A(n919), .Y(n389) );
  INVX1 U488 ( .A(n926), .Y(n390) );
  INVX1 U489 ( .A(n934), .Y(n391) );
  INVX1 U490 ( .A(n943), .Y(n392) );
  INVX1 U491 ( .A(n952), .Y(n393) );
  INVX1 U492 ( .A(n961), .Y(n394) );
  INVX1 U493 ( .A(n969), .Y(n395) );
  INVX1 U494 ( .A(n976), .Y(n396) );
  INVX1 U495 ( .A(n983), .Y(n397) );
  INVX1 U496 ( .A(n990), .Y(n398) );
  INVX1 U497 ( .A(n998), .Y(n399) );
  INVX1 U498 ( .A(n1005), .Y(n400) );
  INVX1 U499 ( .A(n1014), .Y(n401) );
  INVX1 U500 ( .A(n1027), .Y(n402) );
  AND2X1 U501 ( .A(payoff_sum[13]), .B(n611), .Y(n814) );
  AND2X1 U503 ( .A(payoff_sum[10]), .B(p[10]), .Y(n838) );
  OR2X1 U505 ( .A(n466), .B(n478), .Y(n834) );
  INVX1 U507 ( .A(n896), .Y(n406) );
  AND2X1 U508 ( .A(payoff_sum[3]), .B(n614), .Y(n884) );
  INVX1 U509 ( .A(n884), .Y(n407) );
  AND2X1 U510 ( .A(payoff_sum[5]), .B(n618), .Y(n872) );
  INVX1 U511 ( .A(n872), .Y(n408) );
  AND2X1 U512 ( .A(payoff_sum[7]), .B(n620), .Y(n859) );
  INVX1 U513 ( .A(n859), .Y(n409) );
  AND2X1 U514 ( .A(payoff_sum[9]), .B(n626), .Y(n844) );
  INVX1 U515 ( .A(n844), .Y(n410) );
  AND2X1 U516 ( .A(payoff_sum[11]), .B(n627), .Y(n829) );
  INVX1 U517 ( .A(n829), .Y(n411) );
  AND2X1 U518 ( .A(payoff_sum[15]), .B(n802), .Y(n413) );
  AND2X1 U520 ( .A(payoff_sum[12]), .B(n630), .Y(n820) );
  INVX1 U521 ( .A(n820), .Y(n415) );
  OR2X1 U524 ( .A(n617), .B(payoff_sum[4]), .Y(n870) );
  INVX1 U525 ( .A(n870), .Y(n417) );
  AND2X1 U526 ( .A(trial_count[1]), .B(trial_count[0]), .Y(n917) );
  OR2X1 U528 ( .A(n630), .B(payoff_sum[12]), .Y(n819) );
  INVX1 U529 ( .A(n819), .Y(n419) );
  BUFX2 U530 ( .A(n855), .Y(n420) );
  INVX1 U531 ( .A(n895), .Y(n421) );
  OR2X1 U533 ( .A(n455), .B(n931), .Y(n936) );
  INVX1 U534 ( .A(n936), .Y(n423) );
  OR2X1 U535 ( .A(n456), .B(n940), .Y(n945) );
  INVX1 U536 ( .A(n945), .Y(n424) );
  OR2X1 U537 ( .A(n457), .B(n949), .Y(n954) );
  INVX1 U538 ( .A(n954), .Y(n425) );
  OR2X1 U539 ( .A(n458), .B(n958), .Y(n963) );
  INVX1 U540 ( .A(n963), .Y(n426) );
  OR2X1 U541 ( .A(n459), .B(n508), .Y(n970) );
  INVX1 U542 ( .A(n970), .Y(n427) );
  OR2X1 U543 ( .A(n460), .B(n512), .Y(n984) );
  INVX1 U544 ( .A(n984), .Y(n428) );
  OR2X1 U545 ( .A(n461), .B(n516), .Y(n999) );
  INVX1 U546 ( .A(n999), .Y(n429) );
  OR2X1 U547 ( .A(n462), .B(n1011), .Y(n1016) );
  INVX1 U548 ( .A(n1016), .Y(n430) );
  OR2X1 U549 ( .A(n463), .B(n1023), .Y(n1029) );
  INVX1 U550 ( .A(n1029), .Y(n431) );
  INVX1 U551 ( .A(n857), .Y(n432) );
  INVX1 U552 ( .A(n622), .Y(n433) );
  BUFX2 U553 ( .A(n826), .Y(n434) );
  BUFX2 U555 ( .A(n874), .Y(n436) );
  INVX1 U556 ( .A(n897), .Y(n437) );
  BUFX2 U557 ( .A(n1035), .Y(n438) );
  INVX1 U561 ( .A(n830), .Y(n441) );
  INVX1 U563 ( .A(n845), .Y(n443) );
  INVX1 U566 ( .A(n860), .Y(n445) );
  INVX1 U567 ( .A(n878), .Y(n446) );
  AND2X1 U568 ( .A(n454), .B(n870), .Y(n878) );
  INVX1 U569 ( .A(n885), .Y(n447) );
  INVX1 U570 ( .A(n821), .Y(n448) );
  INVX1 U571 ( .A(n851), .Y(n449) );
  AND2X1 U572 ( .A(n481), .B(n849), .Y(n851) );
  INVX1 U573 ( .A(n866), .Y(n450) );
  AND2X1 U574 ( .A(n480), .B(n864), .Y(n866) );
  INVX1 U575 ( .A(n873), .Y(n451) );
  INVX1 U576 ( .A(n891), .Y(n452) );
  AND2X1 U577 ( .A(n479), .B(n889), .Y(n891) );
  INVX1 U578 ( .A(n1034), .Y(n453) );
  OR2X1 U579 ( .A(trial_count[30]), .B(n1030), .Y(n1034) );
  INVX1 U580 ( .A(n877), .Y(n454) );
  AND2X1 U581 ( .A(payoff_sum[4]), .B(n617), .Y(n877) );
  AND2X1 U582 ( .A(trial_count[5]), .B(n526), .Y(n932) );
  INVX1 U583 ( .A(n932), .Y(n455) );
  INVX1 U584 ( .A(n941), .Y(n456) );
  INVX1 U585 ( .A(n950), .Y(n457) );
  INVX1 U586 ( .A(n959), .Y(n458) );
  INVX1 U587 ( .A(n967), .Y(n459) );
  AND2X1 U588 ( .A(trial_count[17]), .B(n525), .Y(n981) );
  INVX1 U589 ( .A(n981), .Y(n460) );
  INVX1 U590 ( .A(n996), .Y(n461) );
  AND2X1 U591 ( .A(trial_count[21]), .B(n524), .Y(n996) );
  AND2X1 U592 ( .A(trial_count[25]), .B(n523), .Y(n1012) );
  INVX1 U593 ( .A(n1012), .Y(n462) );
  INVX1 U594 ( .A(n1024), .Y(n463) );
  INVX1 U595 ( .A(n864), .Y(n464) );
  OR2X1 U596 ( .A(n619), .B(payoff_sum[6]), .Y(n864) );
  OR2X1 U597 ( .A(n613), .B(payoff_sum[2]), .Y(n889) );
  INVX1 U598 ( .A(n889), .Y(n465) );
  OR2X1 U599 ( .A(n625), .B(payoff_sum[8]), .Y(n849) );
  INVX1 U600 ( .A(n849), .Y(n466) );
  INVX1 U601 ( .A(n924), .Y(n467) );
  INVX1 U602 ( .A(n974), .Y(n468) );
  INVX1 U603 ( .A(n988), .Y(n469) );
  INVX1 U604 ( .A(n269), .Y(n470) );
  INVX1 U609 ( .A(n1003), .Y(n473) );
  INVX1 U610 ( .A(n828), .Y(n474) );
  OR2X1 U611 ( .A(n627), .B(payoff_sum[11]), .Y(n828) );
  INVX1 U612 ( .A(n858), .Y(n475) );
  OR2X1 U613 ( .A(n620), .B(payoff_sum[7]), .Y(n858) );
  INVX1 U614 ( .A(n871), .Y(n476) );
  INVX1 U615 ( .A(n883), .Y(n477) );
  OR2X1 U616 ( .A(n614), .B(payoff_sum[3]), .Y(n883) );
  INVX1 U617 ( .A(n843), .Y(n478) );
  INVX1 U618 ( .A(n890), .Y(n479) );
  AND2X1 U619 ( .A(payoff_sum[2]), .B(n613), .Y(n890) );
  INVX1 U620 ( .A(n865), .Y(n480) );
  AND2X1 U621 ( .A(payoff_sum[6]), .B(n619), .Y(n865) );
  INVX1 U622 ( .A(n850), .Y(n481) );
  AND2X1 U623 ( .A(payoff_sum[8]), .B(n625), .Y(n850) );
  BUFX2 U624 ( .A(n1141), .Y(acc_overflow) );
  BUFX2 U625 ( .A(n1142), .Y(sat_x_seen) );
  BUFX2 U626 ( .A(n1143), .Y(sat_s_seen) );
  INVX1 U627 ( .A(trial_count[1]), .Y(n486) );
  BUFX2 U628 ( .A(n1139), .Y(trial_count[1]) );
  INVX1 U629 ( .A(trial_count[3]), .Y(n488) );
  BUFX2 U630 ( .A(n1137), .Y(trial_count[3]) );
  INVX1 U631 ( .A(trial_count[5]), .Y(n490) );
  BUFX2 U632 ( .A(n1135), .Y(trial_count[5]) );
  INVX1 U633 ( .A(trial_count[15]), .Y(n492) );
  BUFX2 U634 ( .A(n1125), .Y(trial_count[15]) );
  INVX1 U635 ( .A(trial_count[17]), .Y(n494) );
  BUFX2 U636 ( .A(n1123), .Y(trial_count[17]) );
  INVX1 U637 ( .A(trial_count[19]), .Y(n496) );
  BUFX2 U638 ( .A(n1121), .Y(trial_count[19]) );
  INVX1 U639 ( .A(trial_count[21]), .Y(n498) );
  BUFX2 U640 ( .A(n1119), .Y(trial_count[21]) );
  INVX1 U641 ( .A(trial_count[23]), .Y(n500) );
  BUFX2 U642 ( .A(n1117), .Y(trial_count[23]) );
  INVX1 U643 ( .A(trial_count[25]), .Y(n502) );
  BUFX2 U644 ( .A(n1115), .Y(trial_count[25]) );
  INVX1 U645 ( .A(trial_count[2]), .Y(n504) );
  BUFX2 U646 ( .A(n1138), .Y(trial_count[2]) );
  INVX1 U647 ( .A(trial_count[4]), .Y(n506) );
  BUFX2 U648 ( .A(n1136), .Y(trial_count[4]) );
  INVX1 U649 ( .A(trial_count[14]), .Y(n508) );
  BUFX2 U650 ( .A(n1126), .Y(trial_count[14]) );
  INVX1 U651 ( .A(trial_count[16]), .Y(n510) );
  BUFX2 U652 ( .A(n1124), .Y(trial_count[16]) );
  INVX1 U653 ( .A(trial_count[18]), .Y(n512) );
  BUFX2 U654 ( .A(n1122), .Y(trial_count[18]) );
  INVX1 U655 ( .A(trial_count[20]), .Y(n514) );
  BUFX2 U656 ( .A(n1120), .Y(trial_count[20]) );
  INVX1 U657 ( .A(trial_count[22]), .Y(n516) );
  BUFX2 U658 ( .A(n1118), .Y(trial_count[22]) );
  INVX1 U659 ( .A(trial_count[24]), .Y(n518) );
  BUFX2 U660 ( .A(n1116), .Y(trial_count[24]) );
  BUFX2 U661 ( .A(n997), .Y(n520) );
  BUFX2 U662 ( .A(n968), .Y(n521) );
  BUFX2 U663 ( .A(n914), .Y(n522) );
  INVX1 U664 ( .A(n1006), .Y(n523) );
  INVX1 U665 ( .A(n991), .Y(n524) );
  INVX1 U666 ( .A(n977), .Y(n525) );
  INVX1 U667 ( .A(n927), .Y(n526) );
  BUFX2 U668 ( .A(n822), .Y(n527) );
  BUFX2 U669 ( .A(n867), .Y(n528) );
  BUFX2 U670 ( .A(n1113), .Y(trial_count[27]) );
  BUFX2 U671 ( .A(n1127), .Y(trial_count[13]) );
  BUFX2 U672 ( .A(n1129), .Y(trial_count[11]) );
  BUFX2 U673 ( .A(n1131), .Y(trial_count[9]) );
  BUFX2 U674 ( .A(n1133), .Y(trial_count[7]) );
  BUFX2 U675 ( .A(n1111), .Y(trial_count[29]) );
  BUFX2 U676 ( .A(n1112), .Y(trial_count[28]) );
  BUFX2 U677 ( .A(n1114), .Y(trial_count[26]) );
  BUFX2 U678 ( .A(n1128), .Y(trial_count[12]) );
  BUFX2 U679 ( .A(n1130), .Y(trial_count[10]) );
  BUFX2 U680 ( .A(n1132), .Y(trial_count[8]) );
  BUFX2 U681 ( .A(n1134), .Y(trial_count[6]) );
  BUFX2 U682 ( .A(n1109), .Y(trial_count[31]) );
  BUFX2 U683 ( .A(n1046), .Y(payoff_sum[62]) );
  BUFX2 U684 ( .A(n1047), .Y(payoff_sum[61]) );
  BUFX2 U685 ( .A(n1048), .Y(payoff_sum[60]) );
  BUFX2 U686 ( .A(n1049), .Y(payoff_sum[59]) );
  BUFX2 U687 ( .A(n1051), .Y(payoff_sum[57]) );
  BUFX2 U688 ( .A(n1052), .Y(payoff_sum[56]) );
  BUFX2 U689 ( .A(n1053), .Y(payoff_sum[55]) );
  BUFX2 U690 ( .A(n1055), .Y(payoff_sum[53]) );
  BUFX2 U691 ( .A(n1056), .Y(payoff_sum[52]) );
  BUFX2 U692 ( .A(n1057), .Y(payoff_sum[51]) );
  BUFX2 U693 ( .A(n1059), .Y(payoff_sum[49]) );
  BUFX2 U694 ( .A(n1060), .Y(payoff_sum[48]) );
  BUFX2 U695 ( .A(n1061), .Y(payoff_sum[47]) );
  BUFX2 U696 ( .A(n1062), .Y(payoff_sum[46]) );
  BUFX2 U697 ( .A(n1063), .Y(payoff_sum[45]) );
  BUFX2 U698 ( .A(n1065), .Y(payoff_sum[43]) );
  BUFX2 U699 ( .A(n1067), .Y(payoff_sum[41]) );
  BUFX2 U700 ( .A(n1069), .Y(payoff_sum[39]) );
  BUFX2 U701 ( .A(n1071), .Y(payoff_sum[37]) );
  BUFX2 U702 ( .A(n1073), .Y(payoff_sum[35]) );
  BUFX2 U703 ( .A(n1075), .Y(payoff_sum[33]) );
  BUFX2 U704 ( .A(n1077), .Y(payoff_sum[31]) );
  BUFX2 U705 ( .A(n1079), .Y(payoff_sum[29]) );
  BUFX2 U706 ( .A(n1081), .Y(payoff_sum[27]) );
  BUFX2 U707 ( .A(n1082), .Y(payoff_sum[26]) );
  BUFX2 U708 ( .A(n1083), .Y(payoff_sum[25]) );
  BUFX2 U709 ( .A(n1084), .Y(payoff_sum[24]) );
  BUFX2 U710 ( .A(n1085), .Y(payoff_sum[23]) );
  BUFX2 U711 ( .A(n1086), .Y(payoff_sum[22]) );
  BUFX2 U712 ( .A(n1045), .Y(payoff_sum[63]) );
  BUFX2 U713 ( .A(n1064), .Y(payoff_sum[44]) );
  BUFX2 U714 ( .A(n1066), .Y(payoff_sum[42]) );
  BUFX2 U715 ( .A(n1068), .Y(payoff_sum[40]) );
  BUFX2 U716 ( .A(n1070), .Y(payoff_sum[38]) );
  BUFX2 U717 ( .A(n1096), .Y(payoff_sum[12]) );
  BUFX2 U718 ( .A(n1097), .Y(payoff_sum[11]) );
  BUFX2 U719 ( .A(n1099), .Y(payoff_sum[9]) );
  BUFX2 U720 ( .A(n1100), .Y(payoff_sum[8]) );
  BUFX2 U721 ( .A(n1101), .Y(payoff_sum[7]) );
  BUFX2 U722 ( .A(n1102), .Y(payoff_sum[6]) );
  BUFX2 U723 ( .A(n1103), .Y(payoff_sum[5]) );
  BUFX2 U724 ( .A(n1104), .Y(payoff_sum[4]) );
  BUFX2 U725 ( .A(n1105), .Y(payoff_sum[3]) );
  BUFX2 U726 ( .A(n1106), .Y(payoff_sum[2]) );
  BUFX2 U727 ( .A(n1107), .Y(payoff_sum[1]) );
  BUFX2 U728 ( .A(n1095), .Y(payoff_sum[13]) );
  BUFX2 U729 ( .A(n1098), .Y(payoff_sum[10]) );
  BUFX2 U730 ( .A(n1108), .Y(payoff_sum[0]) );
  OR2X1 U731 ( .A(n900), .B(payoff_sum[0]), .Y(n901) );
  BUFX2 U732 ( .A(n1110), .Y(trial_count[30]) );
  BUFX2 U733 ( .A(n1088), .Y(payoff_sum[20]) );
  BUFX2 U734 ( .A(n1090), .Y(payoff_sum[18]) );
  BUFX2 U735 ( .A(n1092), .Y(payoff_sum[16]) );
  BUFX2 U736 ( .A(n1094), .Y(payoff_sum[14]) );
  BUFX2 U737 ( .A(n1050), .Y(payoff_sum[58]) );
  BUFX2 U738 ( .A(n1054), .Y(payoff_sum[54]) );
  BUFX2 U739 ( .A(n1058), .Y(payoff_sum[50]) );
  BUFX2 U740 ( .A(n1072), .Y(payoff_sum[36]) );
  BUFX2 U741 ( .A(n1074), .Y(payoff_sum[34]) );
  BUFX2 U742 ( .A(n1076), .Y(payoff_sum[32]) );
  BUFX2 U743 ( .A(n1078), .Y(payoff_sum[30]) );
  BUFX2 U744 ( .A(n1080), .Y(payoff_sum[28]) );
  BUFX2 U745 ( .A(n1140), .Y(trial_count[0]) );
  BUFX2 U746 ( .A(n1087), .Y(payoff_sum[21]) );
  BUFX2 U747 ( .A(n1089), .Y(payoff_sum[19]) );
  BUFX2 U748 ( .A(n1091), .Y(payoff_sum[17]) );
  BUFX2 U749 ( .A(n1093), .Y(payoff_sum[15]) );
  INVX1 U750 ( .A(clear), .Y(n608) );
  INVX2 U751 ( .A(n645), .Y(n1044) );
  INVX1 U753 ( .A(n268), .Y(n200) );
  OR2X1 U754 ( .A(n210), .B(clear), .Y(n912) );
  INVX1 U755 ( .A(n912), .Y(n791) );
  INVX1 U756 ( .A(clear), .Y(n1021) );
  AND2X1 U757 ( .A(n1021), .B(n209), .Y(n992) );
  INVX1 U758 ( .A(n992), .Y(n1030) );
  INVX1 U759 ( .A(n1030), .Y(n800) );
  AND2X1 U760 ( .A(n251), .B(p[21]), .Y(n774) );
  AND2X1 U762 ( .A(n208), .B(p[20]), .Y(n780) );
  AND2X1 U763 ( .A(n250), .B(p[19]), .Y(n783) );
  AND2X1 U764 ( .A(p_valid[0]), .B(p[18]), .Y(n789) );
  AND2X1 U765 ( .A(p_valid[0]), .B(p[17]), .Y(n793) );
  AND2X1 U766 ( .A(p_valid[0]), .B(p[16]), .Y(n798) );
  AND2X1 U767 ( .A(n246), .B(p[15]), .Y(n802) );
  AND2X1 U768 ( .A(n245), .B(p[14]), .Y(n809) );
  AND2X1 U769 ( .A(n244), .B(p[13]), .Y(n611) );
  AND2X1 U770 ( .A(n240), .B(p[6]), .Y(n619) );
  AND2X1 U771 ( .A(n233), .B(p[7]), .Y(n620) );
  AND2X1 U772 ( .A(n234), .B(p[4]), .Y(n617) );
  AND2X1 U773 ( .A(n239), .B(p[2]), .Y(n613) );
  AND2X1 U774 ( .A(p_valid[0]), .B(p[3]), .Y(n614) );
  OAI21X1 U775 ( .A(n485), .B(n421), .C(n406), .Y(n882) );
  OAI21X1 U776 ( .A(n479), .B(n477), .C(n407), .Y(n615) );
  AOI21X1 U777 ( .A(n373), .B(n882), .C(n615), .Y(n855) );
  OAI21X1 U778 ( .A(n454), .B(n476), .C(n408), .Y(n856) );
  OAI21X1 U779 ( .A(n480), .B(n475), .C(n409), .Y(n621) );
  AOI21X1 U780 ( .A(n856), .B(n433), .C(n621), .Y(n623) );
  OAI21X1 U781 ( .A(n374), .B(n420), .C(n345), .Y(n825) );
  OAI21X1 U782 ( .A(n481), .B(n478), .C(n410), .Y(n835) );
  AOI21X1 U783 ( .A(n835), .B(n837), .C(n838), .Y(n826) );
  OAI21X1 U784 ( .A(n474), .B(n434), .C(n411), .Y(n628) );
  AOI21X1 U785 ( .A(n825), .B(n372), .C(n628), .Y(n822) );
  OAI21X1 U786 ( .A(n419), .B(n527), .C(n415), .Y(n816) );
  AND2X2 U791 ( .A(n715), .B(payoff_sum[40]), .Y(n711) );
  AND2X2 U792 ( .A(n708), .B(payoff_sum[42]), .Y(n704) );
  AND2X2 U793 ( .A(n701), .B(payoff_sum[44]), .Y(n697) );
  AND2X2 U795 ( .A(n652), .B(payoff_sum[54]), .Y(n655) );
  AND2X2 U796 ( .A(n664), .B(payoff_sum[58]), .Y(n667) );
  INVX1 U797 ( .A(payoff_sum[63]), .Y(n642) );
  XNOR2X1 U798 ( .A(n905), .B(n642), .Y(n643) );
  AOI22X1 U799 ( .A(n791), .B(payoff_sum[63]), .C(n800), .D(n643), .Y(n644) );
  INVX1 U800 ( .A(n253), .Y(n104) );
  INVX1 U801 ( .A(rst_n), .Y(n645) );
  INVX1 U802 ( .A(n645), .Y(n1041) );
  INVX1 U803 ( .A(n645), .Y(n1039) );
  INVX1 U804 ( .A(n645), .Y(n1040) );
  INVX1 U805 ( .A(n645), .Y(n1038) );
  INVX1 U806 ( .A(n645), .Y(n1042) );
  INVX1 U807 ( .A(n645), .Y(n1043) );
  INVX1 U808 ( .A(n1030), .Y(n717) );
  HAX1 U809 ( .A(payoff_sum[52]), .B(n646), .YC(n649), .YS(n647) );
  AOI22X1 U810 ( .A(n791), .B(payoff_sum[52]), .C(n717), .D(n647), .Y(n648) );
  INVX1 U811 ( .A(n254), .Y(n115) );
  HAX1 U812 ( .A(payoff_sum[53]), .B(n649), .YC(n652), .YS(n650) );
  AOI22X1 U813 ( .A(n791), .B(payoff_sum[53]), .C(n717), .D(n650), .Y(n651) );
  INVX1 U814 ( .A(n255), .Y(n114) );
  XOR2X1 U815 ( .A(n652), .B(payoff_sum[54]), .Y(n653) );
  AOI22X1 U816 ( .A(n791), .B(payoff_sum[54]), .C(n717), .D(n653), .Y(n654) );
  INVX1 U817 ( .A(n256), .Y(n113) );
  HAX1 U818 ( .A(payoff_sum[55]), .B(n655), .YC(n658), .YS(n656) );
  AOI22X1 U819 ( .A(n791), .B(payoff_sum[55]), .C(n717), .D(n656), .Y(n657) );
  INVX1 U820 ( .A(n257), .Y(n112) );
  HAX1 U821 ( .A(payoff_sum[56]), .B(n658), .YC(n661), .YS(n659) );
  AOI22X1 U822 ( .A(n791), .B(payoff_sum[56]), .C(n717), .D(n659), .Y(n660) );
  INVX1 U823 ( .A(n258), .Y(n111) );
  HAX1 U824 ( .A(payoff_sum[57]), .B(n661), .YC(n664), .YS(n662) );
  AOI22X1 U825 ( .A(n791), .B(payoff_sum[57]), .C(n717), .D(n662), .Y(n663) );
  INVX1 U826 ( .A(n259), .Y(n110) );
  INVX1 U827 ( .A(n1030), .Y(n1025) );
  XOR2X1 U828 ( .A(n664), .B(payoff_sum[58]), .Y(n665) );
  AOI22X1 U829 ( .A(n791), .B(payoff_sum[58]), .C(n1025), .D(n665), .Y(n666)
         );
  INVX1 U830 ( .A(n260), .Y(n109) );
  HAX1 U831 ( .A(payoff_sum[59]), .B(n667), .YC(n670), .YS(n668) );
  AOI22X1 U832 ( .A(n791), .B(payoff_sum[59]), .C(n1025), .D(n668), .Y(n669)
         );
  INVX1 U833 ( .A(n261), .Y(n108) );
  HAX1 U834 ( .A(payoff_sum[60]), .B(n670), .YC(n673), .YS(n671) );
  AOI22X1 U835 ( .A(n791), .B(payoff_sum[60]), .C(n1025), .D(n671), .Y(n672)
         );
  INVX1 U836 ( .A(n262), .Y(n107) );
  HAX1 U837 ( .A(payoff_sum[61]), .B(n673), .YC(n676), .YS(n674) );
  AOI22X1 U838 ( .A(n791), .B(payoff_sum[61]), .C(n1025), .D(n674), .Y(n675)
         );
  INVX1 U839 ( .A(n263), .Y(n106) );
  HAX1 U840 ( .A(payoff_sum[62]), .B(n676), .YC(n905), .YS(n677) );
  AOI22X1 U841 ( .A(n791), .B(payoff_sum[62]), .C(n1025), .D(n677), .Y(n678)
         );
  INVX1 U842 ( .A(n264), .Y(n105) );
  HAX1 U843 ( .A(payoff_sum[51]), .B(n679), .YC(n646), .YS(n680) );
  AOI22X1 U844 ( .A(n791), .B(payoff_sum[51]), .C(n717), .D(n680), .Y(n681) );
  INVX1 U845 ( .A(n265), .Y(n116) );
  INVX1 U846 ( .A(n912), .Y(n806) );
  XOR2X1 U847 ( .A(n682), .B(payoff_sum[50]), .Y(n683) );
  AOI22X1 U848 ( .A(n806), .B(payoff_sum[50]), .C(n717), .D(n683), .Y(n684) );
  INVX1 U849 ( .A(n266), .Y(n117) );
  HAX1 U850 ( .A(payoff_sum[49]), .B(n685), .YC(n682), .YS(n686) );
  AOI22X1 U851 ( .A(n806), .B(payoff_sum[49]), .C(n717), .D(n686), .Y(n687) );
  INVX1 U852 ( .A(n267), .Y(n118) );
  HAX1 U853 ( .A(payoff_sum[48]), .B(n688), .YC(n685), .YS(n689) );
  AOI22X1 U854 ( .A(n806), .B(payoff_sum[48]), .C(n717), .D(n689), .Y(n690) );
  INVX1 U855 ( .A(n270), .Y(n119) );
  HAX1 U856 ( .A(payoff_sum[47]), .B(n691), .YC(n688), .YS(n692) );
  AOI22X1 U857 ( .A(n806), .B(payoff_sum[47]), .C(n717), .D(n692), .Y(n693) );
  INVX1 U858 ( .A(n271), .Y(n120) );
  HAX1 U859 ( .A(payoff_sum[46]), .B(n694), .YC(n691), .YS(n695) );
  AOI22X1 U860 ( .A(n806), .B(payoff_sum[46]), .C(n717), .D(n695), .Y(n696) );
  INVX1 U861 ( .A(n272), .Y(n121) );
  HAX1 U862 ( .A(payoff_sum[45]), .B(n697), .YC(n694), .YS(n698) );
  AOI22X1 U863 ( .A(n806), .B(payoff_sum[45]), .C(n717), .D(n698), .Y(n699) );
  INVX1 U864 ( .A(n273), .Y(n122) );
  INVX1 U865 ( .A(payoff_sum[44]), .Y(n700) );
  XNOR2X1 U866 ( .A(n701), .B(n700), .Y(n702) );
  AOI22X1 U867 ( .A(n806), .B(payoff_sum[44]), .C(n717), .D(n702), .Y(n703) );
  INVX1 U868 ( .A(n274), .Y(n123) );
  HAX1 U869 ( .A(payoff_sum[43]), .B(n704), .YC(n701), .YS(n705) );
  AOI22X1 U870 ( .A(n806), .B(payoff_sum[43]), .C(n1025), .D(n705), .Y(n706)
         );
  INVX1 U871 ( .A(n275), .Y(n124) );
  INVX1 U872 ( .A(payoff_sum[42]), .Y(n707) );
  XNOR2X1 U873 ( .A(n708), .B(n707), .Y(n709) );
  AOI22X1 U874 ( .A(n806), .B(payoff_sum[42]), .C(n717), .D(n709), .Y(n710) );
  INVX1 U875 ( .A(n276), .Y(n125) );
  HAX1 U876 ( .A(payoff_sum[41]), .B(n711), .YC(n708), .YS(n712) );
  AOI22X1 U877 ( .A(n806), .B(payoff_sum[41]), .C(n1025), .D(n712), .Y(n713)
         );
  INVX1 U878 ( .A(n277), .Y(n126) );
  INVX1 U879 ( .A(payoff_sum[40]), .Y(n714) );
  XNOR2X1 U880 ( .A(n715), .B(n714), .Y(n716) );
  AOI22X1 U881 ( .A(n806), .B(payoff_sum[40]), .C(n717), .D(n716), .Y(n718) );
  INVX1 U882 ( .A(n278), .Y(n127) );
  HAX1 U883 ( .A(payoff_sum[39]), .B(n719), .YC(n715), .YS(n720) );
  AOI22X1 U884 ( .A(n806), .B(payoff_sum[39]), .C(n1025), .D(n720), .Y(n721)
         );
  INVX1 U885 ( .A(n279), .Y(n128) );
  INVX1 U886 ( .A(payoff_sum[38]), .Y(n722) );
  XNOR2X1 U887 ( .A(n723), .B(n722), .Y(n724) );
  AOI22X1 U888 ( .A(n806), .B(payoff_sum[38]), .C(n992), .D(n724), .Y(n725) );
  INVX1 U889 ( .A(n280), .Y(n129) );
  INVX1 U890 ( .A(n912), .Y(n811) );
  HAX1 U891 ( .A(payoff_sum[37]), .B(n726), .YC(n723), .YS(n727) );
  AOI22X1 U892 ( .A(n811), .B(payoff_sum[37]), .C(n992), .D(n727), .Y(n728) );
  INVX1 U893 ( .A(n281), .Y(n130) );
  XOR2X1 U894 ( .A(n729), .B(payoff_sum[36]), .Y(n730) );
  AOI22X1 U895 ( .A(n811), .B(payoff_sum[36]), .C(n992), .D(n730), .Y(n731) );
  INVX1 U896 ( .A(n282), .Y(n131) );
  HAX1 U897 ( .A(payoff_sum[35]), .B(n732), .YC(n729), .YS(n733) );
  AOI22X1 U898 ( .A(n811), .B(payoff_sum[35]), .C(n992), .D(n733), .Y(n734) );
  INVX1 U899 ( .A(n283), .Y(n132) );
  XOR2X1 U900 ( .A(n735), .B(payoff_sum[34]), .Y(n736) );
  AOI22X1 U901 ( .A(n811), .B(payoff_sum[34]), .C(n992), .D(n736), .Y(n737) );
  INVX1 U902 ( .A(n284), .Y(n133) );
  HAX1 U903 ( .A(payoff_sum[33]), .B(n738), .YC(n735), .YS(n739) );
  AOI22X1 U904 ( .A(n811), .B(payoff_sum[33]), .C(n800), .D(n739), .Y(n740) );
  INVX1 U905 ( .A(n285), .Y(n134) );
  XOR2X1 U906 ( .A(n741), .B(payoff_sum[32]), .Y(n742) );
  AOI22X1 U907 ( .A(n811), .B(payoff_sum[32]), .C(n800), .D(n742), .Y(n743) );
  INVX1 U908 ( .A(n286), .Y(n135) );
  HAX1 U909 ( .A(payoff_sum[31]), .B(n744), .YC(n741), .YS(n745) );
  AOI22X1 U910 ( .A(n811), .B(payoff_sum[31]), .C(n800), .D(n745), .Y(n746) );
  INVX1 U911 ( .A(n287), .Y(n136) );
  XOR2X1 U912 ( .A(n747), .B(payoff_sum[30]), .Y(n748) );
  AOI22X1 U913 ( .A(n811), .B(payoff_sum[30]), .C(n800), .D(n748), .Y(n749) );
  INVX1 U914 ( .A(n288), .Y(n137) );
  HAX1 U915 ( .A(payoff_sum[29]), .B(n750), .YC(n747), .YS(n751) );
  AOI22X1 U916 ( .A(n811), .B(payoff_sum[29]), .C(n800), .D(n751), .Y(n752) );
  INVX1 U917 ( .A(n289), .Y(n138) );
  XOR2X1 U918 ( .A(n753), .B(payoff_sum[28]), .Y(n754) );
  AOI22X1 U919 ( .A(n811), .B(payoff_sum[28]), .C(n800), .D(n754), .Y(n755) );
  INVX1 U920 ( .A(n290), .Y(n139) );
  HAX1 U921 ( .A(payoff_sum[27]), .B(n756), .YC(n753), .YS(n757) );
  AOI22X1 U922 ( .A(n811), .B(payoff_sum[27]), .C(n800), .D(n757), .Y(n758) );
  INVX1 U923 ( .A(n291), .Y(n140) );
  HAX1 U924 ( .A(payoff_sum[26]), .B(n759), .YC(n756), .YS(n760) );
  AOI22X1 U925 ( .A(n811), .B(payoff_sum[26]), .C(n800), .D(n760), .Y(n761) );
  INVX1 U926 ( .A(n292), .Y(n141) );
  HAX1 U927 ( .A(payoff_sum[25]), .B(n762), .YC(n759), .YS(n763) );
  AOI22X1 U928 ( .A(n811), .B(payoff_sum[25]), .C(n800), .D(n763), .Y(n764) );
  INVX1 U929 ( .A(n293), .Y(n142) );
  INVX1 U930 ( .A(n912), .Y(n1007) );
  HAX1 U931 ( .A(payoff_sum[24]), .B(n765), .YC(n762), .YS(n766) );
  AOI22X1 U932 ( .A(n1007), .B(payoff_sum[24]), .C(n800), .D(n766), .Y(n767)
         );
  INVX1 U933 ( .A(n294), .Y(n143) );
  HAX1 U934 ( .A(payoff_sum[23]), .B(n768), .YC(n765), .YS(n769) );
  AOI22X1 U935 ( .A(n1007), .B(payoff_sum[23]), .C(n800), .D(n769), .Y(n770)
         );
  INVX1 U936 ( .A(n295), .Y(n144) );
  HAX1 U937 ( .A(payoff_sum[22]), .B(n416), .YC(n768), .YS(n772) );
  AOI22X1 U938 ( .A(n791), .B(payoff_sum[22]), .C(n800), .D(n772), .Y(n773) );
  INVX1 U939 ( .A(n296), .Y(n145) );
  INVX1 U940 ( .A(n1030), .Y(n907) );
  XOR2X1 U941 ( .A(n774), .B(payoff_sum[21]), .Y(n775) );
  XOR2X1 U942 ( .A(n776), .B(n775), .Y(n777) );
  AOI22X1 U943 ( .A(n806), .B(payoff_sum[21]), .C(n907), .D(n777), .Y(n778) );
  INVX1 U944 ( .A(n297), .Y(n146) );
  FAX1 U945 ( .A(payoff_sum[20]), .B(n780), .C(n472), .YC(n776), .YS(n781) );
  AOI22X1 U946 ( .A(n811), .B(payoff_sum[20]), .C(n800), .D(n781), .Y(n782) );
  INVX1 U947 ( .A(n298), .Y(n147) );
  INVX1 U948 ( .A(n912), .Y(n1017) );
  XOR2X1 U949 ( .A(n783), .B(payoff_sum[19]), .Y(n784) );
  XOR2X1 U950 ( .A(n785), .B(n784), .Y(n786) );
  AOI22X1 U951 ( .A(n1017), .B(payoff_sum[19]), .C(n907), .D(n786), .Y(n787)
         );
  INVX1 U952 ( .A(n299), .Y(n148) );
  FAX1 U953 ( .A(payoff_sum[18]), .B(n789), .C(n471), .YC(n785), .YS(n790) );
  AOI22X1 U954 ( .A(n791), .B(payoff_sum[18]), .C(n800), .D(n790), .Y(n792) );
  INVX1 U955 ( .A(n300), .Y(n149) );
  XOR2X1 U956 ( .A(n793), .B(payoff_sum[17]), .Y(n794) );
  XOR2X1 U957 ( .A(n795), .B(n794), .Y(n796) );
  AOI22X1 U958 ( .A(n806), .B(payoff_sum[17]), .C(n907), .D(n796), .Y(n797) );
  INVX1 U959 ( .A(n301), .Y(n150) );
  FAX1 U960 ( .A(payoff_sum[16]), .B(n798), .C(n470), .YC(n795), .YS(n799) );
  AOI22X1 U961 ( .A(n811), .B(payoff_sum[16]), .C(n800), .D(n799), .Y(n801) );
  INVX1 U962 ( .A(n302), .Y(n151) );
  XOR2X1 U963 ( .A(n802), .B(payoff_sum[15]), .Y(n803) );
  XOR2X1 U964 ( .A(n804), .B(n803), .Y(n805) );
  AOI22X1 U965 ( .A(n806), .B(payoff_sum[15]), .C(n992), .D(n805), .Y(n807) );
  INVX1 U966 ( .A(n303), .Y(n152) );
  FAX1 U967 ( .A(payoff_sum[14]), .B(n809), .C(n444), .YC(n804), .YS(n810) );
  AOI22X1 U968 ( .A(n811), .B(payoff_sum[14]), .C(n992), .D(n810), .Y(n812) );
  INVX1 U969 ( .A(n304), .Y(n153) );
  XNOR2X1 U970 ( .A(n816), .B(n440), .Y(n817) );
  AOI22X1 U971 ( .A(n1017), .B(payoff_sum[13]), .C(n992), .D(n817), .Y(n818)
         );
  INVX1 U972 ( .A(n305), .Y(n154) );
  XOR2X1 U973 ( .A(n527), .B(n448), .Y(n823) );
  AOI22X1 U974 ( .A(n1017), .B(payoff_sum[12]), .C(n992), .D(n823), .Y(n824)
         );
  INVX1 U975 ( .A(n306), .Y(n155) );
  INVX1 U976 ( .A(n825), .Y(n852) );
  OAI21X1 U977 ( .A(n435), .B(n852), .C(n434), .Y(n831) );
  XNOR2X1 U978 ( .A(n831), .B(n441), .Y(n832) );
  AOI22X1 U979 ( .A(n1017), .B(payoff_sum[11]), .C(n907), .D(n832), .Y(n833)
         );
  INVX1 U980 ( .A(n307), .Y(n156) );
  INVX1 U981 ( .A(n835), .Y(n836) );
  OAI21X1 U982 ( .A(n834), .B(n852), .C(n836), .Y(n840) );
  XNOR2X1 U983 ( .A(n840), .B(n442), .Y(n841) );
  AOI22X1 U984 ( .A(n1017), .B(payoff_sum[10]), .C(n907), .D(n841), .Y(n842)
         );
  INVX1 U985 ( .A(n308), .Y(n157) );
  OAI21X1 U986 ( .A(n466), .B(n852), .C(n481), .Y(n846) );
  XNOR2X1 U987 ( .A(n846), .B(n443), .Y(n847) );
  AOI22X1 U988 ( .A(n1017), .B(payoff_sum[9]), .C(n907), .D(n847), .Y(n848) );
  INVX1 U989 ( .A(n309), .Y(n158) );
  XOR2X1 U990 ( .A(n852), .B(n449), .Y(n853) );
  AOI22X1 U991 ( .A(n1017), .B(payoff_sum[8]), .C(n907), .D(n853), .Y(n854) );
  INVX1 U992 ( .A(n310), .Y(n159) );
  INVX1 U993 ( .A(n420), .Y(n879) );
  AOI21X1 U994 ( .A(n879), .B(n432), .C(n856), .Y(n867) );
  OAI21X1 U995 ( .A(n464), .B(n528), .C(n480), .Y(n861) );
  XNOR2X1 U996 ( .A(n861), .B(n445), .Y(n862) );
  AOI22X1 U997 ( .A(n1017), .B(payoff_sum[7]), .C(n907), .D(n862), .Y(n863) );
  INVX1 U998 ( .A(n311), .Y(n160) );
  XOR2X1 U999 ( .A(n528), .B(n450), .Y(n868) );
  AOI22X1 U1000 ( .A(n1017), .B(payoff_sum[6]), .C(n907), .D(n868), .Y(n869)
         );
  INVX1 U1001 ( .A(n312), .Y(n161) );
  AOI21X1 U1002 ( .A(n879), .B(n870), .C(n877), .Y(n874) );
  XOR2X1 U1003 ( .A(n436), .B(n451), .Y(n875) );
  AOI22X1 U1004 ( .A(n1017), .B(payoff_sum[5]), .C(n907), .D(n875), .Y(n876)
         );
  INVX1 U1005 ( .A(n313), .Y(n162) );
  XNOR2X1 U1006 ( .A(n879), .B(n446), .Y(n880) );
  AOI22X1 U1007 ( .A(n1017), .B(payoff_sum[4]), .C(n907), .D(n880), .Y(n881)
         );
  INVX1 U1008 ( .A(n314), .Y(n163) );
  INVX1 U1009 ( .A(n882), .Y(n892) );
  OAI21X1 U1010 ( .A(n465), .B(n892), .C(n479), .Y(n886) );
  XNOR2X1 U1011 ( .A(n886), .B(n447), .Y(n887) );
  AOI22X1 U1012 ( .A(n1017), .B(payoff_sum[3]), .C(n907), .D(n887), .Y(n888)
         );
  INVX1 U1013 ( .A(n315), .Y(n164) );
  XOR2X1 U1014 ( .A(n892), .B(n452), .Y(n893) );
  AOI22X1 U1015 ( .A(n1017), .B(payoff_sum[2]), .C(n907), .D(n893), .Y(n894)
         );
  INVX1 U1016 ( .A(n316), .Y(n165) );
  XOR2X1 U1017 ( .A(n437), .B(n485), .Y(n898) );
  AOI22X1 U1018 ( .A(n1017), .B(payoff_sum[1]), .C(n907), .D(n898), .Y(n899)
         );
  INVX1 U1019 ( .A(n317), .Y(n166) );
  AND2X1 U1020 ( .A(n485), .B(n901), .Y(n903) );
  AOI22X1 U1021 ( .A(n1017), .B(payoff_sum[0]), .C(n907), .D(n903), .Y(n904)
         );
  INVX1 U1022 ( .A(n318), .Y(n167) );
  AOI22X1 U1023 ( .A(acc_overflow), .B(n1021), .C(n907), .D(n906), .Y(n908) );
  INVX1 U1024 ( .A(n1030), .Y(n1018) );
  AOI22X1 U1025 ( .A(sat_x[0]), .B(n1018), .C(sat_x_seen), .D(n1021), .Y(n909)
         );
  INVX1 U1026 ( .A(n319), .Y(n202) );
  AOI22X1 U1027 ( .A(sat_s[0]), .B(n1018), .C(sat_s_seen), .D(n1021), .Y(n910)
         );
  INVX1 U1028 ( .A(n320), .Y(n201) );
  INVX1 U1029 ( .A(trial_count[0]), .Y(n911) );
  AOI22X1 U1030 ( .A(trial_count[0]), .B(n912), .C(n1030), .D(n911), .Y(n199)
         );
  OAI21X1 U1031 ( .A(n486), .B(n439), .C(n1021), .Y(n915) );
  AOI21X1 U1032 ( .A(n486), .B(n439), .C(n915), .Y(n198) );
  NAND3X1 U1033 ( .A(n917), .B(n1018), .C(n504), .Y(n914) );
  OAI21X1 U1034 ( .A(n504), .B(n915), .C(n522), .Y(n197) );
  NAND3X1 U1035 ( .A(n917), .B(trial_count[2]), .C(n221), .Y(n916) );
  NAND3X1 U1036 ( .A(n422), .B(n1018), .C(n488), .Y(n918) );
  OAI21X1 U1037 ( .A(n488), .B(n389), .C(n346), .Y(n196) );
  INVX1 U1038 ( .A(n1030), .Y(n1033) );
  AOI21X1 U1039 ( .A(n1033), .B(n467), .C(n1007), .Y(n922) );
  NAND3X1 U1040 ( .A(n924), .B(n1018), .C(n506), .Y(n921) );
  OAI21X1 U1041 ( .A(n506), .B(n375), .C(n347), .Y(n195) );
  NAND3X1 U1042 ( .A(n924), .B(trial_count[4]), .C(n223), .Y(n923) );
  NAND3X1 U1043 ( .A(n526), .B(n1018), .C(n490), .Y(n925) );
  OAI21X1 U1044 ( .A(n490), .B(n390), .C(n348), .Y(n194) );
  INVX1 U1045 ( .A(trial_count[6]), .Y(n931) );
  AOI21X1 U1046 ( .A(n1033), .B(n455), .C(n1007), .Y(n929) );
  NAND3X1 U1047 ( .A(n932), .B(n1018), .C(n931), .Y(n928) );
  OAI21X1 U1048 ( .A(n931), .B(n376), .C(n349), .Y(n193) );
  INVX1 U1049 ( .A(trial_count[7]), .Y(n935) );
  NAND3X1 U1050 ( .A(n932), .B(trial_count[6]), .C(n222), .Y(n930) );
  NAND3X1 U1051 ( .A(n423), .B(n1033), .C(n935), .Y(n933) );
  OAI21X1 U1052 ( .A(n935), .B(n391), .C(n350), .Y(n192) );
  INVX1 U1053 ( .A(trial_count[8]), .Y(n940) );
  AOI21X1 U1054 ( .A(n1033), .B(n456), .C(n1007), .Y(n938) );
  NAND3X1 U1055 ( .A(n941), .B(n1018), .C(n940), .Y(n937) );
  OAI21X1 U1056 ( .A(n940), .B(n377), .C(n351), .Y(n191) );
  INVX1 U1057 ( .A(trial_count[9]), .Y(n944) );
  NAND3X1 U1058 ( .A(n941), .B(trial_count[8]), .C(n224), .Y(n939) );
  NAND3X1 U1059 ( .A(n424), .B(n1018), .C(n944), .Y(n942) );
  OAI21X1 U1060 ( .A(n944), .B(n392), .C(n352), .Y(n190) );
  INVX1 U1061 ( .A(trial_count[10]), .Y(n949) );
  AOI21X1 U1062 ( .A(n1033), .B(n457), .C(n1007), .Y(n947) );
  NAND3X1 U1063 ( .A(n950), .B(n1018), .C(n949), .Y(n946) );
  OAI21X1 U1064 ( .A(n949), .B(n378), .C(n353), .Y(n189) );
  INVX1 U1065 ( .A(trial_count[11]), .Y(n953) );
  NAND3X1 U1066 ( .A(n950), .B(trial_count[10]), .C(n225), .Y(n948) );
  NAND3X1 U1067 ( .A(n425), .B(n1033), .C(n953), .Y(n951) );
  OAI21X1 U1068 ( .A(n953), .B(n393), .C(n354), .Y(n188) );
  INVX1 U1069 ( .A(trial_count[12]), .Y(n958) );
  AOI21X1 U1070 ( .A(n1018), .B(n458), .C(n1007), .Y(n956) );
  NAND3X1 U1071 ( .A(n959), .B(n992), .C(n958), .Y(n955) );
  OAI21X1 U1072 ( .A(n958), .B(n379), .C(n355), .Y(n187) );
  INVX1 U1073 ( .A(trial_count[13]), .Y(n962) );
  NAND3X1 U1074 ( .A(n959), .B(trial_count[12]), .C(n217), .Y(n957) );
  NAND3X1 U1075 ( .A(n426), .B(n1018), .C(n962), .Y(n960) );
  OAI21X1 U1076 ( .A(n962), .B(n394), .C(n356), .Y(n186) );
  AOI21X1 U1077 ( .A(n1033), .B(n459), .C(n1007), .Y(n965) );
  NAND3X1 U1078 ( .A(n967), .B(n1018), .C(n508), .Y(n964) );
  OAI21X1 U1079 ( .A(n508), .B(n380), .C(n357), .Y(n185) );
  NAND3X1 U1080 ( .A(n967), .B(trial_count[14]), .C(n218), .Y(n966) );
  NAND3X1 U1081 ( .A(n427), .B(n1033), .C(n492), .Y(n968) );
  OAI21X1 U1082 ( .A(n492), .B(n395), .C(n521), .Y(n184) );
  AOI21X1 U1083 ( .A(n1018), .B(n468), .C(n1007), .Y(n972) );
  NAND3X1 U1084 ( .A(n974), .B(n992), .C(n510), .Y(n971) );
  OAI21X1 U1085 ( .A(n510), .B(n381), .C(n358), .Y(n183) );
  NAND3X1 U1086 ( .A(n974), .B(trial_count[16]), .C(n226), .Y(n973) );
  NAND3X1 U1087 ( .A(n525), .B(n1033), .C(n494), .Y(n975) );
  OAI21X1 U1088 ( .A(n494), .B(n396), .C(n359), .Y(n182) );
  AOI21X1 U1089 ( .A(n1033), .B(n460), .C(n1007), .Y(n979) );
  NAND3X1 U1090 ( .A(n981), .B(n992), .C(n512), .Y(n978) );
  OAI21X1 U1091 ( .A(n512), .B(n382), .C(n360), .Y(n181) );
  NAND3X1 U1092 ( .A(n981), .B(trial_count[18]), .C(n220), .Y(n980) );
  NAND3X1 U1093 ( .A(n428), .B(n1033), .C(n496), .Y(n982) );
  OAI21X1 U1094 ( .A(n496), .B(n397), .C(n361), .Y(n180) );
  AOI21X1 U1095 ( .A(n1018), .B(n469), .C(n1007), .Y(n986) );
  NAND3X1 U1096 ( .A(n988), .B(n1025), .C(n514), .Y(n985) );
  OAI21X1 U1097 ( .A(n514), .B(n383), .C(n362), .Y(n179) );
  NAND3X1 U1098 ( .A(n988), .B(trial_count[20]), .C(n219), .Y(n987) );
  NAND3X1 U1099 ( .A(n524), .B(n1033), .C(n498), .Y(n989) );
  OAI21X1 U1100 ( .A(n498), .B(n398), .C(n363), .Y(n178) );
  AOI21X1 U1101 ( .A(n1033), .B(n461), .C(n1007), .Y(n994) );
  NAND3X1 U1102 ( .A(n996), .B(n992), .C(n516), .Y(n993) );
  OAI21X1 U1103 ( .A(n516), .B(n384), .C(n364), .Y(n177) );
  NAND3X1 U1104 ( .A(n996), .B(trial_count[22]), .C(n216), .Y(n995) );
  NAND3X1 U1105 ( .A(n429), .B(n1025), .C(n500), .Y(n997) );
  OAI21X1 U1106 ( .A(n500), .B(n399), .C(n520), .Y(n176) );
  AOI21X1 U1107 ( .A(n1033), .B(n473), .C(n1007), .Y(n1001) );
  NAND3X1 U1108 ( .A(n1003), .B(n1025), .C(n518), .Y(n1000) );
  OAI21X1 U1109 ( .A(n518), .B(n385), .C(n365), .Y(n175) );
  NAND3X1 U1110 ( .A(n1003), .B(trial_count[24]), .C(n214), .Y(n1002) );
  NAND3X1 U1111 ( .A(n523), .B(n1025), .C(n502), .Y(n1004) );
  OAI21X1 U1112 ( .A(n502), .B(n400), .C(n366), .Y(n174) );
  INVX1 U1113 ( .A(trial_count[26]), .Y(n1011) );
  AOI21X1 U1114 ( .A(n1033), .B(n462), .C(n1007), .Y(n1009) );
  NAND3X1 U1115 ( .A(n1012), .B(n1025), .C(n1011), .Y(n1008) );
  OAI21X1 U1116 ( .A(n1011), .B(n386), .C(n367), .Y(n173) );
  INVX1 U1117 ( .A(trial_count[27]), .Y(n1015) );
  NAND3X1 U1118 ( .A(n1012), .B(trial_count[26]), .C(n212), .Y(n1010) );
  NAND3X1 U1119 ( .A(n430), .B(n1025), .C(n1015), .Y(n1013) );
  OAI21X1 U1120 ( .A(n1015), .B(n401), .C(n368), .Y(n172) );
  INVX1 U1121 ( .A(trial_count[28]), .Y(n1023) );
  AOI21X1 U1122 ( .A(n1018), .B(n463), .C(n1017), .Y(n1020) );
  NAND3X1 U1123 ( .A(n1024), .B(n1025), .C(n1023), .Y(n1019) );
  OAI21X1 U1124 ( .A(n1023), .B(n387), .C(n369), .Y(n171) );
  INVX1 U1125 ( .A(trial_count[29]), .Y(n1028) );
  NAND3X1 U1126 ( .A(n1024), .B(trial_count[28]), .C(n213), .Y(n1022) );
  NAND3X1 U1127 ( .A(n431), .B(n1025), .C(n1028), .Y(n1026) );
  OAI21X1 U1128 ( .A(n1028), .B(n402), .C(n370), .Y(n170) );
  AOI21X1 U1129 ( .A(n215), .B(n1032), .C(clear), .Y(n1035) );
  AOI22X1 U1130 ( .A(trial_count[30]), .B(n438), .C(n453), .D(n1032), .Y(n1031) );
  INVX1 U1131 ( .A(n321), .Y(n169) );
  NAND3X1 U1132 ( .A(n1033), .B(trial_count[30]), .C(n1032), .Y(n1037) );
  OAI21X1 U1133 ( .A(n438), .B(n453), .C(trial_count[31]), .Y(n1036) );
  OAI21X1 U1134 ( .A(trial_count[31]), .B(n388), .C(n1036), .Y(n168) );
  AND2X1 U787 ( .A(n747), .B(payoff_sum[30]), .Y(n744) );
  AND2X1 U788 ( .A(n741), .B(payoff_sum[32]), .Y(n738) );
  AND2X1 U789 ( .A(n735), .B(payoff_sum[34]), .Y(n732) );
  AND2X1 U790 ( .A(n729), .B(payoff_sum[36]), .Y(n726) );
  AND2X1 U519 ( .A(n723), .B(payoff_sum[38]), .Y(n719) );
  AND2X1 U794 ( .A(n682), .B(payoff_sum[50]), .Y(n679) );
  INVX1 U231 ( .A(trial_count[0]), .Y(n1144) );
  OR2X1 U242 ( .A(n1144), .B(n231), .Y(n439) );
  INVX1 U243 ( .A(n837), .Y(n1145) );
  OR2X1 U246 ( .A(n838), .B(n1145), .Y(n442) );
  INVX1 U250 ( .A(n813), .Y(n1146) );
  OR2X1 U266 ( .A(n814), .B(n1146), .Y(n440) );
  INVX1 U268 ( .A(p_valid[0]), .Y(n231) );
  INVX1 U269 ( .A(n1147), .Y(n639) );
  OR2X1 U273 ( .A(payoff_sum[21]), .B(n774), .Y(n1147) );
  INVX1 U274 ( .A(n1148), .Y(n634) );
  OAI21X1 U285 ( .A(payoff_sum[17]), .B(n793), .C(n795), .Y(n1148) );
  INVX1 U286 ( .A(p_valid[0]), .Y(n230) );
  INVX1 U287 ( .A(n413), .Y(n1149) );
  AND2X1 U292 ( .A(n1150), .B(n1149), .Y(n269) );
  OAI21X1 U293 ( .A(payoff_sum[15]), .B(n802), .C(n804), .Y(n1150) );
  AND2X1 U295 ( .A(n917), .B(trial_count[2]), .Y(n422) );
  INVX1 U312 ( .A(n837), .Y(n1151) );
  OR2X1 U313 ( .A(n1151), .B(n834), .Y(n435) );
  INVX1 U366 ( .A(p_valid[0]), .Y(n228) );
  INVX1 U372 ( .A(p_valid[0]), .Y(n227) );
  OR2X1 U378 ( .A(n622), .B(n857), .Y(n374) );
  INVX1 U379 ( .A(n342), .Y(n1152) );
  OR2X2 U384 ( .A(n641), .B(n1152), .Y(n416) );
  INVX1 U386 ( .A(n776), .Y(n1153) );
  OR2X2 U426 ( .A(n639), .B(n1153), .Y(n342) );
  OR2X2 U428 ( .A(n637), .B(n638), .Y(n472) );
  OR2X2 U430 ( .A(n635), .B(n634), .Y(n471) );
  OR2X2 U431 ( .A(n631), .B(n814), .Y(n444) );
  AND2X1 U432 ( .A(n785), .B(n636), .Y(n637) );
  AND2X1 U433 ( .A(n816), .B(n813), .Y(n631) );
  AND2X1 U434 ( .A(n900), .B(payoff_sum[0]), .Y(n902) );
endmodule

