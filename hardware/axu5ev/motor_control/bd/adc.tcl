# Existing PS/AXI/ADC/ILA wiring, unchanged by source consolidation.
proc mc_sources {root kind} {
    set f [open $root/hardware/axu5ev/motor_control/sources.list r]
    set sources [list]
    foreach line [split [read $f] "\n"] {
        set fields [split [string trim $line] |]
        if {[lindex $fields 0] eq $kind} {
            lappend sources [file normalize [file join $root [lindex $fields 1]]]
        }
    }
    close $f
    return $sources
}
proc mc_hdl_sources {root with_auto {profile ""}} {
    # Register declarations and their consumers together, packages first.
    # Splitting registration can leave module-reference discovery incomplete.
    if {$profile ne ""} {
        return [concat [mc_sources $root experiment] [mc_sources $root handwritten]]
    }
    set files [mc_sources $root generated]
    if {$with_auto} {set files [concat $files [mc_sources $root generated_foc]]}
    return [concat $files [mc_sources $root handwritten]]
}
proc mc_external_pin {pin external_name} {
    set before [get_bd_ports -quiet]
    make_bd_pins_external [get_bd_pins $pin]
    set added [list]
    foreach port [get_bd_ports -quiet] {
        if {$port ni $before} {lappend added $port}
    }
    if {[llength $added] != 1} {error "Cannot identify external port for $pin"}
    set_property name $external_name $added
}
proc mc_integrate {root out} {
    open_project $out/project/ax02a_ps.xpr
    open_bd_design [get_files */design_1.bd]
    set ps [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 1 CONFIG.PSU__USE__FABRIC__RST 1 \
        CONFIG.PSU__FPGA_PL0_ENABLE 1 CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL IOPLL \
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ 50] $ps
    set_property CONFIG.PSU__NUM_FABRIC_RESETS 1 $ps
    set profile [expr {[info exists ::env(MC_AX04B)] ? $::env(MC_AX04B) : ""}]
    if {$profile ni {"" SELFTEST REAL}} {error "Unknown AX04B build profile: $profile"}
    if {$profile ne ""} {
        set_property CONFIG.PSU__USE__IRQ0 1 $ps
        set_property verilog_define AX04B_EXPERIMENT [get_filesets sources_1]
    }
    set with_auto [expr {[info exists ::env(MC_AUTO)] && $::env(MC_AUTO)==1}]
    add_files -norecurse [mc_hdl_sources $root $with_auto $profile]
    update_compile_order -fileset sources_1
    update_ip_catalog -update_module_ref
    create_bd_cell -type module -reference ax03b3_adc_observer adc_observer_0
    if {[info exists ::env(AX03B3_TEST)]} {set_property CONFIG.TEST_INPUT $::env(AX03B3_TEST) [get_bd_cells adc_observer_0]}
    set with_encoder [expr {[info exists ::env(MC_ENCODER)] && $::env(MC_ENCODER)==1}]
    if {$with_encoder} {
        set_property -dict [list CONFIG.ENCODER_FEEDBACK 1 CONFIG.TEST_ABZ 1] [get_bd_cells adc_observer_0]
    }
    if {$with_auto} {set_property CONFIG.AUTO_CONTROL 1 [get_bd_cells adc_observer_0]}
    if {$profile ne ""} {
        if {!$with_auto || !$with_encoder} {error "AX04B requires the encoder and generated FOC"}
        set selftest [expr {$profile eq "SELFTEST"}]
        set_property -dict [list CONFIG.AX04B 1 CONFIG.TEST_INPUT $selftest CONFIG.TEST_ABZ $selftest] [get_bd_cells adc_observer_0]
        create_bd_cell -type module -reference ax04b_realtime_axi ax04b_realtime_0
        set_property CONFIG.SELFTEST $selftest [get_bd_cells ax04b_realtime_0]
    }
    puts "ADC_MREF_CLOCK_HZ=[get_property CONFIG.FREQ_HZ [get_bd_pins adc_observer_0/s_axi_aclk]]"
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_adc
    set with_pwm [expr {[info exists ::env(MC_PWM)] && $::env(MC_PWM)==1}]
    if {$with_auto && (!$with_pwm || !$with_encoder)} {error "MC_AUTO requires the existing encoder and PWM paths"}
    set_property -dict [list CONFIG.NUM_SI 1 CONFIG.NUM_MI [expr {$profile ne "" ? 3 : ($with_pwm ? 2 : 1)}] CONFIG.NUM_CLKS 1] [get_bd_cells axi_adc]
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pl0
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant zero
    set_property CONFIG.CONST_VAL 0 [get_bd_cells zero]
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant one
    set_property CONFIG.CONST_VAL 1 [get_bd_cells one]
    # Physical encoder pins remain unassigned. Explicit TEST_ABZ goes through
    # the existing receiver; its source remains stopped until a software command.
    if {$profile eq "REAL"} {
        foreach {pin port} {abz_a_i j16_qepa_i abz_b_i j16_qepb_i abz_z_i j16_qepz_i
            ax04b_erri_n_i j16_erri_n_i ax04b_erru_n_i j16_erru_n_i
            ax04b_ctrl_enable_o j16_ctrl_enable_o ax04b_pwm_enable_o j16_pwm_enable_o
            ax04b_relcon_o j16_relcon_o ax04b_encon_o j16_encon_o ax04b_f_reset_n_o j16_f_reset_n_o} {
            mc_external_pin adc_observer_0/$pin $port
        }
    } else {
        connect_bd_net [get_bd_pins zero/dout] [get_bd_pins adc_observer_0/abz_a_i] \
            [get_bd_pins adc_observer_0/abz_b_i] [get_bd_pins adc_observer_0/abz_z_i]
        connect_bd_net [get_bd_pins one/dout] [get_bd_pins adc_observer_0/ax04b_erri_n_i] \
            [get_bd_pins adc_observer_0/ax04b_erru_n_i]
    }
    connect_bd_intf_net [get_bd_intf_pins $ps/M_AXI_HPM0_LPD] [get_bd_intf_pins axi_adc/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins axi_adc/M00_AXI] [get_bd_intf_pins adc_observer_0/s_axi]
    connect_bd_net [get_bd_pins $ps/pl_clk0] [get_bd_pins $ps/maxihpm0_lpd_aclk] \
        [get_bd_pins axi_adc/aclk] [get_bd_pins adc_observer_0/s_axi_aclk] [get_bd_pins rst_pl0/slowest_sync_clk]
    connect_bd_net [get_bd_pins $ps/pl_resetn0] [get_bd_pins rst_pl0/ext_reset_in]
    connect_bd_net [get_bd_pins zero/dout] [get_bd_pins rst_pl0/mb_debug_sys_rst]
    connect_bd_net [get_bd_pins one/dout] [get_bd_pins rst_pl0/dcm_locked] [get_bd_pins rst_pl0/aux_reset_in]
    connect_bd_net [get_bd_pins rst_pl0/interconnect_aresetn] [get_bd_pins axi_adc/aresetn]
    connect_bd_net [get_bd_pins rst_pl0/peripheral_aresetn] [get_bd_pins adc_observer_0/s_axi_aresetn]
    if {$profile ne ""} {mc_ax04b_realtime $ps}
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
        mc_pwm_integrate $out $ps $profile
    }
    if {$profile ne ""} {
        set cpu_space [get_bd_addr_spaces $ps/Data]
        foreach {slave address} {adc_observer_0 0x80000000 pwm_control_0 0x80001000
            ax04b_realtime_0 0x80002000} {
            set regs [get_bd_addr_segs -of_objects [get_bd_intf_pins $slave/s_axi]]
            if {[llength $regs] != 1} {error "Expected one AXI-Lite register segment for $slave"}
            assign_bd_address -target_address_space $cpu_space -offset $address -range 4K $regs
        }
    } else {
        assign_bd_address
    }
    if {$with_pwm && $profile eq ""} {
        set_property offset 0x80000000 [get_bd_addr_segs $ps/Data/SEG_adc_observer_0_reg0]
        set_property range 4K [get_bd_addr_segs $ps/Data/SEG_adc_observer_0_reg0]
        set_property offset 0x80001000 [get_bd_addr_segs $ps/Data/SEG_pwm_control_0_reg0]
        set_property range 4K [get_bd_addr_segs $ps/Data/SEG_pwm_control_0_reg0]
    }
    validate_bd_design
    if {$profile ne ""} {mc_ax04b_check_ila}
    save_bd_design
    if {[get_property CONFIG.C_AUX_RESET_HIGH [get_bd_cells rst_pl0]] != 0} {error "aux reset polarity"}
    set f [open $out/integration_settings.txt w]
    puts $f "part=[get_property PART [current_project]]\nVivado=[version -short]"
    puts $f "pl_clock_pin_hz=[get_property CONFIG.FREQ_HZ [get_bd_pins $ps/pl_clk0]]"
    puts $f "actual_freq_mhz=[get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ $ps]"
    if {$profile eq ""} {
        puts $f "aux_reset_in=1;mb_debug_sys_rst=0;ABZ_TEST=$with_encoder;AUTO_FOC=$with_auto;physical_ABZ=not_connected;current_calibration=explicit_command"
    } else {
        puts $f "aux_reset_in=1;mb_debug_sys_rst=0;ABZ_TEST=$selftest;AUTO_FOC=$with_auto;physical_ABZ=[expr {$selftest ? "not_connected" : "J16_V0.3"}];current_calibration=explicit_command"
        puts $f "AX04B_PROFILE=$profile TEST_SOURCE=$selftest IRQ=PL_PS_IRQ0[format {[%d]} 0] IRQ_TYPE=level_high J16_motion_release=0"
    }
    foreach seg [get_bd_addr_segs -of_objects [get_bd_addr_spaces $ps/Data]] {
        puts $f "segment=$seg offset=[get_property OFFSET $seg] range=[get_property RANGE $seg]"
    }
    close $f
    generate_target all [get_files */design_1.bd]
    set wrapper [make_wrapper -files [get_files */design_1.bd] -top]
    add_files -norecurse $wrapper
    add_files -fileset constrs_1 [mc_sources $root constraints]
    if {$profile eq "REAL"} {
        add_files -fileset constrs_1 [mc_sources $root constraints_real]
        foreach constraint [mc_sources $root constraints_real_impl] {
            add_files -fileset constrs_1 $constraint
            set_property USED_IN_SYNTHESIS false [get_files $constraint]
        }
    }
    set_property top design_1_wrapper [current_fileset]
    update_compile_order -fileset sources_1
    write_hw_platform -fixed -file $out/ax03b3_adc_prebit.xsa
    close_project
}

