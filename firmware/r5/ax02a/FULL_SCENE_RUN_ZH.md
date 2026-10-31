# Runtime R1完整场景回放：用户手动执行

当前PR16分支，先Review本轮交接，再由用户逐次执行。R1 P1000真实板测已PASS，精简证据见[归档](../../../verification/ax02a/runtime_r1_p1000_01/evidence.json)。以下两次完整实验均 **NOT_RUN**，不自动执行，不重复TTC ABA，不重建ELF或重新生成算法。

## 1. 工程与数据

从Windows开始菜单打开Vitis2026.1，Set Workspace选 **`D:/Project/AXU5EV/.runtime/ax02a/vitis_runtime_100us_r1`**。平台ax02a_platform、域r5_standalone、应用ax02a_replay、launch=ax02a_first_wait_a53fsbl。R5 ELF为该workspace的 `ax02a_replay/build/ax02a_replay.elf`，A53 FSBL为 `ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf`。禁PL下载、禁第二套psu_init；不Build。

若仍在同一R1的成功P1000完成停点，可由用户Resume回WAIT，再Suspend确认state1/command0；不必再次Debug初始化。若另开会话，沿[首次指南第13节](FIRST_BOARD_RUN_ZH.md#13-runtime-100µs-r1aba实测之后的p1000候选review后用户执行)到main/WAIT，但不再发P1000命令。失败终态不能靠Resume恢复WAIT，须先保存错误并停。

纯文件检查可在普通PowerShell执行，不连接板卡：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_build_r5.py --config D:/Project/AXU5EV/firmware/r5/ax02a/build_config.runtime_100us_r1.json --check-startup
```

以下路径都相对于 `D:/Project/AXU5EV`，已有输入、参考、参数和生成Runtime不变；每个场景重新初始化Runtime一次。参数来源以配套metadata中冻结的Runtime1.50/V20/A200等为准，不加载当前未提交模型参数来替换参考。

| 项目 | current_motion | current_alignment_reset |
|---|---|---|
| frames / mode / scenario编号 | 64536 / 1 / 2 | 43100 / 1 / 3 |
| 输入/参考/metadata | `.runtime/ax02a/replay/current_motion/` | `.runtime/ax02a/replay/current_alignment_reset/` |
| 描述符（已生成32B） | `.runtime/ax02a/full_scene_descriptors/current_motion/reference_descriptor.bin` | `.runtime/ax02a/full_scene_descriptors/current_alignment_reset/reference_descriptor.bin` |
| 新原始读回目录 | `.runtime/ax02a/board_manual/runtime_r1_motion_01` | `.runtime/ax02a/board_manual/runtime_r1_alignment_reset_01` |
| 新开始前配置文件 | `.runtime/ax02a/runtime_r1_motion_pre_begin_01.json` | `.runtime/ax02a/runtime_r1_alignment_reset_pre_begin_01.json` |
| 完整output/timing/report字节 | 21167808 / 4130304 / 2400 | 14136800 / 2758400 / 2400 |
| 名义采样段长度 | 6.4536s | 4.3100s |

现有ELF的65536帧上限覆盖两场景；帧预算645380000/431020000 ticks均小于32位回绕界限。输入0x10000000、输出0x11000000、描述符0x12f00000、ticks0x13000000、参考0x14000000、报告0x16000000，所有范围互不重叠。名义时长不包含装载/准备/后处理/读回，不能当真实墙钟或WCET。

## 2. 第一次：current_motion（64536帧）

仅在用户确认R5_0已暂停在WAIT（state1/command0）后操作。沿用已有ax02a_result_ready完成断点；若尚无该断点，在GUI设置一次。按以下 **XSDB** 逐行操作，command放最后：

```tcl
source D:/Project/AXU5EV/firmware/r5/ax02a/readback_short.tcl
set motion_before [ax02a_short::scalar experiment]
set motion_expected [expr {$motion_before+1}]
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/input.bin 0x10000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/input.bin 0x10000000
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/reference.bin 0x14000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/reference.bin 0x14000000
dow -data D:/Project/AXU5EV/.runtime/ax02a/full_scene_descriptors/current_motion/reference_descriptor.bin 0x12f00000
verify -data D:/Project/AXU5EV/.runtime/ax02a/full_scene_descriptors/current_motion/reference_descriptor.bin 0x12f00000
set motion_begin_bp [bpadd -addr &begin]
print -set ax02a_post_control.scenario 2
print -set ax02a_post_control.expected_experiment $motion_expected
print -set ax02a_post_control.expected_mode 1
print -set ax02a_post_control.interrupted 0
print -set ax02a_post_control.enabled 1
print -set ax02a_control.frames 64536
print -set ax02a_control.mode 1
print -set ax02a_control.command 0x41583241
```

用户Resume到begin入口，此时两计数器尚未启动。核对快照valid1/raw9999/logical10000、两个Hz100000000、base0xFF110000/0xFF110004、clock0/0、control35/33、IER1/0。此处不用尚未发布的control.timer旧值代替快照。XSDB：

```tcl
print ax02a_ttc_snapshot
source D:/Project/AXU5EV/firmware/r5/ax02a/read_ttc_config.tcl
ax02a_ttc::read_config D:/Project/AXU5EV/.runtime/ax02a/runtime_r1_motion_pre_begin_01.json pre_begin
```

保存GUI停点证据，对照已PASS P1000的 `.runtime/ax02a/runtime_r1_pre_begin_01.json`：ttc_apb_select=0、lpd_lsbus_ctrl=16779778、iopll_ctrl=80896，局部配置同上。这是配置对照，不是独立测频。配置不同即保存现场并停，不写寄存器修正。

在GUI移除begin/main及执行路径断点、观察点，关闭运行中刷新，只保留ax02a_result_ready完成停点，再由用户Resume。**采样段中不暂停、单步、读写、刷新或传输。** 完成停点位于计时器停止且一次性后处理结束之后；核对experiment=motion_expected、state3、result.status0、completed64536、post_control.state2。

然后用户在XSDB显式读回，末尾 `current_motion` 不可省略：

```tcl
ax02a_short::readback D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01 $motion_before {same session I-cache ON D-cache OFF pre-begin only} false D:/Project/AXU5EV/.runtime/ax02a/vitis_runtime_100us_r1/runtime_candidate.tcl current_motion
```

每次mrd最多65536B，依次读已完成output/ticks并合并，完整时分别323/64块，报告1块。分块文件和合并文件都保留，不删除。readback只读取现有暂停目标，不连接/选核/复位/Resume。若实验有意外中断，必须如实将false改true，不能验收为PASS。

回到 **普通PowerShell**，先跑完整数值/时间比较，再核对同次run身份和板报。每条为完整单行；analysis/crosscheck目录须未存在：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_compare_replay.py --metadata D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/metadata.json --reference D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/reference.bin --actual D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/output.bin --timing D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/timing.bin --timer-hz 100000000 --period-ticks 10000 --origin BOARD --output D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/analysis
$motion_before=(Get-Content -Raw D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/run.json | ConvertFrom-Json).before_experiment
python D:/Project/AXU5EV/scripts/ax02a_post_report.py crosscheck --metadata D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/metadata.json --reference D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/reference.bin --actual D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/output.bin --ticks D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/timing.bin --run D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/run.json --report D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/report_v2.bin --before-experiment $motion_before --output D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_motion_01/crosscheck
```

不要用仅支持P1000 prefix的ax02a_analyze_run.py替代上述完整场景命令。比较器单独PASS不够，必须同次crosscheck也PASS/consistent=true。任一失败保留首个异常、全部原始文件及pre-begin，不继续下一场景、不重试掩盖。

## 3. 第二次：current_alignment_reset（43100帧）

motion读回和分析通过后，再由用户决定继续。成功完成停点Resume回WAIT，Suspend确认state1/command0；同一ELF每次ax02a_replay会重新初始化Runtime，不继承上一场景控制状态。不要重新Build或在计数器运行时装载。XSDB逐行：

```tcl
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

## 4. 保存和判读

两次目录都保存run.json/output.bin/timing.bin/report_v2.bin，另保留同编号pre-begin和GUI停点证据。路径已存在时先核对所属实验；新实验选择下一未占用编号，同时更新全部相关命令，不覆盖原始数据。分析命令中的周期10000仅用于读取此候选实际timer.period_ticks，不把raw9999当逻辑周期；出现配置不符即停。

合法失败仍可调用带正确场景的读回：保存错误run及可确认的completed前缀，排除失败帧，不读旧报告。早初始化失败可能只有run.json，不为凑齐四文件补读旧DDR。run中的captured_records/report_captured/report_validity说明捕获范围。失败/中断后保存并停，不自动继续另一次实验。

每个成功实验须同时满足：候选/场景/实验号正确、未中断、全帧完成；全41字段按原容差0失败；序号/时间顺序/截止期异常0、最小slack>0；排除软件首帧后，相位分别使用64535/43099个ISR样本，按既有阈值无持续趋势；板报与PC全部状态/计数/分组一致。分别保留ordinary、speed_due、position_due、command_event、alignment_transition组的样本量与最坏帧。

两次通过后再归档A4/A5实际证据；当前仅完成离线准备，不预签收。观察到的最大执行时间不等于WCET，PS回放不是电机实机闭环。PR16保持Draft、不合并、不关闭Issue15；不扩展AX-02B/C。
