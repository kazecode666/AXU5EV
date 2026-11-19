# AX-04B 候选构建与首次无功率运行

本次工作为离线实现。首次板内 SELFTEST 与外部接口验收分别等待用户授权。现场阶段保持电机和驱动功率级断开，J16 无匹配转换板时保持接口断开。

## 候选对应关系

以下路径相对仓库根目录。启动前选定一整列，核对该列的 `startup_validation.json` 和[本轮状态](../../../verification/experiment/ax04b/results.json)。任何构建阶段失败时保留产物和日志，并停止使用该候选上板。

| 项目 | SELFTEST | REAL |
| --- | --- | --- |
| 候选根目录 | `.runtime/experiment/ax04b/selftest_r1_02/` | `.runtime/experiment/ax04b/real_r1_02/` |
| 位流、ILA、硬件平台 | `hardware/ax04b_selftest.{bit,ltx,xsa}` | `hardware/ax04b_real.{bit,ltx,xsa}` |
| 复用的布线实现 | `selftest_02/hardware` | `real_02/hardware` |
| Vitis Workspace | 候选内 `vitis/` | 候选内 `vitis/` |
| R5 ELF 与链接映射 | `vitis/ax04b_realtime/build/ax04b_realtime.{elf,map}` | 同名文件，使用 REAL 候选自己的 Workspace |
| 启动和初始化文件 | `vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf`、`vitis/ax04b_platform/hw/sdt/psu_init.tcl` | 同名文件，使用 REAL 候选自己的 Workspace |
| 配置编号 | 1 | 2 |
| 数据源 | 数字 ADC/ABZ 测试源 | J15 AN9238、J16 ABZ/故障输入 |
| 输出保护 | 外部 PWM 和驱动使能硬禁止，可观察内部结果 | 禁止运动。仅在单独授权的无功率阶段检查外部输入和禁止态 |

两种配置均使用应用 `ax04b_realtime`，启动项 `ax04b_realtime_manual`，应用身份 `0x41585203`，R5 调用模型 1.173 的 `generated/experiment/ax04b_r1_01/r5`。复用各自原 `*_02/hardware` 的已布线 bit、ltx 和 XSA，由构建入口复制和核对。历史 `*_02/vitis` 应用身份为 `0x41585201`，R1 中间试编译身份为 `0x41585202`。实时寄存器、控制快照、参考接受与采用字段见[接口说明](../../../integration/ps_pl/AX04B_INTERFACE.md)。

## 离线构建及匹配检查

以 SELFTEST 为例。在仓库根目录运行。构建时使用配置指定的原 PL 产物；另建固件候选时，复制一份配置并改为新的硬件目标目录及 Vitis 工作区。

```powershell
$env:MOTOR_CONTROL_CONFIG = 'firmware/r5/motor_control/build_config.ax04b.selftest.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/motor_control_build.py
python scripts/motor_control_build.py --check-startup
```

REAL 使用 `build_config.ax04b.real.json`。启动检查核对复制的 PL 文件、XSA 内嵌 bit、实际 BSP、链接映射中的源文件和 ELF 身份。预期实时 MMIO `0x80002000`、高电平 GIC SPI `121`、IRQ 栈 `16 KiB`。成功标记为 `OFFLINE_STARTUP_CHECK_PASS`。检查命令只读本机文件。历史时序、CDC、DRC 与 IO 报告见原 `*_02/hardware/reports`。

## 用户授权后的启动顺序

1. 保持所有功率驱动和电机断开。先运行对应配置的离线启动检查，保存检查输出和串口原始记录。串口使用 PS UART0，115200、8N1，无流控。
2. 结束旧调试连接。打开选定候选的 Vitis Workspace，使用 `ax04b_realtime_manual`。该启动项会复位系统，启用 RPU split，在 A53_0 执行匹配 FSBL，然后下载 R5_0 ELF 并停在入口。此时先保持 R5 暂停。
3. 在同一 Vitis 调试会话的 XSDB Console 加载所选候选。下例使用 SELFTEST。REAL 将目录末级改为 `real_r1_02`，文件名改为 `ax04b_real.bit`。保存加载和 PS 后配置的输出。需要 ILA 时使用同一候选的 ltx。

   ```tcl
   set candidate D:/Project/AXU5EV/.runtime/experiment/ax04b/selftest_r1_02
   targets -set -filter {name =~ "PL"}
   fpga -file $candidate/hardware/ax04b_selftest.bit
   targets -set -filter {name =~ "Cortex-A53 #0"}
   source $candidate/vitis/ax04b_platform/hw/sdt/psu_init.tcl
   psu_ps_pl_isolation_removal
   psu_ps_pl_reset_config
   ```

