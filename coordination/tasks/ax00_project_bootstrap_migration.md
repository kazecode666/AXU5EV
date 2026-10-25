# AX-00 — AXU5EV建仓、精选迁移与独立基线恢复任务书

> 本地Codex按检查点连续执行；正常检查点不逐项求许可，只有取得证据才勾选。先安全结束旧全HDL优化的新候选启动，保留所有工作；不自动中止正在写文件的工具、不删除实验。使用适用的superpowers执行计划技能。

**Goal:** 在用户已经建立的AXU5EV本地目录创建独立GitHub项目，迁入可追溯的模型/电流RTL/必要资料，恢复不依赖旧工程路径的现有仿真基线，并建立ChatGPT—Codex—GitHub协作入口。

**Architecture:** R5F负责外环、原对齐和上层管理，PL负责电流控制及实时接口。旧库作为只读来源；独立新Git历史，原始基线与活动副本分开，精选复制而非整库搬家。此次只完成迁移，不冒充R5固件和5EV部署。

**Tech Stack:** 当前已装Git/gh、MATLAB/Simulink及原项目工具；本机核对真实版本，不自动升级/重装。新仓库`kazecode666/AXU5EV`默认private。

**Spec:** 用户已经选择Cortex-R5F并新建本地AXU5EV目录；[架构](../../docs/ARCHITECTURE.md)、[来源清单](../../docs/MIGRATION_SOURCES.md)、[协作规则](../../AGENTS.md)共同生效。日期2026-10-25。PR54的全三环HDL任务被替代，不再作为AXU5EV必做验收。

## Global Constraints

- 旧root `D:/Project/FPGA_XC7A200T`只读保留；新root必须先从用户已建目录/当前工作区确认。`D:/Project/AXU5EV`仅候选，不当已确认路径；不能在另一位置再建同名工程或将新目录嵌进旧Git树。
- 不复制旧`.git`，不改旧origin，不fork或镜像整个旧仓库；新项目独立。不得自动stash/reset/clean/强推/覆盖冲突文件，不自动保存未保存模型、关闭全部窗口或用GUI代替可用接口。
- 用户最新磁盘源、未提交文件、未保存Dirty状态分别记录。未保存内容不声称已快照；原字节备份和活动修改分开，已接受远端源不能覆盖用户文件。
- 建仓前核对账号、目录、现有remote及文件。不得打印/索要token，迁移不带旧MCP、.codex秘密或全局工具设置。仓库默认private，若已存在不要更改可见性。
- 保留现有PI/位置P、原对齐五态/计数、100us/1ms/10ms/1us时基、50us应用及单次平均死区；不为迁移改算法。
- 不将Artix-7 part/XDC/时序结果伪装成AXU5EV。板卡完整型号/修订/芯片封装速度等级/时钟/接口以已有实物资料核实；缺项标未确认，不猜引脚。
- 原算法从模型生成，不手改生成SV/C。所有导入旧实验有独立状态和来源，不借用未完成M4候选的PASS。
- 保持正常外部.m初始化入口和模型局部布局；中文注释必要、简短。不要全根目录genpath；历史/基线的同名SLX不可参与活动解析。
- 精选证据，不搬完整数百万行生成候选/仿真缓存。不重新全跑M0、StudyL1、Step6/7、旧M4；不烧录、上电或自动合并。

## Review Focus

1. 路径推测造成错误git init/origin：A/B实测root并断言source与target不同、互不嵌套。
2. 已验收源、LOCAL_DIRTY、未验收候选混成一个模型：A/C逐项身份、保留/采用理由及哈希验证。
3. 新工程暗中从旧MATLAB路径解析依赖：D独立进程隔离来源、查询实际FileName/which及回调。
4. 私有资料或授权配置误入远端：B/C逐项暂存审查，文献/大包本地索引并记录许可。
5. 只创建文档却称迁移完成：E要求新仓库实际模型/依赖/运行记录与开放迁移PR；FAIL和NOT_RUN保留。

## A — 安全收口与迁移盘点

