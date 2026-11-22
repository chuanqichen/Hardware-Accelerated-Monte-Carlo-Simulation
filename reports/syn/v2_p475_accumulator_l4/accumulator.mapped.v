/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : T-2022.03-SP2
// Date      : Sun Nov 22 08:04:27 2026
/////////////////////////////////////////////////////////////


module accumulator ( clk, rst_n, clear, p_valid, p, sat_x, sat_s, payoff_sum, 
        trial_count, acc_overflow, sat_x_seen, sat_s_seen );
  input [3:0] p_valid;
  input [87:0] p;
  input [3:0] sat_x;
  input [3:0] sat_s;
  output [63:0] payoff_sum;
  output [31:0] trial_count;
  input clk, rst_n, clear;
  output acc_overflow, sat_x_seen, sat_s_seen;
  wire   n1200, n1201, n1202, n1203, n1204, n1205, n1206, n1207, n1208, n1209,
         n1210, n1211, n1212, n1213, n1214, n1215, n1216, n1217, n1218, n1219,
         n1220, n1221, n1222, n1223, n1224, n1225, n1226, n1227, n1228, n1229,
         n1230, n1231, n1232, n1233, n1234, n1235, n1236, n1237, n1238, n1239,
         n1240, n1241, n1242, n1243, n1244, n1245, n1246, n1247, n1248, n1249,
         n1250, n1251, n1252, n1253, n1254, n1255, n1256, n1257, n1258, n1259,
         n1260, n1261, n1262, n1263, n1264, n1265, n1266, n1267, n1268, n1269,
         n1270, n1271, n1272, n1273, n1274, n1275, n1276, n1277, n1278, n1279,
         n1280, n1281, n1282, n1283, n1284, n1285, n1286, n1287, n1288, n1289,
         n1290, n1291, n1292, n1293, n1294, n1295, n1296, n1297, n1298,
         g_tree_sx_1__0_, g_tree_sx_1__1_, g_tree_sx_2__0_, g_tree_ss_1__0_,
         g_tree_ss_1__1_, g_tree_ss_2__0_, N40, N41, N42, N43, N44, N45, N46,
         N47, N48, N49, N50, N51, N52, N53, N54, N55, N56, N57, N58, N59, N60,
         N61, N62, N63, N64, N65, N66, N94, N95, N96, N97, N98, N99, N100,
         N101, N102, N103, N104, N105, N106, N107, N108, N109, N110, N111,
         N112, N113, N114, N115, N116, N117, N118, N119, N120, N151, N152,
         N153, N154, N155, N156, N157, N158, N159, N160, N161, N162, N163,
         N164, N165, N166, N167, N168, N169, N170, N171, N172, N173, N174,
         N176, N177, N178, N179, N180, n123, n124, n126, n128, n130, n132,
         n134, n136, n138, n140, n142, n144, n146, n148, n149, n150, n151,
         n152, n153, n154, n155, n156, n157, n158, n159, n160, n161, n162,
         n163, n164, n165, n166, n167, n168, n169, n170, n171, n172, n173,
         n174, n175, n176, n177, n178, n179, n180, n181, n182, n183, n184,
         n185, n186, n187, n188, n189, n190, n191, n192, n193, n194, n195,
         n196, n197, n198, n199, n200, n201, n202, n203, n204, n205, n206,
         n207, n208, n209, n210, n211, n212, n213, n214, n215, n216, n217,
         n218, n219, n220, n221, intadd_0_CI, intadd_0_SUM_21_,
         intadd_0_SUM_20_, intadd_0_SUM_19_, intadd_0_SUM_18_,
         intadd_0_SUM_17_, intadd_0_SUM_16_, intadd_0_SUM_15_,
         intadd_0_SUM_14_, intadd_0_SUM_13_, intadd_0_SUM_12_,
         intadd_0_SUM_11_, intadd_0_SUM_10_, intadd_0_SUM_9_, intadd_0_SUM_8_,
         intadd_0_SUM_7_, intadd_0_SUM_6_, intadd_0_SUM_5_, intadd_0_SUM_4_,
         intadd_0_SUM_3_, intadd_0_SUM_2_, intadd_0_SUM_1_, intadd_0_SUM_0_,
         intadd_0_n22, intadd_0_n21, intadd_0_n20, intadd_0_n19, intadd_0_n18,
         intadd_0_n17, intadd_0_n16, intadd_0_n15, intadd_0_n14, intadd_0_n13,
         intadd_0_n12, intadd_0_n11, intadd_0_n10, intadd_0_n9, intadd_0_n8,
         intadd_0_n7, intadd_0_n6, intadd_0_n5, intadd_0_n4, intadd_0_n3,
         intadd_0_n2, intadd_0_n1, intadd_1_SUM_20_, intadd_1_SUM_19_,
         intadd_1_SUM_18_, intadd_1_SUM_17_, intadd_1_SUM_16_,
         intadd_1_SUM_15_, intadd_1_SUM_14_, intadd_1_SUM_13_,
         intadd_1_SUM_12_, intadd_1_SUM_11_, intadd_1_SUM_10_, intadd_1_SUM_9_,
         intadd_1_SUM_8_, intadd_1_SUM_7_, intadd_1_SUM_6_, intadd_1_SUM_5_,
         intadd_1_SUM_4_, intadd_1_SUM_3_, intadd_1_SUM_2_, intadd_1_SUM_1_,
         intadd_1_SUM_0_, intadd_1_n21, intadd_1_n20, intadd_1_n19,
         intadd_1_n18, intadd_1_n17, intadd_1_n16, intadd_1_n15, intadd_1_n14,
         intadd_1_n13, intadd_1_n12, intadd_1_n11, intadd_1_n10, intadd_1_n9,
         intadd_1_n8, intadd_1_n7, intadd_1_n6, intadd_1_n5, intadd_1_n4,
         intadd_1_n3, intadd_1_n2, intadd_1_n1, intadd_2_A_19_, intadd_2_A_18_,
         intadd_2_A_17_, intadd_2_A_16_, intadd_2_A_15_, intadd_2_A_14_,
         intadd_2_A_13_, intadd_2_A_12_, intadd_2_A_11_, intadd_2_A_10_,
         intadd_2_A_9_, intadd_2_A_8_, intadd_2_A_7_, intadd_2_A_6_,
         intadd_2_A_5_, intadd_2_A_4_, intadd_2_A_3_, intadd_2_A_2_,
         intadd_2_A_1_, intadd_2_A_0_, intadd_2_B_19_, intadd_2_B_18_,
         intadd_2_B_17_, intadd_2_B_16_, intadd_2_B_15_, intadd_2_B_14_,
         intadd_2_B_13_, intadd_2_B_12_, intadd_2_B_11_, intadd_2_B_10_,
         intadd_2_B_9_, intadd_2_B_8_, intadd_2_B_7_, intadd_2_B_6_,
         intadd_2_B_5_, intadd_2_B_4_, intadd_2_B_3_, intadd_2_B_2_,
         intadd_2_B_1_, intadd_2_B_0_, intadd_2_CI, intadd_2_SUM_19_,
         intadd_2_SUM_18_, intadd_2_SUM_17_, intadd_2_SUM_16_,
         intadd_2_SUM_15_, intadd_2_SUM_14_, intadd_2_SUM_13_,
         intadd_2_SUM_12_, intadd_2_SUM_11_, intadd_2_SUM_10_, intadd_2_SUM_9_,
         intadd_2_SUM_8_, intadd_2_SUM_7_, intadd_2_SUM_6_, intadd_2_SUM_5_,
         intadd_2_SUM_4_, intadd_2_SUM_3_, intadd_2_SUM_2_, intadd_2_SUM_1_,
         intadd_2_SUM_0_, intadd_2_n20, intadd_2_n19, intadd_2_n18,
         intadd_2_n17, intadd_2_n16, intadd_2_n15, intadd_2_n14, intadd_2_n13,
         intadd_2_n12, intadd_2_n11, intadd_2_n10, intadd_2_n9, intadd_2_n8,
         intadd_2_n7, intadd_2_n6, intadd_2_n5, intadd_2_n4, intadd_2_n3,
         intadd_2_n2, intadd_2_n1, intadd_3_A_19_, intadd_3_A_18_,
         intadd_3_A_17_, intadd_3_A_16_, intadd_3_A_15_, intadd_3_A_14_,
         intadd_3_A_13_, intadd_3_A_12_, intadd_3_A_11_, intadd_3_A_10_,
         intadd_3_A_9_, intadd_3_A_8_, intadd_3_A_7_, intadd_3_A_6_,
         intadd_3_A_5_, intadd_3_A_4_, intadd_3_A_3_, intadd_3_A_2_,
         intadd_3_A_1_, intadd_3_A_0_, intadd_3_B_19_, intadd_3_B_18_,
         intadd_3_B_17_, intadd_3_B_16_, intadd_3_B_15_, intadd_3_B_14_,
         intadd_3_B_13_, intadd_3_B_12_, intadd_3_B_11_, intadd_3_B_10_,
         intadd_3_B_9_, intadd_3_B_8_, intadd_3_B_7_, intadd_3_B_6_,
         intadd_3_B_5_, intadd_3_B_4_, intadd_3_B_3_, intadd_3_B_2_,
         intadd_3_B_1_, intadd_3_B_0_, intadd_3_CI, intadd_3_SUM_19_,
         intadd_3_SUM_18_, intadd_3_SUM_17_, intadd_3_SUM_16_,
         intadd_3_SUM_15_, intadd_3_SUM_14_, intadd_3_SUM_13_,
         intadd_3_SUM_12_, intadd_3_SUM_11_, intadd_3_SUM_10_, intadd_3_SUM_9_,
         intadd_3_SUM_8_, intadd_3_SUM_7_, intadd_3_SUM_6_, intadd_3_SUM_5_,
         intadd_3_SUM_4_, intadd_3_SUM_3_, intadd_3_SUM_2_, intadd_3_SUM_1_,
         intadd_3_SUM_0_, intadd_3_n20, intadd_3_n19, intadd_3_n18,
         intadd_3_n17, intadd_3_n16, intadd_3_n15, intadd_3_n14, intadd_3_n13,
         intadd_3_n12, intadd_3_n11, intadd_3_n10, intadd_3_n9, intadd_3_n8,
         intadd_3_n7, intadd_3_n6, intadd_3_n5, intadd_3_n4, intadd_3_n3,
         intadd_3_n2, intadd_3_n1, n222, n223, n224, n225, n226, n227, n228,
         n229, n230, n231, n232, n233, n234, n235, n236, n237, n238, n239,
         n240, n241, n242, n243, n244, n245, n246, n247, n248, n249, n250,
         n251, n252, n253, n254, n255, n256, n257, n258, n259, n260, n261,
         n262, n263, n264, n265, n266, n267, n268, n269, n270, n271, n272,
         n273, n274, n275, n276, n277, n278, n279, n280, n281, n283, n286,
         n289, n292, n295, n298, n301, n304, n307, n310, n313, n316, n318,
         n319, n320, n321, n322, n323, n324, n325, n326, n327, n328, n329,
         n330, n331, n333, n334, n336, n337, n339, n340, n341, n342, n343,
         n344, n345, n346, n347, n348, n349, n350, n351, n352, n353, n354,
         n355, n356, n357, n358, n359, n360, n361, n362, n363, n364, n365,
         n366, n367, n368, n369, n370, n371, n372, n374, n375, n377, n378,
         n380, n381, n383, n384, n386, n387, n389, n390, n392, n393, n395,
         n396, n398, n399, n401, n402, n404, n405, n407, n408, n411, n412,
         n414, n415, n417, n418, n420, n421, n423, n424, n426, n427, n429,
         n430, n432, n433, n435, n436, n437, n438, n439, n440, n441, n442,
         n444, n445, n446, n447, n448, n449, n450, n451, n452, n453, n454,
         n455, n456, n457, n458, n459, n460, n461, n462, n463, n464, n465,
         n466, n467, n468, n469, n470, n471, n472, n473, n474, n475, n476,
         n477, n478, n479, n480, n481, n482, n483, n484, n485, n486, n487,
         n488, n489, n490, n491, n492, n493, n494, n495, n496, n497, n498,
         n499, n500, n501, n502, n503, n504, n505, n506, n507, n508, n509,
         n510, n511, n512, n513, n514, n515, n516, n517, n518, n519, n520,
         n521, n522, n523, n524, n525, n526, n527, n528, n529, n530, n531,
         n532, n533, n534, n535, n536, n537, n538, n539, n540, n541, n542,
         n543, n544, n545, n546, n547, n548, n549, n550, n551, n552, n553,
         n554, n555, n556, n557, n558, n559, n560, n561, n562, n563, n564,
         n565, n566, n567, n568, n569, n570, n571, n572, n573, n574, n575,
         n576, n577, n578, n579, n580, n581, n582, n583, n584, n585, n586,
         n587, n588, n589, n590, n591, n592, n593, n594, n595, n596, n597,
         n598, n599, n600, n601, n602, n603, n604, n605, n606, n607, n608,
         n609, n610, n611, n612, n613, n614, n615, n616, n617, n618, n619,
         n620, n621, n622, n623, n624, n625, n626, n627, n628, n629, n632,
         n634, n636, n638, n640, n642, n644, n646, n648, n650, n658, n659,
         n660, n661, n662, n663, n664, n665, n666, n667, n668, n669, n670,
         n671, n672, n673, n674, n675, n676, n677, n678, n679, n680, n681,
         n682, n683, n684, n685, n686, n687, n688, n689, n690, n691, n692,
         n693, n694, n695, n696, n697, n698, n699, n700, n701, n702, n703,
         n704, n705, n706, n707, n708, n709, n710, n711, n712, n713, n714,
         n715, n716, n717, n718, n719, n720, n721, n729, n732, n805, n806,
         n807, n808, n809, n810, n811, n812, n813, n814, n815, n817, n818,
         n821, n824, n825, n826, n827, n828, n829, n830, n831, n832, n833,
         n834, n835, n836, n837, n838, n839, n841, n842, n845, n846, n848,
         n849, n850, n851, n852, n853, n854, n855, n856, n857, n858, n859,
         n860, n861, n862, n863, n864, n866, n867, n868, n869, n870, n871,
         n872, n873, n874, n875, n876, n877, n878, n879, n880, n881, n882,
         n883, n884, n886, n887, n888, n889, n890, n891, n892, n893, n894,
         n895, n896, n897, n898, n899, n900, n901, n902, n903, n904, n905,
         n906, n907, n908, n909, n910, n911, n912, n913, n914, n915, n916,
         n917, n918, n919, n920, n921, n922, n923, n924, n925, n926, n927,
         n928, n929, n930, n931, n932, n933, n934, n935, n936, n937, n938,
         n939, n940, n941, n942, n943, n944, n945, n946, n947, n948, n949,
         n950, n951, n952, n953, n954, n955, n956, n957, n958, n959, n960,
         n961, n962, n963, n964, n965, n966, n967, n968, n969, n970, n971,
         n972, n973, n974, n975, n976, n977, n978, n979, n980, n981, n982,
         n983, n985, n986, n987, n988, n989, n990, n991, n992, n993, n994,
         n995, n996, n997, n998, n999, n1000, n1001, n1002, n1003, n1004,
         n1005, n1006, n1007, n1008, n1009, n1010, n1011, n1012, n1013, n1014,
         n1015, n1016, n1017, n1018, n1019, n1020, n1021, n1022, n1023, n1024,
         n1025, n1026, n1027, n1029, n1030, n1031, n1032, n1033, n1034, n1035,
         n1036, n1037, n1038, n1039, n1040, n1041, n1042, n1043, n1044, n1045,
         n1046, n1047, n1048, n1049, n1050, n1051, n1052, n1053, n1054, n1055,
         n1056, n1057, n1058, n1059, n1060, n1061, n1062, n1063, n1064, n1065,
         n1066, n1067, n1068, n1069, n1070, n1071, n1072, n1073, n1074, n1075,
         n1076, n1077, n1078, n1079, n1080, n1081, n1082, n1083, n1084, n1085,
         n1086, n1087, n1088, n1089, n1090, n1091, n1092, n1093, n1094, n1095,
         n1096, n1097, n1098, n1099, n1100, n1101, n1102, n1103, n1104, n1105,
         n1106, n1107, n1108, n1109, n1110, n1111, n1112, n1113, n1114, n1115,
         n1116, n1117, n1118, n1119, n1120, n1121, n1122, n1123, n1124, n1125,
         n1126, n1127, n1128, n1129, n1130, n1131, n1132, n1133, n1134, n1135,
         n1136, n1137, n1138, n1139, n1140, n1141, n1142, n1143, n1144, n1145,
         n1146, n1147, n1148, n1149, n1150, n1151, n1152, n1153, n1154, n1155,
         n1156, n1157, n1158, n1159, n1160, n1161, n1162, n1163, n1164, n1165,
         n1166, n1167, n1168, n1169, n1170, n1171, n1172, n1173, n1174, n1175,
         n1176, n1177, n1178, n1179, n1180, n1181, n1182, n1183, n1184, n1185,
         n1186, n1187, n1188, n1189, n1190, n1191, n1192, n1193, n1194, n1195,
         n1196, n1197, n1198, n1199, n1299, n1300, n1301, n1302, n1303, n1304,
         n1305, n1306, n1307, n1308, n1309, n1310, n1311;
  wire   [22:0] g_tree_g_level_1__g_node_0__sum_q;
  wire   [1:0] g_tree_g_level_1__g_node_0__count_q;
  wire   [22:0] g_tree_g_level_1__g_node_1__sum_q;
  wire   [1:0] g_tree_g_level_1__g_node_1__count_q;
  wire   [23:0] g_tree_g_level_2__g_node_0__sum_q;
  wire   [2:0] g_tree_g_level_2__g_node_0__count_q;

  DFFSR g_tree_g_level_1__g_node_0__ss_q_reg ( .D(N66), .CLK(clk), .R(n1196), 
        .S(1'b1), .Q(g_tree_ss_1__0_) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_22_ ( .D(n265), .CLK(clk), .R(
        n1195), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[22]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_21_ ( .D(n264), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[21]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_20_ ( .D(n263), .CLK(clk), .R(
        n1195), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[20]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_19_ ( .D(n262), .CLK(clk), .R(
        n1199), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[19]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_18_ ( .D(n261), .CLK(clk), .R(
        n1196), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[18]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_17_ ( .D(n260), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[17]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_16_ ( .D(n259), .CLK(clk), .R(
        n1194), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[16]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_15_ ( .D(n258), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[15]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_14_ ( .D(n257), .CLK(clk), .R(
        n1198), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[14]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_13_ ( .D(n256), .CLK(clk), .R(
        rst_n), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[13]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_12_ ( .D(n255), .CLK(clk), .R(
        n1190), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[12]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_11_ ( .D(n254), .CLK(clk), .R(
        n1196), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[11]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_10_ ( .D(n253), .CLK(clk), .R(
        n1192), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[10]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_9_ ( .D(n252), .CLK(clk), .R(
        n1198), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[9]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_8_ ( .D(n251), .CLK(clk), .R(
        n1193), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[8]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_7_ ( .D(n250), .CLK(clk), .R(
        n1194), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[7]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_6_ ( .D(n249), .CLK(clk), .R(
        n1196), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[6]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_5_ ( .D(n248), .CLK(clk), .R(
        n1192), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[5]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_4_ ( .D(n659), .CLK(clk), .R(
        n1198), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[4]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_3_ ( .D(n247), .CLK(clk), .R(
        n1193), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[3]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_2_ ( .D(n246), .CLK(clk), .R(
        n1194), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[2]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_1_ ( .D(N41), .CLK(clk), .R(
        n1196), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[1]) );
  DFFSR g_tree_g_level_1__g_node_0__sum_q_reg_0_ ( .D(N40), .CLK(clk), .R(
        n1192), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__sum_q[0]) );
  DFFSR g_tree_g_level_1__g_node_0__count_q_reg_1_ ( .D(N64), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__count_q[1]) );
  DFFSR g_tree_g_level_1__g_node_0__count_q_reg_0_ ( .D(N63), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_0__count_q[0]) );
  DFFSR g_tree_g_level_1__g_node_0__sx_q_reg ( .D(n660), .CLK(clk), .R(n1189), 
        .S(1'b1), .Q(g_tree_sx_1__0_) );
  DFFSR g_tree_g_level_1__g_node_1__ss_q_reg ( .D(N120), .CLK(clk), .R(n1189), 
        .S(1'b1), .Q(g_tree_ss_1__1_) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_22_ ( .D(n245), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[22]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_21_ ( .D(n244), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[21]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_20_ ( .D(n243), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[20]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_19_ ( .D(n242), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[19]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_18_ ( .D(n241), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[18]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_17_ ( .D(n240), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[17]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_16_ ( .D(n239), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[16]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_15_ ( .D(n238), .CLK(clk), .R(
        n1189), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[15]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_14_ ( .D(n237), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[14]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_13_ ( .D(n236), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[13]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_12_ ( .D(n235), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[12]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_11_ ( .D(n234), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[11]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_10_ ( .D(n233), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[10]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_9_ ( .D(n232), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[9]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_8_ ( .D(n231), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[8]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_7_ ( .D(n230), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[7]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_6_ ( .D(n229), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[6]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_5_ ( .D(n228), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[5]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_4_ ( .D(n227), .CLK(clk), .R(
        n1198), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[4]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_3_ ( .D(n226), .CLK(clk), .R(
        n1193), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[3]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_2_ ( .D(n225), .CLK(clk), .R(
        n1191), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[2]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_1_ ( .D(n661), .CLK(clk), .R(
        n1195), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[1]) );
  DFFSR g_tree_g_level_1__g_node_1__sum_q_reg_0_ ( .D(N94), .CLK(clk), .R(
        n1197), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__sum_q[0]) );
  DFFSR g_tree_g_level_1__g_node_1__count_q_reg_1_ ( .D(N118), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__count_q[1]) );
  DFFSR g_tree_g_level_1__g_node_1__count_q_reg_0_ ( .D(N117), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_1__g_node_1__count_q[0]) );
  DFFSR g_tree_g_level_1__g_node_1__sx_q_reg ( .D(N119), .CLK(clk), .R(n1191), 
        .S(1'b1), .Q(g_tree_sx_1__1_) );
  DFFSR g_tree_g_level_2__g_node_0__ss_q_reg ( .D(N180), .CLK(clk), .R(n583), 
        .S(1'b1), .Q(g_tree_ss_2__0_) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_23_ ( .D(N174), .CLK(clk), .R(
        n1199), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[23]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_22_ ( .D(N173), .CLK(clk), .R(
        n1190), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[22]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_21_ ( .D(N172), .CLK(clk), .R(
        n1191), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[21]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_20_ ( .D(N171), .CLK(clk), .R(
        n1195), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[20]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_19_ ( .D(N170), .CLK(clk), .R(
        n1197), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[19]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_18_ ( .D(N169), .CLK(clk), .R(
        n1193), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[18]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_17_ ( .D(N168), .CLK(clk), .R(
        n1194), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[17]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_16_ ( .D(N167), .CLK(clk), .R(
        n1196), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[16]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_15_ ( .D(N166), .CLK(clk), .R(
        n1192), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[15]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_14_ ( .D(N165), .CLK(clk), .R(
        n1198), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[14]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_13_ ( .D(N164), .CLK(clk), .R(
        n1193), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[13]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_12_ ( .D(N163), .CLK(clk), .R(
        n1194), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[12]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_11_ ( .D(N162), .CLK(clk), .R(
        n1196), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[11]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_10_ ( .D(N161), .CLK(clk), .R(
        n1192), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[10]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_9_ ( .D(N160), .CLK(clk), .R(
        n1198), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[9]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_8_ ( .D(N159), .CLK(clk), .R(
        n1193), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[8]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_7_ ( .D(N158), .CLK(clk), .R(
        n1194), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[7]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_6_ ( .D(N157), .CLK(clk), .R(
        n1197), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[6]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_5_ ( .D(N156), .CLK(clk), .R(
        n582), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[5]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_4_ ( .D(N155), .CLK(clk), .R(
        n1197), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[4]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_3_ ( .D(N154), .CLK(clk), .R(
        rst_n), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[3]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_2_ ( .D(N153), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[2]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_1_ ( .D(N152), .CLK(clk), .R(
        n1191), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[1]) );
  DFFSR g_tree_g_level_2__g_node_0__sum_q_reg_0_ ( .D(N151), .CLK(clk), .R(
        n1192), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__sum_q[0]) );
  DFFSR g_tree_g_level_2__g_node_0__count_q_reg_2_ ( .D(N178), .CLK(clk), .R(
        n1192), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__count_q[2]) );
  DFFSR g_tree_g_level_2__g_node_0__count_q_reg_1_ ( .D(N177), .CLK(clk), .R(
        n583), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__count_q[1]) );
  DFFSR g_tree_g_level_2__g_node_0__count_q_reg_0_ ( .D(N176), .CLK(clk), .R(
        n1199), .S(1'b1), .Q(g_tree_g_level_2__g_node_0__count_q[0]) );
  DFFSR g_tree_g_level_2__g_node_0__sx_q_reg ( .D(N179), .CLK(clk), .R(n1199), 
        .S(1'b1), .Q(g_tree_sx_2__0_) );
  DFFSR sat_s_seen_reg ( .D(n220), .CLK(clk), .R(rst_n), .S(1'b1), .Q(n1298)
         );
  DFFSR payoff_sum_reg_63_ ( .D(n123), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1200) );
  DFFSR payoff_sum_reg_62_ ( .D(n124), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1201) );
  DFFSR payoff_sum_reg_61_ ( .D(n316), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1202) );
  DFFSR payoff_sum_reg_60_ ( .D(n126), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1203) );
  DFFSR payoff_sum_reg_59_ ( .D(n313), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1204) );
  DFFSR payoff_sum_reg_58_ ( .D(n128), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1205) );
  DFFSR payoff_sum_reg_57_ ( .D(n310), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1206) );
  DFFSR payoff_sum_reg_56_ ( .D(n130), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1207) );
  DFFSR payoff_sum_reg_55_ ( .D(n307), .CLK(clk), .R(n582), .S(1'b1), .Q(n1208) );
  DFFSR payoff_sum_reg_54_ ( .D(n132), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1209) );
  DFFSR payoff_sum_reg_53_ ( .D(n304), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1210) );
  DFFSR payoff_sum_reg_52_ ( .D(n134), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1211) );
  DFFSR payoff_sum_reg_51_ ( .D(n301), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1212) );
  DFFSR payoff_sum_reg_50_ ( .D(n136), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1213) );
  DFFSR payoff_sum_reg_49_ ( .D(n298), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1214) );
  DFFSR payoff_sum_reg_48_ ( .D(n138), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1215) );
  DFFSR payoff_sum_reg_47_ ( .D(n295), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1216) );
  DFFSR payoff_sum_reg_46_ ( .D(n140), .CLK(clk), .R(n583), .S(1'b1), .Q(n1217) );
  DFFSR payoff_sum_reg_45_ ( .D(n292), .CLK(clk), .R(n582), .S(1'b1), .Q(n1218) );
  DFFSR payoff_sum_reg_44_ ( .D(n142), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1219) );
  DFFSR payoff_sum_reg_43_ ( .D(n289), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1220) );
  DFFSR payoff_sum_reg_42_ ( .D(n144), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1221) );
  DFFSR payoff_sum_reg_41_ ( .D(n286), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1222) );
  DFFSR payoff_sum_reg_40_ ( .D(n146), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1223) );
  DFFSR payoff_sum_reg_39_ ( .D(n283), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1224) );
  DFFSR payoff_sum_reg_38_ ( .D(n148), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1225) );
  DFFSR payoff_sum_reg_37_ ( .D(n281), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1226) );
  DFFSR payoff_sum_reg_36_ ( .D(n150), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1227) );
  DFFSR payoff_sum_reg_35_ ( .D(n280), .CLK(clk), .R(n1189), .S(1'b1), .Q(
        n1228) );
  DFFSR payoff_sum_reg_34_ ( .D(n152), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1229) );
  DFFSR payoff_sum_reg_33_ ( .D(n279), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1230) );
  DFFSR payoff_sum_reg_32_ ( .D(n154), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1231) );
  DFFSR payoff_sum_reg_31_ ( .D(n278), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1232) );
  DFFSR payoff_sum_reg_30_ ( .D(n156), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1233) );
  DFFSR payoff_sum_reg_29_ ( .D(n277), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1234) );
  DFFSR payoff_sum_reg_28_ ( .D(n158), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1235) );
  DFFSR payoff_sum_reg_27_ ( .D(n159), .CLK(clk), .R(n1193), .S(1'b1), .Q(
        n1236) );
  DFFSR payoff_sum_reg_26_ ( .D(n160), .CLK(clk), .R(n1194), .S(1'b1), .Q(
        n1237) );
  DFFSR payoff_sum_reg_25_ ( .D(n161), .CLK(clk), .R(n1196), .S(1'b1), .Q(
        n1238) );
  DFFSR payoff_sum_reg_24_ ( .D(n162), .CLK(clk), .R(n1192), .S(1'b1), .Q(
        n1239) );
  DFFSR payoff_sum_reg_23_ ( .D(n163), .CLK(clk), .R(n1198), .S(1'b1), .Q(
        n1240) );
  DFFSR payoff_sum_reg_22_ ( .D(n164), .CLK(clk), .R(n1193), .S(1'b1), .Q(
        n1241) );
  DFFSR payoff_sum_reg_21_ ( .D(n165), .CLK(clk), .R(n1194), .S(1'b1), .Q(
        n1242) );
  DFFSR payoff_sum_reg_20_ ( .D(n166), .CLK(clk), .R(n1196), .S(1'b1), .Q(
        n1243) );
  DFFSR payoff_sum_reg_19_ ( .D(n167), .CLK(clk), .R(n1192), .S(1'b1), .Q(
        n1244) );
  DFFSR payoff_sum_reg_18_ ( .D(n168), .CLK(clk), .R(n1198), .S(1'b1), .Q(
        n1245) );
  DFFSR payoff_sum_reg_17_ ( .D(n169), .CLK(clk), .R(n1193), .S(1'b1), .Q(
        n1246) );
  DFFSR payoff_sum_reg_16_ ( .D(n170), .CLK(clk), .R(n1194), .S(1'b1), .Q(
        n1247) );
  DFFSR payoff_sum_reg_15_ ( .D(n171), .CLK(clk), .R(n1193), .S(1'b1), .Q(
        n1248) );
  DFFSR payoff_sum_reg_14_ ( .D(n172), .CLK(clk), .R(n1194), .S(1'b1), .Q(
        n1249) );
  DFFSR payoff_sum_reg_13_ ( .D(n173), .CLK(clk), .R(n1196), .S(1'b1), .Q(
        n1250) );
  DFFSR payoff_sum_reg_12_ ( .D(n174), .CLK(clk), .R(n1192), .S(1'b1), .Q(
        n1251) );
  DFFSR payoff_sum_reg_11_ ( .D(n175), .CLK(clk), .R(n1198), .S(1'b1), .Q(
        n1252) );
  DFFSR payoff_sum_reg_10_ ( .D(n176), .CLK(clk), .R(n1193), .S(1'b1), .Q(
        n1253) );
  DFFSR payoff_sum_reg_9_ ( .D(n177), .CLK(clk), .R(n1194), .S(1'b1), .Q(n1254) );
  DFFSR payoff_sum_reg_8_ ( .D(n178), .CLK(clk), .R(n1196), .S(1'b1), .Q(n1255) );
  DFFSR payoff_sum_reg_7_ ( .D(n179), .CLK(clk), .R(n1192), .S(1'b1), .Q(n1256) );
  DFFSR payoff_sum_reg_6_ ( .D(n180), .CLK(clk), .R(n1198), .S(1'b1), .Q(n1257) );
  DFFSR payoff_sum_reg_5_ ( .D(n181), .CLK(clk), .R(n1193), .S(1'b1), .Q(n1258) );
  DFFSR payoff_sum_reg_4_ ( .D(n182), .CLK(clk), .R(n1194), .S(1'b1), .Q(n1259) );
  DFFSR payoff_sum_reg_3_ ( .D(n183), .CLK(clk), .R(n582), .S(1'b1), .Q(n1260)
         );
  DFFSR payoff_sum_reg_2_ ( .D(n184), .CLK(clk), .R(n1190), .S(1'b1), .Q(n1261) );
  DFFSR payoff_sum_reg_1_ ( .D(n224), .CLK(clk), .R(n1190), .S(1'b1), .Q(n1262) );
  DFFSR payoff_sum_reg_0_ ( .D(n223), .CLK(clk), .R(n1189), .S(1'b1), .Q(n1263) );
  DFFSR trial_count_reg_31_ ( .D(n187), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1264) );
  DFFSR trial_count_reg_30_ ( .D(n188), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1265) );
  DFFSR trial_count_reg_29_ ( .D(n189), .CLK(clk), .R(n1198), .S(1'b1), .Q(
        n1266) );
  DFFSR trial_count_reg_28_ ( .D(n190), .CLK(clk), .R(n1196), .S(1'b1), .Q(
        n1267) );
  DFFSR trial_count_reg_27_ ( .D(n191), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1268) );
  DFFSR trial_count_reg_26_ ( .D(n276), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1269) );
  DFFSR trial_count_reg_25_ ( .D(n193), .CLK(clk), .R(n1192), .S(1'b1), .Q(
        n1270) );
  DFFSR trial_count_reg_24_ ( .D(n275), .CLK(clk), .R(n1198), .S(1'b1), .Q(
        n1271) );
  DFFSR trial_count_reg_23_ ( .D(n195), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1272) );
  DFFSR trial_count_reg_22_ ( .D(n274), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1273) );
  DFFSR trial_count_reg_21_ ( .D(n197), .CLK(clk), .R(n583), .S(1'b1), .Q(
        n1274) );
  DFFSR trial_count_reg_20_ ( .D(n273), .CLK(clk), .R(n582), .S(1'b1), .Q(
        n1275) );
  DFFSR trial_count_reg_19_ ( .D(n199), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1276) );
  DFFSR trial_count_reg_18_ ( .D(n272), .CLK(clk), .R(n1190), .S(1'b1), .Q(
        n1277) );
  DFFSR trial_count_reg_17_ ( .D(n201), .CLK(clk), .R(n1191), .S(1'b1), .Q(
        n1278) );
  DFFSR trial_count_reg_16_ ( .D(n271), .CLK(clk), .R(n1195), .S(1'b1), .Q(
        n1279) );
  DFFSR trial_count_reg_15_ ( .D(n203), .CLK(clk), .R(n1197), .S(1'b1), .Q(
        n1280) );
  DFFSR trial_count_reg_14_ ( .D(n270), .CLK(clk), .R(n583), .S(1'b1), .Q(
        n1281) );
  DFFSR trial_count_reg_13_ ( .D(n205), .CLK(clk), .R(n582), .S(1'b1), .Q(
        n1282) );
  DFFSR trial_count_reg_12_ ( .D(n269), .CLK(clk), .R(n1199), .S(1'b1), .Q(
        n1283) );
  DFFSR trial_count_reg_11_ ( .D(n207), .CLK(clk), .R(n1194), .S(1'b1), .Q(
        n1284) );
  DFFSR trial_count_reg_10_ ( .D(n268), .CLK(clk), .R(n1196), .S(1'b1), .Q(
        n1285) );
  DFFSR trial_count_reg_9_ ( .D(n209), .CLK(clk), .R(n1192), .S(1'b1), .Q(
        n1286) );
  DFFSR trial_count_reg_8_ ( .D(n267), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1287) );
  DFFSR trial_count_reg_7_ ( .D(n211), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1288) );
  DFFSR trial_count_reg_6_ ( .D(n212), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1289) );
  DFFSR trial_count_reg_5_ ( .D(n213), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1290) );
  DFFSR trial_count_reg_4_ ( .D(n214), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1291) );
  DFFSR trial_count_reg_3_ ( .D(n215), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1292) );
  DFFSR trial_count_reg_2_ ( .D(n216), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1293) );
  DFFSR trial_count_reg_1_ ( .D(n222), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1294) );
  DFFSR trial_count_reg_0_ ( .D(n266), .CLK(clk), .R(rst_n), .S(1'b1), .Q(
        n1295) );
  DFFSR acc_overflow_reg ( .D(n219), .CLK(clk), .R(n1198), .S(1'b1), .Q(n1296)
         );
  DFFSR sat_x_seen_reg ( .D(n221), .CLK(clk), .R(n1193), .S(1'b1), .Q(n1297)
         );
  FAX1 intadd_0_U23 ( .A(n584), .B(payoff_sum[2]), .C(n485), .YC(intadd_0_n22), 
        .YS(intadd_0_SUM_0_) );
  FAX1 intadd_0_U22 ( .A(n585), .B(payoff_sum[3]), .C(intadd_0_n22), .YC(
        intadd_0_n21), .YS(intadd_0_SUM_1_) );
  FAX1 intadd_0_U21 ( .A(n586), .B(payoff_sum[4]), .C(intadd_0_n21), .YC(
        intadd_0_n20), .YS(intadd_0_SUM_2_) );
  FAX1 intadd_0_U20 ( .A(n587), .B(payoff_sum[5]), .C(intadd_0_n20), .YC(
        intadd_0_n19), .YS(intadd_0_SUM_3_) );
  FAX1 intadd_0_U19 ( .A(n588), .B(payoff_sum[6]), .C(intadd_0_n19), .YC(
        intadd_0_n18), .YS(intadd_0_SUM_4_) );
  FAX1 intadd_0_U18 ( .A(n589), .B(payoff_sum[7]), .C(intadd_0_n18), .YC(
        intadd_0_n17), .YS(intadd_0_SUM_5_) );
  FAX1 intadd_0_U17 ( .A(n590), .B(payoff_sum[8]), .C(intadd_0_n17), .YC(
        intadd_0_n16), .YS(intadd_0_SUM_6_) );
  FAX1 intadd_0_U16 ( .A(n591), .B(payoff_sum[9]), .C(intadd_0_n16), .YC(
        intadd_0_n15), .YS(intadd_0_SUM_7_) );
  FAX1 intadd_0_U15 ( .A(n592), .B(payoff_sum[10]), .C(intadd_0_n15), .YC(
        intadd_0_n14), .YS(intadd_0_SUM_8_) );
  FAX1 intadd_0_U14 ( .A(n593), .B(payoff_sum[11]), .C(intadd_0_n14), .YC(
        intadd_0_n13), .YS(intadd_0_SUM_9_) );
  FAX1 intadd_0_U13 ( .A(n594), .B(payoff_sum[12]), .C(intadd_0_n13), .YC(
        intadd_0_n12), .YS(intadd_0_SUM_10_) );
  FAX1 intadd_0_U12 ( .A(n595), .B(payoff_sum[13]), .C(intadd_0_n12), .YC(
        intadd_0_n11), .YS(intadd_0_SUM_11_) );
  FAX1 intadd_0_U11 ( .A(n596), .B(payoff_sum[14]), .C(intadd_0_n11), .YC(
        intadd_0_n10), .YS(intadd_0_SUM_12_) );
  FAX1 intadd_0_U10 ( .A(n597), .B(payoff_sum[15]), .C(intadd_0_n10), .YC(
        intadd_0_n9), .YS(intadd_0_SUM_13_) );
  FAX1 intadd_0_U9 ( .A(n598), .B(payoff_sum[16]), .C(intadd_0_n9), .YC(
        intadd_0_n8), .YS(intadd_0_SUM_14_) );
  FAX1 intadd_0_U8 ( .A(n599), .B(payoff_sum[17]), .C(intadd_0_n8), .YC(
        intadd_0_n7), .YS(intadd_0_SUM_15_) );
  FAX1 intadd_0_U7 ( .A(n600), .B(payoff_sum[18]), .C(intadd_0_n7), .YC(
        intadd_0_n6), .YS(intadd_0_SUM_16_) );
  FAX1 intadd_0_U6 ( .A(n601), .B(payoff_sum[19]), .C(intadd_0_n6), .YC(
        intadd_0_n5), .YS(intadd_0_SUM_17_) );
  FAX1 intadd_0_U5 ( .A(n602), .B(payoff_sum[20]), .C(intadd_0_n5), .YC(
        intadd_0_n4), .YS(intadd_0_SUM_18_) );
  FAX1 intadd_0_U4 ( .A(n603), .B(payoff_sum[21]), .C(intadd_0_n4), .YC(
        intadd_0_n3), .YS(intadd_0_SUM_19_) );
  FAX1 intadd_0_U3 ( .A(n604), .B(payoff_sum[22]), .C(intadd_0_n3), .YC(
        intadd_0_n2), .YS(intadd_0_SUM_20_) );
  FAX1 intadd_0_U2 ( .A(n605), .B(payoff_sum[23]), .C(intadd_0_n2), .YC(
        intadd_0_n1), .YS(intadd_0_SUM_21_) );
  FAX1 intadd_1_U22 ( .A(n720), .B(n523), .C(n487), .YC(intadd_1_n21), .YS(
        intadd_1_SUM_0_) );
  FAX1 intadd_1_U21 ( .A(n719), .B(n524), .C(intadd_1_n21), .YC(intadd_1_n20), 
        .YS(intadd_1_SUM_1_) );
  FAX1 intadd_1_U20 ( .A(n718), .B(n525), .C(intadd_1_n20), .YC(intadd_1_n19), 
        .YS(intadd_1_SUM_2_) );
  FAX1 intadd_1_U19 ( .A(n717), .B(n526), .C(intadd_1_n19), .YC(intadd_1_n18), 
        .YS(intadd_1_SUM_3_) );
  FAX1 intadd_1_U18 ( .A(n716), .B(n527), .C(intadd_1_n18), .YC(intadd_1_n17), 
        .YS(intadd_1_SUM_4_) );
  FAX1 intadd_1_U17 ( .A(n715), .B(n528), .C(intadd_1_n17), .YC(intadd_1_n16), 
        .YS(intadd_1_SUM_5_) );
  FAX1 intadd_1_U16 ( .A(n714), .B(n529), .C(intadd_1_n16), .YC(intadd_1_n15), 
        .YS(intadd_1_SUM_6_) );
  FAX1 intadd_1_U15 ( .A(n713), .B(n530), .C(intadd_1_n15), .YC(intadd_1_n14), 
        .YS(intadd_1_SUM_7_) );
  FAX1 intadd_1_U14 ( .A(n712), .B(n531), .C(intadd_1_n14), .YC(intadd_1_n13), 
        .YS(intadd_1_SUM_8_) );
  FAX1 intadd_1_U13 ( .A(n711), .B(n532), .C(intadd_1_n13), .YC(intadd_1_n12), 
        .YS(intadd_1_SUM_9_) );
  FAX1 intadd_1_U12 ( .A(n710), .B(n533), .C(intadd_1_n12), .YC(intadd_1_n11), 
        .YS(intadd_1_SUM_10_) );
  FAX1 intadd_1_U11 ( .A(n709), .B(n534), .C(intadd_1_n11), .YC(intadd_1_n10), 
        .YS(intadd_1_SUM_11_) );
  FAX1 intadd_1_U10 ( .A(n708), .B(n535), .C(intadd_1_n10), .YC(intadd_1_n9), 
        .YS(intadd_1_SUM_12_) );
  FAX1 intadd_1_U9 ( .A(n707), .B(n536), .C(intadd_1_n9), .YC(intadd_1_n8), 
        .YS(intadd_1_SUM_13_) );
  FAX1 intadd_1_U8 ( .A(n706), .B(n537), .C(intadd_1_n8), .YC(intadd_1_n7), 
        .YS(intadd_1_SUM_14_) );
  FAX1 intadd_1_U7 ( .A(n705), .B(n538), .C(intadd_1_n7), .YC(intadd_1_n6), 
        .YS(intadd_1_SUM_15_) );
  FAX1 intadd_1_U6 ( .A(n704), .B(n539), .C(intadd_1_n6), .YC(intadd_1_n5), 
        .YS(intadd_1_SUM_16_) );
  FAX1 intadd_1_U5 ( .A(n703), .B(n540), .C(intadd_1_n5), .YC(intadd_1_n4), 
        .YS(intadd_1_SUM_17_) );
  FAX1 intadd_1_U4 ( .A(n702), .B(n541), .C(intadd_1_n4), .YC(intadd_1_n3), 
        .YS(intadd_1_SUM_18_) );
  FAX1 intadd_1_U3 ( .A(n701), .B(n542), .C(intadd_1_n3), .YC(intadd_1_n2), 
        .YS(intadd_1_SUM_19_) );
  FAX1 intadd_1_U2 ( .A(n700), .B(n543), .C(intadd_1_n2), .YC(intadd_1_n1), 
        .YS(intadd_1_SUM_20_) );
  FAX1 intadd_2_U21 ( .A(n685), .B(n491), .C(n489), .YC(intadd_2_n20), .YS(
        intadd_2_SUM_0_) );
  FAX1 intadd_2_U20 ( .A(n684), .B(n563), .C(intadd_2_n20), .YC(intadd_2_n19), 
        .YS(intadd_2_SUM_1_) );
  FAX1 intadd_2_U19 ( .A(n612), .B(n564), .C(intadd_2_n19), .YC(intadd_2_n18), 
        .YS(intadd_2_SUM_2_) );
  FAX1 intadd_2_U18 ( .A(n613), .B(n565), .C(intadd_2_n18), .YC(intadd_2_n17), 
        .YS(intadd_2_SUM_3_) );
  FAX1 intadd_2_U17 ( .A(n614), .B(n566), .C(intadd_2_n17), .YC(intadd_2_n16), 
        .YS(intadd_2_SUM_4_) );
  FAX1 intadd_2_U16 ( .A(n615), .B(n567), .C(intadd_2_n16), .YC(intadd_2_n15), 
        .YS(intadd_2_SUM_5_) );
  FAX1 intadd_2_U15 ( .A(n616), .B(n568), .C(intadd_2_n15), .YC(intadd_2_n14), 
        .YS(intadd_2_SUM_6_) );
  FAX1 intadd_2_U14 ( .A(n617), .B(n569), .C(intadd_2_n14), .YC(intadd_2_n13), 
        .YS(intadd_2_SUM_7_) );
  FAX1 intadd_2_U13 ( .A(n683), .B(n570), .C(intadd_2_n13), .YC(intadd_2_n12), 
        .YS(intadd_2_SUM_8_) );
  FAX1 intadd_2_U12 ( .A(n682), .B(n571), .C(intadd_2_n12), .YC(intadd_2_n11), 
        .YS(intadd_2_SUM_9_) );
  FAX1 intadd_2_U11 ( .A(n681), .B(n572), .C(intadd_2_n11), .YC(intadd_2_n10), 
        .YS(intadd_2_SUM_10_) );
  FAX1 intadd_2_U10 ( .A(n680), .B(n573), .C(intadd_2_n10), .YC(intadd_2_n9), 
        .YS(intadd_2_SUM_11_) );
  FAX1 intadd_2_U9 ( .A(n679), .B(n574), .C(intadd_2_n9), .YC(intadd_2_n8), 
        .YS(intadd_2_SUM_12_) );
  FAX1 intadd_2_U8 ( .A(n678), .B(n575), .C(intadd_2_n8), .YC(intadd_2_n7), 
        .YS(intadd_2_SUM_13_) );
  FAX1 intadd_2_U7 ( .A(n677), .B(n576), .C(intadd_2_n7), .YC(intadd_2_n6), 
        .YS(intadd_2_SUM_14_) );
  FAX1 intadd_2_U6 ( .A(n676), .B(n577), .C(intadd_2_n6), .YC(intadd_2_n5), 
        .YS(intadd_2_SUM_15_) );
  FAX1 intadd_2_U5 ( .A(n675), .B(n578), .C(intadd_2_n5), .YC(intadd_2_n4), 
        .YS(intadd_2_SUM_16_) );
  FAX1 intadd_2_U4 ( .A(n674), .B(n579), .C(intadd_2_n4), .YC(intadd_2_n3), 
        .YS(intadd_2_SUM_17_) );
  FAX1 intadd_2_U3 ( .A(n673), .B(n580), .C(intadd_2_n3), .YC(intadd_2_n2), 
        .YS(intadd_2_SUM_18_) );
  FAX1 intadd_2_U2 ( .A(n672), .B(n581), .C(intadd_2_n2), .YC(intadd_2_n1), 
        .YS(intadd_2_SUM_19_) );
  FAX1 intadd_3_U21 ( .A(n699), .B(n490), .C(n488), .YC(intadd_3_n20), .YS(
        intadd_3_SUM_0_) );
  FAX1 intadd_3_U20 ( .A(n698), .B(n544), .C(intadd_3_n20), .YC(intadd_3_n19), 
        .YS(intadd_3_SUM_1_) );
  FAX1 intadd_3_U19 ( .A(n606), .B(n545), .C(intadd_3_n19), .YC(intadd_3_n18), 
        .YS(intadd_3_SUM_2_) );
  FAX1 intadd_3_U18 ( .A(n607), .B(n546), .C(intadd_3_n18), .YC(intadd_3_n17), 
        .YS(intadd_3_SUM_3_) );
  FAX1 intadd_3_U17 ( .A(n608), .B(n547), .C(intadd_3_n17), .YC(intadd_3_n16), 
        .YS(intadd_3_SUM_4_) );
  FAX1 intadd_3_U16 ( .A(n609), .B(n548), .C(intadd_3_n16), .YC(intadd_3_n15), 
        .YS(intadd_3_SUM_5_) );
  FAX1 intadd_3_U15 ( .A(n610), .B(n549), .C(intadd_3_n15), .YC(intadd_3_n14), 
        .YS(intadd_3_SUM_6_) );
  FAX1 intadd_3_U14 ( .A(n611), .B(n550), .C(intadd_3_n14), .YC(intadd_3_n13), 
        .YS(intadd_3_SUM_7_) );
  FAX1 intadd_3_U13 ( .A(n697), .B(n551), .C(intadd_3_n13), .YC(intadd_3_n12), 
        .YS(intadd_3_SUM_8_) );
  FAX1 intadd_3_U12 ( .A(n696), .B(n552), .C(intadd_3_n12), .YC(intadd_3_n11), 
        .YS(intadd_3_SUM_9_) );
  FAX1 intadd_3_U11 ( .A(n695), .B(n553), .C(intadd_3_n11), .YC(intadd_3_n10), 
        .YS(intadd_3_SUM_10_) );
  FAX1 intadd_3_U10 ( .A(n694), .B(n554), .C(intadd_3_n10), .YC(intadd_3_n9), 
        .YS(intadd_3_SUM_11_) );
  FAX1 intadd_3_U9 ( .A(n693), .B(n555), .C(intadd_3_n9), .YC(intadd_3_n8), 
        .YS(intadd_3_SUM_12_) );
  FAX1 intadd_3_U8 ( .A(n692), .B(n556), .C(intadd_3_n8), .YC(intadd_3_n7), 
        .YS(intadd_3_SUM_13_) );
  FAX1 intadd_3_U7 ( .A(n691), .B(n557), .C(intadd_3_n7), .YC(intadd_3_n6), 
        .YS(intadd_3_SUM_14_) );
  FAX1 intadd_3_U6 ( .A(n690), .B(n558), .C(intadd_3_n6), .YC(intadd_3_n5), 
        .YS(intadd_3_SUM_15_) );
  FAX1 intadd_3_U5 ( .A(n689), .B(n559), .C(intadd_3_n5), .YC(intadd_3_n4), 
        .YS(intadd_3_SUM_16_) );
  FAX1 intadd_3_U4 ( .A(n688), .B(n560), .C(intadd_3_n4), .YC(intadd_3_n3), 
        .YS(intadd_3_SUM_17_) );
  FAX1 intadd_3_U3 ( .A(n687), .B(n561), .C(intadd_3_n3), .YC(intadd_3_n2), 
        .YS(intadd_3_SUM_18_) );
  FAX1 intadd_3_U2 ( .A(n686), .B(n562), .C(intadd_3_n2), .YC(intadd_3_n1), 
        .YS(intadd_3_SUM_19_) );
  BUFX2 U395 ( .A(n217), .Y(n222) );
  BUFX2 U396 ( .A(n186), .Y(n223) );
  BUFX2 U397 ( .A(n185), .Y(n224) );
  OR2X1 U398 ( .A(n868), .B(intadd_3_SUM_0_), .Y(N96) );
  INVX1 U399 ( .A(N96), .Y(n225) );
  OR2X1 U400 ( .A(clear), .B(intadd_3_SUM_1_), .Y(N97) );
  INVX1 U401 ( .A(N97), .Y(n226) );
  OR2X1 U402 ( .A(n838), .B(intadd_3_SUM_2_), .Y(N98) );
  INVX1 U403 ( .A(N98), .Y(n227) );
  OR2X1 U404 ( .A(n838), .B(intadd_3_SUM_3_), .Y(N99) );
  INVX1 U405 ( .A(N99), .Y(n228) );
  OR2X1 U406 ( .A(n838), .B(intadd_3_SUM_4_), .Y(N100) );
  INVX1 U407 ( .A(N100), .Y(n229) );
  OR2X1 U408 ( .A(n838), .B(intadd_3_SUM_5_), .Y(N101) );
  INVX1 U409 ( .A(N101), .Y(n230) );
  OR2X1 U410 ( .A(n838), .B(intadd_3_SUM_6_), .Y(N102) );
  INVX1 U411 ( .A(N102), .Y(n231) );
  OR2X1 U412 ( .A(n838), .B(intadd_3_SUM_7_), .Y(N103) );
  INVX1 U413 ( .A(N103), .Y(n232) );
  OR2X1 U414 ( .A(n838), .B(intadd_3_SUM_8_), .Y(N104) );
  INVX1 U415 ( .A(N104), .Y(n233) );
  OR2X1 U416 ( .A(n838), .B(intadd_3_SUM_9_), .Y(N105) );
  INVX1 U417 ( .A(N105), .Y(n234) );
  OR2X1 U418 ( .A(n838), .B(intadd_3_SUM_10_), .Y(N106) );
  INVX1 U419 ( .A(N106), .Y(n235) );
  OR2X1 U420 ( .A(n838), .B(intadd_3_SUM_11_), .Y(N107) );
  INVX1 U421 ( .A(N107), .Y(n236) );
  OR2X1 U422 ( .A(n838), .B(intadd_3_SUM_12_), .Y(N108) );
  INVX1 U423 ( .A(N108), .Y(n237) );
  OR2X1 U424 ( .A(n838), .B(intadd_3_SUM_13_), .Y(N109) );
  INVX1 U425 ( .A(N109), .Y(n238) );
  OR2X1 U426 ( .A(n838), .B(intadd_3_SUM_14_), .Y(N110) );
  INVX1 U427 ( .A(N110), .Y(n239) );
  OR2X1 U428 ( .A(n838), .B(intadd_3_SUM_15_), .Y(N111) );
  INVX1 U429 ( .A(N111), .Y(n240) );
  OR2X1 U430 ( .A(n838), .B(intadd_3_SUM_16_), .Y(N112) );
  INVX1 U431 ( .A(N112), .Y(n241) );
  OR2X1 U432 ( .A(n838), .B(intadd_3_SUM_17_), .Y(N113) );
  INVX1 U433 ( .A(N113), .Y(n242) );
  OR2X1 U434 ( .A(n868), .B(intadd_3_SUM_18_), .Y(N114) );
  INVX1 U435 ( .A(N114), .Y(n243) );
  OR2X1 U436 ( .A(n868), .B(intadd_3_SUM_19_), .Y(N115) );
  INVX1 U437 ( .A(N115), .Y(n244) );
  OR2X1 U438 ( .A(n868), .B(intadd_3_n1), .Y(N116) );
  INVX1 U439 ( .A(N116), .Y(n245) );
  OR2X1 U440 ( .A(n868), .B(intadd_2_SUM_0_), .Y(N42) );
  INVX1 U441 ( .A(N42), .Y(n246) );
  OR2X1 U442 ( .A(n868), .B(intadd_2_SUM_1_), .Y(N43) );
  INVX1 U443 ( .A(N43), .Y(n247) );
  OR2X1 U444 ( .A(n868), .B(intadd_2_SUM_3_), .Y(N45) );
  INVX1 U445 ( .A(N45), .Y(n248) );
  OR2X1 U446 ( .A(n868), .B(intadd_2_SUM_4_), .Y(N46) );
  INVX1 U447 ( .A(N46), .Y(n249) );
  OR2X1 U448 ( .A(n868), .B(intadd_2_SUM_5_), .Y(N47) );
  INVX1 U449 ( .A(N47), .Y(n250) );
  OR2X1 U450 ( .A(n868), .B(intadd_2_SUM_6_), .Y(N48) );
  INVX1 U451 ( .A(N48), .Y(n251) );
  OR2X1 U452 ( .A(n868), .B(intadd_2_SUM_7_), .Y(N49) );
  INVX1 U453 ( .A(N49), .Y(n252) );
  OR2X1 U454 ( .A(n868), .B(intadd_2_SUM_8_), .Y(N50) );
  INVX1 U455 ( .A(N50), .Y(n253) );
  OR2X1 U456 ( .A(n868), .B(intadd_2_SUM_9_), .Y(N51) );
  INVX1 U457 ( .A(N51), .Y(n254) );
  OR2X1 U458 ( .A(n868), .B(intadd_2_SUM_10_), .Y(N52) );
  INVX1 U459 ( .A(N52), .Y(n255) );
  OR2X1 U460 ( .A(n859), .B(intadd_2_SUM_11_), .Y(N53) );
  INVX1 U461 ( .A(N53), .Y(n256) );
  OR2X1 U462 ( .A(n859), .B(intadd_2_SUM_12_), .Y(N54) );
  INVX1 U463 ( .A(N54), .Y(n257) );
  OR2X1 U464 ( .A(n859), .B(intadd_2_SUM_13_), .Y(N55) );
  INVX1 U465 ( .A(N55), .Y(n258) );
  OR2X1 U466 ( .A(n859), .B(intadd_2_SUM_14_), .Y(N56) );
  INVX1 U467 ( .A(N56), .Y(n259) );
  OR2X1 U468 ( .A(n859), .B(intadd_2_SUM_15_), .Y(N57) );
  INVX1 U469 ( .A(N57), .Y(n260) );
  OR2X1 U470 ( .A(n859), .B(intadd_2_SUM_16_), .Y(N58) );
  INVX1 U471 ( .A(N58), .Y(n261) );
  OR2X1 U472 ( .A(n859), .B(intadd_2_SUM_17_), .Y(N59) );
  INVX1 U473 ( .A(N59), .Y(n262) );
  OR2X1 U474 ( .A(n859), .B(intadd_2_SUM_18_), .Y(N60) );
  INVX1 U475 ( .A(N60), .Y(n263) );
  OR2X1 U476 ( .A(n859), .B(intadd_2_SUM_19_), .Y(N61) );
  INVX1 U477 ( .A(N61), .Y(n264) );
  OR2X1 U478 ( .A(n859), .B(intadd_2_n1), .Y(N62) );
  INVX1 U479 ( .A(N62), .Y(n265) );
  OR2X1 U480 ( .A(n868), .B(n867), .Y(n218) );
  INVX1 U481 ( .A(n218), .Y(n266) );
  AND2X1 U482 ( .A(n340), .B(n899), .Y(n210) );
  INVX1 U483 ( .A(n210), .Y(n267) );
  AND2X1 U484 ( .A(n343), .B(n907), .Y(n208) );
  INVX1 U485 ( .A(n208), .Y(n268) );
  AND2X1 U486 ( .A(n665), .B(n914), .Y(n206) );
  INVX1 U487 ( .A(n206), .Y(n269) );
  AND2X1 U488 ( .A(n664), .B(n921), .Y(n204) );
  INVX1 U489 ( .A(n204), .Y(n270) );
  AND2X1 U490 ( .A(n663), .B(n928), .Y(n202) );
  INVX1 U491 ( .A(n202), .Y(n271) );
  AND2X1 U492 ( .A(n346), .B(n935), .Y(n200) );
  INVX1 U493 ( .A(n200), .Y(n272) );
  AND2X1 U494 ( .A(n349), .B(n942), .Y(n198) );
  INVX1 U495 ( .A(n198), .Y(n273) );
  AND2X1 U496 ( .A(n352), .B(n949), .Y(n196) );
  INVX1 U497 ( .A(n196), .Y(n274) );
  AND2X1 U498 ( .A(n355), .B(n957), .Y(n194) );
  INVX1 U499 ( .A(n194), .Y(n275) );
  AND2X1 U500 ( .A(n662), .B(n964), .Y(n192) );
  INVX1 U501 ( .A(n192), .Y(n276) );
  AND2X1 U502 ( .A(n358), .B(n1044), .Y(n157) );
  INVX1 U503 ( .A(n157), .Y(n277) );
  AND2X1 U504 ( .A(n361), .B(n1052), .Y(n155) );
  INVX1 U505 ( .A(n155), .Y(n278) );
  AND2X1 U506 ( .A(n364), .B(n1060), .Y(n153) );
  INVX1 U507 ( .A(n153), .Y(n279) );
  AND2X1 U508 ( .A(n367), .B(n1068), .Y(n151) );
  INVX1 U509 ( .A(n151), .Y(n280) );
  AND2X1 U510 ( .A(n370), .B(n1076), .Y(n149) );
  INVX1 U511 ( .A(n149), .Y(n281) );
  INVX1 U560 ( .A(n320), .Y(n318) );
  INVX1 U561 ( .A(n318), .Y(n319) );
  BUFX2 U562 ( .A(n890), .Y(n320) );
  INVX1 U563 ( .A(n323), .Y(n321) );
  INVX1 U564 ( .A(n321), .Y(n322) );
  BUFX2 U565 ( .A(n968), .Y(n323) );
  INVX1 U566 ( .A(n326), .Y(n324) );
  INVX1 U567 ( .A(n324), .Y(n325) );
  BUFX2 U568 ( .A(n975), .Y(n326) );
  INVX1 U569 ( .A(n329), .Y(n327) );
  INVX1 U570 ( .A(n327), .Y(n328) );
  BUFX2 U571 ( .A(n1035), .Y(n329) );
  INVX1 U573 ( .A(n330), .Y(n331) );
  INVX1 U577 ( .A(n333), .Y(n334) );
  INVX1 U581 ( .A(n336), .Y(n337) );
  INVX1 U584 ( .A(n341), .Y(n339) );
  INVX1 U585 ( .A(n339), .Y(n340) );
  BUFX2 U586 ( .A(n900), .Y(n341) );
  INVX1 U587 ( .A(n344), .Y(n342) );
  INVX1 U588 ( .A(n342), .Y(n343) );
  BUFX2 U589 ( .A(n908), .Y(n344) );
  INVX1 U590 ( .A(n347), .Y(n345) );
  INVX1 U591 ( .A(n345), .Y(n346) );
  BUFX2 U592 ( .A(n936), .Y(n347) );
  INVX1 U593 ( .A(n350), .Y(n348) );
  INVX1 U594 ( .A(n348), .Y(n349) );
  BUFX2 U595 ( .A(n943), .Y(n350) );
  INVX1 U596 ( .A(n353), .Y(n351) );
  INVX1 U597 ( .A(n351), .Y(n352) );
  BUFX2 U598 ( .A(n950), .Y(n353) );
  INVX1 U599 ( .A(n356), .Y(n354) );
  INVX1 U600 ( .A(n354), .Y(n355) );
  BUFX2 U601 ( .A(n958), .Y(n356) );
  INVX1 U602 ( .A(n359), .Y(n357) );
  INVX1 U603 ( .A(n357), .Y(n358) );
  BUFX2 U604 ( .A(n1045), .Y(n359) );
  INVX1 U605 ( .A(n362), .Y(n360) );
  INVX1 U606 ( .A(n360), .Y(n361) );
  BUFX2 U607 ( .A(n1053), .Y(n362) );
  INVX1 U608 ( .A(n365), .Y(n363) );
  INVX1 U609 ( .A(n363), .Y(n364) );
  BUFX2 U610 ( .A(n1061), .Y(n365) );
  INVX1 U611 ( .A(n368), .Y(n366) );
  INVX1 U612 ( .A(n366), .Y(n367) );
  BUFX2 U613 ( .A(n1069), .Y(n368) );
  INVX1 U614 ( .A(n371), .Y(n369) );
  INVX1 U615 ( .A(n369), .Y(n370) );
  BUFX2 U616 ( .A(n1077), .Y(n371) );
  INVX1 U617 ( .A(n374), .Y(n372) );
  BUFX2 U619 ( .A(n1086), .Y(n374) );
  INVX1 U620 ( .A(n377), .Y(n375) );
  BUFX2 U622 ( .A(n1094), .Y(n377) );
  INVX1 U623 ( .A(n380), .Y(n378) );
  BUFX2 U625 ( .A(n1102), .Y(n380) );
  INVX1 U626 ( .A(n383), .Y(n381) );
  BUFX2 U628 ( .A(n1110), .Y(n383) );
  INVX1 U629 ( .A(n386), .Y(n384) );
  BUFX2 U631 ( .A(n1118), .Y(n386) );
  INVX1 U632 ( .A(n389), .Y(n387) );
  BUFX2 U634 ( .A(n1126), .Y(n389) );
  INVX1 U635 ( .A(n392), .Y(n390) );
  BUFX2 U637 ( .A(n1134), .Y(n392) );
  INVX1 U638 ( .A(n395), .Y(n393) );
  BUFX2 U640 ( .A(n1142), .Y(n395) );
  INVX1 U641 ( .A(n398), .Y(n396) );
  BUFX2 U643 ( .A(n1150), .Y(n398) );
  INVX1 U644 ( .A(n401), .Y(n399) );
  BUFX2 U646 ( .A(n1158), .Y(n401) );
  INVX1 U647 ( .A(n404), .Y(n402) );
  BUFX2 U649 ( .A(n1168), .Y(n404) );
  INVX1 U650 ( .A(n407), .Y(n405) );
  BUFX2 U652 ( .A(n1180), .Y(n407) );
  INVX1 U658 ( .A(n411), .Y(n412) );
  INVX1 U662 ( .A(n414), .Y(n415) );
  INVX1 U666 ( .A(n417), .Y(n418) );
  INVX1 U670 ( .A(n420), .Y(n421) );
  INVX1 U674 ( .A(n423), .Y(n424) );
  INVX1 U678 ( .A(n426), .Y(n427) );
  INVX1 U682 ( .A(n429), .Y(n430) );
  INVX1 U686 ( .A(n432), .Y(n433) );
  INVX1 U689 ( .A(n437), .Y(n435) );
  INVX1 U690 ( .A(n435), .Y(n436) );
  BUFX2 U691 ( .A(g_tree_sx_1__0_), .Y(n437) );
  INVX1 U692 ( .A(n440), .Y(n438) );
  INVX1 U693 ( .A(n438), .Y(n439) );
  BUFX2 U694 ( .A(g_tree_ss_1__0_), .Y(n440) );
  INVX1 U696 ( .A(n441), .Y(n442) );
  INVX1 U699 ( .A(n446), .Y(n444) );
  INVX1 U700 ( .A(n444), .Y(n445) );
  BUFX2 U701 ( .A(n883), .Y(n446) );
  INVX1 U702 ( .A(n449), .Y(n447) );
  INVX1 U703 ( .A(n447), .Y(n448) );
  BUFX2 U704 ( .A(n973), .Y(n449) );
  INVX1 U705 ( .A(n452), .Y(n450) );
  INVX1 U706 ( .A(n450), .Y(n451) );
  BUFX2 U707 ( .A(n1026), .Y(n452) );
  INVX1 U708 ( .A(n455), .Y(n453) );
  INVX1 U709 ( .A(n453), .Y(n454) );
  BUFX2 U710 ( .A(n983), .Y(n455) );
  INVX1 U711 ( .A(n458), .Y(n456) );
  INVX1 U712 ( .A(n456), .Y(n457) );
  BUFX2 U713 ( .A(g_tree_sx_2__0_), .Y(n458) );
  INVX1 U714 ( .A(n461), .Y(n459) );
  INVX1 U715 ( .A(n459), .Y(n460) );
  BUFX2 U716 ( .A(g_tree_ss_2__0_), .Y(n461) );
  OR2X1 U717 ( .A(n732), .B(n624), .Y(n872) );
  AND2X1 U718 ( .A(n626), .B(trial_count[0]), .Y(n874) );
  AND2X1 U719 ( .A(trial_count[6]), .B(n479), .Y(n895) );
  AND2X1 U720 ( .A(n895), .B(trial_count[7]), .Y(n901) );
  AND2X1 U721 ( .A(trial_count[8]), .B(n901), .Y(n903) );
  AND2X1 U722 ( .A(n903), .B(trial_count[9]), .Y(n909) );
  AND2X1 U723 ( .A(trial_count[10]), .B(n909), .Y(n911) );
  AND2X1 U724 ( .A(n911), .B(trial_count[11]), .Y(n916) );
  AND2X1 U725 ( .A(trial_count[24]), .B(n959), .Y(n961) );
  AND2X1 U726 ( .A(n961), .B(trial_count[25]), .Y(n966) );
  AND2X1 U727 ( .A(payoff_sum[27]), .B(n478), .Y(n1038) );
  AND2X1 U728 ( .A(n1038), .B(payoff_sum[28]), .Y(n1040) );
  AND2X1 U729 ( .A(payoff_sum[29]), .B(n1040), .Y(n1046) );
  AND2X1 U730 ( .A(n1046), .B(payoff_sum[30]), .Y(n1048) );
  AND2X1 U731 ( .A(payoff_sum[31]), .B(n1048), .Y(n1054) );
  AND2X1 U732 ( .A(n1054), .B(payoff_sum[32]), .Y(n1056) );
  AND2X1 U733 ( .A(payoff_sum[33]), .B(n1056), .Y(n1062) );
  AND2X1 U734 ( .A(n1062), .B(payoff_sum[34]), .Y(n1064) );
  AND2X1 U735 ( .A(payoff_sum[35]), .B(n1064), .Y(n1070) );
  AND2X1 U736 ( .A(n1070), .B(payoff_sum[36]), .Y(n1072) );
  AND2X1 U737 ( .A(payoff_sum[37]), .B(n1072), .Y(n1079) );
  AND2X1 U738 ( .A(n1079), .B(payoff_sum[38]), .Y(n1081) );
  AND2X1 U739 ( .A(payoff_sum[39]), .B(n1081), .Y(n1087) );
  AND2X1 U740 ( .A(n1087), .B(payoff_sum[40]), .Y(n1089) );
  AND2X1 U741 ( .A(payoff_sum[41]), .B(n1089), .Y(n1095) );
  AND2X1 U742 ( .A(n1095), .B(payoff_sum[42]), .Y(n1097) );
  AND2X1 U743 ( .A(payoff_sum[43]), .B(n1097), .Y(n1103) );
  AND2X1 U744 ( .A(n1103), .B(payoff_sum[44]), .Y(n1105) );
  AND2X1 U745 ( .A(payoff_sum[45]), .B(n1105), .Y(n1111) );
  AND2X1 U746 ( .A(n1111), .B(payoff_sum[46]), .Y(n1113) );
  AND2X1 U747 ( .A(payoff_sum[47]), .B(n1113), .Y(n1119) );
  AND2X1 U748 ( .A(n1119), .B(payoff_sum[48]), .Y(n1121) );
  AND2X1 U749 ( .A(payoff_sum[49]), .B(n1121), .Y(n1127) );
  AND2X1 U750 ( .A(n1127), .B(payoff_sum[50]), .Y(n1129) );
  AND2X1 U751 ( .A(payoff_sum[51]), .B(n1129), .Y(n1135) );
  AND2X1 U752 ( .A(n1135), .B(payoff_sum[52]), .Y(n1137) );
  AND2X1 U753 ( .A(payoff_sum[53]), .B(n1137), .Y(n1143) );
  AND2X1 U754 ( .A(n1143), .B(payoff_sum[54]), .Y(n1145) );
  AND2X1 U755 ( .A(payoff_sum[55]), .B(n1145), .Y(n1151) );
  AND2X1 U756 ( .A(n1151), .B(payoff_sum[56]), .Y(n1153) );
  AND2X1 U757 ( .A(payoff_sum[57]), .B(n1153), .Y(n1160) );
  AND2X1 U758 ( .A(n1160), .B(payoff_sum[58]), .Y(n1163) );
  AND2X1 U759 ( .A(payoff_sum[59]), .B(n1163), .Y(n1172) );
  AND2X1 U760 ( .A(n1172), .B(payoff_sum[60]), .Y(n1175) );
  AND2X1 U761 ( .A(payoff_sum[61]), .B(n1175), .Y(n1183) );
  AND2X1 U762 ( .A(n473), .B(n671), .Y(n811) );
  OR2X1 U763 ( .A(n481), .B(n482), .Y(n829) );
  INVX1 U764 ( .A(n807), .Y(n1199) );
  AND2X1 U765 ( .A(payoff_sum[0]), .B(n474), .Y(n988) );
  BUFX2 U766 ( .A(n891), .Y(n462) );
  BUFX2 U767 ( .A(n1036), .Y(n463) );
  AND2X1 U768 ( .A(n1027), .B(n888), .Y(n886) );
  INVX1 U769 ( .A(n886), .Y(n464) );
  AND2X1 U770 ( .A(n1027), .B(n1032), .Y(n1029) );
  INVX1 U771 ( .A(n1029), .Y(n465) );
  BUFX2 U772 ( .A(n882), .Y(n466) );
  BUFX2 U773 ( .A(n972), .Y(n467) );
  BUFX2 U774 ( .A(n1025), .Y(n468) );
  AND2X1 U775 ( .A(n1027), .B(n884), .Y(n878) );
  INVX1 U776 ( .A(n878), .Y(n469) );
  AND2X1 U777 ( .A(n1027), .B(intadd_0_n1), .Y(n1020) );
  INVX1 U778 ( .A(n1020), .Y(n470) );
  OR2X1 U779 ( .A(n473), .B(n671), .Y(n810) );
  INVX1 U780 ( .A(n810), .Y(n471) );
  OR2X1 U781 ( .A(n477), .B(n670), .Y(n812) );
  INVX1 U782 ( .A(n812), .Y(n472) );
  BUFX2 U783 ( .A(g_tree_g_level_1__g_node_0__count_q[0]), .Y(n473) );
  BUFX2 U784 ( .A(g_tree_g_level_2__g_node_0__sum_q[0]), .Y(n474) );
  BUFX2 U785 ( .A(g_tree_g_level_2__g_node_0__sum_q[1]), .Y(n475) );
  AND2X1 U786 ( .A(n477), .B(n670), .Y(n813) );
  INVX1 U787 ( .A(n813), .Y(n476) );
  BUFX2 U788 ( .A(g_tree_g_level_1__g_node_1__sum_q[0]), .Y(n477) );
  OR2X1 U789 ( .A(n619), .B(n1032), .Y(n1034) );
  INVX1 U790 ( .A(n1034), .Y(n478) );
  OR2X1 U791 ( .A(n621), .B(n888), .Y(n893) );
  INVX1 U792 ( .A(n893), .Y(n479) );
  AND2X1 U793 ( .A(n985), .B(n623), .Y(n976) );
  INVX1 U794 ( .A(n976), .Y(n480) );
  AND2X1 U795 ( .A(n836), .B(p[66]), .Y(n827) );
  INVX1 U796 ( .A(n827), .Y(n481) );
  AND2X1 U797 ( .A(n837), .B(p[44]), .Y(n828) );
  INVX1 U798 ( .A(n828), .Y(n482) );
  AND2X1 U799 ( .A(n858), .B(p[0]), .Y(n849) );
  INVX1 U800 ( .A(n849), .Y(n483) );
  AND2X1 U801 ( .A(n857), .B(p[22]), .Y(n848) );
  INVX1 U802 ( .A(n848), .Y(n484) );
  BUFX2 U803 ( .A(intadd_0_CI), .Y(n485) );
  BUFX2 U804 ( .A(n877), .Y(n486) );
  AND2X1 U807 ( .A(n836), .B(p[68]), .Y(intadd_3_CI) );
  INVX1 U808 ( .A(intadd_3_CI), .Y(n488) );
  AND2X1 U809 ( .A(n857), .B(p[24]), .Y(intadd_2_CI) );
  INVX1 U810 ( .A(intadd_2_CI), .Y(n489) );
  BUFX2 U811 ( .A(intadd_3_A_0_), .Y(n490) );
  BUFX2 U812 ( .A(intadd_2_A_0_), .Y(n491) );
  OR2X1 U813 ( .A(trial_count[7]), .B(n1169), .Y(n898) );
  INVX1 U814 ( .A(n898), .Y(n492) );
  OR2X1 U815 ( .A(trial_count[9]), .B(n1169), .Y(n906) );
  INVX1 U816 ( .A(n906), .Y(n493) );
  OR2X1 U817 ( .A(trial_count[11]), .B(n1182), .Y(n913) );
  INVX1 U818 ( .A(n913), .Y(n494) );
  OR2X1 U819 ( .A(trial_count[13]), .B(n1182), .Y(n920) );
  INVX1 U820 ( .A(n920), .Y(n495) );
  OR2X1 U821 ( .A(trial_count[15]), .B(n1159), .Y(n927) );
  INVX1 U822 ( .A(n927), .Y(n496) );
  OR2X1 U823 ( .A(trial_count[17]), .B(n1159), .Y(n934) );
  INVX1 U824 ( .A(n934), .Y(n497) );
  OR2X1 U825 ( .A(trial_count[19]), .B(n1159), .Y(n941) );
  INVX1 U826 ( .A(n941), .Y(n498) );
  OR2X1 U827 ( .A(trial_count[21]), .B(n1159), .Y(n948) );
  INVX1 U828 ( .A(n948), .Y(n499) );
  OR2X1 U829 ( .A(trial_count[23]), .B(n1159), .Y(n956) );
  INVX1 U830 ( .A(n956), .Y(n500) );
  OR2X1 U831 ( .A(trial_count[25]), .B(n1159), .Y(n963) );
  INVX1 U832 ( .A(n963), .Y(n501) );
  OR2X1 U833 ( .A(payoff_sum[28]), .B(n1159), .Y(n1043) );
  INVX1 U834 ( .A(n1043), .Y(n502) );
  OR2X1 U835 ( .A(payoff_sum[30]), .B(n1159), .Y(n1051) );
  INVX1 U836 ( .A(n1051), .Y(n503) );
  OR2X1 U837 ( .A(payoff_sum[32]), .B(n1159), .Y(n1059) );
  INVX1 U838 ( .A(n1059), .Y(n504) );
  OR2X1 U839 ( .A(payoff_sum[34]), .B(n1159), .Y(n1067) );
  INVX1 U840 ( .A(n1067), .Y(n505) );
  OR2X1 U841 ( .A(payoff_sum[36]), .B(n1159), .Y(n1075) );
  INVX1 U842 ( .A(n1075), .Y(n506) );
  OR2X1 U843 ( .A(payoff_sum[38]), .B(n1159), .Y(n1084) );
  INVX1 U844 ( .A(n1084), .Y(n507) );
  OR2X1 U845 ( .A(payoff_sum[40]), .B(n1159), .Y(n1092) );
  INVX1 U846 ( .A(n1092), .Y(n508) );
  OR2X1 U847 ( .A(payoff_sum[42]), .B(n1182), .Y(n1100) );
  INVX1 U848 ( .A(n1100), .Y(n509) );
  OR2X1 U849 ( .A(payoff_sum[44]), .B(n1182), .Y(n1108) );
  INVX1 U850 ( .A(n1108), .Y(n510) );
  OR2X1 U851 ( .A(payoff_sum[46]), .B(n1182), .Y(n1116) );
  INVX1 U852 ( .A(n1116), .Y(n511) );
  OR2X1 U853 ( .A(payoff_sum[48]), .B(n1182), .Y(n1124) );
  INVX1 U854 ( .A(n1124), .Y(n512) );
  OR2X1 U855 ( .A(payoff_sum[50]), .B(n1182), .Y(n1132) );
  INVX1 U856 ( .A(n1132), .Y(n513) );
  OR2X1 U857 ( .A(payoff_sum[52]), .B(n1182), .Y(n1140) );
  INVX1 U858 ( .A(n1140), .Y(n514) );
  OR2X1 U859 ( .A(payoff_sum[54]), .B(n1159), .Y(n1148) );
  INVX1 U860 ( .A(n1148), .Y(n515) );
  OR2X1 U861 ( .A(payoff_sum[56]), .B(n1159), .Y(n1156) );
  INVX1 U862 ( .A(n1156), .Y(n516) );
  OR2X1 U863 ( .A(payoff_sum[58]), .B(n1159), .Y(n1166) );
  INVX1 U864 ( .A(n1166), .Y(n517) );
  OR2X1 U865 ( .A(payoff_sum[60]), .B(n1169), .Y(n1178) );
  INVX1 U866 ( .A(n1178), .Y(n518) );
  AND2X1 U867 ( .A(n991), .B(n990), .Y(n994) );
  INVX1 U868 ( .A(n994), .Y(n519) );
  BUFX2 U869 ( .A(n1188), .Y(n520) );
  OR2X1 U870 ( .A(payoff_sum[62]), .B(n1182), .Y(n1186) );
  INVX1 U871 ( .A(n1186), .Y(n521) );
  BUFX2 U872 ( .A(g_tree_g_level_1__g_node_0__count_q[1]), .Y(n522) );
  BUFX2 U873 ( .A(g_tree_g_level_1__g_node_0__sum_q[2]), .Y(n523) );
  BUFX2 U874 ( .A(g_tree_g_level_1__g_node_0__sum_q[3]), .Y(n524) );
  BUFX2 U875 ( .A(g_tree_g_level_1__g_node_0__sum_q[4]), .Y(n525) );
  BUFX2 U876 ( .A(g_tree_g_level_1__g_node_0__sum_q[5]), .Y(n526) );
  BUFX2 U877 ( .A(g_tree_g_level_1__g_node_0__sum_q[6]), .Y(n527) );
  BUFX2 U878 ( .A(g_tree_g_level_1__g_node_0__sum_q[7]), .Y(n528) );
  BUFX2 U879 ( .A(g_tree_g_level_1__g_node_0__sum_q[8]), .Y(n529) );
  BUFX2 U880 ( .A(g_tree_g_level_1__g_node_0__sum_q[9]), .Y(n530) );
  BUFX2 U881 ( .A(g_tree_g_level_1__g_node_0__sum_q[10]), .Y(n531) );
  BUFX2 U882 ( .A(g_tree_g_level_1__g_node_0__sum_q[11]), .Y(n532) );
  BUFX2 U883 ( .A(g_tree_g_level_1__g_node_0__sum_q[12]), .Y(n533) );
  BUFX2 U884 ( .A(g_tree_g_level_1__g_node_0__sum_q[13]), .Y(n534) );
  BUFX2 U885 ( .A(g_tree_g_level_1__g_node_0__sum_q[14]), .Y(n535) );
  BUFX2 U886 ( .A(g_tree_g_level_1__g_node_0__sum_q[15]), .Y(n536) );
  BUFX2 U887 ( .A(g_tree_g_level_1__g_node_0__sum_q[16]), .Y(n537) );
  BUFX2 U888 ( .A(g_tree_g_level_1__g_node_0__sum_q[17]), .Y(n538) );
  BUFX2 U889 ( .A(g_tree_g_level_1__g_node_0__sum_q[18]), .Y(n539) );
  BUFX2 U890 ( .A(g_tree_g_level_1__g_node_0__sum_q[19]), .Y(n540) );
  BUFX2 U891 ( .A(g_tree_g_level_1__g_node_0__sum_q[20]), .Y(n541) );
  BUFX2 U892 ( .A(g_tree_g_level_1__g_node_0__sum_q[21]), .Y(n542) );
  BUFX2 U893 ( .A(g_tree_g_level_1__g_node_0__sum_q[22]), .Y(n543) );
  AND2X1 U894 ( .A(n837), .B(p[47]), .Y(intadd_3_A_1_) );
  INVX1 U895 ( .A(intadd_3_A_1_), .Y(n544) );
  AND2X1 U896 ( .A(n837), .B(p[48]), .Y(intadd_3_A_2_) );
  INVX1 U897 ( .A(intadd_3_A_2_), .Y(n545) );
  AND2X1 U898 ( .A(n837), .B(p[49]), .Y(intadd_3_A_3_) );
  INVX1 U899 ( .A(intadd_3_A_3_), .Y(n546) );
  AND2X1 U900 ( .A(n837), .B(p[50]), .Y(intadd_3_A_4_) );
  INVX1 U901 ( .A(intadd_3_A_4_), .Y(n547) );
  AND2X1 U902 ( .A(n837), .B(p[51]), .Y(intadd_3_A_5_) );
  INVX1 U903 ( .A(intadd_3_A_5_), .Y(n548) );
  AND2X1 U904 ( .A(n837), .B(p[52]), .Y(intadd_3_A_6_) );
  INVX1 U905 ( .A(intadd_3_A_6_), .Y(n549) );
  AND2X1 U906 ( .A(n837), .B(p[53]), .Y(intadd_3_A_7_) );
  INVX1 U907 ( .A(intadd_3_A_7_), .Y(n550) );
  AND2X1 U908 ( .A(n837), .B(p[54]), .Y(intadd_3_A_8_) );
  INVX1 U909 ( .A(intadd_3_A_8_), .Y(n551) );
  AND2X1 U910 ( .A(p_valid[2]), .B(p[55]), .Y(intadd_3_A_9_) );
  INVX1 U911 ( .A(intadd_3_A_9_), .Y(n552) );
  AND2X1 U912 ( .A(p_valid[2]), .B(p[56]), .Y(intadd_3_A_10_) );
  INVX1 U913 ( .A(intadd_3_A_10_), .Y(n553) );
  AND2X1 U914 ( .A(p_valid[2]), .B(p[57]), .Y(intadd_3_A_11_) );
  INVX1 U915 ( .A(intadd_3_A_11_), .Y(n554) );
  AND2X1 U916 ( .A(p_valid[2]), .B(p[58]), .Y(intadd_3_A_12_) );
  INVX1 U917 ( .A(intadd_3_A_12_), .Y(n555) );
  AND2X1 U918 ( .A(p_valid[2]), .B(p[59]), .Y(intadd_3_A_13_) );
  INVX1 U919 ( .A(intadd_3_A_13_), .Y(n556) );
  AND2X1 U920 ( .A(p_valid[2]), .B(p[60]), .Y(intadd_3_A_14_) );
  INVX1 U921 ( .A(intadd_3_A_14_), .Y(n557) );
  AND2X1 U922 ( .A(p_valid[2]), .B(p[61]), .Y(intadd_3_A_15_) );
  INVX1 U923 ( .A(intadd_3_A_15_), .Y(n558) );
  AND2X1 U924 ( .A(p_valid[2]), .B(p[62]), .Y(intadd_3_A_16_) );
  INVX1 U925 ( .A(intadd_3_A_16_), .Y(n559) );
  AND2X1 U926 ( .A(p_valid[2]), .B(p[63]), .Y(intadd_3_A_17_) );
  INVX1 U927 ( .A(intadd_3_A_17_), .Y(n560) );
  AND2X1 U928 ( .A(p_valid[2]), .B(p[64]), .Y(intadd_3_A_18_) );
  INVX1 U929 ( .A(intadd_3_A_18_), .Y(n561) );
  AND2X1 U930 ( .A(p_valid[2]), .B(p[65]), .Y(intadd_3_A_19_) );
  INVX1 U931 ( .A(intadd_3_A_19_), .Y(n562) );
  AND2X1 U932 ( .A(n858), .B(p[3]), .Y(intadd_2_A_1_) );
  INVX1 U933 ( .A(intadd_2_A_1_), .Y(n563) );
  AND2X1 U934 ( .A(n858), .B(p[4]), .Y(intadd_2_A_2_) );
  INVX1 U935 ( .A(intadd_2_A_2_), .Y(n564) );
  AND2X1 U936 ( .A(n858), .B(p[5]), .Y(intadd_2_A_3_) );
  INVX1 U937 ( .A(intadd_2_A_3_), .Y(n565) );
  AND2X1 U938 ( .A(n858), .B(p[6]), .Y(intadd_2_A_4_) );
  INVX1 U939 ( .A(intadd_2_A_4_), .Y(n566) );
  AND2X1 U940 ( .A(n858), .B(p[7]), .Y(intadd_2_A_5_) );
  INVX1 U941 ( .A(intadd_2_A_5_), .Y(n567) );
  AND2X1 U942 ( .A(n858), .B(p[8]), .Y(intadd_2_A_6_) );
  INVX1 U943 ( .A(intadd_2_A_6_), .Y(n568) );
  AND2X1 U944 ( .A(n858), .B(p[9]), .Y(intadd_2_A_7_) );
  INVX1 U945 ( .A(intadd_2_A_7_), .Y(n569) );
  AND2X1 U946 ( .A(n858), .B(p[10]), .Y(intadd_2_A_8_) );
  INVX1 U947 ( .A(intadd_2_A_8_), .Y(n570) );
  AND2X1 U948 ( .A(p_valid[0]), .B(p[11]), .Y(intadd_2_A_9_) );
  INVX1 U949 ( .A(intadd_2_A_9_), .Y(n571) );
  AND2X1 U950 ( .A(p_valid[0]), .B(p[12]), .Y(intadd_2_A_10_) );
  INVX1 U951 ( .A(intadd_2_A_10_), .Y(n572) );
  AND2X1 U952 ( .A(p_valid[0]), .B(p[13]), .Y(intadd_2_A_11_) );
  INVX1 U953 ( .A(intadd_2_A_11_), .Y(n573) );
  AND2X1 U954 ( .A(p_valid[0]), .B(p[14]), .Y(intadd_2_A_12_) );
  INVX1 U955 ( .A(intadd_2_A_12_), .Y(n574) );
  AND2X1 U956 ( .A(p_valid[0]), .B(p[15]), .Y(intadd_2_A_13_) );
  INVX1 U957 ( .A(intadd_2_A_13_), .Y(n575) );
  AND2X1 U958 ( .A(p_valid[0]), .B(p[16]), .Y(intadd_2_A_14_) );
  INVX1 U959 ( .A(intadd_2_A_14_), .Y(n576) );
  AND2X1 U960 ( .A(p_valid[0]), .B(p[17]), .Y(intadd_2_A_15_) );
  INVX1 U961 ( .A(intadd_2_A_15_), .Y(n577) );
  AND2X1 U962 ( .A(p_valid[0]), .B(p[18]), .Y(intadd_2_A_16_) );
  INVX1 U963 ( .A(intadd_2_A_16_), .Y(n578) );
  AND2X1 U964 ( .A(p_valid[0]), .B(p[19]), .Y(intadd_2_A_17_) );
  INVX1 U965 ( .A(intadd_2_A_17_), .Y(n579) );
  AND2X1 U966 ( .A(p_valid[0]), .B(p[20]), .Y(intadd_2_A_18_) );
  INVX1 U967 ( .A(intadd_2_A_18_), .Y(n580) );
  AND2X1 U968 ( .A(p_valid[0]), .B(p[21]), .Y(intadd_2_A_19_) );
  INVX1 U969 ( .A(intadd_2_A_19_), .Y(n581) );
  INVX1 U970 ( .A(n807), .Y(n582) );
  INVX1 U971 ( .A(n807), .Y(n583) );
  BUFX2 U972 ( .A(g_tree_g_level_2__g_node_0__sum_q[2]), .Y(n584) );
  BUFX2 U973 ( .A(g_tree_g_level_2__g_node_0__sum_q[3]), .Y(n585) );
  BUFX2 U974 ( .A(g_tree_g_level_2__g_node_0__sum_q[4]), .Y(n586) );
  BUFX2 U975 ( .A(g_tree_g_level_2__g_node_0__sum_q[5]), .Y(n587) );
  BUFX2 U976 ( .A(g_tree_g_level_2__g_node_0__sum_q[6]), .Y(n588) );
  BUFX2 U977 ( .A(g_tree_g_level_2__g_node_0__sum_q[7]), .Y(n589) );
  BUFX2 U978 ( .A(g_tree_g_level_2__g_node_0__sum_q[8]), .Y(n590) );
  BUFX2 U979 ( .A(g_tree_g_level_2__g_node_0__sum_q[9]), .Y(n591) );
  BUFX2 U980 ( .A(g_tree_g_level_2__g_node_0__sum_q[10]), .Y(n592) );
  BUFX2 U981 ( .A(g_tree_g_level_2__g_node_0__sum_q[11]), .Y(n593) );
  BUFX2 U982 ( .A(g_tree_g_level_2__g_node_0__sum_q[12]), .Y(n594) );
  BUFX2 U983 ( .A(g_tree_g_level_2__g_node_0__sum_q[13]), .Y(n595) );
  BUFX2 U984 ( .A(g_tree_g_level_2__g_node_0__sum_q[14]), .Y(n596) );
  BUFX2 U985 ( .A(g_tree_g_level_2__g_node_0__sum_q[15]), .Y(n597) );
  BUFX2 U986 ( .A(g_tree_g_level_2__g_node_0__sum_q[16]), .Y(n598) );
  BUFX2 U987 ( .A(g_tree_g_level_2__g_node_0__sum_q[17]), .Y(n599) );
  BUFX2 U988 ( .A(g_tree_g_level_2__g_node_0__sum_q[18]), .Y(n600) );
  BUFX2 U989 ( .A(g_tree_g_level_2__g_node_0__sum_q[19]), .Y(n601) );
  BUFX2 U990 ( .A(g_tree_g_level_2__g_node_0__sum_q[20]), .Y(n602) );
  BUFX2 U991 ( .A(g_tree_g_level_2__g_node_0__sum_q[21]), .Y(n603) );
  BUFX2 U992 ( .A(g_tree_g_level_2__g_node_0__sum_q[22]), .Y(n604) );
  BUFX2 U993 ( .A(g_tree_g_level_2__g_node_0__sum_q[23]), .Y(n605) );
  INVX1 U994 ( .A(intadd_3_B_2_), .Y(n606) );
  AND2X1 U995 ( .A(n836), .B(p[70]), .Y(intadd_3_B_2_) );
  INVX1 U996 ( .A(intadd_3_B_3_), .Y(n607) );
  AND2X1 U997 ( .A(n836), .B(p[71]), .Y(intadd_3_B_3_) );
  INVX1 U998 ( .A(intadd_3_B_4_), .Y(n608) );
  AND2X1 U999 ( .A(n836), .B(p[72]), .Y(intadd_3_B_4_) );
  INVX1 U1000 ( .A(intadd_3_B_5_), .Y(n609) );
  AND2X1 U1001 ( .A(n836), .B(p[73]), .Y(intadd_3_B_5_) );
  INVX1 U1002 ( .A(intadd_3_B_6_), .Y(n610) );
  AND2X1 U1003 ( .A(n836), .B(p[74]), .Y(intadd_3_B_6_) );
  INVX1 U1004 ( .A(intadd_3_B_7_), .Y(n611) );
  AND2X1 U1005 ( .A(n836), .B(p[75]), .Y(intadd_3_B_7_) );
  INVX1 U1006 ( .A(intadd_2_B_2_), .Y(n612) );
  AND2X1 U1007 ( .A(n857), .B(p[26]), .Y(intadd_2_B_2_) );
  INVX1 U1008 ( .A(intadd_2_B_3_), .Y(n613) );
  AND2X1 U1009 ( .A(n857), .B(p[27]), .Y(intadd_2_B_3_) );
  INVX1 U1010 ( .A(intadd_2_B_4_), .Y(n614) );
  AND2X1 U1011 ( .A(n857), .B(p[28]), .Y(intadd_2_B_4_) );
  INVX1 U1012 ( .A(intadd_2_B_5_), .Y(n615) );
  AND2X1 U1013 ( .A(n857), .B(p[29]), .Y(intadd_2_B_5_) );
  INVX1 U1014 ( .A(intadd_2_B_6_), .Y(n616) );
  AND2X1 U1015 ( .A(n857), .B(p[30]), .Y(intadd_2_B_6_) );
  INVX1 U1016 ( .A(intadd_2_B_7_), .Y(n617) );
  AND2X1 U1017 ( .A(n857), .B(p[31]), .Y(intadd_2_B_7_) );
  INVX1 U1018 ( .A(n619), .Y(n618) );
  BUFX2 U1019 ( .A(n1030), .Y(n619) );
  INVX1 U1020 ( .A(n621), .Y(n620) );
  BUFX2 U1021 ( .A(n889), .Y(n621) );
  INVX1 U1022 ( .A(n623), .Y(n622) );
  BUFX2 U1023 ( .A(n977), .Y(n623) );
  INVX1 U1024 ( .A(n625), .Y(n624) );
  BUFX2 U1025 ( .A(g_tree_g_level_2__g_node_0__count_q[1]), .Y(n625) );
  BUFX2 U1026 ( .A(g_tree_g_level_2__g_node_0__count_q[0]), .Y(n626) );
  BUFX2 U1027 ( .A(g_tree_g_level_1__g_node_1__sum_q[1]), .Y(n627) );
  BUFX2 U1028 ( .A(g_tree_g_level_2__g_node_0__count_q[2]), .Y(n628) );
  INVX1 U1029 ( .A(n988), .Y(n629) );
  BUFX2 U1030 ( .A(n1264), .Y(trial_count[31]) );
  BUFX2 U1031 ( .A(n1295), .Y(trial_count[0]) );
  INVX1 U1032 ( .A(trial_count[12]), .Y(n632) );
  BUFX2 U1033 ( .A(n1283), .Y(trial_count[12]) );
  INVX1 U1034 ( .A(trial_count[14]), .Y(n634) );
  BUFX2 U1035 ( .A(n1281), .Y(trial_count[14]) );
  INVX1 U1036 ( .A(trial_count[16]), .Y(n636) );
  BUFX2 U1037 ( .A(n1279), .Y(trial_count[16]) );
  INVX1 U1038 ( .A(trial_count[18]), .Y(n638) );
  BUFX2 U1039 ( .A(n1277), .Y(trial_count[18]) );
  INVX1 U1040 ( .A(trial_count[20]), .Y(n640) );
  BUFX2 U1041 ( .A(n1275), .Y(trial_count[20]) );
  INVX1 U1042 ( .A(trial_count[22]), .Y(n642) );
  BUFX2 U1043 ( .A(n1273), .Y(trial_count[22]) );
  INVX1 U1044 ( .A(trial_count[26]), .Y(n644) );
  BUFX2 U1045 ( .A(n1269), .Y(trial_count[26]) );
  INVX1 U1046 ( .A(trial_count[4]), .Y(n646) );
  BUFX2 U1047 ( .A(n1291), .Y(trial_count[4]) );
  INVX1 U1048 ( .A(trial_count[28]), .Y(n648) );
  BUFX2 U1049 ( .A(n1267), .Y(trial_count[28]) );
  INVX1 U1050 ( .A(payoff_sum[25]), .Y(n650) );
  BUFX2 U1051 ( .A(n1238), .Y(payoff_sum[25]) );
  BUFX2 U1052 ( .A(n1282), .Y(trial_count[13]) );
  BUFX2 U1053 ( .A(n1280), .Y(trial_count[15]) );
  BUFX2 U1054 ( .A(n1278), .Y(trial_count[17]) );
  BUFX2 U1055 ( .A(n1276), .Y(trial_count[19]) );
  BUFX2 U1056 ( .A(n1274), .Y(trial_count[21]) );
  BUFX2 U1057 ( .A(n1272), .Y(trial_count[23]) );
  BUFX2 U1058 ( .A(n846), .Y(n658) );
  OR2X1 U1059 ( .A(n868), .B(intadd_2_SUM_2_), .Y(N44) );
  INVX1 U1060 ( .A(N44), .Y(n659) );
  BUFX2 U1061 ( .A(N65), .Y(n660) );
  BUFX2 U1062 ( .A(N95), .Y(n661) );
  BUFX2 U1063 ( .A(n965), .Y(n662) );
  BUFX2 U1064 ( .A(n929), .Y(n663) );
  BUFX2 U1065 ( .A(n922), .Y(n664) );
  BUFX2 U1066 ( .A(n915), .Y(n665) );
  AND2X1 U1067 ( .A(n829), .B(n992), .Y(n826) );
  INVX1 U1068 ( .A(n826), .Y(n666) );
  AND2X1 U1069 ( .A(p_valid[0]), .B(sat_s[0]), .Y(n841) );
  INVX1 U1070 ( .A(n841), .Y(n667) );
  BUFX2 U1071 ( .A(g_tree_ss_1__1_), .Y(n668) );
  BUFX2 U1072 ( .A(g_tree_sx_1__1_), .Y(n669) );
  BUFX2 U1073 ( .A(g_tree_g_level_1__g_node_0__sum_q[0]), .Y(n670) );
  BUFX2 U1074 ( .A(g_tree_g_level_1__g_node_1__count_q[0]), .Y(n671) );
  AND2X1 U1075 ( .A(p_valid[1]), .B(p[43]), .Y(intadd_2_B_19_) );
  INVX1 U1076 ( .A(intadd_2_B_19_), .Y(n672) );
  AND2X1 U1077 ( .A(p_valid[1]), .B(p[42]), .Y(intadd_2_B_18_) );
  INVX1 U1078 ( .A(intadd_2_B_18_), .Y(n673) );
  AND2X1 U1079 ( .A(p_valid[1]), .B(p[41]), .Y(intadd_2_B_17_) );
  INVX1 U1080 ( .A(intadd_2_B_17_), .Y(n674) );
  AND2X1 U1081 ( .A(p_valid[1]), .B(p[40]), .Y(intadd_2_B_16_) );
  INVX1 U1082 ( .A(intadd_2_B_16_), .Y(n675) );
  AND2X1 U1083 ( .A(p_valid[1]), .B(p[39]), .Y(intadd_2_B_15_) );
  INVX1 U1084 ( .A(intadd_2_B_15_), .Y(n676) );
  AND2X1 U1085 ( .A(p_valid[1]), .B(p[38]), .Y(intadd_2_B_14_) );
  INVX1 U1086 ( .A(intadd_2_B_14_), .Y(n677) );
  AND2X1 U1087 ( .A(p_valid[1]), .B(p[37]), .Y(intadd_2_B_13_) );
  INVX1 U1088 ( .A(intadd_2_B_13_), .Y(n678) );
  AND2X1 U1089 ( .A(p_valid[1]), .B(p[36]), .Y(intadd_2_B_12_) );
  INVX1 U1090 ( .A(intadd_2_B_12_), .Y(n679) );
  AND2X1 U1091 ( .A(p_valid[1]), .B(p[35]), .Y(intadd_2_B_11_) );
  INVX1 U1092 ( .A(intadd_2_B_11_), .Y(n680) );
  AND2X1 U1093 ( .A(p_valid[1]), .B(p[34]), .Y(intadd_2_B_10_) );
  INVX1 U1094 ( .A(intadd_2_B_10_), .Y(n681) );
  AND2X1 U1095 ( .A(p_valid[1]), .B(p[33]), .Y(intadd_2_B_9_) );
  INVX1 U1096 ( .A(intadd_2_B_9_), .Y(n682) );
  AND2X1 U1097 ( .A(p_valid[1]), .B(p[32]), .Y(intadd_2_B_8_) );
  INVX1 U1098 ( .A(intadd_2_B_8_), .Y(n683) );
  AND2X1 U1099 ( .A(n857), .B(p[25]), .Y(intadd_2_B_1_) );
  INVX1 U1100 ( .A(intadd_2_B_1_), .Y(n684) );
  AND2X1 U1101 ( .A(n858), .B(p[2]), .Y(intadd_2_B_0_) );
  INVX1 U1102 ( .A(intadd_2_B_0_), .Y(n685) );
  AND2X1 U1103 ( .A(p_valid[3]), .B(p[87]), .Y(intadd_3_B_19_) );
  INVX1 U1104 ( .A(intadd_3_B_19_), .Y(n686) );
  AND2X1 U1105 ( .A(p_valid[3]), .B(p[86]), .Y(intadd_3_B_18_) );
  INVX1 U1106 ( .A(intadd_3_B_18_), .Y(n687) );
  AND2X1 U1107 ( .A(p_valid[3]), .B(p[85]), .Y(intadd_3_B_17_) );
  INVX1 U1108 ( .A(intadd_3_B_17_), .Y(n688) );
  AND2X1 U1109 ( .A(p_valid[3]), .B(p[84]), .Y(intadd_3_B_16_) );
  INVX1 U1110 ( .A(intadd_3_B_16_), .Y(n689) );
  AND2X1 U1111 ( .A(p_valid[3]), .B(p[83]), .Y(intadd_3_B_15_) );
  INVX1 U1112 ( .A(intadd_3_B_15_), .Y(n690) );
  AND2X1 U1113 ( .A(p_valid[3]), .B(p[82]), .Y(intadd_3_B_14_) );
  INVX1 U1114 ( .A(intadd_3_B_14_), .Y(n691) );
  AND2X1 U1115 ( .A(p_valid[3]), .B(p[81]), .Y(intadd_3_B_13_) );
  INVX1 U1116 ( .A(intadd_3_B_13_), .Y(n692) );
  AND2X1 U1117 ( .A(p_valid[3]), .B(p[80]), .Y(intadd_3_B_12_) );
  INVX1 U1118 ( .A(intadd_3_B_12_), .Y(n693) );
  AND2X1 U1119 ( .A(p_valid[3]), .B(p[79]), .Y(intadd_3_B_11_) );
  INVX1 U1120 ( .A(intadd_3_B_11_), .Y(n694) );
  AND2X1 U1121 ( .A(p_valid[3]), .B(p[78]), .Y(intadd_3_B_10_) );
  INVX1 U1122 ( .A(intadd_3_B_10_), .Y(n695) );
  AND2X1 U1123 ( .A(p_valid[3]), .B(p[77]), .Y(intadd_3_B_9_) );
  INVX1 U1124 ( .A(intadd_3_B_9_), .Y(n696) );
  AND2X1 U1125 ( .A(p_valid[3]), .B(p[76]), .Y(intadd_3_B_8_) );
  INVX1 U1126 ( .A(intadd_3_B_8_), .Y(n697) );
  AND2X1 U1127 ( .A(n836), .B(p[69]), .Y(intadd_3_B_1_) );
  INVX1 U1128 ( .A(intadd_3_B_1_), .Y(n698) );
  AND2X1 U1129 ( .A(n837), .B(p[46]), .Y(intadd_3_B_0_) );
  INVX1 U1130 ( .A(intadd_3_B_0_), .Y(n699) );
  BUFX2 U1131 ( .A(g_tree_g_level_1__g_node_1__sum_q[22]), .Y(n700) );
  BUFX2 U1132 ( .A(g_tree_g_level_1__g_node_1__sum_q[21]), .Y(n701) );
  BUFX2 U1133 ( .A(g_tree_g_level_1__g_node_1__sum_q[20]), .Y(n702) );
  BUFX2 U1134 ( .A(g_tree_g_level_1__g_node_1__sum_q[19]), .Y(n703) );
  BUFX2 U1135 ( .A(g_tree_g_level_1__g_node_1__sum_q[18]), .Y(n704) );
  BUFX2 U1136 ( .A(g_tree_g_level_1__g_node_1__sum_q[17]), .Y(n705) );
  BUFX2 U1137 ( .A(g_tree_g_level_1__g_node_1__sum_q[16]), .Y(n706) );
  BUFX2 U1138 ( .A(g_tree_g_level_1__g_node_1__sum_q[15]), .Y(n707) );
  BUFX2 U1139 ( .A(g_tree_g_level_1__g_node_1__sum_q[14]), .Y(n708) );
  BUFX2 U1140 ( .A(g_tree_g_level_1__g_node_1__sum_q[13]), .Y(n709) );
  BUFX2 U1141 ( .A(g_tree_g_level_1__g_node_1__sum_q[12]), .Y(n710) );
  BUFX2 U1142 ( .A(g_tree_g_level_1__g_node_1__sum_q[11]), .Y(n711) );
  BUFX2 U1143 ( .A(g_tree_g_level_1__g_node_1__sum_q[10]), .Y(n712) );
  BUFX2 U1144 ( .A(g_tree_g_level_1__g_node_1__sum_q[9]), .Y(n713) );
  BUFX2 U1145 ( .A(g_tree_g_level_1__g_node_1__sum_q[8]), .Y(n714) );
  BUFX2 U1146 ( .A(g_tree_g_level_1__g_node_1__sum_q[7]), .Y(n715) );
  BUFX2 U1147 ( .A(g_tree_g_level_1__g_node_1__sum_q[6]), .Y(n716) );
  BUFX2 U1148 ( .A(g_tree_g_level_1__g_node_1__sum_q[5]), .Y(n717) );
  BUFX2 U1149 ( .A(g_tree_g_level_1__g_node_1__sum_q[4]), .Y(n718) );
  BUFX2 U1150 ( .A(g_tree_g_level_1__g_node_1__sum_q[3]), .Y(n719) );
  BUFX2 U1151 ( .A(g_tree_g_level_1__g_node_1__sum_q[2]), .Y(n720) );
  BUFX2 U1152 ( .A(g_tree_g_level_1__g_node_1__count_q[1]), .Y(n721) );
  BUFX2 U1153 ( .A(n1262), .Y(payoff_sum[1]) );
  BUFX2 U1154 ( .A(n1296), .Y(acc_overflow) );
  BUFX2 U1155 ( .A(n1298), .Y(sat_s_seen) );
  BUFX2 U1156 ( .A(n1297), .Y(sat_x_seen) );
  BUFX2 U1157 ( .A(n1236), .Y(payoff_sum[27]) );
  BUFX2 U1158 ( .A(n1237), .Y(payoff_sum[26]) );
  BUFX2 U1159 ( .A(n1290), .Y(trial_count[5]) );
  BUFX2 U1160 ( .A(g_tree_g_level_1__g_node_0__sum_q[1]), .Y(n729) );
  BUFX2 U1161 ( .A(n1289), .Y(trial_count[6]) );
  BUFX2 U1162 ( .A(n1266), .Y(trial_count[29]) );
  INVX1 U1163 ( .A(n874), .Y(n732) );
  BUFX2 U1164 ( .A(n1212), .Y(payoff_sum[51]) );
  BUFX2 U1165 ( .A(n1214), .Y(payoff_sum[49]) );
  BUFX2 U1166 ( .A(n1216), .Y(payoff_sum[47]) );
  BUFX2 U1167 ( .A(n1218), .Y(payoff_sum[45]) );
  BUFX2 U1168 ( .A(n1220), .Y(payoff_sum[43]) );
  BUFX2 U1169 ( .A(n1222), .Y(payoff_sum[41]) );
  BUFX2 U1170 ( .A(n1224), .Y(payoff_sum[39]) );
  BUFX2 U1171 ( .A(n1226), .Y(payoff_sum[37]) );
  BUFX2 U1172 ( .A(n1228), .Y(payoff_sum[35]) );
  BUFX2 U1173 ( .A(n1230), .Y(payoff_sum[33]) );
  BUFX2 U1174 ( .A(n1232), .Y(payoff_sum[31]) );
  BUFX2 U1175 ( .A(n1234), .Y(payoff_sum[29]) );
  BUFX2 U1176 ( .A(n1202), .Y(payoff_sum[61]) );
  BUFX2 U1177 ( .A(n1204), .Y(payoff_sum[59]) );
  BUFX2 U1178 ( .A(n1206), .Y(payoff_sum[57]) );
  BUFX2 U1179 ( .A(n1208), .Y(payoff_sum[55]) );
  BUFX2 U1180 ( .A(n1210), .Y(payoff_sum[53]) );
  BUFX2 U1181 ( .A(n1271), .Y(trial_count[24]) );
  BUFX2 U1182 ( .A(n1285), .Y(trial_count[10]) );
  BUFX2 U1183 ( .A(n1287), .Y(trial_count[8]) );
  BUFX2 U1184 ( .A(n1200), .Y(payoff_sum[63]) );
  BUFX2 U1185 ( .A(n1265), .Y(trial_count[30]) );
  BUFX2 U1186 ( .A(n1294), .Y(trial_count[1]) );
  BUFX2 U1187 ( .A(n1240), .Y(payoff_sum[23]) );
  BUFX2 U1188 ( .A(n1241), .Y(payoff_sum[22]) );
  BUFX2 U1189 ( .A(n1242), .Y(payoff_sum[21]) );
  BUFX2 U1190 ( .A(n1243), .Y(payoff_sum[20]) );
  BUFX2 U1191 ( .A(n1244), .Y(payoff_sum[19]) );
  BUFX2 U1192 ( .A(n1245), .Y(payoff_sum[18]) );
  BUFX2 U1193 ( .A(n1246), .Y(payoff_sum[17]) );
  BUFX2 U1194 ( .A(n1247), .Y(payoff_sum[16]) );
  BUFX2 U1195 ( .A(n1248), .Y(payoff_sum[15]) );
  BUFX2 U1196 ( .A(n1249), .Y(payoff_sum[14]) );
  BUFX2 U1197 ( .A(n1250), .Y(payoff_sum[13]) );
  BUFX2 U1198 ( .A(n1251), .Y(payoff_sum[12]) );
  BUFX2 U1199 ( .A(n1252), .Y(payoff_sum[11]) );
  BUFX2 U1200 ( .A(n1253), .Y(payoff_sum[10]) );
  BUFX2 U1201 ( .A(n1254), .Y(payoff_sum[9]) );
  BUFX2 U1202 ( .A(n1255), .Y(payoff_sum[8]) );
  BUFX2 U1203 ( .A(n1256), .Y(payoff_sum[7]) );
  BUFX2 U1204 ( .A(n1257), .Y(payoff_sum[6]) );
  BUFX2 U1205 ( .A(n1258), .Y(payoff_sum[5]) );
  BUFX2 U1206 ( .A(n1259), .Y(payoff_sum[4]) );
  BUFX2 U1207 ( .A(n1260), .Y(payoff_sum[3]) );
  BUFX2 U1208 ( .A(n1261), .Y(payoff_sum[2]) );
  BUFX2 U1209 ( .A(n1203), .Y(payoff_sum[60]) );
  BUFX2 U1210 ( .A(n1205), .Y(payoff_sum[58]) );
  BUFX2 U1211 ( .A(n1207), .Y(payoff_sum[56]) );
  BUFX2 U1212 ( .A(n1209), .Y(payoff_sum[54]) );
  BUFX2 U1213 ( .A(n1211), .Y(payoff_sum[52]) );
  BUFX2 U1214 ( .A(n1213), .Y(payoff_sum[50]) );
  BUFX2 U1215 ( .A(n1215), .Y(payoff_sum[48]) );
  BUFX2 U1216 ( .A(n1217), .Y(payoff_sum[46]) );
  BUFX2 U1217 ( .A(n1219), .Y(payoff_sum[44]) );
  BUFX2 U1218 ( .A(n1221), .Y(payoff_sum[42]) );
  BUFX2 U1219 ( .A(n1223), .Y(payoff_sum[40]) );
  BUFX2 U1220 ( .A(n1225), .Y(payoff_sum[38]) );
  BUFX2 U1221 ( .A(n1227), .Y(payoff_sum[36]) );
  BUFX2 U1222 ( .A(n1229), .Y(payoff_sum[34]) );
  BUFX2 U1223 ( .A(n1231), .Y(payoff_sum[32]) );
  BUFX2 U1224 ( .A(n1233), .Y(payoff_sum[30]) );
  BUFX2 U1225 ( .A(n1235), .Y(payoff_sum[28]) );
  BUFX2 U1226 ( .A(n1270), .Y(trial_count[25]) );
  BUFX2 U1227 ( .A(n1284), .Y(trial_count[11]) );
  BUFX2 U1228 ( .A(n1286), .Y(trial_count[9]) );
  BUFX2 U1229 ( .A(n1288), .Y(trial_count[7]) );
  BUFX2 U1230 ( .A(n1268), .Y(trial_count[27]) );
  BUFX2 U1231 ( .A(n1263), .Y(payoff_sum[0]) );
  BUFX2 U1232 ( .A(n1201), .Y(payoff_sum[62]) );
  BUFX2 U1233 ( .A(n1293), .Y(trial_count[2]) );
  BUFX2 U1234 ( .A(n1239), .Y(payoff_sum[24]) );
  BUFX2 U1235 ( .A(n1292), .Y(trial_count[3]) );
  BUFX2 U1236 ( .A(rst_n), .Y(n1189) );
  INVX1 U1237 ( .A(clear), .Y(n992) );
  AND2X1 U1238 ( .A(intadd_1_SUM_1_), .B(n992), .Y(N154) );
  AND2X1 U1239 ( .A(n805), .B(n992), .Y(N178) );
  AND2X1 U1240 ( .A(intadd_1_SUM_0_), .B(n992), .Y(N153) );
  FAX1 U1241 ( .A(n721), .B(n522), .C(n811), .YC(n805), .YS(n806) );
  AND2X1 U1242 ( .A(n806), .B(n992), .Y(N177) );
  AND2X1 U1243 ( .A(intadd_1_SUM_2_), .B(n992), .Y(N155) );
  INVX1 U1244 ( .A(n1189), .Y(n807) );
  INVX1 U1245 ( .A(n807), .Y(n1191) );
  INVX1 U1246 ( .A(n807), .Y(n1190) );
  INVX1 U1247 ( .A(n807), .Y(n1195) );
  INVX1 U1248 ( .A(n807), .Y(n1196) );
  INVX1 U1249 ( .A(n807), .Y(n1194) );
  INVX1 U1250 ( .A(n807), .Y(n1192) );
  INVX1 U1251 ( .A(n807), .Y(n1193) );
  INVX1 U1252 ( .A(n807), .Y(n1198) );
  INVX1 U1253 ( .A(n807), .Y(n1197) );
  INVX1 U1254 ( .A(clear), .Y(n985) );
  OAI21X1 U1255 ( .A(n439), .B(n668), .C(n985), .Y(n808) );
  INVX1 U1256 ( .A(n808), .Y(N180) );
  OAI21X1 U1257 ( .A(n436), .B(n669), .C(n985), .Y(n809) );
  INVX1 U1258 ( .A(n809), .Y(N179) );
  INVX1 U1259 ( .A(clear), .Y(n861) );
  INVX1 U1260 ( .A(n861), .Y(n859) );
  NOR3X1 U1261 ( .A(n859), .B(n811), .C(n471), .Y(N176) );
  NOR3X1 U1262 ( .A(n859), .B(n813), .C(n472), .Y(N151) );
  MUX2X1 U1263 ( .B(n476), .A(n813), .S(n627), .Y(n815) );
  OAI21X1 U1264 ( .A(n729), .B(n815), .C(n985), .Y(n814) );
  AOI21X1 U1265 ( .A(n729), .B(n815), .C(n814), .Y(N152) );
  OAI21X1 U1266 ( .A(n729), .B(n627), .C(n813), .Y(n817) );
  AND2X1 U1267 ( .A(intadd_1_SUM_3_), .B(n985), .Y(N156) );
  AND2X1 U1268 ( .A(intadd_1_SUM_4_), .B(n985), .Y(N157) );
  AND2X1 U1269 ( .A(intadd_1_SUM_5_), .B(n985), .Y(N158) );
  AND2X1 U1270 ( .A(intadd_1_SUM_6_), .B(n985), .Y(N159) );
  AND2X1 U1271 ( .A(intadd_1_SUM_7_), .B(n985), .Y(N160) );
  AND2X1 U1272 ( .A(intadd_1_SUM_8_), .B(n985), .Y(N161) );
  AND2X1 U1273 ( .A(intadd_1_SUM_9_), .B(n985), .Y(N162) );
  AND2X1 U1274 ( .A(intadd_1_SUM_10_), .B(n861), .Y(N163) );
  AND2X1 U1275 ( .A(intadd_1_SUM_11_), .B(n861), .Y(N164) );
  AND2X1 U1276 ( .A(intadd_1_SUM_12_), .B(n861), .Y(N165) );
  AND2X1 U1277 ( .A(intadd_1_SUM_13_), .B(n861), .Y(N166) );
  AND2X1 U1278 ( .A(intadd_1_SUM_14_), .B(n861), .Y(N167) );
  AND2X1 U1279 ( .A(intadd_1_SUM_15_), .B(n861), .Y(N168) );
  AND2X1 U1280 ( .A(intadd_1_SUM_16_), .B(n861), .Y(N169) );
  AND2X1 U1281 ( .A(intadd_1_SUM_17_), .B(n861), .Y(N170) );
  AND2X1 U1282 ( .A(intadd_1_SUM_18_), .B(n861), .Y(N171) );
  AND2X1 U1283 ( .A(intadd_1_SUM_19_), .B(n861), .Y(N172) );
  AND2X1 U1284 ( .A(intadd_1_SUM_20_), .B(n861), .Y(N173) );
  AND2X1 U1285 ( .A(intadd_1_n1), .B(n861), .Y(N174) );
  INVX1 U1286 ( .A(p_valid[3]), .Y(n818) );
  INVX1 U1287 ( .A(n818), .Y(n836) );
  AOI21X1 U1288 ( .A(n427), .B(n415), .C(n859), .Y(N120) );
  INVX1 U1289 ( .A(p_valid[2]), .Y(n821) );
  INVX1 U1290 ( .A(n821), .Y(n837) );
  AOI21X1 U1291 ( .A(n430), .B(n418), .C(n859), .Y(N119) );
  OAI21X1 U1292 ( .A(p_valid[3]), .B(p_valid[2]), .C(n992), .Y(n824) );
  AOI21X1 U1293 ( .A(n836), .B(n837), .C(n824), .Y(N117) );
  NAND3X1 U1294 ( .A(n861), .B(p_valid[3]), .C(p_valid[2]), .Y(n825) );
  INVX1 U1295 ( .A(n825), .Y(N118) );
  AOI21X1 U1296 ( .A(n482), .B(n481), .C(n666), .Y(N94) );
  AND2X1 U1297 ( .A(p_valid[3]), .B(p[67]), .Y(n835) );
  INVX1 U1298 ( .A(n829), .Y(n834) );
  AND2X1 U1299 ( .A(p_valid[2]), .B(p[45]), .Y(n833) );
  MUX2X1 U1300 ( .B(n829), .A(n834), .S(n833), .Y(n831) );
  OAI21X1 U1301 ( .A(n835), .B(n831), .C(n992), .Y(n830) );
  AOI21X1 U1302 ( .A(n835), .B(n831), .C(n830), .Y(N95) );
  OR2X1 U1303 ( .A(n835), .B(n834), .Y(n832) );
  AOI22X1 U1304 ( .A(n835), .B(n834), .C(n833), .D(n832), .Y(intadd_3_A_0_) );
  INVX1 U1305 ( .A(n985), .Y(n868) );
  INVX1 U1306 ( .A(n985), .Y(n838) );
  INVX1 U1307 ( .A(p_valid[1]), .Y(n839) );
  INVX1 U1308 ( .A(n839), .Y(n857) );
  AOI21X1 U1309 ( .A(n667), .B(n421), .C(n859), .Y(N66) );
  INVX1 U1310 ( .A(p_valid[0]), .Y(n842) );
  INVX1 U1311 ( .A(n842), .Y(n858) );
  AOI21X1 U1312 ( .A(n433), .B(n424), .C(n859), .Y(N65) );
  OAI21X1 U1313 ( .A(p_valid[1]), .B(p_valid[0]), .C(n992), .Y(n845) );
  AOI21X1 U1314 ( .A(n857), .B(n858), .C(n845), .Y(N63) );
  NAND3X1 U1315 ( .A(n861), .B(p_valid[1]), .C(p_valid[0]), .Y(n846) );
  INVX1 U1316 ( .A(n658), .Y(N64) );
  OR2X1 U1317 ( .A(n484), .B(n483), .Y(n850) );
  AOI21X1 U1318 ( .A(n483), .B(n484), .C(n412), .Y(N40) );
  AND2X1 U1319 ( .A(p_valid[1]), .B(p[23]), .Y(n856) );
  INVX1 U1320 ( .A(n850), .Y(n855) );
  AND2X1 U1321 ( .A(p_valid[0]), .B(p[1]), .Y(n854) );
  MUX2X1 U1322 ( .B(n850), .A(n855), .S(n854), .Y(n852) );
  OAI21X1 U1323 ( .A(n856), .B(n852), .C(n992), .Y(n851) );
  AOI21X1 U1324 ( .A(n856), .B(n852), .C(n851), .Y(N41) );
  OR2X1 U1325 ( .A(n856), .B(n855), .Y(n853) );
  AOI22X1 U1326 ( .A(n856), .B(n855), .C(n854), .D(n853), .Y(intadd_2_A_0_) );
  NOR3X1 U1327 ( .A(n625), .B(n626), .C(n628), .Y(n860) );
  INVX1 U1328 ( .A(n860), .Y(n991) );
  AND2X1 U1329 ( .A(n992), .B(n991), .Y(n1024) );
  AOI22X1 U1330 ( .A(n457), .B(n1024), .C(sat_x_seen), .D(n861), .Y(n862) );
  INVX1 U1331 ( .A(n862), .Y(n221) );
  AOI22X1 U1332 ( .A(n460), .B(n1024), .C(sat_s_seen), .D(n985), .Y(n863) );
  INVX1 U1333 ( .A(n863), .Y(n220) );
  INVX1 U1334 ( .A(payoff_sum[1]), .Y(n995) );
  INVX1 U1335 ( .A(n475), .Y(n989) );
  OR2X1 U1336 ( .A(n995), .B(n629), .Y(n864) );
  AOI22X1 U1337 ( .A(n995), .B(n629), .C(n989), .D(n864), .Y(intadd_0_CI) );
  INVX1 U1338 ( .A(n1024), .Y(n1182) );
  INVX1 U1339 ( .A(n1182), .Y(n1027) );
  NAND3X1 U1340 ( .A(payoff_sum[24]), .B(payoff_sum[25]), .C(intadd_0_n1), .Y(
        n1030) );
  INVX1 U1341 ( .A(payoff_sum[26]), .Y(n1032) );
  NAND3X1 U1342 ( .A(n1027), .B(payoff_sum[62]), .C(n1183), .Y(n1188) );
  INVX1 U1343 ( .A(payoff_sum[63]), .Y(n866) );
  OAI21X1 U1344 ( .A(n520), .B(n866), .C(n331), .Y(n219) );
  OAI21X1 U1345 ( .A(n626), .B(trial_count[0]), .C(n732), .Y(n867) );
  MUX2X1 U1346 ( .B(n624), .A(n625), .S(n732), .Y(n869) );
  INVX1 U1347 ( .A(n869), .Y(n871) );
  OAI21X1 U1348 ( .A(trial_count[1]), .B(n871), .C(n985), .Y(n870) );
  AOI21X1 U1349 ( .A(trial_count[1]), .B(n871), .C(n870), .Y(n217) );
  INVX1 U1350 ( .A(trial_count[1]), .Y(n873) );
  AOI22X1 U1351 ( .A(n732), .B(n624), .C(n873), .D(n872), .Y(n877) );
  INVX1 U1352 ( .A(n1027), .Y(n1169) );
  AND2X1 U1353 ( .A(n992), .B(n1169), .Y(n1017) );
  INVX1 U1354 ( .A(n1017), .Y(n1181) );
  INVX1 U1355 ( .A(n1181), .Y(n1019) );
  AOI22X1 U1356 ( .A(n1024), .B(n875), .C(n1019), .D(trial_count[2]), .Y(n876)
         );
  INVX1 U1357 ( .A(n876), .Y(n216) );
  FAX1 U1358 ( .A(trial_count[2]), .B(n628), .C(n486), .YC(n884), .YS(n875) );
  INVX1 U1359 ( .A(n1027), .Y(n1078) );
  INVX1 U1360 ( .A(n1019), .Y(n967) );
  OAI21X1 U1361 ( .A(n884), .B(n1078), .C(n967), .Y(n880) );
  INVX1 U1362 ( .A(n880), .Y(n879) );
  INVX1 U1363 ( .A(trial_count[3]), .Y(n881) );
  AOI22X1 U1364 ( .A(trial_count[3]), .B(n879), .C(n469), .D(n881), .Y(n215)
         );
  AOI21X1 U1365 ( .A(n1027), .B(n881), .C(n880), .Y(n883) );
  NAND3X1 U1366 ( .A(n1024), .B(trial_count[3]), .C(n884), .Y(n882) );
  AOI22X1 U1367 ( .A(trial_count[4]), .B(n445), .C(n466), .D(n646), .Y(n214)
         );
  NAND3X1 U1368 ( .A(trial_count[3]), .B(trial_count[4]), .C(n884), .Y(n889)
         );
  INVX1 U1369 ( .A(trial_count[5]), .Y(n888) );
  OAI21X1 U1370 ( .A(n620), .B(n1078), .C(n967), .Y(n887) );
  OAI21X1 U1371 ( .A(n621), .B(n464), .C(n334), .Y(n213) );
  INVX1 U1372 ( .A(trial_count[6]), .Y(n892) );
  AOI21X1 U1373 ( .A(n1027), .B(n888), .C(n887), .Y(n891) );
  INVX1 U1374 ( .A(n1182), .Y(n1174) );
  NAND3X1 U1375 ( .A(n479), .B(n1174), .C(n892), .Y(n890) );
  OAI21X1 U1376 ( .A(n892), .B(n462), .C(n319), .Y(n212) );
  OAI21X1 U1377 ( .A(n895), .B(n1078), .C(n967), .Y(n897) );
  AOI22X1 U1378 ( .A(n895), .B(n492), .C(trial_count[7]), .D(n897), .Y(n894)
         );
  INVX1 U1379 ( .A(n894), .Y(n211) );
  INVX1 U1380 ( .A(trial_count[8]), .Y(n896) );
  INVX1 U1381 ( .A(n1182), .Y(n1162) );
  NAND3X1 U1382 ( .A(n896), .B(n901), .C(n1162), .Y(n900) );
  OAI21X1 U1383 ( .A(n492), .B(n897), .C(trial_count[8]), .Y(n899) );
  OAI21X1 U1384 ( .A(n903), .B(n1078), .C(n967), .Y(n905) );
  AOI22X1 U1385 ( .A(n903), .B(n493), .C(trial_count[9]), .D(n905), .Y(n902)
         );
  INVX1 U1386 ( .A(n902), .Y(n209) );
  INVX1 U1387 ( .A(trial_count[10]), .Y(n904) );
  NAND3X1 U1388 ( .A(n904), .B(n909), .C(n1162), .Y(n908) );
  OAI21X1 U1389 ( .A(n493), .B(n905), .C(trial_count[10]), .Y(n907) );
  OAI21X1 U1390 ( .A(n911), .B(n1078), .C(n967), .Y(n912) );
  AOI22X1 U1391 ( .A(n911), .B(n494), .C(trial_count[11]), .D(n912), .Y(n910)
         );
  INVX1 U1392 ( .A(n910), .Y(n207) );
  NAND3X1 U1393 ( .A(n632), .B(n916), .C(n1162), .Y(n915) );
  OAI21X1 U1394 ( .A(n494), .B(n912), .C(trial_count[12]), .Y(n914) );
  AND2X1 U1395 ( .A(trial_count[12]), .B(n916), .Y(n918) );
  OAI21X1 U1396 ( .A(n918), .B(n1078), .C(n967), .Y(n919) );
  AOI22X1 U1397 ( .A(n918), .B(n495), .C(trial_count[13]), .D(n919), .Y(n917)
         );
  INVX1 U1398 ( .A(n917), .Y(n205) );
  AND2X1 U1399 ( .A(n918), .B(trial_count[13]), .Y(n923) );
  NAND3X1 U1400 ( .A(n634), .B(n923), .C(n1027), .Y(n922) );
  OAI21X1 U1401 ( .A(n495), .B(n919), .C(trial_count[14]), .Y(n921) );
  AND2X1 U1402 ( .A(trial_count[14]), .B(n923), .Y(n925) );
  INVX1 U1403 ( .A(n1182), .Y(n1033) );
  INVX1 U1404 ( .A(n1033), .Y(n1159) );
  OAI21X1 U1405 ( .A(n925), .B(n1078), .C(n967), .Y(n926) );
  AOI22X1 U1406 ( .A(n925), .B(n496), .C(trial_count[15]), .D(n926), .Y(n924)
         );
  INVX1 U1407 ( .A(n924), .Y(n203) );
  AND2X1 U1408 ( .A(n925), .B(trial_count[15]), .Y(n930) );
  NAND3X1 U1409 ( .A(n636), .B(n930), .C(n1024), .Y(n929) );
  OAI21X1 U1410 ( .A(n496), .B(n926), .C(trial_count[16]), .Y(n928) );
  AND2X1 U1411 ( .A(trial_count[16]), .B(n930), .Y(n932) );
  OAI21X1 U1412 ( .A(n932), .B(n1078), .C(n967), .Y(n933) );
  AOI22X1 U1413 ( .A(n932), .B(n497), .C(trial_count[17]), .D(n933), .Y(n931)
         );
  INVX1 U1414 ( .A(n931), .Y(n201) );
  AND2X1 U1415 ( .A(n932), .B(trial_count[17]), .Y(n937) );
  NAND3X1 U1416 ( .A(n638), .B(n937), .C(n1024), .Y(n936) );
  OAI21X1 U1417 ( .A(n497), .B(n933), .C(trial_count[18]), .Y(n935) );
  AND2X1 U1418 ( .A(trial_count[18]), .B(n937), .Y(n939) );
  OAI21X1 U1419 ( .A(n939), .B(n1078), .C(n967), .Y(n940) );
  AOI22X1 U1420 ( .A(n939), .B(n498), .C(trial_count[19]), .D(n940), .Y(n938)
         );
  INVX1 U1421 ( .A(n938), .Y(n199) );
  AND2X1 U1422 ( .A(n939), .B(trial_count[19]), .Y(n944) );
  NAND3X1 U1423 ( .A(n640), .B(n944), .C(n1024), .Y(n943) );
  OAI21X1 U1424 ( .A(n498), .B(n940), .C(trial_count[20]), .Y(n942) );
  AND2X1 U1425 ( .A(trial_count[20]), .B(n944), .Y(n946) );
  OAI21X1 U1426 ( .A(n946), .B(n1078), .C(n967), .Y(n947) );
  AOI22X1 U1427 ( .A(n946), .B(n499), .C(trial_count[21]), .D(n947), .Y(n945)
         );
  INVX1 U1428 ( .A(n945), .Y(n197) );
  AND2X1 U1429 ( .A(n946), .B(trial_count[21]), .Y(n951) );
  NAND3X1 U1430 ( .A(n642), .B(n951), .C(n1024), .Y(n950) );
  OAI21X1 U1431 ( .A(n499), .B(n947), .C(trial_count[22]), .Y(n949) );
  AND2X1 U1432 ( .A(trial_count[22]), .B(n951), .Y(n953) );
  OAI21X1 U1433 ( .A(n953), .B(n1078), .C(n967), .Y(n955) );
  AOI22X1 U1434 ( .A(n953), .B(n500), .C(trial_count[23]), .D(n955), .Y(n952)
         );
  INVX1 U1435 ( .A(n952), .Y(n195) );
  INVX1 U1436 ( .A(trial_count[24]), .Y(n954) );
  AND2X1 U1437 ( .A(n953), .B(trial_count[23]), .Y(n959) );
  NAND3X1 U1438 ( .A(n954), .B(n959), .C(n1174), .Y(n958) );
  OAI21X1 U1439 ( .A(n500), .B(n955), .C(trial_count[24]), .Y(n957) );
  OAI21X1 U1440 ( .A(n961), .B(n1078), .C(n967), .Y(n962) );
  AOI22X1 U1441 ( .A(n961), .B(n501), .C(trial_count[25]), .D(n962), .Y(n960)
         );
  INVX1 U1442 ( .A(n960), .Y(n193) );
  NAND3X1 U1443 ( .A(n644), .B(n966), .C(n1174), .Y(n965) );
  OAI21X1 U1444 ( .A(n501), .B(n962), .C(trial_count[26]), .Y(n964) );
  INVX1 U1445 ( .A(trial_count[27]), .Y(n971) );
  AND2X1 U1446 ( .A(trial_count[26]), .B(n966), .Y(n974) );
  OAI21X1 U1447 ( .A(n974), .B(n1182), .C(n967), .Y(n970) );
  INVX1 U1448 ( .A(n970), .Y(n969) );
  NAND3X1 U1449 ( .A(n974), .B(n1174), .C(n971), .Y(n968) );
  OAI21X1 U1450 ( .A(n971), .B(n969), .C(n322), .Y(n191) );
  AOI21X1 U1451 ( .A(n1033), .B(n971), .C(n970), .Y(n973) );
  NAND3X1 U1452 ( .A(n1027), .B(n974), .C(trial_count[27]), .Y(n972) );
  AOI22X1 U1453 ( .A(trial_count[28]), .B(n448), .C(n467), .D(n648), .Y(n190)
         );
  INVX1 U1454 ( .A(trial_count[29]), .Y(n978) );
  NAND3X1 U1455 ( .A(n974), .B(trial_count[28]), .C(trial_count[27]), .Y(n977)
         );
  NAND3X1 U1456 ( .A(n622), .B(n1174), .C(n978), .Y(n975) );
  OAI21X1 U1457 ( .A(n978), .B(n480), .C(n325), .Y(n189) );
  INVX1 U1458 ( .A(n1027), .Y(n1171) );
  OAI21X1 U1459 ( .A(trial_count[29]), .B(n1171), .C(n480), .Y(n981) );
  NOR3X1 U1460 ( .A(n1182), .B(n978), .C(n623), .Y(n980) );
  INVX1 U1461 ( .A(trial_count[30]), .Y(n982) );
  AOI22X1 U1462 ( .A(trial_count[30]), .B(n981), .C(n980), .D(n982), .Y(n979)
         );
  INVX1 U1463 ( .A(n979), .Y(n188) );
  AOI21X1 U1464 ( .A(n1024), .B(n982), .C(n981), .Y(n983) );
  MUX2X1 U1465 ( .B(n442), .A(n454), .S(trial_count[31]), .Y(n187) );
  AND2X1 U1466 ( .A(n474), .B(n991), .Y(n987) );
  OAI21X1 U1467 ( .A(payoff_sum[0]), .B(n987), .C(n985), .Y(n986) );
  AOI21X1 U1468 ( .A(payoff_sum[0]), .B(n987), .C(n986), .Y(n186) );
  MUX2X1 U1469 ( .B(n475), .A(n989), .S(n629), .Y(n990) );
  OAI21X1 U1470 ( .A(n995), .B(n519), .C(n992), .Y(n993) );
  AOI21X1 U1471 ( .A(n995), .B(n519), .C(n993), .Y(n185) );
  AOI22X1 U1472 ( .A(n1024), .B(intadd_0_SUM_0_), .C(n1017), .D(payoff_sum[2]), 
        .Y(n996) );
  INVX1 U1473 ( .A(n996), .Y(n184) );
  AOI22X1 U1474 ( .A(n1024), .B(intadd_0_SUM_1_), .C(n1017), .D(payoff_sum[3]), 
        .Y(n997) );
  INVX1 U1475 ( .A(n997), .Y(n183) );
  AOI22X1 U1476 ( .A(n1033), .B(intadd_0_SUM_2_), .C(n1019), .D(payoff_sum[4]), 
        .Y(n998) );
  INVX1 U1477 ( .A(n998), .Y(n182) );
  AOI22X1 U1478 ( .A(n1033), .B(intadd_0_SUM_3_), .C(n1017), .D(payoff_sum[5]), 
        .Y(n999) );
  INVX1 U1479 ( .A(n999), .Y(n181) );
  AOI22X1 U1480 ( .A(n1033), .B(intadd_0_SUM_4_), .C(n1017), .D(payoff_sum[6]), 
        .Y(n1000) );
  INVX1 U1481 ( .A(n1000), .Y(n180) );
  AOI22X1 U1482 ( .A(n1024), .B(intadd_0_SUM_5_), .C(n1019), .D(payoff_sum[7]), 
        .Y(n1001) );
  INVX1 U1483 ( .A(n1001), .Y(n179) );
  AOI22X1 U1484 ( .A(n1033), .B(intadd_0_SUM_6_), .C(n1017), .D(payoff_sum[8]), 
        .Y(n1002) );
  INVX1 U1485 ( .A(n1002), .Y(n178) );
  AOI22X1 U1486 ( .A(n1033), .B(intadd_0_SUM_7_), .C(n1017), .D(payoff_sum[9]), 
        .Y(n1003) );
  INVX1 U1487 ( .A(n1003), .Y(n177) );
  AOI22X1 U1488 ( .A(n1033), .B(intadd_0_SUM_8_), .C(n1017), .D(payoff_sum[10]), .Y(n1004) );
  INVX1 U1489 ( .A(n1004), .Y(n176) );
  AOI22X1 U1490 ( .A(n1033), .B(intadd_0_SUM_9_), .C(n1017), .D(payoff_sum[11]), .Y(n1005) );
  INVX1 U1491 ( .A(n1005), .Y(n175) );
  AOI22X1 U1492 ( .A(n1033), .B(intadd_0_SUM_10_), .C(n1017), .D(
        payoff_sum[12]), .Y(n1006) );
  INVX1 U1493 ( .A(n1006), .Y(n174) );
  AOI22X1 U1494 ( .A(n1033), .B(intadd_0_SUM_11_), .C(n1019), .D(
        payoff_sum[13]), .Y(n1007) );
  INVX1 U1495 ( .A(n1007), .Y(n173) );
  AOI22X1 U1496 ( .A(n1033), .B(intadd_0_SUM_12_), .C(n1019), .D(
        payoff_sum[14]), .Y(n1008) );
  INVX1 U1497 ( .A(n1008), .Y(n172) );
  AOI22X1 U1498 ( .A(n1033), .B(intadd_0_SUM_13_), .C(n1019), .D(
        payoff_sum[15]), .Y(n1009) );
  INVX1 U1499 ( .A(n1009), .Y(n171) );
  AOI22X1 U1500 ( .A(n1033), .B(intadd_0_SUM_14_), .C(n1019), .D(
        payoff_sum[16]), .Y(n1010) );
  INVX1 U1501 ( .A(n1010), .Y(n170) );
  AOI22X1 U1502 ( .A(n1033), .B(intadd_0_SUM_15_), .C(n1019), .D(
        payoff_sum[17]), .Y(n1011) );
  INVX1 U1503 ( .A(n1011), .Y(n169) );
  AOI22X1 U1504 ( .A(n1174), .B(intadd_0_SUM_16_), .C(n1017), .D(
        payoff_sum[18]), .Y(n1012) );
  INVX1 U1505 ( .A(n1012), .Y(n168) );
  AOI22X1 U1506 ( .A(n1174), .B(intadd_0_SUM_17_), .C(n1017), .D(
        payoff_sum[19]), .Y(n1013) );
  INVX1 U1507 ( .A(n1013), .Y(n167) );
  AOI22X1 U1508 ( .A(n1174), .B(intadd_0_SUM_18_), .C(n1017), .D(
        payoff_sum[20]), .Y(n1014) );
  INVX1 U1509 ( .A(n1014), .Y(n166) );
  AOI22X1 U1510 ( .A(n1174), .B(intadd_0_SUM_19_), .C(n1017), .D(
        payoff_sum[21]), .Y(n1015) );
  INVX1 U1511 ( .A(n1015), .Y(n165) );
  AOI22X1 U1512 ( .A(n1174), .B(intadd_0_SUM_20_), .C(n1017), .D(
        payoff_sum[22]), .Y(n1016) );
  INVX1 U1513 ( .A(n1016), .Y(n164) );
  AOI22X1 U1514 ( .A(n1174), .B(intadd_0_SUM_21_), .C(n1017), .D(
        payoff_sum[23]), .Y(n1018) );
  INVX1 U1515 ( .A(n1018), .Y(n163) );
  INVX1 U1516 ( .A(n1019), .Y(n1170) );
  OAI21X1 U1517 ( .A(intadd_0_n1), .B(n1171), .C(n1170), .Y(n1022) );
  INVX1 U1518 ( .A(n1022), .Y(n1021) );
  INVX1 U1519 ( .A(payoff_sum[24]), .Y(n1023) );
  AOI22X1 U1520 ( .A(payoff_sum[24]), .B(n1021), .C(n470), .D(n1023), .Y(n162)
         );
  AOI21X1 U1521 ( .A(n1024), .B(n1023), .C(n1022), .Y(n1026) );
  NAND3X1 U1522 ( .A(n1027), .B(payoff_sum[24]), .C(intadd_0_n1), .Y(n1025) );
  AOI22X1 U1523 ( .A(payoff_sum[25]), .B(n451), .C(n468), .D(n650), .Y(n161)
         );
  OAI21X1 U1524 ( .A(n618), .B(n1078), .C(n1170), .Y(n1031) );
  OAI21X1 U1525 ( .A(n619), .B(n465), .C(n337), .Y(n160) );
  INVX1 U1526 ( .A(payoff_sum[27]), .Y(n1037) );
  AOI21X1 U1527 ( .A(n1033), .B(n1032), .C(n1031), .Y(n1036) );
  NAND3X1 U1528 ( .A(n478), .B(n1174), .C(n1037), .Y(n1035) );
  OAI21X1 U1529 ( .A(n1037), .B(n463), .C(n328), .Y(n159) );
  OAI21X1 U1530 ( .A(n1038), .B(n1171), .C(n1170), .Y(n1042) );
  AOI22X1 U1531 ( .A(n1038), .B(n502), .C(payoff_sum[28]), .D(n1042), .Y(n1039) );
  INVX1 U1532 ( .A(n1039), .Y(n158) );
  INVX1 U1533 ( .A(payoff_sum[29]), .Y(n1041) );
  NAND3X1 U1534 ( .A(n1041), .B(n1040), .C(n1174), .Y(n1045) );
  OAI21X1 U1535 ( .A(n502), .B(n1042), .C(payoff_sum[29]), .Y(n1044) );
  OAI21X1 U1536 ( .A(n1046), .B(n1078), .C(n1170), .Y(n1050) );
  AOI22X1 U1537 ( .A(n1046), .B(n503), .C(payoff_sum[30]), .D(n1050), .Y(n1047) );
  INVX1 U1538 ( .A(n1047), .Y(n156) );
  INVX1 U1539 ( .A(payoff_sum[31]), .Y(n1049) );
  NAND3X1 U1540 ( .A(n1049), .B(n1048), .C(n1174), .Y(n1053) );
  OAI21X1 U1541 ( .A(n503), .B(n1050), .C(payoff_sum[31]), .Y(n1052) );
  OAI21X1 U1542 ( .A(n1054), .B(n1171), .C(n1170), .Y(n1058) );
  AOI22X1 U1543 ( .A(n1054), .B(n504), .C(payoff_sum[32]), .D(n1058), .Y(n1055) );
  INVX1 U1544 ( .A(n1055), .Y(n154) );
  INVX1 U1545 ( .A(payoff_sum[33]), .Y(n1057) );
  NAND3X1 U1546 ( .A(n1057), .B(n1056), .C(n1174), .Y(n1061) );
  OAI21X1 U1547 ( .A(n504), .B(n1058), .C(payoff_sum[33]), .Y(n1060) );
  OAI21X1 U1548 ( .A(n1062), .B(n1078), .C(n1170), .Y(n1066) );
  AOI22X1 U1549 ( .A(n1062), .B(n505), .C(payoff_sum[34]), .D(n1066), .Y(n1063) );
  INVX1 U1550 ( .A(n1063), .Y(n152) );
  INVX1 U1551 ( .A(payoff_sum[35]), .Y(n1065) );
  NAND3X1 U1552 ( .A(n1065), .B(n1064), .C(n1162), .Y(n1069) );
  OAI21X1 U1553 ( .A(n505), .B(n1066), .C(payoff_sum[35]), .Y(n1068) );
  OAI21X1 U1554 ( .A(n1070), .B(n1171), .C(n1170), .Y(n1074) );
  AOI22X1 U1555 ( .A(n1070), .B(n506), .C(payoff_sum[36]), .D(n1074), .Y(n1071) );
  INVX1 U1556 ( .A(n1071), .Y(n150) );
  INVX1 U1557 ( .A(payoff_sum[37]), .Y(n1073) );
  NAND3X1 U1558 ( .A(n1073), .B(n1072), .C(n1162), .Y(n1077) );
  OAI21X1 U1559 ( .A(n506), .B(n1074), .C(payoff_sum[37]), .Y(n1076) );
  OAI21X1 U1560 ( .A(n1079), .B(n1078), .C(n1170), .Y(n1083) );
  AOI22X1 U1561 ( .A(n1079), .B(n507), .C(payoff_sum[38]), .D(n1083), .Y(n1080) );
  INVX1 U1562 ( .A(n1080), .Y(n148) );
  INVX1 U1563 ( .A(payoff_sum[39]), .Y(n1082) );
  NAND3X1 U1564 ( .A(n1082), .B(n1081), .C(n1162), .Y(n1086) );
  OAI21X1 U1565 ( .A(n507), .B(n1083), .C(payoff_sum[39]), .Y(n1085) );
  OAI21X1 U1566 ( .A(n1087), .B(n1171), .C(n1170), .Y(n1091) );
  AOI22X1 U1567 ( .A(n1087), .B(n508), .C(payoff_sum[40]), .D(n1091), .Y(n1088) );
  INVX1 U1568 ( .A(n1088), .Y(n146) );
  INVX1 U1569 ( .A(payoff_sum[41]), .Y(n1090) );
  NAND3X1 U1570 ( .A(n1090), .B(n1089), .C(n1162), .Y(n1094) );
  OAI21X1 U1571 ( .A(n508), .B(n1091), .C(payoff_sum[41]), .Y(n1093) );
  OAI21X1 U1572 ( .A(n1095), .B(n1171), .C(n1170), .Y(n1099) );
  AOI22X1 U1573 ( .A(n1095), .B(n509), .C(payoff_sum[42]), .D(n1099), .Y(n1096) );
  INVX1 U1574 ( .A(n1096), .Y(n144) );
  INVX1 U1575 ( .A(payoff_sum[43]), .Y(n1098) );
  NAND3X1 U1576 ( .A(n1098), .B(n1097), .C(n1162), .Y(n1102) );
  OAI21X1 U1577 ( .A(n509), .B(n1099), .C(payoff_sum[43]), .Y(n1101) );
  OAI21X1 U1578 ( .A(n1103), .B(n1171), .C(n1170), .Y(n1107) );
  AOI22X1 U1579 ( .A(n1103), .B(n510), .C(payoff_sum[44]), .D(n1107), .Y(n1104) );
  INVX1 U1580 ( .A(n1104), .Y(n142) );
  INVX1 U1581 ( .A(payoff_sum[45]), .Y(n1106) );
  NAND3X1 U1582 ( .A(n1106), .B(n1105), .C(n1162), .Y(n1110) );
  OAI21X1 U1583 ( .A(n510), .B(n1107), .C(payoff_sum[45]), .Y(n1109) );
  OAI21X1 U1584 ( .A(n1111), .B(n1171), .C(n1170), .Y(n1115) );
  AOI22X1 U1585 ( .A(n1111), .B(n511), .C(payoff_sum[46]), .D(n1115), .Y(n1112) );
  INVX1 U1586 ( .A(n1112), .Y(n140) );
  INVX1 U1587 ( .A(payoff_sum[47]), .Y(n1114) );
  NAND3X1 U1588 ( .A(n1114), .B(n1113), .C(n1162), .Y(n1118) );
  OAI21X1 U1589 ( .A(n511), .B(n1115), .C(payoff_sum[47]), .Y(n1117) );
  OAI21X1 U1590 ( .A(n1119), .B(n1171), .C(n1170), .Y(n1123) );
  AOI22X1 U1591 ( .A(n1119), .B(n512), .C(payoff_sum[48]), .D(n1123), .Y(n1120) );
  INVX1 U1592 ( .A(n1120), .Y(n138) );
  INVX1 U1593 ( .A(payoff_sum[49]), .Y(n1122) );
  NAND3X1 U1594 ( .A(n1122), .B(n1121), .C(n1162), .Y(n1126) );
  OAI21X1 U1595 ( .A(n512), .B(n1123), .C(payoff_sum[49]), .Y(n1125) );
  OAI21X1 U1596 ( .A(n1127), .B(n1171), .C(n1181), .Y(n1131) );
  AOI22X1 U1597 ( .A(n1127), .B(n513), .C(payoff_sum[50]), .D(n1131), .Y(n1128) );
  INVX1 U1598 ( .A(n1128), .Y(n136) );
  INVX1 U1599 ( .A(payoff_sum[51]), .Y(n1130) );
  NAND3X1 U1600 ( .A(n1130), .B(n1129), .C(n1162), .Y(n1134) );
  OAI21X1 U1601 ( .A(n513), .B(n1131), .C(payoff_sum[51]), .Y(n1133) );
  OAI21X1 U1602 ( .A(n1135), .B(n1171), .C(n1181), .Y(n1139) );
  AOI22X1 U1603 ( .A(n1135), .B(n514), .C(payoff_sum[52]), .D(n1139), .Y(n1136) );
  INVX1 U1604 ( .A(n1136), .Y(n134) );
  INVX1 U1605 ( .A(payoff_sum[53]), .Y(n1138) );
  NAND3X1 U1606 ( .A(n1138), .B(n1137), .C(n1162), .Y(n1142) );
  OAI21X1 U1607 ( .A(n514), .B(n1139), .C(payoff_sum[53]), .Y(n1141) );
  OAI21X1 U1608 ( .A(n1143), .B(n1171), .C(n1181), .Y(n1147) );
  AOI22X1 U1609 ( .A(n1143), .B(n515), .C(payoff_sum[54]), .D(n1147), .Y(n1144) );
  INVX1 U1610 ( .A(n1144), .Y(n132) );
  INVX1 U1611 ( .A(payoff_sum[55]), .Y(n1146) );
  NAND3X1 U1612 ( .A(n1146), .B(n1145), .C(n1162), .Y(n1150) );
  OAI21X1 U1613 ( .A(n515), .B(n1147), .C(payoff_sum[55]), .Y(n1149) );
  OAI21X1 U1614 ( .A(n1151), .B(n1171), .C(n1181), .Y(n1155) );
  AOI22X1 U1615 ( .A(n1151), .B(n516), .C(payoff_sum[56]), .D(n1155), .Y(n1152) );
  INVX1 U1616 ( .A(n1152), .Y(n130) );
  INVX1 U1617 ( .A(payoff_sum[57]), .Y(n1154) );
  NAND3X1 U1618 ( .A(n1154), .B(n1153), .C(n1162), .Y(n1158) );
  OAI21X1 U1619 ( .A(n516), .B(n1155), .C(payoff_sum[57]), .Y(n1157) );
  OAI21X1 U1620 ( .A(n1160), .B(n1171), .C(n1181), .Y(n1165) );
  AOI22X1 U1621 ( .A(n1160), .B(n517), .C(payoff_sum[58]), .D(n1165), .Y(n1161) );
  INVX1 U1622 ( .A(n1161), .Y(n128) );
  INVX1 U1623 ( .A(payoff_sum[59]), .Y(n1164) );
  NAND3X1 U1624 ( .A(n1164), .B(n1163), .C(n1162), .Y(n1168) );
  OAI21X1 U1625 ( .A(n517), .B(n1165), .C(payoff_sum[59]), .Y(n1167) );
  OAI21X1 U1626 ( .A(n1172), .B(n1171), .C(n1170), .Y(n1177) );
  AOI22X1 U1627 ( .A(n1172), .B(n518), .C(payoff_sum[60]), .D(n1177), .Y(n1173) );
  INVX1 U1628 ( .A(n1173), .Y(n126) );
  INVX1 U1629 ( .A(payoff_sum[61]), .Y(n1176) );
  NAND3X1 U1630 ( .A(n1176), .B(n1175), .C(n1174), .Y(n1180) );
  OAI21X1 U1631 ( .A(n518), .B(n1177), .C(payoff_sum[61]), .Y(n1179) );
  OAI21X1 U1632 ( .A(n1183), .B(n1182), .C(n1181), .Y(n1185) );
  AOI22X1 U1633 ( .A(payoff_sum[62]), .B(n1185), .C(n521), .D(n1183), .Y(n1184) );
  INVX1 U1634 ( .A(n1184), .Y(n124) );
  OAI21X1 U1635 ( .A(n521), .B(n1185), .C(payoff_sum[63]), .Y(n1187) );
  OAI21X1 U1636 ( .A(payoff_sum[63]), .B(n520), .C(n1187), .Y(n123) );
  OR2X2 U512 ( .A(n1299), .B(n405), .Y(n316) );
  OR2X2 U513 ( .A(n1300), .B(n402), .Y(n313) );
  OR2X2 U514 ( .A(n1301), .B(n399), .Y(n310) );
  OR2X2 U515 ( .A(n1302), .B(n396), .Y(n307) );
  OR2X2 U516 ( .A(n1303), .B(n393), .Y(n304) );
  OR2X2 U517 ( .A(n1304), .B(n390), .Y(n301) );
  OR2X2 U518 ( .A(n1305), .B(n387), .Y(n298) );
  OR2X2 U519 ( .A(n1306), .B(n384), .Y(n295) );
  OR2X2 U520 ( .A(n1307), .B(n381), .Y(n292) );
  OR2X2 U521 ( .A(n1308), .B(n378), .Y(n289) );
  OR2X2 U522 ( .A(n1309), .B(n375), .Y(n286) );
  OR2X2 U523 ( .A(n1310), .B(n372), .Y(n283) );
  AND2X1 U524 ( .A(n980), .B(trial_count[30]), .Y(n441) );
  AND2X1 U525 ( .A(n1031), .B(payoff_sum[26]), .Y(n336) );
  AND2X1 U526 ( .A(n887), .B(trial_count[5]), .Y(n333) );
  AND2X1 U527 ( .A(n992), .B(n850), .Y(n411) );
  AND2X1 U528 ( .A(n992), .B(acc_overflow), .Y(n330) );
  AND2X1 U529 ( .A(sat_x[2]), .B(n837), .Y(n429) );
  AND2X1 U530 ( .A(n836), .B(sat_x[3]), .Y(n417) );
  AND2X1 U531 ( .A(n836), .B(sat_s[3]), .Y(n414) );
  AND2X1 U532 ( .A(n857), .B(sat_s[1]), .Y(n420) );
  AND2X1 U533 ( .A(sat_s[2]), .B(p_valid[2]), .Y(n426) );
  INVX1 U534 ( .A(n1179), .Y(n1299) );
  INVX1 U535 ( .A(n1167), .Y(n1300) );
  INVX1 U536 ( .A(n1157), .Y(n1301) );
  INVX1 U537 ( .A(n1149), .Y(n1302) );
  INVX1 U538 ( .A(n1141), .Y(n1303) );
  INVX1 U539 ( .A(n1133), .Y(n1304) );
  INVX1 U540 ( .A(n1125), .Y(n1305) );
  INVX1 U541 ( .A(n1117), .Y(n1306) );
  INVX1 U542 ( .A(n1109), .Y(n1307) );
  INVX1 U543 ( .A(n1101), .Y(n1308) );
  INVX1 U544 ( .A(n1093), .Y(n1309) );
  INVX1 U545 ( .A(n1085), .Y(n1310) );
  AND2X1 U546 ( .A(sat_x[0]), .B(n858), .Y(n432) );
  AND2X1 U547 ( .A(n857), .B(sat_x[1]), .Y(n423) );
  INVX1 U548 ( .A(n817), .Y(n1311) );
  OR2X1 U549 ( .A(n1311), .B(n408), .Y(n487) );
  AND2X1 U550 ( .A(n627), .B(n729), .Y(n408) );
endmodule

