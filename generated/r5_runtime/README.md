# Runtime生成C

由`firmware/r5/AXU5EV_R5_Runtime.slx`通过ERT生成的精选C/H及依赖，保留原生成文件和许可头，未手工修改。算法源仍为Simulink/Stateflow及原点位／S曲线函数。

本轮目标为Intel x86-64 Windows主机，薄包装在`integration/r5_host/`；不是R5 BSP或板上可运行应用。软件100µs调用、接口20输入／41输出和初始化规则见`integration/ps_pl/INTERFACE.md`。

在MATLAB中从仓库根目录执行`addpath('scripts'); ax01b_prepare_hybrid('c_fixed',true);`重生成并构建MEX。完整生成工程在`.runtime/ax01b/codegen/`，不复制其缓存、报告、示例main或工具配置。C/H精选副本供Review；修改算法或生成参数须修改源文件后重生成，不在此补算法。

本轮实际闭环、逐位核对和限制见`coordination/reports/ax01b_runtime_hybrid.md`。生成头中的`Validation result: Not run`为代码生成器自身验证状态，独立主机闭环结果以该报告为准。
