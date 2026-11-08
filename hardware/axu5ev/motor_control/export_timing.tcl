# Read the full adopted routed design; preserve clock trees and inter-cell nets.
if {$argc!=1} {error "newly built hardware output required"}
set out [file normalize [lindex $argv 0]]
if {[file exists $out/timing_pl]} {error "timing_pl exists; preserve previous export"}
open_checkpoint $out/pwm_adc_routed.dcp
# PG172: ILA simulation is not supported. Only debug IP is black-boxed in
# this in-memory simulation view; do not save over the routed checkpoint.
# No synthesis, placement or rerouting is performed. Full-design STA and
# bit/XSA retain the actual ILA/debug hub. Functional clock/AXI nets remain.
set debug_cells [get_cells {design_1_i/pwm_ila dbg_hub}]
if {[llength $debug_cells]!=2} {error "expected exact debug-only boundary"}
update_design -cells $debug_cells -black_box
file mkdir $out/timing_pl
write_verilog -mode timesim -sdf_anno false -rename_top motor_routed $out/timing_pl/motor_routed.v
foreach corner {slow fast} {
    write_sdf -process_corner $corner -rename_top motor_routed $out/timing_pl/motor_${corner}.sdf
}
puts "PWM_ADC_SDF_EXPORT_PASS"
