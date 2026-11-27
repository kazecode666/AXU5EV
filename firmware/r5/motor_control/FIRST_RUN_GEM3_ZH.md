# GEM3 电机控制无功率候选

| 用途 | 候选根目录 | 启动项 |
| --- | --- | --- |
| SELFTEST R01（旧版对照） | `.runtime/experiment/final/GEM3_Control_SELFTEST_R01` | `Motor_Control_GEM3_SELFTEST_NoPower_R01` |
| PR61 SELFTEST + dq（内部合成 ADC/ABZ） | `.runtime/experiment/final/GEM3_Control_SELFTEST_P61_R01` | `Motor_Control_GEM3_SELFTEST_P61_NoPower_R01` |
| Issue #44 SELFTEST timing（PR62 复审候选、PR61 硬件） | `.runtime/experiment/final/P61_TIMING_R02` | `Motor_Control_GEM3_SELFTEST_P61_Timing_R02` |
| REAL IO R02（历史候选） | `.runtime/experiment/final/GEM3_Control_REAL_IO_R02` | `Motor_Control_GEM3_REAL_IO_NoPower_R02` |
| REAL IO R03（B6-1） | `.runtime/experiment/final/GEM3_Control_REAL_IO_R03` | `Motor_Control_GEM3_REAL_IO_NoPower_R03` |

R03 的启动和 J15/J16 分段验收见 [REAL IO 无功率首板步骤](FIRST_BOARD_REAL_R03_ZH.md)。

使用一套候选目录内的 `hardware/ax04b_{selftest,real}.{xsa,bit,ltx}`、`vitis/ax04b_realtime/build/ax04b_realtime.elf`、`vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf` 和对应启动项。内部工程组件沿用原名。需要现场授权后才可按 [AX-04B 首运行步骤](FIRST_RUN_AX04B_ZH.md)连接板卡。使用本表中的候选替换指南中的 R1 路径与启动项，保持驱动级、电机和功率电源断开。

## 离线构建

原 R01 和 REAL R02 使用各自的 [SELFTEST 配置](build_config.gem3.selftest.json)或 [REAL 配置](build_config.gem3.real.json)。构建器从既有候选复制匹配的布线 PL 产物，在新目录为 GEM3 创建 Vitis 2026.1 R5 平台、A53 FSBL 和应用。下面的命令对应原 R01。

```powershell
$env:MOTOR_CONTROL_CONFIG = 'firmware/r5/motor_control/build_config.gem3.selftest.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/motor_control_build.py
python scripts/motor_control_build.py --check-startup
```

检查命令在本地文件上运行。核对 `OFFLINE_STARTUP_CHECK_PASS`、应用身份 `0x41585205`、PL INTID 121、GEM3 INTID 95 和对应 profile。

R03 在新目录用当前 REAL + dq 源综合、实现和导出，再从本次 XSA 构建 R5 和 A53 FSBL。以下命令首次构建时从仓库根目录运行，部署工作区和 Vivado 输出目录需为新目录。

```powershell
.\scripts\motor_control_build_hw.ps1 -Stage all -Profile REAL -Ax05aObservation -Output .runtime/experiment/ax04b/b6_r03/hardware
$env:MOTOR_CONTROL_CONFIG = 'firmware/r5/motor_control/build_config.gem3.real.r03.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/motor_control_build.py
python scripts/motor_control_build.py --check-startup
```

## PR61 SELFTEST + dq 启动

PR61 的 `hardware/ax04b_selftest.bit`、`hardware/ax04b_selftest.ltx` 和 `hardware/ax04b_selftest.xsa` 来自同一通过布线后时序检查的实现。独立 Vitis Platform 导入 PR61 XSA，使用候选内 `vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf` 和 `vitis/ax04b_realtime/build/ax04b_realtime.elf`，两份 ELF 均复用兼容的原 R01 二进制。Vitis 实体 Debug 已验证 R5_0 停在 ELF 入口。

现场授权后，在所选 Workspace 运行表中对应启动项。保持 J15/J16、驱动器、电机和外部功率电源断开。`programDevice=false`，R5_0 按 `stopAtEntry` 暂停。保持暂停，在同一次调试会话的 XSDB Console 手动加载该候选的 bit 并完成 PS–PL 后配置，再手动 Resume R5_0。Studio 的 `-Prepare SELFTEST` 使用 [Issue #44 timing 候选](IRQ_TIMING_ZH.md)，手动替换候选目录和启动项时应保持同套文件。

```tcl
set candidate D:/Project/AXU5EV/.runtime/experiment/final/GEM3_Control_SELFTEST_P61_R01
targets -set -filter {name =~ "PL"}
fpga -file $candidate/hardware/ax04b_selftest.bit
targets -set -filter {name =~ "Cortex-A53 #0"}
source $candidate/vitis/ax04b_platform/hw/sdt/psu_init.tcl
psu_ps_pl_isolation_removal
psu_ps_pl_reset_config
```

Vitis 可能把启动项的 bit 字段刷新为 Workspace 缓存路径，现场下载仍使用上面的 PR61 硬件路径。保留实际下载回执。GEM3 应用身份 `0x41585205`、PL 接口 `0x41584201` 和 dq 扩展 `0x41583501` 在新旧候选相同。

## 经授权的网络核对

在候选启动前连接隔离的实验网。PC 地址可用 `192.168.50.20/24`。JL2121 在应用启动时协商，沿用 ETH-02 的超时路径。启动问题使用 Vitis/XSDB 排查，重新初始化网络需重启应用。PS UART0（115200 8N1）仅提供可选的启动信息。首先读版本、状态和样本，明确确认 SELFTEST 或 REAL IO，再提交适用命令。

```powershell
python scripts/motor_control_client.py version
python scripts/motor_control_client.py status
python scripts/motor_control_client.py watch --count 10
python scripts/motor_control_client.py trace-start
python scripts/motor_control_client.py trace-stop
python scripts/motor_control_client.py download motor_control_no_power.ndjson
```

操作语义、TCP 重连及数据合同见 [GEM3 通信说明](../../../integration/r5_ethernet/MOTOR_CONTROL_GEM3_ZH.md)。REAL 的实测 ADC 增益与零偏校准均通过 TCP 提交。若启用 IRQ 时序记录，业务记录和原 IRQ trace 仍共用存储，分次进行。PR61 的 SELFTEST GEM3 通信和下述 CURRENT 工况已通过实板验证。REAL 实板、网络负载下 IRQ→COMMIT 时延及持续吞吐仍待验证。

## 已验收的无功率 CURRENT 顺序

在 Studio 执行 STOP → CALIBRATE 并确认两路校准完成 → SELECT CURRENT（Id/Iq 都为 0）→ 确认选中版本 → CLEAR → ARM。断开 Studio 后再使用 CLI，保持单一连接所有者。先采 A 的 status、diagnostics、sample，然后按已确认的版本执行一次 START，运行中采 B/C 的同三种响应，最后显式 STOP。读回 `armed=false`、`stop_pending=false` 及业务 sample 的 `mode=0`、`fault=0`。用业务 sample 的 `mode` 判断实际运行，`status.selected_mode` 保留所选模式。三个请求分别采样。

本轮原始文件来自 `.runtime/board_tests/gem3_current_pr61/`，已归档 [PR61 A/B/C](../../../verification/experiment/ax04b/evidence/pr61-current/) 和 [旧 R01 B/C](../../../verification/experiment/ax04b/evidence/r01-current-baseline/)。见 [实板字段、计数和范围](https://github.com/kazecode666/AXU5EV/pull/61#issuecomment-7101789649)。
