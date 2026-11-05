# AX-03B2: AN9238 on J15 only, 3.3V CMOS. No J16 or power-control I/O.
# Sources: AN9238_UG Rev1.0 PDF p9-10; AXU5EVB-E manual PDF p42;
# ACU5EV schematic p4; vendor course_s2/24_ad9238_dma_dp ad9238.xdc.
# Port A = module CH1; port B = module CH2. CH1 pin order is NOT ascending.
# Pin1/GND, pin2/+5V, pin37-38/GND and pin39-40/+3.3V are not FPGA ports.
# Check actual module pin1 and unused pins39-40 before first powered insertion.

set_property PACKAGE_PIN AG11 [get_ports {adc_clk_b_o}]
set_property PACKAGE_PIN AF11 [get_ports {adc_data_b_i[0]}]
set_property PACKAGE_PIN AB14 [get_ports {adc_data_b_i[1]}]
set_property PACKAGE_PIN AB15 [get_ports {adc_data_b_i[2]}]
set_property PACKAGE_PIN W13 [get_ports {adc_data_b_i[3]}]
set_property PACKAGE_PIN W14 [get_ports {adc_data_b_i[4]}]
set_property PACKAGE_PIN W11 [get_ports {adc_data_b_i[5]}]
set_property PACKAGE_PIN W12 [get_ports {adc_data_b_i[6]}]
set_property PACKAGE_PIN Y10 [get_ports {adc_data_b_i[7]}]
set_property PACKAGE_PIN W10 [get_ports {adc_data_b_i[8]}]
set_property PACKAGE_PIN AB9 [get_ports {adc_data_b_i[9]}]
set_property PACKAGE_PIN AB10 [get_ports {adc_data_b_i[10]}]
set_property PACKAGE_PIN AH13 [get_ports {adc_data_b_i[11]}]
set_property PACKAGE_PIN AG13 [get_ports {adc_otr_b_i}]
set_property PACKAGE_PIN AE14 [get_ports {adc_data_a_i[1]}]
set_property PACKAGE_PIN AE15 [get_ports {adc_data_a_i[0]}]
set_property PACKAGE_PIN AD14 [get_ports {adc_data_a_i[3]}]
set_property PACKAGE_PIN AD15 [get_ports {adc_data_a_i[2]}]
set_property PACKAGE_PIN AC13 [get_ports {adc_data_a_i[5]}]
set_property PACKAGE_PIN AC14 [get_ports {adc_data_a_i[4]}]
set_property PACKAGE_PIN Y13 [get_ports {adc_data_a_i[7]}]
set_property PACKAGE_PIN Y14 [get_ports {adc_data_a_i[6]}]
set_property PACKAGE_PIN AH14 [get_ports {adc_data_a_i[9]}]
set_property PACKAGE_PIN AG14 [get_ports {adc_data_a_i[8]}]
set_property PACKAGE_PIN AC11 [get_ports {adc_data_a_i[11]}]
set_property PACKAGE_PIN AB11 [get_ports {adc_data_a_i[10]}]
set_property PACKAGE_PIN AD10 [get_ports {adc_clk_a_o}]
set_property PACKAGE_PIN AD11 [get_ports {adc_otr_a_i}]

set_property IOSTANDARD LVCMOS33 [get_ports {adc_data_a_i[*] adc_data_b_i[*] adc_otr_a_i adc_otr_b_i adc_clk_a_o adc_clk_b_o}]
set_property SLEW SLOW [get_ports {adc_clk_a_o adc_clk_b_o}]
set_property DRIVE 8 [get_ports {adc_clk_a_o adc_clk_b_o}]

# Base fabric clock is the PS-generated nominal 50MHz clock, constrained by
# the PS IP. These are real forwarded 5MHz clocks; both rise at phase0 and
# fall at phase5 of the common ten-cycle counter. Capture CE is phase4 (+80ns).
# Do not create an unrelated primary clock or false-path the return bus.
set adc_clock_source [get_pins -hier -filter {NAME =~ */adc_observer_0/s_axi_aclk}]
create_generated_clock -name an9238_clk_a -source $adc_clock_source -divide_by 10 [get_ports adc_clk_a_o]
create_generated_clock -name an9238_clk_b -source $adc_clock_source -divide_by 10 [get_ports adc_clk_b_o]

# ADI AD9238 Rev.D p6 Table4/Figure2: tPD min2ns/max6ns (5pF load),
# seven conversion-cycle latency. Source:
# https://www.analog.com/media/en/technical-documentation/data-sheets/AD9238.pdf
# External engineering budget (NOT measured): clock forward 0..2ns and data
# return 0..2ns for short 1:1 J15 insertion, including both PCB paths/connector.
# Therefore t_input_min=0+2+0=2ns; t_input_max=2+6+2=10ns, relative to the
# FPGA forwarded-clock port. Internal clock-output/input delays remain in STA.
# OTR uses this same budget as an engineering assumption; the datasheet does
# not separately guarantee an OTR tPD table. Observe OTR on first board test.
# No multicycle is applied: STA checks the earliest 50MHz capture edge (20ns),
# stricter than the implemented phase4 capture (80ns). Do not hide a failure.
set_input_delay -clock [get_clocks an9238_clk_a] -min 2.000 [get_ports {adc_data_a_i[*] adc_otr_a_i}]
set_input_delay -clock [get_clocks an9238_clk_a] -max 10.000 [get_ports {adc_data_a_i[*] adc_otr_a_i}]
set_input_delay -clock [get_clocks an9238_clk_b] -min 2.000 [get_ports {adc_data_b_i[*] adc_otr_b_i}]
set_input_delay -clock [get_clocks an9238_clk_b] -max 10.000 [get_ports {adc_data_b_i[*] adc_otr_b_i}]
