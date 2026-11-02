# AX-02A两完整场景真实板测结果与Issue15验收审计

日期2026-11-02；kazecode666/AXU5EV、PR16、codex/ax02a-r5-target。alignment的原analysis/crosscheck均不存在，本轮按FULL_SCENE_RUN_ZH.md第3节创建并正式执行ax02a_compare_replay.py及ax02a_post_report.py crosscheck，两条exit0，PASS且consistent=true。motion只读复核已有PASS报告，不重跑/覆盖。

两run分别为current_motion/64536/experiment1(before0)、current_alignment_reset/43100/experiment2(before1)，均mode1、state3/status0、未中断、全帧完成；同一R1候选0x52313031/version1/ELF来源，raw9999/logical10000。长度分别21167808/4130304/2400B、14136800/2758400/2400B。snapshot有效，两个100MHz通道及base/clock/control/IER符合已通过配置，alignment pre-begin全部字段与motion及P1000基线一致（上游0/16779778/80896），无原始数据改写。配置相容不等于独立测频。

证据见 [motion](../../verification/ax02a/runtime_r1_motion_01/evidence.json) 与 [alignment/reset](../../verification/ax02a/runtime_r1_alignment_reset_01/evidence.json)，含完整41字段差异、事件、分组时间、run和pre-begin。大型原始二进制留原路径。

## 全样本时间（µs，帧号从0开始）

| 场景 | 指标 | 平均 | P99 | 最小 | 最大 | 最坏帧 |
|---|---|---:|---:|---:|---:|---:|
| motion | runtime_us | 25.053139 | 37.46 | 19.31 | 38.74 | 27899 |
| motion | task_us | 40.105530 | 52.53 | 34.05 | 54.42 | 55499 |
| motion | response_us | 46.329311 | 58.82 | 40.10 | 60.82 | 57339 |
| motion | jitter_us | 6.223781 | 6.82 | 3.22 | 6.94 | 58179 |
| motion | slack_us | 53.670689 | 58.89 | 39.18 | 59.90 | 57339 |
| alignment_reset | runtime_us | 12.705867 | 14.08 | 11.69 | 17.43 | 42099 |
| alignment_reset | task_us | 27.700950 | 29.47 | 26.39 | 32.33 | 42099 |
| alignment_reset | response_us | 33.903643 | 35.75 | 32.60 | 38.39 | 42099 |
| alignment_reset | jitter_us | 6.202693 | 6.79 | 2.59 | 6.92 | 38687 |
| alignment_reset | slack_us | 66.096357 | 67.02 | 61.61 | 67.40 | 42099 |

slack最坏取最小值，其他指标取最大值；P99为Python原ceil算法，C报告P99仍NOT_COMPUTED。最坏帧并列时沿用现有比较器选择，不改统计规则。首帧保留在全样本/分组统计中。

## 各路径样本数及最坏帧

下列帧顺序为runtime/task/response/jitter/slack。组可重叠，不能把事件组再加入普通/速度/位置之和。空组没有最坏帧。

| 场景 | 路径 | 样本 | 最坏帧（五项顺序） |
|---|---|---:|---|
| motion | ordinary | 58083 | 21016/26160/57316/54197/57316 |
| motion | speed_due | 5808 | 55609/57339/57339/58179/57339 |
| motion | position_due | 645 | 27899/55499/56699/17299/56699 |
| motion | command_event | 3 | 21016/21016/21016/20915/21016 |
| motion | alignment_transition | 1 | 0/0/0/0/0 |
| alignment_reset | ordinary | 38790 | 0/0/40010/38687/40010 |
| alignment_reset | speed_due | 3879 | 42019/42139/42139/3939/26169 |
| alignment_reset | position_due | 431 | 42099/42099/42099/21199/42099 |
| alignment_reset | command_event | 0 | N/A |
| alignment_reset | alignment_transition | 9 | 0/0/40010/40010/40010 |

## 数值、截止期和ISR相位

- motion: 64536×41数值失败0，最大绝对差1.7763568394002505e-15；截止期/序号/时间顺序异常0，最小slack39.18µs；ISR样本64535，斜率-5.8365380197388388e-06tick/帧，阈值5.0397601494946961e-05，NO_TREND_DETECTED；板报与PC一致。
- alignment_reset: 43100×41数值失败0，最大绝对差0；截止期/序号/时间顺序异常0，最小slack61.61µs；ISR样本43099，斜率6.7681311713800808e-06tick/帧，阈值8.3003469577879569e-05，NO_TREND_DETECTED；板报与PC一致。

## Issue15第8节A4逐条核对

