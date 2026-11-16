set out [file dirname [info script]]
proc main {} {
 global out
 open_checkpoint {D:/Weiwen Li/AXU5EV/Issue40_PWM_Cut_Handoff/pwm_adc_routed.dcp}
 set f [open $out/physical_cone.txt w]
 foreach name {design_1_i/adc_observer_0/auto_inhibit_o design_1_i/adc_observer_0/inst/auto_inhibit_o design_1_i/pwm_control_0/auto_inhibit_i design_1_i/pwm_control_0/inst/auto_inhibit_i {design_1_i/pwm_control_0/debug_o[35]}} {
 puts $f "BOUNDARY $name"
 set p [get_pins -quiet $name]
 puts $f "PINS $p"
 if {[llength $p]==0} {continue}
 set n [get_nets -segments -of_objects $p]
 puts $f "SEGMENTS $n"
 set leaves [get_pins -leaf -of_objects $n]
 puts $f "LEAF_PINS $leaves"
 set cs [get_cells -of_objects $leaves]
 foreach c $cs {
 puts $f [report_property -return_string $c]
 foreach q [get_pins -of_objects $c] {puts $f "CELL_PIN $q DIR=[get_property DIRECTION $q] NET=[get_nets -segments -of_objects $q]"}
 }
 }
 close $f
 set f [open $out/probe_status.txt w];puts $f COMPLETED_READ_ONLY_TARGETED_QUERY;close $f
}
if {[catch {main} msg opts]} {set f [open $out/probe_status.txt w];puts $f "FAILED $msg
[dict get $opts -errorinfo]";close $f;exit 1}
exit 0
