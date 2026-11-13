set out [file dirname [info script]]
proc emit {name text} {global out; set f [open [file join $out $name] w]; puts $f $text; close $f}
proc main {} {
 global out
 open_checkpoint {D:/Weiwen Li/AXU5EV/Issue40_PWM_Cut_Handoff/pwm_adc_routed.dcp}
 emit write_verilog_help.txt [help write_verilog]
 emit write_sdf_help.txt [help write_sdf]
 set target {design_1_i/pwm_control_0/inst}
 set c [get_cells -quiet $target]
 if {[llength $c]!=1} {error "Expected exact cut not found: $target"}
 emit cut_properties.txt [report_property -return_string $c]
 set f [open [file join $out pins.tsv] w]
 foreach p [get_pins -of_objects $c] {puts $f "[get_property NAME $p]	[get_property DIRECTION $p]	[get_property REF_PIN_NAME $p]	[get_nets -quiet -of_objects $p]"}
 close $f
 set all [get_cells -hierarchical -filter {IS_PRIMITIVE == 1}]
 set cut [get_cells -hierarchical -filter "IS_PRIMITIVE == 1 && NAME =~ $target/*"]
 emit counts.txt "full_primitives=[llength $all]
cut_primitives=[llength $cut]"
 set f [open [file join $out cut_cells.tsv] w]
 foreach x $cut {puts $f "[get_property NAME $x]	[get_property REF_NAME $x]"}
 close $f
 set f [open [file join $out clocks.txt] w]
 foreach x [get_clocks] {puts $f [report_property -return_string $x]}
 close $f
 write_verilog -mode timesim -cell $target -sdf_anno false -rename_top pwm_cut [file join $out pwm_cut.v]
 write_sdf -cell $target -process_corner slow -rename_top pwm_cut [file join $out pwm_cut_slow.sdf]
 write_sdf -cell $target -process_corner fast -rename_top pwm_cut [file join $out pwm_cut_fast.sdf]
 emit export_status.txt EXPORT_COMPLETED_REQUIRES_REVIEW
}
if {[catch {main} msg opts]} {emit export_status.txt "FAILED
$msg
[dict get $opts -errorinfo]"; puts stderr $msg; exit 1}
exit 0
