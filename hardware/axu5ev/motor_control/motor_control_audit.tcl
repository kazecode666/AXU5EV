# Read-only directed audit of the routed automatic ADC/QEP/FOC/PWM candidate.
# Usage: DCP NEW_OUT ORIGINAL_ADC_XDC. No candidate or constraint writes.
if {$argc!=3} {error "Expected routed DCP, new audit directory and ADC XDC"}
set checkpoint [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
set xdc [file normalize [lindex $argv 2]]
if {[file exists $out]} {error "Choose an unoccupied audit output directory"}
file mkdir $out
open_checkpoint $checkpoint
foreach delay {max min} {
 set worst [get_timing_paths -delay_type $delay -max_paths 1 -no_report_unconstrained]
 if {[llength $worst]!=1 || [get_property SLACK $worst]<0} {error "Global routed $delay timing failed"}
}
set allregs [get_cells -hier -filter {IS_SEQUENTIAL == 1}]
set summary [open $out/paths.tsv w]
puts $summary "group\tretained_sequential_cells\tmax_paths_checked\tmax_slack_ns\tmin_slack_ns"
# Full global STA checks every endpoint. These ten worst paths per direction
# independently confirm the new retained groups and the falling-edge boundary.
foreach {group pattern} {
 frozen_foc_inputs {*controller*foc_*_reg*}
 falling_foc_input_hold {*controller*foc/*_h_reg*}
 original_foc {*controller*foc/core/*}
 generated_duty_mapper {*controller*duty_mapper*}
 compare_offer {*controller*auto_compare_reg*}
 generated_current {*generated_current*}
 generated_angle {*generated_angle*}
 sample_metadata {*sample_encoder_reg*}
 seven_event_metadata {*meta_pipe_reg*}
 pair_metadata {*pair_meta_reg*}
 current_join {*current_frame_reg*}
 theta_join {*theta_frame_reg*}
 snapshot_latest {*snapshot*latest_payload_reg*}
 snapshot_frozen {*snapshot*frozen_payload_reg*}
 pwm_auto_release {*pwm_control_0*auto_release_reg*}
 pwm_related_triplet {*pwm_control_0*pending_compare_reg*}
} {
 set regs [filter $allregs "NAME =~ $pattern"]
 if {[llength $regs]==0} {error "Missing retained automatic functional group $group"}
 foreach delay {max min} {
  set paths [get_timing_paths -to $regs -delay_type $delay -max_paths 10 -nworst 1 -no_report_unconstrained]
  if {[llength $paths]==0} {error "No constrained $group $delay paths"}
  set slack($delay) 1e9
  foreach p $paths {
   set value [get_property SLACK $p]
   if {$value<0} {error "Negative $group $delay slack: $value"}
   if {$value<$slack($delay)} {set slack($delay) $value}
  }
  report_timing -to $regs -delay_type $delay -max_paths 10 -path_type full_clock_expanded -file $out/${group}_${delay}.rpt
 }
 puts $summary "$group\t[llength $regs]\t[llength $paths]\t$slack(max)\t$slack(min)"
}
close $summary
set holds [filter $allregs {NAME =~ *controller*foc/*_h_reg*}]
set cores [filter $allregs {NAME =~ *controller*foc/core/*}]
foreach delay {max min} {
 set paths [get_timing_paths -from $holds -to $cores -delay_type $delay -max_paths 10 -no_report_unconstrained]
 if {[llength $paths]==0} {error "Missing falling-edge hold to original FOC $delay path"}
 foreach p $paths {if {[get_property SLACK $p]<0} {error "Falling-edge hold to FOC $delay failed"}}
 report_timing -from $holds -to $cores -delay_type $delay -max_paths 10 -path_type full_clock_expanded -file $out/falling_hold_to_core_${delay}.rpt
}
set syncs [filter $allregs {NAME =~ *encoder*receiver*sync?_reg*}]
if {[llength $syncs]!=6} {error "Expected six retained original ABZ synchronizer registers"}
set f [open $out/abz_synchronizers.tsv w]
foreach c $syncs {
 if {![get_property ASYNC_REG $c]} {error "ABZ ASYNC_REG missing: $c"}
 puts $f "$c\tASYNC_REG=TRUE"
}
close $f
set f [open $xdc r];set constraints [read $f];close $f
set f [open $out/adc_pins.tsv w];set pins 0
foreach line [split $constraints "\n"] {
 if {[regexp {^set_property PACKAGE_PIN ([A-Z0-9]+) \[get_ports \{([^\}]+)\}\]} $line -> expected name]} {
  set port [get_ports -quiet $name]
  if {[llength $port]!=1 || [get_property PACKAGE_PIN $port] ne $expected || [get_property IOSTANDARD $port] ne "LVCMOS33"} {error "ADC IO mismatch: $name"}
  puts $f "$name\t$expected\tLVCMOS33";incr pins
 }
}
close $f
if {$pins!=28} {error "Expected 28 original ADC pins"}
set inputs [get_ports {adc_data_* adc_otr_*}]
if {[llength $inputs]!=26} {error "Expected 26 ADC input bits"}
set f [open $out/adc_delay.tsv w]
foreach port $inputs {
 foreach {delay expected} {min 2.0 max 10.0} {
  set text [report_timing -from $port -delay_type $delay -max_paths 1 -return_string]
  if {![regexp {Input Delay:\s+([-0-9.]+)ns} $text -> observed] || abs($observed-$expected)>0.000001} {error "ADC budget changed: $port $delay"}
  set path [get_timing_paths -from $port -delay_type $delay -max_paths 1 -no_report_unconstrained]
  if {[llength $path]!=1 || [get_property SLACK $path]<0} {error "ADC input timing failed: $port $delay"}
  puts $f "$port\t$delay\t$observed\t[get_property SLACK $path]"
 }
}
close $f
set pwm [get_clocks -of_objects [get_pins design_1_i/pwm_control_0/pwm_clk]]
set adc [get_clocks -of_objects [get_pins design_1_i/adc_observer_0/s_axi_aclk]]
if {[llength $pwm]!=1 || [llength $adc]!=1 || abs([get_property PERIOD $adc]/[get_property PERIOD $pwm]-2.0)>0.000001} {error "Expected related 50/100MHz clocks"}
foreach direction {forward reverse} {
 if {$direction eq "forward"} {set from $adc;set to $pwm} else {set from $pwm;set to $adc}
 foreach delay {min max} {
  set paths [get_timing_paths -from $from -to $to -delay_type $delay -max_paths 10]
  if {[llength $paths]==0} {error "Missing $direction $delay clock paths"}
  foreach p $paths {if {[get_property SLACK $p]<0} {error "Related clock failure $direction $delay"}}
  report_timing -from $from -to $to -delay_type $delay -max_paths 10 -path_type full_clock_expanded -file $out/related_${direction}_${delay}.rpt
 }
}
# Explicit new cancellation recovery/removal coverage: ADC-domain inhibit to
# falling PWM-edge release, then falling release to positive-edge PWM state.
set auto_release [filter $allregs {NAME =~ *pwm_control_0*auto_release_reg*}]
set release_clear [get_pins -of_objects $auto_release -filter {REF_PIN_NAME == CLR}]
set pwm_regs [filter $allregs {NAME =~ *pwm_control_0*}]
set pwm_async [get_pins -of_objects $pwm_regs -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]
foreach direction {inhibit_to_release release_to_pwm} {
 if {$direction eq "inhibit_to_release"} {set from $adc;set to $release_clear} else {set from $auto_release;set to $pwm_async}
 foreach delay {max min} {
  set paths [get_timing_paths -from $from -to $to -delay_type $delay -max_paths 10 -no_report_unconstrained]
  if {[llength $paths]==0} {error "Missing automatic $direction $delay recovery/removal path"}
  foreach p $paths {if {[get_property SLACK $p]<0} {error "Automatic $direction $delay recovery/removal failed"}}
  report_timing -from $from -to $to -delay_type $delay -max_paths 10 -path_type full_clock_expanded -file $out/${direction}_${delay}.rpt
 }
}
report_timing -to [get_pins -hier -filter {REF_PIN_NAME =~ CLR || REF_PIN_NAME =~ PRE}] -delay_type min_max -max_paths 20 -path_type full_clock_expanded -file $out/reset_recovery_removal.rpt
report_timing_summary -delay_type min_max -check_timing_verbose -file $out/timing_summary.rpt
report_pulse_width -all_violators -file $out/pulse_width.rpt
check_timing -verbose -file $out/check_timing.rpt
report_utilization -file $out/utilization.rpt
report_utilization -hierarchical -hierarchical_depth 6 -file $out/utilization_hierarchy.rpt
report_cdc -details -file $out/cdc.rpt
report_methodology -file $out/methodology.rpt
report_drc -file $out/drc.rpt
report_clocks -file $out/clocks.rpt
report_exceptions -file $out/exceptions.rpt
write_xdc $out/expanded_constraints.xdc
puts "MOTOR_ROUTED_AUDIT_PASS pins=$pins inputs=[llength $inputs]"
close_design
exit
