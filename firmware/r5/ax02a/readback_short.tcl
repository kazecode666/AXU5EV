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
        if {$n<0 || $n>1000 || ([dict get $v result.status]==0 &&
            ($n!=1000 || [dict get $v state]!=3))} {error "Inconsistent completion count/state"}
        set timer {}
        foreach f {clock_hz interval prescaler period_ticks timestamp_read_min_ticks timestamp_read_max_ticks start_window_ticks} {
            lappend timer [format {"%s":%lld} $f [scalar timer.$f]]
        }
        set identity {}
        if {$candidate_file ne {}} {
            set f [open $candidate_file r];try {set words [string trim [read $f]]} finally {close $f}
            if {[lrange $words 0 1] ne {dict create}} {error "Invalid passive runtime candidate record"}
            set candidate [lrange $words 2 end]
            foreach key {candidate_id mapping_version workspace elf} {if {![dict exists $candidate $key]} {error "Missing runtime candidate $key"}}
            foreach key {workspace elf} {if {[regexp {["\\\n\r]} [dict get $candidate $key]]} {error "Unsafe candidate path"}}
            if {[dict get $candidate candidate_id]!=0x52313031 || [dict get $candidate mapping_version]!=1 ||
                [symbol ax02a_runtime_candidate_id]!=0x52313031 || [symbol ax02a_timer_mapping_version]!=1 ||
                [scalar timer.clock_hz]!=100000000 || [scalar timer.interval]!=9999 ||
                [scalar timer.period_ticks]!=10000 || [scalar timer.prescaler]!=16 ||
                [symbol ax02a_ttc_snapshot.valid]!=1 || [symbol ax02a_ttc_snapshot.hardware_interval]!=9999 ||
                [symbol ax02a_ttc_snapshot.logical_period_ticks]!=10000 ||
                [symbol ax02a_ttc_snapshot.periodic_hz]!=100000000 || [symbol ax02a_ttc_snapshot.timestamp_hz]!=100000000} {error "Runtime R1 candidate/snapshot/timer mismatch"}
            foreach {key expected} {periodic_base 4279304192 timestamp_base 4279304196 periodic_clock 0 timestamp_clock 0} {
                set value [symbol ax02a_ttc_snapshot.$key]
                if {$value!=$expected} {error "Runtime R1 configuration mismatch: $key"}
                lappend timer [format {"%s":%lld} $key $value]
            }
            lappend timer {"mapping_version":1} {"candidate_id":1378955313}
            set identity [format {,"before_experiment":%lld,"candidate":{"workspace":"%s","elf":"%s"}} $before_experiment [dict get $candidate workspace] [dict get $candidate elf]]
        }
        file mkdir $dir
        set state [open [file join $dir run.json] {WRONLY CREAT EXCL}]
        puts $state [format {{"scenario":"current_motion_prefix","state":%lld,"mode":1,"frames":1000,"experiment":%lld,"interrupted":%s,"conditions":"%s","result":{"status":%lld,"completed_frames":%lld,"failed_frame":%lld},"timer":{%s}%s}} [dict get $v state] [dict get $v experiment] $interrupted $conditions [dict get $v result.status] $n [dict get $v result.failed_frame] [join $timer ,] $identity]
        close $state
        # Only fully completed records are valid; failed_frame may be unwritten/partial.
        bytes $dir output.bin 0x11000000 [expr {$n*41*8}]
        bytes $dir timing.bin 0x13000000 [expr {$n*64}]
        if {$candidate_file ne {}} {bytes $dir report_v2.bin 0x16000000 2400}
        puts "AX02A_SHORT_READBACK_COMPLETE: $n completed records; analyze run.json before judging PASS"
    }
}
