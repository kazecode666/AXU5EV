# AX-03B1：独立无功率反馈观测链

日期：2026-11-05；仓库`kazecode666/AXU5EV`，分支`codex/ax03b1-feedback-observer`。依据[Issue28](https://github.com/kazecode666/AXU5EV/issues/28)，从包含PR27的`origin/main` `d3a10cf627b55984c16fc58a5e6d56b991ea27a5`实施。执行边界与实际入口见[本轮任务记录](../tasks/ax03b1_feedback_observer.md)。本轮只实现反馈观测，不接控制Runtime、FOC或真实PWM；现有电机/PI、模型、旧回放与所有实验数据保留。

## 1. 结构和运行入口

新独立模型为`simulation/AXU5EV_RealIO_NoPower.slx`。数值预处理源在`simulation/real_io/`，经新模型HDL生成，部署RTL位于`generated/ax03b1/`；同步/采集与只读封装在`integration/rtl/ax03b1/`。测试外设和激励仅在模型验证/测试平台，不作为外部ADC/读头的真实性证明；不含部署电机plant或第二套PL速度状态。

逻辑链：抽象双ADC采样事件/同步后ABZ位置历史 → 七个转换事件后的原始返回码/OTR/捕获资格 → 模型生成的两相数值处理 → 带采样身份的整帧观测 → 独立AXI-Lite只读冻结接口。`ax03b1_observer.sv`将这些模块连接，并将PWM六路、ENCON、RELCON、F_Reset、run_permission全部固定为0；没有任何状态能够产生功率运行许可。

离线模型入口（MATLAB MCP）：`addpath('D:/Project/AXU5EV/simulation/real_io'); result=ax03b1_run_no_power(false);`；将参数改为`true`会重新生成新增数值DUT的两份SV，不运行旧模型/FOC。独立源码/模型的路径、缓存设置在入口结束时恢复，不关闭用户模型；只有新模型被保存以记录HDL设置。模型20字段视图是离线示例，板侧32字payload布局见第4节，不把示例视图当完整总线协议。

离线RTL入口：`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/ax03b1_run_rtl.ps1 -Suite all`，使用本机`E:/AMDDesignTools/2026.1/Vivado/bin`的xvlog/xelab/xsim，仅编译新增链路。每次使用新的`.runtime/ax03b1/rtl_<id>/`，存在目录拒绝覆盖，无删除操作。模型/生成与验证结果在第6节记录。

## 2. 仿真假设、采集和位置时间

以下全部是`SIM_ASSUMPTION`，不是硬件签核：单50 MHz逻辑域；5 MHz抽象转换/捕获事件（每10个逻辑拍）；双独立12位并行offset-binary；七转换事件流水线；每5000个逻辑拍选择一帧；ABZ二级同步后稳定2拍滤波。示例无返回DCO、IODELAY、板级输入/输出延时或最终XDC，不规定实板捕获沿。原物理5 V ABZ出口仍须转换，不可把逻辑输入测试当成已允许直连。

`ax03b1_an9238_pinmap`只对抽象40针向量做组合位序转换：CH1的D0..D11对应20/19/22/21/24/23/26/25/28/27/30/29，OTR32；CH2 D0..D11为4..15，OTR16。不绑定封装脚、电源或模块插接方向；没有生成板级约束。

`ax03b1_adc_receiver`在事件E0保存`sample_id`、选样位及位置/时间元数据，在E7关联外部当次返回码/OTR/捕获资格；启动E0..E6不出有效返回。选定事件每次返回都发pair_strobe，包括单路无效或OTR帧；不会拼接另一旧通道。capture_valid_a/b是测试/未来采集适配给出的整字资格，pair_complete仅两者AND，OTR另列。自增ID和恒定码都不证明外部ADC存活；没有基于“码不变”的掉线判断。

`ax03b1_abz_receiver`按00→01→11→10→00加计数，反向减，32位模回绕。初始稳定AB只建立相位，不产生虚假一步；双位跳变累计illegal_count且不猜方向；稳定滤波拒绝短毛刺。Z的过滤上升沿只保存计数/时间、置z_seen，不清连续位置；初始Z高不伪造上升沿。AB和Z同一接受沿时，Z保存该沿AB更新后的count；ADC采样事件同沿读取ABZ注册输出时，保存更新前快照，下一个逻辑沿才看见新状态。同步/滤波和采样边界均有延迟，未声称零延迟物理位置。

元数据在模拟采样事件保存，并随七转换事件传递；不是数字码到达后再读取最新位置。模型中的ABZ行为参考接收理想已同步信号，不以该理想参考代替薄RTL同步/滤波测试。未实施位置mm换算和PL速度状态；AQM30 mm/1 μm目标保持，最终物理mm/count需已知位移验证，原100 μs历史50点=5 ms的后续R5速度语义不改。

## 3. 两路预处理和校准合同

每相输入原始uint16码（有效范围0..4095），offset为signed int32中的code-Q16，gain为signed int32中的A/count-Q24。参数由显式config_apply原子锁存，独立手动seed有效位只用于明确来源的配置；不是实测标定已完成声明。名义带载约0.0613680753 A/count与零流2659.0669可作测试配置，运行还验证不同offset/gain和反向符号，不写回任何AQM/AUM初始化参数。

新两相校准使用各自sum/count/done；只有该路捕获合格、码在范围且OTR=0时计数，不依赖第三ADC。N=2^cal_log2_N（0..10，名义1024；短窗口用于显式测试）。cal_en=0暂停并保持，完成后该相不再继续漂零；cal_restart显式清count/done、保留offset/config，下一批重新校准。自动完成当拍不产生数值有效帧，下一合格样本才采用新offset。config_apply优先于restart/样本，不计碰撞样本；发生碰撞时仍输出result_strobe、数值invalid/0、error bit8，保留原码/元数据供观察，不静默丢帧。cal_version随restart或每相新offset提交模2^32递增，同拍两相可增加2；config_apply按调用方提供版本重标，不能据此推断跨重启永久唯一身份。

计算在int64内进行`(raw*2^16-offset_q16)*gain_q24`，为Q40中间值；合法seed范围0..4095×65536使乘积/双路运算有静态上界。每路以半偶收敛舍入转到宽Q24，再对**尚未夹限**的两路宽结果求和/取负得到c；a/b/c最后各自饱和到signed32/Q24。中间至少满足34位求和/取负需求，不从已饱和a/b反推c。无clip时c_q24精确等于-(a_q24+b_q24)，但零和是重构恒等式，不能当独立传感器诊断。

invalid帧保留raw/OTR/元数据，数值置0且valid=0；clip帧输出饱和值但clip=1、valid=0。error bit0/1为A/B捕获或码范围错误，2/3为OTR，4/5为A/B未校准，6为配置无效，7为算术clip，8为config/restart与样本碰撞。result_strobe覆盖每个已处理样本（包括invalid/clip/碰撞），与数值、offset、校准状态、版本及error统一生成延迟；这些字段不能当有效电流环许可。物理零流条件、偏置质量/噪声阈值、真实增益/极性仍PENDING。

## 4. 原子只读接口与字段

独立模块`ax03b1_snapshot_axi`，相对字节偏移，不指定任何PS板级基址，也不改PR24寄存器。所有producer/AXI信号同一逻辑域，不是CDC原语。

| 相对偏移 | 语义 |
|---|---|
| 0x00 BEGIN | 冻结当前完整latest bank并返回uint32发布seq；没有发布则SLVERR |
| 0x04 | 冻结的调用方session epoch |
| 0x08 | 冻结头flags：bit0观测存在，bit1复位后首发布，bit2已发生seq回绕；不是ADC质量位 |
| 0x0C+4n，n=0..31 | 冻结payload；可重复/乱序读，中间字段不换帧 |
| 0x88（payload31） | 最后一个响应被RREADY接收后释放会话，因此须最后读它 |

单个outstanding，R背压时RDATA/RRESP/RVALID保持，ARREADY=0。BEGIN与publish同沿取更新前完整latest；再次BEGIN显式重捕。未BEGIN、未知/未对齐地址返回SLVERR，不输出伪造有效帧。复位取消响应、清latest/冻结bank、seq重新开始；epoch随publish一起锁入，调用方必须在需要区分的重启后换session标签，RTL不伪造持久boot计数。详见`verification/ax03b1/snapshot_protocol.md`。

| payload词 | 类型/单位/内容 |
|---|---|
| 0/1 | identity=0x42314F42（B1OB）/schema=1 |
| 2 | quality：bit0/1 capture A/B；2 pair_complete；3/4 OTR A/B；5/6 cal_done A/B；7 numeric_valid；8 clip；9 z_seen；10 ab_ready；16 SIM_ASSUMPTION=1；17 physical_link_verified=0 |
| 3 | uint32 ADC事件sample_id（包括未选事件的编号间隔，允许模回绕） |
| 4/5 | uint64采样逻辑tick，低字在前；与position历史同一事件 |
| 6/7 | uint32承载原始12位A/B码 |
| 8/9/10 | signed int32 A/B/C，Q24 A |
| 11/12 | signed int32 offset A/B，Q16 code |
| 13/14 | uint16 cal_count A/B，零扩展 |
| 15 | uint32 cal_version |
| 16/17 | uint32连续AB count/Z锁存count，无mm换算 |
| 18/19 | uint64 Z事件逻辑tick，低字在前 |
| 20/21 | uint32非法跳变累计/error uint16零扩展 |
| 22/23 | 电流/offset小数位数24/16 |
| 24..27 | ADC流水线事件数7、SAMPLE_DIV、OBSERVE_DIV、FILTER_CYCLES |
| 28..31 | 保留0；读31触发会话释放 |

数值全部14路输出固定一级寄存，adapter CE恒1，不增加运算；snapshot在pair返回后第2个逻辑拍采结果。顶层参数约束OBSERVE_DIV≥8且为SAMPLE_DIV整数倍，默认5000拍；receiver一组返回字段保持到下一选定返回。集成测试在20拍选样及最小8拍选样下验证sample_id/tick/原码/位置/Z历史与数值发布一致，并让32字读取跨过多个后续publish，要求返回冻结旧帧。测试缩短间隔是SIM配置，非实物时钟选择。改变生成流水线后须重核此界限，不能任意增加HDL latency而仍复用当前meta保持合同。

## 5. 安全与未实现范围

顶层gate_pwm六路、encon、relcon、fault_reset、run_permission均为常量0，测试每个逻辑拍检查。这里的0只是新观测模块数字输出，不是对驱动板最终门极极性/掉电安全的签核。没有接FOC、PWM时基/死区、R5控制Runtime或任何电机plant部署；无控制写寄存器。G1—G8仍按AX-03A报告保留：模块模式/电气/物理精度/额外负载、ABZ读头尺度、电平转换/OE/掉电隔离、外部母线隔离、完整参数恢复、FOC/R5命令/50 μs采用另行Review。

## 6. 本次验证与停止点

以下均为本轮新增链路实际运行结果，不移用旧PR24实板PASS。MATLAB为本机R2026b Update1，RTL为Vivado Simulator2026.1；没有运行旧控制模型/FOC回放。

| 层级 | 本次实际结果 | 范围 |
|---|---|---|
| MATLAB独立数值/状态参考 | PASS，42项 | 独立gain/符号/小数offset、正负half-even、校准暂停/重启/坏样本、版本回绕/碰撞、重构/饱和 |
| 新Simulink模型 | SIM_PASS，4条唯一观测 | 转换ID0/500/1000/1500、采样位置历史、未clip三流Q24一致；ABZ理想参考不替代同步/滤波RTL |
| 新数值HDL生成 | PASS，2份SV，0 error/0 warning | 只生成Current_Preprocess/Numeric_Algorithm，全部输出1拍 |
| ADC/ABZ薄RTL | PASS，1341项、38条选定返回 | 4条捕获无效、5条含OTR、38条位置历史、采样与AB接受同拍；位序/七event/启动/reset、2/3拍filter、正反/Z/非法/毛刺/上下回绕 |
| 原子只读快照 | PASS，32字81项；参数40字89项 | 跨发布读取、顺序/重复/非法地址、R背压/AR阻塞、seq回绕、epoch冻结、reset取消响应及invalid质量帧 |
| 生成数值RTL独立向量 | PASS，25项 | RTL与独立精确Q24期望一致；包括正常值、正负ties、INT32极值/c扩位、1024样本/最大累加值、自动校准/版本及config/restart碰撞；恒码不误判掉线 |
| 接收→数值→总线整链 | PASS，508项/13次发布；最小间隔580项/25次发布 | 两路不同系数/反向符号、原码/采样位置/Z时间/ID与数值一致，各含2次invalid发布，冻结读取跨多个新发布，所有拍输出许可固定禁止 |

上述25/508/580项由统一RTL入口的`current`、`observer`、`observer_min`套件执行；输入/快照套件也可分别选择`inputs`/`snapshot`。[精简综合证据](../../verification/ax03b1/results.json)记录实际PASS marker与日志位置，[模型最后一次运行](../../verification/ax03b1/model_results.json)为20字段扩充后的model-only运行，因此其hdl=NOT_RUN不覆盖此前已完成的数值生成；两阶段在综合证据中明确区分。完整编译/仿真日志留`.runtime/ax03b1/`。

**生成差异已闭环：** 首次正常小电流RTL测试揭露HDL Coder将`int64(-2147483648)`下界折叠成64位比较中的负32位常量，导致误饱和；第一次改写常量仍被折叠。最终在MATLAB源用精确等价的`bitshift(x,-31)<int64(-1)`检测低于int32下界，重新生成后为安全64位移位/比较。原失败日志保留于`.runtime/ax03b1/current_final_03/current/`，最终同一向量及极值测试通过于`current_final_04`；入口加入针对该已知错误生成形式的拒绝检查。没有手改SV、修改Q格式或放宽判据。模型仿真/生成成功单独不足以证明RTL数值等价，这次实际RTL检查已覆盖该差异。

只执行新增模型/生成与RTL行为验证；板卡发现/连接/寄存器访问/复位/下载/运行均NOT_RUN，板级XDC/STA/物理CDC签核、综合、布线、bit/XSA/新Vitis工程均NOT_RUN。完整AQM参数/PI恢复和AX-03B2未启动。

完成后提交关联Issue28的Draft PR，更新当前交接并停止，等待ChatGPT Review和用户下一步指令，不自动合并或关闭Issue。
