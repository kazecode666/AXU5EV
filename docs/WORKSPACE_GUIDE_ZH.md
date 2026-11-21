# 工作区、上板工程与数据保存位置

## 日常入口

| 用途 | 入口与位置 |
|---|---|
| 纯仿真 | [START_SIMULATION.m](../simulation/START_SIMULATION.m)打开[混合闭环模型](../simulation/closed_loop/AXU5EV_Hybrid_ClosedLoop.slx)，使用[纯仿真参数](../simulation/closed_loop/parameters/init_AXU5EV.m)。[START_HERE.m](../simulation/START_HERE.m)是兼容入口。 |
| 实机模型与生成 | [START_EXPERIMENT.m](../simulation/START_EXPERIMENT.m)打开[实机主模型](../simulation/experiment/AXU5EV_Motor_Control_System.slx)，使用[独立实机参数](../simulation/experiment/parameters/axu5ev_experiment_parameters.m)和模型内的 Model Workspace 快照。 |
| 模型打开、检查和生成说明 | [Simulink 双入口](../simulation/README_运行说明.md) |
| 当前交付、验收进度和下一步 | [HANDOFF](../coordination/HANDOFF.md) |
| 独立 J16 接口板静态验证 | [VIO 测试工程](../hardware/axu5ev/j16_level_test/README.md) · [接口板首板记录](https://github.com/kazecode666/J16-MBDL4-Module/blob/main/docs/writing/interface_board_static_test_record.md) |

## AX-04B R1 候选

相对仓库根目录，SELFTEST 位于 `.runtime/experiment/ax04b/selftest_r1_02`，REAL 位于 `.runtime/experiment/ax04b/real_r1_02`。两者的应用身份均为 `0x41585203`，R5 生成源对应模型 1.173。各自的 `vitis/` 配套其 `hardware/` 中的 bit、ltx 和 XSA，硬件从相应的 `*_02/hardware` 复用。候选组合、应用、FSBL 和启动项按首运行指南逐项对应。实板执行和物理 IO 验收仍为 `NOT_RUN`。[首运行指南](../firmware/r5/motor_control/FIRST_RUN_AX04B_ZH.md) · [生成 R5 C](../generated/experiment/ax04b_r1_01/r5) · [结果索引](../verification/experiment/ax04b/results.json)

## 目录职责与数据保留

| 位置 | 保存内容 |
|---|---|
| [simulation/closed_loop](../simulation/closed_loop) 与 [simulation/experiment](../simulation/experiment) | 两套按用途独立维护的模型、算法和参数。打开入口保留未保存编辑，并遵循各自参数刷新规则。 |
| [simulation/tests](../simulation/tests) 与 [simulation/archive](../simulation/archive) | 显式测试 fixture 与历史生成入口。 |
| `.runtime/closed_loop/<session>` | 本地纯仿真缓存、MEX 与结果。 |
| `.runtime/experiment/<新目录>` | 新生成的日志、定向验证和其他本地产物。生成时显式选择独立目录。 |
| [generated/experiment](../generated/experiment) | 版本化实机生成 C/HDL。当前 R5 源依候选索引选择。 |
| [hardware/axu5ev](../hardware/axu5ev)、[firmware/r5](../firmware/r5)、[integration/ps_pl](../integration/ps_pl) | 板级脚本、R5 应用、启动配置与 PS–PL 接口。 |
| [verification](../verification) 与 [coordination/reports](../coordination/reports) | 入库的精简验证证据和阶段报告。 |
| [baselines](../baselines)、[generated/legacy_m3_p3](../generated/legacy_m3_p3)、[references/legacy](../references/legacy) | 来源、冻结候选及可复用历史基线。 |
| `资料/` 与 `references/local_only/` | 本地厂商资料。 |

每次实验使用未占用的结果目录，保存同次输入条件、候选身份、原始记录和分析结果。既有 Workspace、源、原始数据和失败记录保留原路径。分析结论以该次输入和实际捕获范围为准。`.runtime/` 使用 Git 忽略规则，推送仓库只提交可公开的精简证据。需另行备份原始实验时，成套保存该次输出及匹配的参考和候选来源。

## 历史候选与实验数据

| 阶段 | 原路径与证据 |
|---|---|
| AX-02A | 原始回放与计时在 `.runtime/ax02a/`，含 `board_manual/`、`replay/` 和多套 Vitis Workspace。完整 motion 与 alignment/reset 的实际结果和遗留验收见[板测结果](../coordination/reports/ax02a_full_board_results_2026-11-02.md)。 |
| AX-02C1 / C2 | 原始硬件、软件和采集保留在 `.runtime/ax02c/` 与 `.runtime/ax02c2/`。[C1 实测摘要](../verification/ax02c/board_aux_fixed_01) · [C2 性能版签收](../verification/ax02c2/board_perf_r1_01/README.md) |
| ETH-01 / ETH-02 | 原始采集在 `.runtime/ethernet/eth01/board/` 与 `.runtime/ethernet/eth02/board/`。[ETH-01 r3 证据](../verification/ethernet/eth01/board_r3/README.md) · [ETH-02 实测证据](../verification/ethernet/eth02/board_results/README.md) |
| PR41 数字链冻结候选 | 原硬件、R5 Workspace 和 SDF 留在 `.runtime/motor_control/`。[离线结果](../verification/motor_control/results.json) · [历史工程说明](../hardware/axu5ev/motor_control/README.md#pr41-数字链历史) |

早期 Workspace、完整场景目录、使用过的日志路径和命令可追溯到[原工作区指南](https://github.com/kazecode666/AXU5EV/blob/ae1a496f8260015dfd79f2998a6d9535a97fa1f5/docs/WORKSPACE_GUIDE_ZH.md)和[历史交接](../coordination/HANDOFF_HISTORY_2026-10-31.md)。清理工作仅见[既有历史记录](../coordination/reports/workspace_cleanup_2026-10-31.md)。
