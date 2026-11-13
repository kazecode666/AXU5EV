# Issue40 / PR41 — 旧完整SDF发布包说明（归档）

> **2026-11-13：本文件已归档，不是当前运行入口。** 曾经发布的完整功能PL网表、原始SDF和测试台输入包仍作为历史证据保留，但该包的O0与O2完整网表Windows动态验证未完成。不要按旧版说明重新执行全量长跑，也不要继续尝试Linux环境、文件摘要检查或新的参数组合。

## 当前唯一有效状态

- **PWM局部已布线SDF：** slow/max与fast/min均PASS，各756022次动态检查，原生SDF注释成功；最终证据见[报告](../../../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)。
- **完整功能PL动态SDF：** `FULL_CHAIN_SDF=NOT_COMPLETED`；完整slow O0发生工具编译故障，O2展开24小时仍超时，完整fast从未启动。
- **完整RTL及STA：** 既有独立PASS，不能被称为全链SDF PASS。
- **板测及R5现场采集：** NOT_RUN，没有现场操作授权。
- **当前工作：** 服务器SDF工作线收口，等待用户决定是否以限定范围接受PR41；原算法/RTL/bit/XSA均不因本页修改而变化。

## 历史入口与归档位置

[PR41现行说明](https://github.com/kazecode666/AXU5EV/pull/41)、[HANDOFF](../../../coordination/HANDOFF.md)、[聚合结果](../../../verification/motor_control/results.json)、[Windows服务器完整SDF历史回执](WINDOWS_SERVER_SDF_ZH.md)。

旧发布包、完整原始命令和异常日志仍在原GitHub Release、PR41历史评论与Git历史中。这些仅用于追溯早期尝试，**不是待执行命令**。现行交接不引入额外文件指纹核验或冗长版本标识。
