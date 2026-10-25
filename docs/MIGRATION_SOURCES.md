# 来源与迁移清单（计划，尚未复制）

源仓库：`kazecode666/FPGA_XC7A200T_Study`。
- PR53已接受p3合并：`4470e357cb91778072036475baa667c839dc12c6`。
- 规划时源main：`6617cf58a12b2f49ec9c30d4d41fd800b0b5d911`，包含PR54任务文档，不代表M4实现通过。
- 本地工作树、未提交修改及未保存窗口：由Codex记录，不能用上述提交代替本地状态。

## 必须迁移与按需参考

| 类别 | 源路径/检索入口 | 目的与边界 |
|---|---|---|
| 八份冻结来源 | `docs/reports/m3_foc_hdl/pr53_pipeline_revision/source_snapshot/` | 全部文件及identity按字节保留到`baselines/pr53_p3/source/` |
| 活动仿真/FOC模型与外部.m | `simulink模型/` 中同名源、上述快照 | 对比最新本地后选定活动副本；首轮保留文件名、布局和语义，补必要依赖 |
| 原生p3 RTL/TB/data | `generated/m3_foc/`，包含manifest和candidate_contract | 按清单完整复制到`generated/legacy_m3_p3/`，旧Artix功能基线，非5EV成品 |
| p3生成配置 | `.../candidates/p3/candidate.json`、回读、相关`scripts/m3_*` | 只取重现必要依赖；注意无candidate默认是旧失败B3 |
| 验收摘要及约束 | `docs/FOC_HDL_TIMING_CONTRACT.md`、p3验收JSON、原始时序/代表性测试 | 少量原始文件保留加旧库固定SHA链接，全部历史大报告不搬 |
| FOC数值设计 | `docs/FOC_FIXED_POINT_DESIGN.md`、`simulink模型/pmlsm_foc_fixed_config.m` | 源算法/类型依据，不迁移旧器件引脚为新约束 |
| Host与原对齐 | 活动主模型；`coordination/reports/m1b_repeat_moves_alignment.md` | 连续点位、原五态和有效复位，后续R5迁移语义来源 |
| 完整MIL/DSP研究资料 | `PMLSM_MIL_ControlCore_Sim.slx`、`PMLSM_ControlCore_Block.slx`、`PMSLM_Close_Loop_MBDL4.slx`本地实际位置 | 必要引用/初始化一起保留只读参考；旧DSP模型不整体调用其板级初始化 |
| StudyL1 | `learning/study_l1_speed_pi_hdl_compare/`的模型/状态审计/代表测试 | 取速度PI语义与软件参考，不再要求速度环RTL生产部署 |
| XSI与反馈链经验 | Step7B/C及当前M4必要脚本 | 仅精选可复用运行/接口代码；不继承旧counts极性、无效全HDL调度或未通过结论 |
| 硬件和论文资料 | 旧工程、本地AXU5EV资料、用户既有资料目录 | 分类索引电机/驱动/ADC/光栅磁栅/板卡/文献；核对许可后决定可入库内容 |
| 未完成M4工作 | 当前本地任务分支和未提交文件 | 保存独立快照与摘要，标NOT_ACCEPTED；大包仅本地，不加入活动MATLAB路径 |

## 八份精确输入的原始SHA256

```text
design_PMLSM_three_loop.m          884e199a13e0fa8cf1bf2551c9b29060eeb1d016af0a9fa17c7ab4d7da38aaa2
init_PMLSM_PI_FOC_Float_Baseline.m 5ab7a40613a672b6805ec15dd9ef394fa1aaa0958ec1b9a3ecbbdf1e0a00a016
m1a_require_float_init.m          15cbf8a0bad430eafcff1ce900947589112ecadf137a595a4446a385e1c35fcf
PMLSM_FOC_FixedPoint.slx          ec14e246b00b28b47df6b5250fa72e10819a97a826966d6872fc0cf77f8bba19
pmlsm_foc_fixed_config.m          27008b96a8ea04f68619c39426bc74218b1a96f5059a4959b9e4ca46288aebe1
PMLSM_PI_FOC_Float_Baseline.slx   b27a9083897d932b021d91613799a226748a0be6fc0f50bf4a5cae62aec229dd
pmlsm_point_move_step.m           dbfc0fac3e2e79298f7c7b71a0f52ded12616d460bacece8f1611eb70d0a8b9b
pmlsm_scurve_profile.m            bf1dfeda99037e990980d125176b4bdd5723a1606f6066597d81b2330a0bc79b
```

来源是PR53提交的identity.json；这是定位和完整性锚点，不代替本地功能验收。

每个实际迁移文件记录source_repo、source_commit或LOCAL_DIRTY、source_path、source_sha256、dest_path、dest_sha256、classification、修改原因、许可证/公开范围与验证结果。参考资料只有索引也明确标INDEX_ONLY；不得将“找到文件”写成“已迁移运行”。

不搬旧`.git`、工具缓存、全部失败候选SV、数百万行波形/报告、整套厂商安装包或旧MCP/密钥配置。完整历史留旧库固定提交追溯。旧M2例外只作历史记录，不放行新平台错误。
