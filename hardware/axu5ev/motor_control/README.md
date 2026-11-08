# ADC 模型与 PL 工程入口

本次整理接续 PR33 已审查 head `07e245c0919645b7049b4414d0f6549b9d9c7256`，关联 Issue35。PR33 当时仍为 Draft，独立整理分支依赖它，不自动合并。当前只包含 ADC 数值与板级装配，PWM/ABZ 新功能留后续任务。

## 模型：一份算法，一个共享组件

在 MATLAB 中（通过 MCP）打开：

```matlab
addpath('D:/Project/AXU5EV/simulation', ...
        'D:/Project/AXU5EV/simulation/adc', ...
        'D:/Project/AXU5EV/simulation/real_io');
open_system('AXU5EV_ADC_HDL');
open_system('AXU5EV_ADC_Observer');
```

- **改数值算法**：唯一权威源仍为 `simulation/real_io/ax03b1_current_preprocess.m`，未改公式。库中 MATLAB Function 只调用该函数，没有脚本复制。
- **改算法端口/寄存器**：`simulation/AXU5EV_PL_Algorithm_Library.slx` 的 `Current_Preprocess`。保留原18个输入、14个输出以及各输出一级 UnitDelay。
- **HDL 壳/后续算法顶层复用边界**：`simulation/AXU5EV_ADC_HDL.slx`。raw/采样资格/校准控制从左输入，电流/状态从右输出，内部是库链接。后续顶层引用同一库块，不复制算法；本次未接旧FOC。
- **观察验证壳**：`simulation/AXU5EV_ADC_Observer.slx`，同样为库链接。激励、ADC流水参考、理想ABZ参考和显示均属 SIM_ONLY，不整体综合。

原 `simulation/AXU5EV_RealIO_NoPower.slx` 有用户本地修改，原样保留，不作为活动HDL生成源。新观察壳取自 PR33 已审查版本并改成库链接，未取用或覆盖用户未提交的模型/参数。旧名称仅保留历史，不维护第二套活动算法组件。

## 生成与验证

唯一 ADC HDL 生成入口：

```matlab
adc_generate_hdl('D:/Project/AXU5EV/.runtime/adc_consolidation/matlab_01');
```

实际 DUT 为 `AXU5EV_ADC_HDL/Current_Preprocess`，生成文件为 `generated/adc/AXU5EV_ADC_HDL/Current_Preprocess.sv` 与 `Numeric_Algorithm.sv`。生成配置集中在该函数：SystemVerilog、同步高有效reset、clk_enable、Oversampling=1、关闭分布式/时钟率流水优化；`clk_enable` 在 RTL adapter 中恒1，sample_strobe 单独推动采样消费。生成器附带的模型/报告留本地，源清单只收上述两份SV，不手改生成代码。

`adc_validate_component(新结果目录)` 复用原42项数值检查/49行向量，对库链接壳14路输出检查原有一级延迟，再运行观察壳。`adc_run_observer(true,新结果目录)` 顺序调用验证及唯一生成入口；旧 `ax03b1_run_no_power` 仅薄转发。

```powershell
./scripts/ax03b3_run_rtl.ps1 -RunDir .runtime/adc_consolidation/b3_rtl_01
./scripts/ax03b1_run_rtl.ps1 -Suite current -RunDir .runtime/adc_consolidation/current_rtl_01
```

这些目录为本次已占用证据目录；重跑需另取新目录。旧 `generated/ax03b1/` 为历史生成记录，活动工程与短测试不加载它。

## PL：统一源清单与装配

唯一活动板级入口为 `hardware/axu5ev/motor_control/build.tcl`，通过 `sources.list` 分开收集手写RTL、两份生成RTL和XDC；`bd/adc.tcl` 装配 PS、SmartConnect、时钟复位、ILA。复用现有厂商PS配置，不复制厂商工程。PS基址与R5寄存器布局、冻结读取协议不变。

