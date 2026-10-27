// exp2_unit: x (Q5.12) -> S_T = e^x (UQ14.8) by range reduction.
//
// Bit-accurate reference: model/price_dp.py exp_fx(). The 2^f table is
// generated into rtl/generated/exp2_rom.sv (regenerate when EXP_ADDR_BITS changes).
//
//   S3  y    = x * LOG2E                 e^x = 2^y; y has 12 + 16 = 28 fraction bits
//       n    = y >>> 28                  floor(y): the power of two (shift amount)
//       addr = y[27 -: EXP_ADDR_BITS]    top bits of frac(y): which 2^f cell
//   S4  rom  = 2^((addr + 0.5) / 2^k)    UQ1.16, in [1, 2)
//   S5  n >= 14       -> S_T = max, sat_s (2^14 does not fit UQ14.8)
//       8 <= n <= 13  -> S_T = rom << (n - 8)              exact
//       n <  8        -> S_T = round_even(rom >> (8 - n))  shift capped at 18 (-> 0)
//
// Latency LAT_EXP = 3, one result per cycle. Data registers load only when
// their stage is valid (clock-gating friendly) and are not reset.
module exp2_unit #(
  parameter int EXP_ADDR_BITS = 10
) (
  input  logic               clk,
  input  logic               rst_n,
  input  logic               in_valid,
  input  logic signed [17:0] x,
  output logic               out_valid,
  output logic        [21:0] s_t,
  output logic               sat_s
);
  localparam int LAT_EXP    = 3;
  localparam int Y_FRAC     = 28;                 // 12 (x) + 16 (LOG2E)
  localparam logic [16:0] LOG2E = 17'd94548;      // round(log2(e) * 2^16), see PriceDpConfig.log2e
  localparam int ST_MAX_N   = 14;
  localparam int MAX_RSH    = 18;                 // rom < 2^17: any shift >= 18 rounds to 0

  // ---- S3: change of base and split into integer / fraction -----------------
  logic signed [35:0] y;
  logic signed [7:0]  n3;
  logic [EXP_ADDR_BITS-1:0] addr3;
  logic v3;
  assign y = x * $signed({1'b0, LOG2E});

  always_ff @(posedge clk) if (in_valid) begin
    n3    <= y[35:Y_FRAC];                          // arithmetic: top bits of y = floor(y)
    addr3 <= y[Y_FRAC-1 -: EXP_ADDR_BITS];
  end

  // ---- S4: 2^f table -----------------------------------------------------------
  logic [16:0] rom_val, rom4;
  logic signed [7:0] n4;
  logic v4;
  exp2_rom #(.ADDR_BITS(EXP_ADDR_BITS), .OUT_WIDTH(17)) u_rom (.addr(addr3), .val(rom_val));

  always_ff @(posedge clk) if (v3) begin
    rom4 <= rom_val;
    n4   <= n3;
  end

  // ---- S5: multiply by 2^n (barrel shift), round to UQ14.8, clamp ----------------
  logic [21:0] st5;
  logic        sat5;
  always_comb begin
    int rsh;
    logic [MAX_RSH:0] q, rem, half;   // half reaches 2^17 at rsh = 18: needs 19 bits
    logic up;
    sat5 = 1'b0;
    st5  = '0;
    if (n4 >= ST_MAX_N) begin
      st5  = '1;
      sat5 = 1'b1;
    end else if (n4 >= 8) begin
      st5 = 22'(rom4) << (n4 - 8);
    end else begin
      rsh  = (8 - n4 > MAX_RSH) ? MAX_RSH : 8 - n4;
      q    = (MAX_RSH+1)'(rom4) >> rsh;
      rem  = (MAX_RSH+1)'(rom4) & ((MAX_RSH+1)'(1) << rsh) - 1'b1;
      half = (MAX_RSH+1)'(1) << (rsh - 1);
      up   = (rem > half) || (rem == half && q[0]);
      st5  = 22'(q) + 22'(up);
    end
  end

  always_ff @(posedge clk) if (v4) begin
    s_t   <= st5;
    sat_s <= sat5;
  end

  // ---- valid travels beside the data ------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) {v3, v4, out_valid} <= '0;
    else        {v3, v4, out_valid} <= {in_valid, v3, v4};
  end
endmodule
