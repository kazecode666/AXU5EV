# AX-03B1 observation snapshot protocol

`integration/rtl/ax03b1/ax03b1_snapshot_axi.sv` is an independent AXI4-Lite read-channel slave. It has no write channels, board base address, control permission or actuator output. Producer publication and the bus share `clk`; crossing another clock domain requires a separate coherent transfer before this module.

`SNAP_WORDS=32` by default. `payload_i[32*n+:32]` is word n; the integration top defines its field layout. `publish_i` captures the entire opaque payload and `epoch_i` together, including observations whose sensor/calibration quality bits are invalid. Header availability is never a current-loop permission.

| Byte offset | Response/side effect |
|---|---|
| `0x00` BEGIN | Freeze the latest complete published payload, epoch and flags; return its uint32 publication sequence. A repeat BEGIN explicitly discards/replaces a previous read session. |
| `0x04` | Frozen caller-supplied epoch/session tag. |
| `0x08` | Frozen flags: bit0 observation exists; bit1 this is the first publication after reset; bit2 sequence has wrapped since reset. Other bits zero. |
| `0x0c+4*n` | Frozen payload word n. With 32 words, n=0..31 and offsets are `0x0c..0x88`. The last word releases the frozen bank only when its response is accepted (`RVALID && RREADY`). |

Read the last word last to retain the session. All other words can be repeated or read in any order; reading the last word early intentionally ends the session. Misaligned/out-of-range reads and reads without a successful BEGIN return `SLVERR` with zero data, preserving an existing session. BEGIN before the first publication also returns `SLVERR`; it does not create a bank.

Only one read response can be outstanding. While `RVALID=1`, `ARREADY=0`; data, response and valid stay stable until `RREADY`. A queued AR request is not accepted on the edge consuming the previous response; it can be accepted on a subsequent edge. The master must keep ARADDR/ARVALID stable until acceptance. A publication on the same edge as BEGIN is ordered after BEGIN: the reader receives the complete preceding publication, or `SLVERR` if none existed. It never receives a partially updated frame.

Synchronous active-low `rst_n` cancels any pending response/session, invalidates latest data, sets the sequence to parameter `SEQ_RESET` (default zero), and clears wrap history. First publication is `SEQ_RESET+1` modulo 2^32. `SEQ_RESET` permits direct modulo-wrap verification without forcing internal registers. Epoch is an external session label captured on publication; the caller must change it for resets requiring distinct sessions. This resettable module does not implement persistent boot counting. A master must restart at BEGIN after reset, and concurrent independent bus readers must serialize this single global session.

## Necessary verification

`snapshot_tb.sv` checks cross-publication multiword reads, out-of-order/duplicate words, re-BEGIN, simultaneous BEGIN/publication, invalid addresses, blocked/concurrent AR, stable stalled R and terminal response, terminal release, uint32 wrap, invalid-quality payload transport, and reset during a stalled response. It also proves epoch follows publication rather than a later live epoch input.

Run from a new isolated directory under `.runtime/ax03b1/`, using the installed Vivado simulation tools:

```powershell
& 'E:/AMDDesignTools/2026.1/Vivado/bin/xvlog.bat' -sv 'D:/Project/AXU5EV/integration/rtl/ax03b1/ax03b1_snapshot_axi.sv' 'D:/Project/AXU5EV/verification/ax03b1/snapshot_tb.sv'
& 'E:/AMDDesignTools/2026.1/Vivado/bin/xelab.bat' snapshot_tb -s snapshot_sim
& 'E:/AMDDesignTools/2026.1/Vivado/bin/xsim.bat' snapshot_sim -runall
```

For the supported 40-word instance, use `xelab.bat snapshot_tb -generic_top '"WORDS=40"' -s snapshot_sim_40` from PowerShell in a separate directory, then `xsim.bat snapshot_sim_40 -runall`. The embedded quotes preserve the parameter assignment through the Windows batch wrapper. Always check for `SNAPSHOT_PASS` and absence of `Fatal`/`Error` in the simulation log; simulator exit code alone is insufficient. This is standalone behavioral RTL simulation. Vivado projects, synthesis, implementation, board setup/hold, CDC physical margins and board operation are NOT_RUN.
