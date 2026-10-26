# Runtime生成C

算法源为`simulation/AXU5EV_R5_Runtime.slx`及同目录轨迹函数。这里保存由ERT生成的精选C/H，保留许可头；不手工修改控制计算。Issue #8已同步用户接线顺序，20输入/41输出合同见[接口](../../integration/ps_pl/INTERFACE.md)。

先运行`simulation/START_HERE.m`加载唯一参数，再在停止状态执行`axu5ev_prepare('c_fixed',true)`显式重建。普通Run不生成C。完整工程/MEX位于`.runtime/ax01b/`；这里的C/H供Review，不代替可编辑模型，也不构成R5 BSP。

当前生成目标为Intel x86-64 Windows，薄在线包装在`integration/r5_host/`；主机验证见[Issue #8报告](../../coordination/reports/issue8_manual_run.md)。R5目标编译、任务时间和板上执行NOT_RUN。生成头中的`Validation result: Not run`是生成器自身状态，独立主机闭环以实际报告为准。