```powershell
$env:AX03B3_TEST='0'  # 默认REAL；TEST明确设1，使用另一个新目录
./scripts/ax03b3_build_hw.ps1 -Stage validate -Output .runtime/adc_consolidation/hardware_real_01
```

本次候选执行 base/integrate、validate_bd_design、综合和综合设计约束核对，**不生成新可上板 bit/XSA**。集成中产生的 prebit XSA 仅为候选元数据，未替换R5配置。已有 PR33 bit/ltx/XSA/ELF仍在原路径；本次实现、R5重建、板卡操作均 NOT_RUN，不沿用旧布线报告宣称新候选完成布线。

采样语义保持：名义50MHz逻辑、10拍一次约5MHz转换、500次转换选一帧约100µs；不是500次平均，尚未与PWM同步。七转换事件身份/tick关联保留；一级结果寄存与result_strobe、numeric_valid区别不变。双路独立1024合格帧校准、完成当帧无效、Q16偏置/Q24电流和宽结果重构c相均不变。REAL/TEST共用处理链、来源标记与physical_link_verified=0保留。真实零流/增益/极性/噪声仍待后续物理验证。

## 旧 → 新路径

| 旧路径 | 当前入口/落点 |
|---|---|
| `AXU5EV_RealIO_NoPower/Current_Preprocess` | `AXU5EV_PL_Algorithm_Library/Current_Preprocess`，由ADC_HDL和ADC_Observer库链接引用 |
| `simulation/real_io/ax03b1_run_no_power.m` 的生成段 | `simulation/adc/adc_generate_hdl.m`；旧入口薄转发 |
| `generated/ax03b1/AXU5EV_RealIO_NoPower/*.sv` | `generated/adc/AXU5EV_ADC_HDL/{Current_Preprocess,Numeric_Algorithm}.sv` |
| `integration/rtl/ax03b1/ax03b1_adc_receiver.sv`、`ax03b1_current_adapter.sv` | `motor_control/rtl/adc/` 同名文件 |
| `integration/rtl/ax03b1/ax03b1_snapshot_axi.sv` | `motor_control/rtl/axi/ax03b1_snapshot_axi.sv` |
| `integration/rtl/ax03b3/ax03b3_adc_observer.sv` | `motor_control/rtl/top/ax03b3_adc_observer.sv` |
| `hardware/axu5ev/ax03b3_adc.tcl` | 薄转发至 `motor_control/build.tcl`，装配实现在 `bd/adc.tcl` |
| `hardware/axu5ev/ax03b2_adc_j15.xdc` | 薄转发至 `motor_control/constraints/adc_j15.xdc`，顶层显式加载 |

表中 `motor_control/` 均相对 `hardware/axu5ev/`。B1/B2历史重现脚本已同步共享RTL路径；B2 raw-only板级装配保留为历史复现，非另一个活动B3入口。R5仍在 `firmware/r5/ax03b3/`，配置/应用和既有工作区保持原路径。精简结果见 `verification/adc_consolidation/results.json`。

本次实际结果：模型/HDL检查0错误0警告；42项数值检查及49×14输出一级延迟对比通过，新观察壳4×20字段与既有验收记录一致；B3短RTL2064帧/两轮1024及restart检查、定向数值RTL25检查通过。统一REAL候选BD验证/综合通过，4手写+2生成+1XDC均唯一加载，28引脚/LVCMOS33及两路200ns送出时钟命中，26输入min=2ns/max=10ns覆盖完整，寄存器基址0x80000000/4KiB及PL元数据49.9995MHz保留。

综合态 `check_timing` 保留no_clock=1235（1227为debug hub所驱ILA引脚，8为PS8外设输出时钟引脚）和unconstrained_internal_endpoints=1746（全部位于adc_ila）；no_input_delay/partial_input_delay/generated_clocks问题数均0。本次只核对综合态装配和约束加载，不宣称debug/板级物理时序完成签核，没有为消除这些条目修改约束。
