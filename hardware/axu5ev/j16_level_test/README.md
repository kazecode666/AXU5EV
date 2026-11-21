# J16 接口板静态电平测试

面向 AXU5EVB-E 和 J16-MBDL4 V0.3 接口板。VIO 的 11 个输出可独立写入并保持静态值。上电配置完成后的默认值为 `F_Reset=1`，其余十路为 `0`。五个反馈脚经过两级同步器接到 VIO 输入，供下一阶段使用。

## 首板实际测试

PR49 提供独立静态 VIO 工程。2026-11-19 至 20 日，用户自行焊接 J1 并插入 AXU5EVB-E J16，记录了 9 路输出与 QEPA 一路反馈的空载静态验证（`USER_REPORTED`）。QEPB、QEPZ、ERRI、ERRU 仅观察到默认低电平，仍缺外部高电平逐路测试。动态 PWM/死区、真实驱动器负载和电机运动仍未测。装配、测点及实际范围以 [J16 首板实测记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md) 为准。

接口含 14 路业务信号和两路独立使能。U1 由 `PWM_EN` 控制，U2 与 U3 共用 `CTRL_EN`。AX-04B R1 的运行、真实 IO 和 IRQ 时延验收见[当前交接](../../../coordination/HANDOFF.md)。

## 工程与构建

使用 Vivado 2026.1、`xczu5ev-sfvc784-2-i`、AX02C 所用的最小 PS 基线和 IOPLL 的 50 MHz `pl_clk0`。Vivado 计算频率为 49.9995 MHz，VIO 和 Debug Hub 使用同一时钟。工程的 PL 只含静态 VIO 和反馈同步器。

本机构建位于 `.runtime/j16_level_test/`，每次构建使用新目录。打开该次构建下的 `project/j16_level_test.xpr`。同目录树顶层的 `j16_level_test.bit`、`j16_level_test.ltx` 和 `psu_init.tcl` 成套使用。`reports/` 保存布线、STA、DRC 和端口读回。Git 记录构建入口和源文件，生成的 Vivado 工程和产物留在本机。

从仓库根目录运行以下 PowerShell 命令。最后一个参数使用现有 AX03B2 本地 `vendor_ps/design_1.bd`，也可使用原厂 `资料/factory_file/factory_vivado/board_test.srcs/sources_1/bd/design_1/design_1.bd`。对应 PS XCI 应位于 BD 旁的 `ip/design_1_zynq_ultra_ps_e_0_0/`。Vivado 升级其副本。

```powershell
New-Item -ItemType Directory -Force .runtime/j16_level_test | Out-Null
Push-Location .runtime/j16_level_test
try {
    & 'E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat' -mode batch -nojournal -log rebuild_01.log `
        -source ../../hardware/axu5ev/j16_level_test/build.tcl `
        -tclargs rebuild_01 ../ax03b2/vendor_ps/design_1.bd
    if ($LASTEXITCODE -ne 0) { throw "Vivado build failed: $LASTEXITCODE" }
} finally {
    Pop-Location
}
```

## 离线验收

2026-11-19 本地 `build_01` 完成综合、实现及布线。1,362 条可布线网络全部完成，布线错误为 0。布线后 WNS +14.796 ns、WHS +0.022 ns、WPWS +9.468 ns，TNS、THS、TPWS 均为 0。四项 Debug Hub 总线偏斜检查均通过，最小裕量 +19.564 ns。

