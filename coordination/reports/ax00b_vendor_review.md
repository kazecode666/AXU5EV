# AX-00B：已解压ALINX资料实读结果

执行依据：[Issue #3](https://github.com/kazecode666/AXU5EV/issues/3)及已合并的[任务书](../tasks/ax00b_alinx_vendor_materials_intake.md)。基线`origin/main=7dc3505620e3c2558d10d3ca43ff67096a63261d`（PR #1/#2均已合并），实施分支`codex/ax00b-alinx-materials`。日期2026-10-25。

**结果：目标AXU5EVB-E已由用户确认，资料主体沿用B-E手册/原理图；PCB修订、芯片完整料号及R5运行/5EV实现仍待核。** 没有把资料索引或旧工程保存字段当作工具运行结果。

## 实际检查范围

原件在本地项目`资料/`。实测硬件、S2、S2 addition及factory已展开；S1只有`course_s1_fpga.zip`，本轮只读成员、未再次解压。独立`配套模块`目录未找到；ADC相关依据来自实际S1/S2示例，不推定用户具有模块实物。

| 检查层次 | 实际数量/范围 |
|---|---|
| 文件枚举及SHA256 | 14,289个实际文件，59,634,848,099字节；另57个只读ZIP/XSA成员有独立哈希。总索引14,346行 |
| 真正读取/检索定位 | 317个来源定位；其中120项聚焦内容、196项仅内容关键词检索、1项仅图纸标题扫描；外层S1包另标成员已读，未冒充全部3648条目已审 |
| 手册/原理图 | B-E手册51页，聚焦型号/资源/时钟/电压/接口/Boot；核心21张、B-E底板19张及E底板19张做页级标题检索（共59张），核心/底板相关电路进一步细读，关键10页渲染复核；不是59张全网表审计 |
| S1 | V1.02，228页，聚焦读取69页文字；ZIP中18个XPR均核器件，另查PLL/FIFO/PWM/UART/RS485/两类ADC和对应XDC/IP/TB |
| S2 | V1.06，423页，聚焦91页；addition另4页。234个工程文件：38个聚焦核查、196个关键词检索；40个S2创建脚本及1个addition脚本核处理器/OS |
| factory | 实际`board_test.xpr`、BD、HWH、生成连接网表、8个用户XDC、top和选定自定义IP；XSA仅静态元数据，未执行其bit/初始化程序 |
| 本地RPU原始TRM | UG1085 v1.7（2017-12-22），1165页；聚焦82/83/85/86/87/91/92/93/311/317/512/513共12页及封面/修订页1–3；给R5F、TCM/OCM、GIC架构依据，不证明当前平台配置 |

精确逐页/逐文件阅读范围在[READING_LOG.csv](../../references/alinx/READING_LOG.csv)；所有原件及未读项在[完整索引](../../references/alinx/ALINX_MATERIALS_INVENTORY.csv)。**哈希不等于阅读**。图纸PDF页序与标题号存在差异，报告及逐针表按PDF页序＋网名定位。

## 对架构真正有用的结果

| 结论 | 证据与层次 | 复用判定 |
|---|---|---|
| 核心支持双R5；资料型号是XCZU5EV-2SFVC784I，但18个S1 XPR/factory XPR/XSA配置XA/-1 | 用户手册p6、9–11；S1 p22及XPR Part；`factory_file/factory_vivado/board_test.xpr`与`top.xsa!/xsa.json`；DOC_VERIFIED/PROJECT_INSPECTED | 目标AXU5EVB-E用户已确认；具体PCB修订/芯片完整料号及XA/-1与XC/-2差异留待板级适配，不阻塞R5软件提取 |
| J15/J16可查到68数字IO及12电源/地脚，另列时钟/UART/RS485/复位 | 手册p20–24、40–42；核心p2、4–6、17–19；B-E底板p11、14、18–19；DOC_VERIFIED | [101行资源表](../../hardware/axu5ev/PL_IO_RESOURCE_MAP.csv)记录已连接事实与接口缺项，未给电机信号挑脚/创建XDC |
| S2全部平台脚本是A53_0/64bit，AMP第二域A53_1 | `course_s2/*/vitis/auto_create_vitis/build_vitis.tcl`；17_dualcore_amp脚本；PROJECT_INSPECTED | 不能称为R5F例程；UART/GIC/TTC、AXI-Lite/BRAM/IRQ仅作需适配参考 |
| 小规模PS—PL学习入口明确 | S2 p160–177、198、209–210、235、240–244；13_ps_axi_gpio/16_custom_pwm_ip/20_bram_test；PROJECT_INSPECTED | 优先学习寄存器/双口存储/中断，再在AX-01审查R5内存/缓存、原子命令与反馈一致性；本轮不设计协议 |
| AD7606/AD9238/AD9280实际例程存在 | S1 p187–204；S2 p260–303；相应源/XDC；DOC_VERIFIED/PROJECT_INSPECTED | 可借CONVST/BUSY/并行口/FIFO。显示链降精度/分批等待、PLL锁定/CDC、采样同步与输入时序都需适配；不证明电流模拟前端或模块实物 |
| PWM只是单路教学/附带IP | S1 07_pwm_led；S2 16_custom_pwm_ip；factory BD无ax_pwm实例，top.v fan固定1；PROJECT_INSPECTED | 不直接复用为三相互补/死区/快速禁止；已接受FOC/PWM与控制参数未变 |
| factory可提供网路追踪参考 | BD/HWH及`design_1/synth/design_1.v`：主AXI200MHz经外部差分时钟/Wizard，HPM0_LPD32bit、HP0/1_FPD128bit，reset/IRQ线序可定位；PROJECT_INSPECTED | 只作重建输入；ACT_FREQ和validated元数据不是运行/时序证明；详见[教程地图](../../docs/ALINX_TUTORIAL_MAP.md) |
| 厂商未提供匹配的电机位置/保护例程 | 已查手册/原理图、S1/S2关键源码只有通用IO、RS485和采集/显示例子；INFERRED | 继承旧MBDL4三相电流、光栅和使能/故障接口；厂商无专用例程，待补新板ADC、接收/电平、门极/急停与故障接线适配 |

## 冲突与最小缺项

1. **板卡/器件**：AXU5EVB-E用户已确认；非B版资料仅作对照。具体PCB修订、芯片完整料号以及手册XC/-2与工程XA/-1差异留待板级实施前核对，不再阻塞R5控制软件整理。
2. **文档笔误**：手册p24/41正文Bank号与逐针表/核心图不符；p44 TXD2网名与AG10的P/N相反；eMMC p9写8GB、p18–19写32GB；R5最高频率同页500/600MHz不一致。表中保留冲突，未修改原件。
3. **软件残留**：S2 p216写Cortex-A9、p400写XScuTimer，与实际A53脚本/XTtcPs代码不符；AArch64链接脚本不作R5内存定义。R5 domain、split/lockstep、TCM/MPU、启动和中断路由尚未确认。
4. **时钟/reset**：factory主AXI时钟不能按PS PL1标签猜；生成网表的proc_sys_reset.dcm_locked绑1，另一个~locked复位端口与ACTIVE_LOW元数据语义不一致。属于待核静态风险，不是本轮发现的实板失败或已修复结果。
5. **实时接口**：继承[旧接口定义](../../references/legacy/PMLSM_Hardware_Interface_Map.md)及MBDL4参数/MIL/DSP：YXPHM-MBDL4、独立ia/ib/ic、0.1µm/count光栅、RELCON/ENCON/F_Reset与低有效ERRI/ERRU。待完成AXU5EVB-E外置ADC选型/通道/量程、光栅接收/电平、互补门极与快速禁止的新板连接；旧DSP编号和ePWM/ADC配置不直接移用。100µs电流/1ms速度/10ms位置/50µs应用边界保持原算法参考，加入新硬件后需另测最坏时延。

## 资料取舍与下一步顺序

**可直接查用**：本文原创事实表/页码/工程定位，作为理解板级连接和学习接口的入口。**需要适配**：A53裸机API用法、PS—PL互联、PLL/FIFO/ADC/单路PWM示例，必须按实际板卡和R5/新工具重建与验证。**当前不需要**：Linux/PetaLinux、AI/VCU、视频显示、恢复镜像、完整factory外设集合以及不需要的DMA/存储链，保留索引不投入当前控制实现。

后续从已有Simulink主模型提取位置P、速度PI、Reference_Manager和原对齐作为R5软件；PL复用已接受电流FOC，按AXU5EVB-E重定向与集成。已有PI/FOC/定点化无需从零重做，旧M4全HDL候选不补为生产基线。厂商UART/TTC/AXI/BRAM仅作平台接口参考，见[R5指南](../../firmware/r5/ALINX_R5_REUSE_GUIDE.md)与[教程地图](../../docs/ALINX_TUTORIAL_MAP.md)。

## 版权、保护与验证范围

新增内容只有原创Markdown/CSV和忽略规则，原件无上传。14,346个索引记录各自唯一归于INDEX_ONLY或EXCLUDE；没有APPROVED_COPY。个别源文件的有条件分发声明仅按文件记录，未外推整包；带Confidential的图纸、PDF、BSP、XSA/bit和整套工程仍在本地。

提交前检查包含：来源存在/哈希、页码范围、逐针表与手册/核心图/XDC交叉核对、内部文档链接、CSV字段与路径唯一、基线文件/模型/FOC字节保护、Git暂存许可/敏感标识和体积。原文件只读；原未跟踪的`资料/`新增忽略规则，未删除或改动。没有保存/关闭用户未保存模型。

Vivado/Vitis2020.1→2026.1升级、R5固件/编译/SIL、RTL仿真、综合、布局布线、ARM/WCET、bitstream/烧录/上电全部 **NOT_RUN**。这次文档改动不重跑AX-00控制仿真，也不借旧Artix结果声称5EV通过。历史检查结果保留在`ax00b_validation.json`。2026-10-26按PR #4 Review修订板型、继承接口和当前协作流程；本次文字修订未重跑资料哈希、保护报表或旧仿真/RTL，修订后由用户授权合并。
