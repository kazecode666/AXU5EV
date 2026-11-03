# 下一实施任务：ETH-02 — 以太网接入 R5 Runtime 实验

PR17 已合并。下一实现 PR 预计为 PR18，实际编号由 GitHub 分配；本评论作为 Codex 交接，不重开 PR17、不另建纯任务书 PR。

## 目标和方案

把已经验证的两部分接起来：PR16 的 R5 100µs Runtime 回放 + PR17 的 PS GEM3/JL2121/lwIP TCP。用户以后通过以太网上传真实实验输入、发起一次回放、下载结果并调用原分析脚本。Simulink 仍是控制算法来源，MATLAB 提供统一实验入口；Vitis 负责平台集成与构建。

本轮选“上传 → 暂停网络收发并执行 → 恢复网络并导出”，网线始终保持连接。计划内重新建立下载连接属于此流程；持续在线遥测、网络与控制并行调度、异常断线自动恢复留到以后。先完成这条日常实验路径，再进入 5EV PL 电流核及 PS—PL 集成。

## 工作边界

- 在 `D:/Project/AXU5EV` 从包含 PR17 合并的当前 main 开正常实现分支，建议 `codex/eth02-runtime-ethernet`。保留本地修改；不另 clone/worktree、不强制回退或清理。
- 保留 R1 和 ETH01 r3 工作区、ELF、原始数据。新产物集中 `.runtime/ethernet/eth02/`。算法继续使用已验证的 Simulink 生成 Runtime；不手改生成 C/SV，不改 PI、轨迹、对齐、类型或参数。现成输入/参考和 metadata 直接复用。
- 继续 R5_0 standalone，A53 仅运行匹配的新 FSBL；复用已跑通的 JL2121 修正和网络参数。新 XSA 同时启用 GEM3 与 TTC0。
- 只做本次必要构建、现有启动检查和正常实验验证。不增加冒烟/红绿/压力/异常注入套件、防御性框架、文件哈希清单；交接不列提交 SHA。不重跑旧 RTL、TTC ABA 或重新验收原 ETH01 测试模式。
- Codex 自动执行范围是离线代码、构建和本地分析；开发板连接、下载、复位、运行及面向板卡的客户端调用仍由用户手动执行。固定接线，功率级保持断开。遇到真实问题再针对处理。

## Task 1 — 合并最小平台与内存布局

建立独立 Runtime+Ethernet 应用，复用已有构建入口的方法与平台代码。

两个现有实现的具体合并点已核对：
1. `hardware/axu5ev/eth01_ps_ethernet.tcl` 当前关闭 TTC0；新平台需同时保留原 R1 的 TTC0 配置与 ETH01 的 GEM3/MDIO。保留 TTC 原 100MHz、raw interval=9999、logical period=10000 的映射。
2. ETH01 的 32MiB 测试数组占 `0x10000000..0x11ffffff`，与 AX02A 的 input/output 区重合。新应用移除这个测试用途，改为真实实验的数据对象；原 ETH01 工程保持原样。
3. 优先沿用 AX02A 的 input `0x10000000`、output `0x11000000`、descriptor `0x12f00000`、timing `0x13000000`、reference `0x14000000`、report `0x16000000`。用实际 linker/map 确认程序、栈、堆和 GEM 描述符/缓冲区位于其他区域。
4. 沿用 I-cache ON / D-cache OFF。网络时间服务继续用原 PMU 路径，Runtime 使用 TTC；统一 GIC 初始化/中断注册，避免一方初始化覆盖另一方设置。

交付：新的 XSA、匹配 FSBL、R5 ELF/map、build 配置和明确的 workspace/launch；原两套工程仍可独立使用。

## Task 2 — 将网络协议对接真实实验数据

复用 ETH01 的 TCP 字节流、分块和 CRC，只新增本轮必需的操作：上传指定数据对象、设置场景、启动、查询结果、按对象下载。对象限 input/reference/descriptor 和 output/timing/report/run信息，不开发任意地址访问工具。

- 上传 `input.bin`、`reference.bin`、32字节描述符；PC 读取已有 metadata 设置场景/帧数，保持 20输入/41输出、原 little-endian float64 及时间记录格式。
- 场景支持 `current_motion`（64536帧）与 `current_alignment_reset`（43100帧），本轮使用 mode1、100µs。
- 文件长度按场景与帧数确定，沿用已有 CRC 和传输完整性处理。每份对象接收完成再提交；三份输入齐备后进入 READY。
- 启动请求只设置待执行状态并返回实验号，回执发送及必要连接收尾完成后由主循环调用 Runtime。长回放不在 lwIP 接收回调内执行。
- 实验号/场景/完整输入标记和冻结的输出属于实验状态，独立于 TCP 会话。上传连接结束、下载连接建立时保留这些状态；现有 `EthSessionReset()` 只作用于传输队列与连接相关状态。

