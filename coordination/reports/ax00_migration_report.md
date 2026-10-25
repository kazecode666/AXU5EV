# AX-00 精选迁移与独立复验

日期：2026-10-25。新仓库 `kazecode666/AXU5EV`，private；本地 `D:/Project/AXU5EV`，origin `https://github.com/kazecode666/AXU5EV.git`。迁移分支 `codex/ax00-migration`，开放 PR 等待 ChatGPT Review，不自动合并。

## 来源、保护与采用决定

- 桥接 PR：`kazecode666/FPGA_XC7A200T_Study#55`，head `81a4464784b06d49644d7e8d31cc7bdecb08cf58`，读取时 open/未合并。该提交仅提供初始化包。
- 已接受算法/RTL锚点：PR53合并 `4470e357cb91778072036475baa667c839dc12c6`。旧本地 HEAD `6617cf58a12b2f49ec9c30d4d41fd800b0b5d911`；存在未提交修改与删除，均保留。
- 实测目标初始为空、不在旧 Git 树内；独立初始化，无额外 clone/worktree，无复制旧 `.git`、无改旧origin、stash/reset/clean、强推或文件删除。新库仅复用旧库的本地作者姓名/邮箱，没有修改全局配置。
- 19个已修改磁盘文件存于忽略的 `.runtime/ax00/local_disk_snapshot/`；非敏感二进制patch、旧status及精选M4未提交源码另存忽略目录。旧 `.codex`、凭据及全局工具配置未复制。保护核查按原哈希与status逐项比较。
- 连接的 R2026b 工具会话枚举时没有加载模型。另有用户桌面MATLAB会话；未保存内容为 **UNSAVED_NOT_CAPTURED**，没有强制保存、导出、关闭或终止。尝试读取已有AutomationServer时受系统脚本策略阻止，未绕过策略。不能把磁盘快照当作全部窗口内容。
- 本轮没有启动新的全HDL M4候选；旧未验收工作保留、标NOT_ACCEPTED。未自动中止其他Codex聊天；本轮不对其他聊天将来的行为作保证。

八份冻结输入及identity在 `baselines/pr53_p3/source`，保持原SHA256；p3配置与精选验收证据分别在 `codegen` / `evidence`。34份manifest载荷及candidate_contract在 `generated/legacy_m3_p3`，原字节与原Artix属性保留。

活动init使用已接受版本，不采纳本地新增未验收M4三环参数接口。两份SLX系统XML经去除Position/Points/Labels/ModelReferenceVersion后逐字节规范化相等，采纳本地局部布局；保留冻结root配置、Stateflow和日志。未采纳本地物理日志抽取100→2及若干日志删除。没有修改PI、位置P、采样周期、原五态或默认10mm/5s/V10/A100。布局证明与本地原差异分别在 `layout_adoption.json` / `local_source_comparison.json`，活动哈希与原哈希单列。

## 资产与资料

逐项清单：`migration_inventory.csv`（120项导入资产，含首提交骨架、冻结输入、活动副本、RTL、必要工具与参考）。全部导入源记录source_repo/commit或LOCAL_DIRTY、源/目标SHA、分类、采用原因与许可范围；新编验证脚本另由Git追踪。

MIL/DSP旧库磁盘副本放 `references/legacy/mil`；另取完整 `D:/Project/PMSLM_Simulation` 的13份当前磁盘模型/初始化/说明为 `pmslm_disk`，不加入活动路径，不改其PICDO布局。StudyL1仅取浮点速度PI模型、类型/初始化和代表性向量/参考函数，没有重跑其历史全套学习任务。

`references/INDEX.csv` 有54项本地硬件/研究/论文索引；12份硬件资料存忽略的local_only副本，其余论文/文档索引保留原位置与SHA。未确认再分发许可的整本论文、厂商资料和安装大包不上传。实际5EV芯片全料号、修订、封装/速度等级及引脚/时钟资料尚未确认，见 `hardware/axu5ev/BOARD_INVENTORY.md`。

