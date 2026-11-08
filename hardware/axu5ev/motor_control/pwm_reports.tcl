# Called on the actual new routed candidate, never on a historical checkpoint.
proc mc_pwm_reports {out} {
    set report_dir $out/reports
    report_clock_interaction -delay_type min_max -file $report_dir/clock_interaction.rpt
    report_cdc -details -file $report_dir/cdc.rpt
    report_timing -delay_type max -max_paths 20 -path_type full_clock_expanded -file $report_dir/worst_setup.rpt
    report_timing -delay_type min -max_paths 20 -path_type full_clock_expanded -file $report_dir/worst_hold.rpt
    report_pulse_width -all_violators -file $report_dir/pulse_width.rpt
    write_xdc -force $report_dir/expanded_constraints.xdc
    set pwm [get_clocks -of_objects [get_pins design_1_i/pwm_control_0/pwm_clk]]
    set adc [get_clocks -of_objects [get_pins design_1_i/adc_observer_0/s_axi_aclk]]
    if {[llength $pwm]!=1 || [llength $adc]!=1} {error "clock coverage"}
    if {abs([get_property PERIOD $adc]/[get_property PERIOD $pwm]-2.0)>0.000001} {error "2:1 timing clock ratio"}
    foreach direction {forward reverse} {
        if {$direction eq "forward"} {set from $adc;set to $pwm} else {set from $pwm;set to $adc}
        foreach delay {min max} {
            set paths [get_timing_paths -from $from -to $to -delay_type $delay -max_paths 10]
            if {[llength $paths]==0} {error "missing related $direction $delay paths"}
            foreach p $paths {if {[get_property SLACK $p]<0} {error "related clock timing failed"}}
            report_timing -from $from -to $to -delay_type $delay -max_paths 10 -path_type full_clock_expanded -file $report_dir/related_${direction}_${delay}.rpt
        }
    }
    write_checkpoint $out/pwm_adc_routed.dcp
    file mkdir $out/timing_sim
    # PS/SmartConnect/ILA remain covered by whole-design STA. Export actual
    # routed ADC/PWM/MMCM cells for bounded PL timing simulation without PS VIP.
    foreach {name cell} {adc_routed adc_observer_0 pwm_routed pwm_control_0 clock_routed pwm_clock} {
        set target [get_cells design_1_i/$cell]
        if {[llength $target]!=1} {error "SDF boundary missing: $cell"}
        write_verilog -mode timesim -cell $target -rename_top $name $out/timing_sim/$name.v
        foreach corner {slow fast} {
            write_sdf -process_corner $corner -cell $target -rename_top $name $out/timing_sim/${name}_${corner}.sdf
        }
    }
}