交付：少量明确的消息定义、文件对象接口、主机上传下载逻辑。原 ETH01 v1 的 standalone demo 保留其行为；新增消息在文档中列清即可。

## Task 3 — 完成“通信—测量—导出”切换

顺序固定：

`READY → 启动回执/连接收尾 → 停网络收发 → TTC准备和快照 → RUNNING → 停TTC → 原板上后处理 → 冻结结果 → 恢复网络 → RESULT_READY`

- 用本机 AMD 驱动完成 GEM 收发/DMA与相应中断的停启，操作发生在测量窗口之外；TTC中断在测量中正常工作。复用 BSP 能力，不另造驱动。核对现有 lwIP 前台定时维护在恢复阶段的处理。
- 复用原 `ax02a_replay`、计时器映射和 `ax02a_postprocess`。每次实验仅初始化 Runtime 一次，保持原时序与数值边界。除整合确需的薄适配外不重构这些实现。
- 计时前保存 TTC 配置与快照；结束后保存实际状态、完成帧数和计时数据。成功或原运行错误返回后都能回到数据服务阶段，让电脑读取已有现场。
- 完成后 R5 保持运行，提供结果下载，不要求用户停在 `ax02a_result_ready` 断点；首次调试仍可用 JTAG 下载和定位。
- 新固件身份与传输方式如实写入 run.json；原 R1 计时映射验证继续使用。若分析器需要识别新应用标识，仅增加明确的元数据兼容，保留原数值容差、周期/截止期/相位判据。

交付：一条能够从接收输入连续走到结果下载的应用流程。这里的网络停启是测量流程本身，不扩展热插拔、keepalive或持续在线遥测。

## Task 4 — MATLAB 日常入口与既有分析衔接

提供一个 MATLAB 实验入口和对应 Python 客户端，最短路径为“选择已有场景 → 上传 → 明确启动一次 → 等应用结束 → 计划内重连下载 → 自动分析”。不在 model load、代码生成或 import 时连接板卡。

- 建议新增 `scripts/eth02_run.py`、`simulation/ethernet/RUN_ETH02.m`；数据打包/收发逻辑集中在 Python，MATLAB 负责显式调用和显示结果，避免维护两套协议。
- 导出同次的 `run.json`、`output.bin`、`timing.bin`、`report_v2.bin`。run 中保存本次实验号、场景、帧数、状态、实际计时配置、ETH02应用身份、以太网传输来源和测量条件；必要的 pre-begin 配置随同保存。
- 直接调用 `ax02a_compare_replay.py` 与 `ax02a_post_report.py crosscheck`，优先原样复用。客户端输出上传/下载耗时和进度，以及数值比较、时序、crosscheck的最终结果。
- 复用现有 Runtime 模型和生成算法；本轮不重新搭完整实机模型、不把 lwIP 放进控制 step、不增加上位机GUI/External Mode。统一 MATLAB 入口服务后续模型化实验。

交付：用户可复制执行的实际命令、唯一操作指南、结果目录；命令与路径以实际实现为准，不留空泛示例。

## Task 5 — 最少必要验证与交接

Codex先完成上述离线实现和目标构建，运行已有启动文件检查，将可执行指南和改动推送新 Draft PR，交 ChatGPT Review。只保留一份简短实施/结果说明，不新增测试套件。

Review通过后由用户在新应用手动完成两次正常集成实验：
1. `current_motion`：真实输入通过以太网上传，100µs回放，网络导出并自动分析。
2. `current_alignment_reset`：同一应用再执行此场景，验证第二次调用和结果切换。

两次都使用已有输入和参考，结果保存到新的 ETH02 目录。这是新集成应用的板测，旧 R1 / ETH01 结果原样保留。

验收只看必要结果：全部帧完成、41字段原容差比较通过、原截止期/序号/相位检查与板报crosscheck通过，输出本次最大响应/最小slack、上传下载耗时。时间统计按新实测值记录，不要求与R1逐项完全相同。不另加P1000、异常断线、压力测试或吞吐优化门槛。

用户可运行同一候选的第二次场景而无需手动写XSDB内存；两场景结果都能经原分析工具得到结论，就是本PR完成标准。

## 文件安排和交付

建议在 `firmware/r5/ethernet_runtime/` 放新应用/配置，在 `hardware/axu5ev/` 增加新的集成平台入口；共享通信和算法代码优先复用原文件，不整套复制两套main。将本任务随实现保存为 `coordination/tasks/eth02_runtime_ethernet.md`，更新当前 HANDOFF 即可。

最终返回：改了什么、必要构建/检查结果、用户打开的 workspace/launch、先执行哪条场景命令，以及尚需用户操作的一步。不附提交哈希或全文件清单。上板由用户完成，合并由用户决定，Issue15保留。

完成ETH02后暂停网络扩展，进入 AX-02B 的5EV PL电流核落地，再推进真实PS—PL协同。
