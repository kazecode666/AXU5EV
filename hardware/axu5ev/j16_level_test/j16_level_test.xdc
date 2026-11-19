# J16-MBDL4 V0.3 and AXU5EVB-E J16. J16.2 (+5 V) has no logic port.
# J16.3 through J16.12, Bank 45 (3.3 V).
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVCMOS33} [get_ports PWM1]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports PWM2]
set_property -dict {PACKAGE_PIN F10 IOSTANDARD LVCMOS33} [get_ports PWM3]
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS33} [get_ports PWM4]
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports PWM5]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports PWM6]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports RELCON]
set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVCMOS33} [get_ports ENCON]
set_property -dict {PACKAGE_PIN F11 IOSTANDARD LVCMOS33} [get_ports F_Reset]
set_property -dict {PACKAGE_PIN F12 IOSTANDARD LVCMOS33} [get_ports QEPA]

# J16.13 through J16.18, Bank 46 (3.3 V).
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports QEPB]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports QEPZ]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports ERRI]
set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33} [get_ports ERRU]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports PWM_EN]
set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS33} [get_ports CTRL_EN]

set j16_outputs [get_ports {PWM1 PWM2 PWM3 PWM4 PWM5 PWM6 RELCON ENCON F_Reset PWM_EN CTRL_EN}]
set_property DRIVE 8 $j16_outputs
set_property SLEW SLOW $j16_outputs

# The meter supplies no external timing reference for the static outputs.
set_false_path -to $j16_outputs