- [ ] 确认旧Codex任务不再启动全HDL取模/流水线新候选。正在运行的工具在不损坏文件的边界收口；记录未完成项，不要求旧M4先通过。
- [ ] 记录两个root及其Git顶层/HEAD/status/remotes、正在加载模型的绝对路径和Dirty。新目录已有文件先清单/哈希，不覆盖；旧磁盘字节及未提交patch保存到新的忽略运行目录，敏感项不入库。
- [ ] 从PR53合并`4470e357cb91778072036475baa667c839dc12c6`验证八份source_snapshot及p3清单；同时读取最新本地修改。布局变化、算法变化、未验收实验分别分类，不能只按文件日期选生产版。
- [ ] 枚举依赖和资料：现有主SLX/init/FOC、原完整MIL/引用模型/DSP、StudyL1、XSI、板卡/电机/驱动/ADC/编码器和论文索引。不让用户重复提供已经存在的接口信息。
- [ ] 创建`coordination/reports/ax00_preflight.json`和`migration_inventory.csv`：source_repo/commit_or_LOCAL_DIRTY/path/sha256、classification、目标路径、copy/index/local_only/exclude、原因和公开许可。原始未保存状态写UNSAVED_NOT_CAPTURED。

## B — 新仓库和协作骨架

- [ ] 从本初始化包将README、AGENTS、docs、coordination、.gitignore/.gitattributes、PR模板按原相对路径复制到新root。只新增；已有同名文件比较再合并，不强制覆盖。本包不含任何实际SLX或RTL。
- [ ] 核对`gh auth status`、`gh api user --jq .login`，应为`kazecode666`；核对`gh repo view kazecode666/AXU5EV`。不能把单独404当确定不存在，先确保账号/登录有效。已有非空仓库先读取，不能覆盖或重置。
- [ ] 新目录不是Git仓库且不位于其他Git树内时，才执行`git init -b main`。已有独立Git时保留历史与配置。检查身份配置，不替用户更改全局用户名/邮箱。
- [ ] 全新空库只允许一次文档初始化提交到main：明确逐路径add骨架，不`git add .`。核对暂存没有模型、密钥、大包或用户无关文件。
- [ ] 仅在确认新repo不存在、本地首提交与root正确、无冲突origin后，执行以下建仓流程；不使用`--clone`、不在远端另生成README，不复制旧Git历史：

```powershell
# 当前目录必须已确认是用户的AXU5EV根目录，已有文档首提交。
gh repo create kazecode666/AXU5EV --private --source . --remote origin --push --description "Simulink-led PMLSM research: Cortex-R5F motion control and PL current control"
# 每个命令检查退出码；创建/推送失败就记录实际阶段，不重复创建或强推。
gh repo view kazecode666/AXU5EV --json nameWithOwner,url,visibility,defaultBranchRef
git remote -v
git rev-parse --show-toplevel
```

- [ ] 若CLI未安装/未登录/无建仓权限，保留本地工作并标REMOTE_BLOCKED；用户在GitHub建立空AXU5EV后可继续，不索要token、不偷偷改用公开仓库。当前ChatGPT连接缺建仓动作，不代表本机gh一定可用。
- [ ] 创建`codex/ax00-migration`工作分支，后续资产/实现全部进入该分支。检查新私有repo已纳入用户的ChatGPT/Codex GitHub连接授权；CLI可访问不等于ChatGPT连接已获选仓权限。需要用户操作时给出准确阻塞，不自动扩大App权限。

官方CLI依据：https://cli.github.com/manual/gh_repo_create 。只采用本机实际可用命令；不把此文本示例当执行记录。

## C — 精选复制与路径迁移

