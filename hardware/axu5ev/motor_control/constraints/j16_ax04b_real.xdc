# J16-MBDL4 V0.3 pin_connections.csv, J16 3...18, cross-checked against
# hardware/axu5ev/PL_IO_RESOURCE_MAP.csv and production schematic/assembly.
# Pins are 3.3 V on the AXU5EVB-E side. Board electrical validation is pending.
foreach {port pin} {
    j16_pwm_h_o[0] B10 j16_pwm_l_o[0] C11
    j16_pwm_h_o[1] F10 j16_pwm_l_o[1] G11
    j16_pwm_h_o[2] C12 j16_pwm_l_o[2] D12
    j16_relcon_o A11 j16_encon_o A12 j16_f_reset_n_o F11
    j16_qepa_i F12 j16_qepb_i E13 j16_qepz_i E14
    j16_erri_n_i A13 j16_erru_n_i B13
    j16_pwm_enable_o A14 j16_ctrl_enable_o B14
} {
    set_property -dict [list PACKAGE_PIN $pin IOSTANDARD LVCMOS33] [get_ports $port]
}
set j16_outputs [get_ports {j16_pwm_h_o[*] j16_pwm_l_o[*] j16_relcon_o
    j16_encon_o j16_f_reset_n_o j16_pwm_enable_o j16_ctrl_enable_o}]
set_property SLEW SLOW $j16_outputs
set_property DRIVE 8 $j16_outputs
# Feedback from the translator is asynchronous. Its first synchronizer input
# has no external source-clock contract. Keep stage 1 -> stage 2 timed.
set qep_first [get_pins -quiet -hierarchical -regexp {.*encoder[.]receiver/sync1_reg\[[012]\]/D}]
set fault_first [get_pins -quiet -hierarchical -regexp {.*ax04b_live[.]err[ui]_sync_reg\[0\]/D}]
if {[llength $qep_first] != 3 || [llength $fault_first] != 2} {
    error "AX04B REAL expected three ABZ and two fault synchronizer D pins"
}
set_false_path -from [get_ports {j16_qepa_i j16_qepb_i j16_qepz_i}] -to $qep_first
set_false_path -from [get_ports {j16_erri_n_i j16_erru_n_i}] -to $fault_first
# Raw ERRI_n/ERRU_n also assert a dedicated asynchronous inhibit path. Do not
# blanket-false-path these ports. Output timing at the MBDL4 and enable/pulse
# behavior are B6 measurements, with the motion outputs hard-vetoed in AX04B.