排除清单：旧 `.git`/`.codex`，全局工具配置和密钥，整库/整套scripts或reports，slprj/slxc/Xil及运行缓存，大波形、失败候选和M4完整生成包、原Artix板级工程与引脚约束、厂商安装包、无许可整本资料。未迁移依赖不通过旧绝对路径暗中补齐。

## 实际复验

| 层次 | 结果与证据 |
|---|---|
| 冻结输入与p3载荷 | PASS：8份输入、34份载荷及合同按原SHA核对；暂存blob再次核对，见asset_verification.json |
| 路径独立性 | PASS：独立MATLAB R2026b进程恢复默认path后仅添加新活动目录和验证scripts；FileName/which-all证明算法依赖位于新root，正常工具库位于MATLAB安装目录；path无旧root，见path_*.json和静态回调/引用扫描 |
| 浮点1.2s标准工况 | PASS：冻结来源与最终活动布局副本，各67信号，完整时间/数据完全相等 |
| 固定FOC1.2s标准工况 | PASS：同上67信号；没有插值、调PI或放宽容差。两模式共134行，max_abs全0，见baseline_comparison.csv |
| 单次Run连续点位 | PASS：原M1B测试接收.2→-.1→-.09mm三个新目标，最大接收延迟约100us；到位误差满足原.02mm判据；轨迹公式误差0，含busy/草稿/NaN/repeat/pause检查，见unit_live.json |
| 原对齐chart单元 | PASS：normal/no_start/reset/fault/reset_after_done，每组源/目标70001点、6路输出全0差；保持10000/30000/2000计数与0.5A，见unit_alignment.json |
| 完整4.2s物理对齐 | NOT_RERUN：可追溯旧M1B证据；本轮chart单元不代替机电整机验证 |
| p3短RTL smoke | PASS：xvlog/xelab/xsim均exit0，17帧、340183检查；bit/state/XZ/protocol/deadline均0。输出相位314，独立scoreboard，见rtl_smoke_result.json / rtl_smoke_scoreboard.json |
| 完整MIL/DSP/StudyL1和长历史回归 | NOT_RUN：保留参考及依赖，不整套重跑 |
| 新R5 C/SIL/WCET/AXI | NOT_RUN；AX-00范围外 |
| 5EV综合/布局布线/时序/ARM实测/bitstream/烧录/上电 | NOT_RUN；旧Artix通过不作为5EV验收 |

MATLAB实测版本 `26.2.0.3386108 (R2026b)`，工具和所需许可可用。固定FOC原sin/cos常数量化warning仍存在，源/活动一致，未屏蔽；这不构成新平台溢出或时序放行。首次RTL准备缺少一个Python合同模块，补入原提交依赖后通过，未改RTL。

点位和chart单元先在冻结算法活动副本执行；随后只采纳经静态证明的布局，最终活动0/1模式再跑并全部零差异。运行使用独立-batch，不操作用户窗口；点位脚本在退出时对其独立会话内未保存的参数编辑产生关闭提示，未保存磁盘SLX。大日志/波形仅在`.runtime`，精简结果与命令见 `verification/AX00_REPRODUCE.md`。

## 远端和审查边界

本机没有gh，用户自行建立空private仓库后，现有Git凭据推送；GitHub连接核实登录kazecode666及新库admin/push权限。独立main仅一次文档首提交 `74306cf`；迁移在任务分支，创建开放PR后向用户返回完整head SHA供ChatGPT Review。不扩大GitHub App权限，不自动合并。

本轮按AX-00停止，不启动AX-01/02。旧库PR55已包含新项目迁移入口且仍开放，本轮未修改旧工作区再留重复说明。按executing-plans技能派发了一次只读最终复核，同时进行本地清单/路径/秘密/字节/证据边界检查；这些不能代替用户要求的ChatGPT Review。未保存桌面状态和板卡资料缺项保持显式限制。
