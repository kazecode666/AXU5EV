# M2独立FOC定点设计

## 转换前冻结：2026-10-24

源为本地最新PR49浮点FOC，PR50已合并1cab599。A在任何SLX改动前独立采集11个工况；B先抽取double、增加9th Vdc，并在除法前保护未选中零分母候选，108项严格迁移指标通过（duty≤1e-12，电压/状态≤1e-10）。原近似常数0.866/1.7321保留。详见[source](reports/m2_foc_fixed_point/source_acceptance.json)、[B](reports/m2_foc_fixed_point/interface_metrics.csv)。预算在定点实现前冻结于[contract](reports/m2_foc_fixed_point/acceptance_contract.json)，属于工程验证目标，不是硬件额定指标。

## 范围的四种依据

| 项 | 硬件/物理资料 | 当前配置 | 已有观察 | 首版工程验证范围 |
|---|---|---|---|---|
| 相电流/参考 | 硬件说明/YXPHM-MDBL4电机驱动板硬件说明书p1—2称12A额定；不是电机额定/完整采集链合同；p14过流约+27/-29A为保护阈值 | 速度环输出±1A，手动参考无同一全局钳位；对齐.5A | M1B及A保存波形，不能当最大值 | 相电流各±2A；id/iq参考各±2A。算法向量可不平衡，单独标注 |
| 母线 | 说明书p1输入12—60V，p2另列12—80V且额定60V；p15过压阈60V，资料有差异 | 默认48V | 默认均48V | [12,60]V，受限仿真范围，不据此批准实机60V |
| 控制电速度 | 未找到电机额定/最大速度确定记录；旧DSP标度不等于物理极限 | 位置速度限幅20mm/s→2.0944rad/s | A正负速度/闭环场景 | ±100rad/s，附显式输入条件 |
| 角度 | 真实采集/安装偏置不是本轮范围 | 控制角与真实角独立，rad | A含原标称对齐 | ±8π rad，含负值、0/2π及多周期边界 |
| 初态/时长 | 无无限时长硬件证明 | 原FOC积分/AW初值0，100µs更新 | A最长日常5s/对齐4.5s | 零状态起点、声明输入范围、60s序列；另做递推界，不宣称所有参数/硬件无限鲁棒 |

源PDF已用本地pypdf提取文本留.runtime，M0索引和实际init参数交叉核对。电机额定电流、速度、驱动持续过载/热限制、ADC硬量程仍待后续资料签定。没有要求用户重填已存在信息，没有沿用旧24bit/2500。

## 运算位增长和状态界

相电流各|i|≤2，则Clarke |alpha|≤8/3，|beta|≤4/√3。正交Park的轴界保守取 sqrt((8/3)^2+(4/√3)^2)；现有线性LUT插值位于单位圆弦内，量化小余量另由宽类型及测试覆盖。误差界 E=2+轴界，电压前馈界 F=100*(max(Ld,Lq)*轴界+psi)，圆输出界 U=.9*60/√3。原输出u_raw=Kp*e+x+ff，没有用圆限幅替代状态范围。

无复位时每轴 x[k+1]=x[k]-a*x[k-1]+b[k]，a=Kaw∈(0,.25]，b=KiTs*e[k]-a*(Kp*e[k-1]+ff[k-1]-u_lim[k-1])。零初态下特征根在(0,1)，脉冲响应非负且绝对和1/a，因此连续段界 S0=KiTs*E/a+Kp*E+F+U。控制复位优先将输出和次拍积分置0；AW延迟仍按原raw-minus-limited更新，不额外清零。复位后保留的前拍状态贡献齐次响应最多a*S，因此任意复位段保守界采用 S=S0/(1-a_max)，而不是假设AW也清零。配置函数从实际参数计算state/raw/square界；非当前Kaw条件明确拒绝。该界针对理想算术，固定类型实际另有宽存储余量和60s递推测试，不声称已形式化证明所有重调参数和无限时长硬件鲁棒性。

数据增加/乘法/平方先保证足够整数位，输出量化点明确收敛舍入。Work为64bit/40小数位，状态存储没有算法硬钳位；Square无符号64/36，最小epsilon=1e-6量化后非零。未限幅比例U/(sqrt(sum)+epsilon)在零电压时可达约3.12e7，因此单独用无符号72/40，不以随后min(1)掩盖中间溢出。

## 类型和系数单一来源

`cfg=pmlsm_foc_fixed_config(p)`，p显式来自当前Rs/Ld/Lq/psi/Kp/Ki/Kaw_d/q/Ts/Udc。配置含Types、TypeStrings、Coefficients、Ranges、Version和Convergent/Saturate fimath；不加载旧参数。所有系数从现有值一次量化，含Ki*Ts、原0.866/1.7321、epsilon及-2/T_pwm。

[实际类型表](reports/m2_foc_fixed_point/types.csv)、[系数量化表](reports/m2_foc_fixed_point/coefficients.csv)、[推导界/配置验收](reports/m2_foc_fixed_point/types_acceptance.json)。Duty无符号32/30，0、.5、1精确；算法输出限幅与数值表示饱和分开，范围内数值饱和/溢出目标为0。输入负例在测试/边界明确诊断，不新增完整保护系统。

## 后续实际实现映射和结果

完整定点通路保留原Gain/Sum/Product、PI和5个UnitDelay；原向量Fcn分解为显式Demux/Gain/Sum，圆限幅保留Sqrt/Divide/MinMax。新增三路显式DTC只编码无符号command duty；不是只将浮点输出量化。Clarke、Park、dq PI/前馈、圆限幅/AW、反Park和SVPWM的活动编译端口全为fixed/integer/boolean，DataTypeOverride=Off。

Park/InversePark继续用同一Motor Control Blockset库的固定类型实现、同一1024配置和原rad包角/插值，不改成另一套三角算法。库内部类型由输入Angle类型派生，实际逐端口见compiled_types.csv；其内部Simplest/indexing Floor沿用库语义，不以未使用的自定义Trig/Phase类型冒充实际采用。外围缩位Convergent，唯SqrtBitset经实际checkhdl证实不支持Convergent，改为Floor、量子2^-40 V，单列工具适配；不加周期延迟。

12000拍种子20261024有界向量：三相duty总max差2.883e-7，限幅电压max差7.159e-6 V；入口量化与已量化输入的内部误差分别列unit_metrics.csv。扇区差0，PI递推最大残差一个Work LSB=9.095e-13 V，前拍AW残差0。12/24/60 V各6000拍通过；60 s/600001拍、1个电流LSB误差积分到.042378815 V，递推差0，未发生意外溢出/饱和。全分支有限，负例在量化前明确拒绝。不是仅短波形证明无限时长。

共享模型使用官方convertToVariantSubsystem形成停止后Float/Fixed选择；原FOC仍为内层8输入参考，新定点经Normal Model Reference唯一引用。引用模型须FixedStep=auto、SampleTimeConstraint=STIndependent且所有输入继承；调用者的100us function-call决定更新，同拍算法没有新增UnitDelay。独立向量测试仅显式给100us仿真调度，不改数据类型。原已量化系数KiTs仍来自当前100us参数；这不是任意周期可运行声明。

没有HDL/C生成或Vivado授权。最终兼容性、共享闭环与局部布局另见整合报告；M2同拍数值完成不证明FPGA单时钟周期可完成。
