# Offline only. Reuse accepted vendor DDR migration in a NEW output directory.
# vivado -mode batch -source this.tcl -tclargs part new-output vendor-bd
if {$argc != 3} {error "expected part new-output vendor-bd"}
set eth_out [file normalize [lindex $argv 1]]
source [file join [file dirname [info script]] ax02a_ps_minimal.tcl]
open_project $eth_out/project/ax02a_ps.xpr
open_bd_design [get_files */design_1.bd]
set eth_ps [get_bd_cells zynq_ultra_ps_e_0]
set_property -dict [list CONFIG.PSU__ENET3__PERIPHERAL__ENABLE 1 \
 CONFIG.PSU__ENET3__PERIPHERAL__IO {MIO 64 .. 75} \
 CONFIG.PSU__ENET3__GRP_MDIO__ENABLE 1 \
 CONFIG.PSU__ENET3__GRP_MDIO__IO {MIO 76 .. 77} \
 CONFIG.PSU__TTC0__PERIPHERAL__ENABLE 0] $eth_ps
validate_bd_design
save_bd_design
generate_target all [get_files */design_1.bd]
write_hw_platform -fixed -file $eth_out/eth01_ps.xsa
set eth_f [open $eth_out/ethernet_settings.txt w]
foreach eth_p [lsort [list_property $eth_ps]] {
 if {[regexp {^CONFIG.PSU__(ENET3|MIO_(6[4-9]|7[0-7])|CRL_APB__GEM3|BANK_2)} $eth_p]} {
  puts $eth_f "$eth_p=[get_property $eth_p $eth_ps]"
 }
}
close $eth_f
puts "ETH01_XSA_PASS $eth_out/eth01_ps.xsa"
close_project
