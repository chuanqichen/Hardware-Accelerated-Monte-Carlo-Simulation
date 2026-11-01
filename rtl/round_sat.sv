// round_sat: the lane's one narrowing operator. Drops SHIFT fraction bits with
// round-half-to-even, then saturates to OUT_WIDTH bits and flags it.
//
// Bit-accurate reference: model/fxp.py round_sat() (= round_shift_even() followed
// by Fxp.saturate()). Lane_Interface_Spec.md Sec. 2 and Gaussian_Lookup_Work_Plan.md
// Sec. 4.2: every narrowing in the lane goes through this module; silent truncation
// and wrap-around are prohibited.
//
//   q       = floor(in / 2^SHIFT)                 arithmetic shift: floors for in < 0 too
//   rem     = in mod 2^SHIFT                      the dropped bits
//   up      = rem > half | (rem == half & q[0])   round half to even (ties -> even q)
//   rounded = q + up
//   out     = clip(rounded, MIN, MAX)
//   sat     = rounded < MIN | rounded > MAX
//
// Saturation is checked AFTER rounding: a value just under MAX can round up past it.
//
// Combinational, no clock or valid: the consumer places the register (price_dp S2
// registers the output; DC retiming may move it). SIGNED selects two's-complement
// (Q) or unsigned (UQ) interpretation of both in and out. SHIFT = 0 is a pure
// saturate.
//
// Instances:
//   price_dp S2   acc Q5.26 (34 b) -> x Q5.12 (18 b)   IN_WIDTH=34 OUT_WIDTH=18 SHIFT=14 SIGNED=1

module round_sat #(
  parameter int IN_WIDTH  = 34,
  parameter int OUT_WIDTH = 18,
  parameter int SHIFT     = 14,
  parameter bit SIGNED    = 1
) (
  input  logic [IN_WIDTH-1:0]  in,
  output logic [OUT_WIDTH-1:0] out,
  output logic                 sat
);
  if (SHIFT < 0 || SHIFT >= IN_WIDTH) $error("round_sat: SHIFT must be in [0, IN_WIDTH)");
  if (OUT_WIDTH < 1)                  $error("round_sat: OUT_WIDTH must be >= 1");

  // Compare width: holds floor(in / 2^SHIFT) plus the round-up carry plus a sign
  // bit (QW: the compare is signed even when SIGNED = 0, so an unsigned magnitude
  // that uses all IN_WIDTH-SHIFT+1 bits must not land in the sign position), and
  // holds MIN/MAX with one bit of headroom (OUT_WIDTH + 1), whichever is larger.
  localparam int QW = IN_WIDTH - SHIFT + 2;
  localparam int CW = (QW > OUT_WIDTH + 1) ? QW : OUT_WIDTH + 1;

  localparam logic signed [CW-1:0] ONE = 1;
  localparam logic signed [CW-1:0] MAX = SIGNED ? (ONE <<< (OUT_WIDTH - 1)) - ONE
                                                : (ONE <<< OUT_WIDTH) - ONE;
  localparam logic signed [CW-1:0] MIN = SIGNED ? -(ONE <<< (OUT_WIDTH - 1)) : '0;

  logic signed [CW-1:0] q, rounded;
  logic                 up;

  // ---- floor(in / 2^SHIFT), resized to CW bits ----------------------------------
  // Extend to EW >= max(IN_WIDTH, CW) BEFORE shifting. CW is usually narrower than
  // IN_WIDTH, so casting `in` to CW first would truncate the high input bits.
  localparam int EW = (IN_WIDTH > CW) ? IN_WIDTH : CW;
  logic signed [EW-1:0] in_ext, sh;
  if (SIGNED) begin : g_signed
    assign in_ext = EW'($signed(in));        // sign-extend (EW >= IN_WIDTH: never truncates)
    assign sh     = in_ext >>> SHIFT;        // arithmetic shift = floor, also for in < 0
  end else begin : g_unsigned
    assign in_ext = EW'(in);                 // zero-extend
    assign sh     = in_ext >> SHIFT;
  end
  assign q = sh[CW-1:0];                     // value fits in IN_WIDTH-SHIFT+1 <= CW bits

  // ---- round half to even on the dropped bits -----------------------------------
  if (SHIFT > 0) begin : g_round
    localparam logic [SHIFT-1:0] HALF = SHIFT'(1) << (SHIFT - 1);
    logic [SHIFT-1:0] rem;
    assign rem = in[SHIFT-1:0];
    assign up  = (rem > HALF) | ((rem == HALF) & q[0]);
  end else begin : g_noround
    assign up = 1'b0;
  end
  assign rounded = q + $signed(CW'(up));

  // ---- saturate -------------------------------------------------------------------
  logic over, under;
  assign over  = rounded > MAX;
  assign under = rounded < MIN;
  assign sat   = over | under;
  assign out   = over  ? MAX[OUT_WIDTH-1:0]
               : under ? MIN[OUT_WIDTH-1:0]
               :         rounded[OUT_WIDTH-1:0];
endmodule
