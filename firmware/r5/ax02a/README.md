# AX-02A：R5 standalone 回放

当前交付是**Cortex-R独立生成配置、真实ARM Runtime对象/静态库、R5应用源码/构建入口、全采样数据及主机数值证据**。2026.1的ZU5器件/嵌入式平台链不可用，尚未产出standalone ELF/map。目标启动、板上数值和100µs实测均 **NOT_RUN**；不能把本目录称作已通过的R5目标工程。详见[结果报告](../../../coordination/reports/ax02a_r5_target_validation.md)。

## 已实际执行的入口

MATLAB操作通过MCP。本次会话初始无已加载参数，先运行唯一`simulation/init_AXU5EV.m`；如已有初始化则不重载。随后：

```matlab
addpath('D:/Project/AXU5EV/simulation');
axu5ev_build_r5_target;   % .runtime/ax02a/target，必须不存在
axu5ev_export_r5_replay;  % .runtime/ax02a/replay，必须不存在
```

再次生成时传入新的输出目录。原PC配置、fileGen目录及Dirty状态在退出时恢复，不保存SLX。生成头实际为`ARM Compatible->ARM Cortex-R`；ERT/C、little-endian、8/16/32/32/64位整数、32位word、double。没有运行交叉编译，生成日志中的MinGW只用于主机侧工具链选择，不能作为R5编译器证明。

本次在PowerShell执行：

```powershell
python scripts/ax02a_build_host.py --gcc C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin/gcc.exe --generated .runtime/ax02a/target/codegen/AXU5EV_R5_Runtime_ert_rtw --output .runtime/ax02a/host
& .runtime/ax02a/host/host_replay.exe .runtime/ax02a/replay/current_motion/input.bin 64536 .runtime/ax02a/host/current_motion_1.bin
python scripts/ax02a_compare_replay.py --metadata .runtime/ax02a/replay/current_motion/metadata.json --reference .runtime/ax02a/replay/current_motion/reference.bin --actual .runtime/ax02a/host/current_motion_1.bin --output verification/ax02a/host_motion_1 --origin HOST
python -m unittest discover -s verification/ax02a -p 'test_*.py'
```

同一主机程序独立运行两次运动场景，并运行43100帧`current_alignment_reset`；对应结果在`verification/ax02a/host_*`。这是生成C/Simulink数值对照与通用执行层验证，**不是ARM运行或托管SIL/PIL**。

另用系统既有Arm GNU12.3.1实际交叉编译Runtime/bridge/runner，未安装新工具：

```powershell
python scripts/ax02a_build_r5.py --config firmware/r5/ax02a/build_config.example.json --runtime-only --compiler D:/ST/STMicroelectronics/STM32Cube/STM32CubeCLT_1.17.0/GNU-tools-for-STM32/bin/arm-none-eabi-gcc.exe --output .runtime/ax02a/arm_runtime
```

六个真实ARM对象与`libax02a_runtime.a`留在该目录，readelf确认ELF32/ARM、v7/Realtime、VFPv3-D16、VFP寄存器传参；精简配置/属性已提交`verification/ax02a/arm_runtime_*`。这是目标对象编译，**尚未链接启动/BSP/数学库成可执行程序**。输出目录须为新目录。

## 数据合同

三个本地场景：`pr14_original`保留原MAT输出；`current_motion`以其64536帧输入喂当前Runtime模型生成新参考；`current_alignment_reset`为当前模型定向输入。前者是历史V10/A100/minRamp0.1，后两者是本地用户参数V20/A200/minRamp0.2；不能混用输出。当前运动参考没有重跑对象闭环或RTL。

每场景含`input.bin`、`reference.bin`、`metadata.json`和完整参考MAT。输入20、输出41，逐帧little-endian float64，无结构体padding；[字段表](../../../integration/ps_pl/INTERFACE.md)。输入位置20、速度15，分组`[11 3 1 1 1 1 1 1]`。每帧一次`u[k]→step→y[k]`，新实验初始化一次。

比较器精确比较布尔/枚举/计数/段号；连续量门限`1e-9+1e-9*abs(reference)`，非有限值、缺帧失败。输出`signals.csv`、`events.csv`和`summary.json`；指定`--origin`保留执行来源，比较通过不会自动推断来源。

## 目标构建入口与当前阻塞

