# 候选版本记录（上限3）

## v1 — 首次统一协议候选

依据：上一轮930ns duplicate source offer，源输出寄存器和task撤销未闭合；真实上游motor_foc_control在valid&&ready&&!inhibit同沿撤销auto_valid，桥同沿捕获frozen银行并置busy/request。

最小修复：唯一posedge源驱动器，task只提交mailbox；真实握手同沿+0.2ns撤销，payload保持至握手并在后续边沿污染live输入；取消/恢复统一驱动协议，finish_offer用同步轮询保留条件；初笔真实valid/ready/inhibit/seq/busy/CE/request/pending/accepted trace。原同相2:1、0.2ns、20nsanchor、全部44关键check与覆盖门槛不变。

静态阶段发现forward declaration风险，编译前已移驱动块到所有声明后；不涉及行为变更。每次实际预检/仿真结果单独存v1目录。最终：v1语法预检通过，slow注释成功；910ns握手、910.2ns真实撤销，native CE0/busy0/request0且500us未接受。现有native LUT/reset对inhibit端口的直接语义与RTL不一致，疑似cut/优化边界问题而非已证明TB-only，已硬停。候选使用1/3，v2/v3未创建，不再自动重试。
