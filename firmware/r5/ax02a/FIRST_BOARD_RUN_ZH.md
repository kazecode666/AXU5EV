# AX-02A：用户手动上板指南（Vitis 2026.1）

**2026-10-31当前导航：R1 P1000用户实测已PASS；下一次使用第14节的两个完整场景，workspace仍为 `.runtime/ax02a/vitis_runtime_100us_r1`，先Review、用户手动逐次操作，完整场景板验NOT_RUN。** [工作区与数据保存位置](../../../docs/WORKSPACE_GUIDE_ZH.md)列出完整ELF/FSBL和独立实验目录。ABA已完成，不重复第12节或可选C。用户BOARD_BOOT/FIRST_WAIT和motion_03首次完整数值已PASS，完整A4/A5仍未验收。

第1—6节保留首次启动/旧回放步骤，第7/8/12节分别是历史后处理/phase/TTC-only阶段；具体路径与状态按所属阶段理解。第13节会复用其中通用初始化检查，但工程/ELF/数据以第13节为准。以下开头的启动故障描述是首次修复时的记录。


本指南对应 `kazecode666/AXU5EV` [PR16首次启动故障评论](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6443462085)。用户旧日志显示GUI先选A53_0，却加载了R5 FSBL，等待`XFsbl_Exit`超时。本版修正为 **A53_0 FSBL初始化＋R5_0控制应用**，使用新的离线工作区`vitis_target_a53fsbl`，保留旧`vitis_target`及用户设置。当前XSA、生成算法和配套参考复用。本轮Codex只做离线构建/检查，**没有连接或操作板卡，也没有实测点击GUI；首次修复时硬件步骤待用户确认，后续实际结果见顶部当前导航**。

**停止使用旧workspace中的`ax02a_first_wait_manual`和`app_hw_1`反复重试。** 仅改launch名称或等待时间不会改变FSBL的处理器架构。旧日志中的R5 `Suspended`只说明调试器暂停了核，不能证明FSBL、DDR或应用启动成功。旧尝试当时未到WAIT；后续修正后用户BOARD_BOOT/FIRST_WAIT已PASS，见当前交接。

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

## 6. 已通过首次启动后的P1000技术预检（用户手动）

2026-10-30：用户BOARD_BOOT和motion_03首次完整数值回放已通过，旧首次操作边界已完成。当前执行PR16评论6514858529的C1；仍缺第二次motion、alignment/reset和完整A5。**不Build，不覆盖正在调试的vitis_target_a53fsbl ELF**。固定A53 FSBL→R5应用，不评估R5-only启动。

P1000数据已在`.runtime/ax02a/replay/p1000`准备，第0帧起1000帧，input160000B/reference328000B，末采样0.0999s。日后需重新准备时，用新目录运行：

```powershell
python scripts/ax02a_prepare_prefix.py --source .runtime/ax02a/replay/current_motion --output .runtime/ax02a/replay/p1000_new --frames 1000
```

1. 在当前成功完成断点，记录experiment；Resume回WAIT，再Pause确认state1、command0，记录**启动前experiment**。保留ax02a_result_ready完成断点，禁用Runtime/ISR/路径断点和运行中自动内存刷新。
2. 同一未断电、未覆盖且已verify的会话可复用原输入前1000帧；新加载/断电后必须用户重装并verify前缀，不能复用旧DDR。需要时仅由用户在现有XSDB执行：

```tcl
# 仅在WAIT暂停、目标已由用户选为R5_0时执行。
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/input.bin 0x10000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/input.bin 0x10000000
```

3. 用户GUI Watch记下启动前experiment（不固定为1），分别设frames1000、mode1，**最后**写command0x41583241；Resume。周期窗口不得Pause/单步/读写内存/传输。超时不自动停核；用户若暂停，本次标interrupted=true，只作失败诊断，不能作为实时性结果，不重复发command或放宽周期。
4. 到完成停点后确认当前R5_0暂停、state3或4、experiment递增、result及timer；失败留现场。此时计时器已停止。下列source仅定义过程，第二行显式调用才读板卡；用真实启动前experiment替换变量值，并选择全新目录。最后一个参数必须明确声明本次是否中断（true/false），有过人工Pause/单步就填true；无法确认不要填false，缺参数拒绝执行。该工具不连接/复位/选择目标、不下载/写内存/恢复运行。

```tcl
source D:/Project/AXU5EV/firmware/r5/ax02a/readback_short.tcl
# ax02a_before必须由用户按本次记录设置；不是固定experiment=1。
ax02a_short::readback D:/Project/AXU5EV/.runtime/ax02a/board_manual/p1000_01 $ax02a_before {warm I-cache, D-cache off, no debug traffic during run} false
```

