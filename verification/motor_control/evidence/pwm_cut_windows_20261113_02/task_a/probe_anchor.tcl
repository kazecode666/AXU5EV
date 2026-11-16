set out [file dirname [info script]]
proc save {name data} {global out;set f [open $out/$name w];puts $f $data;close $f}
proc main {} {
 global out
 open_checkpoint {D:/Weiwen Li/AXU5EV/Issue40_PWM_Cut_Handoff/pwm_adc_routed.dcp}
 save timing_help.txt [help report_timing]
 set pin [get_pins {design_1_i/pwm_control_0/inst/adc_anchor}]
 set nets [get_nets -segments -of_objects $pin]
 set drivers [get_pins -leaf -of_objects $nets -filter {DIRECTION == OUT}]
 set ep [get_cells {design_1_i/pwm_control_0/inst/pwm/timebase/anchor_delayed_reg}]
 set d [get_pins -of_objects $ep -filter {REF_PIN_NAME == D}]
 save endpoints.txt "cut_pin=$pin
nets=$nets
drivers=$drivers
endpoint=$ep
data_pin=$d"
 if {[llength $drivers]!=1 || [llength $d]!=1} {error {Expected single native anchor driver and endpoint}}
 save driver_properties.txt [report_property -return_string [get_cells -of_objects $drivers]]
 save endpoint_properties.txt [report_property -return_string $ep]
 report_clocks -file $out/clock_relationships.rpt
 report_timing -from $drivers -to $d -delay_type min -max_paths 1 -path_type full_clock_expanded -file $out/anchor_min.rpt
 report_timing -from $drivers -to $d -delay_type max -max_paths 1 -path_type full_clock_expanded -file $out/anchor_max.rpt
 save probe_status.txt COMPLETED_READ_ONLY_TARGETED_QUERY
}
if {[catch {main} msg opts]} {save probe_status.txt "FAILED
$msg
[dict get $opts -errorinfo]";exit 1}
exit 0
