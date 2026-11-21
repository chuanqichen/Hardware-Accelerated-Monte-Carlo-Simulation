`timescale 1ns/1ps
module tb_accumulator_tree;
  parameter int LANES=4, SUM_WIDTH=32;
  localparam int LEVELS=$clog2(LANES);
  logic clk=0, rst_n=0, clear=0;
  logic [LANES-1:0] p_valid='0, sat_x='0, sat_s='0;
  logic [LANES-1:0][21:0] p='0;
  logic [SUM_WIDTH-1:0] payoff_sum;
  logic [31:0] trial_count;
  logic acc_overflow, sat_x_seen, sat_s_seen;
  accumulator #(.LANES(LANES),.SUM_WIDTH(SUM_WIDTH),.REGISTER_TREE(1)) dut (.*);
  always #5 clk=~clk;
  longint unsigned pending_sum[LEVELS], expected_sum=0, beat_sum;
  int pending_count[LEVELS], expected_count=0, beat_count, checked=0;
  bit pending_sx[LEVELS], pending_ss[LEVELS], expected_sx=0, expected_ss=0, expected_ovf=0;
  bit saw_overflow=0, beat_sx, beat_ss;
  always @(posedge clk) begin
    if (!rst_n || clear) begin
      expected_sum=0; expected_count=0; expected_sx=0; expected_ss=0; expected_ovf=0;
      for (int j=0;j<LEVELS;j++) begin
        pending_sum[j]=0; pending_count[j]=0; pending_sx[j]=0; pending_ss[j]=0;
      end
    end else begin
      expected_sum+=pending_sum[LEVELS-1];
      expected_ovf |= (expected_sum >> SUM_WIDTH) != 0;
      expected_sum &= (64'b1 << SUM_WIDTH)-1;
      expected_count+=pending_count[LEVELS-1];
      expected_sx |= pending_sx[LEVELS-1]; expected_ss |= pending_ss[LEVELS-1];
      for (int j=LEVELS-1;j>0;j--) begin
        pending_sum[j]=pending_sum[j-1]; pending_count[j]=pending_count[j-1];
        pending_sx[j]=pending_sx[j-1]; pending_ss[j]=pending_ss[j-1];
      end
      beat_sum=0; beat_count=0; beat_sx=0; beat_ss=0;
      for (int lane=0;lane<LANES;lane++) if (p_valid[lane]) begin
        beat_sum+=p[lane]; beat_count++;
        beat_sx |= sat_x[lane]; beat_ss |= sat_s[lane];
      end
      pending_sum[0]=beat_sum; pending_count[0]=beat_count;
      pending_sx[0]=beat_sx; pending_ss[0]=beat_ss;
    end
    #1;
    if (payoff_sum !== expected_sum[SUM_WIDTH-1:0] || trial_count !== expected_count ||
        {acc_overflow,sat_x_seen,sat_s_seen} !== {expected_ovf,expected_sx,expected_ss})
      $fatal(1,"tree L=%0d cycle=%0d got %h/%0d/%b expected %h/%0d/%b",LANES,checked,
             payoff_sum,trial_count,{acc_overflow,sat_x_seen,sat_s_seen},
             expected_sum,expected_count,{expected_ovf,expected_sx,expected_ss});
    saw_overflow |= acc_overflow;
    checked++;
  end
  initial begin
    repeat (2) @(negedge clk); rst_n=1;
    for (int i=0;i<1100;i++) begin
      // Exercise every mask, including holes; invalid flags/data must be ignored.
      p_valid=LANES'(i < 64 ? i : (i%7==0 ? 0 : (1<<LANES)-1));
      sat_x=~p_valid; sat_s=~p_valid;
      if (i==71) sat_x=p_valid;
      if (i==83) sat_s=p_valid;
      for (int lane=0;lane<LANES;lane++) p[lane]=22'h3fffff;
      clear=(i==17 || i==42);
      @(negedge clk);
    end
    clear=1; @(negedge clk); clear=0; p_valid=0;
    repeat (LEVELS+3) @(negedge clk);
    if (!saw_overflow || payoff_sum || trial_count || acc_overflow || sat_x_seen || sat_s_seen)
      $fatal(1,"overflow/clear coverage failed");
    $display("PASS: tb_accumulator_tree L=%0d cycles=%0d, masks bubbles clear overflow",LANES,checked);
    $finish;
  end
endmodule
