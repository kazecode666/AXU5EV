# PR41 / Issue40 PWM cut：原实现极性证明与局部两角 SDF

承接 [授权评论6849202758](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6849202758)，服务器 DeepSeek Harness GPT-6.1 Sol 独立执行；无本地 Codex、板卡、生产 RTL/约束/参数/bit/XSA 修改，无全设计 elaboration、重综合、实现、额外指纹检查、合并或 Issue 关闭。

## 独立状态

| 项目 | 本轮状态 |
|---|---|
| CUT_BOUNDARY_MAPPING | **PROVEN：cut 输入是 permission = !logical_inhibit** |
| PWM_CUT_SDF_SLOW | **PASS**，最终 v2，原生 max SDF + 完整动态 |
| PWM_CUT_SDF_FAST | **PASS**，最终 v2，原生 min SDF + 完整动态；slow 完整 PASS 后才启动 |
| FULL_CHAIN_SDF | **NOT_COMPLETED** |
| 既有全设计 STA | 既有证据 WNS +1.272 ns / WHS +0.011 ns、TNS/THS 0；本轮未重跑、不以其替代动态 |
| 既有 RTL | 既有独立证据；本轮未改生产 RTL，未重跑其测试 |
| fast_inhibit 独立动态 / 板卡 | N/A（原 BD 常量0） / NOT_RUN |

## Task1 — 先证明，后适配

唯一一次原完整 routed DCP cone-only 只读查询耗时 **239.502 s**，上限600 s，完成标记和 Harness exit0均留存。PowerShell raw ExitCode 为 null，未伪造其值；完成依据见 [probe_status](<probe_status.txt>)、[process record](<probe.process.json>)、[脚本](<probe_polarity.tcl>)、[原查询日志](<probe.log>)、[DCP 完整 cone 输出](<physical_cone.txt>)、[精简驱动引脚连通](<dcp_driver_connectivity.txt>)。

[原完整 timesim 网表定向摘录](<original_full_netlist_excerpt.txt>)独立证明：上游 LUT5 INIT=04000000（bit26）为 P=run_permitted & ref_arm & !invalidate & !lock_blocked & auto_online。原物理 wrapper 的 frame_cancelled_reg_0 实接 manual_disarm；不能误认成同名 controller state。[精确逻辑源 aliases](<source_aliases.txt>)明确 ref_arm=ref_active[7][0]、invalidate=apply||restart||manual_disarm，闭合此前两个语义缺口。故 P 恰为逻辑 auto_inhibit 的补值，不是仅凭名称或局部 CE 猜测。

原完整 DCP 中 upstream native auto_inhibit_o、PWM 两级 auto_inhibit_i、debug_o[35] 属同一物理 net segments。捕获 LUT08000000、request/busy reset LUT7、两级下降沿 release CLR LUT7F、enabled C8 / want80 / 六路 C8000000 权限扇出均一致。逻辑名 inhibit 是高有效禁止；物理 net 和导出 cut 端口虽然保留该名，实际承载高有效许可。详见 [极性证明](<POLARITY_PROOF.md>)。

在 resetn=locked=online=valid=1、busy=0 条件下：

| logical inhibit | cut physical P | capture CE | request/busy 同步 reset | release CLR | 输出许可 |
|---:|---:|---:|---:|---:|---|
|0|1|1|0|0|经原两级下降沿 release 和 deadtime 后许可|
|1|0|0|1|1|禁止；pending/active 取消，六路低|

一般 CE=resetn & locked & online & valid & !busy & P；reset=!(P&resetn)；release CLR=!(P&resetn&locked)。本轮未另选切点、未重新导出网表/SDF、未扫全设计 STA。

## Task2 — 单一接口适配与首笔实际捕获

[最终 TB](<v2/pwm_cut_tb.sv>)只在顶层连接 cut_permission=~inhibit。[接口及观察门槛 diff](<TB_CHANGES.diff>)保留逻辑 inhibit、源握手、同沿 +0.2 ns valid 撤销、下一源沿 poison、取消/重臂原语义。没有 force 内部信号、改源 CQ、相位、20 ns anchor 或 DUT。

slow 实际 trace：910 ns pre-edge physicalP=1/CE=1/busy=0/request=0；910.2 ns valid撤销；914 ns frozen_seq=1、frozen_compare=3e813883e8、busy=request=1；944 ns pending=1/accepts=1；930 ns无重复握手；后续 poisoned seq63 未替换已冻结 seq1。trace 同时含 logical/physical level、ready、CE、reset、busy/request、frozen、pending。首笔 gate 失败会立即 fatal，不是以捕获成功提前退出。完整取消/重臂和 inhibited-no-capture 检查继续执行。

40 PWM-edge pending gate 仅是诊断存活上限，不是 extracted CDC deadline；SOURCE_CQ=0.2 ns 是固定本地源模型假设，不声称为 extracted CQ。原切点外真实源互连不包含在该局部 SDF 内。

## 唯一一次非极性 TB 修订与基础设施中断