proc mc_ax04b_realtime {ps} {
    set cpu ax04b_realtime_0
    set obs adc_observer_0
    connect_bd_intf_net [get_bd_intf_pins axi_adc/M02_AXI] [get_bd_intf_pins $cpu/s_axi]
    connect_bd_net [get_bd_pins $ps/pl_clk0] [get_bd_pins $cpu/s_axi_aclk]
    connect_bd_net [get_bd_pins rst_pl0/peripheral_aresetn] [get_bd_pins $cpu/s_axi_aresetn]
    foreach {from to} {ax04b_frame_o frame_publish_i ax04b_frame_data_o frame_data_i
        ax04b_p0_o p0_i ax04b_p0_id_o p0_sample_id_i ax04b_fault_o fast_fault_i
        ax04b_invalidate_o invalidate_i} {
        connect_bd_net [get_bd_pins $obs/$from] [get_bd_pins $cpu/$to]
    }
    foreach {from to} {active_reference_o ax04b_reference_i active_valid_o ax04b_ref_valid_i
        inhibit_o ax04b_inhibit_i ctrl_enable_o ax04b_ctrl_enable_i} {
        connect_bd_net [get_bd_pins $cpu/$from] [get_bd_pins $obs/$to]
    }
    set interrupt_pin [get_bd_pins $ps/pl_ps_irq0]
    set interrupt_width [expr {[get_property LEFT $interrupt_pin]-[get_property RIGHT $interrupt_pin]+1}]
    if {$interrupt_width == 1} {
        connect_bd_net [get_bd_pins $cpu/irq_o] $interrupt_pin
    } else {
        create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat ax04b_irq_concat
        set_property -dict [list CONFIG.NUM_PORTS 2 CONFIG.IN0_WIDTH 1 \
            CONFIG.IN1_WIDTH [expr {$interrupt_width-1}]] [get_bd_cells ax04b_irq_concat]
        create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant ax04b_unused_irq
        set_property -dict [list CONFIG.CONST_VAL 0 CONFIG.CONST_WIDTH [expr {$interrupt_width-1}]] \
            [get_bd_cells ax04b_unused_irq]
        connect_bd_net [get_bd_pins $cpu/irq_o] [get_bd_pins ax04b_irq_concat/In0]
        connect_bd_net [get_bd_pins ax04b_unused_irq/dout] [get_bd_pins ax04b_irq_concat/In1]
        connect_bd_net [get_bd_pins ax04b_irq_concat/dout] $interrupt_pin
    }
    create_bd_cell -type ip -vlnv xilinx.com:ip:ila realtime_ila
}

