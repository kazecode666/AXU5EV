# Offline only. Usage: vivado -mode batch -source build.tcl -tclargs <new-output> <vendor-bd>
proc j16_create_project {src out vendor_bd} {
    # AX02C uses this vendor-XCI migration and PS baseline before adding Ethernet/AXI.
    set argc 3
    set argv [list xczu5ev-sfvc784-2-i $out/ps_base $vendor_bd]
    source $src/../ax02a_ps_minimal.tcl
    open_project $out/ps_base/project/ax02a_ps.xpr
    save_project_as -exclude_run_results j16_level_test $out/project
    close_project
    open_project $out/project/j16_level_test.xpr

    set bd [get_files */design_1.bd]
    open_bd_design $bd
    set ps [get_bd_cells zynq_ultra_ps_e_0]
    set_property -dict {CONFIG.PSU__FPGA_PL0_ENABLE 1
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL IOPLL
        CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ 50} $ps
    set ps_pin [get_bd_pins $ps/pl_clk0]
    set clock_hz [get_property CONFIG.FREQ_HZ $ps_pin]
    connect_bd_net $ps_pin [create_bd_port -dir O -type clk -freq_hz $clock_hz pl_clk0]
    validate_bd_design
    save_bd_design
    if {[get_property CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ $ps] != 50
        || abs($clock_hz - 50000000) > 1000} {
        error "Unexpected PL0 clock: $clock_hz Hz"
    }
    generate_target all $bd
    set wrapper [make_wrapper -files $bd -top]
    add_files -norecurse $wrapper

    create_ip -name vio -vendor xilinx.com -library ip -version 3.0 -module_name j16_vio
    set vio [get_ips j16_vio]
    set config {CONFIG.C_NUM_PROBE_IN 5 CONFIG.C_NUM_PROBE_OUT 11}
    for {set i 0} {$i < 5} {incr i} {
        lappend config CONFIG.C_PROBE_IN${i}_WIDTH 1
    }
    for {set i 0} {$i < 11} {incr i} {
        lappend config CONFIG.C_PROBE_OUT${i}_WIDTH 1
        # probe_out8 drives F_Reset directly. The other probes initialize low.
        lappend config CONFIG.C_PROBE_OUT${i}_INIT_VAL [expr {$i == 8 ? {0x1} : {0x0}}]
    }
    set_property -dict $config $vio
    set settings [open $out/reports/configuration.txt w]
    puts $settings "Vivado=[version -short]\npart=[get_property PART [current_project]]\npl_clk0_hz=$clock_hz"
    foreach {key expected} $config {
        set actual [get_property $key $vio]
        if {$actual != $expected} {error "VIO $key is $actual, expected $expected"}
        puts $settings "$key=$actual"
    }
    close $settings

    generate_target all $vio
    import_files -fileset sources_1 -norecurse $src/j16_level_test.v
    import_files -fileset constrs_1 -norecurse [list $src/j16_level_test.xdc $src/j16_feedback_timing.xdc]
    set_property USED_IN_SYNTHESIS false [get_files */j16_feedback_timing.xdc]
    set_property top j16_level_test [current_fileset]
    update_compile_order -fileset sources_1

    set init [glob -nocomplain $out/project/j16_level_test.gen/sources_1/bd/design_1/ip/*/psu_init.tcl]
    if {[llength $init] != 1} {error "Expected one generated PSU initialization script: $init"}
    file copy [lindex $init 0] $out/psu_init.tcl
}

proc j16_check_pins {report} {
    # Independent readback against the J16.3 through J16.18 source order.
    set ports {
        PWM1 B10 OUT 45   PWM2 C11 OUT 45   PWM3 F10 OUT 45   PWM4 G11 OUT 45
        PWM5 C12 OUT 45   PWM6 D12 OUT 45   RELCON A11 OUT 45 ENCON A12 OUT 45
        F_Reset F11 OUT 45 QEPA F12 IN 45   QEPB E13 IN 46   QEPZ E14 IN 46
        ERRI A13 IN 46    ERRU B13 IN 46    PWM_EN A14 OUT 46 CTRL_EN B14 OUT 46
    }
    if {[llength [get_ports]] != 16} {error "Expected exactly 16 J16 GPIO ports"}
    set csv [open $report w]
    puts $csv "J16,Signal,Package_pin,Direction,Bank,IOStandard"
    set j16 3
    foreach {signal pin direction bank} $ports {
        set port [get_ports $signal]
        set actual_pin [get_property PACKAGE_PIN $port]
        set actual_direction [get_property DIRECTION $port]
        set actual_bank [get_property BANK [get_package_pins $actual_pin]]
        set actual_standard [get_property IOSTANDARD $port]
        if {$actual_pin ne $pin || $actual_direction ne $direction || $actual_bank ne $bank
            || $actual_standard ne "LVCMOS33"} {
            error "J16.$j16 $signal mismatch: $actual_pin $actual_direction $actual_bank $actual_standard"
        }
        puts $csv "$j16,$signal,$actual_pin,$actual_direction,$actual_bank,$actual_standard"
        incr j16
    }
    close $csv
}

proc j16_build {out} {
    set_param general.maxThreads 8
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
    launch_runs impl_1 -to_step route_design -jobs 4
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
    open_run impl_1
    set reports $out/reports
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file $reports/timing_summary.rpt
    report_clock_utilization -file $reports/clock_utilization.rpt
    report_route_status -file $reports/route_status.rpt
    report_io -file $reports/io.rpt
    report_drc -file $reports/drc.rpt
    report_utilization -file $reports/utilization.rpt
    j16_check_pins $reports/j16_io.csv

    set clock [get_clocks -of_objects [get_pins vio_j16/clk]]
    if {[llength $clock] != 1 || abs([get_property PERIOD $clock] - 20.0) > 0.01} {
        error "VIO clock is not constrained at 50 MHz: $clock"
    }
    foreach delay {max min} {
        set worst [get_timing_paths -delay_type $delay -max_paths 1]
        if {[llength $worst] != 1 || [get_property SLACK $worst] < 0} {
            error "Routed $delay timing failed; see timing_summary.rpt"
        }
    }
    write_bitstream $out/j16_level_test.bit
    write_debug_probes $out/j16_level_test.ltx
    close_project
    puts "J16_LEVEL_TEST_BUILD_PASS $out"
}

if {$argc != 2} {error "Expected a new output directory and the original ALINX design_1.bd"}
set j16_src [file dirname [file normalize [info script]]]
set j16_out [file normalize [lindex $argv 0]]
set j16_vendor [file normalize [lindex $argv 1]]
if {[file exists $j16_out]} {error "Output directory already exists: $j16_out"}
file mkdir $j16_out/reports
j16_create_project $j16_src $j16_out $j16_vendor
j16_build $j16_out
