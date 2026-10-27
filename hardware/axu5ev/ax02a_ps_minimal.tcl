# PS-only platform. No synthesis, PL image, board connection, or download.
# Usage: vivado -mode batch -source ... -tclargs <part> <new-output-dir> <vendor-bd>
if {$argc != 3} { error "expected: part new-output-dir vendor-bd" }
# PS IP callbacks mutate global variables (including 'config'). Keep all build
# state local; the reproduced global collision replaced 3376 values with 54.
proc ax02a_build_platform {part out source_bd} {
set out [file normalize $out]
if {[file exists $out]} { error "output directory already exists: $out" }
if {![file exists $source_bd]} { error "missing vendor PS BD: $source_bd" }
if {[llength [get_parts -quiet $part]] != 1} { error "part unavailable: $part" }
file mkdir $out
create_project ax02a_ps $out/project -part $part
# Upgrade only a copy of the vendor customization. The 2020.1 BD itself cannot
# be opened without its retired 3.3 catalog entry, even with its XCI registered.
# Native XCI upgrade applies AMD's parameter migration before creating the BD.
set ip_name design_1_zynq_ultra_ps_e_0_0
set source_xci [file dirname $source_bd]/ip/$ip_name/$ip_name.xci
if {![file exists $source_xci]} { error "missing vendor PS customization: $source_xci" }
set xci $out/vendor_ip/$ip_name.xci
file mkdir [file dirname $xci]
file copy $source_xci $xci
add_files -norecurse $xci
set old_ip [get_ips $ip_name]
upgrade_ip $old_ip
set vlnv [get_property IPDEF $old_ip]
set config [list]
foreach prop [list_property $old_ip] {
    # Copy hardware/user parameters, not GUI presets or interface metadata.
    # AXI frequencies and interrupt/TSU metadata below are owned by the BD.
    if {[regexp {^CONFIG\.(PSU[^.]*|[A-Z0-9_]+_BOARD_INTERFACE)$} $prop]
            && ![regexp {^CONFIG\.PSU__([MS]_AXI_GP[0-9]__FREQMHZ|NUM_F2P[01]__INTR__INPUTS|TSU__BUFG_PORT_LOOPBACK)$} $prop]} {
        lappend config $prop [get_property $prop $old_ip]
    }
}
remove_files [get_files $xci]
create_bd_design design_1
set ps [create_bd_cell -type ip -vlnv $vlnv zynq_ultra_ps_e_0]
set_property -dict $config $ps
set bd [get_files */design_1.bd]
# Retain vendor DDR timing/MIO/electrical setup. Disable unrelated peripherals.
set disable [list]
foreach prop [list_property $ps] {
    if {[regexp {^CONFIG\.PSU__(.+)__PERIPHERAL__ENABLE$} $prop -> peripheral] \
            && $peripheral ni {UART0 TTC0} && [get_property $prop $ps] eq {1}} {
        lappend disable $prop 0
    }
}
set_property -dict [concat $disable [list \
    CONFIG.PSU__USE__M_AXI_GP0 {0} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
    CONFIG.PSU__USE__FABRIC__RST {0} \
    CONFIG.PSU__FPGA_PL0_ENABLE {0} \
    CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TTC2__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TTC3__PERIPHERAL__ENABLE {0}]] $ps
if {[get_property CONFIG.PSU__DDRC__BUS_WIDTH $ps] ne {64 Bit} \
        || [get_property CONFIG.PSU__DDRC__DRAM_WIDTH $ps] ne {16 Bits} \
        || [get_property CONFIG.PSU__UART0__PERIPHERAL__IO $ps] ne {MIO 42 .. 43}} {
    error "DDR/UART mismatch: bus=[get_property CONFIG.PSU__DDRC__BUS_WIDTH $ps], DRAM=[get_property CONFIG.PSU__DDRC__DRAM_WIDTH $ps], UART=[get_property CONFIG.PSU__UART0__PERIPHERAL__IO $ps]"
}
validate_bd_design
save_bd_design
generate_target all [get_files $bd]
set wrapper [make_wrapper -files [get_files $bd] -top]
add_files -norecurse $wrapper
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1
write_hw_platform -fixed -force -file $out/ax02a_ps.xsa
set info [open $out/platform_settings.txt w]
puts $info "Vivado=[version -short]\npart=$part\nsource=$source_bd\nprocessor=psu_cortexr5_0\nRPU_runtime_mode=split (set by authorized debug launch; not a board measurement)"
foreach prop [lsort [list_property $ps]] {
    if {[regexp {^CONFIG\.PSU__(CR[FL]_APB__|DDR|UART0|TTC0|PSS_REF_CLK|RPU)} $prop]} {
        puts $info "$prop=[get_property $prop $ps]"
    }
}
close $info
puts "AX02A_XSA_BUILD_PASS $out/ax02a_ps.xsa"
close_project
}
ax02a_build_platform {*}$argv