| 条款（按原文顺序） | 结论与依据 |
|---|---|
| A4.1 执行前装载、结束后读回 | 满足本次记录；run完成、未中断、pre-begin及用户手动读回。Codex未亲自观察测量全过程，条件为用户声明。 |
| A4.2 全量DDR、分块不改控制状态 | 完整长度与全帧比较PASS，原DDR窗口；仅结束后分块读回。 |
| A4.3 cache与计时边界 | I-cache ON/D-cache OFF、原main/runner与记录一致；传输/后处理在计时之外。 |
| A4.4 k0开始逐帧、不移时轴 | 全41字段/序号完整，原runner一次init，原时间轴。 |
| A4.5 所有41字段与精确离散量 | 两场景signals.csv每字段失败0，原EXACT字段规则。 |
| A4.6 原浮点容差/非有限拒绝 | 现有比较器原容差未改，数值PASS。 |
| A4.7 运动命令和Ready事件 | motion events为接受3/拒绝1/段号3，2.0915/2.1016/5.2999s对应2/3/2，首次Ready1.9199/3.9599/6.3499s；末帧Ready由全量比较覆盖，未强行保持。当前参考是Runtime1.50独立参数，不冒称PR14全部配置相同。 |
| A4.8 同ELF两次新实验与独立复位 | R1 motion exp1→alignment exp2为同一ELF来源、独立初始化的两个不同场景。alignment输入零基42150 PI_Reset、42300 Init_Reset、42400 travel_fault、42500 Init_Reset分开，完整五态0→1→2→3→4及后续复位事件均在全量比较内。不是硬件全局复位或两次同输入重复试验的证明。Issue只要求至少两次独立实验，不擅自新增必须再跑同输入的门槛。 |

A4分阶段口径仍须Review：早期mode0 motion_03已PASS但来自旧workspace；最终R1两场景均mode1。是否接受这些mode1全量数值证据闭合“连续回放（先不要求实时）”的阶段要求，由ChatGPT最终Review确认；本轮不将未单列的R1 mode0 alignment写成已运行，也不自动追加实验。

## Issue15第9节A5逐条核对

| 条款（按原文顺序） | 结论与依据 |
|---|---|
| A5.1 纯Runtime与完整软件任务计时 | runtime/task/response独立统计，TTC100MHz配置（10ns/tick），读计数开销26ticks，start window motion92/align91ticks；短段预算下不回绕。不是PC墙钟推算或独立测频。 |
| A5.2 BSP周期源与分频重装 | TTC0通道0/1、100MHz配置、无分频、raw9999/logical10000，既有ABA实测和两次pre-begin一致；相位门槛均通过。 |
| A5.3 ISR只发布、单前台消费 | 既有timing/runner来源未改，序号/时序异常0，未用boolean吞并或补算。 |
| A5.4 k0与速度/位置首相 | k0为软件首帧，原k9/k99类别和全41字段比较保留，未另加外环调度。 |
| A5.5 序号/释放/开始/完成及独立时间 | 完整ticks长度及比较PASS，序号/截止期异常0；不从“无中断报错”推导通过。 |
| A5.6 分类统计/首轮冷启动 | 五类样本与全部五项时间已归档；首帧保留。conditions只声明same session，未明确cold/warm及电源冷启动条件，独立冷启动/冷cache覆盖未获证明，此条不能无条件全签。 |
| A5.7 定时输出仍与参考一致 | 两完整场景全41字段零失败，参数/算法不改。 |
| A5.8 每帧执行一次、下一释放前完成 | 完整帧数、序号正常、零deadline、最小slack39.18/61.61µs均正；失败停止逻辑沿原runner。 |
| A5.9 停止后导出 | 用户完成停点读回声明、原main先stop再postprocess、全部输出在DDR；无测量中PC供数或逐拍printf。 |

## 未满足/待确认与结论边界

- A5.6冷启动条件/样本覆盖仍缺明确证据；不把保留k0等同独立cold启动验证。
- A4连续mode0→mode1的严格分阶段签收口径待最终Review；不能把两个mode1 PASS自动解释为所有阶段均已单列执行。
- 同ELF两次独立不同场景已具备；两次同输入的确定性复跑未做，但不把它新增为Issue15硬性验收项。
- A1的实际芯片完整料号/PCB修订与厂商XA/-1差异签核仍未由这些软件数据解除。A6最终Review/用户决定尚未完成。
- 观察到的最大执行时间不是WCET，不含未来AXI/ADC/PL链，也不是实机电机闭环。

本轮没有重Build、重生成、模型/参数/TTC映射修改、清理或任何板卡连接/复位/下载/运行。只做数据分析和文本归档，不为文字更新重跑仿真/RTL/旧回归。PR16保持Draft、不合并、Issue15开放，等待最终Review。
