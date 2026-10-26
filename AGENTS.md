# AXU5EV 协作与工作区规则

## 当前开发

- 目标板：AXU5EVB-E，用户已确认。具体PCB修订、芯片完整料号及厂商工程XA/-1与手册XC/-2差异，在板级适配前核对，不阻塞R5软件整理。
- R5F：位置P、速度PI、原五态对齐及一次性偏置、Reference_Manager/轨迹/命令与恢复管理。
- PL：复用已接受的电流FOC，负责同步采样/位置接口、运行中角度/偏置应用、PWM及快速禁止。
- 算法源为现有Simulink/Stateflow；不手改生成SV/C补算法，不重做PI/FOC和定点化，不强制三环全部HDL化。
- Simulink搭建完成后逐层检查连线与排版；From/Goto使用局部作用域，Inport/Outport保持默认大小与外观。
- 先读 `coordination/HANDOFF.md`。AX-00迁移已完成；旧迁移任务、Issue #3及旧M4仅作历史记录，不作为继续开发的流程清单。
- 当前优先Issue #8正常用户运行修复与验证；活动模型和必要.m集中在`simulation/`，唯一日常参数入口`init_AXU5EV.m`，启动入口`START_HERE.m`。不得用旧1 mm脚本结果代替默认10 mm验收。
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
