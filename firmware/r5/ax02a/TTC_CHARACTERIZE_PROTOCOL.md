# TTC-only v1 合同

来源：[PR16 任务书](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6525374617)。本诊断不调用 Runtime，不产生 A4/A5/数值或 WCET 验收结论。

`ttc_characterize.h` 是 C 布局定义；邮箱共25个小端 uint32（100B），依声明顺序排列。末字段build_id为构建器产生并编译进ELF的候选标识，读回时与本候选provenance核对，联合分析也核对一致。magic=`0x31435454`、version=1、record_bytes=16。状态 WAIT=1、RUNNING=2、COMPLETE=3、ERROR=4；command=1 单次启动。case_id=1/2/3/4 分别表示 A1/B/A2/C。错误 0=无、1=参数、2=配置、3=自由计数超时、4=自由计数连续1000000次不变、5=回绕、6=非预期间隔IRQ状态。COMPLETE 只表示采集完成。

全局 `ax02a_ttc_char_samples[1000]` 每条为 `sequence,f_before,p_count,f_after`，4×uint32=16B，共16000B；seq0 是第一次真实IRQ。不会写入第1001条，不与旧 P1000 的64B记录或2400B报告混用。只有 completed_samples 之前的记录有效；失败不分析为完整采集。

每次复制参数、递增experiment、配置停止的计数器、清旧状态、保存实际只读配置、经过prestart停点，才启动F/P。1000条或错误后关闭CPU采样中断、停止两计数器、断开中断回调，发布state，再到done。继续运行才返回WAIT，须用户再次显式command。参数限1000条、raw9999/10000/10001；nominal始终10000。超时以64位计算 `(1000+100)*(raw+1)+100000`，小于20000000tick及32位回绕期；不依赖IRQ计数前进。时钟停转有额外有限轮询保护，此轮询不是校准的墙钟超时。

MMIO 使用本机2026.1 R5 SDT BSP的XTtcPs/Xil_In32，三次读之间各有`dsb sy`及编译器memory屏障。驱动`XTtcPs_InterruptHandler`负责唯一一次运行中clear-on-read应答；回调不再次读状态、不复位P、不打印/分配/浮点计算。配置阶段停止时清旧状态与运行时应答分开。本平台已核对TTC0通道0/1地址0xff110000/0xff110004、同源未分频100MHz配置；这不是独立测频。安装目录未修改。

PC以`[F_before-P,F_after-P]`估计回零窗口。全部样本为主结果，同时单列排除第一条的启动诊断；不以过滤异常支持映射。保存OLS、残差、首尾、窗口、P趋势和ISR相位。相位参考`(sequence+1)*10000`，保留负值。先由数据估计事件周期；首尾窗口差/跨度及每端2tick余量仍作为斜率范围诊断，但不能单独判定候选相容。

对每个候选`D=raw`及`D=raw+1`，必须核对全部1000条窗口是否存在同一个epoch。令`L_i=F_before_i-P_i`、`U_i=F_after_i-P_i`、`i=sequence`、每端量化余量`q=2tick`，只有`max(L_i-q-i*D) <= min(U_i+q-i*D)`才有共同epoch；不扩大原误差预算，不依赖OLS拟合消除窗口矛盾，也不使用after_first替代全采样检查。输出`candidate_feasibility`保留每个候选的可行性、epoch交集上下界及提供极值的样本序号。

仍保留原斜率范围总宽≤0.25tick/IRQ、相邻估计事件间隔不偏离拟合周期20%（至少100tick）、残差不超最大读窗口+4tick等门槛。仅一个候选满足全窗口与原门槛时，才输出RAW或RAW_PLUS_ONE_COMPATIBLE。无共同epoch、多个候选可行或分辨率不足均保留INCONCLUSIVE，`hypothesis_reason`分别说明原因。采集有效与固定周期假设相容分开：窗口矛盾不删除原始样本或诊断；A1/A2即使可重复，联合结果也不能覆盖单次INCONCLUSIVE。

