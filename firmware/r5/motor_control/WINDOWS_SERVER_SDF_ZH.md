# Issue40 / PR41 — Windows服务器SDF：已结束的执行记录

> **当前说明（2026-11-13）：本页仅用于追溯历史，不是现行执行脚本或待办清单。** 服务器局部PWM两角SDF已经完成并通过；完整功能PL的两角动态SDF仍未完成，且目前没有再次启动长时间全量`xelab`的任务。当前统一状态：[HANDOFF](../../../coordination/HANDOFF.md)、[results.json](../../../verification/motor_control/results.json)、[PR41](https://github.com/kazecode666/AXU5EV/pull/41)。

## 一、实际结果（替代早期“仍待启动”的说明）

| 实验范围 | 实际状态 | 判定 |
|---|---|---|
| 完整功能PL网表：slow/max，`xelab` O0 | 工具编译阶段出错，未完成XSim动态 | **NOT_COMPLETED，不是DUT失败** |
| 完整功能PL网表：slow/max，`xelab` O2 | 在24小时预算到限时仍未生成可运行快照 | **NOT_COMPLETED，不是DUT失败** |
| 完整功能PL网表：fast/min | slow未完成，未启动 | **NOT_RUN** |
| 已布线PWM cut：slow/max | SDF成功注释、动态全部场景完成 | **PASS** |
| 已布线PWM cut：fast/min | 与slow使用相同最终测试台，动态全部场景完成 | **PASS** |
| 板上R5、ADC、ILA和电机 | 本轮未上板 | **NOT_RUN** |

原完整设计的路由STA仍有独立PASS证据（WNS +1.272ns、WHS +0.011ns），与上述动态仿真状态不能互相替代。

## 二、当前有效证据入口

- [PWM局部两角最终报告](../../../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)。
- [局部物理接口极性证明](../../../verification/motor_control/evidence/pwm_cut_windows_20261113_04/POLARITY_PROOF.md)。原RTL的`auto_inhibit`为高有效禁止；局部物理切点承载`permission=!logical_inhibit`，适配仅存在于测试台连接层。
- [slow/max的工具与动态结果](../../../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/slow/summary.json)；[fast/min的工具与动态结果](../../../verification/motor_control/evidence/pwm_cut_windows_20261113_04/v2/fast/summary.json)。
- [全量SDF早期停止记录](../../../verification/motor_control/evidence/full_sdf_20261110/README.md)、[O0编译故障回执](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6801862540)、[O2超时回执](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6844442026)。
- [局部cut第一至第三轮的失败与诊断证据](../../../verification/motor_control/evidence/pwm_cut_windows_20261113_01/README.md)（后续轮次在相邻`_02`/`_03`目录）。

本轮局部验证每角完成756022次动态检查、11次源请求/接受、8次谷值采用/回执、3次取消/重臂，最小死区1000ns，相关工具正常退出、原生SDF注释成功且没有真实时序错误。

## 三、不可扩大宣称的覆盖边界

局部PWM cut的输入采用**声明的50/100MHz相关时钟及0.2ns局部源延迟模型**，不包含ADC/FOC算法的门级传播、完整源到切点互连和时钟树、PS/AXI环境、80字R5板上读回、完整上游late/disarm/reference重臂逻辑。它不等于`FULL_CHAIN_SDF=PASS`。

原BD中`fast_inhibit`连接常量0，不能把对该输入的独立动态覆盖标记为PASS。没有经过确认的外部PWM输出端口和驱动硬件，也没有功率级验证。

## 四、历史操作与后续决策

过去的发布包、命令、运行器和日志保留在PR41历史讨论、Git版本历史及既有Evidence/Release中；**不应从本页重新执行旧O0/24小时入口，也不再开展相同输入的参数搜索**。若未来重新授权完整SDF工作，应另立具有明确目标、预算和验收范围的任务，不能把既有局部PASS改成全链PASS。

下一步是本地Codex核对并同步当前GitHub文档与现行分层结果，随后由用户决定PR41是否允许按限定范围验收；无功率板测及R5现场采集必须另行授权。所有历史原始证据不因本页更新而删除或改判。
