# Read the full adopted routed design; preserve clock trees and inter-cell nets.
if {$argc!=1} {error "newly built hardware output required"}
set out [file normalize [lindex $argv 0]]
if {[file exists $out/timing_full]} {error "timing_full exists; preserve previous export"}
open_checkpoint $out/pwm_adc_routed.dcp
file mkdir $out/timing_full
write_verilog -mode timesim -sdf_anno false -rename_top motor_routed $out/timing_full/motor_routed.v
foreach corner {slow fast} {
    write_sdf -process_corner $corner -rename_top motor_routed $out/timing_full/motor_${corner}.sdf
}
puts "PWM_ADC_SDF_EXPORT_PASS"
