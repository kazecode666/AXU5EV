# AXU5EV — ChatGPT / Codex / GitHub 交接

日期：2026-10-25。**状态：AX-00 PR #1与资料任务PR #2已合并；AX-00B按Issue #3完成本地资料静态核查，提交独立开放PR等待ChatGPT Review。** 资料结果见[AX-00B报告](reports/ax00b_vendor_review.md)，原仿真/RTL证据仍见[迁移报告](reports/ax00_migration_report.md)。

## 唯一当前任务

Review [AX-00B资料核查](tasks/ax00b_alinx_vendor_materials_intake.md)与[Issue #3](https://github.com/kazecode666/AXU5EV/issues/3)的实施PR。本地根目录为 `D:/Project/AXU5EV`，origin 为 `https://github.com/kazecode666/AXU5EV.git`。资料原件在忽略的`资料/`，只上传原创总结和索引。不自动进入AX-01/02，原算法/布局/生成RTL保持原样。

## 方案已定，不重新讨论

Cortex-R5F为实时运动控制核心：外环、原对齐及上层参考/轨迹/命令管理走C软件；PL保留电流算法、实时采集/角度与PWM/快速禁止。旧PR54全三环/全对齐HDL目标被此决定替代。

旧工程只读保留。当前M4实验安全收口、保存局部成果和失败，不继续投入全HDL对齐取模优化。没有自动停止用户Codex/MATLAB进程；由执行者在安全边界落实。PR53 p3是已接受算法/RTL锚点，不声称已在5EV通过。

## 交付约定

全新仓库main仅一次文档初始化，实际迁移分支`codex/ax00-migration`。最后在**新仓库**提交一个开放PR：实际模型/必要脚本/精选RTL/资料索引/哈希来源/迁移复验，不自动合并。

报告须写实际新root、origin、repo可见性、source HEAD/dirty情况、保留内容、复制/排除清单、路径独立性及每项验证状态。ChatGPT后续以`kazecode666/AXU5EV`＋PR号＋提交SHA Review；不把旧库PR号当新库PR号。

新远端暂不可创建时，完成本地初始化/迁移/检查并保留报告，状态REMOTE_BLOCKED，说明实际障碍；不能为此改回旧origin或把新实机资料发布到旧公开库。

## 当前不做

不新建完整R5平台、生成新电流算法、优化旧全HDL控制器、改PI/死区/对齐、不作板级XDC猜测、不烧录/上电。后续AX-01/02分别处理软件边界/接口及5EV重定向和混合闭环。

## 接受边界

旧板卡的综合/RTL结论是来源证据，不是新板验收；400帧等未审本地M4结果不能替代PR53来源。迁移通过只证明文件/依赖/现有仿真恢复，不等于R5实时性、5EV布线时序或实机安全通过。
