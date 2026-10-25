# AXU5EV 板卡与接口资料核查

2026-10-25，本轮为迁移盘点，不是板级验收。

| 项目 | 实际证据与状态 |
|---|---|
| 用户选择的板卡 | AXU5EV；用户已建立 `D:/Project/AXU5EV` |
| 完整芯片料号、封装、速度等级、核心/底板修订 | UNCONFIRMED；现有目录和 Downloads 定向检索未发现 AXU5EV/5EV 专用资料，不能用产品名推定 |
| PS/R5 时钟、split/lockstep、BSP/Vitis 平台 | NOT_CONFIGURED，后续 AX-01/02 核实 |
| PL 时钟、ADC/编码器/PWM 引脚及电气电平 | UNCONFIRMED；没有创建板级 XDC |
| 已有电机/驱动/接口信息 | `references/legacy/PMLSM_Hardware_Interface_Map.md` 与 `references/legacy/mil/PMSLM_Init_Params_MBDL4.m`；仅作旧平台来源 |
| 旧驱动/ADC/转接板等实物资料 | 12 份本地只读副本，逐项路径及 SHA256 见 `references/INDEX.csv`；未确认再分发许可，不入 Git |
| 电机基线 | Rs=2.37 Ω，Ld=Lq=1.745 mH，质量0.91 kg，电气周期60 mm，母线48 V；来源为冻结 init，不当作新硬件实测 |
| 旧 p3 器件信息 | `xc7a200tfbg484-2`、20 ns 合同保留原字节；只提供历史功能证据 |
| 本轮硬件操作 | 5EV综合/布局布线/R5实测/bitstream/烧录/功率级上电均 NOT_RUN |

整本论文和厂商资料仅索引；没有把旧Artix引脚或结果转换为5EV配置。后续需要实际板卡版本资料后再进行接口与平台设计。
