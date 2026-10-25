# AX-01 首批开发结果：R5软件提取与PL边界

2026-10-26，`kazecode666/AXU5EV`。PR #4已按最新评论修订并合并，合并提交`7492fc4a354d356f19123da0649e7861e6354943`；本批开发分支`codex/ax01-r5-pl-boundary`从该main建立。

实施提交`7c9246a95d63bcd4012ac4d4f3d719d4faa15458`，交付[PR #5](https://github.com/kazecode666/AXU5EV/pull/5)，保持开放供Review；后续文档提交仅补交付链接。

## 做了什么

- 新建`firmware/r5/AXU5EV_R5_Control.slx`，直接从现有`PMLSM_PI_FOC_Float_Baseline`复制Control_Task（原SID505）和Alignment_Task（原SID2103）。保留位置P、速度PI、Reference_Manager、调度器及原五态对齐，移出电流FOC和仅FOC使用的电流/角度输入；导出d/q参考、偏置和状态。
- 原有1ms/10ms调度器不改；顶层100µs调用，保留独立对齐/控制函数调用入口。对齐10000/30000/2000拍、手动Start、一次性偏置公式和PI/Init复位区分不变；没有调PI、位置P或初始参数。
- `verification/r5/AXU5EV_R5_Reference.slx`保留原Control_Task连同FOC作为对照，只增加参考导出；FOC输入置零，比较控制参考和状态，不将其当成机械闭环或5EV验证。
- 新增[PS—PL边界](../../integration/ps_pl/INTERFACE.md)，把软件端口、MBDL4既有需求与已接受FOC端口/类型对应起来。PL原RTL及其生成配置未修改。
- 整理新模型根层与Motion_Control的短正交线、局部方括号标签及d/q两条参考路径。渲染检查了根层、Motion_Control、位置P、速度PI、Reference_Manager及Alignment_Task；三个新整理层的模块矩形重叠为0。未改原主模型布局。
- R5模型65个Goto均local，94个Inport/Outport保持默认30×14；对照模型74个Goto均local，202个端口同为默认大小。`model_check`两模型均healthy，无悬空端口/线或Stateflow lint问题。

## 实际验证

MATLAB/Simulink R2026b（26.2.0.3386108），ERT；生成目标仍为Windows64。MinGW直接编译生成C及只负责I/O/比较的`r5_c_replay.c`，未手改生成算法。46,505个采样点，每点比较12项输出。

| 工况 | 时长/点数 | 原模型组件→提取模型 | 生成C主机回放最大绝对偏差 |
|---|---|---|---|
| position_reset | 0.1s / 1001 | PASS，0 | 5.1070259132757201e-15 |
| speed_slew | 0.1s / 1001 | PASS，0 | 5.1070259132757201e-15 |
| current_test | 0.1s / 1001 | PASS，0 | 0 |
| alignment_full | 4.25s / 42501 | PASS，0；覆盖原0..4五态、完整计数及偏置公式 | 1.7763568394002505e-15 |
| alignment_reset_fault | 0.1s / 1001 | PASS，0 | 5.0306980803327406e-17 |

C回放容差1e-12；这是主机上编译生成C的等价性验证，不是ARM实时性结论。原主模型、初始化、PL FOC与冻结来源没有提交改动。

Simulink管理的顶层SIL曾尝试，**FAIL（环境）**：辅助库`AXU5EV_R5_Control_ca`构建时，安装目录驱动映射检查产生空MATLAB_ROOT，make找不到`/toolbox/rtw/targets/pil/c/coder_assumptions_hwimpl.c`。没有关闭该检查来假装通过，也未改变系统工具配置。其内部条件信号日志另有“不支持SIL日志”警告；本轮比较使用全部根输出。最终采用上表独立主机C回放，不将它记作Simulink管理SIL通过。

对照FOC的原Motor Control Blockset库存在参数覆盖警告，正常模型对比仍通过；未改原库。建模过程中发现的函数调用错误分支、对照端口重连缺项及验证结果结构体初始化错误均已修复，最终检查/独立进程运行通过。

## 复现入口

在仓库根目录用PowerShell执行：

```powershell
./scripts/ax01_verify_host_c.ps1
```

该入口启动独立MATLAB进程，执行C生成与模型比较，再编译/回放C。本机默认R2026b与已安装MinGW路径可通过脚本参数调整。正常比较入口为`ax01_verify_r5(false)`；可选`true`会尝试目前环境失败的Simulink管理SIL。`ax01_format_r5`仅作用于这两个新模型。

本地日志/回放CSV在`.runtime/ax01/final_verification.log`、`host_c_result.log`及同目录；C在`.runtime/ax01/codegen/AXU5EV_R5_Control_ert_rtw`。原图渲染留在同目录供本地查看，不新增哈希或保护报表。

## 真正未完成

这批是R5软件组件提取，**不是AX-01/02全部完成**。Simple_Host/Host_Core的命令、连续点位与轨迹部署提取、R5恢复管理、PS—PL原子交换/过期行为及数值转换适配仍需继续；不把本轮人工输入波形当已实现轨迹/总线。

R5目标编译、Vitis R5 domain/BSP/启动/TCM/MPU、板上调度/WCET、PL采样/位置/实时角度/PWM与快速禁止集成、5EV RTL仿真/综合/布线、ARM实测及实机均NOT_RUN。B-E芯片完整料号/PCB修订、外置ADC选型与接线、电平及故障链适配仍按[接口边界](../../integration/ps_pl/INTERFACE.md)推进；本轮没有烧录或上电。
