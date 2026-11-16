# One read-only feasibility pass for Issue40 Review6740612318.
# This script never changes cells/nets, writes a checkpoint/netlist/SDF,
# synthesizes, places, routes, or starts a simulator.
if {$argc!=2} {error "expected hardware_02 routed DCP and new probe directory"}
set checkpoint [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
if {[file exists $out/groups.tsv]} {error "preserve prior probe output"}
file mkdir $out
open_checkpoint $checkpoint
set regs [get_cells -hier -filter {IS_SEQUENTIAL == 1}]
set core [get_cells -hier -filter {NAME =~ *auto_path.controller/foc/core}]
if {[llength $core]!=1} {error "expected the single adopted original FOC core"}
set core_name [get_property NAME $core]
set hold [filter $regs {NAME =~ *controller*foc/*_h_reg*}]
set result [filter $regs {NAME =~ *controller/foc/duty_*_reg*}]
if {[llength $hold]==0 || [llength $result]==0} {error "missing actual input/output boundary registers"}
set hold_q [get_pins -of_objects $hold -filter {REF_PIN_NAME == Q}]
set result_d [get_pins -of_objects $result -filter {REF_PIN_NAME == D}]
set first [all_fanout -flat -endpoints_only -only_cells -from $hold_q]
set first [filter $first {IS_SEQUENTIAL == 1 && NAME =~ *controller/foc/core/*}]
set last [all_fanin -flat -startpoints_only -only_cells -to $result_d]
set last [filter $last {IS_SEQUENTIAL == 1 && NAME =~ *controller/foc/core/*}]
set core_regs [filter $regs {NAME =~ *controller/foc/core/*}]
set f [open $out/groups.tsv w]
puts $f "group\tcount\texamples"
foreach {label objects} [list falling_hold $hold core_first_receivers $first core_output_sources $last original_core_sequential $core_regs wrapper_result $result] {
 puts $f "$label\t[llength $objects]\t[lrange [get_property NAME $objects] 0 3]"
}
foreach {label pattern} {
 p127_capture {*controller/foc_*reg*}
 generated_mapper {*controller/duty_mapper/*}
 source_offer {*controller/auto_compare_reg*}
 mailbox_frozen {*pwm_control_0*inst/frozen_compare_reg*}
 mailbox_pending {*pwm_control_0*inst/pwm/pending_compare_reg*}
 pwm_active {*pwm_control_0*inst/pwm/active_compare_reg*}
 applied_return {*pwm_control_0*inst/adopted_seq_reg*}
 falling_auto_release {*pwm_control_0*inst/auto_release_reg*}
} {
 set objects [filter $regs "NAME =~ $pattern"]
 puts $f "$label\t[llength $objects]\t[lrange [get_property NAME $objects] 0 3]"
}
close $f
# These are the actual first/last old-core sequential cells that a whole-core
# black box would erase. Only save object names, not a new circuit/implementation.
foreach {label objects} [list first_receivers $first output_sources $last] {
 set f [open $out/${label}.tsv w]
 puts $f "cell\tprimitive"
 foreach cell $objects {puts $f "[get_property NAME $cell]\t[get_property REF_NAME $cell]"}
 close $f
}
set f [open $out/boundary_paths.tsv w]
puts $f "boundary\tdelay\tslack_ns\tstartpoint\tendpoint"
foreach delay {max min} {
 foreach {label from to} [list falling_to_first $hold_q $first core_output_to_result $last $result_d] {
  set paths [get_timing_paths -from $from -to $to -delay_type $delay -max_paths 1 -no_report_unconstrained]
  if {[llength $paths]!=1} {error "missing actual $label $delay path"}
  set p [lindex $paths 0]
  puts $f "$label\t$delay\t[get_property SLACK $p]\t[get_property STARTPOINT_PIN $p]\t[get_property ENDPOINT_PIN $p]"
 }
}
close $f
# Physical reset buffering can be placed inside an arithmetic hierarchy while
# driving retained cells outside it. Inspect the real cross-hierarchy net.
set reset_pin [lindex [get_pins -of_objects $hold -filter {REF_PIN_NAME == R}] 0]
set reset_nets [get_nets -segments -of_objects $reset_pin]
set drivers [get_pins -of_objects $reset_nets -filter {DIRECTION == OUT}]
set f [open $out/hold_reset_drivers.tsv w]
puts $f "retained_reset_pin\tdriver_pin\tcell\tprimitive"
foreach pin $drivers {
 set cells [get_cells -of_objects $pin]
 foreach cell $cells {puts $f "$reset_pin\t$pin\t[get_property NAME $cell]\t[get_property REF_NAME $cell]"}
}
close $f
# Report which direct old-core subhierarchies contain required receivers or
# output sources. A module-level cut cannot assume those objects are outside.
set branches [dict create]
foreach {label objects} [list first $first output $last] {
 foreach cell $objects {
  set tail [string range [get_property NAME $cell] [expr {[string length $core_name]+1}] end]
  set branch [lindex [split $tail /] 0]
  dict incr branches "$label/$branch"
 }
}
set f [open $out/required_core_branches.tsv w]
puts $f "boundary_branch\tcount"
dict for {branch count} $branches {puts $f "$branch\t$count"}
close $f
set f [open $out/decision.txt w]
puts $f "SOURCE=$checkpoint"
puts $f "CANDIDATE_CUT=$core_name"
puts $f "WHOLE_CORE_BLACKBOX=REJECTED: erases [llength $first] real first receivers and [llength $last] output source registers"
puts $f "NO_PARTIAL_CONE_EDIT: no independently proven native partial cut preserving the above paths and shared physical reset tree was established in this bounded pass"
puts $f "TEMP_VIEW_EXPORT=NOT_ATTEMPTED; SDF_ANNOTATION=NOT_RUN; SDF_DYNAMIC=NOT_RUN"
puts $f "STOP: do not infer feasibility from object matches or start long xelab to resolve the missing proof"
close $f
puts "MOTOR_ROUTED_PROBE_COMPLETE_NOT_SDF first=[llength $first] output=[llength $last] export=NOT_ATTEMPTED"
close_design
