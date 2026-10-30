# TTC-only v1 合同

来源：[PR16 任务书](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6525374617)。本诊断不调用 Runtime，不产生 A4/A5/数值或 WCET 验收结论。

`ttc_characterize.h` 是 C 布局定义；邮箱共24个小端 uint32（96B），依声明顺序排列。magic=`0x31435454`、version=1、record_bytes=16。状态 WAIT=1、RUNNING=2、COMPLETE=3、ERROR=4；command=1 单次启动。case_id=1/2/3/4 分别表示 A1/B/A2/C。错误 0=无、1=参数、2=配置、3=自由计数超时、4=自由计数连续1000000次不变、5=回绕、6=非预期间隔IRQ状态。COMPLETE 只表示采集完成。

全局 `ax02a_ttc_char_samples[1000]` 每条为 `sequence,f_before,p_count,f_after`，4×uint32=16B，共16000B；seq0 是第一次真实IRQ。不会写入第1001条，不与旧 P1000 的64B记录或2400B报告混用。只有 completed_samples 之前的记录有效；失败不分析为完整采集。

每次复制参数、递增experiment、配置停止的计数器、清旧状态、保存实际只读配置、经过prestart停点，才启动F/P。1000条或错误后关闭CPU采样中断、停止两计数器、断开中断回调，发布state，再到done。继续运行才返回WAIT，须用户再次显式command。参数限1000条、raw9999/10000/10001；nominal始终10000。超时以64位计算 `(1000+100)*(raw+1)+100000`，小于20000000tick及32位回绕期；不依赖IRQ计数前进。时钟停转有额外有限轮询保护，此轮询不是校准的墙钟超时。

MMIO 使用本机2026.1 R5 SDT BSP的XTtcPs/Xil_In32，三次读之间各有`dsb sy`及编译器memory屏障。驱动`XTtcPs_InterruptHandler`负责唯一一次运行中clear-on-read应答；回调不再次读状态、不复位P、不打印/分配/浮点计算。配置阶段停止时清旧状态与运行时应答分开。本平台已核对TTC0通道0/1地址0xff110000/0xff110004、同源未分频100MHz配置；这不是独立测频。安装目录未修改。

PC以`[F_before-P,F_after-P]`估计回零窗口。全部样本为主结果，同时单列排除第一条的启动诊断；不以过滤异常支持映射。保存OLS、残差、首尾、窗口、P趋势和ISR相位。相位参考`(sequence+1)*10000`，保留负值。候选周期先由数据估计；兼容范围为首尾窗口差/跨度，再为每端增加2tick量化余量。要求该斜率范围总宽≤0.25tick/IRQ、相邻估计事件间隔不偏离拟合周期20%（至少100tick）、残差不超最大读窗口+4tick，才输出单一RAW或RAW_PLUS_ONE_COMPATIBLE。

这是明确假设下的分辨率门槛，并非统计置信区间或精确边沿。读窗口≥raw/4、P>raw/4、P接近0或raw、F回绕/倒退、疑似漏事件、身份/配置/中断声明异常均保留并拒绝推断。四字段不足以识别所有跨回零、合并IRQ、时钟同步和总线延迟影响；硬件IRQ丢失状态始终UNKNOWN。A1/A2事件周期范围须重叠且P斜率差≤0.05tick/IRQ；供电会话/条件/ELF/配置不同直接拒绝联合归因。即使兼容raw+1，也须Review真实数据后再决定平台修正。

本轮执行记录：T1提交`1c55a3e`；新增首轮7测试在缺实现时7项FAIL（`.runtime/ax02a/ttc_red.txt`），最小实现后7/7通过（`ttc_green_first.txt`）。真实C HOST HAL覆盖重复A-B-A、容量、无IRQ超时、时钟停转、配置/参数拒绝及统一清理；仅是合成事件，不是板上中断证据。按用户约束在现有分支执行，不创建worktree、不删除原产物；直接沿任务书执行，无额外规划流程。
