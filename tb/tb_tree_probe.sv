// Probe the TreeGRNG 8-bit decision tree (gaussianSimplified8) to extract, for every level
// and every prefix of already-decided bits, which comparator index is selected and whether
// it is inverted. Output lines: "MAP level prefix_bits index inverted". Research (R3).
`timescale 1ns/1ps
module tb_tree_probe;
  logic        p7, p6;
  logic [0:1]  p5;  logic [0:3]  p4;  logic [0:7]  p3;
  logic [0:15] p2;  logic [0:15] p1;  logic [0:7]  p0;
  logic [7:0]  result;
  gaussianSimplified8 dut (p7, p6, p5, p4, p3, p2, p1, p0, result);

  // set a whole level to a constant (0/1) or to a one-hot at index m (-1 = none)
  task automatic set_level(int lvl, bit all, int onehot);
    case (lvl)
      7: p7 = (onehot == 0) ? 1'b1 : all;
      6: p6 = (onehot == 0) ? 1'b1 : all;
      5: begin p5 = {2{all}};  if (onehot >= 0) p5[onehot] = 1'b1; end
      4: begin p4 = {4{all}};  if (onehot >= 0) p4[onehot] = 1'b1; end
      3: begin p3 = {8{all}};  if (onehot >= 0) p3[onehot] = 1'b1; end
      2: begin p2 = {16{all}}; if (onehot >= 0) p2[onehot] = 1'b1; end
      1: begin p1 = {16{all}}; if (onehot >= 0) p1[onehot] = 1'b1; end
      0: begin p0 = {8{all}};  if (onehot >= 0) p0[onehot] = 1'b1; end
    endcase
  endtask
  function automatic int width(int lvl);
    case (lvl) 7,6: return 1; 5: return 2; 4: return 4; 3: return 8; 2,1: return 16; default: return 8; endcase
  endfunction

  // bits of result: result = {~bit7, bit6..bit0}; internal bit7 = ~result[7]
  function automatic bit tbit(int k); return (k == 7) ? ~result[7] : result[k]; endfunction

  int lvl, nup, c, prefix, m, u, d;
  bit base;
  initial begin
    for (lvl = 6; lvl >= 0; lvl--) begin
      nup = 7 - lvl;                             // levels above: 7 .. lvl+1
      for (c = 0; c < (1 << nup); c++) begin
        // force upper levels to all-0 / all-1 per combination c; lower levels all-0
        for (u = 7; u > lvl; u--) set_level(u, c[7 - u], -1);
        for (d = lvl; d >= 0; d--) set_level(d, 1'b0, -1);
        #1; prefix = 0; for (u = 7; u > lvl; u--) prefix = (prefix << 1) | tbit(u);
        base = tbit(lvl);
        for (m = 0; m < width(lvl); m++) begin
          set_level(lvl, 1'b0, m); #1;
          if (tbit(lvl) != base) $display("MAP %0d %0d %0d %0d", lvl, prefix, m, base);
        end
      end
    end
    $finish;
  end
endmodule
