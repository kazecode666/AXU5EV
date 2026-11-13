# Issue #40 / Draft PR #41：Windows PWM cut SDF 一次性执行报告

## 结论
**原生局部导出成功，slow/max 展开及SDF注释成功；首次动态仿真遇到真实hold违例，按规则停止。未重跑，fast/min未启动。不能认定生产DUT功能失败，也没有任何动态SDF PASS。**

本轮我适配的局部TB把anchor变化安排在50MHz下降沿，恰好与所生成100MHz PWM上升沿重合；外部时钟/数据传播被切除后，该零裕量输入刺激不满足门级保持时间。这是已识别的本轮TB/切点边界建模缺陷，足以解释已见违例，不能转嫁为生产RTL缺陷。由于没有修正复验，不能据此排除其他尚未到达的边界或生产时序问题。

## 状态矩阵
|验收项|结果|
|---|---|
|PWM_CUT_SDF_SLOW|FAIL：动态时序检查失败，未完成场景|
|PWM_CUT_SDF_FAST|NOT_RUN：slow未通过|
|FULL_CHAIN_SDF|保持NOT_COMPLETED：既有O0 GCC异常、O2超时均未完成动态验收；不改判DUT失败|
|FULL_DESIGN_STA|保留原hardware_02既有PASS证据，未重跑|
|FULL_CHAIN_RTL|保留原整链功能验证证据与结论，未重跑、未重新认证|

## 实际执行与性能
使用Windows Vivado/XSim2026.1，SW Build6511674、IP Build6504888。输入为交接包既有routed DCP，切点仅design_1_i/pwm_control_0/inst。未综合、实现或编辑网表/SDF。

- 原生write_verilog -mode timesim -cell、write_sdf -cell -process_corner slow/fast各执行一次。
- 导出监督器墙钟228.586秒，上限1800秒。Vivado自然结束，Harness作业exit0；PowerShell记录内exit_code为null，该字段不能单独作为退出码证据（见原日志正常exit0及作业结果）。
- xvlog：1.781秒，exit0。
- slow/max xelab：14.198秒，exit0，O2仅一次，1ps精度；XSIM43-3452确认成功注释并生成快照。
- 首次xsim：实际运行约142.669秒墙钟后人工监督停止；并非自然完成用时。最后已记录的违例位于模拟760ns及820ns，不能把墙钟时间当成已完成毫秒级场景。
- 本轮未运行fast xelab/xsim；未启动全量xelab。

### 缩小幅度（只按大小/单元计数，无哈希或提交校验）
|指标|全量|局部|缩小倍数|
|---|---:|---:|---:|
|DCP primitive数|196766|1204|163.43×|
|Verilog字节|95227427|377238|252.43×|
|slow SDF字节|485670050|1623447|299.16×|
|fast SDF字节|489460046|1640368|298.38×|

局部570个FF；两角各1197 CELL（1196非恒量原语+根），4433 INTERCONNECT。静态实例路径及CELLTYPE匹配。8个恒量GND/VCC不写入SDF，非关键单元丢失。

## 关键日志与停止原因
slow/xelab.stdout.log 第14–15行记录开始及成功SDF注释，第36行记录快照生成。
slow/xsim.stdout.log 第14–15行：pwm/timebase/anchor_delayed_reg，在760ns与820ns分别posedge/negedge D触发hold违例；数据与参考事件均同一时间戳，Limit=60ps。未关闭timingcheck、SDF delay或过滤真实违例。

pwm_cut_tb.sv 第6–7行所建时钟使aclk下降沿与pclk上升沿重合；pulse_anchor任务在aclk下降沿直接更改anchor。这一刺激不具备原50MHz源寄存器和外部布线的真实延迟，解释了本次零保持裕量边界。未在此轮修改后重跑。

初始运行器错误地将全部WARNING当作硬失败，故保留slow/summary.json中的前置门控FAIL。人工只读审查了VRFC10-3645未接AXI输出及两条XSIM43-4328固定任务参数敏感性提示；它们不是SDF/时序违例，因此仅使用同一快照首次运行xsim，没有重复xelab。最终动态证据在slow/dynamic_review.json；总体验收以results.json为准，未覆盖原停机记录。

确认本轮xsim根PID65780命令后，仅终止该树（子PID66924、20160、6156），未按工具名批杀。动态退出1为监督停止后的进程状态，不冒充自然DUT断言退出。未运行完毕及无PASS标记都不能当PASS。

## 保留与覆盖边界
静态确认完整39位frozen/pending/active比较银行、对应seq、跨50/100MHz往返握手、两级auto_release/reset_release、时基、三相比较和完整互补死区状态。门级TB使用真实导出端口，重构97位debug观测；两个原生reset副本输入按相同低有效复位驱动。没有force内部compare、phase、pending或输出。

**实际动态已获得的证据仅为：仿真器接受局部真实SDF并执行至anchor输入时序检查，且检出了hold违例。** 整组采用、目标谷值、取消不复活、失锁恢复、新请求重许可、死区及边界占空比虽然已编写检查，未完成，均不得声称获得动态SDF通过覆盖。

- FOC/ADC内部、上游到cut完整互连、外部时钟树/复位树、PS/AXI完整链均不在局部SDF覆盖中，仍仅保留原STA和功能仿真依据。
- 上游sticky inhibit/显式reference commit重臂是局部TB环境假设，不是本cut独立验证性质。
- fast_inhibit在原全量routed视图已经无有效连接；局部同样无fanout，该独立输入动态行为N/A，不以auto_inhibit代替并宣称覆盖。
- 原hardware_02 STA审计PASS：WNS1.272ns、WHS0.011ns、TNS/THS0；这只是既有证据，未重新认证全设计。

## 后续建议（未执行）
建议在另行授权的一轮中，首先建立具备明确50/100MHz相位与源clock-to-Q/输入延迟预算的cut边界模型，再做RTL上游+局部SDF PWM混合验证。混合方式有助于保留真实reference commit、late取消、同帧组来源和重臂环境，局部规模也已证明可快速展开。但本轮尚未证明混合边界时序或动态PASS；不能用理想延迟或关闭检查来制造通过，也不建议恢复全量24小时xelab。

## 归档与GitHub
本目录保留导出Tcl、监督器、适配TB、原生网表与两角SDF、接口/单元清单、静态审计、实际命令/进程信息及完整原始日志。审阅小包不含巨大编译缓存/C文件；本地原目录保留全部现场。

公共PR页面可读，但gh未安装、GH_TOKEN/GITHUB_TOKEN未配置，非交互Git凭据查询无可用凭据；因此没有发表评论。PR41评论稿另存PR41_COMMENT.md。未提交巨大生成文件，未合并PR、关闭Issue或操作板卡。
