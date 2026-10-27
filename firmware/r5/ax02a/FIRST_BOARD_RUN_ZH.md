# AX-02A：第一次手动启动 R5（Vitis 2026.1）

本指南对应 `kazecode666/AXU5EV` [PR16首次启动故障评论](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6443462085)。用户旧日志显示GUI先选A53_0，却加载了R5 FSBL，等待`XFsbl_Exit`超时。本版修正为 **A53_0 FSBL初始化＋R5_0控制应用**，使用新的离线工作区`vitis_target_a53fsbl`，保留旧`vitis_target`及用户设置。当前XSA、生成算法和配套参考复用。本轮Codex只做离线构建/检查，**没有连接或操作板卡，也没有实测点击GUI；修正后的硬件步骤均待用户亲自执行确认**。

**停止使用旧workspace中的`ax02a_first_wait_manual`和`app_hw_1`反复重试。** 仅改launch名称或等待时间不会改变FSBL的处理器架构。旧日志中的R5 `Suspended`只说明调试器暂停了核，不能证明FSBL、DDR或应用启动成功。旧尝试未到WAIT；BOARD_BOOT验收仍NOT_RUN。

第一次只做停点①—③：识别目标 → 初始化并停在R5应用入口/main → 看到已有的等待消息并确认邮箱状态。到③即结束，不发送实验命令，不装载64536帧，不启动定时器。后面的回放命令仅留作下一次操作。

## 1. 先认识这份工程

| 环节 | 本工程的输入 → 产物 | 在哪里发生、有什么作用 |
|---|---|---|
| Vivado PS配置 | 本板PS XCI参数 → `ax02a_ps.xsa` | 电脑上生成硬件描述：器件、DDR、MIO、UART、TTC、时钟；XSA自身不运行，也不是bitstream |
| Vitis platform/domain | XSA → `ax02a_platform`、`r5_standalone`及BSP | 电脑上生成R5的地址/中断/驱动/启动配置；domain指定`psu_cortexr5_0`和standalone |
| 应用构建 | 独立Cortex-R生成C＋既有bridge＋main/runner/timing → ELF/map | 电脑上交叉编译；ELF含可加载代码，map说明放在哪段内存，不是运行结果 |
| PS/DDR初始化 | 同平台的A53 FSBL → PS时钟、MIO、UART、DDR初始化 | 用户通过JTAG把ELF64/AArch64 FSBL载入OCM并让A53_0执行；FSBL是启动辅助程序，不是控制应用 |
| 应用加载/运行 | `ax02a_replay.elf` → R5_0执行 | 用户通过JTAG加载；向量/启动数据在ATCM，应用代码/状态/堆/栈主要在DDR，所以必须先完成DDR初始化 |
| 观察/后续回放 | UART消息、邮箱、记录输入/输出 | UART用于观察；以后JTAG预装输入、发邮箱命令、完成后读回。回放不是实际电机闭环 |

当前阶段使用PS，不需要FOC bitstream，不写QSPI/eMMC/SD。A53_0只运行初始化FSBL并停在退出点，不运行控制应用；控制应用只在R5_0执行，R5_1不运行任务。用户实际操作时只用开发板，功率级/门极使能保持隔离或禁止。

## 2. 打开哪个工作区、看哪些文件

固定仓库根目录为 `D:/Project/AXU5EV`，下表中相对路径均以它为起点。完整工程和数据位于被Git忽略的`.runtime`，远端clone不会自动带出这些文件。