proc mc_ax04b_ila_config {} {
    set ila [get_bd_cells realtime_ila]
    set_property -dict [list CONFIG.C_MONITOR_TYPE Native CONFIG.C_NUM_OF_PROBES 4 \
        CONFIG.C_DATA_DEPTH 8192] $ila
    set_property -dict [list CONFIG.C_PROBE0_WIDTH 6 CONFIG.C_PROBE1_WIDTH 32 \
        CONFIG.C_PROBE2_WIDTH 32 CONFIG.C_PROBE3_WIDTH 128] $ila
}

proc mc_ax04b_check_ila {} {
    set ila [get_bd_cells realtime_ila]
    if {[llength [get_bd_cells -filter {VLNV =~ "xilinx.com:ip:ila:*"}]] != 1 ||
        [get_property CONFIG.C_NUM_OF_PROBES $ila] != 4} {
        error "AX04B needs exactly one four-probe ILA"
    }
    foreach {probe top_bit} {0 5 1 31 2 31 3 127} {
        set pin [get_bd_pins realtime_ila/probe$probe]
        if {[get_property LEFT $pin] != $top_bit || [get_property RIGHT $pin] != 0} {
            error "AX04B ILA narrowed probe $probe"
        }
    }
    set expected [get_bd_nets -of_objects [get_bd_pins pwm_clock/clk_out1]]
    if {[get_bd_nets -of_objects [get_bd_pins realtime_ila/clk]] ne $expected} {
        error "AX04B ILA must use the PWM clock to observe exact adoption"
    }
}

