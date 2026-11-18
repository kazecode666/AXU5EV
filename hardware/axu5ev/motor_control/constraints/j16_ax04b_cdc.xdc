# Bind the pin exception only to the first D of each asynchronous input
# synchronizer, with the implemented module-reference hierarchy available.
set qep_ff [get_cells -quiet -hier -filter {NAME =~ *encoder.receiver/sync1_reg* && ASYNC_REG == TRUE}]
set fault_ff [get_cells -quiet -hier -filter {
    (NAME =~ *ax04b_live.erri_sync_reg?0? || NAME =~ *ax04b_live.erru_sync_reg?0?) && ASYNC_REG == TRUE}]
set qep_first [get_pins -quiet -of_objects $qep_ff -filter {REF_PIN_NAME == D}]
set fault_first [get_pins -quiet -of_objects $fault_ff -filter {REF_PIN_NAME == D}]
set_false_path -from [get_ports {j16_qepa_i j16_qepb_i j16_qepz_i}] -to $qep_first
set_false_path -from [get_ports {j16_erri_n_i j16_erru_n_i}] -to $fault_first
# Keep inter-stage timing and the raw asynchronous PWM inhibit independent.
