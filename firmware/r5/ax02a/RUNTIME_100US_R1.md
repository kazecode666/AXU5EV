# Runtime 100µs R1 平台合同

依据：[任务6541052405](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6541052405)，实测精简证据`verification/ax02a/ttc_aba_01/`。ABA及Runtime R1 P1000实测已完成，1000×41数值/时间与板报交叉PASS；证据见 `verification/ax02a/runtime_r1_p1000_01/`。两个完整场景仍NOT_RUN，操作见 [FULL_SCENE_RUN_ZH.md](FULL_SCENE_RUN_ZH.md)。

仅对本板TTC0通道0/1、内部同源100MHz、无预分频、interval模式及10kHz目标应用`hardware_interval=9999 / logical_period_ticks=10000`。`timing.c`先确定逻辑计数，再由自有`timer_mapping.h`映射；其他配置拒绝准备，不无条件减一。真实配置仍须在开始前快照核对。原expected、deadline、释放等待超时、防回绕按逻辑10000计数；无ISR变更，无数值/相位阈值放宽。

候选全局符号`ax02a_timer_mapping_version=1`、`ax02a_runtime_candidate_id=0x52313031`供停止后的只读身份核对；不改变原timer结构或v2/2400B二进制报告。新run.json的timer保存上述mapping_version/candidate_id及实际两通道base/clock，原interval保留9999，period_ticks保留10000。PC版本1必须同时满足身份、频率、通道、无分频、时钟控制和9999/10000；未知版本拒绝。历史无版本数据仍按旧raw×divisor=period约定，不追溯修改原文件；旧+0.99779tick/frame趋势继续检出。

`readback_short.tcl`保留原4参数历史入口；新候选额外传入本构建生成的被动`runtime_candidate.tcl`。source不读板。用户显式调用时核对版本/身份、快照与真实timer，保存候选workspace/ELF来源及run/output/timing/report_v2四文件。不覆写旧目录、不自动连接/选目标或运行；失败的已完成前缀不能冒充完整1000帧。

测试先行：新PC映射和平台映射函数在缺实现时失败，最小实现后通过；错raw、logical9999、时钟、预分频、通道/身份被拒绝，旧漂移保持拒绝。HOST编译并执行真实生成Runtime＋原runner的合同测试，保留原1000tick合成用例，再加逻辑10000的漏序号/截止期退出测试；不是ARM性能或板上中断证据。未修改模型、生成代码、BSP、PLL/cache/TCM布局。

T3已真实构建新`.runtime/ax02a/vitis_runtime_100us_r1`：ELF32/R5/hard-float与实际A53 FSBL通过，候选常量从ELF读取核对，不只信文件名。`runtime_candidate.json/.tcl`由该构建生成；相对config路径按仓库ROOT解析，根目录/新workspace纯文件检查结果一致。专项及相关全套最终63/63通过，独立审查无新P1/P2。精简证据在`verification/ax02a/runtime_100us_r1/`，用户步骤见`FIRST_BOARD_RUN_ZH.md`第13节。状态OFFLINE_READY_FOR_REVIEW；T4仅用户Review后执行，未以离线通过宣布Runtime物理周期已验证。

完整场景不重建ELF：readback_short.tcl在candidate_file后新增可选scene，current_motion固定64536帧、current_alignment_reset固定43100帧；不提供该参数仍按原P1000。两场景必须使用R1候选记录，沿用分块与失败取证语义。描述符分别为scenario2/3，不再复用P1000描述符。
