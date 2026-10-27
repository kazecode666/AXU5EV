# AX-02A：R5 standalone 回放

当前已实际生成**手册5EV器件的PS-only XSA、R5 standalone BSP/FSBL及含Runtime的ELF/map**，TARGET_BUILD通过。Cortex-R独立生成配置、全采样数据和主机数值证据继续保留。目标启动、板上数值和100µs实测均 **NOT_RUN**，构建通过不代表目标运行验收通过。详见[结果报告](../../../coordination/reports/ax02a_r5_target_validation.md)。

**第一次使用PS端，先读[首次手动启动指南](FIRST_BOARD_RUN_ZH.md)**：打开已有workspace，选`ax02a_first_wait_manual`，依次停在目标识别、应用入口/main、邮箱等待。首次仅确认已有启动消息与`state=1/experiment=0`，由用户亲自上板；Codex只做离线准备。启动配置模板为[launch_first_wait.json](launch_first_wait.json)，采用同平台R5 FSBL、RPU split，禁PL下载，不同时执行`psu_init.tcl`。分段XSDB命令、后续回放与故障定位统一放在该指南，不在这里重复。

## 已实际执行的入口

MATLAB操作通过MCP。本次会话初始无已加载参数，先运行唯一`simulation/init_AXU5EV.m`；如已有初始化则不重载。随后：

```matlab
addpath('D:/Project/AXU5EV/simulation');
axu5ev_build_r5_target;   % .runtime/ax02a/target，必须不存在
axu5ev_export_r5_replay;  % .runtime/ax02a/replay，必须不存在
```

再次生成时传入新的输出目录。原PC配置、fileGen目录及Dirty状态在退出时恢复，不保存SLX。生成头实际为`ARM Compatible->ARM Cortex-R`；ERT/C、little-endian、8/16/32/32/64位整数、32位word、double。这两个MATLAB入口本身不交叉编译；生成日志中的MinGW只用于主机侧工具链选择，不能作为R5编译器证明。

本次在PowerShell执行：

```powershell
python scripts/ax02a_build_host.py --gcc C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe --generated .runtime/ax02a/target/codegen/AXU5EV_R5_Runtime_ert_rtw --output .runtime/ax02a/host
& .runtime/ax02a/host/host_replay.exe .runtime/ax02a/replay/current_motion/input.bin 64536 .runtime/ax02a/host/current_motion_1.bin
python scripts/ax02a_compare_replay.py --metadata .runtime/ax02a/replay/current_motion/metadata.json --reference .runtime/ax02a/replay/current_motion/reference.bin --actual .runtime/ax02a/host/current_motion_1.bin --output verification/ax02a/host_motion_1 --origin HOST
python -m unittest discover -s verification/ax02a -p 'test_*.py'
```

同一主机程序独立运行两次运动场景，并运行43100帧`current_alignment_reset`；对应结果在`verification/ax02a/host_*`。这是生成C/Simulink数值对照与通用执行层验证，**不是ARM运行或托管SIL/PIL**。

在补齐AMD组件前，另用系统既有Arm GNU12.3.1实际交叉编译Runtime/bridge/runner：

```powershell
python scripts/ax02a_build_r5.py --config firmware/r5/ax02a/build_config.example.json --runtime-only --compiler D:/ST/STMicroelectronics/STM32Cube/STM32CubeCLT_1.17.0/GNU-tools-for-STM32/bin/arm-none-eabi-gcc.exe --output .runtime/ax02a/arm_runtime
```

六个真实ARM对象与`libax02a_runtime.a`留在该目录，readelf确认ELF32/ARM、v7/Realtime、VFPv3-D16、VFP寄存器传参；精简配置/属性已提交`verification/ax02a/arm_runtime_*`。这是目标对象编译，**尚未链接启动/BSP/数学库成可执行程序**。输出目录须为新目录。

## 数据合同

三个本地场景：`pr14_original`保留原MAT输出；`current_motion`以其64536帧输入喂当前Runtime模型生成新参考；`current_alignment_reset`为当前模型定向输入。前者是历史V10/A100/minRamp0.1，后两者是本地用户参数V20/A200/minRamp0.2；不能混用输出。当前运动参考没有重跑对象闭环或RTL。

每场景含`input.bin`、`reference.bin`、`metadata.json`和完整参考MAT。输入20、输出41，逐帧little-endian float64，无结构体padding；[字段表](../../../integration/ps_pl/INTERFACE.md)。输入位置20、速度15，分组`[11 3 1 1 1 1 1 1]`。每帧一次`u[k]→step→y[k]`，新实验初始化一次。

比较器精确比较布尔/枚举/计数/段号；连续量门限`1e-9+1e-9*abs(reference)`，非有限值、缺帧失败。输出`signals.csv`、`events.csv`和`summary.json`；指定`--origin`保留执行来源，比较通过不会自动推断来源。

## 已通过的完整目标构建入口

