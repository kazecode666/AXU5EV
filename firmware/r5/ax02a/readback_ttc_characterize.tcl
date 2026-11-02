# Passive definitions. Source does not contact a target or load provenance.
namespace eval ax02a_ttc_char {
    proc uint32 {value} {
        if {![string is entier -strict $value] || $value < -2147483648 || $value > 4294967295} {error "Value is not a signed/unsigned uint32 representation"}
        if {$value < 0} {return [expr {$value + 4294967296}]}
        return [expr {wide($value)}]
    }
    proc address {value} {
        if {[llength $value]==1} {return [uint32 [lindex $value 0]]}
        if {[llength $value]!=4} {error "Address requires one integer or four little-endian bytes"}
        set result 0;set shift 0
        foreach byte $value {
            if {![string is entier -strict $byte] || $byte<0 || $byte>255} {error "Address byte out of range"}
            set result [expr {$result | (wide($byte) << $shift)}];incr shift 8
        }
        return $result
    }
    proc scalar {field} {
        set symbol ax02a_ttc_char_control.$field
        set value [print -dict $symbol]
        if {![dict exists $value $symbol]} {error "Missing diagnostic symbol: $symbol"}
        return [uint32 [dict get $value $symbol]]
    }
    proc readback {dir case_id before_experiment raw provenance session_id conditions interrupted} {
        # Explicit call in the existing user's XSDB session, at done only.
        if {$interrupted ni {true false}} {error "Declare debugger interruption true or false"}
        if {[file exists $dir]} {error "Directory exists; never overwrite captures"}
        set cases [dict create A1 1 B 2 A2 3 C 4]
        set raws [dict create A1 10000 B 9999 A2 10000 C 10001]
        if {![dict exists $cases $case_id] || $raw!=[dict get $raws $case_id] ||
            $before_experiment<0 || $before_experiment>=4294967295} {error "Invalid case/raw/before experiment"}
        foreach text [list $session_id $conditions] {
            if {![regexp {^[A-Za-z0-9 ,_.:/+-]+$} $text]} {error "Use nonempty ASCII session and conditions"}
        }
        set current {}
        foreach target [targets -target-properties] {
            if {[dict get $target is_current]} {set current $target}
        }
        if {$current eq {} || [dict get $current name] ne "Cortex-R5 #0" ||
            ![dict exists $current suspended] || ![dict get $current suspended]} {error "Use the already paused R5_0 at done; no target selection performed"}
        # Builder writes a passive dict expression; parse as list, never eval/source it.
        set f [open $provenance r];try {set words [string trim [read $f]]} finally {close $f}
        if {[lrange $words 0 1] ne {dict create}} {error "Invalid candidate provenance"}
        set prov [lrange $words 2 end]
        foreach k {build_id workspace elf samples_address} {if {![dict exists $prov $k]} {error "Missing provenance: $k"}}
        dict set prov build_id [uint32 [dict get $prov build_id]]
        dict set prov samples_address [uint32 [dict get $prov samples_address]]
        foreach k {workspace elf} {
            if {[regexp {["\\\n\r]} [dict get $prov $k]]} {error "Unsafe provenance path"}
        }
        set fields {magic version record_bytes state command experiment case_id requested_raw actual_raw nominal_period requested_samples completed_samples error timeout_ticks periodic_hz timestamp_hz periodic_base timestamp_base periodic_clock timestamp_clock periodic_control timestamp_control periodic_ier timestamp_ier build_id}
        foreach field $fields {dict set v $field [scalar $field]}
        if {[dict get $v magic]!=0x31435454 || [dict get $v version]!=1 || [dict get $v record_bytes]!=16 ||
            [dict get $v build_id]!=[dict get $prov build_id] || [dict get $v build_id]==0 ||
            [dict get $v state] ni {3 4} || [dict get $v command]!=0 ||
            [dict get $v experiment]!=$before_experiment+1 || [dict get $v case_id]!=[dict get $cases $case_id] ||
            [dict get $v requested_raw]!=$raw || [dict get $v nominal_period]!=10000 ||
            [dict get $v requested_samples]!=1000} {error "Wrong diagnostic protocol/candidate/case/experiment/state"}
        set n [dict get $v completed_samples]
        if {$n<0 || $n>1000 || ([dict get $v state]==3 && ($n!=1000 || [dict get $v error]!=0)) ||
            ([dict get $v state]==4 && [dict get $v error]==0)} {error "Invalid completion/error count"}
        # Failed prepare may have actual_raw=0; preserve that failure without
        # representing it as a completed acquisition or reading stale records.
        if {[dict get $v actual_raw]!=$raw && !($n==0 && [dict get $v state]==4 && [dict get $v actual_raw]==0)} {error "Actual raw mismatch"}
        set symbol &ax02a_ttc_char_samples
        set address [print -dict $symbol]
        if {![dict exists $address $symbol] || [address [dict get $address $symbol]]!=[dict get $prov samples_address]} {error "Candidate sample symbol mismatch"}
        set config {}
        foreach field {periodic_hz timestamp_hz periodic_base timestamp_base periodic_clock timestamp_clock periodic_control timestamp_control periodic_ier timestamp_ier} {
            lappend config [format {"%s":%lld} $field [dict get $v $field]]
        }
        set members {}
        foreach field {magic version record_bytes state experiment requested_raw actual_raw nominal_period requested_samples completed_samples error timeout_ticks build_id} {
            lappend members [format {"%s":%lld} $field [dict get $v $field]]
        }
        file mkdir $dir
        set f [open [file join $dir run.json] {WRONLY CREAT EXCL}]
        try {
            puts $f [format {{%s,"case_id":"%s","before_experiment":%lld,"interrupted":%s,"session_id":"%s","conditions":"%s","workspace":"%s","elf":"%s","clock_basis":"BSP configuration, not measured","config":{%s}}} [join $members ,] $case_id $before_experiment $interrupted $session_id $conditions [dict get $prov workspace] [dict get $prov elf] [join $config ,]]
        } finally {close $f}
        set path [file join $dir samples.bin]
        if {$n==0} {set f [open $path {WRONLY CREAT EXCL}];close $f} else {
            set partial $path.partial
            mrd -size b -bin -file $partial [dict get $prov samples_address] [expr {$n*16}]
            if {![file isfile $partial] || [file size $partial]!=$n*16} {error "Short read; retain partial and failure metadata"}
            file rename $partial $path
        }
        puts "TTC_READBACK_SAVED: $case_id, $n records; collection complete is not period PASS"
    }
}