成功全读回output328000B/timing64000B及run.json。失败时只读completed_frames完整记录，failed_frame可能未写完整；旧DDR尾部不可信。不要把手动中断改成正常完成，也不要将计时数据换成HOST时间。PC分析（新输出目录）：

```powershell
python scripts/ax02a_analyze_run.py --metadata .runtime/ax02a/replay/p1000/metadata.json --reference .runtime/ax02a/replay/p1000/reference.bin --actual .runtime/ax02a/board_manual/p1000_01/output.bin --ticks .runtime/ax02a/board_manual/p1000_01/timing.bin --run .runtime/ax02a/board_manual/p1000_01/run.json --before-experiment <本次启动前整数> --mode 1 --output .runtime/ax02a/board_manual/p1000_01/analysis --origin BOARD
```

先通过运行身份/完成门禁才分析数值与时间。timer频率只是配置换算依据，保留计数读取开销/start_window、I-cache冷暖及运行条件；未覆盖的command/alignment类别显示0（首帧initial alignment样本不等于完整对齐覆盖）。P1000通过只证明这1000帧；下列完整A4/A5仍须补齐。

## 7. C2/C3 v1历史交接（2336B；当前候选见第8节）

当前P1000仍用原`vitis_target_a53fsbl` ELF，无需更新固件。本节新固件只在独立`D:/Project/AXU5EV/.runtime/ax02a/vitis_postprocess`离线构建；**HOST交叉检查与编译通过不代表目标后处理已验证**。待ChatGPT Review通过且用户决定更换时，再由用户打开新workspace，按原A53 FSBL→R5_0启动链路加载，不能在旧workspace点击Build或把新ELF原位覆盖过去。新ELF时序不能继承旧ELF的性能结论。

新程序既有`ax02a_control`字段和START_COMMAND含义保留；另有`ax02a_post_control`，enabled初值0（关闭），设1只对下一实验生效，接收命令后自动清零。回放返回并停止两个计时器后才比较参考/汇总时间，全部完成后到原完成断点。程序result.status、报告compare_status、timing_status分别判断，status0并不等于数值合格。报告原始output/ticks均保留。

| DDR区域 | 地址 / 容量 | 用户装载或读取时机 |
|---|---|---|
| 原input / output / ticks | 0x10000000 / 0x11000000 / 0x13000000，容量合同不变 | WAIT装input；完成后读output/ticks |
| 参考描述符 | 0x12f00000 / 32B，8字节对齐 | WAIT前装载并verify；含magic/version/scenario/frames/41/source_start0/字节数 |
| 独立reference | 0x14000000 / 最大21,495,808B，8字节对齐 | 必须从PC配套reference预装并verify，不能用actual替代 |
| 小型报告 | 0x16000000 / 2336B，64字节对齐 | 程序启动/每次实验清valid，后处理完成最后发布valid；仅完成后读回 |

实际XSA覆盖这些地址；新ELF装载/栈堆与各窗口无交叠，详见`verification/ax02a/postprocess_validation.json`。本版不排序、不申请大工作数组，使用原16KB栈；C端P99明确NOT_COMPUTED，Python继续从完整ticks计算原ceil规则P99。

P1000参考描述符已生成在`.runtime/ax02a/postprocess_p1000/reference_descriptor.bin`，source.json记录配套来源。日后准备新场景或新目录时，在电脑执行：

```powershell
python scripts/ax02a_post_report.py descriptor --metadata .runtime/ax02a/replay/p1000/metadata.json --reference .runtime/ax02a/replay/p1000/reference.bin --output .runtime/ax02a/postprocess_p1000_new
```

Review后用户决定加载新ELF时，先停在新应用WAIT，检查enabled0和当前experiment。用户自己在现有XSDB执行装载并校验（source工具不会替用户执行这些命令）：

```tcl
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/reference.bin 0x14000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/reference.bin 0x14000000
dow -data D:/Project/AXU5EV/.runtime/ax02a/postprocess_p1000/reference_descriptor.bin 0x12f00000
verify -data D:/Project/AXU5EV/.runtime/ax02a/postprocess_p1000/reference_descriptor.bin 0x12f00000
```

input也必须装载/verify（重加载新应用后不要假定旧输入有效）。GUI Watch依次设post_control的scenario1、expected_experiment为启动前experiment+1、expected_mode1、interrupted0（有中断/无法确认不可据此做性能验收）、enabled1；普通邮箱frames1000、mode1，最后才写command。此处完整符号前缀是`ax02a_post_control`。运行期间不暂停/单步/传输；完成断点检查`ax02a_post_control.state=2`和原result/experiment。若descriptor/场景/长度/实验号不符，报告contract_errors非0即拒绝，不比较未完成前缀。

