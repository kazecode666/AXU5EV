# ETH-01：Review后用户分步上板唯一入口

当前仅离线准备完成，PHY_LINK/TCP_IO/MODEL_BOARD_IO/BULK_TRANSFER全部 **NOT_RUN**。本指南的连接、上电、GUI启动、网卡与客户端命令均由用户本人执行。功率级断开，不接完整电机Runtime；不得用旧R1 ELF或旧同名launch。失败保存首次现场并停止，不自动改PHY寄存器/反复重试凑PASS。

## 1. 先核对文件，不连接板卡

仓库 `D:/Project/AXU5EV`，工具 Vitis2026.1。

| 项目 | 实际路径/名称 |
|---|---|
| XSA | `D:/Project/AXU5EV/.runtime/ethernet/eth01/ps_target/eth01_ps.xsa` |
| workspace | `D:/Project/AXU5EV/.runtime/ethernet/eth01/vitis_ethernet_r2` |
| platform / domain | `eth01_platform` / `r5_standalone`（psu_cortexr5_0、standalone） |
| application | `eth01_tcp` |
| R5 ELF | `D:/Project/AXU5EV/.runtime/ethernet/eth01/vitis_ethernet_r2/eth01_tcp/build/eth01_tcp.elf` |
| map | 上述build目录的 `eth01_tcp.map` |
| A53 FSBL | `D:/Project/AXU5EV/.runtime/ethernet/eth01/vitis_ethernet_r2/eth01_platform/export/eth01_platform/sw/boot/fsbl.elf` |
| launch文件 / 配置 | `eth01_tcp/_ide/launch.json` / **eth01_tcp_manual** |
| 构建身份 | `0x45303102`，与本次精简验证证据对应 |

```powershell
Set-Location D:/Project/AXU5EV
python scripts/eth01_build.py --check-startup
```

必须exit0、STARTUP_CHECK_PASS、workspace尾部为vitis_ethernet_r2。此命令只读文件，不启动调试器。确认R5 ELF32/Realtime/VFPv3-D16、A53 FSBL ELF64及实际launch核选择。旧R1和ETH01早期vitis_ethernet/vitis_ethernet_r1均保留，不能混用。不要重建已验证候选；构建方法在下节，仅为离线复现。

## 2. 离线复现入口（不下载）

MATLAB通过MCP执行：

```matlab
addpath('D:/Project/AXU5EV/simulation/ethernet');
START_ETH01('all');    % 原算法模型+真实C Caller目标模型+SoC消息探针仿真/生成
START_ETH01('host');   % 只localhost，生成C原生编译和相关测试
START_ETH01('check');  % 现有目标的纯文件检查
```

仿真后端为Dataset/内存队列，SoC消息探针不建socket。目标后端为ETH01_Target的C Caller→有界字节队列→NetService/lwIP。`generated/ethernet/eth01/`供Review，构建用MATLAB实际生成目录；不手改生成C。

全新XSA输出必须选不存在的目录：

```powershell
& E:/AMDDesignTools/2026.1/Vivado/bin/vivado.bat -mode batch -source hardware/axu5ev/eth01_ps_ethernet.tcl -tclargs xczu5ev-sfvc784-2-i .runtime/ethernet/eth01/reproduce_ps 资料/course_s2/01_ps_hello/vivado/ps_hello.srcs/sources_1/bd/design_1/design_1.bd
```

当前默认XSA为已生成的ps_target/eth01_ps.xsa。复用它复现软件时，复制 `build_config.json` 到新的明确配置文件，workspace改为同output下一个不存在的新候选（例如vitis_ethernet_reproduce_01）。在MATLAB使用`setenv('ETH01_CONFIG','该配置绝对路径')`后执行`START_ETH01('build')`；或在同一PowerShell用`$env:ETH01_CONFIG='该配置绝对路径'`后直接执行`& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -s scripts/eth01_build.py`。PowerShell环境变量不会修改已经运行的MATLAB进程。已存在workspace默认拒绝；`-- --resume`只用于本任务未验证完成的候选，不用于重建R1或已冻结候选。Vitis批处理launcher有时在Python异常后仍exit0，必须另查Build Finished successfully与新的startup_validation.json，再用普通Python纯文件检查；不能只凭launcher exit0判PASS。

若workspace被本次离线Vitis服务占用，待其退出；不要关闭用户其他Vitis会话。PHY适配源变化会拒绝旧overlay，另建候选/overlay，不静默复用缓存。

## 3. 用户接线及测试网卡

1. 确认电机功率级断开。连接PS UART、JTAG、PS以太网 **J6/PHY1**；PL网口第8页不使用。用户核对实物丝印/原理图，记录实际SoC完整料号、PCB修订及JL2121标记。
2. 用户确认 `192.168.50.0/24` 无现有网段/VPN/路由冲突，MAC `02:45:30:31:00:10` 无重复；同次仅一块此候选测试板。板IP192.168.50.10/24，TCP5001；PC专用测试网卡192.168.50.1/24，无网关/DNS。只修改选定测试网卡，保留其他网卡/VPN；不全局关闭防火墙。冲突则先停，由Review决定新候选地址，不能连接试探。
3. 用户打开PS UART，115200/8N1。稳定供电后再启动应用；RC复位并非软件GPIO，不能把名义RC常数当精确时序。首次保留完整串口日志。

