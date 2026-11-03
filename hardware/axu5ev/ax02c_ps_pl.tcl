# AX-02C1 PS + real p3 FOC. Offline project/bitstream/XSA only; no target tools.
# Usage: <new-output> <vendor-bd> <PR20-rtl> ?all|base|integrate|build?
if {$argc < 3 || $argc > 4} {error "expected output vendor-bd PR20-rtl ?stage?"}
proc ax02c_base {root out vendor} {
    # Reuse accepted PS configuration and its native vendor-XCI upgrade path.
    set argc 3
    set argv [list xczu5ev-sfvc784-2-i $out $vendor]
    source [file join $root hardware axu5ev eth02_ps_runtime_ethernet.tcl]
}
proc ax02c_integrate {root out rtl} {
    open_project $out/project/ax02a_ps.xpr
    open_bd_design [get_files */design_1.bd]
    set ps [get_bd_cells zynq_ultra_ps_e_0]
    # PL0 and the LPD master are the only added PS features. IOPLL is retained
    # from the accepted GEM3 configuration; its divider provides nominal 50MHz.
    set desired [list CONFIG.PSU__USE__M_AXI_GP2 1 \
        CONFIG.PSU__USE__FABRIC__RST 1 CONFIG.PSU__FPGA_PL0_ENABLE 1 \
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL IOPLL \
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ 50]
    set_property -dict $desired $ps
    # The inherited PS-only preset has zero fabric resets. Enable first, then
    # select one output; PG201 Fabric Reset Enable defines these separately.
    set_property -dict [list CONFIG.PSU__NUM_FABRIC_RESETS 1] $ps
    lappend desired CONFIG.PSU__NUM_FABRIC_RESETS 1
    foreach {key value} $desired {
        if {[get_property $key $ps] ne $value} {error "PS setting did not take: $key"}
    }
    set names [exec python -c {import json,sys;print("\n".join(x["path"] for x in json.load(open(sys.argv[1],encoding="utf-8"))["design_files"]))} $root/generated/legacy_m3_p3/manifest.json]
    set files [list $rtl/FOC_DUT_pkg.sv]
    foreach name [lsort [split $names \n]] {
        set name [string trim $name]
        if {$name ne "FOC_DUT_pkg.sv"} {lappend files $rtl/$name}
    }
    lappend files $root/integration/rtl/axu5ev_foc_frame_top.sv \
        $root/integration/rtl/axu5ev_foc_axi.sv
    add_files -norecurse $files
    update_compile_order -fileset sources_1
    create_bd_cell -type module -reference axu5ev_foc_axi foc_axi_0
    create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_foc
    set_property -dict [list CONFIG.NUM_SI 1 CONFIG.NUM_MI 1 CONFIG.NUM_CLKS 1] [get_bd_cells axi_foc]
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pl0
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant zero
    set_property -dict [list CONFIG.CONST_VAL 0 CONFIG.CONST_WIDTH 1] [get_bd_cells zero]
    create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant one
    set_property -dict [list CONFIG.CONST_VAL 1 CONFIG.CONST_WIDTH 1] [get_bd_cells one]
    connect_bd_intf_net [get_bd_intf_pins $ps/M_AXI_HPM0_LPD] [get_bd_intf_pins axi_foc/S00_AXI]
    connect_bd_intf_net [get_bd_intf_pins axi_foc/M00_AXI] [get_bd_intf_pins foc_axi_0/s_axi]
    connect_bd_net [get_bd_pins $ps/pl_clk0] [get_bd_pins $ps/maxihpm0_lpd_aclk] \
        [get_bd_pins axi_foc/aclk] [get_bd_pins foc_axi_0/s_axi_aclk] [get_bd_pins rst_pl0/slowest_sync_clk]
    connect_bd_net [get_bd_pins $ps/pl_resetn0] [get_bd_pins rst_pl0/ext_reset_in]
    connect_bd_net [get_bd_pins zero/dout] [get_bd_pins rst_pl0/aux_reset_in] [get_bd_pins rst_pl0/mb_debug_sys_rst]
    connect_bd_net [get_bd_pins one/dout] [get_bd_pins rst_pl0/dcm_locked]
    connect_bd_net [get_bd_pins rst_pl0/interconnect_aresetn] [get_bd_pins axi_foc/aresetn]
    connect_bd_net [get_bd_pins rst_pl0/peripheral_aresetn] [get_bd_pins foc_axi_0/s_axi_aresetn]
    assign_bd_address
    validate_bd_design
    # Reset polarity is derived by IPI from the active-low PS driver.
    if {[get_property CONFIG.C_EXT_RESET_HIGH [get_bd_cells rst_pl0]] != 0} {error "PS reset polarity mismatch"}
    save_bd_design
    set f [open $out/integration_settings.txt w]
    puts $f "part=[get_property PART [current_project]]\nVivado=[version -short]"
    foreach key [concat [lmap {k v} $desired {set k}] [list \
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ CONFIG.PSU__PSS_REF_CLK__FREQMHZ \
        CONFIG.PSU__DDRC__BUS_WIDTH CONFIG.PSU__DDRC__DRAM_WIDTH \
        CONFIG.PSU__UART0__PERIPHERAL__IO CONFIG.PSU__ENET3__PERIPHERAL__ENABLE \
        CONFIG.PSU__TTC0__PERIPHERAL__ENABLE]] {
        puts $f "$key=[get_property $key $ps]"
    }
    puts $f "pl_clock_pin_hz=[get_property CONFIG.FREQ_HZ [get_bd_pins $ps/pl_clk0]]"
    foreach seg [get_bd_addr_segs -of_objects [get_bd_addr_spaces $ps/Data]] {
        puts $f "segment=$seg offset=[get_property OFFSET $seg] range=[get_property RANGE $seg]"
    }
    close $f
    generate_target all [get_files */design_1.bd]
    # Recreate the wrapper from the integrated BD in this candidate only.
    set wrapper [make_wrapper -files [get_files */design_1.bd] -top]
    add_files -norecurse $wrapper
    set_property top design_1_wrapper [current_fileset]
    update_compile_order -fileset sources_1
    write_hw_platform -fixed -file $out/ax02c_ps_pl_prebit.xsa
    close_project
    puts "AX02C_INTEGRATED $out"
}
proc ax02c_build {out} {
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
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file $out/reports/timing_summary.rpt
    report_route_status -file $out/reports/route_status.rpt
    report_drc -file $out/reports/drc.rpt
    check_timing -verbose -file $out/reports/check_timing.rpt
    report_utilization -file $out/reports/utilization.rpt
    report_clock_utilization -file $out/reports/clock_utilization.rpt
    report_timing -delay_type max -max_paths 5 -path_type full_clock_expanded -file $out/reports/setup.rpt
    report_timing -delay_type min -max_paths 5 -path_type full_clock_expanded -file $out/reports/hold.rpt
    report_pulse_width -all_violators -file $out/reports/pulse_width.rpt
    set setup [get_timing_paths -delay_type max -max_paths 1]
    set hold [get_timing_paths -delay_type min -max_paths 1]
    if {[get_property SLACK $setup]<0 || [get_property SLACK $hold]<0} {error "integrated timing failure; see reports"}
    close_design
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    if {![string match {*Complete*} [get_property STATUS [get_runs impl_1]]]} {error "bitstream failed"}
    open_run impl_1
    file copy [get_property DIRECTORY [get_runs impl_1]]/design_1_wrapper.bit $out/ax02c_ps_pl.bit
    write_hw_platform -fixed -include_bit -file $out/ax02c_ps_pl.xsa
    close_project
    puts "AX02C_BUILD_PASS $out/ax02c_ps_pl.xsa"
}
set ax02c_root [file normalize [file join [file dirname [info script]] ../..]]
set ax02c_out [file normalize [lindex $argv 0]]
set ax02c_vendor [file normalize [lindex $argv 1]]
set ax02c_rtl [file normalize [lindex $argv 2]]
set ax02c_stage [expr {$argc==4 ? [lindex $argv 3] : "all"}]
if {$ax02c_stage ni {all base integrate build}} {error "unknown stage: $ax02c_stage"}
if {$ax02c_stage in {all base}} {ax02c_base $ax02c_root $ax02c_out $ax02c_vendor}
if {$ax02c_stage in {all integrate}} {ax02c_integrate $ax02c_root $ax02c_out $ax02c_rtl}
if {$ax02c_stage in {all build}} {ax02c_build $ax02c_out}