4. 仅继续 R5_0。等待串口打印 `AX04B WAIT app=41585203`，核对 `mode=1`（SELFTEST）或 `mode=2`（REAL）、`base=80002000`、`GIC_INTID=121`。用 `s` 检查当前禁止和反馈状态，再进行获授权的现场分项。身份、模式或寄存器检查失败时，采集原始日志并停在禁止态。

## SELFTEST 与 REAL 的现场检查

- SELFTEST 先发 `s`，核对数据源标记和外部禁止状态。授权的板内流程用 `c` 请求数字校准，待两路资格和测速历史有效后发 `r`，检查清错回执。发 `l` 开始采集 256 条 IRQ 记录。内部中立参考用 `a`，0.1 A 内部 q 轴测试量用 `j`，内部一次性对齐请求用 `i`。按场景独立执行，逐步核对 `s`、接受回执、下一 P0 采用以及内部三相比较值。发 `z` 复位对齐，或发 `x` 停止和禁止。
- STOP、PL 禁止或本地 COMMIT／编码失败后，先用 `s` 读取 `stop_reason`、`permit` 和 `stop_pending`。等待 `stop_pending=0` 且反馈资格恢复，再显式发送 `r`。核对此次请求让 `clear_ok` 增 1，且 PL `status` 的 `INHIBIT_LATCHED` 位已清除，才发送 `a`。确认 ARM 后，用一次新的 `i` 请求对齐。STOP 会作废此前排队的 CLEAR 和 Start。记录实际收到的状态及原始串口数据。[寄存器位定义](../../../integration/ps_pl/AX04B_INTERFACE.md)
- 需要观察独立复位路径时，SELFTEST 的 `f` 发出一个选定帧长度的内部驱动复位请求。分别记录 `f` 的驱动复位、`z` 的模型对齐复位和 `r` 的故障清除。
- REAL 仅在物理接口经核对后操作。根据最终板的供电、地、OE 及缓冲方向确认默认态，读取真实 ADC/ABZ 并记录资格和故障。在取得有效电流增益及极性后，使用 `g <A路有符号Q24十进制值> <B路有符号Q24十进制值>` 再发 `c` 请求真实零流校准。数字校准配置不能用于真实电流换算。本候选拒绝 `a`。用 `s` 检查运动禁止，记录参考、反馈及禁止原因。
- 停止后用 `p` 冻结采集并输出 CSV，用 `d` 读取采用后的 80 字诊断快照。板内时序需记录 IRQ 响应、快照读取、生成算法、COMMIT 接受以及退出窗口，覆盖 1 ms/10 ms 外环重拍。当前离线构建证据没有这些实际处理器时延数据。
- 单个实时 ILA 使用约 100 MHz 的 PWM 时钟与 8192 点深度。probe0 的位 0–5 依次为 P0、早期反馈发布、IRQ、active_valid、inhibit 和故障。probe1 和 probe2 分别为完整 32 位 P0 sample_id 和 active_target。probe3 保留原 128 位内部 PWM、谷值采用与禁止状态。CSV 的 `applied_coherent=0` 表示本条未取得一致采用身份，不使用这条记录计算采用时差。PMU 增量按实际分频及处理器计时频率换算。PL 时钟仅用于转换帧内相位和反馈 tick。
- 记录按这次候选单独归档，至少包含 UART、选定帧的序号/时间戳、COMMIT 与采用身份、停止前后的输出禁止状态。超时或故障时保留原始数据，先完成停止和禁止确认，避免重复启动掩盖现场。

实机软件中断运行、实际外部电气与功率运动分别记录。现场授权和采集均在本轮 Draft Review 之后进行。
