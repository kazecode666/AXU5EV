# AX-02A：TTC 周期辨识与 A—B—A 对照实验任务书

> 执行对象：本地 Codex。按任务逐项实施，先写失败测试、再最小实现、验证后提交；可使用 `superpowers:executing-plans`。本轮交付离线工具与候选 ELF，硬件实验必须在 Review 后由用户本人执行。

**日期：**2026-10-30  
**仓库／事项：**`kazecode666/AXU5EV`，PR16，Issue15。继续现有分支，不新建项目或纯任务书 PR。  
**规划基点：**`3da5eee5a277288898f19dd1ef25aa84eb472ff8`。执行前只读确认实际 HEAD；已有后续相关实现应接续，不覆盖或重复。  
**目标：**用小数据量、单变量、可回退的 TTC-only 实验，区分硬件 interval 周期映射与 ISR／读取延迟的影响，为下一步平台层修正提供证据。  
**架构：**复用现有 PS-only XSA、A53 FSBL→R5_0 standalone 启动路线和 BSP；独立应用只采集定时器，不调用 Runtime。同一 ELF 下由用户分别发起 A1→B→A2，停止计时后读回原始记录，在 PC 分析。  
**技术栈：**Vitis 2026.1、当前官方 R5 GCC／TTC BSP、C、Python、现有 XSDB 会话中的显式读回工具。  
**需求依据：**PR16 研究评论 6523765948、诊断实测评论 6521574860、模型优先约束评论 6520067972，以及本任务书。执行前阅读 `AGENTS.md`、`coordination/HANDOFF.md`。本任务把研究建议转为可执行范围，不宣称 N+1 已证实。

## 1. 本轮边界与现有事实

### 已有证据

- 原 ELF P1000 的释放相位斜率约 +0.99927 tick/周期；诊断 ELF 的独立 P1000 约 +0.99779 tick/周期。两次短段记录均未违反原名义截止期，但存在累积趋势。
- 用户已取得 TTC 开始前配置：两个通道内部时钟、无预分频，periodic interval=10000，control=0x23/0x21，IER=1/0，上层时钟选择符合已核对配置。BSP 100 MHz 是换算依据，不是独立测频。
- 最新诊断实验 `phase_p1000_01` 四文件已由用户保存；板上报告数值 PASS，原始时间统计与报告一致。仍需用本地独立 reference 对其 actual 做完整数值交叉，不得只引用板上 PASS。
- **尚无证据确认物理 N/N+1 根因，也没有已验证的周期补偿。** 原完整 A4 剩余场景和完整 A5 未完成。

### 全局约束

1. **Simulink／Stateflow 是算法唯一来源。**不编辑生成 C/H/SV、不重生成模型、不修改模型参数、采样时间、PI、轨迹或接口语义；诊断程序不执行 Runtime，不替代算法验收。
2. 不改 PLL、BSP 时钟、处理器频率、O2／FP 配置、缓存和 TCM 布局策略。保持 I-cache ON、D-cache OFF；不把 TTC-only 的耗时当成 Runtime 性能。
3. 保留 `vitis_target_a53fsbl`、`vitis_postprocess`、`vitis_phase_diagnostic` 及所有原始数据，不重建或覆盖这些目录；不重跑 RTL，不修改厂商安装目录。
4. Codex 只做本地读文件、分析、测试、离线构建、普通 Git 提交／推送。**不启动或连接 hw_server，不发现目标，不操作 JTAG、UART、板卡寄存器或内存，不复位、下载、运行板卡。**有线缆或供电不等于授权。
5. 用户负责上板；ChatGPT Review；PR16 保持 Draft，Issue15 不关闭、不合并。不得声称 GitHub 评论自动启动了本地 Codex。
6. 沿用 `D:/Project/AXU5EV` 和现有分支。不额外 clone/worktree，不自动 stash/reset/clean，不覆盖用户未提交修改。无需全仓库哈希或额外资料清点。
7. 本轮只交付**辨识工具**。9999 是实验条件，不是正式修复；Match 调度仅保留为后备，不同时实现第二套后端。

## 2. 实验合同：同一 ELF，A1→B→A2

| 运行标识 | raw interval 请求值 | 实际 IRQ 样本数 | 用途 |
|---|---:|---:|---|
| A1 | 10000 | 1000 | 本轮轻载诊断基线 |
| B | 9999 | 1000 | 单变量检验计数映射 |
| A2 | 10000 | 1000 | 恢复原值并检验可重复性 |
| C（可选） | 10001 | 1000 | 只有 A—B—A 不足以辨识、再经用户确认时执行 |

