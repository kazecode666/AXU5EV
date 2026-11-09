# Issue40 — 统一模型与PL自动控制通路

基线为已合并PR39的 `origin/main ffaa5683322e2a485d96a23cc1b8a9e88fbcdb13`，独立分支 `codex/motor-control-chain`。真实实时路径为原ADC/QEP接收器→原生成电流/电角度→原p3 FOC→模型生成Q30比较值→原100MHz PWM。板级仍使用同一个motor_control工程；没有复制外设或手写第二套数值算法。

## 实际入口与数值来源

统一系统模型 `simulation/motor_control/AXU5EV_Motor_Control_System.slx` 实际连接完整数值链，通过 `motor_control_run(<新目录>)` 执行。Current_Preprocess和Encoder_Angle仍为原库链接，FOC是原固定点模型的Model Reference，R5旁路调用原位置/50间隔测速函数。外设接口及谷值保持标为SIM_ONLY，没有电机/逆变器plant、完整外环、Runtime或自动对齐。

用户当前共享库、ADC及主模型有本地修改，运行器在新目录从上述已接受Git基线取得原依赖，在隐藏独立MATLAB batch中运行；不保存用户模型，不改交互基础工作区参数。它是同一来源的受控依赖解析，不建立第二套公式。模型逻辑参考固定后移一帧消费完成的反馈；物理P128捕获与+50us采用由实际RTL验证，两种调度没有混称。

原FOC的29份生成设计SV及原帧壳直接复用，没有为统一排版重生成。唯一新数值算法为 `duty_to_compare.m`：unsignedQ30饱和到1.0，乘5000、half-up舍入，三路及事件共同寄存一拍；HDL由 `motor_control_generate_mapper` 生成，未手改生成物。

## 冻结、自动交接和观测

R5整组预提交九字段参考，下一选中ADC phase0采用，后续shadow写不污染冻结组。ADC/QEP在实际选样沿保持原身份管线；P110原电流/角度会合，P127加载九字段，下降沿壳保持后P128首次送入原FOC。原核一次启动、连续全5000使能拍，结果按原核frame_id识别，约P442可用；不把持续result_valid当脉冲，不停CE，不逐帧global reset/timing_restart。

三相经生成映射后交给原整组邮箱，在sample_tick+2500目标谷值采用。P2400尚未交接则取消并禁止；实际确认与采样ID关联，晚到不记作目标成功。自动模式静态选择，手动duty/许可提交被拒绝，原手动候选语义保留。失锁后旧arm不会自行恢复，须新参考版本或arm低/高。

无效帧用零电流/参考/角度/速度、48V和PI_Reset=1运行，但不提交结果；固定捕获后disarm/失锁/晚到只关闭PWM并取消在途组，不改本帧冻结输入。下一捕获若仍无效则复位PI，若已显式重臂且有效则按原状态连续递推。未加入通用防御/恢复框架。

新增MCT1/schema3为80字原子快照，前41字保留原单位，FOC输入ID/tick、参考版本、完整40位角度/速度、Q30 duty、比较值、提交/采用身份及晚到计数同帧发布。最后word79/0x148读响应释放；原写地址保留，读写空间分开。R5复用原生成位置/测速C与字段适配器，只提供明确TEST参考、配置与采集观察，不逐帧转发电流或计算duty。

## 直接相关的验证

- 系统模型实际运行55个逻辑帧/5.4ms，非零电流/角度、FOC阶跃、模型比较值与谷值保持、51项历史后的R5 speed_valid均执行。逻辑帧末尾不足一个完整PWM周期的情况不算完整周期验收。
- 最终RTL06同一输入事件表回到受控原电流函数20事件/280输出字、原角度函数19事件均一致；原固定点FOC单次连续仿真19帧/57个duty字与RTL逐位一致。联合唯一入口的实际which路径已记录，独立FOC验证壳显式约束根输入100us与求解步长，不改变FOC_DUT数学或状态。
- 新映射模型31组三相边界向量及实际生成RTL125检查通过，覆盖0/100%、超过1.0饱和与舍入边界。
- 完整合成ADC从接收器前进入，ABZ通过原同步解码；最终整链短RTL06共370245检查、19个FOC帧/19发布、9次目标谷值采用、9无效帧、18次峰值关联、9次整组三相核对、92386原核使能拍、1次晚到取消、1次失锁显式重臂及2项disarm优先级检查通过。包含参考阶跃/冻结、真实OTR、手动旁路拒绝与80字冻结释放。

独立复核发现，原 `0x1a4` 只置禁止但未取消已经冻结的arm，下一P0可能重新许可。新增RTL05在未修DUT上于1500.170001us明确失败；`bc52d7498e1c913166b496e626ebe5e0757ce061` 只在原phase8禁止命令分支增加清ref_pending，RTL06再通过。两项检查覆盖先commit后disarm跨P0、AW/W恰P0握手并按原phase8消费后保持禁止，只有后续新version8提交才重臂。没有修改数值、解码节拍或另加恢复框架。

`hardware_01` 因该问题在综合中主动取消，只终止核实属于本轮的batch及其子进程，项目/日志保留，不计最终实现PASS；新候选为 `hardware_02`。模型独立复核还修正了front比对的冻结依赖查找优先级及本轮新SLX端口/终止器的重叠，不改旧用户模型或算法。早期脚本日志采样失败、RTL04、RTL05及全部原始数据均保留。

hardware02初次集成发生filemgmt56-587模块发现失败，48份源路径存在且语法检查通过，fresh reopen在原自动模式可解析同一模块。入口改为包在前的一次完整源登记；原清单读取函数仅移到同一BD入口复用。冷启动 `source_entry_02` 在新结果目录的in-memory工程、独立空top下直接调用该生产入口，46份HDL、ADC/PWM两模块引用与AUTO参数/端口检查PASS，不做综合、不复制板级工程。随后只续建02尚未成功的integrate/build，原all失败日志及诊断日志保留，不重跑all。首个源诊断额外写出的根 `.srcs` 原位保留未入库，最终测试已隔离；没有为模块发现切换手动编译模式或修改DUT/XDC。

完整新候选、STA/CDC、SDF及匹配R5实际结果集中记录在 `verification/motor_control/results.json`；原始日志/数据保留于各自新 `.runtime/motor_control/` 目录。操作入口为 `firmware/r5/motor_control/FIRST_RUN_ZH.md`，生成/板级来源索引为motor_control README。

板卡发现/连接/下载/运行、驱动板/电机均NOT_RUN，physical_link_verified=0。内部PWM观察不是外部引脚实测；AQM数字测试尺度、48V和omega不是已恢复的完整AUM机械参数。真实标定、电平/缓冲/极性、完整外环/Runtime/自动对齐留后续。原电机/PI/电流公式及用户8个模型/参数修改、未跟踪文件、全部旧Workspace和原始数据保留；未重跑旧FOC全量回归。提交独立Draft PR后停在Review，不合并或关闭Issue。
