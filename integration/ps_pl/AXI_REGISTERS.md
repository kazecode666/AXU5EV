# AX-02C1：R5—AXI-Lite—真实 FOC

本接口复用PR20实际生成的p3核和原`axu5ev_foc_frame_top`。总线PL侧、寄存器和FOC共用PS导出的同一名义50MHz时钟；R5通过PS的M_AXI_HPM0_LPD及AMD SmartConnect访问。R5处理器时钟不同，其跨域由PS/标准AXI设施处理，本封装不另造CDC。

实际外设基址由BD分配、匹配XSA/BSP导出，R5构建读取本次`xparameters.h`中的FOC BASEADDR。以下为**字节偏移**，软件使用对齐的32位MMIO，端序沿用R5 standalone小端。AXI AW与W独立握手，每次只有一个未完成响应；写暂存字段支持WSTRB。保留偏移读0、写忽略，不定义队列、自动恢复或通用协议。

| 偏移 | 方向 | 名称及含义 |
|---|---|---|
| 0x00 | R | ID，0x43314301 |
| 0x04 | W | CONTROL：bit0 INIT；bit1 START；bit2 STOP_AFTER_FRAME。命令用独立整字写入，控制位所在byte0须有效 |
| 0x08 | W | COMMIT：写入命令序号，同时复制全部九字段到唯一pending槽；不得覆盖尚未采用的pending |
| 0x0c | R | ADOPTED_SEQ，当前帧采用的命令序号 |
| 0x10 | R | RESULT_SEQ，已发布三相结果对应的命令序号 |
| 0x14 | R | RESULT_FRAME，已发布结果的连续PL帧号，从1开始 |
| 0x18 / 0x1c / 0x20 | R | 同次发布的duty_u / duty_v / duty_w，unsigned32、30小数位 |
| 0x24 | R | STATUS：bit0 RUNNING、bit1 PENDING、bit2 VALID、bit3 STOP_REQUESTED、bit4 HOLD_ERROR，其余0 |
| 0x28 | R | COMPLETED_FRAMES，仅在完整5000拍结束后加1 |
| 0x2c | R | CAPTURE_EDGE，结果的实际原封装捕获相位，当前315；停止后保留 |
| 0x40 / 0x44 / 0x48 | RW | ia / ib / ic，signed32、24小数位，Apeak |
| 0x4c / 0x50 | RW | theta_e低32位 / 高8有效位，signed40、32小数位，rad |
| 0x54 / 0x58 | RW | omega_e低32位 / 高8有效位，signed40、24小数位，rad/s |
| 0x5c / 0x60 | RW | iq_ref / id_ref，signed32、24小数位，Apeak |
| 0x64 | RW | PI_Reset，bit0有效，沿原FOC算法消费 |
| 0x68 | RW | Vdc，unsigned32、24小数位，V |

40位字段的位串为`{HI[7:0], LO[31:0]}`；HI[7]是总字段符号位，HI[31:8]不参与FOC。例：已有向量theta位串`e7b59318ce`写LO=`b59318ce`、HI=`000000e7`，不能把HI当第二个独立signed32重新量化。所有字段直接从已有CSV整数位串导出，三相golden只用于事后比较，不作为FOC输出。

## 一次实验的帧关系

1. 写CONTROL=INIT。封装/算法初始化、序号/结果清零，duty初值0.5、VALID=0；未运行时核心保持reset，没有暗中消耗输入帧。初始化是实验边界，不逐帧清PI。0.5不是门极安全关断。
2. 写完第一行全部11个32位字，执行MMIO顺序屏障，再写COMMIT=1。pending保存完整九字段；随后写START，先采用pending再释放核心reset。首个negedge共同锁存，接下来的posedge是该帧edge1。
3. 连续运行期间，每帧均使能完整5000拍。核心post314，原封装edge315捕获三相duty和帧号；薄AXI封装在edge316观察该捕获并共同发布三相、RESULT_FRAME和RESULT_SEQ。VALID首结果后持续为1，不是每帧脉冲。
4. R5轮询RESULT_FRAME，读取RESULT_SEQ、三相duty、ADOPTED_SEQ，再读RESULT_FRAME核对前后相同。只有序号/帧号符合预期才记入RAM；正常窗口没有重试或跳过帧。读取期间如跨结果更新，报告失败。
5. 收到当前帧结果后立即提前提交下一行。pending只在当前帧edge5000结束时一次成为active，随后的negedge锁存到下一帧。暂存写、COMMIT均不改变正在运算的九字段。没有新提交则保持active数据及其采用序号，PL继续计算并正常增加帧号；17帧窗口中的重复采用会被软件序号检查拒绝，不伪装成暂停。
6. 第17帧结果进入RAM后写STOP_AFTER_FRAME，继续到该帧edge5000，再置RUNNING=0、COMPLETED_FRAMES=17；已发布三相/命令/帧号、捕获相位和hold状态保留到下一次INIT。结束后才输出17行UART及摘要。停止后核心处于reset，不能据此承诺跨实验保留PI状态。

正常运行`timing_restart=0`，原帧封装及生成SV均未修改。AXI封装内的13位帧计数器与原封装共用时钟、reset/start边界；新增短仿真逐拍确认两者对齐，以及完整85000拍、17帧和51个duty位串。

启动顺序、真实Workspace/Launch和bitstream/ELF位置只见[用户唯一指南](../../firmware/r5/ax02c/FIRST_BOARD_RUN_ZH.md)。加载PL并使时钟/复位就绪后才能访问MMIO。本轮不接完整Runtime、ADC、编码器或门极PWM；内部duty寄存器没有引到电机IO。名义100µs帧/50µs应用参考保留，不构成真实50µs端到端闭环验收。
