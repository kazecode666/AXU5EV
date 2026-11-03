# ETH-02：实现结果及用户实验唯一入口

> 2026-11-03最新：PR18评论6596653379所述两场景现已用户实板PASS，待最终Review。精简证据：verification/ethernet/eth02/board_results，当前状态：verification/ethernet/eth02/status.json。两个01结果目录已占用，无需重跑；Workspace/Launch不变。本轮仅归档，不新增测试、构建或上板。下文NOT_RUN及待用户执行均为此前准备阶段记录。

2026-11-03，kazecode666/AXU5EV，分支`codex/eth02-runtime-ethernet`，依据[PR17评论6595084647](https://github.com/kazecode666/AXU5EV/pull/17#issuecomment-6595084647)。PR17已合并；ETH-02当前仅离线实现及构建通过，待Draft PR Review。下列两次整合板测均 **NOT_RUN**，由用户在Review通过后执行；旧R1与ETH01板测不代替新固件验收。

## 1. 已完成的整合与构建

复用原`ax02a_replay`、冻结的Cortex-R Runtime生成代码、后处理、JL2121 r3适配及ETH01字节流/分块/CRC。共享服务仅在ETH02编译条件下分派真实实验对象，ETH01 demo原协议行为保留。本轮没有重新生成控制模型、改算法/参数、重跑旧RTL或新增测试套件。

新PS-only XSA同时启用GEM3/MDIO与TTC0，保留原DDR/UART和TTC的100MHz、raw9999/logical10000映射。网络仍用PMU CPU/64、I-cache ON/D-cache OFF。GEM和TTC均复用BSP `XSetupInterruptSystem`的同一个GIC实例；本机standalone9.5的IsReady检查避免第二次注册重置控制器。

固定流程：`READY → START回执被确认/正常FIN收尾 → GEM TX完成 → 屏蔽GEM IRQ并XEmacPs_Stop → TTC准备/配置快照 → 原Runtime回放 → 停TTC → 原板上后处理 → 冻结结果 → reset_dma/XEmacPs_Start/恢复GEM IRQ → sys_restart_timeouts → RESULT_READY`。长回放仅在主循环执行，接收回调只收字节。实验号、完整输入标记及冻结结果独立于连接；传输队列清理不清实验。prepare失败时停止已准备的TTC，原运行错误返回后也恢复数据服务并保留有效完成前缀。

内存沿用input `0x10000000`、output `0x11000000`、descriptor `0x12f00000`、timing `0x13000000`、reference `0x14000000`、report `0x16000000`；不包含ETH01的32MiB测试数组。实际ELF PT_LOAD均在实验区之外，GEM描述符`emac_bd_space`在`0x00400000`、1MiB；程序/栈/堆/DMA缓冲区限定低DDR。实际map和[启动检查证据](../../../verification/ethernet/eth02/startup_check.json)可核对。

必要验证：Vivado2026.1导出`ETH02_XSA_PASS`；Vitis2026.1真实FSBL/BSP/R5链接及`ETH02_BUILD_PASS`；复用原启动检查，参数化新平台/应用/Launch并核对GEM/TTC/PMU与内存，结果`OFFLINE_STARTUP_CHECK_PASS`。最终text/data/bss为142031/5596/3513152字节。保留厂商BSP的废弃头、EMAC尾字段/xtopology类型、遗留PHY函数和FSBL宏警告，最终应用无新增编译警告。Python语法检查和`--help`通过，MATLAB Code Analyzer无问题；未调用板卡客户端。

本地构建日志：`D:/Project/AXU5EV/.runtime/ethernet/eth02/vivado_console.txt`、`vitis_final.log`。原R1、ETH01 r3、原始输入/参考与既有实验数据保持原路径。

## 2. 用户打开的工程

| 项目 | 实际路径/名称 |
|---|---|
| Workspace | `D:/Project/AXU5EV/.runtime/ethernet/eth02/vitis_runtime_ethernet` |
| Platform / Domain | `eth02_platform` / `r5_standalone` |
| Application / Launch | `eth02_runtime` / **eth02_runtime_manual** |
| R5 ELF | `D:/Project/AXU5EV/.runtime/ethernet/eth02/vitis_runtime_ethernet/eth02_runtime/build/eth02_runtime.elf` |
| map | 同build目录`eth02_runtime.map` |
| A53_0 FSBL | `D:/Project/AXU5EV/.runtime/ethernet/eth02/vitis_runtime_ethernet/eth02_platform/export/eth02_platform/sw/boot/fsbl.elf` |
| XSA | `D:/Project/AXU5EV/.runtime/ethernet/eth02/ps_target/eth02_ps.xsa` |
| 新固件身份 | `0x45303201`（ETH02）；timer mapping仍为version1 |

纯文件启动检查，不连接板卡：

```powershell
Set-Location D:/Project/AXU5EV
python scripts/eth02_build.py --check-startup
```

用户在Vitis选择上述Workspace和Launch；RPU split、A53_0执行匹配FSBL、R5_0装载应用，programDevice关闭且无bitstream。启动后人工Continue R5，持续运行以提供网络服务；不设置结果断点，不暂停测量或下载过程。可由用户打开：

```powershell
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ethernet/eth02/vitis_runtime_ethernet
```

## 3. Review后用户启动新应用

功率级断开；固定连接PS J6/JL2121网口，保留UART/JTAG。沿用已验证的专用PC网卡192.168.50.1/24、板192.168.50.10/24、TCP5001及MAC02:45:30:31:00:10，不改变其他网卡/VPN。UART115200/8N1，保存本次串口。

必须看到`ETH02 R5_0 standalone build=45303201 ... Runtime=TTC0`与`ETH02 TCP_READY 192.168.50.10:5001`。共享JL2121驱动仍打印ETH01前缀的PHY/PHYSR/LINK行，保留实际ID、速率和全双工状态；这些前缀不代表运行旧r3应用。识别/初始化失败则保存日志并停。全程固定网线；测量阶段暂时不提供网络服务属于计划内流程。

## 4. 第一次：current_motion

使用已有`D:/Project/AXU5EV/.runtime/ax02a/replay/current_motion/{input.bin,reference.bin,metadata.json}`及`full_scene_descriptors/current_motion/reference_descriptor.bin`，64536帧、mode1、100µs。

在MATLAB先添加唯一入口路径，然后明确启动一次：

```matlab
addpath('D:/Project/AXU5EV/simulation/ethernet');
RUN_ETH02("current_motion",Start=true,Conditions="first ETH02 launch; fixed cable; power stage disconnected")
```

Conditions须按实际运行条件填写（英文ASCII，不含引号/反斜杠）。默认新结果目录为`D:/Project/AXU5EV/.runtime/ethernet/eth02/board/current_motion_01`；已存在时换`Output="新的绝对路径"`，不覆盖。本轮交接时此目录未占用。

等价Python命令（只选一种入口执行一次）：

```powershell
python D:/Project/AXU5EV/scripts/eth02_run.py --ip 192.168.50.10 --scenario current_motion --start --conditions "first ETH02 launch; fixed cable; power stage disconnected" --out D:/Project/AXU5EV/.runtime/ethernet/eth02/board/current_motion_01
```

入口依次上传真实三份文件、检查READY、发送一次START、等待正常连接收尾及名义回放时长，再建立一次计划内下载连接（最长等待120秒）。不重发START或自动重跑实验。串口应显示`ETH02 RUNNING ... network=STOPPED`，随后`ETH02 RESULT_READY ... network=RUNNING`。

结果目录保存原始`run.json`、`pre_begin.json`、`output.bin`、`timing.bin`、`report_v2.bin`、所用metadata及`transfer.json`。run记录新固件身份、以太网来源、实验号、实际TTC信息/快照、状态/完成数与网络停止条件；保留小端float64的20输入/41输出和原64字节计时记录。下载经过原分块CRC和整对象CRC核对，未完成文件保留.partial。

完整成功后自动调用原`ax02a_compare_replay.py`及`ax02a_post_report.py crosscheck`，产生analysis和crosscheck目录，显示上传/下载耗时、原容差数值比较、截止期/序号/相位、板报crosscheck、最大响应与最小slack。分析器只增加ETH02应用身份兼容，原判据未改。原程序失败时保存可用现场/前缀并报错，不把前缀判为整场景PASS；保留输出和串口，交Review定位。

## 5. 第二次：同一应用current_alignment_reset

第一次全部通过后，R5仍运行；无需重启应用、手动写XSDB内存或覆盖第一组结果：

```matlab
RUN_ETH02("current_alignment_reset",Start=true,Conditions="same ETH02 application; fixed cable; power stage disconnected")
```

直接复用同名replay与full_scene_descriptors下的真实文件，43100帧、mode1；新结果目录`D:/Project/AXU5EV/.runtime/ethernet/eth02/board/current_alignment_reset_01`。新场景显式开始时才替换应用内上一组冻结结果，实验号应递增。两组各自要求全部帧、41字段原容差、原时序与crosscheck通过；时间按本次新实测值报告，不要求与旧R1相同。

## 6. 必需的协议增量和复用边界

沿用ETH01的E01T/version1、32字节大端帧头、4096字节分块、序号及CRC；旧demo操作不在ETH02应用启用，原ETH01应用仍保留。新操作如下：

| kind | 操作与载荷 |
|---|---|
| 0x10 SCENE | 大端scenario/frames/mode三个uint32＋ASCII条件；仅支持2=current_motion、3=current_alignment_reset、mode1 |
| 0x11 BEGIN | uint32对象ID；帧头total为对象精确长度 |
| 0x12 WRITE | 原文件字节；total/offset精确顺序 |
| 0x13 SEAL | uint32完整CRC；校验成功才提交对象，三份输入齐备才READY |
| 0x14 START | 空载荷；回uint32实验号，仅标记待执行 |
| 0x15 QUERY | 回12个uint32：build/phase/experiment/scenario/frames/uploaded/status/completed/failed/link/cache/mapping |
| 0x16 INFO | uint32下载对象ID；回长度/CRC |
| 0x17 READ | uint32对象ID；total/offset指定分块，回原文件字节 |

回复kind为请求kind OR 0x80，错误沿用0xff＋错误码。上传对象1=input、2=reference、3=32字节descriptor；下载对象4=output、5=timing、6=report、7=run JSON、8=pre-begin JSON，不提供任意地址访问。phase为0=IDLE、1=UPLOADING、2=READY、3=PENDING、4=RUNNING、5=RESULT_READY。

网络停启只用于测量流程；不包含热插拔/keepalive/异常断线自动恢复、持续遥测、吞吐优化、GUI或网络与控制并行运行。出现真实异常保存现场交Review，不盲重试。PR保持Draft，板测与合并由用户决定，Issue15保留；ETH-02完成后暂停网络扩展，再推进AX-02B的5EV PL电流核。
