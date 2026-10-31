# AXU5EV — 当前交接

更新：2026-10-31。仓库 [kazecode666/AXU5EV](https://github.com/kazecode666/AXU5EV)，本地 `D:/Project/AXU5EV`，分支 `codex/ax02a-r5-target`、草稿 [PR #16](https://github.com/kazecode666/AXU5EV/pull/16)，未合并。当前优先 [Issue #15](https://github.com/kazecode666/AXU5EV/issues/15) AX-02A；AX-00及PR14仿真已完成，不重规划项目、不默认重跑RTL。

## 当前入口

- [工作区、上板工程与数据保存位置](../docs/WORKSPACE_GUIDE_ZH.md)：目录职责、完整ELF/FSBL路径、数据命名和ChatGPT交接。
- [首次上板指南第13节](../firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md#13-runtime-100µs-r1aba实测之后的p1000候选review后用户执行)：下一次Runtime R1 P1000，先Review，再由用户手动操作。
- 日常仿真：`simulation/START_HERE.m`；唯一参数入口 `simulation/init_AXU5EV.m`，保留本地模型/参数/wrapper修改，不保存未保存窗口。
- 原逐阶段交接保留在 [HANDOFF_HISTORY_2026-10-31.md](HANDOFF_HISTORY_2026-10-31.md)。其中“当前”“NOT_RUN”等按当时阶段理解，不覆盖本文状态。

## 当前任务与证据

最新为[任务6541052405](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6541052405)，[版本化任务书](tasks/ax02a_runtime_100us_r1.md)。T1—T3完成，状态 **OFFLINE_READY_FOR_REVIEW**：

| 阶段 | 实际提交 | 结果 |
|---|---|---|
| T1 | `b46fdf69830baa36072af6b8ab047b4196e1c900` | ABA真实数据闭合；XSDB地址及uint32兼容，原始run/samples不改 |
| T2 | `2aa9a9aa691c78f7ca70c897b091635a8ff37283` | 仅已验证TTC0通道0/1、内部同源100MHz、无分频10kHz映射raw9999/logical10000；其他配置拒绝，expected/deadline不变 |
| T3 | `44872ec40e4df2efced9bf557f7459664ce72d31` | 独立Runtime R1真实构建、实际ELF身份检查及第13节交接；当时相关63/63离线测试通过 |

六套workspace和全部ELF保留。**下一次选择 `.runtime/ax02a/vitis_runtime_100us_r1`**，应用 `ax02a_replay`，launch `ax02a_first_wait_a53fsbl`。旧workspace存在同名launch，必须核对路径；候选0x52313031、mapping_version1。完整路径及纯文件检查见工作区指南。现有候选不随未提交模型/参数自动更新。

| 验收项 | 当前实际状态/证据 |
|---|---|
| BOARD_BOOT/FIRST_WAIT | 用户实测PASS；A53 FSBL→R5_0启动，旧架构不匹配失败保留作历史 |
| 首次完整运动数值 | motion_03，64536×41 PASS；[精简证据](../verification/ax02a/board_motion_03/baseline.json) |
| 旧exp2及phase P1000 | 数值、deadline/sequence PASS；ISR约+1tick/帧，周期不接受，不是R1板验 |
| TTC-only ABA | 三组各1000真实IRQ/16000B；周期10000.999985/9999.999988/10000.999700ticks，全窗口RAW_PLUS_ONE_COMPATIBLE、repeatable=true、issues=[]；[摘要](../verification/ax02a/ttc_aba_01/summary.json) |
| Runtime R1 | 离线构建/启动文件检查PASS；**T4板验NOT_RUN**，[证据](../verification/ax02a/runtime_100us_r1/validation.json) |
| 完整A4 | 第二次独立完整motion、43100帧alignment/reset仍未验收 |
| 完整A5/WCET | 未完成，TTC-only和短段P1000不替代 |

ABA已完成，不重复ABA或可选C。Review后按第13节保存独立 `board_manual/runtime_r1_p1000_01` 的 `run.json/output.bin/timing.bin/report_v2.bin`，另保留同次开始前配置；输入/参考仍用 `replay/p1000`，v2描述符仍用 `phase_p1000_descriptor`。这些路径均位于 `.runtime/ax02a/`。新采集和分析目录不得覆盖已有目录。

T4成功也只记“带Runtime的100µs短段通过”；失败保留首个异常，不改9998、expected、deadline或容差。之后完整A4/A5另行推进，不扩展ADC/QEP/PS—PL/实物FOC。

## 本轮目录整理

统一README、固件入口、当前状态和工作区指南，历史交接单独保留；workspace/原始数据/生成源物理路径不变。可手动清理项见[清单](reports/workspace_cleanup_2026-10-31.md)。按AGENTS禁止批量删除，Codex未删除文件；清单交用户手动处理。`.runtime/`不入库，推送GitHub不备份本地原始数据。

## 固定方向与工作边界

- AXU5EVB-E；PCB/完整芯片料号及厂商XA/-1与手册XC/-2差异待板级核对。核心板参考ACU5EV、底板参考AXU5EVB-E/共用AXU3EG资料，实物以太网JL2121，本轮不做网络适配。
- R5F负责位置P、速度PI、原五态对齐/一次偏置、Host/参考/轨迹/恢复；PL复用FOC及采样/位置/角度/PWM/快速禁止。算法源为Simulink/Stateflow，不手改生成C/SV补算法，不改PI、时基、首相、一次死区、50µs应用边界。
- 保留紫色分区和Host/Alignment_Task/Motion_Control布局；MATLAB/Simulink仅MCP操作，From/Goto局部，端口默认。Ready为当拍许可，Busy=0不保证Ready，未Ready拒绝、不排队。
- 不stash/reset/clean、强制同步、clone/worktree、批量删除或覆盖用户修改，不保存未保存窗口。旧 `D:/Project/FPGA_XC7A200T` 只读。
- Codex不连接/发现/复位/读写/下载/运行板卡，不启动或连接hw_server；用户本人Review后操作。合并和功率级上电另行授权。
- C教学、Issue11、AX-02B/C及旧M4不在本轮范围。区分HOST、RTL、目标构建、ARM实测，未运行写NOT_RUN。

详细实际结果见[AX-02A阶段报告](reports/ax02a_r5_target_validation.md)；基线方向见[架构](../docs/ARCHITECTURE.md)、[接口需求](../references/legacy/PMLSM_Hardware_Interface_Map.md)及[历史交接](HANDOFF_HISTORY_2026-10-31.md)。