这是明确假设下的分辨率门槛，并非统计置信区间或精确边沿。读窗口≥raw/4、P>raw/4、P接近0或raw、F回绕/倒退、疑似漏事件、身份/配置/中断声明异常均保留并拒绝推断。四字段不足以识别所有跨回零、合并IRQ、时钟同步和总线延迟影响；硬件IRQ丢失状态始终UNKNOWN。A1/A2事件周期范围须重叠且P斜率差≤0.05tick/IRQ；供电会话/条件/ELF/配置不同直接拒绝联合归因。即使兼容raw+1，也须Review真实数据后再决定平台修正。

本轮执行记录：T1提交`1c55a3e`；新增首轮7测试在缺实现时7项FAIL（`.runtime/ax02a/ttc_red.txt`），最小实现后7/7通过（`ttc_green_first.txt`）。真实C HOST HAL覆盖重复A-B-A、容量、无IRQ超时、时钟停转、配置/参数拒绝及统一清理；仅是合成事件，不是板上中断证据。按用户约束在现有分支执行，不创建worktree、不删除原产物；直接沿任务书执行，无额外规划流程。

交付回归另先复现构建/读回缺实现的2项失败，再实现。独立Review发现错timeout预算及过晚样本可能被接受，新增测试先FAIL再GREEN，PC现在核对精确预算且拒绝超预算记录。所有新测试的临时材料保留在忽略的`.runtime/ax02a/ttc_*`目录，不批量清除。P3暂缓：纯文件check不重新解析ARM profile属性，依靠本候选构建时readelf验证；当前真实ELF已通过R-profile/VFP门禁，后续替换ELF须重新构建/核验。

[Review5714581774](https://github.com/kazecode666/AXU5EV/pull/16#pullrequestreview-5714581774)补充：按其三角形中段偏移反例，单次及A—B—A回归在旧实现均先失败（误报RAW_COMPATIBLE），增加全窗口共同epoch检查后通过。raw10000反例交集下界10618、上界10562，raw/raw+1均不可行；采集仍有效、全部与after_first诊断保留，联合只能INCONCLUSIVE。修正仅涉及PC分析器、测试与本说明，不要求重采或重建目标ELF；已有记录应保留并用修正版离线重分析。板上T4、物理根因和正式周期修复状态不变。

本次实际回归：TTC专项12/12、AX-02A相关全套53/53通过，0失败/0跳过；原有正反例全部保留。RED、GREEN、专项及全套日志分别保留在`.runtime/ax02a/ttc_window_review_red.txt`、`ttc_window_review_green.txt`、`ttc_window_review_tests.txt`和`ttc_window_review_full_tests.txt`。这些是HOST/合成验证，不是新的硬件证据。

2026-10-31任务6541052405的T1：用户`ttc_aba_01`原始三组各1000真实IRQ已完整，按全窗口规则复算事件周期10000.999985476985／9999.999988308988／10000.999700386701，联合RAW_PLUS_ONE_COMPATIBLE、repeatable=true、issues=[]。仅支持本板TTC0内部同源100MHz、无分频间隔模式；不表示Runtime周期验收。

读回器现兼容XSDB地址的单整数与4个小端字节，逐字节检查0..255、严格长度，仍与provenance地址核对。邮箱uint32先检查输入范围[-2^31,2^32-1]再将负int32转正，使用Tcl的`%lld`十进制宽整数格式保存已归一化的无符号值（`%d`会按平台截成int32，`%llu`在本机Tcl不支持）。旧run.json仅在PC内存中转换build_id和两个base这三个uint32字段，保留转换前后诊断；不改原文件或样本，不绕过候选一致性。此次build_id=3113983656，base=0xff110000/0xff110004。地址越界/错地址/错构建/短读保护测试已先失败后通过，原始数据无需重采。
