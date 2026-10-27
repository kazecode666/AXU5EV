# PS-only platform. No synthesis, PL image, board connection, or download.
# Usage: vivado -mode batch -source ... -tclargs <part> <new-output-dir> <vendor-bd>
if {$argc != 3} { error "expected: part new-output-dir vendor-bd" }
lassign $argv part out source_bd
set out [file normalize $out]
if {[file exists $out]} { error "output directory already exists: $out" }
if {![file exists $source_bd]} { error "missing vendor PS BD: $source_bd" }
if {[llength [get_parts -quiet $part]] != 1} { error "part unavailable: $part" }
file mkdir $out
create_project ax02a_ps $out/project -part $part
# Work on exactly one copied BD; never open/upgrade the vendor project in place.
file copy $source_bd $out/design_1.bd
add_files -norecurse $out/design_1.bd
open_bd_design $out/design_1.bd
set ps [get_bd_cells -hier -filter {VLNV =~ "xilinx.com:ip:zynq_ultra_ps_e:*"}]
if {[llength $ps] != 1 || [llength [get_bd_cells]] != 1} {
    error "expected vendor hello design containing exactly one PS cell"
}
upgrade_bd_cells $ps
# Retain vendor DDR timing/MIO/electrical setup. Disable unrelated peripherals.
foreach prop [list_property $ps] {
    if {[regexp {^CONFIG\.PSU__(.+)__PERIPHERAL__ENABLE$} $prop -> peripheral] \
            && $peripheral ni {UART0 TTC0}} {
        set_property $prop 0 $ps
    }
}
set_property -dict [list \
    CONFIG.PSU__USE__M_AXI_GP0 {0} \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__M_AXI_GP2 {0} \
    CONFIG.PSU__USE__FABRIC__RST {0} \
    CONFIG.PSU__FPGA_PL0_ENABLE {0} \
    CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
    CONFIG.PSU__TTC1__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TTC2__PERIPHERAL__ENABLE {0} \
    CONFIG.PSU__TTC3__PERIPHERAL__ENABLE {0}] $ps
if {[get_property CONFIG.PSU__DDRC__BUS_WIDTH $ps] ne {64 Bit} \
        || [get_property CONFIG.PSU__DDRC__DRAM_WIDTH $ps] ne {16 Bits} \
        || [get_property CONFIG.PSU__UART0__PERIPHERAL__IO $ps] ne {MIO 42 .. 43}} {
    error "vendor DDR/UART settings differ from the AXU5EVB-E manual"
}
validate_bd_design
save_bd_design
generate_target all [get_files $out/design_1.bd]
set wrapper [make_wrapper -files [get_files $out/design_1.bd] -top]
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
