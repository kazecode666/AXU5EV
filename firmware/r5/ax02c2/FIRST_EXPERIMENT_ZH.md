# AX-02C2：连续协同回放唯一入口

本页更新为PR24评论6620575361的性能修复候选perf_r1。原native64候选已实板运行，1200条成功后第1201帧命令落后一帧，原数据及备份保留。新软件仅减少桥接复制、将日志放在COMMIT后，原生构建及启动检查PASS；必要等价验证见[主报告](../../../coordination/reports/ax02c2_runtime_pl_replay.md)。**新候选板测NOT_RUN，本轮未授权加载或运行；以下单次步骤仅供Review及用户之后授权使用。** C1成功不复现。

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
| 新输出目录（未运行） | `D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01` |

硬件继承已验证的AUX接1、debug reset接0；旧hardware_01、C1 app_hw_1及其默认旧bit不可用于本轮。原C1 ELF/FSBL及所有旧工作区、实验数据保留。

修复继续提交到[PR24](https://github.com/kazecode666/AXU5EV/pull/24)，等待ChatGPT Review及用户新的单次板验授权。原`current_motion_01`、`current_motion_01_fail1200_backup`、native64 Workspace/ELF及其FSBL保留。C1、RTL及ETH02旧板测不重跑；保持功率级断开，不写启动介质。

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

## 3. 单一实验入口

在MATLAB添加入口目录，随后仅调用一次：

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

新结果目录`D:/Project/AXU5EV/.runtime/ax02c2/board/current_motion_perf_r1_01`尚未占用时才能执行；已存在则保留，另定新编号，不覆盖。产物为`output.bin`（R5真实41输出）、`pl_result.bin`（真实AXI三相duty与record/step/PL帧/命令对应）、`timing.bin`（独立PMU16计时）、`run.json`、配置、原数值报告及下载/分析摘要。

完整通过须64536条均处理完、原Runtime数值比较通过、193608个三相duty位串零差，record/step=0..64535、PL帧/命令/采用序号=1..64536不丢不重，`complete_frames=64536`且停止/hold无错误。当前板测仍为NOT_RUN，不能凭文件检查或主机对照宣称实板通过。

PMU时基由实际`COUNTS_PER_SECOND`写入run.json，只用于计算、适配、提交、读回窗口统计；没有TTC IRQ，旧TTC phase/deadline判据标明不适用。**旧adapter段含Runtime日志复制，新段不含；新日志复制位于commit_end与wait_begin之间。** 后续应比较上一结果观察到下一commit的实际窗口、全部非零反馈及重外环拍，不能仅比较adapter一列就宣称通过。提交前减少了49个double重复复制，另41字段日志移后，总CPU仍消耗该日志复制。首记录先计算再START，帧关系不变；同帧50µs与WCET仍未签核。结束后保存原始数据交Review，不自动合并。
