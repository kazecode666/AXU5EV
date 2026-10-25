# AXU5EV 板卡与接口资料核查

2026-10-25，AX-00B已实读本地ALINX资料；详细来源见[板卡事实](ALINX_BOARD_FACTS.md)和[逐针资源表](PL_IO_RESOURCE_MAP.csv)。这是资料/工程静态核查，不是板级验收。

| 项目 | 实际证据与状态 |
|---|---|
| 用户选择的板卡 | AXU5EV；用户已建立 `D:/Project/AXU5EV` |
| 完整芯片料号、封装、速度等级、核心/底板修订 | 手册为AXU5EVB-E/ACU5EV、XCZU5EV-2SFVC784I；核心图框Rev1.0，底板同时存在E/B-E且标题残留AXU3EG；工程为xazu5ev-sfvc784-1-i。实物型号/修订/丝印仍UNCONFIRMED（手册p2、6、9–11；原理图；XPR） |
| PS/R5 时钟、split/lockstep、BSP/Vitis 平台 | PS参考33.333MHz（手册p20–21）；工程R5请求500MHz只是配置；40个S2创建脚本均A53_0/64bit，AMP第二域A53_1。R5 BSP、模式、TCM/MPU、启动与WCET仍NOT_RUN/未确认 |
| PL 时钟与IO | 文档200MHz差分AE5/AF5、Bank64；J15/J16共68路3.3V候选数字IO；65/66不同电压及文档Bank号冲突见详细表。没有创建新板级XDC |
| ADC/编码器/PWM/故障 | 已有外接ADC教程和单路PWM参考；实际电流模拟前端、位置尺协议/收发器、互补PWM门极电路和快速禁止线尚未确认，不当成板上现成功能 |
| 已有电机/驱动/接口信息 | `references/legacy/PMLSM_Hardware_Interface_Map.md` 与 `references/legacy/mil/PMSLM_Init_Params_MBDL4.m`；仅作旧平台来源 |
| 旧驱动/ADC/转接板等实物资料 | 12 份本地只读副本，逐项路径及 SHA256 见 `references/INDEX.csv`；未确认再分发许可，不入 Git |
| 电机基线 | Rs=2.37 Ω，Ld=Lq=1.745 mH，质量0.91 kg，电气周期60 mm，母线48 V；来源为冻结 init，不当作新硬件实测 |
| 旧 p3 器件信息 | `xc7a200tfbg484-2`、20 ns 合同保留原字节；只提供历史功能证据 |
| 本轮硬件操作 | 5EV综合/布局布线/R5实测/bitstream/烧录/功率级上电均 NOT_RUN |

整本论文和厂商资料仅索引；没有把旧Artix引脚或结果转换为5EV配置。后续需要实际板卡版本资料后再进行接口与平台设计。
