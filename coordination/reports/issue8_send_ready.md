# Issue #8：Send采样、Ready回落与请求回执

仓库 `kazecode666/AXU5EV`。基于已合并PR #9（合并提交 `e5c348eb23fd117dcca805ac9f01781c5b939b30`），执行[最新评论](https://github.com/kazecode666/AXU5EV/issues/8#issuecomment-6415202238)。本轮范围为现有Send/Ready链路；Issue #11保留为后续讨论。

开放实现[PR #12](https://github.com/kazecode666/AXU5EV/pull/12)，实现提交`bff686425bfdc440bad421d03ae9737483fca69b`，不自动合并。

## 根因与最小修改

实际Dashboard `Send_Move_Toggle` 绑定 `Simple_Host/Host_Move_Request` 的 `Host_Move_Request` 变量；Ready/Busy分别绑定 `R5_Commit_Fields` 第31/25路，未发现绑定错位。使用用户当前磁盘模型，START_HERE加载原10 mm/V10/A100/J1000参数后运行；本地模型StopTime已由用户保存为6 s，未覆盖回5 s，参数文件默认仍为5 s。

无发送的运行中，Ready在1.9199 s升为1，1.9799 s又降为0；Busy始终为0。位置误差在原0.02 mm边缘波动，每个10 ms位置事件重新核对连续5次窗口，期间Ready可能回落。1.9798 s的已提交Ready仍为1；下一位置事件1.9799 s误差为0.0204068573991 mm，计数清零并撤销Ready。其后2.0799 s重新满足条件。这里不应通过改PI、扩大窗口、锁存许可或排队来“修复”。

之前说明把status=3简写成“Busy拒绝”，而实际代码用Ready拒绝，存在 **Busy=0、Ready=0** 的情况。旧面板也缺少明显的接收时间、计数及段号，单看之前显示的Ready=1和未变化的接受目标，容易把正常拒绝误认为Send未采集。MCP能复现采样边界，不能证明真实鼠标控件的刷新延迟；该UI因素仍未实测。

最小修改是补齐只读回执并纠正操作说明：

- Hybrid操作面板右侧增加 `Command_Receipt` 及两个数字显示。输入快照显式100 µs保持，与同拍Runtime提交共同产生 `sampled_send_Ready_Busy` 和 `command_receipt`，不参与控制或改变请求判定。
- 当前显示按行给出R5采样Send、Ready、Busy；回执按行给出接收软件秒、Host状态、接受数、拒绝数、段号、接受目标。接收时间对应最近请求；status通常保留最近请求结果，但运动中PWM禁止/PI_Reset可异步将其改为7，时间不变，不代表新请求。Ready是当前状态。[面板实际导出](../../verification/issue8/send_panel.png)。
- 仅向右扩展受影响操作面板，新增局部From/Goto；原有块位置与本轮开始时的用户磁盘模型比较保持（该用户版本与Git合并基线本就存在布局差异）。布局工具曾自动缩放Runtime块、移动反馈日志块，最终已分别恢复并核对。Runtime、Control、PI、轨迹函数、五态对齐、0.02 mm/连续5次规则及拒绝不排队策略均未改。
- 新增 `axu5ev_verify_send`，从Dashboard Binding读取变量名后用 `simulation.setVariable` 调参；`axu5ev_send_trace` 对实际快照/提交逐拍复算原Host，用状态副本取得处理请求前的Ready/allowed/Busy，检查复算与实际提交一致。它们是本任务的复验与分析入口，不是日常启动前置条件。

## 复验方式与证据

从现有START_HERE入口初始化，再分别执行 `axu5ev_verify_send('model_fixed')` 和 `axu5ev_verify_send('c_fixed')`。只在SimulationInput中将本次停止时间设为8 s，不改模型保存值。首段仍为10 mm；1.97985 s暂停时先读到Ready=1，再改草稿为0并翻转实际绑定变量；下一R5拍1.9799 s重新判定并拒绝。2.09 s只反向翻转Send才发起返回；随后包含Busy拒绝、反向至−2、同目标确认及PWM不允许拒绝。

详细实际数值以 [model事件](../../verification/issue8/model_fixed_send_events.csv)、[C事件](../../verification/issue8/c_fixed_send_events.csv) 和 [原Ready变化](../../verification/issue8/send_ready_edges.csv) 为准。完整MAT在本地 `.runtime/issue8/*_send.mat`，运行日志保留既有Alignment_Task Inherit及FOC定点量化警告。

| 实际检查 | 结果 |
|---|---|
| model_fixed与c_fixed各6次发送 | PASS；状态均为3、2、3、2、5、6，每次变化的接收时间均匹配100 µs采样拍 |
| Ready回落、允许但未Ready、Busy、不允许的区分 | PASS；首个拒绝为Ready=0/allowed=1/Busy=0；第三个为Busy=1；最后一个为allowed=0 |
| 10→0→−2 mm与重复目标 | PASS；接受数最终3（含自动首段）、拒绝数3、段号3；同目标status5不增加计数 |
| 拒绝不排队 | PASS；1.9799 s拒绝后，2.09 s再次翻转前接受目标仍为10、接受数仍为1 |
| 模型/C逐拍实际提交 | PASS；全41字段最大差1.77635683940025e−15；Host复算与实际提交一致 |
| 新观察器与原输出 | PASS；显示日志与同拍输入/提交逐值一致；第一次发送前全部41字段相对修改前差0 |
| 观察器节拍 | PASS；初版继承1 µs的问题由显式100 µs保持修正后重跑通过；最终显示格式/日志命名修改另做1 ms针对性验证 |
| 静态与排版 | PASS；受影响模型连线/Stateflow检查健康，新增两份.m的Code Analyzer无问题；原块位置按用户磁盘基准恢复核对，并检查面板导出无文字盖线 |

## 操作结论与范围

每次翻转后先看实际采样Send与接收秒，再看status、计数和段号。status=3表示该请求拍未Ready，6表示当拍不允许；均已处理但拒绝，不会等Ready后补发。条件满足后需再次翻转。status=5表示同目标，不新起段；status7是原运动中断状态。暂停显示的是已提交状态，继续后的采样拍仍可撤销Ready；暂停本身不承诺下一个请求必然接受。

本轮没有修改算法源或接口，不需重新生成C/MEX或RTL。静态结构检查与Windows主机模型/C功能仿真单列；实际鼠标输入/点击和屏幕刷新、c_rtl重跑、完整RTL点位、托管SIL、R5目标、真实AXI、5EV综合/布线、ARM实测、烧录与实机均 **NOT_RUN**。旧PR #9的C/RTL验证保持其原范围，不充当本轮新证据。
