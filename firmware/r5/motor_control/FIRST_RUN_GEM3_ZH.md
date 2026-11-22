# GEM3 电机控制无功率候选

| 用途 | 候选根目录 | 启动项 |
| --- | --- | --- |
| SELFTEST（内部合成 ADC/ABZ） | `.runtime/experiment/final/GEM3_Control_SELFTEST_R01` | `Motor_Control_GEM3_SELFTEST_NoPower_R01` |
| REAL IO（真实输入、功率输出硬禁止） | `.runtime/experiment/final/GEM3_Control_REAL_IO_R02` | `Motor_Control_GEM3_REAL_IO_NoPower_R02` |

使用一套候选目录内的 `hardware/ax04b_{selftest,real}.{xsa,bit,ltx}`、`vitis/ax04b_realtime/build/ax04b_realtime.elf`、`vitis/ax04b_platform/export/ax04b_platform/sw/boot/fsbl.elf` 和对应启动项。内部工程组件沿用原名。需要现场授权后才可按 [AX-04B 首运行步骤](FIRST_RUN_AX04B_ZH.md)连接板卡。使用本表中的候选替换指南中的 R1 路径与启动项，保持驱动级、电机和功率电源断开。

## 离线构建

使用各 profile 对应的 [SELFTEST 配置](build_config.gem3.selftest.json)或 [REAL 配置](build_config.gem3.real.json)。构建器从既有候选复制匹配的布线 PL 产物，在新目录为 GEM3 创建 Vitis 2026.1 R5 平台、A53 FSBL 和应用。正式候选名称、版本和启动项保持原样。本次使用 `.runtime/experiment/final/`，保留上一轮 Workspace。

```powershell
$env:MOTOR_CONTROL_CONFIG = 'firmware/r5/motor_control/build_config.gem3.selftest.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/motor_control_build.py
python scripts/motor_control_build.py --check-startup
```

检查命令在本地文件上运行。核对 `OFFLINE_STARTUP_CHECK_PASS`、应用身份 `0x41585205`、PL INTID 121、GEM3 INTID 95 和对应 profile。

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

操作语义、TCP 重连及数据合同见 [GEM3 通信说明](../../../integration/r5_ethernet/MOTOR_CONTROL_GEM3_ZH.md)。检查 PC 重连、记录下载和 REAL 对运行命令的拒绝。REAL 的实测 ADC 增益与零偏校准均通过 TCP 提交。若启用 IRQ 时序记录，业务记录和原 IRQ trace 仍共用存储，分次进行。两种模式的板上通信、流量下 IRQ→COMMIT 时延和持续吞吐均待验证。