首次新固件验证必须全量读回P1000 output/ticks/run.json（第6节工具仍可用，选新目录，例如post_p1000_01并如实声明中断）。完成后另读小报告，禁止覆盖旧文件：

```tcl
set ax02a_post_file D:/Project/AXU5EV/.runtime/ax02a/board_manual/post_p1000_01/post_report.bin
if {[file exists $ax02a_post_file]} {error "preserve old report; use a new run directory"}
mrd -size b -bin -file $ax02a_post_file 0x16000000 2336
```

PC端先解码并检查本次身份（只报告C端声明），再以相同完整数据与Python交叉比较，所有输出目录必须未使用：

```powershell
python scripts/ax02a_post_report.py decode --metadata .runtime/ax02a/replay/p1000/metadata.json --run .runtime/ax02a/board_manual/post_p1000_01/run.json --report .runtime/ax02a/board_manual/post_p1000_01/post_report.bin --before-experiment <本次启动前整数> --output .runtime/ax02a/board_manual/post_p1000_01/decoded
python scripts/ax02a_post_report.py crosscheck --metadata .runtime/ax02a/replay/p1000/metadata.json --reference .runtime/ax02a/replay/p1000/reference.bin --actual .runtime/ax02a/board_manual/post_p1000_01/output.bin --ticks .runtime/ax02a/board_manual/post_p1000_01/timing.bin --run .runtime/ax02a/board_manual/post_p1000_01/run.json --report .runtime/ax02a/board_manual/post_p1000_01/post_report.bin --before-experiment <本次启动前整数> --output .runtime/ax02a/board_manual/post_p1000_01/crosscheck
```

数值FAIL规则不变：EXACT按有限double数值相等（含±0相等），其他为abs+rel各1e-9，NaN/Inf拒绝。C/Python每字段判定/位置/max_abs精确核对；RMS统计误差abs1e-15+rel1e-12，时间汇总abs1e-12+rel1e-9，仅用于对照统计计算，不放宽数值/截止期PASS。小报告PASS不能代替首次全量交叉读回；后续完整A4/A5也不因P1000通过而取消。

## 8. 当前相位诊断候选：下一轮GUI步骤（仅用户执行）

exp2 capture现已完整分析：数值PASS、旧规则序号/截止期PASS，release−expected有约0.999271tick/帧趋势，周期一致性不放行。无需保留旧DDR或持续供电来完成离线分析。下面候选**修复的是验收盲区，不是已证明消除了硬件漂移**；interval仍10000，logical period仍10000ticks，deadline未放宽。

### 8.1 新工程与报告

保留`vitis_target_a53fsbl`和`vitis_postprocess`，本轮新ELF仅在`D:/Project/AXU5EV/.runtime/ax02a/vitis_phase_diagnostic`实际构建。Review后由用户决定打开该workspace，选择同名`ax02a_first_wait_a53fsbl`（路径必须在新workspace），仍A53 FSBL→R5_0，按前面步骤到WAIT。Codex没有打开/连接IDE调试目标。

```powershell
# 纯文件检查，不连接板卡。
python scripts/ax02a_build_r5.py --config .runtime/ax02a/build_config_phase.json --check-startup
# 仅用户在决定加载候选后打开新IDE；此命令不是自动Debug。
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ax02a/vitis_phase_diagnostic
```

后处理仍默认关闭、一次性启用；旧control字段和timer7字段不改。参考描述符仍版本1/32B；本轮已另存`.runtime/ax02a/phase_p1000_descriptor/reference_descriptor.bin`，source.json标示报告v2。报告**版本2/2400B**，原2336B前缀保留，追加deadline_status/period_status/phase_samples及6个相位统计double；地址仍0x16000000，结束0x16000960。读取v1旧报告时解析器明确phase unavailable，不能沿用其mode1 timing PASS。

### 8.2 必要的最小只读寄存器证据

硬件N/N+1根因仍缺实际启动配置确认；这一步由用户执行，不由Codex自动探测。若用户选择用旧基线先取证，也保留原ELF，只按下面的**开始前**停点采集。所有实验输出使用新目录，不能复用exp2输出或上次小报告。

