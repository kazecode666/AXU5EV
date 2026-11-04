# AX-02C2：真实R5 Runtime与PL帧同步回放

## 当前：perf_r1完整实板PASS，等待最终Review

2026-11-04，依据[PR24评论6622743887](https://github.com/kazecode666/AXU5EV/pull/24#issuecomment-6622743887)，签收用户已经完成的单次`current_motion`实验；本轮只读已有文件并归档，不连接或操作板卡、不构建、不重跑C1/RTL/ETH02或其他回归。受测软件提交为`480a6cbe4a762e7a01504275706a4cdef6e64e07`，实际`run.json`、传输状态和UART共同确认身份`0x43324302`。Workspace仍为`D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_perf_r1`，Launch为`ax02c2_runtime_manual`，原native64平台/BSP/FSBL及hardware_02直接复用。

### 实板结果与归档

原始结果根目录为`D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01`，现已占用，不再作为待运行的新目录。[精简签收证据](../../verification/ax02c2/board_perf_r1_01/README.md)保存原`run.json`、`pl_summary.json`、`analysis/summary.json`、`transfer.json`及626B的`UART.txt`；[完整PMU复算](../../verification/ax02c2/board_perf_r1_01/timing_statistics.json)记录本次原始文件的离线复核及全部统计。原1200条失败目录与`current_motion_01_fail1200_backup`保持原样，[原故障证据](../../verification/ax02c2/perf_fix_01/failure_analysis.json)继续保留。

| 签收项 | 用户实验原始结果及本轮只读复核 |
|---|---|
| Runtime完整执行 | status=0，completed_frames=64536，failed_frame=0 |
| Runtime 41字段数值 | 2645976值按原判据零失败；最大差1.7763568394002505e-15，仅x_ref_mm，k3644，在原容差内 |
| 真实PL duty | 193608个uint32位串零差 |
| 帧/命令/采用关系 | 64536条均对应record/step=k、PL帧/命令/采用=k+1；PMU身份亦无错 |
| 捕获与完整停止 | 每条capture_edge=315、status=0；complete_frames/last_frame/last_seq均64536，hold_error=stop_status=0 |
| 实际对象长度 | output.bin=21167808B，timing.bin=4130304B，pl_result.bin=2065152B；与传输记录相符 |
| 网络与UART | 1000Mbps全双工；上传/下载29.616512/22.052247s，计划内重连3.021360s；UART从TCP_READY到RESULT_READY status0/completed64536 |
| 总回放计时 | 50419315 PMU ticks / 7812421Hz = 6.453738s；名义64536×100µs=6.453600s，入口计时还含初始化/首帧准备及停止开销 |

本轮直接使用原Runtime比较器复核全量`output.bin`与同源参考，独立解析全量PL/PMU记录，且所得旧客户端统计与已有`pl_summary.json`一致。不是重新运行板测。浮点数值通过按原容差判断，不声称本次ARM输出与PC参考逐位相同；先前旧/新主机桥接位模式完全相同仍是独立的离线等价证据。`analysis/summary.json`中的`timing=NOT_RUN`只指旧TTC IRQ判据不适用；本应用没有TTC IRQ调度。原`report_v2.bin`保留在运行根目录，本轮未新增板报交叉签核，仍保留其原未验证标识。

### 实际PMU时间分布：包含COMMIT后的日志

时基为记录内的PMU CPU/64、7812421Hz；PL配置元数据为49999500Hz，名义边界比较沿用50MHz、5000拍、edge316。P99取最近秩`ceil(0.99*n)`，全部索引为零基。首记录0在START之前准备：单段Runtime等包含64536条，但跨记录窗口及COMMIT后日志段只统计k1..64535，避免把首记录的START操作混入日志开销。每项最大值独立计算，不能相加当成同一条记录。

| PMU区间（µs） | 样本 | 最小 | 均值 | P99 | 最大 |
|---|---:|---:|---:|---:|---:|
| 输入复制：prepare_begin→step_begin | 64536 | 3.968 | 4.368 | 4.992 | 5.248 |
| 真实Runtime：step_begin→step_end | 64536 | 18.944 | 25.025 | 37.760 | 39.040 |
| 薄适配，不含41字段日志：step_end→adapt_end | 64536 | 13.184 | 28.927 | 30.464 | 30.976 |
| AXI写入/COMMIT：adapt_end→commit_end | 64536 | 6.528 | 6.828 | 7.168 | 7.296 |
| 准备到提交：prepare_begin→commit_end | 64536 | 43.520 | 65.148 | 78.465 | 81.025 |
| **后移日志及返回/循环开销：commit_end→wait_begin** | 64535 | 8.832 | 9.245 | 10.496 | 10.880 |
| 准备含后移日志：prepare_begin→wait_begin | 64535 | 52.481 | 74.393 | 87.809 | 90.625 |
| 结果轮询等待：wait_begin→read_begin | 64536 | 4.352 | 20.552 | 27.008 | 42.624 |
| 结果读回：read_begin→read_end | 64536 | 3.712 | 3.848 | 3.968 | 4.352 |
| 上一结果read_end→下一commit_end | 64535 | 44.672 | 66.356 | 79.617 | 82.177 |
| **上一结果read_begin→下一commit_end** | 64535 | 48.512 | 70.204 | 83.457 | 86.017 |
| **上一结果read_begin→下一wait_begin，含后移日志** | 64535 | 57.473 | 79.449 | 92.929 | 95.617 |
| 相邻结果观察read_begin间隔 | 64535 | 99.073 | 100.001 | 100.609 | 100.865 |

后移的328B日志没有漏计：`commit_end[k]→wait_begin[k]`覆盖该复制及函数返回/循环记录开销，缺少独立日志起止时间戳，不能称其为纯memcpy时间。完整软件工作窗口`read_begin[k-1]→wait_begin[k]`还包含上一结果读回、下一次准备/适配/提交；不包含接下来的空闲轮询等待。

下一提交窗口最大86.016870µs，出现在k55599（10ms/1ms共同到期），与名义发布到下一边界93.68µs相比，描述性差值为7.663130µs，样本没有越过该名义值。**这不是精确AXI接受余量**：未测得结果发布到软件观察的延迟，commit_end也在COMMIT及屏障之后。完整含日志窗口最大95.616967µs，出现在k25999/55389/55549/55789/56189；共有204条超过93.68µs。日志已在COMMIT之后，这些跨越不是命令提交迟到，真实帧采用关系全部通过；不能据此声称全部软件工作在93.68µs内完成。日志最大段10.880110µs发生在k2239，与最大提交窗口不是同一记录。

| Runtime分组 | Runtime样本 | Runtime均值/最大µs | 下一提交窗口最大µs | 含后移日志窗口最大µs |
|---|---:|---:|---:|---:|
| 普通步 | 58083 | 24.823 / 36.864 | 83.713 | 93.825 |
| 仅1ms速度事件 | 5808 | 26.726 / 38.272 | 85.505 | 95.617 |
| 10ms位置及1ms速度共同到期 | 645 | 27.902 / 39.040 | 86.017 | 95.617 |

普通组的跨记录窗口排除k0后为58082条，另外两组数量不变。Runtime最大39.040395µs发生在k28699。分组完整的均值、P99、极值及全部并列最大索引见JSON。这里没有用普通步结果替代较重外环拍，也没有预先优化或修改算法。

### 与原失败点的同口径对照

| 项目，k1200（第1201帧） | 原native64，0x43324301 | perf_r1，0x43324302 |
|---|---:|---:|
| Runtime µs | 35.328 | 34.944 |
| 旧输出日志＋适配 / 新适配不含日志 µs | 44.160 | 23.808（不同边界，不能直接解释为纯量化加速） |
| COMMIT后至wait_begin µs | 0.384，无日志 | 9.472，含328B日志及返回开销 |
| 上一结果read_begin→下一commit_end µs | 95.873 | 75.009 |
| 上一结果read_begin→下一wait_begin µs，含全部日志 | 96.257 | 84.481 |
| PL帧 / 命令 / 采用序号 | 1201 / 1200 / 1200 | 1201 / 1201 / 1201 |
| 完整场景结果 | 前1200条有效后status11停止 | 全部64536条PASS |

同记录提交窗口观察缩短20.864211µs；把后移日志及开销计回后，完整软件窗口缩短11.776119µs。它们是两次真实运行同索引的观察差，不是单个函数隔离周期或所有帧的固定收益。原失败前同一k1..1199前缀的提交窗口均值/最大79.447/91.137µs，新候选同前缀为58.647/69.889µs；全场景的新最大86.017µs另列，未拿短前缀直接替代完整场景。

原k1199为较重外环步；新同记录Runtime37.888µs、下一提交69.889µs、计入后移日志80.129µs。新k1200五反馈首次非零时仍正确采用1201；新k1201提交76.545µs、含日志86.401µs且采用1202。失败点及前后邻居的原PMU字一并写入归档JSON，原保存的XSDB现场没有再上板获取。

**验收范围：** 新perf_r1在本次已知反馈`current_motion`连续回放合同内为BOARD_PASS，原第1201帧故障在完整64536条中未出现。计时是当前I-cache开/D-cache关、停GEM/DMA/IRQ及固定网线条件下的实际分布，非独立测频、WCET、真实ADC/QEP/门极PWM机械闭环或同帧50µs端到端签核。没有新增功能、测试套件、构建或上板操作；原工程、用户模型/参数和全部数据保留。PR24等待用户最终Review，不自动合并或关闭Issue15，也不因历史关机交接再次关机。

## 历史：PR24评论6620575361定向性能修复（当时离线快照）

2026-11-04，接续现有PR24分支，依据[最新评论](https://github.com/kazecode666/AXU5EV/pull/24#issuecomment-6620575361)执行离线诊断、最小软件修改及必要验证/构建。本轮不连接或操作板卡；新候选待ChatGPT Review及用户另行授权单次上板。原实验及`current_motion_01_fail1200_backup`均实际存在，未覆盖；原1200帧失败是有效性能证据。下文旧BOARD_NOT_RUN指最初离线交付阶段，不覆盖此次原候选实板失败。

### 故障证据与时间窗口

独立解析`.runtime/ax02c2/board/current_motion_01`的run/transfer、1200条PMU/PL结果及已保存的失败DDR记录。前1200条的49200个Runtime值按原判据零失败（最大差4.3368e-19），3600个duty位串零差，记录/命令/帧对应正确。失败记录k1200即第1201帧，PL已到1201而命令/采用序号仍1200；完整停止1201帧，hold与stop无错，网络上传/恢复下载成功。[精简原始证据及复算](../../verification/ax02c2/perf_fix_01/failure_analysis.json)，复算入口`scripts/ax02c2_analyze_failure.py`只读已有数据。

| 原现场阶段 | PMU ticks | 约µs（7812421Hz） |
|---|---:|---:|
| k1200输入复制 | 31 | 3.968 |
| k1200真实Runtime | 276 | 35.328 |
| k1200输出日志复制＋薄适配 | 345 | 44.160 |
| k1200适配末至COMMIT完成 | 53 | 6.784 |
| 上一结果read_begin至k1200 commit_end | 749 | 95.873 |
| 此前1199个同类窗口最大值（k1199） | 712 | 91.137 |

名义edge316发布到5000拍边界为93.68µs；此前最大窗口的名义剩余仅约2.54µs。失败的软件完成窗口比该配置窗口长约2.193µs，但commit_end在COMMIT与屏障之后，未采样确切AXI接受时刻，不能把2.193µs写为精确的AXI迟到量。旧采用序号直接证明该次命令错过采用边界。

不是失败步触发更重外环：k1199才是1ms/10ms共同到期，Runtime296ticks；k1200是普通步，Runtime反而少20ticks。实际数据表明五项物理反馈首次非零均恰为k1200；iq/vref在k1199首次非零。生成Convergent代码的非零舍入路径包含余数、floor/ceil等调用，适配时间从k1199的37.248µs增至44.160µs，与数据相关计算激活相符。源路径推断的余数调用次数为k1198/1199/1200的1/2/5次，不是硬件函数跟踪；未单独隔离cache/DDR贡献，不将其猜测为确定根因。

### 最小软件修改及性能边界

生成Runtime、生成薄适配C、FOC/AXI RTL、浮点编译选项及5000拍/314—316相位都不变。修改仅限桥接和日志顺序：

1. 直接将本次`AXU5EV_R5_Runtime_Y.runtime_y`传给薄适配，避免先写DDR日志再从日志读回。
2. 包装层只复制原模型输入端口需要的4个Runtime输入、8个Runtime输出及5个反馈；保留Init_Reset/Init_Done端口，虽然当前生成C已将这两个路径折叠。原选择、Convergent/Saturate和32/40位量化仍在同一份生成C中执行。
3. 完成COMMIT及commit_end时间戳后，再复制全部41个Runtime输出到原日志地址；下一次Runtime step前已复制完成。同一记录、所有41字段及失败前缀关联保持不变，既有pending失败分支也仍保存当步输出。没有放宽序号、跳帧或插延迟。

| 复制工作 | 原候选 | 新候选 |
|---|---:|---:|
| wrapper Runtime U/Y/feedback | 66 doubles | 17 doubles |
| 每拍真正减少 | — | 49 doubles＝392B复制 |
| 41输出日志复制 | COMMIT前 | COMMIT后、wait_begin前 |
| 提交关键路径减少或移后 | — | 合计90 doubles＝720B复制（1440B源读＋目的写流量） |

日志移动只重排截止前的工作，不减少这328B日志的总CPU工作量；后续结果观察仍要承担它。旧adapter计时包含输出复制，新adapter计时不含，日志位于commit_end和wait_begin之间；run.json和客户端说明已更新，PMU16字段与时基不变。

对原失败点，若关键路径实际缩短Sµs，则按同一名义窗口估计的软件完成余量约为S−2.193µs。本轮没有新目标实测，不能为S填入伪造值或保证正余量；已减少的复制量由源代码及ARM指令核对，不等于全负载周期数或WCET。新的非零量化计算仍存在，最终是否满足全部64536帧，只由后续另行授权的单次实验确认。

### 候选验证与构建

必要验证及新软件构建已完成，结果如下。所有等价对照是主机执行；没有连接板卡或测得新R5耗时。

| 本次检查 | 实际结果 |
|---|---|
| 原模型/C定点合同 | 候选API的709896个整场字＋88个必要语义字零差；[证据](../../verification/ax02c2/perf_fix_01/adapter_equivalence.json) |
| 冻结Runtime的旧／新桥接顺序 | 两个独立MEX各64536步，2645976个Runtime double位模式相同，709896个AXI字相同；[证据](../../verification/ax02c2/perf_fix_01/runtime_bridge_equivalence.json) |
| 原Runtime数值判据 | 对同源41字段参考零失败，HOST；未运行旧TTC计时判据 |
| 原生新软件构建 | Vitis2026.1退出0，AX02C2_BUILD_PASS，应用0 warning；[构建及实际内存核对](../../verification/ax02c2/perf_fix_01/build.json) |
| 既有被动启动检查 | PASS，新ELF身份0x43324302、基址0x80000000，ARM32/R5、原AArch64 FSBL、manual启动标志正确；[证据](../../verification/ax02c2/perf_fix_01/startup_check.json) |
| 实际目标关键路径 | ARM反汇编确认无原160/328B memcpy调用、COMMIT/屏障/commit_end后才日志复制，生成Runtime/量化运算序列保持；[证据](../../verification/ax02c2/perf_fix_01/target_path.json) |
| 新候选完整板测及实际余量 | NOT_RUN，待Review及用户之后授权 |

新Workspace为`D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_perf_r1`，Launch仍为`ax02c2_runtime_manual`；新ELF为`ax02c2_runtime/build/ax02c2_runtime.elf`，1015744字节，text/data/bss为141695/5516/3513120。实际GEM/heap/stack仍分别位于0x00400000..0x00500000、0x00508320..0x00548320、0x00548320..0x00558320，与原8个回放对象不重叠。

使用本机原生Vitis注册原native64的已构建xpfm，只创建新应用；没有复制或重建平台/BSP/FSBL。A53 FSBL及PS后配置仍指向`.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_platform`。构建配置为`firmware/r5/ax02c2/build_config.perf_r1.json`，`AX02C2_CONFIG`显式选择；共享被动检查仅增加可选platform_workspace末参数，默认仍为原Workspace路径。Runtime和Adapter仍使用原生成C、`-O2 -fno-fast-math -ffp-contract=off`及相同R5浮点ABI。原失败目录、备份、native64 ELF和所有旧Workspace均保留。

实际成功日志为`.runtime/ax02c2/perf_r1/build_01.log`，原始选定函数反汇编为同目录`target_path.objdump.txt`；主机对照日志`.runtime/ax02c2/perf_fix_01/equivalence_02.log`、输出`.runtime/ax02c2/perf_fix_01/runtime_bridge_02/candidate_output.bin`。首次MEX runner因混用SimStruct与生成复杂类型未编译，已按既有bridge方式隔离翻译单元；该次未执行Runtime算法，不重复已通过的模型字比较。没有另跑FOC golden、旧RTL、C1或ETH02板测。

新单次实验输出预定`.runtime/ax02c2/board/current_motion_perf_r1_01`，不复用失败目录。本轮不运行该入口，待Review后由用户另行授权；唯一操作指南仍为[同一份指南](../../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)。

## 历史：初版离线交付

仓库`kazecode666/AXU5EV`，依据[Issue23](https://github.com/kazecode666/AXU5EV/issues/23)，2026-11-04从包含已合并PR22的`origin/main`建立`codex/ax02c2-runtime-pl-replay`。用户四份模型/参数修改及两个未跟踪源文件原样保留；没有stash/reset/clean、额外clone/worktree或数据搬移。

离线实现、必要模型/C适配对照、原生R5构建及现有启动文件检查已PASS，已提交[kazecode666/AXU5EV Draft PR24](https://github.com/kazecode666/AXU5EV/pull/24)，待Review、不自动合并。C2新应用完整板测为NOT_RUN；C1已经验收的17帧/51duty实板结果直接继承，不再运行。任务书随实现保存于[AX-02C2](../tasks/AX-02C2.md)。

## 调度和数据索引

唯一完整场景为`current_motion`，64536条记录；Runtime每逻辑100µs一步，内部1ms/10ms事件及首相不变。PL同一名义50MHz时钟、每帧5000拍；不启用TTC IRQ作为第二套调度。

| 阶段 | 记录索引 | R5逻辑步 | PL帧 | 命令序号 |
|---|---:|---:|---:|---:|
| 首帧准备，PL尚未START | 0 | 0 | 将启动1 | 1 |
| 读回当前帧，再准备下一记录 | k读回，随后k+1准备 | k+1 | k+1读回，下一帧k+2 | k+2 |
| 最后结果读回并请求完整停止 | 64535 | 已完成64536次step | 64536 | 64536 |

首帧先真实Runtime step、模型薄适配及共同提交，再START。当前帧结果在AXI发布后，读入RAM，计算下一记录的Runtime与适配并提交pending；下一完整边界才采用。最后一帧结果后请求STOP_AFTER_FRAME，等待完整5000拍结束。每条记录仅step一次；不逐帧初始化PI或重启PL。

这是已知记录预装下一帧的连续协同回放，不是未来真实ADC反馈；计算/交换窗口独立记录，不声称同帧50µs端到端控制验收。PMU CPU/64只用于计时，不套用旧TTC IRQ相位/100MHz换算。

## 复用边界

同源物理记录为`.runtime/ax01c/c_fixed_continuous.mat`，包含64536拍原三相电流、真实角度、机械速度/位置以及20输入/41输出。当前Runtime输入/参考沿用`.runtime/ax02a/replay/current_motion`及冻结的Cortex-R目标代码（与ETH02来源一致）；其参考采用较新的Runtime参数，故原MAT中的历史duty不直接作为本轮golden。FOC参考须由同源物理反馈、本轮Runtime参考以及从原模型生成的薄适配共同计算，不能混用历史电流参考。

同源映射实查：原MAT的旧`r5_commit`＋同次物理反馈，通过复制出的原薄模型后，与同MAT已记录`foc_frame9`的64536×9＝580824个量化字段逐值一致。此核对确认theta/x/Tau_e接线和索引来源；新参考改用当前Runtime的41输出，不能直接沿用旧duty。

继承`hardware/axu5ev/ax02c_ps_pl.tcl`中AUX接1、debug reset接0，沿用`.runtime/ax02c/hardware_02/ax02c_ps_pl.bit`和同目录XSA。FOC/AXI RTL、50MHz/5000拍、九字段寄存器及C1复位关联证据沿用；接口未改则不重新生成HDL、不综合或布局布线。

传输复用ETH02的TCP文件对象、分块和CRC及GEM停收发/DMA/IRQ后执行、冻结再恢复下载。新增C2对象和身份；原ETH02独立使用。Runtime算法和适配来自模型生成，不手改生成C/SV。

新增对象9为每记录5个double物理反馈，10为32字节PL结果（record_index、runtime_step、pl_frame、command_seq、adopted_seq、三相duty）。对象1/2/3仍为20输入、41参考和原32字节描述符；4/5/6/7/8仍为Runtime输出、计时、数值报告、run.json和配置。C2计时对象改用独立64字节`AX02C2_PMU16_V1`，不当作旧TTC记录解析；原数值比较器以mode0复用，其TTC时序项不运行。

64536条记录的固定DDR对象范围如下，结束地址不包含在范围内；应用、GEM缓冲、堆栈需在实际map中确认低于`0x10000000`。

| 对象 | 起始 | 字节数 | 结束 |
|---|---|---:|---|
| Runtime输入 | 0x10000000 | 10325760 | 0x109D8F00 |
| Runtime实际输出 | 0x11000000 | 21167808 | 0x1242FEC0 |
| 参考描述符 | 0x12F00000 | 32 | 0x12F00020 |
| C2 PMU记录 | 0x13000000 | 4130304 | 0x133F0600 |
| Runtime参考 | 0x14000000 | 21167808 | 0x1542FEC0 |
| 原数值报告 | 0x16000000 | 2400 | 0x16000960 |
| 物理反馈 | 0x17000000 | 2581440 | 0x172763C0 |
| PL实际结果 | 0x18000000 | 2065152 | 0x181F8300 |

## 实际结果和产物

| 项目 | 实际结果 |
|---|---|
| 同源数据及旧记录字段映射 | PASS，64536拍，580824个量化字段一致；[来源](../../verification/ax02c2/data_source.json) |
| 最终薄适配生成C与复制模型比较 | PASS，709896个整场寄存器字＋8条必要语义输入的88个字，零差；[结果](../../verification/ax02c2/adapter_check.json) |
| 同源FOC参考 | 已实际运行原model_fixed模型，得到64536×3的uint32 duty参考；未运行RTL |
| 最终Vitis原生构建 | PASS，`AX02C2_BUILD_PASS`、退出0，应用编译0 warning |
| 已有被动启动检查 | PASS，ARM32 R5／AArch64 FSBL，身份及MMIO地址正确，未链接TTC调度；[结果](../../verification/ax02c2/startup_check.json) |
| 实际linker/map与对象布局 | PASS，全部PT_LOAD、GEM、heap、stack低于0x10000000，与8个回放区不重叠；[布局](../../verification/ax02c2/memory_layout.json) |
| Python及MATLAB入口 | Python AST解析通过，RUN_AX02C2 Code Analyzer无问题；入口检查没有发起网络连接 |
| 新应用一次完整current_motion板测 | NOT_RUN，按用户最新要求本轮仅离线交付，随后正常关机 |

薄适配复制原`Alignment_Interface`、`Effective_PI_Reset`、`PWM_Disabled`及`Frame_Quantization`；Runtime实际Y14提供Vdc，实际Y1/Y2为id/iq，实际模式/偏置/PWM/复位与同索引记录一同进入原选择和Convergent/Saturate转换。反馈5为ia/ib/ic、原theta_true及原已量化的s40/24角速度；本场景Alignment_Enable始终0。Tau_e为60mm，原角度与位置圆周误差最大约1.13e-15rad，原速度与Runtime输入15逐样本相同；48V来源同时由原记录及当前Runtime参考核对。

只有11字寄存器的整数拆分由API包装完成，选择和量化均来自生成C；40位保留低32与高8有效位。ARM联编实际发现生成multiword helper将int32_t*传给frexp(int*)不兼容，已仅开启薄模型的`ProdLongLongMode=on`，使用编译器支持的int64_t表达原40位，不改Q格式或算法。最终生成C对同一已有q完整对照PASS，没有重算golden。Windows公共头文件与生成头文件大小写重名已改为`ax02c2_adapter_api.*`。较早未交付的workspace及失败/警告日志保留，最终候选仅为下表native64目录。

| 产物 | 实际路径，均以D:/Project/AXU5EV为根 |
|---|---|
| 唯一Workspace | `.runtime/ax02c2/vitis_runtime_pl_native64` |
| Application / Launch | `ax02c2_runtime` / `ax02c2_runtime_manual` |
| R5 ELF，1015452字节 | `.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_runtime/build/ax02c2_runtime.elf` |
| A53 FSBL，341352字节 | `.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_platform/export/ax02c2_platform/sw/boot/fsbl.elf` |
| 新应用map | `.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_runtime/build/ax02c2_runtime.map` |
| 复用bit / XSA | `.runtime/ax02c/hardware_02/ax02c_ps_pl.{bit,xsa}` |
| 实际Cortex-R Runtime源 | `.runtime/ax02a/target/codegen/AXU5EV_R5_Runtime_ert_rtw` |
| 最终薄适配C源 | `.runtime/ax02c2/adapter_native_01/adapter_01/codegen/AX02C2_Adapter_ert_rtw` |
| 完整实验输入及参考 | `.runtime/ax02c2/prepared_04/data/current_motion` |
| 最终成功日志 | `.runtime/ax02c2/vitis_native64.log` |
| 新实验输出预定目录，尚未运行 | `.runtime/ax02c2/board/current_motion_01` |

实际GEM BD为0x00400000..0x00500000、heap为0x00508320..0x00548320（256KiB）、stack为0x00548320..0x00558320（64KiB），结束地址不含。最终应用text/data/bss为141543/5516/3513120字节。平台/FSBL保留原厂emacps配置初始化、deprecated类型和原PS宏等生成警告；应用无新增警告，没有修改厂商代码来消除这些既有提示。

生成入口为`simulation/axu5ev_prepare_ax02c2_data.m`，仅在独立MATLAB batch经MCP执行，复制薄模型及原model_fixed FOC，不保存用户模型。`axu5ev_generate_ax02c2_adapter.m`可只重新生成薄适配而复用已有数据；最终对应检查脚本位于`verification/ax02c2/verify_adapter.m`。本轮没有重跑C1、完整历史RTL、TTC ABA、ETH02旧板测或另一完整alignment场景。构建入口为`scripts/ax02c2_build.py`（本机原生`vitis.bat -s`，独立任务XILINX_VITIS_DATA_DIR）；已验证候选的保护不变，不覆盖旧Workspace。

操作入口见[唯一指南](../../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)。MATLAB的`RUN_AX02C2`调用薄Python入口，实际upload/download直接复用ETH02的Connection实现；该共享类只增加默认仍为旧身份的可选expected_build参数。新固件身份0x43324301，原FOC模块身份0x43314301不改。`runtime`计时不含输入复制；`adapter`统计包含Runtime输出复制；提交/读回/结果观察间隔均是本次PMU窗口，不是硬件测频、TTC IRQ相位或WCET。

用户本次原先授权C2新镜像加载及一次完整`current_motion`，并已说明会接回原ETH02直连网卡并设192.168.50.x；之后最新明确要求“完成离线实现后关闭计算机”。因此本轮停在离线实现与Draft PR交付，不连接、复位、加载或运行C2，板测留待后续继续。交接推送完成后正常关机，不强制关闭或代保存未保存窗口。功率级保持断开，不写启动介质；授权不扩展为无限实验轮次。原R1/ETH01/ETH02/C1工作区和数据保留，不自动合并、不关闭Issue15。
