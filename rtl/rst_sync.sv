// rst_sync: asynchronous-assert, synchronous-de-assert reset synchronizer.
//
// Spec D-2: every block uses `always_ff @(posedge clk or negedge rst_n)`. The
// assertion edge of the external reset may arrive at any time and must reach the
// flops without a clock; the de-assertion edge must be aligned to clk so that no
// flop leaves reset in a different cycle from its neighbours (recovery/removal).
// This module produces that aligned de-assertion. mc_top instantiates one and
// drives every block's rst_n from rst_sync_n; blocks never see the raw pin.
//
//   rst_in_n  0 -> rst_sync_n falls immediately (asynchronous)
//   rst_in_n  1 -> rst_sync_n rises STAGES clock edges later (synchronous)
//
// Constraints (constraints/lane_5ns.sdc): rst_n is timed as a normal input so DC
// and PT check the DFFSR recovery/removal arcs on every block.
module rst_sync #(
  parameter int STAGES = 2
) (
  input  logic clk,
  input  logic rst_in_n,
  output logic rst_sync_n
);
  logic [STAGES-1:0] chain;

  always_ff @(posedge clk or negedge rst_in_n) begin
    if (!rst_in_n) chain <= '0;
    else           chain <= {chain[STAGES-2:0], 1'b1};
  end

  assign rst_sync_n = chain[STAGES-1];
endmodule
