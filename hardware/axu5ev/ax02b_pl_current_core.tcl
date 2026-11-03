# Offline OOC FOC+frame implementation. args: candidate RTL directory, new output.
if {$argc!=2} {error "expected candidate-rtl new-output"}
set rtl [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
if {[file exists $out]} {error "output exists: $out"}
file mkdir $out
set root [file normalize [file join [file dirname [info script]] ../..]]
set part xczu5ev-sfvc784-2-i
if {[llength [get_parts -quiet $part]]!=1} {error "5EV target unavailable"}
set f [open $out/tool_target.txt w];puts $f "Vivado=[version -short]\npart=[get_parts $part]";close $f
set manifest [open $out/sources.txt w]
set files [list]
# Reuse only the accepted design list, never a TB/XSI glob. Package first;
# remaining modules sorted consistently with the qualified implementation.
set names [exec python -c {import json,sys;print("\n".join(x["path"] for x in json.load(open(sys.argv[1],encoding="utf-8"))["design_files"]))} $root/generated/legacy_m3_p3/manifest.json]
lappend files [file join $rtl FOC_DUT_pkg.sv]
foreach name [lsort [split $names \n]] {
 set name [string trim $name]
 if {$name ne "FOC_DUT_pkg.sv"} {lappend files [file join $rtl $name]}
}
lappend files $root/integration/rtl/axu5ev_foc_frame_top.sv
foreach file $files {puts $manifest $file;read_verilog -sv $file}
close $manifest
read_xdc $root/hardware/axu5ev/ax02b_pl_current_core_ooc.xdc
set_param general.maxThreads 8
synth_design -top axu5ev_foc_frame_top -part $part -mode out_of_context
write_checkpoint $out/synth.dcp
report_utilization -hierarchical -file $out/synth_utilization.rpt
opt_design
place_design
route_design
write_checkpoint $out/routed.dcp
report_utilization -file $out/utilization.rpt
report_utilization -hierarchical -file $out/utilization_hierarchical.rpt
report_clock_utilization -file $out/clock_utilization.rpt
report_route_status -file $out/route_status.rpt
report_drc -file $out/drc.rpt
check_timing -verbose -file $out/check_timing.rpt
report_exceptions -file $out/exceptions.rpt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file $out/timing_summary.rpt
report_pulse_width -all_violators -file $out/pulse_width.rpt
report_timing -delay_type max -max_paths 10 -path_type full_clock_expanded -file $out/setup.rpt
report_timing -delay_type min -max_paths 10 -path_type full_clock_expanded -file $out/hold.rpt
# Explicitly preserve the mixed-edge paths, without relaxing their 10ns budget.
set neg [get_cells -hier -regexp {.*(ia_h|ib_h|ic_h|iq_h|id_h|theta_h|omega_h|pi_h|vdc_h)_reg.*}]
if {[llength $neg]} {
 report_timing -from $neg -delay_type max -max_paths 5 -file $out/negedge_to_core.rpt
 report_timing -to $neg -delay_type max -max_paths 5 -file $out/to_negedge.rpt
}
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
set f [open $out/internal_slack.txt w]
puts $f "WNS=[get_property SLACK $setup]\nWHS=[get_property SLACK $hold]";close $f
if {[get_property SLACK $setup]<0 || [get_property SLACK $hold]<0} {error "internal timing violation; retain reports"}
puts "AX02B_ROUTE_COMPLETE_REVIEW_REPORTS $out"
