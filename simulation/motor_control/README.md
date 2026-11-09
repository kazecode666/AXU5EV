# 统一电机控制数值入口

打开 `AXU5EV_Motor_Control_System.slx` 查看并跟随实际数值路径：

`SIM_ONLY_ADC_QEP_References → Current_Preprocess / Encoder_Angle → Same_Frame_Hold → Accepted_P3_FOC → Generated_Duty_Compare → SIM_ONLY_PWM_Valley_Hold`。

旁路的 `R5_Position_And_50Interval_Speed` 调用同一个 `encoder_position_speed.m`，只在新帧事件推进历史，输出在两帧间保持；完整外环/Runtime与自动对齐未接入。

在 MATLAB MCP 中执行唯一运行入口：

```matlab
addpath('D:/Project/AXU5EV/simulation/motor_control');
motor_control_run('D:/Project/AXU5EV/.runtime/motor_control/<新目录>');
% 同一实际RTL帧表的模型比较（目录中含 current_events/angle_events/foc_frames.txt）：
motor_control_run('D:/Project/AXU5EV/.runtime/motor_control/<另一个新目录>', ...
  'D:/Project/AXU5EV/.runtime/motor_control/<RTL结果目录>');
```

默认同步等待；第三参数false仅用于异步启动，结果必须以新目录的JSON状态判断，不能把RUNNING视为PASS。运行器通过MATLAB原生.NET进程接口隐藏启动独立 `-batch` 进程，保留交互进程的模型、基础工作区及用户参数。它从包含PR39的固定基线 `ffaa5683322e2a485d96a23cc1b8a9e88fbcdb13` 获取同名受控依赖到本次新目录，记录source_relation.json，不覆盖用户磁盘模型，也不建立第二套公式。

这是必要的真实来源隔离：用户现有Current共享库与ADC壳有本地修改。系统SLX仍引用原 `AXU5EV_PL_Algorithm_Library/Current_Preprocess` 和 `AXU5EV_Encoder_Components/Encoder_Angle` 库链接，FOC是原 `baselines/pr53_p3/source/PMLSM_FOC_FixedPoint.slx` 的Model Reference。独立进程解析这些已接受的依赖；没有让部署暗中使用交互进程的未审查模型。直接在用户原会话按Run可能解析当前用户修改，不能当作本轮接受的复现结果。

系统模型每20ns运行电流/角度组件，并在事件处保持同帧反馈。原FOC数学模型保持原100us采样及原PI/AW状态，以完整连续仿真运行；ZOH在下一个逻辑帧消费已完成反馈。因此系统模型的FOC帧表比ADC采样表固定后移一帧，端口sample_id/reference_version用于对齐，绝不把这一个SIM_ONLY参考调度延迟宣称为真实PL延迟。实际板级通路在采样后P128捕获输入、目标谷值采用，完整5000使能拍与实际跨频由RTL/SDF验证。

无效反馈也推进完整FOC帧，九字段明确使用零电流/参考/角度/速度、TEST48V及PI_Reset=1；与RTL捕获策略一致。送往SIM_ONLY谷值保持的许可使用与FOC相同100us边界冻结的valid，避免用下一帧刚更新的许可采用上一帧数值。

仿真输入为明确SIM_ONLY数字例子：原码2000/2100经4帧校准后阶跃到2010/2090；有效解码count固定4、手动相位偏置7500、omega=0，符合静止反馈。预提交IQ从0阶跃到0.1A，母线为TEST48V。没有电机/逆变器plant，没有假称机械闭环。电流/角度Q位串先除以2^24/2^32，再转换到原FOC的精确定点类型；FOC的fi duty先还原成Q30整数位串，再进入生成的比较尺度组件，不能把0..1直接cast成整数。

`motor_control_system_batch` 验证实际非零电流、角度、FOC输出、三相比较值与谷值保持，以及51项历史后的speed_valid；CSV中速度为静止0是显式测试条件。PWM行为块只做SIM_ONLY三相谷值保持，未模拟真实互补边沿/死区，不能代替真实RTL外设测试，也未重复叠加平均死区。

## 单源/生成索引

| 修改对象 | 权威入口/边界 |
| --- | --- |
| 电流零偏与换算 | 原 `simulation/real_io/ax03b1_current_preprocess.m` / Current_Preprocess，未改；原 `simulation/adc/adc_generate_hdl.m` 为独立生成入口 |
| 电角度 | 原 `simulation/encoder/encoder_angle_step.m` / Encoder_Angle，未改；原 `encoder_generate_hdl.m` |
| FOC/坐标变换/PI/SVPWM | 已接受p3固定点模型与 `baselines/pr53_p3/codegen/candidate.json`；`simulation/axu5ev_build_pl_target.m` 是独立batch目标生成入口。本轮复用原生成RTL，未调用或重生成；冻结包仍保持原样 |
| Q30→比较尺度 | 唯一新数值源 `duty_to_compare.m`，模型 `AXU5EV_Duty_Adapter_HDL/Duty_To_Compare`，`motor_control_generate_mapper(new_dir)` 生成两个SV |
| 位置/50间隔测速C | 原 `encoder_position_speed.m` / `encoder_generate_c.m`；已生成目标C直接复用 |
| ADC/QEP/PWM/AXI/跨频 | 同一motor_control源清单、手写RTL与BD，不由系统SIM_ONLY块生成 |
| 板级/R5构建 | 新统一构建入口和匹配Workspace见HANDOFF及本轮操作说明 |

新映射公式只在MATLAB源中：unsigned Q30先饱和到1.0，再round-half-up到0..5000，三个uint16输出及result_strobe共同寄存一拍。31组模型向量含0/100%、溢出与量化决策边界；由实际生成RTL另行对比，不手写RTL换算公式。

`motor_control_compare_foc` 在一个连续原固定点模型仿真内消费实际冻结的九字段帧表，保留跨帧PI/AW递推，按精确100us时刻输出并对比三相Q30位串；不逐帧重启模型。`motor_control_compare_front` 把同一RTL事件表逐行送回原电流函数与原角度串行函数（包含显式reset标记），不用另一套生产算法。

独立FOC参考的测试壳通过SimulationInput将九个根Inport的SampleTime明确为100us、关闭输入插值，并将SampleTimeConstraint临时设为Unconstrained及FixedStepDiscrete=100us。这样消除原继承端口加auto步长的欠约束，得到精确的逐帧日志；原FOC_DUT、PI/AW递推和冻结SLX均不修改、不保存、不重新生成。只接受时间点逐项一致后的Q30位串比较，不靠插值或截取尾部匹配。

前端比较也将本次`dependencies`目录放在路径首位；运行日志及结果JSON记录`which`解析的两条权威函数绝对路径，并断言它们确实位于本次受控目录。系统SLX和映射组件的各个新建层级另做端口连线及块重叠检查；仅排版不触发旧数值回归。

所有源未改变的模块仍使用原生成入口及设置；Current/Angle与p3的Oversampling/内部调度不同，不要求一次makehdl生成全部组件。以后修改组件时必须重新生成对应边界、重新做其定向对比，不能只改SLX说明而继续部署另一份旧算法。