proc mc_ax04b_configure_combined_ila {} {
    # BASIC limits debug cores and probes. Pack status into one probe and
    # sample both related domains at 100 MHz to see the exact PWM valley.
    set old [get_bd_cells -quiet pwm_ila]
    if {[llength $old]} {delete_bd_objs $old}
    foreach pin [get_bd_pins -quiet realtime_ila/probe*] {
        set net [get_bd_nets -quiet -of_objects $pin]
        if {[llength $net]} {disconnect_bd_net $net $pin}
    }
    mc_ax04b_ila_config
    set clock [get_bd_pins realtime_ila/clk]
    set net [get_bd_nets -quiet -of_objects $clock]
    set source [get_bd_pins pwm_clock/clk_out1]
    if {$net ne [get_bd_nets -of_objects $source]} {
        if {[llength $net]} {disconnect_bd_net $net $clock}
        connect_bd_net $source $clock
    }
    set obs adc_observer_0
    set cpu ax04b_realtime_0
    set flags ax04b_probe_flags
    if {![llength [get_bd_cells -quiet $flags]]} {
        create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat $flags
        set_property CONFIG.NUM_PORTS 6 [get_bd_cells $flags]
        set bit 0
        foreach signal [list $obs/ax04b_p0_o $obs/ax04b_frame_o $cpu/irq_o \
            $cpu/active_valid_o $cpu/inhibit_o $obs/ax04b_fault_o] {
            connect_bd_net [get_bd_pins $signal] [get_bd_pins $flags/In$bit]
            incr bit
        }
    }
    set probe 0
    foreach signal [list $flags/dout $obs/ax04b_p0_id_o $cpu/active_target_o pwm_control_0/debug_o] {
        connect_bd_net [get_bd_pins $signal] [get_bd_pins realtime_ila/probe$probe]
        incr probe
    }
}