- [ ] 八份源及identity不改字节复制至`baselines/pr53_p3/source/`；p3配置和精简已验收证据分别放同目录`codegen/`和`evidence/`，原始SHA必须相等。
- [ ] 按原manifest完整复制`generated/m3_foc/`为`generated/legacy_m3_p3/`，包含SV/TB/data和合同。验证每个载荷哈希；记录旧Artix属性，不用字符串替换把part伪装为5EV。可移植索引另建，原清单不改。
- [ ] 在`simulink模型/`建立活动副本，初始以已验收基线为算法锚点；合入最新本地合理布局/明确非算法变更时保留对照和采纳依据。未验收全HDL三环文件放独立实验/本地快照，不能取代活动浮点/FOC。
- [ ] 活动init、三环整定、点位/S曲线、类型与初始化检查函数一起迁移。初始化入口文件名先不变；新增`setup_AXU5EV.m`仅管理本项目路径，不clear/close all、不调用旧全局初始化、不自动生成/综合。
- [ ] 精选原MIL/ControlCore/DSP及必要依赖到`references/legacy/`，保持可追溯、不要求本轮在新平台执行旧DSP硬件块。StudyL1取原速度PI语义、浮点模型/相关测试，RTL只按需参考；无关学习缓存排除。
- [ ] 根据真实依赖精选构建/位比较/XSI工具。旧工具路径、manifest位置及临时目录在活动副本中做最小可重现调整；冻结原件不动。不要递归复制所有`scripts`或整个`docs/reports`。
- [ ] 整理`references/INDEX.csv`和`hardware/axu5ev/BOARD_INVENTORY.md`：材料名称、来源、版本、用途、许可、实际存放位置及sha。已有接口资料优先。整本学位论文/厂商资料仅在许可或已有明确授权范围内入库，否则本地`references/local_only/`加索引；不因private就免去检查。
- [ ] `.gitattributes`确保冻结源和生成文件按原字节保存；在暂存Git blob上再核对sha，不只检查工作目录。新增活动文本可规范换行，不能通过改manifest隐藏字节变化。
- [ ] 迁移后清单补`dest_sha256/changed_reason/verification/status`和排除清单。不得缺文件就悄悄改回旧绝对路径；真正缺失记录BLOCKED，不造替代参数。

## D — 新路径独立性与最小复验

- [ ] 独立MATLAB进程执行，不触碰用户窗口；记录实际版本/许可。仅添加新活动目录，排除旧工程和历史同名模型路径；不用重命名/搬走旧目录做验证。
- [ ] 检查路径设置、回调、数据字典、MAT、引用模型、Library及脚本的绝对路径；用实际FileName、which -all和运行加载清单证明全部运行依赖位于新root或正常工具安装目录。文档中的旧源地址允许保留，运行依赖不允许。
- [ ] 在同一工具版本、同一工况下，将冻结来源副本和新活动副本分别在隔离进程执行。至少比较原float模式、固定FOC模式的一组1.2s标准工况；标准参数由测试显式覆盖，用户10mm/5s/V10/A100默认不改。
- [ ] 迁移只改变路径/配置时，对相同时间向量下的位置/速度/dq电流、参考、duty、使能与状态期望相同；出现差异先定位路径/来源，不调PI或放宽窗口。不同工具版本导致差异单列，不能声称零差。
- [ ] 补一组同一次Run到位后接收至少两个新目标的短连续点位测试，及原对齐模块的Start/Reset/计数/偏置单元对照。不要压缩原对齐计数来假装完成物理对齐；完整4.2s物理过程本轮可引用原证据而明确NOT_RERUN。
- [ ] p3只做清单/依赖完整性和可获得的短RTL smoke；工具/许可可用则复用17帧位/状态检查，未执行写NOT_RUN。不为此再跑全历史RTL/OOC，也不将旧Artix综合算作5EV结果。
- [ ] 产出`coordination/reports/ax00_migration_report.md`及精简CSV/JSON；大波形/日志只在.runtime。源/目标用户已有文件提交前后保护检查均保留。

## E — 新仓库PR与三方重新接通

- [ ] 更新README/HANDOFF：实际repo/root、已迁资产与未完成、下一任务入口；骨架中的待建仓文字仅在真实成功后更新。
- [ ] 任务分支显式暂存已审查资产/脚本/索引/报告，进行秘密与大文件检查，推送`codex/ax00-migration`。在`kazecode666/AXU5EV`创建开放迁移PR，不假设必然编号1，不自动合并。
- [ ] 返回新repo URL、PR URL、精确head SHA、源清单和复验摘要。之后ChatGPT使用新repo读取与Review；若连接未授权明确说明，需要用户将新repo加入既有连接选仓范围。
- [ ] 旧库只留下新项目迁移入口/旧M4已替代的说明，不删除旧任务、分支或报告，不自动archive旧repo。新项目所有后续实现留新库。
- [ ] AX-00终点是可独立打开/运行的迁移基线与来源记录，不要求新增R5 C代码/AXI/5EV实现/实机。只有通过的层次写PASS；实际远端未建或依赖缺失则部分交付并说明。

## 后续，不在本轮偷偷开展

AX-01从保留的外环/原对齐生成C并做SIL，定义PS—PL数据与事件；AX-02以核实后的5EV器件实现电流核与接口、做混合闭环，再测R5时间；AX-03按已有硬件资料集成ADC/位置/PWM/保护。Simulink里SIL运行不是ARM实测。所有硬件下载/上电另行明确授权。
