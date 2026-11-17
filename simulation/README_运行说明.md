# Simulink 双入口

## 纯仿真

运行 [START_SIMULATION.m](START_SIMULATION.m)，打开 [AXU5EV_Hybrid_ClosedLoop.slx](closed_loop/AXU5EV_Hybrid_ClosedLoop.slx)。[START_HERE.m](START_HERE.m)保留为同一入口的兼容脚本。

参数位于 [closed_loop/parameters/init_AXU5EV.m](closed_loop/parameters/init_AXU5EV.m)。首次进入时初始化，已有 base 参数及已打开模型的未保存编辑继续保留。停止后需要应用参数文件修改时，显式运行 `init_AXU5EV`。`model_fixed` 可直接准备，C/RTL 后端缺少产物时按提示显式构建。日常操作见[闭环操作说明](closed_loop/README_闭环操作.md)。

## 实机模型

运行 [START_EXPERIMENT.m](START_EXPERIMENT.m)，打开 [AXU5EV_Motor_Control_System.slx](experiment/AXU5EV_Motor_Control_System.slx)。实机算法、函数和参数位于 `experiment/{r5,pl,parameters,scripts}`，参数快照存入实机模型的 ModelWorkspace。

[axu5ev_experiment_parameters.m](experiment/parameters/axu5ev_experiment_parameters.m)提供独立参数。`axu5ev_experiment('parameters')` 显式刷新停止且已保存的实机模型，写入内存后可显式保存实机源。普通打开保留已有参数和未保存编辑。

`axu5ev_experiment('check')` 更新检查主模型的编译、依赖与实机边界。可分别调用 `generate_r5`、`generate_pl` 定向生成，或调用 `axu5ev_experiment('generate',new_work_dir,new_generated_dir)` 串联生成。建议使用独立 MATLAB `-batch` 进程。工作目录及生成目录均须全新，串联生成的 R5 C 和 PL HDL 分别写入 `new_generated_dir/{r5,pl}`，日志与定向验证写入工作目录。

硬件 IRQ、驱动 IO 与板级绑定为 `HW_BINDING_PENDING`，板卡运行状态为 `BOARD_NOT_RUN`。本入口用于模型与代码生成阶段。

## 测试与历史

原数字链壳正确另名为 [AXU5EV_DigitalChain_Test.slx](tests/digital_chain/AXU5EV_DigitalChain_Test.slx)。ADC、编码器、数字链和以太网 fixture 保存在 `tests`，通过 `axu5ev_test_paths` 显式选用。测试方法见[数字链说明](tests/digital_chain/motor_control_README.md)。

`archive` 保存历史生成入口。新纯仿真缓存、MEX 与结果位于 `.runtime/closed_loop/<session>`，新实机生成使用调用者指定的新目录。历史 `.runtime/ax01b` 的 MEX/XSI 可供纯仿真只读复用。
