# Keep PS pl_clk0 and ADC reset wiring. Add only the derived PWM clock/domain.
proc mc_pwm_integrate {out ps} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz pwm_clock
    set input_mhz [expr {[get_property CONFIG.FREQ_HZ [get_bd_pins $ps/pl_clk0]]/1000000.0}]
    set_property -dict [list CONFIG.PRIM_IN_FREQ $input_mhz \
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ [expr {2*$input_mhz}] \
        CONFIG.PRIM_SOURCE No_buffer CONFIG.USE_RESET true CONFIG.RESET_TYPE ACTIVE_LOW \
        CONFIG.USE_LOCKED true] [get_bd_cells pwm_clock]
    create_bd_cell -type module -reference pwm_config_bridge pwm_control_0
    if {[info exists ::env(MC_AUTO)] && $::env(MC_AUTO)==1} {
        set_property CONFIG.AUTO_FOC 1 [get_bd_cells pwm_control_0]
    }
    foreach {source target} {auto_valid_o auto_valid_i auto_compare_o auto_compare_i auto_seq_o auto_seq_i auto_inhibit_o auto_inhibit_i} {
        connect_bd_net [get_bd_pins adc_observer_0/$source] [get_bd_pins pwm_control_0/$target]
    }
    foreach {source target} {auto_ready_o auto_ready_i auto_online_o auto_online_i auto_applied_seq_o auto_applied_seq_i} {
        connect_bd_net [get_bd_pins pwm_control_0/$source] [get_bd_pins adc_observer_0/$target]
    }
    connect_bd_net [get_bd_pins $ps/pl_clk0] [get_bd_pins pwm_clock/clk_in1] [get_bd_pins pwm_control_0/s_axi_aclk]
    connect_bd_net [get_bd_pins rst_pl0/peripheral_aresetn] [get_bd_pins pwm_clock/resetn] [get_bd_pins pwm_control_0/s_axi_aresetn]
    connect_bd_net [get_bd_pins pwm_clock/clk_out1] [get_bd_pins pwm_control_0/pwm_clk]
    connect_bd_net [get_bd_pins pwm_clock/locked] [get_bd_pins pwm_control_0/locked]
    connect_bd_net [get_bd_pins zero/dout] [get_bd_pins pwm_control_0/fast_inhibit]
    connect_bd_net [get_bd_pins adc_observer_0/pwm_anchor_o] [get_bd_pins pwm_control_0/adc_anchor]
    connect_bd_intf_net [get_bd_intf_pins axi_adc/M01_AXI] [get_bd_intf_pins pwm_control_0/s_axi]
    create_bd_cell -type ip -vlnv xilinx.com:ip:ila pwm_ila
    set_property -dict [list CONFIG.C_MONITOR_TYPE Native CONFIG.C_NUM_OF_PROBES 1 CONFIG.C_PROBE0_WIDTH 128 CONFIG.C_DATA_DEPTH 4096] [get_bd_cells pwm_ila]
    connect_bd_net [get_bd_pins pwm_clock/clk_out1] [get_bd_pins pwm_ila/clk]
    connect_bd_net [get_bd_pins pwm_control_0/debug_o] [get_bd_pins pwm_ila/probe0]
    # No external gate pins: buffering/polarity/driver mapping remain unverified.
    set f [open $out/pwm_clock_settings.txt w]
    foreach prop [lsort [list_property [get_bd_cells pwm_clock]]] {
        if {[regexp {^CONFIG\.(MMCM|CLKOUT1|PRIM|RESET|USE_LOCKED)} $prop]} {
            puts $f "$prop=[get_property $prop [get_bd_cells pwm_clock]]"
        }
    }
    set c [get_bd_cells pwm_clock]
    set mult [get_property CONFIG.MMCM_CLKFBOUT_MULT_F $c]
    set div [get_property CONFIG.MMCM_DIVCLK_DIVIDE $c]
    set outdiv [get_property CONFIG.MMCM_CLKOUT0_DIVIDE_F $c]
    if {abs($mult/$div/$outdiv-2.0)>0.000001} {error "PWM clock must be strictly 2:1"}
    puts $f "input_mhz=$input_mhz output_mhz=[expr {$input_mhz*$mult/$div/$outdiv}] ratio=2"
    close $f
}
