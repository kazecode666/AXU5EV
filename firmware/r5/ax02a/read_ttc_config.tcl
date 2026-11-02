# Passive definitions only. USER calls read_config at pre-begin, counters stopped.
namespace eval ax02a_ttc {
    proc read_config {path stage} {
        if {$stage ne "pre_begin"} {error "Use only at timing.c begin entry, before counters start"}
        set current {}
        foreach p [targets -target-properties] {
            if {[dict get $p is_current]} {set current $p}
        }
        if {$current eq {} || [dict get $current name] ne "Cortex-R5 #0" ||
            ![dict exists $current suspended] || ![dict get $current suspended]} {error "User must select already-paused R5_0"}
        if {[file exists $path]} {error "Preserve old evidence; use a new file"}
        set pc [lindex [mrd -value 0xff11000c] 0]
        set tc [lindex [mrd -value 0xff110010] 0]
        if {!(($pc&1)&&($tc&1))} {error "Counters are enabled; no additional reads permitted"}
        set rows {}
        foreach {name address} {
            periodic_clock 0xff110000 timestamp_clock 0xff110004
            hardware_interval 0xff110024 timestamp_interval 0xff110028
            periodic_ier 0xff110060 timestamp_ier 0xff110064
            ttc_apb_select 0xff180380 lpd_lsbus_ctrl 0xff5e00ac iopll_ctrl 0xff5e0020
        } {
            set value [expr {wide([lindex [mrd -value $address] 0])}]
            lappend rows [format {"%s":%d} $name $value]
        }
        lappend rows [format {"periodic_control":%d,"timestamp_control":%d} $pc $tc]
        set f [open $path {WRONLY CREAT EXCL}]
        try {puts $f [format {{"stage":"pre_begin","registers":{%s}}} [join $rows ,]]} finally {close $f}
        puts "AX02A_TTC_CONFIG_SAVED: $path; configuration only, not N/N+1 root-cause proof"
    }
}