| 项目 | 当前实际位置/名称 |
|---|---|
| Vitis可执行入口 | `E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat` |
| workspace | `D:/Project/AXU5EV/.runtime/ax02a/vitis_target_a53fsbl`（新建，旧workspace不修改） |
| platform | `ax02a_platform` |
| domain / CPU | `r5_standalone` / `psu_cortexr5_0`，standalone |
| application | `ax02a_replay` |
| 启动域 / CPU | `zynqmp_fsbl` / **`psu_cortexa53_0`**，ELF64/AArch64 |
| 首次专用launch名称 | **`ax02a_first_wait_a53fsbl`**，模板[launch_first_wait.json](launch_first_wait.json) |
| XSA | `.runtime/ax02a/ps_target/ax02a_ps.xsa` |
| A53 FSBL（launch采用此导出副本） | `.runtime/ax02a/vitis_target_a53fsbl/ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf` |
| FSBL原构建产物 | `.runtime/ax02a/vitis_target_a53fsbl/ax02a_platform/zynqmp_fsbl/build/fsbl.elf` |
| PS初始化Tcl（本路线不执行） | `.runtime/ax02a/vitis_target_a53fsbl/ax02a_platform/hw/sdt/psu_init.tcl`；应用另有`ax02a_replay/_ide/psinit/psu_init.tcl` |
| R5应用ELF / map | `.runtime/ax02a/vitis_target_a53fsbl/ax02a_replay/build/ax02a_replay.elf` / 同目录`ax02a_replay.map` |
| 程序源码 / GUI调试副本 | `firmware/r5/ax02a/main.c` / workspace下`ax02a_replay/main.c` |
| 以后运动回放输入/参考 | `.runtime/ax02a/replay/current_motion/input.bin` / `reference.bin` / `metadata.json` |
| 以后对齐/复位参考 | `.runtime/ax02a/replay/current_alignment_reset/`下同名三个文件 |

本地`current_motion`是Runtime 1.50、V20/A200/J1000/minRamp0.2/rate100在PR14记录反馈上的新参考，64536帧、Ts=100µs、输入20/输出41列、逐帧LE double。输入10,325,760B，参考21,167,808B。`pr14_original`输出属于旧参数，不能拿来比较当前ELF。本轮已在新workspace重建A53 FSBL和相同源的R5应用，用户首次操作无需再次生成算法或Build；如果以后换了模型/参数，目标C、ELF和reference必须一起更新。

点击Debug之前，在仓库根目录的PowerShell执行纯离线检查（不会创建Vitis客户端或连接硬件）：

```powershell
python scripts/ax02a_build_r5.py --config .runtime/ax02a/build_config_a53fsbl.json --check-startup
```

预期`OFFLINE_STARTUP_CHECK_PASS`，FSBL为`psu_cortexa53_0 / AArch64 / 64`，application为`psu_cortexr5_0 / ARM / 32`，launch为`ax02a_first_wait_a53fsbl`。命令同时检查两个域、实际导出FSBL、实际应用ELF和launch路径；失败就停在电脑端，不能仅凭platform界面名称继续。它不证明真实GUI执行顺序或板上成功。

## 3. 启动配置：只选择一条初始化路线

本指南统一采用 **系统复位 → RPU split → A53_0执行同平台A53 FSBL → 到达`XFsbl_Exit` → 选择并复位R5_0处理器 → R5应用ELF → 入口/main**。处理器复位与系统复位不同：FSBL完成后只复位R5处理器，保留已经完成的PS/DDR配置。不要在FSBL与应用之间再做系统复位，也不要让A53继续执行R5应用。

