# AX-03B3 双路校准与电流观察

执行 kazecode666/AXU5EV Issue #32。基线为含已合并 PR31 的 main `810939798c76ed66ee8f96a450d5283f6b6f3656`；分支 `codex/ax03b3-current-observer`。未自动合并、未覆盖用户修改。

## 实现

新增 B3 顶层沿用 B2 J15 时钟/采集、七转换身份关联及每500次转换选样；直接实例化 B1 `ax03b1_current_adapter` 和原两份生成SV，数值源/生成物不变。用数值 result_strobe 发布原32word冻结快照，测试输入原码在采样拍锁存，保持与结果同帧。采样ID/tick来自原接收器，下一选样之前保持稳定。未接 ABZ/FOC/Runtime/功率输出。

六个暂存参数和一个命令寄存器提供整组 apply、restart 和 cal_en。独立AW/W保留，命令固定在无采样冲突的相位消费。保持生成DUT的分路累计、完成后保持、完成当帧无效、下一帧使用新偏置行为。不增加滤波或第二套电流算法。

REAL 默认真实双路 ADC；TEST 构建时固定注入2000/2001与2100/2101，校准后正负增量，复用同一数值和快照实例。TEST质量bit16及UART来源显式标识，physical_link_verified仍0。默认固件增益65536仅作数字链测试，真实增益/极性尚未标定。配置及校准不自动执行。

## 验证和范围

新增集成短仿真通过2064帧：两次1024帧校准与各8帧电流、独立分数偏置、完成当帧无效、正负换算与c相重构、显式重启、AW/W分拍、命令与采样不碰撞。原快照读协议直接复用；本次未重跑B1/PR24全量。结果与实际构建状态见 `verification/ax03b3/results.json`。

REAL与TEST均完成综合、布局布线、bit/ltx/含bit XSA导出。REAL：WNS +1.361ns/WHS +0.015ns、4463 LUT/4699 FF；TEST：WNS +1.757ns/WHS +0.012ns、4449 LUT/4620 FF。均TNS/THS=0、22 DSP、2 BRAM Tile。REAL R5构建及既有被动启动检查PASS；TEST R5构建及既有被动启动检查也PASS。两应用实际BSP基址均0x80000000，ARM32 R5应用/AArch64 FSBL、手动Launch文件检查通过；板上运行NOT_RUN。

两版本保留DRC建议：DPIP-2 21项、DPOP-3/4各14项（原数值DUT未加额外流水线），PDCN-1569 3项、REQP-1617 2项、RTSTAT-10 1项；不宣称DRC零警告。methodology保留TIMING-18 26项、LUTAR-1 5项、XDCB-5 4项。外部ADC时序预算和送出pad时钟约束沿用B2，非实测；未放宽约束或添加false_path。所有板卡操作NOT_RUN，不把数字TEST结果当模拟前端或物理电流精度验证。

## 已有零流观测归档

原始文件保留 `.runtime/ax03b2/board/zero_current_01/uart_zero_current_01.txt` 和 `ila_zero_current_01.csv`。本轮复算UART64条：A范围2659..2680、均值2669.078125；B范围2658..2678、均值2667.59375，两路OTR均0。ILA文件1024行是逻辑分析仪采样行，不冒称1024个独立控制采样。统计见 `verification/ax03b3/zero_current_summary.json`。

实验条件沿用Issue32记录：24V辅助供电开启、母线/电机未连接，1.654V是接AN9238前测量；ILA首次未发现后刷新恢复。仅支持原码观测，未在当时运行校准，不改写B2构建时NOT_RUN历史。

## 使用与未完成项

唯一操作说明：`firmware/r5/ax03b3/FIRST_RUN_ZH.md`。无驱动板，不进行真实零流/增益/极性/噪声验证；后续手动板测须另行授权。原5个修改文件、2个未跟踪文件、全部旧Workspace和数据保留。

交付：[kazecode666/AXU5EV Draft PR33](https://github.com/kazecode666/AXU5EV/pull/33)，实现提交`90f70e62803c9e7de49e24d42793f8154e2279bf`。已停止等待Review。