1. 在当前R5 ELF的`timing.c`中给静态函数`begin`入口设置一次性断点，确保位于两个counter尚未Start之前。当前候选ELF确有begin符号。保留实际GUI线程/PC/源码位置截图；脚本的`pre_begin`是用户阶段声明，字符串本身不能证明PC位置。
2. 回到WAIT，按第6节加载/verify P1000 input；若使用新候选的后处理，按第7节另加载/verify配套reference和本轮32B描述符，配置scenario1、expected_mode1、expected_experiment为本次启动前值+1、enabled1，command仍最后写。每次新ELF加载后重新校验输入/参考，不假定旧DDR有效。
3. 用户Resume到begin入口。此刻计时窗口尚未开始、两个counter均停止；候选`ax02a_ttc_snapshot`已记录periodic/timestamp基址、BSP Hz、raw interval/logical period、两个clock/control/IER。`snapshot.valid=1`仅表示读回完成，不等于设置正确或周期PASS；检查原result/后续准备错误。
4. 用户在现有XSDB显式执行下面只读过程。source只定义过程，调用才读取配置；当前R5必须已由用户选中并暂停。工具检查DIS位、拒绝覆盖文件；不连接、复位、写寄存器或恢复运行，也不读0xff110054/58/5c这些clear-on-read状态寄存器。

```tcl
source D:/Project/AXU5EV/firmware/r5/ax02a/read_ttc_config.tcl
ax02a_ttc::read_config D:/Project/AXU5EV/.runtime/ax02a/ttc_pre_begin_01.json pre_begin
# 使用候选时还可保存这个纯符号快照；旧ELF没有该变量。
print ax02a_ttc_snapshot
```

最小配置组：TTC0通道0/1 clock@0xff110000/04、control@0xff11000c/10、interval@0xff110024/28、IER@0xff110060/64；上层mux@0xff180380、LPD_LSBUS_CTRL@0xff5e00ac、IOPLL_CTRL@0xff5e0020。通道1基址0xff110004属于TTC0第二通道，不是TTC1模块。预期本轮内部未分频：两个clock低6位为0；开始前control分别0x23/0x21，periodic interval10000，timestamp interval0，IER分别1/0；上层TTC0_SEL应为0（LPD总线），IOPLL FB60/DIV2、LPD除10。出现不符时保留原值/截图停止，不能为了对齐预期写寄存器。

### 8.3 只在用户去掉开始前断点后运行P1000

移除begin断点和Runtime/ISR路径断点、关闭运行中自动内存刷新，再由用户Resume。首次命中begin尚未启动计时，不算周期窗口中的暂停；若实际在counter已启动后暂停/单步，则如实interrupted=true，不作实时性验收。运行中不再读取寄存器/变量或传输文件。

完成后保留ax02a_result_ready断点。第6节`readback_short.tcl`仍可读当前1000帧控制口；用全新目录如`phase_p1000_01`、真实before_experiment和真实中断声明，取得input对应的output328000B/ticks64000B/run.json。随后用户另读新报告（只用于启用后处理的候选）：

```tcl
set ax02a_phase_report D:/Project/AXU5EV/.runtime/ax02a/board_manual/phase_p1000_01/report_v2.bin
if {[file exists $ax02a_phase_report]} {error "preserve previous report"}
mrd -size b -bin -file $ax02a_phase_report 0x16000000 2400
```

PC端运行第6节analyze_run，并将第7节crosscheck的report路径换为report_v2.bin、全部run路径换成本次新目录。核对数值、deadline_sequence、period_consistency和C/Python一致性；**C/Python一致可以通过，但只要检出趋势，整个周期验收仍不能PASS**。v2中deadline_status0表示旧记录/截止期规则通过，period_status1表示检出ISR相位趋势；不足32个ISR样本为2，不能整体放行。mode0不做周期判断。

相位筛查排除软件赋值k0，用OLS拟合ISR的released−expected；阈值为6×残差标准误＋2ticks/拟合跨度，允许固定延迟/随机抖动和非零但不可分辨的小斜率。此为有限轨迹的诊断筛查，相关ISR延迟会影响标准误，既不是“6σ硬件频率证明”，也不能把无检出当严格零漂移。保存截距/残差/斜率/阈值和原始ticks。

若配置与预期一致而趋势仍在，先保留失败结果供Review，核对硬件边界/ISR延迟等原因后再决定最小硬件周期修正；本轮不预置9999，也不改expected或加宽deadline。需要10000帧时先准备对应frame0前缀并扩展/审查当前仅限1000帧的读回工具，不能直接把10000塞给硬编码P1000过程。完整A4第二次motion、alignment/reset及完整A5仍须完成；新ELF不继承旧时间结果。

## 9. 完整A4/A5备查（不自动执行）

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

## 10. 常见停点与最小排查

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

## 11. 历史首次指南离线依据与交接范围

本轮实际复核旧导出FSBL为ELF32/ARM/v7-Realtime，结合用户日志定位核不匹配；离线创建新platform/BSP/FSBL及相同生成源的R5 ELF/map，并检查两个域、实际导出FSBL、应用属性与被动launch。精简证据见`verification/ax02a/startup_validation.json`和报告的“首次启动故障与离线修正”；原目标构建证据原样保留。新增FSBL架构回归门禁覆盖原错误。未运行IDE、hw_server、XSDB目标会话或任何板卡命令；没有重建模型、仿真或RTL。CLI构建服务仅用于电脑上的编译，不是硬件调试会话。

