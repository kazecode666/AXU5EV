# Read-only directed audit of an adopted routed encoder candidate.
# Usage: vivado -mode batch -source encoder_audit.tcl -tclargs DCP NEW_OUT XDC
if {$argc!=3} {error "Expected routed DCP, new audit directory, original ADC XDC"}
set checkpoint [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
set xdc [file normalize [lindex $argv 2]]
if {[file exists $out]} {error "Preserve existing audit output; choose a new directory"}
file mkdir $out
open_checkpoint $checkpoint
set summary [open $out/paths.tsv w]
puts $summary "group\tretained_sequential_cells\ttimed_endpoints\tmax_slack_ns\tmin_slack_ns"
set allregs [get_cells -hier -filter {IS_SEQUENTIAL == 1}]
set syncs [filter $allregs {NAME =~ *encoder*receiver*sync?_reg*}]
if {[llength $syncs]!=6} {error "Expected six retained ABZ two-stage synchronizer cells"}
set sf [open $out/abz_synchronizers.tsv w]
foreach cell $syncs {
    if {![get_property ASYNC_REG $cell]} {error "ABZ synchronizer lost ASYNC_REG: $cell"}
    puts $sf "$cell\tASYNC_REG=TRUE"
}
close $sf
foreach {group pattern} {
    angle {*generated_angle*}
    sample_metadata {*sample_encoder_reg*}
    seven_event_metadata {*meta_pipe_reg*}
    pair_metadata {*pair_meta_reg*}
    current_join {*current_frame_reg*}
    theta_join {*theta_frame_reg*}
    snapshot_latest {*snapshot*latest_payload_reg*}
    snapshot_frozen {*snapshot*frozen_payload_reg*}
} {
    set regs [filter $allregs "NAME =~ $pattern"]
    if {[llength $regs]==0} {error "Missing new functional state: $group"}
    set ends {}
    foreach delay {max min} {
        # Cell targets retain DSP/CE endpoints too, not only FDRE D pins.
        set paths [get_timing_paths -to $regs -delay_type $delay -max_paths [expr {[llength $regs]*64}] -nworst 1 -no_report_unconstrained]
        if {[llength $paths]==0} {error "Missing constrained $group $delay paths"}
        set worst($delay) 1e9
        foreach p $paths {
            set slack [get_property SLACK $p]
            if {$slack<0} {error "New encoder path failed: $group $delay $slack"}
            if {$slack<$worst($delay)} {set worst($delay) $slack}
            if {$delay eq "max"} {lappend ends [get_property ENDPOINT_PIN $p]}
        }
        report_timing -to $regs -delay_type $delay -max_paths 5 -path_type full_clock_expanded -file $out/${group}_${delay}.rpt
    }
    puts $summary "$group\t[llength $regs]\t[llength [lsort -unique $ends]]\t$worst(max)\t$worst(min)"
}
close $summary

# Actual routed IO properties must still agree with all28 original J15 pins.
set f [open $xdc r];set constraints [read $f];close $f
set f [open $out/adc_pins.tsv w];set pin_count 0
foreach line [split $constraints "\n"] {
    if {[regexp {^set_property PACKAGE_PIN ([A-Z0-9]+) \[get_ports \{([^\}]+)\}\]} $line -> expected name]} {
        set port [get_ports -quiet $name]
        if {[llength $port]!=1 || [get_property PACKAGE_PIN $port] ne $expected || [get_property IOSTANDARD $port] ne "LVCMOS33"} {error "ADC IO mismatch: $name"}
        puts $f "$name\t$expected\tLVCMOS33";incr pin_count
    }
}
close $f
if {$pin_count!=28} {error "Expected28 original ADC ports"}
set inputs [get_ports {adc_data_* adc_otr_*}]
if {[llength $inputs]!=26} {error "Expected26 original ADC input bits"}
set f [open $out/adc_delay.tsv w]
foreach port $inputs {
    foreach {delay expected} {min 2.0 max 10.0} {
        set report [report_timing -from $port -delay_type $delay -max_paths 1 -return_string]
        if {![regexp {Input Delay:\s+([-0-9.]+)ns} $report -> observed] || abs($observed-$expected)>0.000001} {error "ADC input budget changed: $port $delay"}
        set path [get_timing_paths -from $port -delay_type $delay -max_paths 1 -no_report_unconstrained]
        if {[llength $path]!=1 || [get_property SLACK $path]<0} {error "ADC IO timing failed: $port $delay"}
        puts $f "$port\t$delay\t$observed\t[get_property SLACK $path]"
    }
}
close $f

report_timing_summary -delay_type min_max -check_timing_verbose -file $out/timing_summary.rpt
check_timing -verbose -file $out/check_timing.rpt
report_io -file $out/io.rpt
report_clocks -file $out/clocks.rpt
report_exceptions -file $out/exceptions.rpt
write_xdc $out/expanded_constraints.xdc
puts "ENCODER_ROUTED_AUDIT_PASS pins=$pin_count inputs=[llength $inputs]"
close_design
exit