初始已证明适配 v1 的 slow 在 **750824 ns / phase9999 / active_seq3** 报 C=0 request/output 断言失败；原失败保留于 [v1 raw log](<v1/slow/xsim.stdout.log>) 与 [summary](<v1/slow/summary.json>)，不冒充 DUT 故障或 PASS。

原 PWM RTL 的 request 使用 next_phase，valley 时提前选择 pending bank。旧 TB 把该前瞻组合 debug 与当前 active bank/输出混配。授权内唯一一次 v1→v2 非极性修订在外部 PWM 上升沿采样 debug request，对齐逻辑输出周期，并增加独立 raw lookahead 公式检查；没有屏蔽 valley/0/5000 检查、放宽 deadtime 或挪动观察延迟。[最小修订 diff](<TB_REVISION.diff>)、[定性依据](<REVISION_REASON.md>)、[独立只读审查](<INDEPENDENT_REVIEW.md>)、[原44→最终51 callsites 校验](<static_validation.json>)。

边界：外部 pclk 上的 debug 采样只校正逻辑 epoch，**本身不是内部输出 FF 的物理采样/clock-arrival 证明**；仍依靠启用的原生 timing checks、独立输出/Q/deadtime/atomic-bank 检查。raw golden 在非 valley 时使用 DUT active_compare，结合现有 bank 检查，不是完全独立的 bank 状态模型。

v2 第一轮 slow 在 seq5 已采用后会话基础设施中断：进程均消失，raw summary 停在 RUNNING，没有正常退出或 PASS，原因未知。原目录完整保留为 [slow_interrupted](<v2/slow_interrupted/summary.json>)。用户要求继续后，仅恢复完全相同最终 TB/native inputs，未增加版本；[中断裁定](<INFRASTRUCTURE_INTERRUPTION.md>)、[窄化预算 recovery wrapper](<resume_identical_slow.py>)。先前路径转义错误及随后 exclusive-directory 拒绝均发生在工具仿真启动前，未覆盖任何 raw 数据。恢复调用预算595/575/3300 s，保守扣除此前耗时；原每角上限600/600/3600 s未放宽。

## Task3 — 最终同一 TB 动态结果

| 指标 | slow/max 最终 v2 | fast/min 最终 v2 |
|---|---:|---:|
| xvlog / xelab / xsim wall seconds |0.765 / 9.907 / 319.406|0.766 / 9.890 / 274.625|
| 实际结束时刻 |2182440200 ps|2182440200 ps|
| 完整 PASS 标记数 |1|1|
| 动态 check 执行数 |756022|756022|
| offer / accept |11 / 11|11 / 11|
| valley adoption / ack |8 / 8|8 / 8|
| anchor / startup / peak |3 / 3 / 3|3 / 3 / 3|
| cancel / rearm |3 / 3|3 / 3|
| carrier periods |20，100 us 检查|20，100 us 检查|
| high / low edge observations |43 / 41|43 / 41|
| zero / full boundary observations |51028 / 51028|51028 / 51028|
| Q events / release observations |8 / 4|8 / 4|
| 最小 deadtime |1000.000 ns（门槛>=990 ns）|1000.000 ns|
| 最大观测 Q 事件延迟 |0.100 ns|0.100 ns|

两角均全阶段自然退出0，XSIM43-3452 原生 SDF 注释成功，diagnostics与reviewed warnings均空，唯一完整 PWM_CUT_SDF_PASS。不能只靠exit0/模拟推进判定。slow [commands/summary](<v2/slow/summary.json>)、[动态原日志](<v2/slow/xsim.stdout.log>)、[注释原日志](<v2/slow/xelab.stdout.log>)；完整 argv、stage pid/limit/elapsed、实际进度保留。

fast [commands/summary](<v2/fast/summary.json>)、[动态原日志](<v2/fast/xsim.stdout.log>)、[注释原日志](<v2/fast/xelab.stdout.log>)；[机器可读最终裁定](<RESULTS.json>)。两角计数相同，各自独立产生一个完整 PASS。

实际调用如下；恢复 slow 的唯一差异是更窄运行预算，仿真命令、优化 O2、timing checks、transport/pulse 配置不变。fast runner 自身再次验证 slow 完整 PASS 与相同最终 TB/native path；slow→fast 之间未编辑输入。


env: Python bundled runtime + Vivado/XSim2026.1，单机 Windows。

```powershell
python pwm_cut_sdf_20261113_1735/resume_identical_slow.py
python pwm_cut_sdf_20261113_1735/v2/run_corner.py fast
```

## Task4 — 证据与范围

原生网表及两份 SDF 仅复用服务器已有导出，未重复上传大型生成输入；上述原完整网表摘录和 DCP cone 是 proof，不是替代仿真输入。证据包含两版 TB、相同 [runner](<v2/run_corner.py>)、失败/中断/最终结果原日志、最小diff与裁定；旧_01/_02/_03证据不覆盖。

局部两角均已 PASS，但**FULL_CHAIN_SDF=NOT_COMPLETED**：FOC/ADC 算法、跨 cut 真实互连、完整 reference 重臂没有被本 cut 动态证明。既有全设计 STA、RTL 结论独立保留；未做板卡和 fast_inhibit 独立动态。PR41 保持 Draft，不合并、不关闭 Issue40。
