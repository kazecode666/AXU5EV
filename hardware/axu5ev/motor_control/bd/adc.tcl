# Existing PS/AXI/ADC/ILA wiring, unchanged by source consolidation.
proc mc_integrate {root out} {
    open_project $out/project/ax02a_ps.xpr
    open_bd_design [get_files */design_1.bd]
    set ps [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 1 CONFIG.PSU__USE__FABRIC__RST 1 \
        CONFIG.PSU__FPGA_PL0_ENABLE 1 CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL IOPLL \
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ 50] $ps
    set_property CONFIG.PSU__NUM_FABRIC_RESETS 1 $ps
    add_files -norecurse [mc_sources $root handwritten]
    add_files -norecurse [mc_sources $root generated]
    set with_auto [expr {[info exists ::env(MC_AUTO)] && $::env(MC_AUTO)==1}]
    if {$with_auto} {add_files -norecurse [mc_sources $root generated_foc]}
    update_compile_order -fileset sources_1
    update_ip_catalog -update_module_ref
    create_bd_cell -type module -reference ax03b3_adc_observer adc_observer_0
    if {[info exists ::env(AX03B3_TEST)]} {set_property CONFIG.TEST_INPUT $::env(AX03B3_TEST) [get_bd_cells adc_observer_0]}
    set with_encoder [expr {[info exists ::env(MC_ENCODER)] && $::env(MC_ENCODER)==1}]
    if {$with_encoder} {
        set_property -dict [list CONFIG.ENCODER_FEEDBACK 1 CONFIG.TEST_ABZ 1] [get_bd_cells adc_observer_0]
    }
    if {$with_auto} {set_property CONFIG.AUTO_CONTROL 1 [get_bd_cells adc_observer_0]}
    puts "ADC_MREF_CLOCK_HZ=[get_property CONFIG.FREQ_HZ [get_bd_pins adc_observer_0/s_axi_aclk]]"
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_adc
    set with_pwm [expr {[info exists ::env(MC_PWM)] && $::env(MC_PWM)==1}]
    if {$with_auto && (!$with_pwm || !$with_encoder)} {error "MC_AUTO requires the existing encoder and PWM paths"}
    set_property -dict [list CONFIG.NUM_SI 1 CONFIG.NUM_MI [expr {$with_pwm?2:1}] CONFIG.NUM_CLKS 1] [get_bd_cells axi_adc]
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pl0
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant zero
    set_property CONFIG.CONST_VAL 0 [get_bd_cells zero]
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant one
    set_property CONFIG.CONST_VAL 1 [get_bd_cells one]
    # Physical encoder pins remain unassigned. Explicit TEST_ABZ goes through
    # the existing receiver; its source remains stopped until a software command.
    connect_bd_net [get_bd_pins zero/dout] [get_bd_pins adc_observer_0/abz_a_i] \
        [get_bd_pins adc_observer_0/abz_b_i] [get_bd_pins adc_observer_0/abz_z_i]
    connect_bd_intf_net [get_bd_intf_pins $ps/M_AXI_HPM0_LPD] [get_bd_intf_pins axi_adc/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins axi_adc/M00_AXI] [get_bd_intf_pins adc_observer_0/s_axi]
    connect_bd_net [get_bd_pins $ps/pl_clk0] [get_bd_pins $ps/maxihpm0_lpd_aclk] \
        [get_bd_pins axi_adc/aclk] [get_bd_pins adc_observer_0/s_axi_aclk] [get_bd_pins rst_pl0/slowest_sync_clk]
    connect_bd_net [get_bd_pins $ps/pl_resetn0] [get_bd_pins rst_pl0/ext_reset_in]
    connect_bd_net [get_bd_pins zero/dout] [get_bd_pins rst_pl0/mb_debug_sys_rst]
    connect_bd_net [get_bd_pins one/dout] [get_bd_pins rst_pl0/dcm_locked] [get_bd_pins rst_pl0/aux_reset_in]
    connect_bd_net [get_bd_pins rst_pl0/interconnect_aresetn] [get_bd_pins axi_adc/aresetn]
    connect_bd_net [get_bd_pins rst_pl0/peripheral_aresetn] [get_bd_pins adc_observer_0/s_axi_aresetn]
    foreach name {adc_data_a_i adc_data_b_i adc_otr_a_i adc_otr_b_i adc_clk_a_o adc_clk_b_o} {
        make_bd_pins_external [get_bd_pins adc_observer_0/$name]
        set_property name $name [get_bd_ports ${name}_0]
    }
    if {!$with_pwm} {
        create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant zero_seq
        set_property -dict [list CONFIG.CONST_VAL 0 CONFIG.CONST_WIDTH 32] [get_bd_cells zero_seq]
        connect_bd_net [get_bd_pins zero_seq/dout] [get_bd_pins adc_observer_0/auto_applied_seq_i]
        connect_bd_net [get_bd_pins zero/dout] [get_bd_pins adc_observer_0/auto_ready_i] [get_bd_pins adc_observer_0/auto_online_i]
        create_bd_cell -type ip -vlnv xilinx.com:ip:ila adc_ila
        set_property -dict [list CONFIG.C_MONITOR_TYPE Native CONFIG.C_NUM_OF_PROBES 1 CONFIG.C_PROBE0_WIDTH 64 \
            CONFIG.C_DATA_DEPTH 1024 CONFIG.C_EN_STRG_QUAL 1] [get_bd_cells adc_ila]
        connect_bd_net [get_bd_pins $ps/pl_clk0] [get_bd_pins adc_ila/clk]
        connect_bd_net [get_bd_pins adc_observer_0/debug_o] [get_bd_pins adc_ila/probe0]
    }
    if {$with_pwm} {
        source $root/hardware/axu5ev/motor_control/bd/pwm_clock.tcl
        mc_pwm_integrate $out $ps
    }
    assign_bd_address
    if {$with_pwm} {
        set_property offset 0x80000000 [get_bd_addr_segs $ps/Data/SEG_adc_observer_0_reg0]
        set_property range 4K [get_bd_addr_segs $ps/Data/SEG_adc_observer_0_reg0]
        set_property offset 0x80001000 [get_bd_addr_segs $ps/Data/SEG_pwm_control_0_reg0]
        set_property range 4K [get_bd_addr_segs $ps/Data/SEG_pwm_control_0_reg0]
    }
    validate_bd_design
    save_bd_design
    if {[get_property CONFIG.C_AUX_RESET_HIGH [get_bd_cells rst_pl0]] != 0} {error "aux reset polarity"}
    set f [open $out/integration_settings.txt w]
    puts $f "part=[get_property PART [current_project]]\nVivado=[version -short]"
    puts $f "pl_clock_pin_hz=[get_property CONFIG.FREQ_HZ [get_bd_pins $ps/pl_clk0]]"
    puts $f "actual_freq_mhz=[get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ $ps]"
    puts $f "aux_reset_in=1;mb_debug_sys_rst=0;ABZ_TEST=$with_encoder;AUTO_FOC=$with_auto;physical_ABZ=not_connected;current_calibration=explicit_command"
    foreach seg [get_bd_addr_segs -of_objects [get_bd_addr_spaces $ps/Data]] {
        puts $f "segment=$seg offset=[get_property OFFSET $seg] range=[get_property RANGE $seg]"
    }
    close $f
    generate_target all [get_files */design_1.bd]
    set wrapper [make_wrapper -files [get_files */design_1.bd] -top]
    add_files -norecurse $wrapper
    add_files -fileset constrs_1 [mc_sources $root constraints]
    set_property top design_1_wrapper [current_fileset]
    update_compile_order -fileset sources_1
    write_hw_platform -fixed -file $out/ax03b3_adc_prebit.xsa
    close_project
}
