# PR53 p3 时序合同

当前M3核心门禁通过，等待PR53 Review；机器合同为 [cycle_contract.json](reports/m3_foc_hdl/cycle_contract.json)，逐态映射为 [state_mapping.csv](reports/m3_foc_hdl/state_mapping.csv)。首轮B3仍是失败历史，274拍和WNS−58.833ns不适用于当前p3。

## 时钟、输入与输出

器件xc7a200tfbg484-2，目标50MHz/20ns，控制100us/5000拍，PWM应用边界50us/2500拍。九路输入在第1拍前的negedge建立，一直保持到第5000拍后才整体换新。没有共同九路捕获寄存器，没有原生frame-valid；ce_out是快时钟CE。外围捕获/valid/提交适配没有实现，不能把文档约定称为已交付接口。

三相均在accepted post-edge314观察，理想20ns算术为6.28us；初始两拍global reset不计入accepted相位，所以正常首输出绝对物理拍为316。输出提交预留1拍且至少还留1拍裕量：314+1+1=316≤2500，提交后余2185拍/43.7us。该预算不是完整板级物理deadline证明。

## PI/AW状态事件

原100us算法Unit Delay、PI系数、舍入/饱和和前拍AW不改。Id/Iq原旁路之后增加一个快寄存器，实际观察点x_d/q_z_out1提交在下一帧post-edge1；D输入为x_d/q_z_out1_1。原旧态消费仍在本帧pre-edge5000，必须消费相同原前态。AW观察提交同为下一帧post-edge1。每个active edge的D输入、保持、CE和同步reset均检查；不是平移golden掩盖递推错误。

源/gm四态仍为sfix64_En40，实际日志100us；gm RateTransition SID依次546/406/480/479。17帧下一态68值逐位相等，17/1024/1536全部输出与旧态18039值逐位相等。第一次p3沿用旧post5000提交映射的27状态/31协议错误原样保留；p3q只是同一硬件的资格合同修订，最终全部门禁绑定新manifest。

## 复位、CE与负例

global reset同步高有效，优先于CE；reset_FOC_DUT_tc正常固定0，TC复位为两者OR。单独额外复位脉冲没有验证。PI_Reset_EN只是九路数据之一，不复位调度器或无条件清AW。gm没有硬件reset/CE端口，只承担正常初始化数值基准。

RTL验证冷启动、计算中global reset、重放、单帧/持续PI复位以及21物理边沿CE暂停。CE最大墙钟输出325拍仅为诊断，不重定义正常deadline。1bit错误与真实变化帧提前第313拍观察均被严格运行器非零拒绝；不丢弃任意启动帧，四分母全程禁止0，IntegerOverflowMsg仍为error。

## 物理预检与边界

同manifest实际OOC：WNS+5.317ns、WHS+0.135ns，TNS/THS均0，setup/hold失败端点均0；内部无时钟/未约束、latch/blackbox/组合环均0。70983LUT、83278FF、439DSP、0BRAM。最差路径rd_11匹配寄存器→XYZ DSP，数据14.235ns/26层；92个DSP启用PREG，MREG仍0。

这是综合后、布线前的核心估算。外部I/O未签核，保留276输入/96输出缺少delay和HD.CLK_SRC未设置警告；未运行place/route、RTL电机联合仿真、bitstream、硬件或M4。原始报告、首轮失败和重构建身份见 [本轮结果](reports/m3_foc_hdl/pr53_pipeline_revision/acceptance_result.json)及 [续办报告](../coordination/reports/pr53_critical_path_pipeline_revision.md)。