UART依据：当前BSP `bspconfig.h`选`STDOUT_BASEADDRESS=0xff000000`，`outbyte`直接发UART0；匹配FSBL `psu_init.c`的UART0模式为8N1、CD=124、BDIV=6，对应约115200baud。该依据比泛用教程的UART1/默认COM号更适合本工程。

GUI/命令参考：[AMD 2026.1启动配置教程](https://docs.amd.com/r/en-US/Vitis-Tutorials-Embedded-Software/Deploying-the-application-on-the-target)、[应用/Stop at entry](https://docs.amd.com/r/en-US/ug1400-vitis-embedded/Application-Part)、[FSBL在平台中的作用](https://docs.amd.com/r/en-US/ug1209-embedded-design-tutorial/Reviewing-FSBL-in-the-Platform)、[XSDB表达式读写](https://docs.amd.com/r/en-US/ug1725-xsdb-reference-guide/print)、[二进制内存读回](https://docs.amd.com/r/en-US/ug1725-xsdb-reference-guide/mrd)。泛用教程的ZCU预设、A53/PMU示例及UART1不搬入本板流程。

本次交付是可供用户操作的离线交接，不是BOARD_BOOT、BOARD_REPLAY或BOARD_PERIODIC_100US证据；这些继续NOT_RUN，PR16保持草稿、不合并。后续由用户提供停点证据，再逐项更新状态。

## 12. TTC-only A—B—A 辨识（本轮离线交付，Review后用户执行）

任务来源为[评论6525374617](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6525374617)，协议见[TTC_CHARACTERIZE_PROTOCOL.md](TTC_CHARACTERIZE_PROTOCOL.md)。本节是独立小诊断应用，不执行Runtime，不装载input/reference，不用旧P1000读回器；9999仅是B实验条件。旧第6—8节仍对应原回放应用。TTC-only完成不能用于A4/A5或WCET验收。

### 12.1 本次电脑产物与纯文件检查

新workspace为`D:/Project/AXU5EV/.runtime/ax02a/vitis_ttc_characterize`，platform=`ax02a_platform`，R5域=`r5_standalone`，应用=`ax02a_ttc_characterize`，launch=`ax02a_ttc_characterize_hw`。R5 ELF/map在该workspace的`ax02a_ttc_characterize/build/ax02a_ttc_characterize.elf`及同目录`.map`；A53 FSBL在`ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf`。启动检查与数组地址依据在`startup_validation.json`；本候选被动身份文件为`ttc_provenance.tcl`。不要导入旧`ax02a_replay`配置。

电脑PowerShell可从任意目录执行以下完整单行；它只读文件，不启动Vitis或连接硬件：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_build_ttc_characterize.py --config D:/Project/AXU5EV/firmware/r5/ax02a/build_config.ttc_characterize.json --check-startup
```

需重建时必须选明确的新workspace并Review路径；现目录存在时构建器拒绝覆盖。离线构建入口为下列PowerShell单行（电脑编译服务，不是板卡会话；已有候选不应再次运行）：

```powershell
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s D:/Project/AXU5EV/scripts/ax02a_build_ttc_characterize.py
```

### 12.2 从开始菜单打开，到main／WAIT

1. Review通过后，用户从Windows开始菜单打开 **Vitis 2026.1**；在欢迎页 **Set Workspace**（已有窗口则用工作区切换入口）选择上面的新workspace。保留旧workspace，不点清理/重建旧应用。若新组件或launch没有出现，停止并保留截图。
2. Explorer中核对本次platform、`r5_standalone`和`ax02a_ttc_characterize`。打开 **Run and Debug**，选 **ax02a_ttc_characterize_hw**，核对A53_0 FSBL路径、本次R5_0 ELF、RPU split=true、Stop at entry=true、禁PL/psu_init/trace/cross-trigger。不得使用旧first_wait/app_hw配置。本节沿用第4节已说明的A53 FSBL状态检查；FSBL退出并不单独证明初始化成功。
3. 只有用户点击Debug才发生板卡初始化/加载。main入口停点确认当前为 **Cortex-R5 #0** 和本次ELF；不要在A53 FSBL上查看诊断邮箱。main处尚未执行应用缓存配置。Resume后看到`AX02A TTC-only; I-cache ON; D-cache OFF; WAIT`；在WAIT循环Suspend，核对`ax02a_ttc_char_control.state=1`、command=0、experiment=0（若已运行则记真实值）。第一次启动无采集，原始样本尾部无效。
4. 在GUI的XSDB控制台显式source下列单行。它只定义过程，不连接/选目标/复位/读板；后续显式调用才读取暂停目标。

```tcl
source D:/Project/AXU5EV/firmware/r5/ax02a/readback_ttc_characterize.tcl
```

保留唯一完成断点（XSDB单行）：

```tcl
set ttc_done_bp [bpadd -addr &ax02a_ttc_char_done]
```

可选地用GUI给`ax02a_ttc_char_prestart`设置函数断点：此处配置快照已就绪、两个计数器仍停止，可以看邮箱的actual_raw、clock/control/IER、Hz及timeout_ticks。应为clock0/0、control35/33、IER1/0、Hz100000000/100000000，actual_raw与本次请求相符。移除prestart断点后再Resume。不得在`char_hw_start`、ISR或采集循环内停下；若意外发生，读回必须声明interrupted=true，不能作辨识证据。

下列每段只发起一次。提前移除main/其他执行路径断点和观察点，关闭Expressions/Memory运行中刷新；采样窗口中不Suspend、单步、读变量或传文件。约100ms仅由BSP配置换算，不承诺墙钟耗时。无完成、ERROR、FSBL错误或目标不符时停下，保存信息，不自动重试/转入下一段。

### 12.3 A1：raw10000，用户显式执行

在已暂停WAIT，先记本次before值，再设置参数，command最后写。以下均为 **XSDB**，每行分别执行：

```tcl
set ttc_a1_before [ax02a_ttc_char::scalar experiment]
print -set ax02a_ttc_char_control.case_id 1
print -set ax02a_ttc_char_control.requested_raw 10000
print -set ax02a_ttc_char_control.requested_samples 1000
print -set ax02a_ttc_char_control.command 1
```

由用户点击GUI Resume，等done断点。此时两计数器与采样中断已经关闭；核对state3、error0、completed_samples1000、experiment=before+1、actual_raw10000。失败也允许保存已完成记录（0—999条及ERROR元数据），不能标成1000条成功。以下XSDB单行默认新目录，若已有则拒绝；最后false必须如实声明。会话和条件字符串用ASCII，三次保持一致：

```tcl
ax02a_ttc_char::readback D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/A1 A1 $ttc_a1_before 10000 D:/Project/AXU5EV/.runtime/ax02a/vitis_ttc_characterize/ttc_provenance.tcl warm01 {same power session I-cache ON D-cache OFF} false
```

只读本次已完成记录（完整16000B）及少量邮箱，生成samples.bin/run.json；不会读中断状态寄存器。目录/原始数据不覆盖，partial保留表明读回未完整。任何失败或元数据拒绝先停在这里。

### 12.4 B：raw9999，用户检查A1后再执行

同一Debug会话、同一供电、同一ELF，用户从done Resume返回WAIT，再Suspend并确认state1。不要再次点击Debug/初始化。只改变raw条件和标识，不改clock/cache/编译配置/样本数/nominal10000；不是正式修复。XSDB：

```tcl
set ttc_b_before [ax02a_ttc_char::scalar experiment]
print -set ax02a_ttc_char_control.case_id 2
print -set ax02a_ttc_char_control.requested_raw 9999
print -set ax02a_ttc_char_control.requested_samples 1000
print -set ax02a_ttc_char_control.command 1
```

用户Resume到done，核对本次experiment、state3/error0/count1000/actual_raw9999。再显式执行XSDB单行：

```tcl
ax02a_ttc_char::readback D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/B B $ttc_b_before 9999 D:/Project/AXU5EV/.runtime/ax02a/vitis_ttc_characterize/ttc_provenance.tcl warm01 {same power session I-cache ON D-cache OFF} false
```

### 12.5 A2：恢复raw10000，用户检查B后再执行

再次从done Resume回WAIT并Suspend确认state1。XSDB：

```tcl
set ttc_a2_before [ax02a_ttc_char::scalar experiment]
print -set ax02a_ttc_char_control.case_id 3
print -set ax02a_ttc_char_control.requested_raw 10000
print -set ax02a_ttc_char_control.requested_samples 1000
print -set ax02a_ttc_char_control.command 1
```

用户Resume到done并核对本次结果，再执行XSDB单行：

```tcl
ax02a_ttc_char::readback D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/A2 A2 $ttc_a2_before 10000 D:/Project/AXU5EV/.runtime/ax02a/vitis_ttc_characterize/ttc_provenance.tcl warm01 {same power session I-cache ON D-cache OFF} false
```

C/raw10001虽在同一ELF中受限支持，本轮默认不执行；需ABA不足辨识且用户另行确认。

### 12.6 结束后在普通终端离线分析

以下为 **PowerShell** 单行，不能粘到XSDB；输出目录须未存在。单次示例A1（B/A2同样可分别分析）：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_analyze_ttc_characterize.py run D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/A1/samples.bin D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/A1/run.json D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/analysis_A1
```

三次联合分析，直接读取原始三个目录，拒绝混ELF/build_id/配置/会话条件或实验顺序：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_analyze_ttc_characterize.py aba D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/A1 D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/B D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/A2 D:/Project/AXU5EV/.runtime/ax02a/board_manual/ttc_aba_01/analysis_ABA
```

向Review提交三个run.json/samples.bin与summary.json。先看采集有效和全部样本，再看窗口/残差/首尾、P与ISR趋势、排除第一条的并列摘要、A1/A2重复性。RAW_COMPATIBLE或RAW_PLUS_ONE_COMPATIBLE只是限制条件下相容；INCONCLUSIVE时保留异常，提出最小补证，不盲改9999。软件序号连续不能证明没有合并IRQ。物理根因、正式周期修正与T4板验在本次交付时仍UNCONFIRMED/NOT_RUN。

## 13. Runtime 100µs R1：ABA实测之后的P1000候选（Review后用户执行）

本节实验现已由用户完成并独立复算PASS；以下保留当时步骤，不要求重复。当前下一步是第14节完整场景。

Review5722212233的PC交叉/失败读回/构建入口修复已离线完成，72/72回归通过，**等待复审**；当前R1 ELF不重建。详情见[本轮报告](../../../coordination/reports/ax02a_review_5722212233.md)。原成功数据/相位/deadline门槛不变。

任务[6541052405](https://github.com/kazecode666/AXU5EV/pull/16#issuecomment-6541052405)。ABA实测已完成，全窗口支持本配置raw+1映射；无需重复ABA或运行C。本节为带原生成Runtime的独立候选，板验NOT_RUN；不覆盖旧工程，不继承旧时间结果。平台/PC版本合同见[RUNTIME_100US_R1.md](RUNTIME_100US_R1.md)。

从Windows开始菜单打开Vitis2026.1，**Set Workspace**选择`D:/Project/AXU5EV/.runtime/ax02a/vitis_runtime_100us_r1`。platform=`ax02a_platform`、domain=`r5_standalone`、应用=`ax02a_replay`（不是TTC-only），launch=`ax02a_first_wait_a53fsbl`。确认应用ELF位于本workspace的`ax02a_replay/build/ax02a_replay.elf`，FSBL为本workspace的`ax02a_platform/export/ax02a_platform/sw/boot/fsbl.elf`；A53 FSBL→R5_0 split、Stop at entry、禁PL/第二套psu_init。初始化状态检查仍按第4节；只选本次workspace路径。

普通PowerShell纯文件检查（任意目录，既不启动IDE也不连接板卡）：

```powershell
python D:/Project/AXU5EV/scripts/ax02a_build_r5.py --config D:/Project/AXU5EV/firmware/r5/ax02a/build_config.runtime_100us_r1.json --check-startup
```

用户Debug到R5 main，Resume到已有WAIT后Suspend，核对state1和真实experiment。XSDB逐行操作；先装载并verify同一配套数据，最后才发command：

```tcl
source D:/Project/AXU5EV/firmware/r5/ax02a/readback_short.tcl
set r1_before [ax02a_short::scalar experiment]
set r1_expected [expr {$r1_before+1}]
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/input.bin 0x10000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/input.bin 0x10000000
dow -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/reference.bin 0x14000000
verify -data D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/reference.bin 0x14000000
dow -data D:/Project/AXU5EV/.runtime/ax02a/phase_p1000_descriptor/reference_descriptor.bin 0x12f00000
verify -data D:/Project/AXU5EV/.runtime/ax02a/phase_p1000_descriptor/reference_descriptor.bin 0x12f00000
set r1_done_bp [bpadd -addr &ax02a_result_ready]
set r1_begin_bp [bpadd -addr &begin]
print -set ax02a_post_control.scenario 1
print -set ax02a_post_control.expected_experiment $r1_expected
print -set ax02a_post_control.expected_mode 1
print -set ax02a_post_control.interrupted 0
print -set ax02a_post_control.enabled 1
print -set ax02a_control.frames 1000
print -set ax02a_control.mode 1
print -set ax02a_control.command 0x41583241
```

用户Resume到`begin`入口，两个counter尚未启动；保存实际GUI位置及`ax02a_ttc_snapshot`（valid1、hardware_interval9999、logical_period_ticks10000、两个Hz100000000、clock0/0、control35/33、IER1/0）。这里`ax02a_control.timer`尚未在本次结束发布，不用其旧值取代快照。XSDB只读取证：

```tcl
print ax02a_ttc_snapshot
source D:/Project/AXU5EV/firmware/r5/ax02a/read_ttc_config.tcl
ax02a_ttc::read_config D:/Project/AXU5EV/.runtime/ax02a/runtime_r1_pre_begin_01.json pre_begin
```

测量前将本次保存的 `ttc_apb_select`（含TTC0_SEL）、`lpd_lsbus_ctrl`、`iopll_ctrl` 与上次确认的pre-begin基线对照上游选择/有效分频配置。两路局部clock=0及BSP声明100MHz不独立证明上游配置或绝对频率；不写寄存器修正、不重做ABA或外部测频。

配置不符立即停止，保留原值；不写寄存器“纠正”。在GUI移除begin/main及执行路径断点/观察点，关闭运行中刷新，只保留done停点，再Resume。测量中不暂停/单步/读写/传输；意外中断必须声明true。done时计时器已停止，核对本次experiment=before+1、state3/status0/completed1000、post_control.state2和timer.interval9999/period_ticks10000。任一失败保留异常，不自动重试、改9998或放宽deadline。

XSDB显式读回（新目录，最后false必须真实；可保存失败已完成前缀，但不能把它认作1000帧通过）：

```tcl
ax02a_short::readback D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01 $r1_before {same session I-cache ON D-cache OFF pre-begin only} false D:/Project/AXU5EV/.runtime/ax02a/vitis_runtime_100us_r1/runtime_candidate.tcl
```

成功路径仍严格核对本候选版本/身份、timer及snapshot，完整1000帧且后处理state2时保存run.json、output328000B、timing64000B及report_v2 2400B。报告仅为捕获，必须PC交叉后判断；板报状态/相位样本数/空组计数矛盾会拒绝。

合法ERROR终态先核对板核/候选/本次实验身份，再保存run.json及实际timer/snapshot。timer prepare早失败可能只有run.json（status3/completed0、snapshot.valid0），不读取旧DDR输出/ticks/报告；valid0的其他快照字段仅留痕，不能当有效配置。配置可确认的失败只读completed有效前缀，排除failed_frame；失败或后处理未完成时不读取报告。run中的captured_records/report_captured/report_validity说明捕获范围，缺失文件不补读旧数据、不补旧尾部。source只定义过程，不连接/选择/重置目标、不恢复运行。保留开始前配置JSON及GUI停点截图。

回到普通PowerShell，以下每条均完整单行，分析目录必须未存在：

```powershell
$r1_before=(Get-Content -Raw D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/run.json | ConvertFrom-Json).before_experiment
python D:/Project/AXU5EV/scripts/ax02a_analyze_run.py --metadata D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/metadata.json --reference D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/reference.bin --actual D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/output.bin --ticks D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/timing.bin --run D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/run.json --before-experiment $r1_before --mode 1 --output D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/analysis
python D:/Project/AXU5EV/scripts/ax02a_post_report.py crosscheck --metadata D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/metadata.json --reference D:/Project/AXU5EV/.runtime/ax02a/replay/p1000/reference.bin --actual D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/output.bin --ticks D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/timing.bin --run D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/run.json --report D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/report_v2.bin --before-experiment $r1_before --output D:/Project/AXU5EV/.runtime/ax02a/board_manual/runtime_r1_p1000_01/crosscheck
```

通过须同时满足候选/experiment正确、未中断且完整1000帧；41字段原容差0失败、序号正常/零截止期超限/最小余量>0；既有相位门槛无持续趋势（仍排除回放软件首帧，999个ISR样本），报告斜率/阈值与旧+0.997790849tick/frame对照；板上报告与PC一致。失败或证据不足保留首个异常并停。通过也只记录带Runtime的100µs短段通过，之后另补A4第二次完整运动/对齐复位，再做完整A5；本轮不自动延长采集、不扩展外设/电流环。

## 14. Runtime R1完整场景（Review后用户逐次执行）

第13节P1000真实数据已完整归档PASS，见[证据](../../../verification/ax02a/runtime_r1_p1000_01/evidence.json)。完整场景沿用现有ELF、DDR与原生成Runtime，不Build。**具体Vitis/XSDB逐步操作、两份数据/描述符/读回目录及两条分析命令集中在 [FULL_SCENE_RUN_ZH.md](FULL_SCENE_RUN_ZH.md)。**

先current_motion（64536帧/mode1/scenario2），用户保存并分析通过后，再显式执行current_alignment_reset（43100帧/mode1/scenario3）。两次板验NOT_RUN；不重复ABA或P1000，不改采样参数/映射/deadline，不自动执行另一个场景，PR16保持Draft、Issue15开放。
