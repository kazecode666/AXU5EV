# AXU5EV 协作与工作区规则

## 当前开发

- 相位候选为`.runtime/ax02a/vitis_phase_diagnostic`，v2报告2400B，原两个workspace及ELF保留。exp2本次数值PASS、deadline/sequence PASS，但ISR phase趋势0.999271tick/帧被新PC/C诊断拒绝；硬件根因未确认，interval/logical period仍10000，不盲减1、不宽deadline。GUI只读配置取证/复验见指南第8节；候选板上NOT_RUN。

- 最新执行PR16评论6516979286/6517272543及Review5708766094：exp2新capture已完整，数值PASS但存在约1tick/帧ISR相位累积趋势，周期一致性未确认。先提交数据结论，再诊断/核查TTC/证据充分后最小修正；不能盲改9999、修改名义period掩盖漂移或放宽deadline。保留`vitis_target_a53fsbl`与`vitis_postprocess`及全部原始数据，候选新目录；不连接/发现/操作板卡，寄存器步骤交用户。

- C1已提交64466414773038524dce40c120dd99434102e7e8；C2/C3新固件只在`.runtime/ax02a/vitis_postprocess`离线构建，默认后处理关闭，目标后处理/P1000周期未验证。当前执行PR16评论6514858529的C1—C3。用户BOARD_BOOT/FIRST_WAIT及motion_03首次64536×41真板数值PASS已有评论/本地报告证据；A4第二次motion、alignment/reset及完整A5仍待验收。先提交C1不改固件，再做C2/C3离线后处理。用户正在调试`.runtime/ax02a/vitis_target_a53fsbl`，禁止覆盖/重建其ELF；新固件独立输出。Codex不得连接、发现、暂停/恢复、复位、下载、读写或运行板卡。原始output/ticks保留；比较/时间摘要只在实验结束且计时器停止后做，开关默认关闭，不改算法/cache/TCM/采样首相，不重跑RTL。

- 目标板：AXU5EVB-E，用户已确认。具体PCB修订、芯片完整料号及厂商工程XA/-1与手册XC/-2差异，在板级适配前核对，不阻塞R5软件整理。
- R5F：位置P、速度PI、原五态对齐及一次性偏置、Reference_Manager/轨迹/命令与恢复管理。
- PL：复用已接受的电流FOC，负责同步采样/位置接口、运行中角度/偏置应用、PWM及快速禁止。
- 算法源为现有Simulink/Stateflow；不手改生成SV/C补算法，不重做PI/FOC和定点化，不强制三环全部HDL化。
- Simulink搭建完成后逐层检查连线与排版；From/Goto使用局部作用域，Inport/Outport保持默认大小与外观。
- 先读 `coordination/HANDOFF.md`。AX-00迁移已完成；旧迁移任务、Issue #3及旧M4仅作历史记录，不作为继续开发的流程清单。
- 当前优先Issue #15的AX-02A（A1—A6）：先真实R5目标工程、数值与100µs时间证据，不重规划全项目、不默认重跑完整RTL。PR #14已合并（ae9a11d2d59abc952cce0b979d004a315878639a），Issue #13仿真收尾仅作既有证据。当前Cortex-R生成/全采样导出/主机比较及真实5EV PS-only XSA、R5 standalone BSP/FSBL/ELF/map构建通过；10月27日历史BOARD_BOOT/REPLAY/PERIODIC为NOT_RUN；10月30日新状态见本节首条及`coordination/reports/ax02a_r5_target_validation.md`。不得以构建或主机结果关闭板上验收。
- 继续取消C源码学习、逐行讲解及教学配置更改。Ready是当拍许可，Busy=0不保证Ready=1；status3未Ready拒绝、不排队。Issue #11和AX-02B/C不在本轮实施。活动模型和必要.m集中在`simulation/`，唯一日常参数入口`init_AXU5EV.m`，启动入口`START_HERE.m`。保留用户本地SLX/参数修改；旧PR14输入可复用，但当前参数参考必须独立标识。目标生成不覆盖PC目录/MEX、不保存未保存模型。板卡复位/JTAG加载运行须本次明确授权。
- 当前按PR16“用户手动上板与首次PS开发学习”评论补齐离线操作交接，上板由用户本人完成；Codex不连接、复位、写内存、加载或运行板卡，也不自动探测已接好的线。首次手动测试只到现有R5应用等待输入；操作见`firmware/r5/ax02a/FIRST_BOARD_RUN_ZH.md`。不恢复C语法教学，不另建Hello World/LED/QEMU项目，不把后续回放段自动执行。
- PR16首次故障已定位旧GUI将R5 FSBL加载到A53_0；当前离线启动工程为`.runtime/ax02a/vitis_target_a53fsbl`，A53_0 FSBL＋R5_0应用，launch为`ax02a_first_wait_a53fsbl`。先用构建入口的`--check-startup`核对实际架构/域/路径；保留旧workspace，旧`ax02a_first_wait_manual`不再用于GUI重试。用户修正后BOARD_BOOT和首次motion已有PASS；其他板上验收见C1—C3首条，不把旧R5 Suspended当初始化成功。
- 板型以《AXU5EVB-E开发板用户手册》为依据；用户确认核心板可参考`ACU5EV核心板原理图.pdf`，底板可参考`AXU5EVB-E开发板原理图.pdf`（与AXU3EG底板共用），实物以太网收发芯片JL2121。不得仅凭图框AXU3EG否定底板资料，也不因此在AX-02A扩展网络适配。
- 保留用户现有紫色分区与Host/Alignment_Task/Motion_Control布局；修改仅微调受影响区域。MATLAB/Simulink操作使用MCP，不使用Computer Use。