Vitis 2026.1的`usingFSBL`字段没有可设置的FSBL目标核；`downloadElf[].core`只选择后面的应用核，**不会把前面的FSBL改为R5执行**。旧用户日志实际显示初始化选择A53_0，新平台因此显式用`fsbl_target='psu_cortexa53_0'`；`zynqmp_fsbl`与`r5_standalone`是两个独立域。launch模板只适用于已通过上节检查的新工作区，不能拿它指向旧R5 FSBL。此选择符合[AMD UG1400的FSBL目标处理器说明](https://docs.amd.com/r/en-US/ug1400-vitis-embedded/Switching-FSBL-Targeting-Processor)。

FSBL先在OCM执行，不依赖尚未初始化的DDR。调试器以当前FSBL中确实存在的`XFsbl_Exit`符号结束初始化等待，但**错误路径也可能到这里，符号本身不是成功判据**。本次还须读取FSBL状态寄存器`PMU_GLOBAL.PERS_GLOB_GEN_STORAGE4`（`0xffd80060`）：当前FSBL正常JTAG交接写`XFSBL_COMPLETED=0`，错误路径写非零ErrorStatus。必须同时有本次FSBL执行/退出记录、状态0且无错误。

GUI自动launch在退出符号后就会尝试下载应用，不能在下载前按这个状态值硬停；下面GUI路线在入口/main处检查该值，失败即不Resume。若要在应用下载前严格分段，选择第5节XSDB路线，在2a确认成功才手动执行2b；两者使用同一份FSBL，不能叠加跑。无论哪条路线，都不能据此宣称全量DDR或100µs验收通过。

已有自动生成配置`ax02a_replay_app_hw_1`默认`programDevice=true`、`stopAtEntry=false`。首次使用独立配置，原配置保留。2026.1本机的launch schema和编辑器对应设置如下：

| GUI设置 / JSON键 | 首次值 | 作用 |
|---|---|---|
| Target Connection | `Local` | 本机hw_server；只有用户主动启动调试才连接 |
| Reset entire System / `resetSystem` | true | 从JTAG启动的干净状态开始；会复位板卡 |
| Program Device / `programDevice` | **false** | 不下载PL镜像，bitstream路径为空 |
| Enable RPU Split Mode | **true** | 单独运行R5_0；不选择lockstep |
| Initialize using FSBL / `isFsbl`、`initWithFSBL` | true | 初始化核A53_0，使用上表A53 FSBL，完成符号`XFsbl_Exit` |
| Run psu init / `runPsuInit` | **false** | 不再重复执行另一套初始化；PL powerup也关闭 |
| Processor / Application | `psu_cortexr5_0` / 当前`ax02a_replay.elf` | 此行只选择R5应用，FSBL仍在A53_0执行 |
| Reset Processor / `resetProcessor` | true | FSBL完成后为应用复位R5处理器 |
| Stop at entry / `stopAtEntry` | **true** | 先停在入口，便于检查目标和main |
| Cross trigger / trace | false | 首次不引入额外触发/跟踪 |

构建入口已在**新**workspace的`ax02a_replay/_ide/launch.json`追加首次配置，不触发任何调试动作；旧workspace配置保留。需要在另一份重建workspace中恢复时，可在Vitis的launch JSON编辑页将模板的那一个configuration对象追加到现有`configurations`数组，保留其他配置；`${workspaceFolder}`必须是含A53 FSBL的新workspace，恢复后仍须执行离线检查。

## 4. 第一次操作主线：停在等待输入

### 停点①：用户确认连接与目标身份

1. 用户核对实物为AXU5EVB-E并记录能看到的核心板/PCB修订；现工程器件依用户指定手册为XCZU5EV-2SFVC784I，原厂XA/-1差异未转成实物签核。JTAG只能辅助识别器件，不能读出完整封装/速度级丝印。
2. 本板手册PDF p48–49写SW1的JTAG模式为`0000`。由用户在断电时按板上标识和手册核对，不照抄其他板的ON/OFF方向；再接开发板电源。JTAG线与PS USB-UART线用途不同，不拔插核心板。
3. 在用户现有串口工具选择PS UART对应COM口，**115200、8数据位、无校验、1停止位、无流控**。COM号由Windows设备管理器确认，不预填COM3。PS口由CP2102接UART0 MIO42/43；不要选PL串口或将普通PowerShell窗口当串口窗口。
4. 用户在一个PowerShell窗口启动服务器，在第二个窗口启动XSDB。以下命令只由用户执行；Codex没有运行它们：

```powershell
# 窗口A：保持运行。若已有3121服务，不再开第二个。
& E:/AMDDesignTools/2026.1/Vitis/bin/hw_server.bat
```

```powershell
# 窗口B：随后出现 xsdb% 提示符；它不是PowerShell。
& E:/AMDDesignTools/2026.1/Vitis/bin/xsdb.bat
```

```tcl
# XSDB：只连接/列举，不复位、不下载、不写内存。
connect -url tcp:127.0.0.1:3121
targets
jtag targets
```

预期能识别一块对应5EV的目标，含`PSU`、`Cortex-A53 #0`与`Cortex-R5 #0`；JTAG启动时核心可能显示Reset。旧日志已经确认HS1、xczu5/arm_dap及Bootmode0000；这些不代表初始化成功。`RPU`分组在复位时可能不出现，不要求手动选择该分组，也不固定target9之类数字ID。若没有正确核心、器件不符或同时出现多块板，**停在这里**，保留完整输出。

```tcl
# 识别完成后关闭这个XSDB连接，下一步由GUI独占控制。
disconnect
exit
```

### 停点②：用户用GUI初始化并停在应用入口/main

1. 启动已有workspace，以下仍只在电脑打开IDE，不会主动执行launch：

```powershell
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ax02a/vitis_target_a53fsbl
```

2. 先确认窗口workspace为`vitis_target_a53fsbl`，再在Explorer确认`ax02a_platform`和`ax02a_replay`。展开platform Settings并双击`vitis-comp.json`：`zynqmp_fsbl`须在`psu_cortexa53_0`下，`r5_standalone`须在`psu_cortexr5_0`下。application的`vitis-comp.json`仍为`r5_standalone / psu_cortexr5_0`。不要在旧workspace直接点Re-target或重建，不新建Hello World。
3. 在应用的Flow Navigator调试设置入口，或Explorer右键 **Edit Launch Configurations**，打开`ax02a_replay/_ide/launch.json`。选择 **ax02a_first_wait_a53fsbl**，对照第3节检查新workspace的A53 FSBL路径、R5应用路径、split、禁PL下载和Stop at entry。编辑/保存配置本身不启动板卡；不要选旧`ax02a_first_wait_manual`或任何`app_hw_1`配置。
4. 打开当前workspace的`ax02a_replay/main.c`，在`main`的第一个可执行语句处设置断点。O2可能合并行，断点显示不可用时在Breakpoints视图添加函数断点`main`；不改优化参数或重生成代码来解决显示问题。
5. **只有用户现在点击所选配置的Debug按钮，才开始板上复位/FSBL运行/应用下载。** 保留完整Debug/XSDB日志，核对先选择`Cortex-A53 #0`并下载**新A53 FSBL**、命中本次`XFsbl_Exit`，再选择`Cortex-R5 #0`下载`ax02a_replay.elf`。前面选A53是预期，后面应用仍须R5。FSBL未退出、再次60秒超时、下载失败或核/路径不符时停止，不扩大timeout、不补跑`psu_init.tcl`或bitstream、不手改PC。GUI退出点后自动尝试下载，不能把下载本身当成FSBL成功。
6. 在入口暂停后，先在Expressions添加`*(unsigned int *)0xffd80060`，读取第3节命名的FSBL状态寄存器；必须为0，并核对本次控制台没有FSBL错误。非0或读失败就停下，保存状态/日志，不Resume，也不靠旧值或一条退出消息放行。这个地址来自当前FSBL的`xfsbl_hw.h`，不是手猜邮箱偏移。
7. Debug视图检查当前线程为`Cortex-R5 #0`、当前映像为`ax02a_replay.elf`且已暂停。若先停在`_boot`/入口，只在上述检查通过且`main`断点已就绪时Resume一次，等待main断点。不要用设置PC到main来跳过启动代码。若已经停在main，就不再重复初始化。

停在main时，启动消息尚未打印通常正常。此时只证明应用已加载并走到入口；还未证明邮箱等待状态、数值或实时性。

### 停点③：用户继续到等待输入，第一次到此结束

1. 在Expressions/Watch里添加下列**符号表达式**，不手猜结构体地址/偏移：

```text
ax02a_control.state
ax02a_control.command
ax02a_control.frames
ax02a_control.mode
ax02a_control.experiment
ax02a_control.result.status
ax02a_control.result.completed_frames
```

2. 从main点Resume，让程序执行已有cache设置和启动打印。PS串口应出现一次：

```text
AX02A R5_0 standalone replay; D-cache OFF; waiting for input
```

3. 看到消息后点Pause/Suspend，仍选择R5_0，刷新表达式。新启动预期`state=1`、`command=0`、`frames=0`、`mode=0`、`experiment=0`。当前PC通常在main的等待循环附近；O2导致行号跳动不代表控制算法正在运行。
4. `state=1`是应用邮箱WAIT，不是调试器“Running/Suspended”的状态。`status=0/completed_frames=0`在新启动时仅为零初值，**不是回放通过**。这里“输入”指预装DDR数据＋邮箱命令，串口文本不会启动回放；第一次不要写`command`。

**第一次手动测试到此结束。** 保留：所选launch设置、目标/core与暂停位置、UART完整启动消息、上述邮箱值，以及本次ELF路径。返回这些实际证据后再判断BOARD_BOOT；不要继续下面的A4/A5命令，也不要据此标数值/100µs通过。

## 5. XSDB等价分段命令（备查，不与GUI同时控制）

本节与GUI使用同一个 **FSBL初始化路线**，供用户需要命令行定位时逐段执行，不是首次GUI测试后再跑一遍的脚本。先结束GUI调试会话，回到JTAG干净启动，再从①连接。每段报错/超时即停；`con -block`超时并不会自动停核，应先输入`stop`，保存第一处错误。

### 0：仅设置电脑路径，可离线检查

```tcl
set ax02a_root D:/Project/AXU5EV
set ax02a_ws $ax02a_root/.runtime/ax02a/vitis_target_a53fsbl
set ax02a_xsa $ax02a_root/.runtime/ax02a/ps_target/ax02a_ps.xsa
set ax02a_fsbl $ax02a_ws/ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf
set ax02a_app $ax02a_ws/ax02a_replay/build/ax02a_replay.elf
set ax02a_utils E:/AMDDesignTools/2026.1/Vitis/scripts/vitis/util/zynqmp_utils.tcl
foreach ax02a_file [list $ax02a_xsa $ax02a_fsbl $ax02a_app $ax02a_utils] {
    if {![file isfile $ax02a_file]} {error "missing local file: $ax02a_file"}
}
```

这段仅设置变量/检查本地文件，不连接、复位或写板卡。`xsdb.bat`是当前调试器；不调用已移除的XSCT建工程命令。

### 2a：用户初始化PS/DDR，等FSBL完成

前提是①已列出唯一正确的目标且当前XSDB仍连接。会复位板卡并运行FSBL；不加载PL，不启动控制回放。

```tcl
targets -set -filter {name =~ "PSU"}
rst -system
after 1000
source $ax02a_utils
disable_pmu_gate
targets -set -filter {name =~ "Cortex-R5 #0"}
enable_split_mode
rst -processor
targets -set -filter {name =~ "Cortex-A53 #0"}
rst -processor
loadhw -hw $ax02a_xsa
dow $ax02a_fsbl
set ax02a_fsbl_bp [bpadd -addr &XFsbl_Exit]
con -block -timeout 60
rrd pc
set ax02a_fsbl_status [lindex [mrd -value 0xffd80060] 0]
if {$ax02a_fsbl_status != 0} {
    error "FSBL failed, status=$ax02a_fsbl_status; do not download the application"
}
```

`source`载入本机AMD命名辅助过程；`disable_pmu_gate`在PSU上执行，`enable_split_mode`在可见的R5_0上执行，不依赖复位时可能缺失的`RPU`分组。随后明确切到**A53_0**才加载A53 FSBL，不能在R5_0上运行这份ELF。`loadhw`读取XSA并配置调试器的内存描述，不编程PL。完成停点必须是本次**A53_0**命中`XFsbl_Exit`、状态寄存器为0且无FSBL错误；单独命中符号不放行。状态寄存器依据新FSBL的`xfsbl_hw.h`及正常/错误分支。若未满足，**不要执行2b**；不要同时运行`psu_init`作为补救。此段仅离线核对，硬件顺序待用户确认。

### 2b：用户加载应用并停在main

```tcl
bpremove $ax02a_fsbl_bp
targets -set -filter {name =~ "Cortex-R5 #0"}
rst -processor
dow $ax02a_app
set ax02a_main_bp [bpadd -addr &main]
con -block -timeout 10
rrd pc
```

预期为R5_0的`ax02a_replay.elf` main断点；A53_0停留在FSBL退出处，不继续运行。保留PS/DDR初始化，不再系统复位。FSBL在A53_0、应用在R5_0，R5_1不运行任务。没有到main就停止，不写PC跳转绕过启动。

### 3：用户继续并只读等待状态

```tcl
bpremove $ax02a_main_bp
con
```

等串口出现第4节的启动消息后，用户再输入：

```tcl
stop
print ax02a_control
print ax02a_control.state
print ax02a_control.experiment
print -defs ax02a_control
```

`print`用ELF调试符号读取结构体；`-defs`可查看实际地址/类型，地址不写死。`state=1/experiment=0`后，命令行第一次测试也在此结束。不要输入下一节的`print -set`。

## 6. 后续A4/A5预备段（首次不要执行）

### 停点④：非定时连续回放与本次结果读回

以下仅供后续在首次启动已确认后使用。保持同一个ELF及配套`current_*`数据；每个新实验程序内部初始化一次，不按帧/分块复位。先做两次独立mode=0运动实验，再做对齐/复位场景；数值通过后才进入⑤。

用户在电脑新建一个未使用的读回目录，例如PowerShell：

```powershell
New-Item -ItemType Directory -Path D:/Project/AXU5EV/.runtime/ax02a/board_manual/motion_01 -ErrorAction Stop
```

当前R5_0应暂停在`state=1`。XSDB每行均由用户显式执行；输入装载只改预留DDR，邮箱最后写`command`，不能倒序：

```tcl
print ax02a_control.state
print ax02a_control.experiment
# 记下本次启动前的experiment；若state不是1，先停下排查。
dow -data $ax02a_root/.runtime/ax02a/replay/current_motion/input.bin 0x10000000
set ax02a_done_bp [bpadd -addr &ax02a_result_ready]
print -set ax02a_control.frames 64536
print -set ax02a_control.mode 0
print -set ax02a_control.command 0x41583241
con -block -timeout 120
print ax02a_control.state
print ax02a_control.experiment
print ax02a_control.result
```

完成断点在定时器停止、结果已写入之后。读回前人工核对：`state=3`、`result.status=0`、`completed_frames=64536`、`experiment=启动前值+1`，且没有超时/异常。缺任何一项都不认定本次成功，不拿DDR旧数据去比较。成功后继续运行会很快返回`state=1`，所以保留完成断点进行核对。`state=4`/非零status是失败；记录后停止，不自动重试。

```tcl
# 只有以上本次结果核对通过，才写电脑文件。-size b使num明确以字节计。
mrd -size b -bin -file $ax02a_root/.runtime/ax02a/board_manual/motion_01/output.bin 0x11000000 21167808
```

用户回到仓库根目录的PowerShell执行比较，执行环境不是XSDB：

```powershell
python scripts/ax02a_compare_replay.py --metadata .runtime/ax02a/replay/current_motion/metadata.json --reference .runtime/ax02a/replay/current_motion/reference.bin --actual .runtime/ax02a/board_manual/motion_01/output.bin --output .runtime/ax02a/board_manual/motion_01/compare --origin BOARD
```

用新目录完成第二次mode=0实验；输入一致也必须再次核对新experiment与帧数。已有`ax02a_done_bp`继续保留，不重复增加。移除main/其他会中断执行的断点。第二次实验前从完成停点Resume回WAIT，Pause后确认`state=1`；不重新初始化PS、不逐帧重新下载ELF。

对齐/复位场景另用`current_alignment_reset`的43100帧，输入6,896,000B、输出14,136,800B；同步换input、reference、metadata、邮箱frames与读回字节数，保留原10000/30000/2000拍。不能只换文件而沿用64536帧。

### 停点⑤：100µs周期回放

只有A4数值已通过后，才在WAIT装好相同输入，将`mode`设1、最后写command。开始前去掉main和执行路径上的断点/观察点，只保留实验结束后的`ax02a_result_ready`停点；若启用了Memory/Expressions的运行中自动刷新，也先关闭。**周期执行期间不Pause/单步、不读写变量或DDR、不传输文件、不在实时路径打印**；结束后统一观察和读回。

仍先核对本次experiment、status、completed_frames，再读相同output和以下计时文件：

```tcl
print ax02a_control.timer
mrd -size b -bin -file $ax02a_root/.runtime/ax02a/board_manual/periodic_01/timing.bin 0x13000000 4130304
```

`periodic_01`须事先新建，output也写入该新目录。`timer.clock_hz`、`period_ticks`必须取本次邮箱，不能把配置值或PC运行时间当实测。motion的计时为64536×8×uint64，即4,130,304B。比较器在前述数值比较参数之外增加`--timing <本次timing.bin> --timer-hz <本次clock_hz> --period-ticks <本次period_ticks>`；保留冷启动、读计数开销、普通/速度/位置/命令/对齐分类和最小slack。超期、漏序号或帧数不符即失败，不补算、不改算法或自动放宽门限。此处尚无硬件时间结果。

## 7. 常见停点与最小排查

| 现象 | 只先核对什么 / 在哪里停止 |
|---|---|
| 无JTAG目标 | 开发板供电、JTAG线/驱动、唯一hw_server的3121连接、SW1 JTAG模式；保留`targets`/`jtag targets`输出，不反复复位试运行 |
| 无COM口 | 是否接了PS USB-UART数据线、CP2102驱动和设备管理器；JTAG可见不代表UART线正确 |
| 串口空白 | main停点时还未执行printf；确认已Resume且使用PS COM口。消息在打开串口前输出会丢失；先看WAIT状态，不为补一行日志反复初始化 |
| 串口乱码 | 115200/8N1/无流控、PS端口；当前FSBL的UART0 BDIV=6、CD=124，BSP输出直接用UART0，未由应用改波特率 |
| FSBL超时或DDR访问失败 | 先核对**新workspace＋A53_0选择＋实际AArch64 FSBL路径**，防止重用旧R5 FSBL；再查JTAG冷启动、实物料号/修订及首条错误。退出符号也可能来自错误路径，须检查状态；不增大timeout、不强行开放地址或补跑另一套初始化 |
| main没到 | 当前映像是否误选FSBL/A53，R5_0是否split、应用ELF是否本工程、FSBL是否完成；不要设置PC绕过启动 |
| main变量显示optimized out | 本工程保留O2；观察全局volatile邮箱，使用符号表达式/`print -defs`；不改生成代码或关闭优化来教学 |
| 停在等待输入 | 第一次这是目标。串口输入不是邮箱命令，`experiment=0`说明还没启动实验 |
| 结果帧数/experiment不符 | 不比较旧DDR；确认本场景frames、先装输入后发command、本次是否失败/被断点中断；保留status与failed_frame |

## 8. 本次离线依据与交接范围

本轮实际复核旧导出FSBL为ELF32/ARM/v7-Realtime，结合用户日志定位核不匹配；离线创建新platform/BSP/FSBL及相同生成源的R5 ELF/map，并检查两个域、实际导出FSBL、应用属性与被动launch。精简证据见`verification/ax02a/startup_validation.json`和报告的“首次启动故障与离线修正”；原目标构建证据原样保留。新增FSBL架构回归门禁覆盖原错误。未运行IDE、hw_server、XSDB目标会话或任何板卡命令；没有重建模型、仿真或RTL。CLI构建服务仅用于电脑上的编译，不是硬件调试会话。

UART依据：当前BSP `bspconfig.h`选`STDOUT_BASEADDRESS=0xff000000`，`outbyte`直接发UART0；匹配FSBL `psu_init.c`的UART0模式为8N1、CD=124、BDIV=6，对应约115200baud。该依据比泛用教程的UART1/默认COM号更适合本工程。

GUI/命令参考：[AMD 2026.1启动配置教程](https://docs.amd.com/r/en-US/Vitis-Tutorials-Embedded-Software/Deploying-the-application-on-the-target)、[应用/Stop at entry](https://docs.amd.com/r/en-US/ug1400-vitis-embedded/Application-Part)、[FSBL在平台中的作用](https://docs.amd.com/r/en-US/ug1209-embedded-design-tutorial/Reviewing-FSBL-in-the-Platform)、[XSDB表达式读写](https://docs.amd.com/r/en-US/ug1725-xsdb-reference-guide/print)、[二进制内存读回](https://docs.amd.com/r/en-US/ug1725-xsdb-reference-guide/mrd)。泛用教程的ZCU预设、A53/PMU示例及UART1不搬入本板流程。

本次交付是可供用户操作的离线交接，不是BOARD_BOOT、BOARD_REPLAY或BOARD_PERIODIC_100US证据；这些继续NOT_RUN，PR16保持草稿、不合并。后续由用户提供停点证据，再逐项更新状态。
