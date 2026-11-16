# Unified ADC board entry. Offline only; no hardware manager/debug calls.
# Usage: <new-output> ?base|integrate|synth|audit|validate|build|all? ?vendor-bd?
# validate builds a new candidate through synthesis and constraint checks only.
if {$argc < 1 || $argc > 3} {error "output ?stage? ?vendor-bd?"}
set mc_root [file normalize [file join [file dirname [info script]] ../../..]]
set mc_out [file normalize [lindex $argv 0]]
set mc_stage [expr {$argc>1 ? [lindex $argv 1] : "validate"}]
set mc_vendor [expr {$argc>2 ? [file normalize [lindex $argv 2]] : [file join $mc_root .runtime ax03b2 vendor_ps design_1.bd]}]
if {$mc_stage ni {base integrate synth audit validate build all reports}} {error "unknown stage"}
source $mc_root/hardware/axu5ev/motor_control/bd/adc.tcl
proc mc_base {root out vendor} {
    # Same vendor DDR/UART preset and accepted GEM3/TTC PS configuration as C1.
    set argc 3
    set argv [list xczu5ev-sfvc784-2-i $out $vendor]
    source $root/hardware/axu5ev/eth02_ps_runtime_ethernet.tcl
}
proc mc_build {out} {
    open_project $out/project/ax02a_ps.xpr
    set_param general.maxThreads 8
    set jobs [expr {[info exists ::env(MC_PWM)] && $::env(MC_PWM)==1 ? 2 : 4}]
    launch_runs synth_1 -jobs $jobs
    wait_on_run synth_1
    if {![string match {*Complete*} [get_property STATUS [get_runs synth_1]]]} {error "synthesis failed"}
    launch_runs impl_1 -to_step route_design -jobs $jobs
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
    if {[info exists ::env(MC_PWM)] && $::env(MC_PWM)==1} {
        source $::mc_root/hardware/axu5ev/motor_control/pwm_reports.tcl
        mc_pwm_reports $out
    }
    if {[get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]<0 || \
        [get_property SLACK [get_timing_paths -delay_type min -max_paths 1]]<0} {error "timing failed"}
    write_debug_probes -force $out/ax03b3_adc.ltx
    close_design
    launch_runs impl_1 -to_step write_bitstream -jobs $jobs
    wait_on_run impl_1
    if {![string match {*Complete*} [get_property STATUS [get_runs impl_1]]]} {error "bitstream failed"}
    open_run impl_1
    file copy [get_property DIRECTORY [get_runs impl_1]]/design_1_wrapper.bit $out/ax03b3_adc.bit
    write_hw_platform -fixed -include_bit -file $out/ax03b3_adc.xsa
    close_project
    puts "AX03B3_BUILD_PASS $out/ax03b3_adc.xsa"
}

proc mc_synth {out} {
    open_project $out/project/ax02a_ps.xpr
    set_param general.maxThreads 4
    launch_runs synth_1 -jobs 2
    wait_on_run synth_1
    if {![string match {*Complete*} [get_property STATUS [get_runs synth_1]]]} {error "synthesis failed"}
    close_project
}
proc mc_audit {root out} {
    open_project $out/project/ax02a_ps.xpr
    open_run synth_1
    file mkdir $out/reports
    set f [open $out/reports/source_constraint_checks.txt w]
    foreach kind {handwritten generated constraints} {
        foreach path [mc_sources $root $kind] {
            if {[llength [get_files -quiet $path]] != 1} {error "source missing or duplicate: $path"}
            puts $f "$kind=$path"
        }
    }
    puts $f "synthesis_compile_order:"
    foreach path [get_files -compile_order sources -used_in synthesis] {puts $f $path}
    set cf [open [lindex [mc_sources $root constraints] 0] r]
    set xdc [read $cf]
    close $cf
    set pin_count 0
    foreach line [split $xdc "\n"] {
        if {[regexp {^set_property PACKAGE_PIN ([A-Z0-9]+) \[get_ports \{([^\}]+)\}\]} $line -> expected name]} {
            set port [get_ports -quiet $name]
            if {[llength $port] != 1} {error "port not found: $name"}
            if {[get_property PACKAGE_PIN $port] ne $expected} {error "pin mismatch: $name"}
            if {[get_property IOSTANDARD $port] ne "LVCMOS33"} {error "IOSTANDARD mismatch: $name"}
            puts $f "pin=$name package_pin=$expected IOSTANDARD=LVCMOS33"
            incr pin_count
        }
    }
    if {$pin_count != 28} {error "expected 28 ADC package pins"}
    set inputs [get_ports {adc_data_* adc_otr_*}]
    if {[llength $inputs] != 26} {error "expected 26 ADC input bits"}
    set source [get_pins -hier -filter {NAME =~ */adc_observer_0/s_axi_aclk}]
    if {[llength $source] != 1} {error "ADC generated-clock source miss"}
    puts $f "generated_clock_source=$source"
    foreach name {an9238_clk_a an9238_clk_b} {
        set clock [get_clocks -quiet $name]
        if {[llength $clock] != 1} {error "missing forwarded clock: $name"}
        if {abs([get_property PERIOD $clock]-200.0)>0.01} {error "forwarded clock period changed"}
        puts $f "clock=$name period_ns=[get_property PERIOD $clock] source=[get_property SOURCE_PINS $clock]"
    }
    foreach name {adc_clk_a_o_reg adc_clk_b_o_reg} {
        set cell [get_cells -hier -filter "NAME =~ */$name"]
        if {[llength $cell] != 1} {error "forwarded-clock register hierarchy miss: $name"}
        puts $f "clock_register=$cell IOB=[get_property IOB $cell]"
    }
    close $f
    write_xdc -force $out/reports/expanded_constraints.xdc
    report_io -file $out/reports/io.rpt
    report_clocks -file $out/reports/clocks.rpt
    check_timing -verbose -file $out/reports/check_timing.rpt
    report_timing -from $inputs -delay_type max -max_paths 26 -file $out/reports/adc_setup_synth.rpt
    report_timing -from $inputs -delay_type min -max_paths 26 -file $out/reports/adc_hold_synth.rpt
    report_utilization -file $out/reports/utilization_synth.rpt
    puts "ADC_CONSOLIDATION_SYNTH_AUDIT_PASS pins=$pin_count inputs=[llength $inputs]"
    close_project
}
if {$mc_stage in {base validate all}} {mc_base $mc_root $mc_out $mc_vendor}
if {$mc_stage in {integrate validate all}} {mc_integrate $mc_root $mc_out}
if {$mc_stage in {synth validate}} {mc_synth $mc_out}
if {$mc_stage in {audit validate}} {mc_audit $mc_root $mc_out}
if {$mc_stage in {build all}} {mc_build $mc_out}
if {$mc_stage eq "reports"} {
    open_project $mc_out/project/ax02a_ps.xpr
    open_run impl_1
    source $mc_root/hardware/axu5ev/motor_control/pwm_reports.tcl
    mc_pwm_reports $mc_out
    close_project
}
