# AX-03B3 离线交付与后续手动观察

本轮不连接、下载或运行板卡。无 MBDL4 驱动板；TEST 不验证模拟前端或 ADC 针脚。

## 构建与产物

- REAL：`scripts/ax03b3_build_hw.ps1 -Output .runtime/ax03b3/hardware_real_02`，环境变量 AX03B3_TEST=0（未设置时默认 REAL）。已存在工程不要重复执行 all。
- TEST：同一入口，AX03B3_TEST=1，输出 `.runtime/ax03b3/hardware_test_01`。
- 两目录分别包含 `ax03b3_adc.bit/.ltx/.xsa`；使用各自匹配的 XSA 构建 R5。
- Vitis：`vitis.bat -s scripts/ax03b3_build.py` 默认 REAL；TEST 将 AX03B3_CONFIG 指向 `firmware/r5/ax03b3/build_config.test.json`。
- R5 工作区分别为 `.runtime/ax03b3/vitis_real_01`、`.runtime/ax03b3/vitis_test_01`，ELF 相对路径 `ax03b3_adc/build/ax03b3_adc.elf`，FSBL 为 `ax03b3_platform/export/ax03b3_platform/sw/boot/fsbl.elf`。Launch 为 ax03b3_adc_manual。

## 后续获准后用户手动操作

沿用 B2 的 A53 FSBL、R5 stopAtEntry、匹配 bit、PS 隔离解除/复位释放顺序；本说明不授权本轮加载。禁止混用 REAL/TEST 的 bit、XSA 和工作区。

UART 启动明确显示 REAL/TEST。`c` 提交配置并启用校准；`s` 读取64条约1ms间隔冻结结果；`r` 显式重新校准；`p` 暂停累计；`q` 结束应用观察。PL 时钟仍持续。校准以约10kHz选样累计1024帧，名义102.4ms，完成当帧 valid=0，随后为1。不要把低速64行显示当连续1024个原始样本。

默认两路 gain_q24=65536 **仅为数字测试比例**，不代表真实 A/count。REAL 的 `c` 只能在用户确认物理零流条件后使用；算法 done 不代表物理条件验证。上电不自动配置或校准，physical_link_verified 始终0。

TEST 注入位于 ADC receiver 后、生成数值入口前。校准码 A=2000/2001、B=2100/2101交替，偏置应为2000.5/2100.5码（Q16=131104768/137658368）；完成后 A=1990/2010、B=2120/2080交替，同链输出正负 Q24 电流及 c=-(a+b)。重启从同组测试激励开始；不持久化为真实标定。

## 最小接口

实际基址由匹配 BSP 的 XPAR_ADC_OBSERVER_0_BASEADDR 取得（应核对构建输出）。BEGIN 0x00、冻结字段及终字0x88释放协议不变。

写地址：0x100/104 两路 offset_seed_q16；0x108/10c 两路 gain_q24；0x110 log2N；0x114 config_version；0x118 命令 bit0=apply、bit1=restart、bit2=cal_en（apply优先）。参数只在 apply 整组进入既有生成DUT；manual_valid 固定0。只接受整字写，非法地址/字节写返回 SLVERR。命令在相位8接收、相位9消费，与相位4捕获及随后数值采样分离。

快照 word8..10电流Q24、11..12偏置Q16、13..14计数、15版本、21错误；quality bit5/6 done、bit7 valid、bit8 clip、bit16 TEST、bit17物理验证仍0。word0身份为0x42334f42。raw/sample_id/tick与数值结果同帧发布。
