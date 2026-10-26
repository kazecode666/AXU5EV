# 日常仿真：从这里开始

进入 `simulation/`，按需编辑 **init_AXU5EV.m**，运行 **START_HERE.m**。入口按自身位置加载参数、准备所选后端并打开 **AXU5EV_Hybrid_ClosedLoop**，不自动Run。默认保留 **model_fixed、10 mm、5 s、V10/A100/J1000**。

## 正常点位与同次Run继续发送

1. 以命令行 `AXU5EV_READY backend=...` 确认准备后端。Run后面板Backend显示0=model_fixed、1=c_fixed、2=c_rtl；停止时数字显示可能保留上一Run。AutoStart=1自动发起首段，status=1不是故障。
2. 观察 `x_ref_mm`、`x_mm` 和Ready。Ready需轨迹完成、误差不超过0.02 mm、连续5个位置事件，并同时满足模式、PWM、复位和对齐条件。它按10 ms位置事件更新，事件间机械仍会运动；不能按现实等待了几秒判断。
3. Ready=1后，在 `Set_Host_Target_mm` 输入下一草稿目标，按Enter确认，再将 **Send_Move_Toggle** 翻转一次。0→1、1→0各算一次请求；只改草稿不会启动运动。
4. 观察 `accepted_target_mm`、段号/接受数变化和新的运动。Busy时发送status=3，拒绝且不排队；同一目标重复确认status=5，不新起段。status保留最近请求的处理结果，status=3不取消当前已接受的运动段。

也可点击Pause后修改目标并确认，再翻转Send，点击Continue。暂停继续不会重置控制/轨迹状态。仿真结束前需留足运动时间；停止后修改 `init_AXU5EV.m` 的 `M1A_StopTime_s` 并重新运行START_HERE，或只在模型工具栏延长本次StopTime。Pacing只影响交互节奏，不修正控制问题。

Dashboard绑定已通过MCP检查；本轮不使用Computer Use，输入框按键、实际鼠标翻转及显示刷新尚未亲手操作，记为 **UI手动验证NOT_RUN**。最短人工核验：按上述路径完成10 mm，Ready后输入0并按Enter，翻转Send，确认接受目标变0且电机返回；再输入−2确认并反向翻转Send。若草稿没变，先核对输入是否确认；草稿变了但接受目标没变时，查看status=3（Busy拒绝）或6（当前不允许）。

## 参数、运行输入与重建

| 类别 | 修改方式 |
|---|---|
| 目标草稿、Send、速度/id/iq测试请求、PWM请求、PI_Reset、手动Init_Start/Init_Reset | 通过现有面板运行输入修改，无需生成C；模式组合须有效 |
| backend、Alignment_Enable | 停止后设置；backend在init中选定后运行START_HERE，或在已初始化状态调用 `axu5ev_prepare('c_fixed')` |
| 电机参数、时基、PI/限幅、轨迹配置、对齐拍数等 | 停止后编辑唯一init并初始化；编入C的参数改变后必须显式重建；不改变既定时序合同 |
| 纯区域/注释/排版 | 无需重生成C；Control、Runtime、Hybrid布局分别保留 |

普通Run不重新编译。首次C/RTL模式会构建缺少的产物；已有MEX不会因工作区参数变化而自动更新。修改Runtime算法、输入向量顺序或编入C的参数后，停止并执行：

```matlab
axu5ev_prepare('c_fixed',true); % 或c_rtl；使用当前已初始化参数，不恢复默认目标
```

不要在另一个MATLAB正在使用相同MEX/DLL时重建。Vivado路径只在init中的 `AX01B_Vivado_Root` 设置。完整缓存、MEX、XSI及生成工程在仓库 `.runtime/ax01b/`。仅切换后端或查看模型不应重复运行初始化；**START_HERE明确重新加载文件中的参数，不能在运行/暂停中使用它刷新面板**。

## 手动对齐与各类复位

停止时设置 `Alignment_Enable=1`，`Init_Start=0`、`Init_Reset=0`。在允许电流调节的状态Run后，手动Start=1；观察原五态及Init_Done，完成后Start=0，Alignment_Enable保持启用以继续应用已取得偏置，Ready后再发送目标。保持RAMP_ID 10000拍、HOLD_ALIGN 30000拍、RAMP_DOWN_ID 2000拍、0.5 A；以100 µs仿真拍计约4.2 s。Alignment_Enable=0是旁路，不自动对齐；软件AutoStart与手动对齐Start不是同一输入。

PI_Reset是原控制复位请求，不能当运动启停按钮；有效复位仍受PWM禁止和对齐故障条件影响。PWM请求禁止逆变器输出，但机械模型继续运动。Init_Reset只复位原对齐；全局新Run、PI_Reset、Init_Reset和故障清除分别处理。原运动中断后保持参考、拒绝自动续段；清故障或释放PI_Reset不自动恢复原段。需要全新首段时Stop后新Run，不新增恢复框架。

## 三个模型的角色与区域

| 模型 | 用途 |
|---|---|
| Hybrid_ClosedLoop | 日常Run的完整反馈闭环，含电机/逆变器和操作面板 |
| R5_Runtime | Host/命令/轨迹、外环、原对齐的C代码生成入口；需顶层输入，不是独立电机闭环 |
| R5_Control | PR5组件来源，供研究与对照；其子系统曾复制进Runtime，二者没有自动同步的引用关系 |

保持原紫色分区：操作面板；轨迹/外环/参考管理/原对齐；100 µs调用与帧提交/50 µs应用；原逆变器/电机1 µs对象；Alignment_Interface；Motor_Control_Monitor。Runtime保留Host、Alignment_Task、Motion_Control。视觉区域不构成新的执行边界。

Hybrid输入Mux与Runtime的Demux均为分组宽度 `[11 3 1 1 1 1 1 1]`：**1:11命令，12:14 replay，15速度mm/s，16对齐使能，17 Start，18 Init_Reset，19故障，20位置mm**。前两路仍为向量，端口号不等于字段索引；两端有旁注。输出41字段保持原顺序，详见[接口](../integration/ps_pl/INTERFACE.md)。

SDI直接使用 `draft_target_mm`、`accepted_target_mm`、`x_ref_mm`、`x_mm`、`position_error_mm`、`v_ref_mmps/v_mmps`、`id_ref_A/id`、`iq_ref_A/iq`、`Ready/Busy/command_status`、`send_toggle`、`pi_reset_request/effective_reset`；面板同时显示backend与仿真时间。不要把草稿目标、接受目标与轨迹参考混作一条信号。

## 针对性复验

先按正常路径运行START_HERE，再执行所需工况；脚本不替代Dashboard实测：

```matlab
axu5ev_run_case('model_fixed','default');  % 原10mm/5s，普通Run参数
axu5ev_run_case('c_fixed','continuous');   % 同Run 10→0→−2mm，含Busy拒绝
axu5ev_run_case('c_fixed','reset_release');% 初始PI_Reset=1，在0.2s释放
axu5ev_run_case('c_fixed','reset_moving'); % 运动中PI_Reset=1→0
axu5ev_run_case('c_fixed','restart_short');% Stop后新Run的初态
```

脚本通过Dashboard实际绑定的常数输入在暂停点修改；结果在 `.runtime/issue8/`。旧 `scripts/ax01b_run_closedloop` 的1 mm工况只作PR7历史记录，不作为当前10 mm验收。实际结果见[Issue #8报告](../coordination/reports/issue8_manual_run.md)。所有结果均为主机功能仿真；R5目标执行、AXI、5EV综合/布线、ARM实测、烧录、功率级上电NOT_RUN。