- 三次使用同一 ELF、同一通道／时钟／预分频、同一采样代码和启动流程。每次重新初始化诊断状态、清待处理中断、复位计数器；只在开始前配置 raw interval，ISR 内不重置周期计数器。
- 名义目标保持 **10000 个 source ticks**；不随 raw 值改 expected、deadline 或模型。该目标用于诊断比较，不用于在 B 提前到达时立即中止采集。
- 每次由用户在 WAIT 设置参数并最后发启动命令；禁止上电自动跑 A—B—A。各次 experiment 递增，以实际启动前后值对应，不固定写死为 1/2/3。
- 本次 k=0 必须是**第一次真实 IRQ**，不是软件制造的初始帧。保存全部样本；如分析排除启动暂态，必须同时报告排除规则及含／不含的结果，不能照抄旧 P1000 的“自动排除第0帧”。
- 试验期间不打断点、单步、自动刷新或传输。可在启动两个计数器之前设置明确的取证停点，采样后才读回；真实测量窗口内被调试中断必须如实声明。
- A1 与 A2 不一致时先报告不可重复，不把 B 的变化归因于 interval。

## 3. 目录、应用与接口约定

以下是**拟新增**路径，不表示当前已经存在或构建成功。实施时只做必要增量，不搭通用测试框架。

| 文件／路径 | 职责 |
|---|---|
| `coordination/tasks/ax02a_ttc_aba_characterization.md` | 将本任务书纳入版本管理；不再重写另一份规划 |
| `firmware/r5/ax02a/ttc_characterize.h` | 独立邮箱、记录及协议合同 |
| `firmware/r5/ax02a/ttc_characterize.c` | 独立诊断入口、TTC 配置、采集、超时与清理 |
| `firmware/r5/ax02a/build_config.ttc_characterize.json` | 新构建配置示例 |
| `scripts/ax02a_build_ttc_characterize.py` | 复用可用构建辅助，离线创建诊断应用及启动检查；不重构原构建器 |
| `firmware/r5/ax02a/readback_ttc_characterize.tcl` | 仅定义被动过程；用户显式调用后保存本次记录／元数据 |
| `scripts/ax02a_analyze_ttc_characterize.py` | 单次分析与 A—B—A 联合判读 |
| `verification/ax02a/test_ttc_characterize.py` | HOST／协议／脚本故障回归 |
| `firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md` | 新增一段 GUI 停点操作；保留旧版本适用范围 |
| `coordination/reports/ax02a_r5_target_validation.md` | 更新真实证据与未完成项，不整篇重写历史 |

**隔离构建输出：**`.runtime/ax02a/vitis_ttc_characterize`，已存在则拒绝覆盖并使用明确的新候选目录。  
**应用名称：**`ax02a_ttc_characterize`。沿用既有 A53 FSBL＋R5_0 split；用新名称 `ax02a_ttc_characterize_hw` 区分回放 launch，ELF/FSBL 路径必须属于本次已验证平台。不得重建 PS 硬件架构或另做 Hello World。

**目标符号：**
- `ax02a_ttc_char_control`：独立 volatile 邮箱，不复用 `ax02a_control` 或修改现有 v2 报告。
- `ax02a_ttc_char_samples`：全局固定容量数组，禁止放在栈上。
- `ax02a_ttc_char_prestart()`：计数器尚未启动的可选取证停点。
- `ax02a_ttc_char_done()`：计数器和中断已停止、结果已发布的完成停点。

邮箱至少表达：协议 magic/version、状态 WAIT/RUNNING/COMPLETE/ERROR、command、experiment、请求／实际 raw interval、名义 period=10000、请求／完成样本数、BSP 时钟、采样错误及超时原因。具体整数布局在头文件、解码器和测试中一次性定义；不要将“采集完成”命名为“周期 PASS”。

**记录固定为小端 4×uint32，共16字节：**`sequence, f_before, p_count, f_after`。静态断言宽度；1000条=16000B。报告元数据独立保存在 `run.json`，与旧 P1000 的8×uint64时间格式严格分开，不允许旧解码器误读。

读取数组地址以本 ELF 的符号／map 为准，不要求用户猜结构体地址。新增全局缓冲及栈堆必须有实际链接布局检查。

