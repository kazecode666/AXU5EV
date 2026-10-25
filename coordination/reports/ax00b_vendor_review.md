# AX-00B：已解压ALINX资料实读结果

执行依据：[Issue #3](https://github.com/kazecode666/AXU5EV/issues/3)及已合并的[任务书](../tasks/ax00b_alinx_vendor_materials_intake.md)。基线`origin/main=7dc3505620e3c2558d10d3ca43ff67096a63261d`（PR #1/#2均已合并），实施分支`codex/ax00b-alinx-materials`。日期2026-10-25。

**结果：已取得可追溯的板卡/工程事实；未取得实物后缀/修订、R5运行或5EV实现验收。** 没有把资料索引或旧工程保存字段当作工具运行结果。

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
| 核心支持双R5；资料型号是XCZU5EV-2SFVC784I，但18个S1 XPR/factory XPR/XSA配置XA/-1 | 用户手册p6、9–11；S1 p22及XPR Part；`factory_file/factory_vivado/board_test.xpr`与`top.xsa!/xsa.json`；DOC_VERIFIED/PROJECT_INSPECTED | 实物完整后缀、核心/底板修订、芯片丝印继续UNCONFIRMED；不可直接签核器件/引脚 |
| J15/J16可查到68数字IO及12电源/地脚，另列时钟/UART/RS485/复位 | 手册p20–24、40–42；核心p2、4–6、17–19；B-E底板p11、14、18–19；DOC_VERIFIED | [101行资源表](../../hardware/axu5ev/PL_IO_RESOURCE_MAP.csv)记录已连接事实与接口缺项，未给电机信号挑脚/创建XDC |
| S2全部平台脚本是A53_0/64bit，AMP第二域A53_1 | `course_s2/*/vitis/auto_create_vitis/build_vitis.tcl`；17_dualcore_amp脚本；PROJECT_INSPECTED | 不能称为R5F例程；UART/GIC/TTC、AXI-Lite/BRAM/IRQ仅作需适配参考 |
| 小规模PS—PL学习入口明确 | S2 p160–177、198、209–210、235、240–244；13_ps_axi_gpio/16_custom_pwm_ip/20_bram_test；PROJECT_INSPECTED | 优先学习寄存器/双口存储/中断，再在AX-01审查R5内存/缓存、原子命令与反馈一致性；本轮不设计协议 |
| AD7606/AD9238/AD9280实际例程存在 | S1 p187–204；S2 p260–303；相应源/XDC；DOC_VERIFIED/PROJECT_INSPECTED | 可借CONVST/BUSY/并行口/FIFO。显示链降精度/分批等待、PLL锁定/CDC、采样同步与输入时序都需适配；不证明电流模拟前端或模块实物 |
| PWM只是单路教学/附带IP | S1 07_pwm_led；S2 16_custom_pwm_ip；factory BD无ax_pwm实例，top.v fan固定1；PROJECT_INSPECTED | 不直接复用为三相互补/死区/快速禁止；已接受FOC/PWM与控制参数未变 |
| factory可提供网路追踪参考 | BD/HWH及`design_1/synth/design_1.v`：主AXI200MHz经外部差分时钟/Wizard，HPM0_LPD32bit、HP0/1_FPD128bit，reset/IRQ线序可定位；PROJECT_INSPECTED | 只作重建输入；ACT_FREQ和validated元数据不是运行/时序证明；详见[教程地图](../../docs/ALINX_TUTORIAL_MAP.md) |
| 位置反馈/功率保护没有得到项目级证实 | 已查手册/原理图、S1/S2关键源码只有通用IO、RS485和采集/显示例子；INFERRED | 具体位置协议/RS422等接收器、隔离、门极驱动、急停与故障线MISSING；不能把复位或DE/一般PWM当电机保护链 |

## 冲突与最小缺项

1. **板卡/器件**：E/B-E资料并存，底板图框残留AXU3EG；手册XC/-2与工程XA/-1不同，当前没有实物丝印证据。需要用户实际底板/核心板版本、芯片料号才能结束板级定义。
2. **文档笔误**：手册p24/41正文Bank号与逐针表/核心图不符；p44 TXD2网名与AG10的P/N相反；eMMC p9写8GB、p18–19写32GB；R5最高频率同页500/600MHz不一致。表中保留冲突，未修改原件。
3. **软件残留**：S2 p216写Cortex-A9、p400写XScuTimer，与实际A53脚本/XTtcPs代码不符；AArch64链接脚本不作R5内存定义。R5 domain、split/lockstep、TCM/MPU、启动和中断路由尚未确认。
4. **时钟/reset**：factory主AXI时钟不能按PS PL1标签猜；生成网表的proc_sys_reset.dcm_locked绑1，另一个~locked复位端口与ACTIVE_LOW元数据语义不一致。属于待核静态风险，不是本轮发现的实板失败或已修复结果。
5. **实时接口**：实际电流传感器/ADC板量程和隔离、位置尺协议、电平/终端、互补门极与故障禁止电路及引脚未选定。100µs电流/1ms速度/10ms位置/50µs应用边界保持原算法参考，加入新硬件后需另测最坏时延。

## 资料取舍与下一步顺序

**可直接查用**：本文原创事实表/页码/工程定位，作为理解板级连接和学习接口的入口。**需要适配**：A53裸机API用法、PS—PL互联、PLL/FIFO/ADC/单路PWM示例，必须按实际板卡和R5/新工具重建与验证。**当前不需要**：Linux/PetaLinux、AI/VCU、视频显示、恢复镜像、完整factory外设集合以及不需要的DMA/存储链，保留索引不投入当前控制实现。

AX-01建议先解除实物/器件冲突，再按[R5指南](../../firmware/r5/ALINX_R5_REUSE_GUIDE.md)查最小平台→UART/GIC→TTC→AXI GPIO/BRAM；AX-02先按[教程地图](../../docs/ALINX_TUTORIAL_MAP.md)与实际ADC/位置/驱动底板做接口匹配，才讨论采样/跨域/PWM/快速禁止的预算。本轮仅给阅读次序，不启动这些设计。

## 版权、保护与验证范围

新增内容只有原创Markdown/CSV和忽略规则，原件无上传。14,346个索引记录各自唯一归于INDEX_ONLY或EXCLUDE；没有APPROVED_COPY。个别源文件的有条件分发声明仅按文件记录，未外推整包；带Confidential的图纸、PDF、BSP、XSA/bit和整套工程仍在本地。

提交前检查包含：来源存在/哈希、页码范围、逐针表与手册/核心图/XDC交叉核对、内部文档链接、CSV字段与路径唯一、基线文件/模型/FOC字节保护、Git暂存许可/敏感标识和体积。原文件只读；原未跟踪的`资料/`新增忽略规则，未删除或改动。没有保存/关闭用户未保存模型。

Vivado/Vitis2020.1→2026.1升级、R5固件/编译/SIL、RTL仿真、综合、布局布线、ARM/WCET、bitstream/烧录/上电全部 **NOT_RUN**。这次文档改动不重跑AX-00控制仿真，也不借旧Artix结果声称5EV通过。最终检查结果在`ax00b_validation.json`，提交独立开放PR等待ChatGPT Review，不自动合并。
