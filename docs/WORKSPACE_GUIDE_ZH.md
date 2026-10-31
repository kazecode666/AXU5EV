# 工作区、上板工程与数据保存位置

更新：2026-10-31。仓库 `kazecode666/AXU5EV`，本地根目录 `D:/Project/AXU5EV`，分支 `codex/ax02a-r5-target`、草稿 [PR #16](https://github.com/kazecode666/AXU5EV/pull/16)。本文统一目录入口；具体操作以[首次上板指南第13节](../firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md#13-runtime-100µs-r1aba实测之后的p1000候选review后用户执行)为准。

## 当前入口

| 目的 | 入口/位置 |
|---|---|
| 当前任务及未完成项 | [coordination/HANDOFF.md](../coordination/HANDOFF.md) |
| 日常仿真 | `simulation/START_HERE.m`；唯一参数入口 `simulation/init_AXU5EV.m` |
| 下一次用户上板 | `.runtime/ax02a/vitis_runtime_100us_r1`；Review后按指南第13节 |
| 当前构建配置 | [build_config.runtime_100us_r1.json](../firmware/r5/ax02a/build_config.runtime_100us_r1.json) |
| 原始实测数据 | `.runtime/ax02a/board_manual/<独立实验目录>/` |
| GitHub精简证据 | `verification/ax02a/<对应实验或候选>/` |
| 当前离线成果 | `verification/ax02a/runtime_100us_r1/`；T4板验NOT_RUN |

本地模型/参数存在未提交修改。现有候选来自T3构建时的生成源，不能认定ELF已同步这些修改；本轮不保存模型、不重建候选。当前参考与PR14历史参数分开标识，以各自metadata为准。

## 当前上板候选：整组路径一起核对

以下路径均相对于 `D:/Project/AXU5EV`，在Vitis选择workspace时使用完整绝对路径。

| 项目 | Runtime 100µs R1 |
|---|---|
| Workspace | `.runtime/ax02a/vitis_runtime_100us_r1` |
| 平台/域/应用 | `ax02a_platform` / `r5_standalone` / `ax02a_replay` |
| Launch | `ax02a_first_wait_a53fsbl`；旧workspace有同名配置，须核对实际路径 |
| R5 ELF | `.runtime/ax02a/vitis_runtime_100us_r1/ax02a_replay/build/ax02a_replay.elf` |
| Map | 同目录 `ax02a_replay.map` |
| A53 FSBL | `.runtime/ax02a/vitis_runtime_100us_r1/ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf` |
| 来源记录 | 该workspace内 `runtime_candidate.json`、`runtime_candidate.tcl` |
| 身份/映射 | `candidate_id=0x52313031`、`mapping_version=1`；已验证配置raw9999/logical10000 |
| P1000输入/参考/元数据 | `.runtime/ax02a/replay/p1000/{input.bin,reference.bin,metadata.json}` |
| v2参考描述符 | `.runtime/ax02a/phase_p1000_descriptor/reference_descriptor.bin`，R1仍复用此路径 |
| 新原始读回目录 | `.runtime/ax02a/board_manual/runtime_r1_p1000_01`，在读回时新建 |
| 开始前配置 | `.runtime/ax02a/runtime_r1_pre_begin_01.json`，与同编号实验对应 |
| 离线分析输出 | 同次原始目录下 `analysis/`、`crosscheck/`，均须尚未存在 |

普通PowerShell纯文件检查，不连接板卡：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_build_r5.py --config D:/Project/AXU5EV/firmware/r5/ax02a/build_config.runtime_100us_r1.json --check-startup
```

**不要省略 `--config`。** 构建器无参数默认值仍指向历史phase配置；当前完整新构建/预检须显式 `runtime_mapping=1`，省略/旧版本在创建workspace前拒绝。历史ELF的只读检查继续兼容。候选已构建，只检查时保留 `--check-startup`；未来重建须另定独立workspace，不覆盖现有ELF。

## 每次实验如何保存

1. 首次R1使用 `runtime_r1_p1000_01` 和 `runtime_r1_pre_begin_01.json`。路径已存在时先查看所属实验；后续新实验使用下一未占用编号，将读回、分析、交叉命令中的路径一起更新。保留真实before/after experiment、候选身份及中断声明，不拼接旧输出。
2. P1000完成后，同一次目录保存 `run.json`、`output.bin`（328000B）、`timing.bin`（64000B）、`report_v2.bin`（2400B），另保留同次开始前配置和GUI停点证据。合法早失败可能只有run.json，保存真实错误码及timer/snapshot；snapshot.valid=0时残留字段不作当前配置证据。有效失败前缀排除失败帧；失败或后处理未完成时不读取报告。run.json的captured_records/report_captured/report_validity说明实际捕获范围，捕获的报告仍须PC交叉，不填充旧尾部或标为完整通过。
3. 按指南用该次run和同套参考离线分析，分别记录数值、deadline/sequence、period consistency及PC/C一致性。分析目录已有时换新目录；原始文件不改。
4. 原始二进制、完整workspace保留本地；GitHub只提交必要摘要、来源、身份和结论到 `verification/ax02a/<同名实验>/`，更新HANDOFF。`.runtime/` 已被Git忽略，**推送仓库不备份原始数据**；需要转存时由用户另存整次实验及配套参考/候选来源。

下表路径均位于 `.runtime/ax02a/` 下：

| 数据 | 原始目录 | 解释 |
|---|---|---|
| 首次完整运动 | `board_manual/motion_03` | 64536×41 PASS，不能截前1000帧充当新P1000 |
| 旧P1000/exp2 | `board_manual/p1000_01`、`board_manual/p1000_exp2_capture` | 按所属实验解释，旧相位趋势不接受 |
| phase诊断P1000 | `board_manual/phase_p1000_01` | 数值/截止期序号通过；约+0.99779tick/帧，周期拒绝 |
| TTC-only ABA | `board_manual/ttc_aba_01/{A1,B,A2}` | 每组run.json + samples.bin 16000B，真实IRQ已复算 |
| 下一次Runtime R1 | `board_manual/runtime_r1_p1000_01` | 预定新目录，当前NOT_RUN |

TTC-only的16B记录与Runtime的64B timing记录不同，不可交叉解码。motion_01/02等失败/中断记录及 `ttc_aba_01.zip` 继续保留。

## 目录职责与保留边界

| 位置 | 职责 |
|---|---|
| `simulation/` | 活动模型、唯一参数入口和必要.m，保留用户修改 |
| `simulink模型/`、根目录 `setup_AXU5EV.m` | 旧入口转发/用户wrapper，不另设活动参数入口 |
| `firmware/r5/ax02a/` | 版本化平台/runner/读回源码、配置模板、操作指南 |
| `hardware/axu5ev/`、`integration/ps_pl/` | 平台脚本、板卡事实、接口合同 |
| `.runtime/ax02a/ps_target/`、`.runtime/ax02a/target/codegen/` | 真实XSA、已生成R5算法源，当前构建依赖，保留 |
| `.runtime/ax02a/replay/` | current_motion、current_alignment_reset、p1000、pr14_original分开保留 |
| `verification/` | 精简证据与测试，历史证据不覆盖 |
| `coordination/tasks/`、`coordination/reports/` | 任务原文与阶段报告，当前入口为HANDOFF |
| `baselines/`、`generated/legacy_m3_p3/`、`references/legacy/` | 已验收基线及来源，generated名称不表示可删除 |
| `资料/`、`references/local_only/` | 本地厂商原件，不入库，保留 |
| `.runtime/ax00*`、`ax01*`、`issue8/`等 | 既有证据、MEX/XSI、历史快照，保留 |

六套workspace均位于 `.runtime/ax02a/` 下，完整保留：

| Workspace | 用途 |
|---|---|
| `vitis_runtime_100us_r1` | 当前候选，第13节，板验NOT_RUN |
| `vitis_ttc_characterize` | 已完成ABA的TTC-only应用，第12节历史步骤 |
| `vitis_phase_diagnostic` | phase诊断及其本次实测来源，第8节历史步骤 |
| `vitis_postprocess` | 旧v1/2336B后处理候选，第7节历史步骤 |
| `vitis_target_a53fsbl` | 首次启动/motion/P1000调试工程，第4—6节 |
| `vitis_target` | 最初目标构建/旧R5 FSBL工程，历史保留，不用旧launch重试 |

本轮通过索引与阶段标识整理职责，保留物理路径和启动/来源引用。手工移动workspace、原始数据或生成源会使现有配置失效。

## 清理与ChatGPT交接

历史[清理候选](../coordination/reports/workspace_cleanup_2026-10-31.md)记录整理时109个测试临时目录（892文件/约10.6MiB）；用户已手动删除，不恢复、不再清理。关键workspace和原始数据仍在原路径。本轮Review5722212233的新测试产物隔离于 `.runtime/ax02a/review_5722212233/`。修复详情见[本轮报告](../coordination/reports/ax02a_review_5722212233.md)，当前等待复审，R1 ELF未重建。

给ChatGPT端可直接引用本指南和HANDOFF，并转述：

> 仓库kazecode666/AXU5EV、PR16、分支codex/ax02a-r5-target。目录整理统一了当前入口，workspace和原始数据未搬动。下一次按FIRST_BOARD_RUN_ZH.md第13节，选择vitis_runtime_100us_r1、ax02a_replay及该workspace自己的FSBL/ELF；候选0x52313031、mapping_version1、raw9999/logical10000。输入/参考仍用replay/p1000，描述符仍用phase_p1000_descriptor。新采集保存board_manual/runtime_r1_p1000_01的run/output/timing/report_v2四文件，开始前配置同编号另存。ABA已完成，不重复ABA/C；Runtime R1板验NOT_RUN，第二次完整motion、alignment/reset、完整A5/WCET仍未完成。GitHub只保存精简证据，原始数据本地保留。用户手动上板，Codex不操作硬件；PR仍Draft、不合并。
