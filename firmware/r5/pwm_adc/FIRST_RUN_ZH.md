# PWM/ADC 离线候选与后续手动观察

本轮没有连接/发现/复位/下载/运行板卡。仅内部逻辑观察，外部六路引脚、驱动缓冲/极性/配对均 PENDING；ENCON/RELCON/功率级许可未接入。不要连接驱动板或电机。本指南不构成此次上板授权，后续由用户 Review 后另行决定。

## 唯一入口

- PL：`hardware/axu5ev/motor_control/build.tcl`，PWM 包装脚本 `scripts/pwm_adc_build_hw.ps1` 设置 `MC_PWM=1`，仍为同一 PS/ADC 工程；未设置时保留 ADC-only 入口。
- R5：`scripts/pwm_adc_build.py`，配置 `firmware/r5/pwm_adc/build_config.json`。从实际 BSP 宏取得 PWM/ADC 地址，不用猜测的地址构建。
- 数据：`.runtime/pwm_adc/` 中各新目录。已完成目录不重建、不移动。失败/早期日志保留。
- MATLAB 组件仍为 `AXU5EV_PL_Algorithm_Library/Current_Preprocess`，本轮未改或重新生成数值 HDL。

## 本轮采用产物

- bit / ltx / 含bit XSA：`.runtime/pwm_adc/hardware_05/ax03b3_adc.bit`、`ax03b3_adc.ltx`、`ax03b3_adc.xsa`。
- Workspace：`.runtime/pwm_adc/vitis_02`；Launch：`pwm_adc_manual`。
- R5 ELF：`.runtime/pwm_adc/vitis_02/pwm_adc_observer/build/pwm_adc_observer.elf`。
- A53 FSBL：`.runtime/pwm_adc/vitis_02/pwm_adc_platform/export/pwm_adc_platform/sw/boot/fsbl.elf`。
- 构建/被动启动检查与功能PL边界slow/max、fast/min SDF均PASS，详见精简结果。本轮没有上板。

## 构建与验证入口

```powershell
./scripts/pwm_adc_run_rtl.ps1 -Suite pwm -RunDir .runtime/pwm_adc/<新目录>
./scripts/pwm_adc_run_rtl.ps1 -Suite adc -RunDir .runtime/pwm_adc/<另一个新目录>
./scripts/ax03b3_run_rtl.ps1 -RunDir .runtime/pwm_adc/<新的B3目录>
./scripts/pwm_adc_build_hw.ps1 -Stage all -Output .runtime/pwm_adc/<新的硬件目录>
./scripts/pwm_adc_run_sdf.ps1 -Hardware <本次硬件目录> -Corner slow -RunDir <新的slow目录>
./scripts/pwm_adc_run_sdf.ps1 -Hardware <同一硬件目录> -Corner fast -RunDir <新的fast目录>
# 更新配置指向实际新XSA/bit/ltx和未占用Workspace后：
vitis.bat -s scripts/pwm_adc_build.py
python scripts/pwm_adc_build.py --check-startup
```

SDF 从该候选真实路由检查点导出功能 PL 边界及匹配的 slow/max、fast/min 延迟，保留 ADC、MMCM、PWM、SmartConnect、复位及功能互连。PG172 明确 ILA 不支持仿真：导出脚本只在内存中将 `pwm_ila`/`dbg_hub` 变为 black box，不重新综合、布线或覆盖检查点；完整 STA、bit/XSA 仍包含真实调试 IP。测试台替代 PS 时钟/复位及 AXI 主接口事务源，不模拟 ARM 软件/PS 内部或 ILA 采集操作。输入从 ADC 引脚、已知七转换延迟及4ns tPD进入接收器，不使用 B3 TEST。保留1ps精度、时序检查和互连脉冲传播；注释失败、功能范围时序违例、未知读数据或六路未知输出均不能算 PASS。具体原始目录见精简结果。

[PG172 ILA 仿真限制](https://docs.amd.com/api/khub/documents/w1BckBqYd0w2WsdXTPu1og/content)；[UG835 update_design 仅修改内存视图](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/update_design)。

## 后续用户手动观察顺序

采用产物路径与本轮实际 PASS/未完成项见 `verification/pwm_adc/results.json` 与 `coordination/HANDOFF.md` 首节。硬件文件沿用统一工程现有名称 `ax03b3_adc.bit/.ltx/.xsa`，路径必须选择本次 `pwm_adc` 候选，不能误选旧 B3 文件。Workspace 中应用 `pwm_adc_observer`，平台 `pwm_adc_platform`，Launch `pwm_adc_manual`。ELF 相对路径 `pwm_adc_observer/build/pwm_adc_observer.elf`，A53 FSBL 为 `pwm_adc_platform/export/pwm_adc_platform/sw/boot/fsbl.elf`。

1. 后续获准后才按现有手动启动路径运行 A53 FSBL、R5 停在入口；显式选择本次 bit/ltx，使用该平台 `hw/sdt/psu_init.tcl` 的隔离解除及 PS-PL reset 配置。Launch 不自动加载 PL。
2. 继续 R5 后只到 `PWM_ADC 50574101 WAIT`。应用没有开机自动提交或使能。
3. `s` 检查 ID/status；`a` 只读原 ADC 冻结快照（本应用不自动校准，未校准电流不能当真实反馈）。
4. `p` 请求 25/50/75%，`s` 区分 received/adopted；确认 adopted 序号后，`e` 请求全局及六路逻辑许可。所有输出仍只接内部 100MHz ILA。
5. `t` 请求 75/25/50% 阶跃，观察下一个规定谷值整组采用。`d` 禁止；`h` 只允许三相上路、`l` 只允许三相下路，仍受互补请求/死区约束。重新允许等谷值且重新计死区。
6. 结束前 `d` 并读回许可 0。任何复位/失锁后都需重新显式配置/使能；应用不自动恢复。

串口只提交状态，不决定实时边沿；R5 发字符到本地域关断的传输延迟不是 10ns。原 ADC 转换不随 PWM 常规禁止停止。本轮固定 duty 未连接采样反馈、FOC 或 Runtime，不能宣称完整闭环已通过。
