# AX-02C1 AUX修复后一次实板验证

2026-11-03，执行PR22评论6603516201及用户后续明确授权：一次系统复位恢复调试访问，再加载修复后的hardware_02、运行原A53 FSBL、下载原R5 ELF，首个MMIO断点取证并完成唯一一次17帧。功率级保持断开，不写启动介质。

- [原始UART](uart.txt)：XCOM COM5、115200/8N1接收窗口直接保存；原件留在`D:/Project/AXU5EV/.runtime/ax02c/board/uart_17_aux_fixed_01.txt`，3290字节。
- [证据](evidence.json)：新bit/XSA与原软件路径、首次LDR的实际PC/寄存器、板报、原CSV独立整数比较和最终暂停状态。
- 必要XSDB原始返回值：[FSBL/ELF启动](boot.txt)、[新bit与PS—PL后配置](program.txt)、[首读之前](first_mmio_before.txt)、[首读单步之后](first_mmio_after.txt)、[结束暂停](completed_state.txt)。恢复调试访问的[一次系统复位](../online_debug_01/reset.txt)独立保留。
- 首次LDR前`PC=0x001031BC`、`r6=0x80000000`；移除断点并执行一条`stpi`，`PC=0x001031C0`、`r2=0x43314301`。该断点位于开始PL帧计时之前；继续的是同一轮，没有第二次发送`s`。
- UART仅一个START、17行ROW及一个PASS：完整帧17，51个duty与原`verification/m3_foc/directed_probe_source_hex.csv`逐位一致，帧/结果/采用序号均1..17，mismatch=0。
- 结束后一次`stop`成功，R5停在`0x0010333C`（末尾WFI循环），DSCR=`0x03186003`、HALTED=1；无APB读取错误。随后自建XSDB断开并退出，3121仅hw_server监听、无已连接客户端。其他核处于未用核复位或A53 FSBL出口暂停状态。

全部XSDB命令/目标/返回值原始日志保留`D:/Project/AXU5EV/.runtime/ax02c/online_diag_01/`；旧故障取证摘要见[online_debug_01](../online_debug_01/evidence.json)。原故障没有获得有效PC，不能用本次修复后的断点倒写为原现场PC证据。本次仅签收R5—AXI—真实PL FOC的记录向量通路，不是完整Runtime、真实传感器、电机闭环、WCET或50µs端到端验收。PR22待Review，不自动合并。