## 4. 任务 T1：先闭合最新诊断版的数值证据

**输入：**用户实际使用的 `.runtime/ax02a/board_manual/phase_p1000_01/`（若用户已改用 `_02` 等目录，按真实记录定位，禁止拼凑不同实验）；配套 `.runtime/ax02a/replay/p1000/reference.bin`、`metadata.json`；已保存的开始前配置 JSON。

- [ ] 只读核对 output=328000B、timing=64000B、report_v2=2400B 和 run.json 的场景、模式、实验号、完整完成／中断声明。区分旧 exp2 和此次新诊断 ELF experiment=1，不能跨实验代替。
- [ ] 使用本地配套 reference 独立复算最新 actual，并与板上报告核对41字段结果、时间及相位摘要。沿用现有比较规则，在全新分析目录输出。
- [ ] 分开记录 `numeric`、`deadline_sequence`、`period_consistency`、`crosscheck_consistent`。预期趋势仍在时，整个周期不接受与“PC/C一致”可以同时成立，不把非零分析退出码当成构建失败。
- [ ] 保存必要精简证据和来源说明；原始二进制留在 `.runtime`，不覆盖旧报告，不伪造缺失参考。缺数据时明确列出缺口，不用板上自报 PASS 替代独立比较。
- [ ] 先独立提交该任务。验收：本次数字有明确来源，剩余未验证项准确；不要求为这一步给开发板供电。

## 5. 任务 T2：先定义分析与故障测试，再实现小型采集程序

### 5.1 可独立验证的分析接口

`ax02a_analyze_ttc_characterize.py` 提供 `analyze_run(samples_path, run_path, output_dir)` 和 `compare_aba(a1_dir, b_dir, a2_dir, output_dir)`；支持命令行 `run` 与 `aba` 两个子命令。目录已存在时拒绝覆盖。

- [ ] 先写合成数据测试：实际周期=raw 与实际周期=raw+1；固定ISR延迟；固定周期但ISR延迟线性增加；随机抖动；负相位；A1/A2不一致。
- [ ] 再覆盖长度／协议错误、参数与读回值不符、缺记录、重复序号、疑似合并IRQ、过晚采样、读取窗口跨回零、uint32回绕和人为中断。坏数据不得被过滤成根因已确认。
- [ ] 先执行测试记录失败，再最小实现并复测。分开输出“可用样本”“采集有效”“假设是否相容”，不以一个模糊 PASS 代替。

### 5.2 采样和推断方法

每次真实 IRQ 中按固定顺序读 `F_before → P → F_after`，只记录整数和必要状态；禁止浮点、printf、文件传输、内存分配或模型调用。只使用本平台已核对的 MMIO 访问和排序方法；中断应答由确定的一处负责，不重复读 clear-on-read 状态来“观察”。

对于两通道同源、同分频，且读窗口没有回绕／跨回零的样本，可用 `[F_before−P, F_after−P]` 估计对应回零时刻范围。**这是有同步与访问延迟限制的估计，不是原子采样、精确边沿或统计置信区间。**

- [ ] 保留 F 两侧读数与窗口宽度，分别统计：ISR采样相位、P的趋势、回零时刻估计的趋势和估计宽度。
- [ ] 推断事件周期时不得预先硬塞 raw 或 raw+1 再用该结果证明自己的假设；先从数据估计事件周期，再与两个候选解释比较。
- [ ] 本轮单次采集时长有上限并短于32位回绕期；检测回绕则拒绝本轮，不引入复杂多圈扩展。过晚、跨回零、疑似漏事件及不可辨样本必须留痕；若四字段不足以判断，报告歧义，不宣称已可靠识别所有异常。
- [ ] 软件序号连续仅说明回调记录连续，不能独自证明硬件中断没有被合并。结合事件间隔、P与读窗口做异常判读；无法证明时保留 UNKNOWN。
- [ ] 第一条是真实IRQ。给出包含全部样本的结果；剔除启动暂态的诊断必须并列报告剔除规则和结果，不隐式删掉反例。
- [ ] OLS斜率只作为摘要，必须同时查看窗口、残差、首尾及A1/A2重复性。不机械套用旧P1000阈值；阈值依据写清，分辨率不足时输出 INCONCLUSIVE。

### 5.3 固件生命周期与失败处理