已执行以下Vivado命令，实际在器件检查处失败，未修改厂商工程：

```powershell
& E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -nojournal -log .runtime/ax02a/ps_minimal.log -source hardware/axu5ev/ax02a_ps_minimal.tcl -tclargs xczu5ev-sfvc784-2-i .runtime/ax02a/ps_minimal 资料/course_s2/01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1/design_1.bd
python scripts/ax02a_build_r5.py --preflight
```

`ax02a_ps_minimal.tcl`后续设计为复制单个厂商hello BD、升级副本PS、保留DDR/MIO、关闭非UART0/TTC0外设、生成无PL镜像的XSA。**器件检查之后的步骤尚未运行。** 厂商配置的DDR4/64bit、4×8Gbit/x16、UART MIO42/43与手册一致；不采用通用ZCU preset。手册器件XC/-2与原工程XA/-1不同，不能直接将旧XSA交付为当前目标平台。

`build_config.example.json`指向本地输出。补齐既有2026.1的MPSoC器件与嵌入式R5工具后，才可运行下列**尚未验证成功**的目标命令：

```powershell
Copy-Item -LiteralPath firmware/r5/ax02a/build_config.example.json -Destination .runtime/ax02a/build_config.json
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/ax02a_build_r5.py
```

完整平台入口使用本机Vitis Python API，不调用XSCT；其默认`armr5-none-eabi-gcc`当前不可用，上述通用GNU工具只用于已验证的`--runtime-only`路径。计划创建`psu_cortexr5_0`/standalone和R5启动FSBL；应用只链接生成C、现有bridge及本目录`main/replay_runner/timing`，排除`ert_main`、host main、MEX/SimStruct/XSI。`-O2 -fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard`，BSP默认链接模板、16KB主栈/4KB堆；真实ABI/段分布以ELF/map为准。脚本检查ARM32、hard-float、R-profile/VFP属性、Runtime符号及DDR窗口重叠；尚未有目标ELF供检查。

## 目标执行与计时合同（未上板）

单R5_0前台执行；RPU split必须在授权启动时核实，R5_1不运行任务。启动需要当前XSA对应的PS/DDR初始化，不加载未知bitstream、不写启动介质。**本次没有执行板卡复位/JTAG下载/目标运行；须另获本次硬件授权并确认功率级隔离。**

应用启动后打印版本并等待`ax02a_control`命令；预装输入完成后才启动实验。控制结构中`frames<=65536`，`mode=0`连续、`mode=1`周期；设置`command=0x41583241`释放。每次新实验调用同一初始化；分块/逐帧均不初始化。失败停止，不自动重试。实际JTAG启动/读回流程和板上内存可达性尚未验证。

预留DDR输入`0x10000000`（最大10,485,760B）、输出`0x11000000`（最大21,495,808B）、8×uint64计时记录`0x13000000`（最大4,194,304B）。脚本检查XSA的DDR暴露范围和ELF装载段不重叠；上板仍须检查DDR已初始化及可用。程序D-cache关闭、I-cache开启，JTAG仅在等待/完成断点装载/读出；结束DSB之后读回。大缓冲区不放TCM；真实代码/状态/栈位置仍待map。

TTC第一通道作周期释放，第二通道作独立32bit自由计数；频率、IRQ、基址来自SDT BSP表。ISR只应答并记录时间/递增32bit序号，前台检测序号与独立经过时间，异常即停。实验总时间必须小于计数溢出边界；每个实验重新启动计数器。保留k=0在epoch，之后k=1由首个中断释放；内部速度/位置首相k=9/k=99不加外部分频。

每帧记录`[frame,seq,expected,release,start,step_begin,step_end,completion]`，单位为硬件ticks；纯Runtime区间排除输入拷贝，响应/截止期包含本帧输入、算法、输出和记录开销（最终completion时间戳存储除外）。保留1024次计数器连续读取开销、TTC起动窗口、实际周期量化；不扣掉开销美化时间。与同输入41字段比较后，用比较器`--timing ... --timer-hz <实际ClockHz> --period-ticks <interval*divisor> --origin BOARD`产生各类别统计；实际周期仅允许偏离100µs至多一个源时钟tick，错误的1ms周期会失败。所有这些硬件时间值目前 **NOT_RUN**，不能给出R5的µs结果或WCET。
