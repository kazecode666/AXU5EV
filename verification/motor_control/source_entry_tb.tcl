# Cold source-registration check only. No synthesis, implementation or board IP.
if {$argc != 1} {error "usage: source_entry_tb.tcl <new-result-directory>"}
set root [file normalize [file join [file dirname [info script]] ../..]]
set out [file normalize [lindex $argv 0]]
if {[file exists $out]} {error "result directory exists; preserve previous output"}
file mkdir $out
cd $out
source $root/hardware/axu5ev/motor_control/bd/adc.tcl
set sources [mc_hdl_sources $root 1]
foreach path $sources {if {![file isfile $path]} {error "missing HDL source: $path"}}

create_project -in_memory -part xczu5ev-sfvc784-2-i
# An unrelated top ensures discovery must include uninstantiated module refs.
set f [open $out/empty_top.sv w]
puts $f "module empty_top; endmodule"
close $f
add_files -norecurse $out/empty_top.sv
set_property top empty_top [current_fileset]
set_property source_mgmt_mode All [current_project]
add_files -norecurse $sources
update_compile_order -fileset sources_1
create_bd_design source_entry
create_bd_cell -type module -reference ax03b3_adc_observer adc_observer_0
set_property -dict [list CONFIG.ENCODER_FEEDBACK 1 CONFIG.TEST_ABZ 1 CONFIG.AUTO_CONTROL 1] [get_bd_cells adc_observer_0]
create_bd_cell -type module -reference pwm_config_bridge pwm_control_0
set_property CONFIG.AUTO_FOC 1 [get_bd_cells pwm_control_0]
foreach name {s_axi_aclk auto_valid_o auto_compare_o auto_seq_o auto_inhibit_o auto_ready_i auto_online_i auto_applied_seq_i} {
    if {[llength [get_bd_pins -quiet adc_observer_0/$name]] != 1} {error "missing ADC module-reference port: $name"}
}
foreach name {pwm_clk auto_valid_i auto_compare_i auto_seq_i auto_inhibit_i auto_ready_o auto_online_o auto_applied_seq_o} {
    if {[llength [get_bd_pins -quiet pwm_control_0/$name]] != 1} {error "missing PWM module-reference port: $name"}
}
if {[get_property CONFIG.AUTO_CONTROL [get_bd_cells adc_observer_0]] != 1 ||
    [get_property CONFIG.AUTO_FOC [get_bd_cells pwm_control_0]] != 1} {error "AUTO parameters not accepted"}
set f [open $out/result.txt w]
puts $f "MOTOR_SOURCE_ENTRY_PASS sources=[llength $sources] module_refs=2 AUTO_CONTROL=1 AUTO_FOC=1 synthesis=NOT_RUN board=NOT_RUN"
close $f
close_project
puts "MOTOR_SOURCE_ENTRY_PASS sources=[llength $sources] module_refs=2 AUTO_CONTROL=1 AUTO_FOC=1 synthesis=NOT_RUN board=NOT_RUN"
