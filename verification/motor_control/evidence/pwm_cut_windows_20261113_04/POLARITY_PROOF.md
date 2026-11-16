# Task1: CUT_BOUNDARY_MAPPING=PROVEN_PERMISSION_COMPLEMENT

Unique original routed DCP read-only query completed239.502s of600s cap; Harness jobexit0, probe_status COMPLETED. PowerShell ExitCode null retained as raw collector quirk, not inventedVivadoexit. Full existing motor_routed.v independently inspected, no re-export.

Physical upstream LUT auto_inhibit_o_INST_0 INIT04000000 (onlybit26), I0=invalidate,I1=ref_arm,I2=lock_blocked,I3=auto_online,I4=run_permitted gives P=run_permitted & ref_arm & !invalidate & !lock_blocked & auto_online. Its preceding LUT3FE ORs apply/restart/manual_disarm (wrapper physical frame_cancelled_reg_0 actually connectedmanual_disarm, not controllerframe_cancelled). Exact logical wrapper source ax03b3_adc_observer.sv282–285 confirms ref_arm(ref_active[7][0]) and invalidate(apply||restart||manual_disarm); motor_foc_control.sv60 defines logical inhibit as exact complement.

Full original netlist evidence motor_routed.v:2423672–87 upstreamdriver+OR,2324600–41 wrapperaliases,2440168–76 lock_blockedQ=control_debug[5],2441319–26 run_permittedQ;823876/824013 topconnectivity,2552939/2552976 PWMwrapperaliases. DCP physical_cone.txt:1470–1508 confirms driverINIT04000000andconcreteinputs;1503 originaldriverOsharesnativePWMcutauto_inhibit_i anddebug_o35 segments. Five boundaryqueriesinonescript show same physicalnetandfanouts, not inferredfromnetname.

Full original destinationfanouts: captureLUT08000000:2555140–48; request/busyresetLUT7:2556269–74 andbusyR2554339; auto_releaseCLR7F:2554141–47 andtwoinverted-clockFDCE2554153–77; enabledLUT C8:2562450–2511; wantLUT80:2562941–47 andsixC8000000gates. AllconsistentP highmeanspermission. DCPmatchednativefanouts, no newinverterbetweenboundaries; inversionabsorbedRETARGETlogic, misleadinglogicalportnamesretained.

Withresetn=locked=online=1,valid=1,busy=0:

| logical inhibit | native physical P | captureCE | request/busy syncreset | releaseCLR | PWM permission |
|---:|---:|---:|---:|---:|---|
|0|1|1|0|0|enabled aftertwofallingreleaseedges andnormaldeadtime|
|1|0|0|1|1|disabled, cancelpending/active, outputs low|

General equations CE=resetn&locked&online&valid&!busy&P; reset=!(P&resetn); CLR=!(P&resetn&locked); enablednext=P&(valley|enabledold),want_h includesP. Inhibitdoesnotresettimebase. Counter/readback/ILAfanoutareobservationorcancelbookkeepingnotoppositepermission.

Namesdistinguished: sourceRTL auto_inhibit activehighblock; upstreamnative auto_inhibit_o anddebug_o35 physicalP activehighpermit; exportedcutport auto_inhibit_i retainsnamebutcarriesP. This proves one topTB adapter cut_permission=~logical_inhibit. Not a stimulationexperiment or producerlogicchange. FullchainSDF/realcrosscutrouting/upstreamalgorithm not certified.
