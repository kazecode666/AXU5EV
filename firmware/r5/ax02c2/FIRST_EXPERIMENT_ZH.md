# AX-02C2：连续协同回放唯一入口

本页按[PR24评论6622743887](https://github.com/kazecode666/AXU5EV/pull/24#issuecomment-6622743887)更新签收：用户已完成perf_r1单次64536条完整实板，Runtime数值、193608个duty位串、帧/序号及完整停止均PASS，实际身份0x43324302。原native64第1201帧失败数据及备份保留；[主报告](../../../coordination/reports/ax02c2_runtime_pl_replay.md)记录实际耗时和对照，[精简证据](../../../verification/ax02c2/board_perf_r1_01/README.md)已归档。**本轮只读归档，不加载或运行；下列步骤保留本次已执行操作来源，不要求再次实验。** C1成功不复现。

| 项目 | 本轮安排 |
|---|---|
| 新产物根目录 | `D:/Project/AXU5EV/.runtime/ax02c2` |
| Workspace | `D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_perf_r1` |
| Platform / Domain | 复用原native64的`ax02c2_platform` / `r5_standalone`，新Workspace只建应用 |
| Application / Launch | `ax02c2_runtime` / **ax02c2_runtime_manual** |
| R5 ELF | `D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_perf_r1/ax02c2_runtime/build/ax02c2_runtime.elf` |
| A53 FSBL | `D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_platform/export/ax02c2_platform/sw/boot/fsbl.elf` |
| PS后配置 | `D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_platform/hw/sdt/psu_init.tcl` |
| 复用bit | `D:/Project/AXU5EV/.runtime/ax02c/hardware_02/ax02c_ps_pl.bit` |
| 复用XSA | `D:/Project/AXU5EV/.runtime/ax02c/hardware_02/ax02c_ps_pl.xsa` |
| 场景 | `current_motion`，64536条记录 |
| 同源输入/参考/物理反馈/FOC参考 | `D:/Project/AXU5EV/.runtime/ax02c2/prepared_04/data/current_motion` |
| 应用身份 / PL模块身份 | **0x43324302** / 原`0x43314301` |
| 本次实板结果目录（已完成、已占用） | `D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01` |

硬件继承已验证的AUX接1、debug reset接0；旧hardware_01、C1 app_hw_1及其默认旧bit不可用于本轮。原C1 ELF/FSBL及所有旧工作区、实验数据保留。

修复与本次实板证据继续提交到[PR24](https://github.com/kazecode666/AXU5EV/pull/24)，等待用户最终Review，不自动合并。原`current_motion_01`、`current_motion_01_fail1200_backup`、native64 Workspace/ELF及其FSBL保留。C1、RTL及ETH02旧板测不重跑；本轮不连接板卡，未授权新的JTAG操作。

## 1. 文件检查与打开Workspace

只读已有启动文件，不连接板卡：

```powershell
Set-Location D:/Project/AXU5EV
$env:AX02C2_CONFIG='D:/Project/AXU5EV/firmware/r5/ax02c2/build_config.perf_r1.json'
python scripts/ax02c2_build.py --check-startup
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_perf_r1
```

仅使用`ax02c2_runtime_manual`。启动检查必须实际给出`OFFLINE_STARTUP_CHECK_PASS`、身份0x43324302、新perf_r1 ELF及复用native64 FSBL。新Workspace注册了原已构建平台，不会复制或重建BSP/FSBL；FSBL和PS脚本路径仍在上表native64目录。旧native64的0x43324301是有效失败基线，不用于本次修复候选实验。

## 2. 一次加载：PS、PL、PS后配置、R5网络等待

接好JTAG、CP210x UART及PS侧JL2121实验网口，串口115200/8N1先保存日志。以太网仍沿用ETH02默认板卡`192.168.50.10:5001`，PC直连网卡应有同子网地址；不擅自修改当前用于联网的网卡地址/网关。

1. 先结束旧调试会话，确认没有另一个XSDB硬件客户端竞争访问。启动本表manual Launch：系统复位、RPU split、A53_0执行匹配FSBL、下载R5并停在入口，暂不Continue。
2. manual Launch的`programDevice=false`，在同一Vitis XSDB Console显式加载已验收的正确bit，不重跑C1程序：

   ```tcl
   targets -set -filter {name =~ "PL"}
   fpga -file D:/Project/AXU5EV/.runtime/ax02c/hardware_02/ax02c_ps_pl.bit
   targets -set -filter {name =~ "Cortex-A53 #0"}
   source D:/Project/AXU5EV/.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_platform/hw/sdt/psu_init.tcl
   psu_ps_pl_isolation_removal
   psu_ps_pl_reset_config
   ```

3. 以上全部正常完成后，仅Continue R5_0。UART应显示`AX02C2 ... build=43324302 ... Runtime=PL_polling base=80000000`，JL2121协商成功及`AX02C2 TCP_READY 192.168.50.10:5001`。A53保持FSBL出口暂停；未用核复位是正常状态。

本应用不会因Continue就开始控制回放；须下一节显式上传和START。此处不在UART发送`s`，那是旧C1程序入口。若初始化、编程或网络就绪失败，保留原始输出，不盲目重复复位/START。

## 3. 本次已执行的单一实验入口（留档，不再运行）

用户本次在MATLAB添加入口目录后仅调用一次。以下命令留档，输出目录已经占用，不要再次执行或覆盖；若后续另有实验，需另行授权并选择新目录。

```matlab
addpath('D:/Project/AXU5EV/simulation/ethernet');
RUN_AX02C2("current_motion",Start=true,Conditions="power stage disconnected; fixed cable; C2 perf r1",Output="D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01");
```

等价Python入口（两者择一，不能各跑一次）：

```powershell
python scripts/ax02c2_run.py --ip 192.168.50.10 --start --conditions "power stage disconnected; fixed cable; C2 perf r1" --out D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01
```

上传真实20字段输入、41字段参考、描述符与5字段物理反馈；本轮R5实际41输出驱动模型生成薄适配，PC参考不参与运行中控制。START回执和连接正常收尾后，GEM DMA/IRQ停止；PL帧调度64536次Runtime计算与实际AXI读回；末帧完整停止后冻结结果、恢复网络，再进行一次计划内重连下载。不自动重试上传/START。

## 4. 结果与解释

本次结果目录`D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01`已完整保存，保留原件，不覆盖。产物为`output.bin`（R5真实41输出）、`pl_result.bin`（真实AXI三相duty与record/step/PL帧/命令对应）、`timing.bin`（独立PMU16计时）、`run.json`、配置、原数值报告、`UART.txt`及下载/分析摘要。

实际64536条均处理完、原Runtime数值比较零失败、193608个三相duty位串零差，record/step=0..64535、PL帧/命令/采用序号=1..64536不丢不重，`complete_frames=64536`且停止/hold无错误。本轮离线读取原始全量文件，独立复核与已有摘要一致，签收BOARD_PASS。

PMU时基由实际`COUNTS_PER_SECOND`写入run.json，本次7812421Hz；没有TTC IRQ，旧TTC phase/deadline判据不适用。**旧adapter段含Runtime日志复制，新段不含；新日志复制位于commit_end与wait_begin之间，本次统计已计入。** 上一结果read_begin到下一commit_end均值/P99/最大70.204/83.457/86.017µs；再计入后移日志及返回开销到wait_begin为79.449/92.929/95.617µs，后者204条超过名义93.68µs。命令已先提交，实际帧采用均正确；这些完整工作窗口不等于提交迟到，也不能声称全部CPU工作均在93.68µs内结束。日志及返回开销单段均值/最大9.245/10.880µs，未单独隔离memcpy周期。Runtime最大39.040µs；总回放6.453738s。完整分组、最坏索引、与原失败点的同口径对照见主报告。同帧50µs与WCET仍未签核；当前交用户最终Review，不自动合并。