用户手动补齐2026.1的Zynq UltraScale+ MPSoCs和Vitis Embedded Development后，实际执行成功：

```powershell
& E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -nojournal -log .runtime/ax02a/ps_target.log -source hardware/axu5ev/ax02a_ps_minimal.tcl -tclargs xczu5ev-sfvc784-2-i .runtime/ax02a/ps_target 资料/course_s2/01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1/design_1.bd
Copy-Item -LiteralPath firmware/r5/ax02a/build_config.example.json -Destination .runtime/ax02a/build_config.json
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/ax02a_build_r5.py
```

这组输出目录已存在；复验须选择新的Vivado输出目录和Vitis workspace，并在独立JSON中同步XSA路径（可用`AX02A_BUILD_CONFIG`指定）。脚本拒绝覆盖已有工程，不删除或重置它们。

`ax02a_ps_minimal.tcl`复制厂商hello的一个PS XCI，原生升级3.3→3.5后将参数用于新BD；厂商原件不变。构建proc使用局部变量，避免已复现的Vivado回调覆盖全局配置字典。关闭非UART0/TTC0外设及PL接口，验证DDR64bit/x16与UART MIO42/43，导出无bitstream的XSA。4×8Gbit、DDR4_2400P来自本板原配置，不采用通用ZCU preset；手册器件XC/-2与旧厂商XA/-1的区别继续保留。

实际工具为Vivado/Vitis2026.1 SW6511674、官方R5 GCC13.4.0；完整平台入口使用Vitis Python API，不调用XSCT。生成`psu_cortexr5_0`/`r5_standalone`及R5 FSBL，应用只链接生成C、既有bridge和`main/replay_runner/timing`，排除`ert_main`、host main、MEX/SimStruct/XSI。真实编译命令含`-O2 -fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard`。

实际产物为`.runtime/ax02a/ps_target/ax02a_ps.xsa`、`.runtime/ax02a/vitis_target/ax02a_replay/build/ax02a_replay.elf`和同目录map；FSBL为`ax02a_platform/zynqmp_fsbl/build/fsbl.elf`。ELF32/ARM/v7-Realtime/VFPv3-D16/hard-float，入口0x3c；装载段[0,0x7d8)、[0x100000,0x111c80)，与回放DDR窗口无重叠。size为text41588/data5100/bss28136B。默认链接布局将向量/启动数据置ATCM，其余代码、状态、栈/堆置DDR；主栈16KB、堆4KB，尚未做TCM性能布局。精简证据见`verification/ax02a/target_*`。

## 目标执行与计时合同（未上板）

单R5_0前台执行；RPU split必须在授权启动时核实，R5_1不运行任务。启动需要当前XSA对应的PS/DDR初始化，不加载未知bitstream、不写启动介质。**本次没有执行板卡复位/JTAG下载/目标运行；须另获本次硬件授权并确认功率级隔离。**

应用启动后打印版本并等待`ax02a_control`命令；预装输入完成后才启动实验。控制结构中`frames<=65536`，`mode=0`连续、`mode=1`周期；设置`command=0x41583241`释放。每次新实验调用同一初始化；分块/逐帧均不初始化。失败停止，不自动重试。实际JTAG启动/读回流程和板上内存可达性尚未验证。

预留DDR输入`0x10000000`（最大10,485,760B）、输出`0x11000000`（最大21,495,808B）、8×uint64计时记录`0x13000000`（最大4,194,304B）。实际XSA/ELF已通过范围和不重叠检查；上板仍须检查DDR已初始化及可用。程序D-cache关闭、I-cache开启，JTAG仅在等待/完成断点装载/读出；结束DSB之后读回。大缓冲区不放TCM。

TTC第一通道作周期释放，第二通道作独立32bit自由计数。新SDT BSP实际给出TTC0三个通道`0xff110000/4/8`、时钟100MHz、编码IRQ`0x4024/25/26`；前两项已核对为独立通道，频率仍是配置值。ISR只应答并记录时间/递增32bit序号，前台检测序号与独立经过时间，异常即停。实验总时间必须小于计数溢出边界；每个实验重新启动计数器。保留k=0在epoch，之后k=1由首个中断释放；内部速度/位置首相k=9/k=99不加外部分频。

每帧记录`[frame,seq,expected,release,start,step_begin,step_end,completion]`，单位为硬件ticks；纯Runtime区间排除输入拷贝，响应/截止期包含本帧输入、算法、输出和记录开销（最终completion时间戳存储除外）。保留1024次计数器连续读取开销、TTC起动窗口、实际周期量化；不扣掉开销美化时间。与同输入41字段比较后，用比较器`--timing ... --timer-hz <实际ClockHz> --period-ticks <interval*divisor> --origin BOARD`产生各类别统计；实际周期仅允许偏离100µs至多一个源时钟tick，错误的1ms周期会失败。所有这些硬件时间值目前 **NOT_RUN**，不能给出R5的µs结果或WCET。
