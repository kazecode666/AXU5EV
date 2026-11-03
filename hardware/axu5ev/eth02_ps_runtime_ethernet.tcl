# Offline PS-only integration: accepted DDR/UART/TTC0 plus ETH01 GEM3/MDIO.
# No synthesis, bitstream, debugger or board access.
if {$argc != 3} {error "expected part new-output vendor-bd"}
set eth02_out [file normalize [lindex $argv 1]]
source [file join [file dirname [info script]] ax02a_ps_minimal.tcl]
open_project $eth02_out/project/ax02a_ps.xpr
open_bd_design [get_files */design_1.bd]
set eth02_ps [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__ENET3__PERIPHERAL__ENABLE 1 \
 CONFIG.PSU__ENET3__PERIPHERAL__IO {MIO 64 .. 75} \
 CONFIG.PSU__ENET3__GRP_MDIO__ENABLE 1 \
 CONFIG.PSU__ENET3__GRP_MDIO__IO {MIO 76 .. 77} \
 CONFIG.PSU__TTC0__PERIPHERAL__ENABLE 1] $eth02_ps
validate_bd_design
save_bd_design
generate_target all [get_files */design_1.bd]
write_hw_platform -fixed -file $eth02_out/eth02_ps.xsa
set eth02_f [open $eth02_out/integrated_settings.txt w]
foreach eth02_p [lsort [list_property $eth02_ps]] {
 if {[regexp {^CONFIG.PSU__(ENET3|TTC0|CRL_APB__|MIO_(6[4-9]|7[0-7])|BANK_2)} $eth02_p]} {
  puts $eth02_f "$eth02_p=[get_property $eth02_p $eth02_ps]"
 }
}
close $eth02_f
puts "ETH02_XSA_PASS $eth02_out/eth02_ps.xsa"
close_project