内部未约束端点为 0。五路异步输入只在外部脚到同步器第一级之间设时序例外，十一路静态输出以外部端口为例外终点。布线 DRC 为 0 错误、0 严重告警，有 `PDCN-1569` 三条和 `RTSTAT-10` 一条。另有 `LUTAR-1` 方法学告警五条。报告列出的告警对象均位于 Vivado 生成的 Debug Hub。构建时记录的硬件测量状态为 `NOT_RUN`。后续实测见[首板实际测试](#首板实际测试)。

布线端口读回 `reports/j16_io.csv` 的 16 项球号、方向、Bank 和 `LVCMOS33` 全部通过。Bitstream 和 LTX 从同一布线设计导出。LTX 中的 VIO UUID 与实现日志一致，已读回 11 个单比特输出和 5 个单比特输入的顺序，Debug Hub 标称 50 MHz。

## 管脚依据

J16 第 3–18 针的 16 路信号逐项对照接口板 CSV、ALINX《AXU5EVB-E 开发板用户手册》PDF 第 41 页和底板原理图 PDF 第 18 页。核心板原理图 PDF 第 4 页用于核对 Bank 45/46 的 3.3 V 供电。所有逻辑脚为 `LVCMOS33`。J16.2 为 +5 V 电源，约束只分配 J16.3–18。 [接口板 V0.3 管脚表 e388c58](https://github.com/kazecode666/J16-MBDL4-Module/blob/e388c58e6b3e8643aca555dd9847beaf314b3d8c/hardware/v0.1/pin_connections.csv)

| J16 | 信号 | FPGA 球号 | Bank | FPGA 方向 | VIO |
| --- | --- | --- | --- | --- | --- |
| 3 | PWM1 | B10 | 45 | 输出 | `probe_out0` |
| 4 | PWM2 | C11 | 45 | 输出 | `probe_out1` |
| 5 | PWM3 | F10 | 45 | 输出 | `probe_out2` |
| 6 | PWM4 | G11 | 45 | 输出 | `probe_out3` |
| 7 | PWM5 | C12 | 45 | 输出 | `probe_out4` |
| 8 | PWM6 | D12 | 45 | 输出 | `probe_out5` |
| 9 | RELCON | A11 | 45 | 输出 | `probe_out6` |
| 10 | ENCON | A12 | 45 | 输出 | `probe_out7` |
| 11 | F_Reset | F11 | 45 | 输出 | `probe_out8` |
| 12 | QEPA | F12 | 45 | 输入 | `probe_in0` |
| 13 | QEPB | E13 | 46 | 输入 | `probe_in1` |
| 14 | QEPZ | E14 | 46 | 输入 | `probe_in2` |
| 15 | ERRI | A13 | 46 | 输入 | `probe_in3` |
| 16 | ERRU | B13 | 46 | 输入 | `probe_in4` |
| 17 | PWM_EN | A14 | 46 | 输出 | `probe_out9` |
| 18 | CTRL_EN | B14 | 46 | 输出 | `probe_out10` |

## 用户手动测量

以下为获得现场授权后使用的工程操作与预期值。实际首板结果统一记录于上方链接。

1. 断电插合 AXU5EVB-E 与接口板，接口板 J2 保持与 MBDL4 断开。功率级和电机保持断开。用 Hardware Manager 为 PL 手动选择同一次构建的 `.bit` 和 `.ltx`，JTAG 建议 10 MHz 或更低。 [AMD 调试时钟指南](https://docs.amd.com/r/en-US/ug908-vivado-programming-debugging/Debug-Cores-Clocking-Guidelines)
2. 冷上电的 JTAG 启动需要初始化 PS 才有 `pl_clk0`。若板上尚无匹配的 PS 初始化，完成 PL 配置后在 XSDB 连接同一硬件服务器，用 `targets` 找到该板的 `PSU` 并选中其编号。`source` 本次生成的 `psu_init.tcl`，依次运行 `psu_init`、`after 1000`、`psu_ps_pl_isolation_removal`、`after 1000`、`psu_ps_pl_reset_config`。结束 XSDB 会话，在 Hardware Manager 刷新器件。该操作只用于专用 JTAG 测试会话。 [AMD Zynq UltraScale+ MPSoC 初始化顺序](https://docs.amd.com/r/2023.1-English/ug1400-vitis-embedded/Debugging-Applications-on-Zynq-UltraScale-MPSoC)
3. 打开 `vio_j16`，添加输出探针。LTX 中输出名带 `_OBUF` 后缀，例如 `F_Reset_OBUF`。从硬件刷新 VIO 值并确认 `F_Reset=1`、其余输出为 `0`。GUI 编辑输出会立即写入硬件。下表测点见本地 `资料/J16_MBDL4接口板原理图/schematic_A3.pdf` 第 1 页。万用表以 C10.2 为地，先测 C10.1 约 3.3 V、C11.1 约 5 V。 [AMD VIO 输出面板操作](https://docs.amd.com/r/en-US/ug908-vivado-programming-debugging/Writing-VIO-Outputs-Using-the-VIO-Cores-View)

| 检查 | VIO 操作 | 万用表预期 |
| --- | --- | --- |
| U1 `/OE` 独立控制 | `CTRL_EN=0`，手动将 `PWM_EN` 从 `0` 改为 `1` | R13.2 从约 3.3 V 变为约 0 V，R19.2 保持约 3.3 V |
| U1 六路电平 | `PWM_EN=1`，六路逐一手动设 `0→1→0` 并测量，每次只改一路 | U1 对应 A 侧约 `0→3.3→0 V`，J2.1–6 对应针约 `0→5→0 V`。完成后将 `PWM_EN=0`，R13.2 回到约 3.3 V |
| U2 `/OE` 独立控制 | `PWM_EN=0`、`F_Reset=1`，手动将 `CTRL_EN` 从 `0` 改为 `1` | R19.2 从约 3.3 V 变为约 0 V，R13.2 保持约 3.3 V |
| U2 三路电平 | `CTRL_EN=1`，分别令 `RELCON`、`ENCON` 走 `0→1→0`，`F_Reset` 走 `1→0→1` | U2 对应 A 侧在约 0/3.3 V 切换，J2.7–9 对应针在约 0/5 V 切换。完成后将 `CTRL_EN=0`，R19.2 回到约 3.3 V |

U1 禁止时，J2.1–6 由板载下拉保持低。U2 禁止时，J2.7–8 由板载下拉保持低，J2.9 在 J2 断开时浮空，以 R19.2 判定禁止。U3 与 U2 共用 `/OE`，本轮只测 U2 的受控信号。结束时使用 **Reset VIO Core Outputs** 恢复初值，然后刷新并核对两路使能均为 `0`。 [AMD VIO 初值恢复](https://docs.amd.com/r/en-US/ug908-vivado-programming-debugging/Resetting-the-VIO-Core-Output-Values)
