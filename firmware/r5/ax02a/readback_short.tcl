# Passive definitions only. source does not query a target or transfer data.
namespace eval ax02a_short {
    proc symbol {name} {
        set values [print -dict $name]
        if {![dict exists $values $name]} {error "Cannot resolve symbol: $name"}
        set v [dict get $values $name]
        if {![string is entier -strict $v] || $v < -2147483648 || $v > 4294967295} {error "Invalid uint32 symbol: $name"}
        if {$v<0} {set v [expr {$v+4294967296}]}
        return $v
    }
    proc scalar {field} {
        return [symbol ax02a_control.$field]
    }
    proc bytes {dir name base total} {
        set partial [file join $dir $name.partial]
        set dest [open $partial {WRONLY CREAT EXCL}]
        fconfigure $dest -translation binary
        try {
            for {set offset 0} {$offset < $total} {incr offset 65536} {
                set count [expr {min(65536,$total-$offset)}]
                set part [file join $dir [format "%s_%08d.bin" $name $offset]]
                mrd -size b -bin -file $part [expr {$base+$offset}] $count
                if {![file isfile $part] || [file size $part]!=$count} {error "Short read: $part"}
                set src [open $part rb]; fconfigure $src -translation binary
                try {fcopy $src $dest} finally {close $src}
            }
        } finally {close $dest}
        if {[file size $partial]!=$total} {error "Merged length mismatch: $partial"}
        file rename $partial [file join $dir $name]
    }
    proc readback {dir before_experiment conditions interrupted {candidate_file {}}} {
        if {$interrupted ni {true false}} {error "Explicitly declare interrupted true or false; omitted/unknown is not accepted"}
        # Explicit user call only, in the existing GUI XSDB session, after timer stop.
        set current {}
        foreach p [targets -target-properties] {
            if {[dict get $p is_current]} {set current $p}
        }
        if {$current eq {} || [dict get $current name] ne "Cortex-R5 #0" ||
            ![dict exists $current suspended] || ![dict get $current suspended]} {
            error "Select the already-paused R5_0 completion target in GUI first; no target selection performed"
        }
        if {[file exists $dir] || $before_experiment<0 || $before_experiment>=4294967295} {
            error "Use a new directory and this-run before_experiment, not a fixed experiment=1"
        }
        if {![regexp {^[A-Za-z0-9 ,_.:/+-]+$} $conditions]} {error "Describe cold/warm/cache conditions using plain ASCII"}
        foreach f {state command frames mode experiment result.status result.completed_frames result.failed_frame} {
            dict set v $f [scalar $f]
        }
        if {[dict get $v state] ni {3 4} || [dict get $v command]!=0 ||
            [dict get $v mode]!=1 || [dict get $v frames]!=1000 ||
            [dict get $v experiment]!=$before_experiment+1} {
            error "Not this P1000 completed/failed experiment; do not read running or stale buffers"
        }
        set n [dict get $v result.completed_frames]
        set status [dict get $v result.status]
        if {$n<0 || $n>1000 || $status ni {0 1 2 3 4} ||
            ($status==0 && ($n!=1000 || [dict get $v state]!=3)) ||
            ($status!=0 && ([dict get $v state]!=4 || $n>=1000 ||
                [dict get $v result.failed_frame]!=$n)) ||
            ($status in {3 4} && $n!=0)} {error "Inconsistent completion count/state"}
        set timer {}
        set timer_values {}
        foreach f {clock_hz interval prescaler period_ticks timestamp_read_min_ticks timestamp_read_max_ticks start_window_ticks} {
            set value [scalar timer.$f]
            dict set timer_values $f $value
            lappend timer [format {"%s":%lld} $f $value]
        }
        set identity {}
        set timer_ok 1
        if {$candidate_file ne {}} {
            set f [open $candidate_file r];try {set words [string trim [read $f]]} finally {close $f}
            if {[lrange $words 0 1] ne {dict create}} {error "Invalid passive runtime candidate record"}
            set candidate [lrange $words 2 end]
            foreach key {candidate_id mapping_version workspace elf} {if {![dict exists $candidate $key]} {error "Missing runtime candidate $key"}}
            foreach key {workspace elf} {if {[regexp {["\\\n\r]} [dict get $candidate $key]]} {error "Unsafe candidate path"}}
            if {[dict get $candidate candidate_id]!=0x52313031 || [dict get $candidate mapping_version]!=1 ||
                [symbol ax02a_runtime_candidate_id]!=0x52313031 || [symbol ax02a_timer_mapping_version]!=1} {
                error "Runtime R1 candidate identity mismatch"
            }
            # Snapshot globals may contain invalid/previous fields after prepare
            # fails. Preserve actual values and valid flag, never infer success.
            set snapshot {}; set snapshot_values {}
            foreach key {valid periodic_base timestamp_base periodic_hz timestamp_hz hardware_interval logical_period_ticks periodic_clock timestamp_clock periodic_control timestamp_control periodic_ier timestamp_ier} {
                set value [symbol ax02a_ttc_snapshot.$key]
                dict set snapshot_values $key $value
                lappend snapshot [format {"%s":%lld} $key $value]
            }
            foreach {key expected} {clock_hz 100000000 interval 9999 period_ticks 10000 prescaler 16} {
                if {[dict get $timer_values $key]!=$expected} {set timer_ok 0}
            }
            foreach {key expected} {valid 1 hardware_interval 9999 logical_period_ticks 10000 periodic_hz 100000000 timestamp_hz 100000000} {
                if {[dict get $snapshot_values $key]!=$expected} {set timer_ok 0}
            }
            foreach {key expected} {periodic_base 4279304192 timestamp_base 4279304196 periodic_clock 0 timestamp_clock 0} {
                set value [dict get $snapshot_values $key]
                if {$value!=$expected} {set timer_ok 0}
                lappend timer [format {"%s":%lld} $key $value]
            }
            if {$status==0 && !$timer_ok} {error "Runtime R1 snapshot/timer mismatch on successful experiment"}
            lappend timer {"mapping_version":1} {"candidate_id":1378955313}
            set identity [format {,"before_experiment":%lld,"candidate":{"workspace":"%s","elf":"%s"},"ttc_snapshot":{%s},"timer_snapshot_valid":%s} $before_experiment [dict get $candidate workspace] [dict get $candidate elf] [join $snapshot ,] [expr {$timer_ok?"true":"false"}]]
        }
        # Failed frame is excluded. No DDR output/ticks exist on early failure;
        # uncertain timer/configuration also cannot establish a valid prefix.
        set captured [expr {$timer_ok && $status in {0 1 2} ? $n : 0}]
        set report_captured false
        if {$candidate_file ne {} && $status==0 && [symbol ax02a_post_control.state]==2} {set report_captured true}
        set report_validity [expr {$report_captured?"UNVALIDATED_REQUIRES_PC_CROSSCHECK":"NOT_CAPTURED"}]
        file mkdir $dir
        set state [open [file join $dir run.json] {WRONLY CREAT EXCL}]
        puts $state [format {{"scenario":"current_motion_prefix","state":%lld,"mode":1,"frames":1000,"experiment":%lld,"interrupted":%s,"conditions":"%s","result":{"status":%lld,"completed_frames":%lld,"failed_frame":%lld},"timer":{%s},"captured_records":%lld,"report_captured":%s,"report_validity":"%s"%s}} [dict get $v state] [dict get $v experiment] $interrupted $conditions $status $n [dict get $v result.failed_frame] [join $timer ,] $captured $report_captured $report_validity $identity]
        close $state
        # Only fully completed records are valid; failed_frame may be unwritten/partial.
        if {$captured>0} {
            bytes $dir output.bin 0x11000000 [expr {$captured*41*8}]
            bytes $dir timing.bin 0x13000000 [expr {$captured*64}]
        }
        if {$report_captured} {bytes $dir report_v2.bin 0x16000000 2400}
        puts "AX02A_SHORT_READBACK_COMPLETE: $n completed, $captured captured records; report $report_validity; inspect run.json before judging PASS"
    }
}
