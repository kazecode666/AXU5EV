# current_alignment_reset手动板测交接（2026-11-02）

状态：OFFLINE_CHECKED / USER_MANUAL_NOT_RUN。仅只读检查已有数据/启动文件；没有连接/发现/复位/下载/运行板卡，没有重建ELF、修改模型或重跑motion分析。PR16分支codex/ax02a-r5-target，基于42b46757cdec5701dddf11bba8ffbf38b94664b3。

## 已有motion证据核对（没有重算或覆盖）

原目录 `.runtime/ax02a/board_manual/runtime_r1_motion_01/`：run.json为current_motion、mode1、experiment1/before0、state3/status0/completed64536、interrupted=false。output21167808B/timing4130304B/report2400B齐备。已有analysis/summary.json为passed=true、数值失败0、deadline_sequence PASS、anomalies=[]；64535 ISR斜率−5.836538019738839e−6tick/帧，阈值5.039760149494696e−5，无趋势。已有crosscheck/crosscheck.json为passed=true/consistent=true，状态/统计矛盾与时间异常均为空。

已有timing.csv：最大Runtime38.74µs、task54.42µs、response60.82µs、jitter6.94µs，最小slack39.18µs，按本次100MHz配置换算，不是WCET。pre-begin `.runtime/ax02a/runtime_r1_motion_pre_begin_01.json` 为raw9999、clock0/0、control35/33、IER1/0、ttc_apb_select0、lpd_lsbus_ctrl16779778、iopll_ctrl80896。此处记录已有分析结果，未重新运行比较器。

## 本次实际路径及静态检查

全部路径以D:/Project/AXU5EV为根。数据 `.runtime/ax02a/replay/current_alignment_reset/` 中input6896000B、reference14136800B；metadata为current_alignment_reset/43100帧/Ts0.0001/20输入41输出/Runtime1.50。32B描述符 `.runtime/ax02a/full_scene_descriptors/current_alignment_reset/reference_descriptor.bin` 的8个小端uint32为0x31464552,1,3,43100,41,0,14136800,0。

纯文件--check-startup退出0：A53_0 AArch64 FSBL、R5_0 ELF32、launch=ax02a_first_wait_a53fsbl、实际候选0x52313031/mapping_version1，runtime_candidate.tcl一致。workspace仍为 `.runtime/ax02a/vitis_runtime_100us_r1`；ELF=ax02a_replay/build/ax02a_replay.elf，FSBL=ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf，启动文件=ax02a_replay/_ide/launch.json，候选记录=runtime_candidate.tcl，均存在，未重建。

本次新读回目录 `.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01`、pre-begin `.runtime/ax02a/runtime_r1_alignment_reset_pre_begin_01.json` 均未占用，使用01；不预创建，不删除。实际执行前用户应再确认没有其他会话占用。

## 四个停点预期与操作边界

- WAIT：已暂停R5_0，state1/command0；若承接motion同一会话，experiment应为1，实际仍用scalar读取，不硬编码本次实验号。GUI确认ax02a_result_ready完成断点存在，无则手动设置一次。
- begin：快照valid1/raw9999/logical10000，两Hz100000000，base0xFF110000/0xFF110004，clock0/0、control35/33、IER1/0；两个计数器未启动。保存本次pre-begin，对照motion上游字段0/16779778/80896。移除begin/main/执行路径断点及观察点、关闭刷新，只留done，再由用户Resume。不要用旧control.timer代替快照。
- 完成停点ax02a_result_ready：计时器已停，experiment=align_before+1（同一会话通常为2），state3/status0/completed43100/failed_frame0、post_control.state2，timer.interval9999/period_ticks10000；不满足则保存错误并停，不宣布PASS。
- 读回：显式current_alignment_reset，64KiB分块并保留；完整output14136800B、timing2758400B、report2400B。意外中断如实声明true；没有第二场景实际数据及后续比较前，其状态仍NOT_RUN。

以下命令仅供用户手动执行，未由Codex执行。WAIT若尚停在motion完成点，先由用户GUI Resume回WAIT再Suspend确认；不得把这段当自动连跑。测量过程中不暂停/单步/读写。



motion读回和分析通过后，再由用户决定继续。成功完成停点Resume回WAIT，Suspend确认state1/command0；同一ELF每次ax02a_replay会重新初始化Runtime，不继承上一场景控制状态。不要重新Build或在计数器运行时装载。XSDB逐行：

```tcl
source D:/Project/AXU5EV/firmware/r5/ax02a/readback_short.tcl
set align_before [ax02a_short::scalar experiment]
set align_expected [expr {$align_before+1}]
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/input.bin 0x10000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/input.bin 0x10000000
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/reference.bin 0x14000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/reference.bin 0x14000000
dow -data D:/Project/AXU5EV/.runtime/ax02a/full_scene_descriptors/current_alignment_reset/reference_descriptor.bin 0x12f00000
verify -data D:/Project/AXU5EV/.runtime/ax02a/full_scene_descriptors/current_alignment_reset/reference_descriptor.bin 0x12f00000
set align_begin_bp [bpadd -addr &begin]
print -set ax02a_post_control.scenario 3
print -set ax02a_post_control.expected_experiment $align_expected
print -set ax02a_post_control.expected_mode 1
print -set ax02a_post_control.interrupted 0
print -set ax02a_post_control.enabled 1
print -set ax02a_control.frames 43100
print -set ax02a_control.mode 1
print -set ax02a_control.command 0x41583241
```

用户Resume到begin，同样核对快照并保存另一份开始前配置：

```tcl
print ax02a_ttc_snapshot
source D:/Project/AXU5EV/firmware/r5/ax02a/read_ttc_config.tcl
ax02a_ttc::read_config D:/Project/AXU5EV/.runtime/ax02a/runtime_r1_alignment_reset_pre_begin_01.json pre_begin
```

按上节移除执行路径断点/观察点和刷新，仅留done，用户Resume。完成后确认experiment=align_expected、state3/status0/completed43100、post_control.state2，再XSDB显式读回：

```tcl
ax02a_short::readback D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01 $align_before {same session I-cache ON D-cache OFF pre-begin only} false D:/Project/AXU5EV/.runtime/ax02a/vitis_runtime_100us_r1/runtime_candidate.tcl current_alignment_reset
```

完整时output216块、timing43块、报告1块，均自动合并并保留。普通PowerShell逐条分析：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_compare_replay.py --metadata D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/metadata.json --reference D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/reference.bin --actual D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/output.bin --timing D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/timing.bin --timer-hz 100000000 --period-ticks 10000 --origin BOARD --output D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/analysis
$align_before=(Get-Content -Raw D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/run.json | ConvertFrom-Json).before_experiment
python D:/Project/AXU5EV/scripts/ax02a_post_report.py crosscheck --metadata D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/metadata.json --reference D:/Project/AXU5EV/.runtime/ax02a/replay/current_alignment_reset/reference.bin --actual D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/output.bin --ticks D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/timing.bin --run D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/run.json --report D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/report_v2.bin --before-experiment $align_before --output D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01/crosscheck
```