- [ ] 只接受1000个样本及raw∈{9999,10000,10001}；名义比较周期固定10000，不给用户任意改频入口。C条件可编译支持，但本轮指南默认不执行。
- [ ] 同一ELF支持逐次运行：WAIT配置→最后写command→复制本次参数→清理待处理状态→采集→停止两个计数器及采样中断→发布结果→完成断点；返回WAIT不自动发起下一次。
- [ ] 开始前读取实际clock/control/interval/IER；两个通道必须同源、未分频并符合预期。BSP频率和实际寄存器分开保存，不把配置称为测频。
- [ ] 第1000条之后不得越界写数组。无IRQ、停止条件未达、参数错误须有明确结果和统一清理路径，不能无限等待或静默重试。
- [ ] 设置基于自由计数器、独立于IRQ计数进展的有界超时；计算预算避免整数溢出，检查计数器可用，记录触发原因。允许观察早到／晚到，不移植原runner的 `released<expected` 即停止规则；这不是放宽正式控制验收。
- [ ] 新应用不链接或调用生成Runtime；不修改原 `timing.c` 的生产周期映射，不改原ISR以伪造A/B结果。保留现有P1000主线。
- [ ] 采用必要HOST测试／最小MMIO桩验证参数、边界、完成／超时发布，不能把合成事件当板上中断证据。完成后提交协议、分析器和诊断代码。

## 6. 任务 T3：隔离构建、被动读回与新手GUI交接

- [ ] 离线构建新应用，复用已通过的XSA、A53 FSBL目标和R5域；输出完整ELF/map及精简构建证据。确认ARM32/R5、入口/栈堆/记录数组布局和launch所指文件，不从编译成功推导板上成功。
- [ ] 新构建器只做必要复用。`--check-startup` 为纯文件操作，普通Python运行不得创建硬件连接；诊断应用路径不能误套旧的 `ax02a_replay`。
- [ ] 相对配置路径按仓库根解析而不是终端当前目录；从项目根和新workspace两处使用绝对config执行检查，得到相同文件路径。加回归，避免此前 `.runtime/...` 被拼接两次的问题；不为此重构旧工具。
- [ ] `readback_ttc_characterize.tcl` 被source时只定义过程。用户显式调用后才核对当前暂停R5、诊断邮箱magic/version、本次experiment、actual raw、完成数和中断声明，读小记录并保存run.json。
- [ ] 每次只读已完成记录，遇到已有目录拒绝覆盖；失败记录保留状态且不能当完整1000条。脚本不连接、不选择/重置目标、不改寄存器、不恢复运行，不用读取中断状态寄存器判断完成。
- [ ] run.json至少记录：case_id、before/after experiment、requested/readback raw、nominal10000、requested/completed样本、状态/错误、实际配置、时钟依据、ELF/工作空间来源、调试中断声明、运行条件。对A1/B/A2串错、raw不符及不同候选的文件混用必须拒绝。
- [ ] GUI说明从开始菜单／Set Workspace开始，不要求用户命令行启动Vitis。明确本次platform、应用、launch、main/WAIT、可选prestart、done停点和文件路径；读回/离线分析命令分别标注XSDB与普通终端，命令完整单行。
- [ ] 指南把A1/B/A2写成三个用户显式步骤；每次只改变raw，供电/会话不变，禁止自动三连跑。默认只读约16000B记录及少量元数据，不要求参考文件或21MB输出。
- [ ] 本机执行相关旧回归及新增测试，报告实际通过／失败／未运行项，不虚报全部通过。提交实现SHA、构建日志、GUI指南和已知限制，**停在待Review/待用户上板**。

建议最低离线验证命令（从项目根执行；新增命令在实现后才可用）：

```text
python -m unittest discover -s verification/ax02a -p "test_ttc_characterize.py" -v
python -m unittest discover -s verification/ax02a -p "test_*.py" -v
```

若某旧测试依赖缺失本地数据，应明确列为未执行及原因，不伪造替代样本。新构建／检查命令由Codex按实际工具产物验证后写入指南，不让用户猜。

## 7. 任务 T4：用户上板及判读门槛（本轮Codex不得代做）

Review通过后，用户加载同一诊断ELF，分别采A1、B、A2并保存到新的独立目录；每次完成再进行下一次。命名建议 `ttc_aba_01/A1`、`B`、`A2`，不得将这些数据送入旧P1000比较器。

| 候选解释 | raw10000相对名义周期的预测斜率 | raw9999 | 可选raw10001 |
|---|---:|---:|---:|
| 实际事件周期=raw+1 | +1 tick/周期 | 约0 | +2 |
| 实际事件周期=raw | 约0 | −1 | +1 |

