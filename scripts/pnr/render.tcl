# Run with xvfb-run -a innovus -files scripts/pnr/render.tcl (GUI enabled).
# PNR_DB is the saved mc_top.enc.dat directory; PNR_IMAGE is a fresh GIF path.
if {[catch {
  if {![file isdirectory $::env(PNR_DB)]} { error "Missing PNR_DB" }
  if {[file exists $::env(PNR_IMAGE)]} { error "Image already exists" }
  restoreDesign $::env(PNR_DB) mc_top
  win
  fit
  dumpToGIF $::env(PNR_IMAGE)
} reason]} {
  puts stderr "Layout rendering failed: $reason"
  exit 1
}
puts "LAYOUT_IMAGE_DONE $::env(PNR_IMAGE)"
exit 0
