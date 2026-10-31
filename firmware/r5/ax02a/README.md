# AX-02A：R5 standalone 回放

更新：2026-10-31。当前为任务6541052405的Runtime 100µs R1，**OFFLINE_READY_FOR_REVIEW，T4板验NOT_RUN**。ABA实测已复算闭合，不重复ABA/C。用户已完成BOARD_BOOT/FIRST_WAIT和motion_03首次完整数值；A4剩余项与完整A5/WCET未完成。

- 目录与数据保存：[工作区指南](../../../docs/WORKSPACE_GUIDE_ZH.md)，当前状态：[HANDOFF](../../../coordination/HANDOFF.md)。
- 下一次上板：[手动指南第13节](FIRST_BOARD_RUN_ZH.md#13-runtime-100µs-r1aba实测之后的p1000候选review后用户执行)，先Review，用户本人操作。
- Workspace：`.runtime/ax02a/vitis_runtime_100us_r1`；应用 `ax02a_replay`；launch `ax02a_first_wait_a53fsbl`。旧workspace有同名launch，须核对该workspace自己的ELF与A53 FSBL。
- 配置：[build_config.runtime_100us_r1.json](build_config.runtime_100us_r1.json)；合同：[RUNTIME_100US_R1.md](RUNTIME_100US_R1.md)。候选0x52313031、mapping_version1，仅已验证配置raw9999/logical10000，原expected/deadline不变。
- 新采集：`.runtime/ax02a/board_manual/runtime_r1_p1000_01`，同一次run/output/timing/report_v2四文件。输入/参考仍用replay/p1000，描述符仍用phase_p1000_descriptor，完整规则见工作区指南。

普通PowerShell只做文件检查：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_build_r5.py --config D:/Project/AXU5EV/firmware/r5/ax02a/build_config.runtime_100us_r1.json --check-startup
```

不要省略配置或去掉检查开关；无参数构建仍默认历史phase配置。已有候选不重建，全部六套workspace/ELF与原始数据保留。Codex不连接/操作板卡，PR16仍Draft、不合并。

## 以下为历史阶段说明与复用方法

第4—6节首次启动/旧P1000、第7节v1后处理、第8节phase、第12节TTC-only步骤按所属阶段理解。TTC-only ABA现已完成；这些历史构建命令不作为当前R1操作入口。

## 历史：相位诊断候选

exp2新capture的数值已通过，最大差4.336808689942018e-19；但ISR相位约0.999271tick/帧，不能完整周期PASS。本轮先提交数据结论1096f56，再修复PC/C诊断盲区。候选实际构建于`.runtime/ax02a/vitis_phase_diagnostic`，原两个workspace/ELF保留；原interval10000/logical period10000和deadline未改，物理根因尚待用户读取开始前配置。新报告v2为2400B，兼容解析历史v1但不承认其mode1周期结论。GUI停点、最小只读步骤与回归后的全量交叉见[指南第8节](FIRST_BOARD_RUN_ZH.md)。

默认构建配置改为`.runtime/ax02a/build_config_phase.json`（示例`build_config.phase.json`）。本轮已完成构建，未来复验须换独立workspace，不能覆盖现有目录。实际离线命令：

```powershell
$env:AX02A_BUILD_CONFIG='D:/Project/AXU5EV/.runtime/ax02a/build_config_phase.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/ax02a_build_r5.py
python -m unittest discover -s verification/ax02a -p 'test_*.py' -v
```

下面C1/C2/C3为此前阶段交接，涉及2336B/vitis_postprocess的命令只适用于旧v1；该历史phase候选按第8节2400B/新workspace执行。控制算法、原始数据、FP/cache/TCM策略均不改。

## 历史C1：P1000预检与基线

用户BOARD_BOOT及motion_03首次完整数值回放已通过，A4仍缺第二次motion和alignment/reset，完整周期A5尚未运行。当前按照PR16评论6514858529先提交C1：不改固件，不Build正在使用的vitis_target_a53fsbl。第0帧起1000帧配套数据已生成于`.runtime/ax02a/replay/p1000`，日后复现使用`ax02a_prepare_prefix.py`的新目录参数。用户P1000操作与仅显式调用才读回的`readback_short.tcl`见[指南第6节](FIRST_BOARD_RUN_ZH.md#6-已通过首次启动后的p1000技术预检用户手动)。PC分析用`ax02a_analyze_run.py`先核对run.json身份和完成状态，再复用原比较器，不能把完整输出前缀当成新板上实验。新增C2/C3固件将单独输出、供Review，不覆盖现有ELF。

## 历史C2/C3独立固件与复验

新后处理只在回放/计时器停止之后执行，默认disabled，一次性显式enabled1。新workspace为`.runtime/ax02a/vitis_postprocess`；旧`vitis_target_a53fsbl`保留给用户继续P1000，禁止原位重建/覆盖。启动仍A53 FSBL→R5_0。新产物已离线构建完成，用户无需重复Build；先供ChatGPT Review，再由用户决定加载。操作停点和装载/verify/reference/report/全量P1000交叉读回见[指南第7节](FIRST_BOARD_RUN_ZH.md)。

离线构建配置为`firmware/r5/ax02a/build_config.postprocess.json`，默认本地入口改用`.runtime/ax02a/build_config_postprocess.json`，避免误用旧配置。未来复验必须在独立JSON指定新的workspace，脚本拒绝已有目录。本轮实际命令：

```powershell
# 以下配置和workspace已经存在；不要覆盖或重跑到同一目录。
$env:AX02A_BUILD_CONFIG='D:/Project/AXU5EV/.runtime/ax02a/build_config_postprocess.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/ax02a_build_r5.py
```

HOST复验命令为`python -m unittest discover -s verification/ax02a -p 'test_*.py' -v`，测试自行以既有MATLAB MinGW14.2编译同一纯C后处理，覆盖真实motion_03与故障注入。可重复的显式HOST交叉入口（新output目录）如下，library由该工具链`gcc -shared -O2 -fno-fast-math -ffp-contract=off ... postprocess.c -lm`构建；MinGW bin须加入PATH：

```powershell
python scripts/ax02a_post_report.py host --metadata .runtime/ax02a/replay/current_motion/metadata.json --reference .runtime/ax02a/replay/current_motion/reference.bin --actual .runtime/ax02a/board_manual/motion_03/output.bin --run .runtime/ax02a/c3_motion03_transcribed_run.json --before-experiment 0 --library .runtime/ax02a/postprocess_probe.dll --gcc-bin C:/ProgramData/MATLAB/SupportPackages/R2026b/3P.instrset/mingw_w64.instrset/bin --output .runtime/ax02a/c3_motion03_host_new
```

本次HOST的run身份来自用户评论转写文件，非自动抓取邮箱；原始motion_03缺少本地run.json的限制保持。C的P99明确NOT_COMPUTED。HOST一致与交叉链接通过不代表新ELF板上验证通过，也不继承旧ELF性能结果。

## 本轮离线启动修正

依据[PR16故障评论](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6443462085)，构建入口显式指定`fsbl_target='psu_cortexa53_0'`，而控制域仍为`psu_cortexr5_0 / r5_standalone`。这是两个独立域，不是把控制应用迁到A53。平台构建后检查实际导出FSBL的ELF64/AArch64架构；应用构建后安装被动首次配置，并检查域、文件架构、配置路径和应用核。没有通过改文件名冒充修正。

本轮复用已有XSA及独立生成C，在PowerShell实际执行以下构建（只在电脑编译，不连接板卡）：

```powershell
# 本轮使用的新配置/工作区已存在；未来重建须换未使用的workspace。
# 初次创建配置时仅复制到不存在的明确文件，保留旧build_config.json。
if (Test-Path -LiteralPath .runtime/ax02a/build_config_a53fsbl.json) { throw '配置已存在，请保留并检查；不要覆盖' }
Copy-Item -LiteralPath firmware/r5/ax02a/build_config.example.json -Destination .runtime/ax02a/build_config_a53fsbl.json
$env:AX02A_BUILD_CONFIG='D:/Project/AXU5EV/.runtime/ax02a/build_config_a53fsbl.json'
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/ax02a_build_r5.py
```

目前已构建完成，用户只需运行下面的纯离线检查再按指南打开GUI，无需重跑上面的构建段：

```powershell
python scripts/ax02a_build_r5.py --config .runtime/ax02a/build_config_a53fsbl.json --check-startup
```

新产物为`.runtime/ax02a/vitis_target_a53fsbl/ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf`（ELF64/AArch64，入口`0xfffc0000`）、同workspace的`ax02a_replay/build/ax02a_replay.elf`及map（ELF32/ARM/v7-Realtime/hard-float）。两者分别由A53与R5工具链真实构建。精简证据另存`verification/ax02a/startup_validation.json`与`startup_elf_attributes.txt`；旧`target_*`证据保留。新应用仍用原Cortex-R生成源、原cache/栈/堆设置；未改变控制算法或重新导出参考。

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

## 首次完整目标构建（历史R5 FSBL，不用于本版GUI）

用户手动补齐2026.1的Zynq UltraScale+ MPSoCs和Vitis Embedded Development后，在历史提交`1b4834526275b1824098ad66a2c2a6ce0d04dc0b`首次完整构建成功。其中XSA继续复用；旧R5 FSBL与自动GUI核选择不匹配，不能作为当前启动入口。原Vivado命令为：

```powershell
& E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -nojournal -log .runtime/ax02a/ps_target.log -source hardware/axu5ev/ax02a_ps_minimal.tcl -tclargs xczu5ev-sfvc784-2-i .runtime/ax02a/ps_target 资料/course_s2/01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1/design_1.bd
```

这组输出目录已存在；本轮无需重跑Vivado。当前构建入口见上节，未来复验须选择新的输出目录和workspace，在独立JSON同步路径。脚本拒绝覆盖已有工程，不删除或重置它们。

`ax02a_ps_minimal.tcl`复制厂商hello的一个PS XCI，原生升级3.3→3.5后将参数用于新BD；厂商原件不变。构建proc使用局部变量，避免已复现的Vivado回调覆盖全局配置字典。关闭非UART0/TTC0外设及PL接口，验证DDR64bit/x16与UART MIO42/43，导出无bitstream的XSA。4×8Gbit、DDR4_2400P来自本板原配置，不采用通用ZCU preset；手册器件XC/-2与旧厂商XA/-1的区别继续保留。

实际工具为Vivado/Vitis2026.1 SW6511674、官方R5 GCC13.4.0；完整平台入口使用Vitis Python API，不调用XSCT。生成`psu_cortexr5_0`/`r5_standalone`及R5 FSBL，应用只链接生成C、既有bridge和`main/replay_runner/timing`，排除`ert_main`、host main、MEX/SimStruct/XSI。真实编译命令含`-O2 -fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -mfpu=vfpv3-d16 -mfloat-abi=hard`。

实际产物为`.runtime/ax02a/ps_target/ax02a_ps.xsa`、`.runtime/ax02a/vitis_target/ax02a_replay/build/ax02a_replay.elf`和同目录map；FSBL为`ax02a_platform/zynqmp_fsbl/build/fsbl.elf`。ELF32/ARM/v7-Realtime/VFPv3-D16/hard-float，入口0x3c；装载段[0,0x7d8)、[0x100000,0x111c80)，与回放DDR窗口无重叠。size为text41588/data5100/bss28136B。默认链接布局将向量/启动数据置ATCM，其余代码、状态、栈/堆置DDR；主栈16KB、堆4KB，尚未做TCM性能布局。精简证据见`verification/ax02a/target_*`。

## 目标执行与计时合同（未上板）

单R5_0前台执行；RPU split须由用户按指南启动时核实，R5_1不运行任务。启动使用当前XSA对应的A53_0 FSBL初始化PS/DDR，不加载PL镜像、不写启动介质。**本轮Codex没有执行连接、复位、JTAG下载或目标运行；上板由用户亲自完成，首次到WAIT即停止。**

应用启动后打印版本并等待`ax02a_control`命令；预装输入完成后才启动实验。控制结构中`frames<=65536`，`mode=0`连续、`mode=1`周期；设置`command=0x41583241`释放。每次新实验调用同一初始化；分块/逐帧均不初始化。失败停止，不自动重试。实际JTAG启动/读回流程和板上内存可达性尚未验证。

预留DDR输入`0x10000000`（最大10,485,760B）、输出`0x11000000`（最大21,495,808B）、8×uint64计时记录`0x13000000`（最大4,194,304B）。实际XSA/ELF已通过范围和不重叠检查；上板仍须检查DDR已初始化及可用。程序D-cache关闭、I-cache开启，JTAG仅在等待/完成断点装载/读出；结束DSB之后读回。大缓冲区不放TCM。

TTC第一通道作周期释放，第二通道作独立32bit自由计数。新SDT BSP实际给出TTC0三个通道`0xff110000/4/8`、时钟100MHz、编码IRQ`0x4024/25/26`；前两项已核对为独立通道，频率仍是配置值。ISR只应答并记录时间/递增32bit序号，前台检测序号与独立经过时间，异常即停。实验总时间必须小于计数溢出边界；每个实验重新启动计数器。保留k=0在epoch，之后k=1由首个中断释放；内部速度/位置首相k=9/k=99不加外部分频。

每帧记录`[frame,seq,expected,release,start,step_begin,step_end,completion]`，单位为硬件ticks；纯Runtime区间排除输入拷贝，响应/截止期包含本帧输入、算法、输出和记录开销（最终completion时间戳存储除外）。保留1024次计数器连续读取开销、TTC起动窗口、实际周期量化；不扣掉开销美化时间。与同输入41字段比较后，用比较器`--timing ... --timer-hz <实际ClockHz> --period-ticks <interval*divisor> --origin BOARD`产生各类别统计；实际周期仅允许偏离100µs至多一个源时钟tick，错误的1ms周期会失败。所有这些硬件时间值目前 **NOT_RUN**，不能给出R5的µs结果或WCET。
