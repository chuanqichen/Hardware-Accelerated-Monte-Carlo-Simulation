// Optional waveform dump. Compile this module alongside any testbench (VCS picks it
// up as a second top) and run with +vcd=<file> to write a VCD of the whole design.
// No testbench needs to change. Used by scripts/sim/dump_waves.sh for the
// documentation figures (scripts/plot_waves.py renders them).
module vcd_dump;
  string path;
  initial begin
    if ($value$plusargs("vcd=%s", path)) begin
      $dumpfile(path);
      $dumpvars;
    end
  end
endmodule