## 4. 用户在Vitis启动新候选

用户可执行以下GUI入口；它会打开workspace，不等于授权Codex执行：

```powershell
& E:/AMDDesignTools/2026.1/Vitis/bin/vitis.bat -w D:/Project/AXU5EV/.runtime/ethernet/eth01/vitis_ethernet_r2
```

在应用的Debug配置中明确选 **eth01_tcp_manual**，不要选默认自动生成配置。核对A53_0初始化FSBL、R5_0应用、RPU split、programDevice关闭、无bitstream；Start/Stop at entry用于人工核对后，用户Continue R5。历史错误是将R5 FSBL交给A53_0执行，本候选必须使用表中匹配A53 FSBL。

串口顺序应包含：

```text
ETH01 R5_0 standalone build=45303102 I-cache=ON D-cache=OFF GEM3=ff0e0000 PMU/64 no TTC
ETH01 PHY addr=1 id=937c403x
ETH01 LINK <10/100/1000> Mbps full duplex (partner validated)
ETH01 TCP_READY 192.168.50.10:5001 MAC=02:45:30:31:00:10 DDR=10000000..11ffffff
```

ID低nibble是现场修订，不是要求必须某个x。ID mask只识别JL21xx家族；JL2121型号由实物/板资料确认。PHY_FAIL code1地址、2MDIO、3ID、4协商超时、5速率、6双工能力，或INIT_FAIL/BIND_FAIL均保存日志并停。没有无限协商、地址扫描、静默使用其他PHY或GPIO复位。

链路灯或用户必要时`ping 192.168.50.10`只能辅助；必须记录实际协商速率。百兆就记百兆。整个TCP测试期间R5要持续运行，不能停在main/完成断点后要求下载。调试暂停会导致超时，不能据此误判PHY故障；暂停后不要把被扰动会话作为吞吐证据。

## 5. 用户小数据及模型真实往返

用户每次选不存在的输出目录。只有以下显式`--ip`调用才连接指定板；import/build/model-load/test均不会连接板卡。

```powershell
python scripts/eth01_client.py --ip 192.168.50.10 --stage small --out .runtime/ethernet/eth01/board/small_01
```

该命令先读构建/cache/实际速率/初始模型计数，再逐次做0/1/255/256字节手写ECHO与 **模型生成代码** 的异或0x5A；核对原seq、每个模型消息计数增加1。result.json必须PASS。只有echo成功不能签MODEL_BOARD_IO；STATUS里的cache1表示I ON/D OFF。异常保存串口、result.json和.partial并停止。

## 6. 用户逐次大数据（前一步通过才执行下一步）

```powershell
python scripts/eth01_client.py --ip 192.168.50.10 --stage bulk --bytes 65536 --out .runtime/ethernet/eth01/board/bulk_64k_01
python scripts/eth01_client.py --ip 192.168.50.10 --stage bulk --bytes 1048576 --out .runtime/ethernet/eth01/board/bulk_1m_01
python scripts/eth01_client.py --ip 192.168.50.10 --stage bulk --bytes 33554432 --out .runtime/ethernet/eth01/board/bulk_32m_01
```

不要一次粘贴三条作为自动批跑。每条先上传确定性模式，目标核对完整CRC并seal，再分块读回；客户端逐字节核对模式、总长度、CRC，全部成功才从readback.bin.partial形成readback.bin。只访问专用测试DDR区，绝不装载/读取旧Runtime数据区。每次连接有新transfer，断线不复用未完成内容。

result记录方向、字节数、upload/download秒和MiB/s、实际初始协商Mbps、cache、错误与1MiB/s目标是否达成。HOST目录里的相同尺寸测试不能充当此处板测。吞吐未达目标按实报告，不减校验或把链路速率当有效吞吐。

## 7. 受控断线重连，仍逐步执行

完成前述三个尺寸后，用户另选如 `board/interrupted_01`，显式启动32MiB测试并在传输中按Ctrl+C；保留transfer.json.partial及已经产生的readback.bin.partial（上传阶段尚未读回时可能没有后者）。目标TCP超时/FIN结束后，用户另开新目录执行small，核对新连接/seq/计数；再按Review指定尺寸重做新transfer，不能续写旧结果。首次异常即停，不自动重试；不得删除原.partial或覆写旧目录。

客户端完整请求后half-close发送方向仍允许目标drain已接受回复；RST/链路中断会丢弃该会话部分帧和未发送回复，测试缓冲有效标记清除。R5持续服务才能等待ACK/超时、接受新连接。

回传完整串口、各result.json、保留的partial说明以及上电/暂停/cache/网线/协商条件。Codex后续只读分析归档。本次交接停在Draft待Review，不自动上板、合并、关闭Issue15或接入完整电机Runtime。
