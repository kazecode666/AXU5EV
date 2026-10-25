# Generated FOC SystemVerilog — PR53 p3

Current raw HDL Coder R2026b publication: 29 design SV, one ordinary SV TB and four data files. All34 payloads are byte-identical to the fully validated p3 build and independent repeat. No generated control SV was edited.

Standalone M3 core gates PASS, PR53 remains open for Review: source/gm18039 exact words +68 next states; RTL2613 positive frames/52289123 checks; 20ns OOC WNS+5.317ns/WHS+0.135ns,70983 LUT/83278FF/439DSP/0BRAM. Output phase314; PI/AW observation commit next-frame1, old state consumed pre5000.

Compilation resolves payload and candidate-contract paths relative to this packet. Provenance absolute paths are informational. [Chinese reproduction guide](../../docs/PMLSM_FOC_HDL_GUIDE_ZH.md) explains the required p3 candidate JSON; a bare default run intentionally reproduces B3.

This is pre-route core evidence. External IO, capture/valid/output adapters, routed timing and hardware are not signed off. ce_out is fast CE, not frame-valid. [Timing contract](../../docs/FOC_HDL_TIMING_CONTRACT.md). Original B3 -58.833ns/274-cycle failure remains in Git7f859f7 and original raw reports.