以上仅为假设预测。需结合回零事件估计、P趋势、读窗口和A1/A2一致性，不凭“B看起来好了”确认N+1。

判读分支：
- A1/A2重复、估计事件周期支持raw+1、ISR延迟没有相应线性增长：支持下一轮最小映射修正，仍只限已测试平台/模式。
- 估计回零周期无相应偏差，但ISR采样延迟增长：转查中断/总线/采样路径，不减interval抵消它。
- TTC-only不重现：说明负载条件可能重要；下一步设计带Runtime的最小对照，仍不修改生成算法。
- 数据矛盾、漏事件或读取窗口不能区分：结论INCONCLUSIVE；提出一个最小补证动作，不反复重复同一实验。必要时才讨论硬件波形/独立测量。

**即使采集成功，本诊断也不得生成 BOARD_NUMERICAL_PASS、A4_PASS、A5_PASS 或 WCET 结论。**

## 8. 后续修复门禁：本次不得抢先实施

硬件数据经Review后，才选择：

- **优先：**在自有平台适配层建立已验证的 `logical_period_ticks → hardware_interval` 转换，分别记录请求值、寄存器值和实际验证结论。同步相关检查，保留名义100µs及原deadline，不手改生成C或厂商安装目录。
- **备选：**TTC自由计数＋绝对Match。须另行评审过期目标、回绕、漏拍；不照搬迟到后 `now+period` 的静默重排。当前不实现，不引入RTOS。

正式修正后先重跑P1000，数值、原始ticks和小报告交叉；通过后才适当延长并补齐完整A4/A5。新ELF不能继承旧性能结论。最终流程须能从模型重新生成并直接构建，所有平台修正来自版本化源码。

## 9. 本轮完成标准与交付顺序

建议按三个有实际成果的提交交付：①最新诊断数据交叉结论；②辨识代码／协议／分析／测试；③真实离线构建与GUI交接。不要提交一份任务书后就声称开发完成。

本轮离线完成必须同时满足：
- [ ] 最新P1000实际输出有独立参考比较，或缺失条件被准确记录。
- [ ] 合成raw/raw+1、延迟增长及异常对照能给出不同结论；不会把软件序号连续误称没有漏IRQ。
- [ ] 记录16B、1000条16000B的合同及新协议测试通过，旧P1000/v2不被破坏。
- [ ] 同一诊断ELF支持用户逐次A—B—A，数据/实际raw/实验身份可追溯。
- [ ] 新目标实际编译/链接与纯文件启动检查通过；没有改生成算法或原工作空间。
- [ ] 小型被动读回工具及GUI指南可交付，失败停止点清楚。
- [ ] 状态明确标为 `OFFLINE_READY_FOR_REVIEW`；A—B—A板验、物理根因和正式周期修复仍为NOT_RUN/UNCONFIRMED。

不要求此轮在没有新板上数据时闭合物理根因。JTAG提速、网络/USB/DMA、PL测量电路和控制性能优化不在本轮实施范围。

## 10. 参考资料与证据边界

- 项目研究与设计依据：[PR16 评论6523765948](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6523765948)。本任务沿用其中研究结果，不新增“官方已证实减一”的结论。
- 最新四文件实测回执：[评论6521574860](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6521574860)；模型优先约束：[评论6520067972](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6520067972)。
- [AMD TTC API](https://xilinx.github.io/embeddedsw.github.io/ttcps/doc/html/api/group__ttcps.html)：核对实际安装的MPSoC/R5编译分支，不混用旧Zynq-7000的16位条件。
- [RTEMS ZynqMP RPU TTC实现](https://lists.rtems.org/pipermail/vc/2023-November/040043.html)：只作绝对Match备选参考，本轮不移植RTOS或迟到重排策略。
- [CTU实时系统中断延迟实验](https://psr.pages.fel.cvut.cz/psr/cviceni/06-latency/)：借鉴ISR读取周期计数器的方法，不复制其平台地址和计数宽度。
- [Alonso等，Electronics 2024,13(9),1626](https://www.mdpi.com/2079-9292/13/9/1626)：支持区分硬件事件与软件响应，不是本平台N+1勘误。

**执行口令：先完成T1—T3并提交供Review；T4由用户上板；第8节所述正式修复必须在真实对照结果确认后另行推进。**
