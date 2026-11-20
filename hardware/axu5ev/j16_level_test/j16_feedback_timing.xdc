# Only the asynchronous port-to-first-flop paths are excluded from STA.
# The synchronizer stages and VIO paths still use the PS clock timing.
set feedback_d [get_pins -hierarchical -filter {REF_PIN_NAME == D && NAME =~ feedback_meta_reg*}]
set_false_path -from [get_ports {QEPA QEPB QEPZ ERRI ERRU}] -to $feedback_d

# This XDC is applied to the synthesized netlist before opt_design inserts the hub.
set_property C_CLK_INPUT_FREQ_HZ 50000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
