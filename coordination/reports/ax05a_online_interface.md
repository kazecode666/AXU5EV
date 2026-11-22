# AX-05A 在线观测与命令交付

起始 main 为 `9e5ff3d69e6d00a25dd10482bee68043fee3e467`，包含 PR51。执行入口为 [Issue #52](https://github.com/kazecode666/AXU5EV/issues/52)。首版接口、旧 F28335 名称映射和控制顺序见[业务接口合同](../../integration/ps_pl/AX05A_ONLINE_ZH.md)。本地核对了 `PMSLM_Init_Params_MBDL4_F28335_Backup.m` 与对应备份 SLX，包括旧 `Align_EN` 固定零角、三轴观测、限幅前后电压、ADC 自动零偏、GPIO 禁止与自动对齐。复用范围以当前模型接点和类型为准。

## 实际修改

- 实机 FOC 模型从 1.29 更新为 1.30，增加四个业务输出和对应 DUT 内端口。XML 对照未发现原块参数或位置变更。HDL Coder 生成 28 个模块及一份 package，原 p3 的 18 项配置和 5000 拍帧保留。生成检查报告有 4 条警告，报告在本地生成目录。
- 新版本保留实质变化的 3 份生成 SV。其余 26 份去掉生成文件名与模型版本头后逐一相同，继续复用 AX-04 目录的原文件。[生成源](../../generated/experiment/ax05a_03/pl/AXU5EV_Experiment_FOC) · [选择逻辑](../../hardware/axu5ev/motor_control/bd/adc.tcl)
- PL 复用 ADC、QEP、FOC/PWM 和 AX-04B IRQ/提交路径。dq 观测与原 duty 同一捕获边沿进入旁路，谷值后进入诊断包保留字。仅有诊断快照读取和发布旁路接入控制源。原参考写协议、硬禁止、死区、PL 算法数值配置和 R5 模型 1.173 保留。
- 固件提供前台 C API 和串口操作。业务按 ID、tick 对齐，缺失组保留有效性标记。命令明确区分选择、确认、模型实际消费、PL 接受和采用。有限窗口记录复用 IRQ trace 的 RAM，容量 256 条。业务拉取和底层诊断均在前台。REAL 的 START、ARM、运行给定和驱动复位保持软件拒绝，外部功率门极、使能和 RELCON/ENCON 保持 RTL 硬禁止。

## 离线证据

| 项目 | 结果 |
| --- | --- |
| FOC 模型与 HDL | Simulink 端口与连线检查、模型更新、生成通过。48 个动态帧包含 8 组角度/速度组合，192 个 Q40 dq 电流／电压字在 phase 314 与 Simulink 逐位一致；144 个 UQ30 duty 字在新旧模型参考下分别零差。 |
| AX-04B 到 AX-05A 整链 RTL | SELFTEST 110443、REAL 110445 项检查。分别对比原 FOC 的两组有效帧，全部 duty 位串相同。P76 IRQ、P110 会合、P127 捕获、P443 结果、P2500 采用和 P2504 回传保持原相位。两种模式的 AXI 读回同一采样身份、冻结 dq、诊断扩展标识及硬禁止输出。 |
| R5 主机 | 编译实际 IRQ 调度绑定和 Cortex-R 1.173 生成 C。6 个 AX-05A 场景覆盖模式门槛、给定范围、位置 Host 回执、独立复位、相位微调、真实模式拒绝、读取释放、跨帧拒绝、带符号原码、重复和缺帧。12 个 AX-04B 兼容场景通过。 |
| Ready 回归 | 上一轮 POSITION 的 Ready 帧重放时，修复前误返回 `ACCEPTED`。修复后返回 `NOT_READY`，MOVE、命令版本和挂起状态保持不变。当前命令对应的新控制帧就绪后可接受给定。修复提交 `19e3b59` 的 AX-05A 主机测试 6/6 通过。 |
| 两套部署文件 | Vitis 2026.1 为 `19e3b59` 重建 SELFTEST、REAL 的 Cortex-R5 ELF 与对应 A53 FSBL。两套独立启动文件核对均返回 `OFFLINE_STARTUP_CHECK_PASS`。沿用原布线结果，SELFTEST WNS/WHS 为 +0.733/+0.011 ns，REAL 为 +0.704/+0.010 ns，两套 TNS/THS 及布线错误均为 0。 |
| 实板 | 板内 SELFTEST、ARM 执行、业务读取和 trace 对 IRQ→COMMIT 的负担、持续记录率、真实 ADC/IO、功率运动均为 `NOT_RUN`。完整动态 SDF 为 `NOT_RUN`。 |

本地日志保存在 `.runtime/experiment/ax05a/`。机器可读结果见[结果索引](../../verification/experiment/ax05a/results.json)。

## 独立候选构建

当前候选根目录为 `.runtime/experiment/ax04b/selftest_ax05a_03` 与 `.runtime/experiment/ax04b/real_ax05a_03`。每套的 `hardware/` 提供 bit、ltx、XSA 与两份 profile／schema 标记，对应 `vitis/` 中的 ELF、A53 FSBL 和 `ax04b_realtime_manual`。使用同一 profile 的 [SELFTEST 配置](../../firmware/r5/motor_control/build_config.ax05a.selftest.json)或 [REAL 配置](../../firmware/r5/motor_control/build_config.ax05a.real.json)。构建器核对 XSA 内嵌 bit、LTX、BSP、应用身份、API 符号、16 KiB IRQ 栈和链接输入。

本次从各自的 `*_ax05a_02/hardware` 复制并逐文件比对 bit、ltx、XSA、`ax04b_build_profile.txt` 与 `ax05a_dq_schema.txt`。将 `MOTOR_CONTROL_CONFIG` 设为对应配置路径后，使用 Vitis 执行 [R5 构建脚本](../../scripts/motor_control_build.py)，再用该脚本的 `--check-startup` 独立核对。各候选根目录保存 `vitis_build.log` 与 `independent_startup_check.json`。重建改用未使用的编号。

原 PL 由 [PL 构建入口](../../scripts/motor_control_build_hw.ps1) 的 `-Ax05aObservation` 与对应 `-Profile` 生成，布线报告保存在各自的 `*_ax05a_02/hardware/reports/`。

实测工作仍需另行授权。`*_ax05a_02` 的 ELF 来自 Ready 修复前版本，按历史候选保留。本地初期的 `selftest_ax05a_01` 用 PR48 的 PL 产物验证过早期固件构建。

## 后续接入

[Issue #53](https://github.com/kazecode666/AXU5EV/issues/53) 可调用 [ax05a_online.h](../../firmware/r5/motor_control/ax04b/ax05a_online.h) 的采样、诊断、命令、回读和有限记录。命令和采样由单前台所有者串行化，无需改动 ACK/COMMIT 的唯一 IRQ 写路径。线上编码须显式序列化业务字段和有效性，R5 的 C 结构体保留本机布局。应用目标负担、实际可持续拉取间隔以及真实现场允许范围由后续获授权试验验证。
