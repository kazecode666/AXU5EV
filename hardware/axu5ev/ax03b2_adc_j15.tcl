# Issue30 offline-only ADC project. No hardware manager/debugger calls.
# Usage: <new-output> ?base|integrate|build|all? ?vendor-bd?
if {$argc < 1 || $argc > 3} {error "output ?stage? ?vendor-bd?"}
set b2_root [file normalize [file join [file dirname [info script]] ../..]]
set b2_out [file normalize [lindex $argv 0]]
set b2_stage [expr {$argc>1 ? [lindex $argv 1] : "all"}]
set b2_vendor [expr {$argc>2 ? [file normalize [lindex $argv 2]] : [file join $b2_root .runtime ax03b2 vendor_ps design_1.bd]}]
if {$b2_stage ni {base integrate build all}} {error "unknown stage"}
proc b2_base {root out vendor} {
    # Same vendor DDR/UART preset and accepted GEM3/TTC PS configuration as C1.
    set argc 3
    set argv [list xczu5ev-sfvc784-2-i $out $vendor]
    source $root/hardware/axu5ev/eth02_ps_runtime_ethernet.tcl
}
proc b2_integrate {root out} {
    open_project $out/project/ax02a_ps.xpr
    open_bd_design [get_files */design_1.bd]
    set ps [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict [list CONFIG.PSU__USE__M_AXI_GP2 1 CONFIG.PSU__USE__FABRIC__RST 1 \
        CONFIG.PSU__FPGA_PL0_ENABLE 1 CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL IOPLL \
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ 50] $ps
    set_property CONFIG.PSU__NUM_FABRIC_RESETS 1 $ps
    add_files -norecurse [list $root/integration/rtl/ax03b1/ax03b1_adc_receiver.sv \
        $root/integration/rtl/ax03b1/ax03b1_snapshot_axi.sv \
        $root/integration/rtl/ax03b2/ax03b2_adc_observer.sv]
    update_compile_order -fileset sources_1
    update_ip_catalog -update_module_ref
    create_bd_cell -type module -reference ax03b2_adc_observer adc_observer_0
    puts "ADC_MREF_CLOCK_HZ=[get_property CONFIG.FREQ_HZ [get_bd_pins adc_observer_0/s_axi_aclk]]"
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_adc
    set_property -dict [list CONFIG.NUM_SI 1 CONFIG.NUM_MI 1 CONFIG.NUM_CLKS 1] [get_bd_cells axi_adc]
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pl0
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant zero
    set_property CONFIG.CONST_VAL 0 [get_bd_cells zero]
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant one
    set_property CONFIG.CONST_VAL 1 [get_bd_cells one]
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
    create_bd_cell -type ip -vlnv xilinx.com:ip:ila adc_ila
    set_property -dict [list CONFIG.C_MONITOR_TYPE Native CONFIG.C_NUM_OF_PROBES 1 CONFIG.C_PROBE0_WIDTH 64 \
        CONFIG.C_DATA_DEPTH 1024 CONFIG.C_EN_STRG_QUAL 1] [get_bd_cells adc_ila]
    connect_bd_net [get_bd_pins $ps/pl_clk0] [get_bd_pins adc_ila/clk]
    connect_bd_net [get_bd_pins adc_observer_0/debug_o] [get_bd_pins adc_ila/probe0]
    assign_bd_address
    validate_bd_design
    save_bd_design
    if {[get_property CONFIG.C_AUX_RESET_HIGH [get_bd_cells rst_pl0]] != 0} {error "aux reset polarity"}
    set f [open $out/integration_settings.txt w]
    puts $f "part=[get_property PART [current_project]]\nVivado=[version -short]"
    puts $f "pl_clock_pin_hz=[get_property CONFIG.FREQ_HZ [get_bd_pins $ps/pl_clk0]]"
    puts $f "actual_freq_mhz=[get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ $ps]"
    puts $f "aux_reset_in=1;mb_debug_sys_rst=0;ABZ=not_connected;current_calibration=disabled"
    foreach seg [get_bd_addr_segs -of_objects [get_bd_addr_spaces $ps/Data]] {
        puts $f "segment=$seg offset=[get_property OFFSET $seg] range=[get_property RANGE $seg]"
    }
    close $f
    generate_target all [get_files */design_1.bd]
    set wrapper [make_wrapper -files [get_files */design_1.bd] -top]
    add_files -norecurse $wrapper
    add_files -fileset constrs_1 $root/hardware/axu5ev/ax03b2_adc_j15.xdc
    set_property top design_1_wrapper [current_fileset]
    update_compile_order -fileset sources_1
    write_hw_platform -fixed -file $out/ax03b2_adc_prebit.xsa
    close_project
}
proc b2_build {out} {
    open_project $out/project/ax02a_ps.xpr
    set_param general.maxThreads 8
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    if {![string match {*Complete*} [get_property STATUS [get_runs synth_1]]]} {error "synthesis failed"}
    launch_runs impl_1 -to_step route_design -jobs 4
    wait_on_run impl_1
    if {![string match {*Complete*} [get_property STATUS [get_runs impl_1]]]} {error "implementation failed"}
    open_run impl_1
    file mkdir $out/reports
    report_methodology -file $out/reports/methodology.rpt
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file $out/reports/timing_summary.rpt
    check_timing -verbose -file $out/reports/check_timing.rpt
    report_drc -file $out/reports/drc.rpt
    report_utilization -file $out/reports/utilization.rpt
    report_io -file $out/reports/io.rpt
    report_clocks -file $out/reports/clocks.rpt
    report_exceptions -file $out/reports/exceptions.rpt
    report_timing -from [get_ports {adc_data_* adc_otr_*}] -delay_type max -max_paths 26 -file $out/reports/adc_setup.rpt
    report_timing -from [get_ports {adc_data_* adc_otr_*}] -delay_type min -max_paths 26 -file $out/reports/adc_hold.rpt
    if {[get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]<0 || \
        [get_property SLACK [get_timing_paths -delay_type min -max_paths 1]]<0} {error "timing failed"}
    write_debug_probes -force $out/ax03b2_adc.ltx
    close_design
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    if {![string match {*Complete*} [get_property STATUS [get_runs impl_1]]]} {error "bitstream failed"}
    open_run impl_1
    file copy [get_property DIRECTORY [get_runs impl_1]]/design_1_wrapper.bit $out/ax03b2_adc.bit
    write_hw_platform -fixed -include_bit -file $out/ax03b2_adc.xsa
    close_project
    puts "AX03B2_BUILD_PASS $out/ax03b2_adc.xsa"
}
if {$b2_stage in {base all}} {b2_base $b2_root $b2_out $b2_vendor}
if {$b2_stage in {integrate all}} {
    if {[catch {b2_integrate $b2_root $b2_out} message]} {puts stderr $::errorInfo; error $message}
}
if {$b2_stage in {build all}} {b2_build $b2_out}
