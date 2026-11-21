# AXU5EV 协作与工作区规则

开始前读 [当前交接](coordination/HANDOFF.md)，从实际仓库状态和本次用户授权接续。旧阶段状态、操作背景和证据见[历史交接](coordination/HANDOFF_HISTORY_2026-10-31.md)。

## 工作区与资料

- 使用现有 `D:/Project/AXU5EV` 与 `kazecode666/AXU5EV`。旧 `D:/Project/FPGA_XC7A200T` 只读。另建 clone 或 worktree 须由用户授权。
- 先检查分支、工作树及相关未提交差异。保留用户文件、未保存窗口、历史 Workspace、冻结产物与原始实验数据。禁用自动 reset、clean、stash、强制 pull 或 push。MATLAB/Simulink 通过 MCP 操作，未经授权不保存或关闭用户模型。
- 禁止批量删除。删除时一次只能处理一个明确路径的文件；需要批量删除时交由用户手动处理。厂商原件和大包默认留本地，只提交原创整理、必要索引及许可允许的精简证据。
- 继承[原 MIL/DSP 硬件接口需求](references/legacy/PMLSM_Hardware_Interface_Map.md)，将 AXU5EVB-E 的 ADC、电平和接线适配单列。板型以 AXU5EVB-E 为准，厂商原理图与实物器件需按[板卡资料](hardware/axu5ev/ALINX_BOARD_FACTS.md)核对；旧 DSP 和 Artix 引脚仅作来源参考。

## 模型、接口与生成

- 纯仿真与实机各用独立的模型、算法、参数和显式路径。入口分别为 `simulation/START_SIMULATION.m` 和 `simulation/START_EXPERIMENT.m`。避免根目录递归 `genpath`，历史、测试和冻结产物按用途引用。
- 算法源为 Simulink/Stateflow。算法修改在模型源中进行，生成 C/SV 通过对应入口重生成。以新版本目录保存必要生成源，本地缓存、Workspace 和大结果放独立的 `.runtime/` 子目录。
- 保持已确认的 PI、位置 P、采样周期、五态对齐与手动 Start。区分 PI_Reset、Init_Reset、global reset、故障清除，保留死区、应用延迟和 PWM 禁止后机械继续的语义。新增算法与整定须明确授权。
- 保留用户现有紫色分区与 Host/Alignment_Task/Motion_Control 布局。只微调受影响的区域，逐层检查连线和排版；From/Goto 使用局部作用域，Inport/Outport 保持默认外观。
- 向量接口变更应同步模型 Mux、Demux、旁注和 C 生成来源。按对应接口合同区分字段索引和向量端口号。原 Runtime 的 `[11 3 1 1 1 1 1 1]` 分组及位置字段 20 属于其既有接口，实机 AX-04B 帧以[实时接口合同](integration/ps_pl/AX04B_INTERFACE.md)为准。

## 验证、权限与交付

- 只做本次变更需要的验证。区分静态检查、主机仿真/SIL、RTL、综合、布线、ARM 实测和物理实验。未运行写 `NOT_RUN`，保留旧报告和失败证据。文档维护使用路径、链接及提交范围检查，无需复跑历史验证或编制全库哈希清单。
- 用户决定研究方向、合并和现场操作。板卡连接、调查、JTAG 复位/下载/运行、改接线、启动介质写入及功率上电须本次明确授权。历史会话中的现场许可只用于追溯。
- 正常提交小步变更并记录完整仓库名、PR 和提交 SHA。使用现有登录权限，不索取、打印或复制凭据及全局工具配置。按任务约定交付并停在 Review，合并须用户明确授权。
