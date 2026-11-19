# J16-MBDL4 V0.3 pin_connections.csv, J16 3...18, cross-checked against
# hardware/axu5ev/PL_IO_RESOURCE_MAP.csv and production schematic/assembly.
# Pins are 3.3 V on the AXU5EVB-E side. Board electrical validation is pending.
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVCMOS33} [get_ports {j16_pwm_h_o[0]}]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {j16_pwm_l_o[0]}]
set_property -dict {PACKAGE_PIN F10 IOSTANDARD LVCMOS33} [get_ports {j16_pwm_h_o[1]}]
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS33} [get_ports {j16_pwm_l_o[1]}]
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports {j16_pwm_h_o[2]}]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {j16_pwm_l_o[2]}]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {j16_relcon_o}]
set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVCMOS33} [get_ports {j16_encon_o}]
set_property -dict {PACKAGE_PIN F11 IOSTANDARD LVCMOS33} [get_ports {j16_f_reset_n_o}]
set_property -dict {PACKAGE_PIN F12 IOSTANDARD LVCMOS33} [get_ports {j16_qepa_i}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {j16_qepb_i}]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports {j16_qepz_i}]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports {j16_erri_n_i}]
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33} [get_ports {j16_erru_n_i}]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports {j16_pwm_enable_o}]
set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS33} [get_ports {j16_ctrl_enable_o}]
set j16_outputs [get_ports {j16_pwm_h_o[*] j16_pwm_l_o[*] j16_relcon_o
    j16_encon_o j16_f_reset_n_o j16_pwm_enable_o j16_ctrl_enable_o}]
set_property SLEW SLOW $j16_outputs
set_property DRIVE 8 $j16_outputs
