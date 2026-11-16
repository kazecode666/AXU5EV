# PWM cut 静态只读审核

## 结论

**Task1结构审核可接受进入局部SDF仿真；不是仿真PASS，也不是完整原RTL功能覆盖。** 必须保留以下明确限制：fast_inhibit在原交接routed设计已经无有效连接，在cut也无fanout，不能通过驱动此端口验证快速禁止。若验收强制要求该独立输入动态覆盖，则本cut不能满足该项，不得以auto_inhibit替代并声称通过。未编辑网表/SDF，未启动Vivado或仿真，未做哈希；仅新建本记录。

## 数量与关键逻辑

对[单元清单](<cut_cells.tsv>)全部1204行统计：FDCE=272、FDRE=297、FDPE=1（共570 FF），LUT1/2/3/4/5/6=2/13/35/33/86/123，CARRY8=14，GND=4、VCC=4。

- frozen_compare_reg、pwm/pending_compare_reg、pwm/active_compare_reg分别39位；三组对应seq分别32位。adopted_compare另39位、adopted_seq另32位，未发现单相切割/缺位。
- auto_release、reset_release分别2个FDCE，实际均IS_C_INVERTED=1、PWM下降沿两级释放；见[网表](<pwm_cut.v#L1153-L1189>)及[reset_release](<pwm_cut.v#L3336-L3371>)。
- request_reg=1；request_pipe、accept_pipe、apply_pipe、online_pipe各2位；busy及accepted/applied/pending保留。
- 时基phase=14个FDCE、started=1个FDCE、anchor_delayed=1个FDPE。见[时基清单](<cut_cells.tsv#L1189-L1204>)，交接[RTL](<../Issue40_PWM_Cut_Handoff/hardware/axu5ev/motor_control/rtl/pwm/pwm_timebase.sv>)为PERIOD=10000、PEAK=5000、起始4997、新anchor上升沿启动。
- 三相每相wait_h/wait_l各16 FF、last_h/last_l各1 FF、high_o/low_o各1 FF；总192个计数FF、6个last FF、6个输出FF，enabled另7 FF。整组三相死区结构保留；数值规格交接[三相RTL](<../Issue40_PWM_Cut_Handoff/hardware/axu5ev/motor_control/rtl/pwm/pwm_three_phase.sv>)为每方向100 PWM拍=1000ns。静态结构不等于已动态证明死区。

## 接口与可驱动性

[实际端口](<pwm_cut.v#L22-L92>)包括pwm_clk、s_axi_aclk及s_axi_aresetn，另两根转义reset边界peripheral_aresetn[0]_bufg_place与其replica，见[pins](<pins.tsv#L210-L213>)。它们不是新增独立振荡器；replica参与ready/online及auto/reset_release，非replica在本cut中无内部消费者。结合原reset语义及AXI ready逻辑，将两者与s_axi_aresetn同极性同波形驱动是合理局部环境建模，不能保留为X/悬空，也不代表覆盖外部reset缓冲延迟。未发现关键compare/握手/死区逻辑被外移而需force内部状态才能实现。

[clocks](<clocks.txt>)给出clk_pl_0=20ns，PWM为乘2生成时钟，但生成PERIOD/MASTER_CLOCK字段为needs timing update；不能把这份文本当作新STA证明。按交接相关50/100MHz、2:1关系驱动20ns/10ns即可；外部MMCM、时钟树及跨切点上游互连延迟不在覆盖内。

**debug不能套用原RTL128位布局。** [pins](<pins.tsv>)明确实际debug_o[96:0]：
- [5:0]六路输出，[19:6]phase，[20]valley，[21]peak；
- started_reg、accepted_reg、pending_reg分别是原debug[22]/[23]/[25]独立输出；
- debug[22]=applied（原24），[25:23]=high_request（原28:26）；
- debug[57:26]=active_seq（原67:36），debug[96:58]=active_compare（原106:68）。
- 原permission调试位经过别名/优化，不是实际debug[35:29]；auto_inhibit_i本身别名原debug[35]。AXI bresp/rresp仅导出一个非常量位，另位已优化，不能用原RTL端口宽度盲接。自动模式AXI手动数据端口已优化，局部激励须用auto_*接口。

## fast_inhibit限制的来源

[cut网表](<pwm_cut.v#L2509-L2518>)下级fast_inhibit接NLW未连接网络，顶层fast_inhibit仅声明，三层均无逻辑消费者。原[全网表](<../AXU5EV_Issue40_20261110/AXU5EV_Issue40_SDF_hardware_02_0bd081a/inputs/hardware_02/timing_pl/motor_routed.v#L824009-L824028>)在pwm_control_0实例已经.fast_inhibit(NLW_pwm_control_0_fast_inhibit_UNCONNECTED)，因此不是本次切割新丢失。auto_inhibit_i、locked真实有fanout，可检查取消、禁止、失锁、恢复及重新许可；不得将这些替换行为称为fast_inhibit覆盖。

## SDF静态层级核对

分段读取[网表](<pwm_cut.v>)与[slow](<pwm_cut_slow.sdf>)/[fast](<pwm_cut_fast.sdf>)全部文本，递归展开pwm_cut -> pwm -> timebase的实例名，按Verilog转义标识符及SDF反斜线转义规范化。

两角各1197个CELL：1196个非恒量原语与1个空INSTANCE根pwm_cut；每角4433个INTERCONNECT。1196非根CELL的INSTANCE路径和CELLTYPE全部与实际网表匹配，未发现明显路径/类型错配。1204与1196相差8是GND/VCC恒量单元，非8个关键单元丢失。SDF DESIGN=pwm_cut、DIVIDER=/、TIMESCALE=1ps，与网表一致。

这是静态实例/类型一致性检查，不是仿真器实际注释成功；还需xelab/xsim证明interconnect和timingcheck实际注释，并保留原生时序检查。不得据本审核宣称FULL_CHAIN_SDF或上游FOC/ADC内部时序通过。