## 工作区与接口

- 使用已确认的 `D:/Project/AXU5EV` 和 `kazecode666/AXU5EV`，旧 `D:/Project/FPGA_XC7A200T` 只读；不额外clone/worktree，不复制旧`.git`。
- 继承 `references/legacy/PMLSM_Hardware_Interface_Map.md`、MBDL4参数及MIL/DSP的三相电流、光栅、RELCON/ENCON/F_Reset与ERRI/ERRU需求；单列AXU5EVB-E的新ADC、电平和接线适配，不要求用户重述已有定义，不照搬DSP引脚。
- 不自动stash/reset/clean、强制pull/push、覆盖用户修改、保存未保存窗口或关闭全部模型。活动模型与冻结/历史副本分开；不用根目录递归genpath。
- 禁止批量删除。需要删除时，一次只删除一个明确路径的文件；批量删除交由用户手动进行。

## 开发与验证

- 保持已有PI/位置P、采样周期、五态对齐与手动Start；PI_Reset、Init_Reset、global reset、故障清除分别处理。保留一次死区、应用延迟和PWM禁止后机械继续的语义。
- 向量接口同时维护Mux、Demux、旁注与C生成来源；当前Runtime输入分组宽度`[11 3 1 1 1 1 1 1]`，位置在字段20。Demux前两路仍是向量，不把输出端口号当字段索引。
- 只做变更所需验证；不要求提交文件哈希/清单，不做全资料哈希遍历、快照保护报表、字节一致性专项或额外资料冒烟测试。历史证据原样保留；文字修订不重跑旧仿真/RTL。
- 报告说明做了什么、相关文件/章节、可复用点和真正未完成项；区分静态检查、主机仿真/SIL、RTL、综合、布线、ARM实测和实机，未运行写NOT_RUN。
- 不增加位置积分、运动中重规划、CORDIC、标幺化、缩位或旧全HDL对齐优化，除非用户另行要求。

## 协作与交付

- ChatGPT负责架构/Review；Codex在本仓库实施并按需验证，普通小步Git提交与PR正常进行。记录完整owner/repo、PR和提交SHA，旧新编号分开。
- 用户决定研究方向与合并、硬件操作；明确授权后可执行指定PR合并。烧录bitstream、功率级上电须另行授权。
- 使用现有登录与权限，不索要/打印token，不复制密钥或全局工具配置。厂商原件默认本地保留，只提交原创整理和必要索引；第三方文件遵守许可。
