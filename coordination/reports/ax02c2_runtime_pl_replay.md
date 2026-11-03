# AX-02C2：真实R5 Runtime与PL帧同步回放

仓库`kazecode666/AXU5EV`，依据[Issue23](https://github.com/kazecode666/AXU5EV/issues/23)，2026-11-04从包含已合并PR22的`origin/main`建立`codex/ax02c2-runtime-pl-replay`。用户四份模型/参数修改及两个未跟踪源文件原样保留；没有stash/reset/clean、额外clone/worktree或数据搬移。

离线实现、必要模型/C适配对照、原生R5构建及现有启动文件检查已PASS，已提交[kazecode666/AXU5EV Draft PR24](https://github.com/kazecode666/AXU5EV/pull/24)，待Review、不自动合并。C2新应用完整板测为NOT_RUN；C1已经验收的17帧/51duty实板结果直接继承，不再运行。任务书随实现保存于[AX-02C2](../tasks/AX-02C2.md)。

## 调度和数据索引

唯一完整场景为`current_motion`，64536条记录；Runtime每逻辑100µs一步，内部1ms/10ms事件及首相不变。PL同一名义50MHz时钟、每帧5000拍；不启用TTC IRQ作为第二套调度。

| 阶段 | 记录索引 | R5逻辑步 | PL帧 | 命令序号 |
|---|---:|---:|---:|---:|
| 首帧准备，PL尚未START | 0 | 0 | 将启动1 | 1 |
| 读回当前帧，再准备下一记录 | k读回，随后k+1准备 | k+1 | k+1读回，下一帧k+2 | k+2 |
| 最后结果读回并请求完整停止 | 64535 | 已完成64536次step | 64536 | 64536 |

首帧先真实Runtime step、模型薄适配及共同提交，再START。当前帧结果在AXI发布后，读入RAM，计算下一记录的Runtime与适配并提交pending；下一完整边界才采用。最后一帧结果后请求STOP_AFTER_FRAME，等待完整5000拍结束。每条记录仅step一次；不逐帧初始化PI或重启PL。

这是已知记录预装下一帧的连续协同回放，不是未来真实ADC反馈；计算/交换窗口独立记录，不声称同帧50µs端到端控制验收。PMU CPU/64只用于计时，不套用旧TTC IRQ相位/100MHz换算。

## 复用边界

同源物理记录为`.runtime/ax01c/c_fixed_continuous.mat`，包含64536拍原三相电流、真实角度、机械速度/位置以及20输入/41输出。当前Runtime输入/参考沿用`.runtime/ax02a/replay/current_motion`及冻结的Cortex-R目标代码（与ETH02来源一致）；其参考采用较新的Runtime参数，故原MAT中的历史duty不直接作为本轮golden。FOC参考须由同源物理反馈、本轮Runtime参考以及从原模型生成的薄适配共同计算，不能混用历史电流参考。

同源映射实查：原MAT的旧`r5_commit`＋同次物理反馈，通过复制出的原薄模型后，与同MAT已记录`foc_frame9`的64536×9＝580824个量化字段逐值一致。此核对确认theta/x/Tau_e接线和索引来源；新参考改用当前Runtime的41输出，不能直接沿用旧duty。

继承`hardware/axu5ev/ax02c_ps_pl.tcl`中AUX接1、debug reset接0，沿用`.runtime/ax02c/hardware_02/ax02c_ps_pl.bit`和同目录XSA。FOC/AXI RTL、50MHz/5000拍、九字段寄存器及C1复位关联证据沿用；接口未改则不重新生成HDL、不综合或布局布线。

传输复用ETH02的TCP文件对象、分块和CRC及GEM停收发/DMA/IRQ后执行、冻结再恢复下载。新增C2对象和身份；原ETH02独立使用。Runtime算法和适配来自模型生成，不手改生成C/SV。

新增对象9为每记录5个double物理反馈，10为32字节PL结果（record_index、runtime_step、pl_frame、command_seq、adopted_seq、三相duty）。对象1/2/3仍为20输入、41参考和原32字节描述符；4/5/6/7/8仍为Runtime输出、计时、数值报告、run.json和配置。C2计时对象改用独立64字节`AX02C2_PMU16_V1`，不当作旧TTC记录解析；原数值比较器以mode0复用，其TTC时序项不运行。

64536条记录的固定DDR对象范围如下，结束地址不包含在范围内；应用、GEM缓冲、堆栈需在实际map中确认低于`0x10000000`。

| 对象 | 起始 | 字节数 | 结束 |
|---|---|---:|---|
| Runtime输入 | 0x10000000 | 10325760 | 0x109D8F00 |
| Runtime实际输出 | 0x11000000 | 21167808 | 0x1242FEC0 |
| 参考描述符 | 0x12F00000 | 32 | 0x12F00020 |
| C2 PMU记录 | 0x13000000 | 4130304 | 0x133F0600 |
| Runtime参考 | 0x14000000 | 21167808 | 0x1542FEC0 |
| 原数值报告 | 0x16000000 | 2400 | 0x16000960 |
| 物理反馈 | 0x17000000 | 2581440 | 0x172763C0 |
| PL实际结果 | 0x18000000 | 2065152 | 0x181F8300 |

## 实际结果和产物

| 项目 | 实际结果 |
|---|---|
| 同源数据及旧记录字段映射 | PASS，64536拍，580824个量化字段一致；[来源](../../verification/ax02c2/data_source.json) |
| 最终薄适配生成C与复制模型比较 | PASS，709896个整场寄存器字＋8条必要语义输入的88个字，零差；[结果](../../verification/ax02c2/adapter_check.json) |
| 同源FOC参考 | 已实际运行原model_fixed模型，得到64536×3的uint32 duty参考；未运行RTL |
| 最终Vitis原生构建 | PASS，`AX02C2_BUILD_PASS`、退出0，应用编译0 warning |
| 已有被动启动检查 | PASS，ARM32 R5／AArch64 FSBL，身份及MMIO地址正确，未链接TTC调度；[结果](../../verification/ax02c2/startup_check.json) |
| 实际linker/map与对象布局 | PASS，全部PT_LOAD、GEM、heap、stack低于0x10000000，与8个回放区不重叠；[布局](../../verification/ax02c2/memory_layout.json) |
| Python及MATLAB入口 | Python AST解析通过，RUN_AX02C2 Code Analyzer无问题；入口检查没有发起网络连接 |
| 新应用一次完整current_motion板测 | NOT_RUN，按用户最新要求本轮仅离线交付，随后正常关机 |

薄适配复制原`Alignment_Interface`、`Effective_PI_Reset`、`PWM_Disabled`及`Frame_Quantization`；Runtime实际Y14提供Vdc，实际Y1/Y2为id/iq，实际模式/偏置/PWM/复位与同索引记录一同进入原选择和Convergent/Saturate转换。反馈5为ia/ib/ic、原theta_true及原已量化的s40/24角速度；本场景Alignment_Enable始终0。Tau_e为60mm，原角度与位置圆周误差最大约1.13e-15rad，原速度与Runtime输入15逐样本相同；48V来源同时由原记录及当前Runtime参考核对。

只有11字寄存器的整数拆分由API包装完成，选择和量化均来自生成C；40位保留低32与高8有效位。ARM联编实际发现生成multiword helper将int32_t*传给frexp(int*)不兼容，已仅开启薄模型的`ProdLongLongMode=on`，使用编译器支持的int64_t表达原40位，不改Q格式或算法。最终生成C对同一已有q完整对照PASS，没有重算golden。Windows公共头文件与生成头文件大小写重名已改为`ax02c2_adapter_api.*`。较早未交付的workspace及失败/警告日志保留，最终候选仅为下表native64目录。

| 产物 | 实际路径，均以D:/Project/AXU5EV为根 |
|---|---|
| 唯一Workspace | `.runtime/ax02c2/vitis_runtime_pl_native64` |
| Application / Launch | `ax02c2_runtime` / `ax02c2_runtime_manual` |
| R5 ELF，1015452字节 | `.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_runtime/build/ax02c2_runtime.elf` |
| A53 FSBL，341352字节 | `.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_platform/export/ax02c2_platform/sw/boot/fsbl.elf` |
| 新应用map | `.runtime/ax02c2/vitis_runtime_pl_native64/ax02c2_runtime/build/ax02c2_runtime.map` |
| 复用bit / XSA | `.runtime/ax02c/hardware_02/ax02c_ps_pl.{bit,xsa}` |
| 实际Cortex-R Runtime源 | `.runtime/ax02a/target/codegen/AXU5EV_R5_Runtime_ert_rtw` |
| 最终薄适配C源 | `.runtime/ax02c2/adapter_native_01/adapter_01/codegen/AX02C2_Adapter_ert_rtw` |
| 完整实验输入及参考 | `.runtime/ax02c2/prepared_04/data/current_motion` |
| 最终成功日志 | `.runtime/ax02c2/vitis_native64.log` |
| 新实验输出预定目录，尚未运行 | `.runtime/ax02c2/board/current_motion_01` |

实际GEM BD为0x00400000..0x00500000、heap为0x00508320..0x00548320（256KiB）、stack为0x00548320..0x00558320（64KiB），结束地址不含。最终应用text/data/bss为141543/5516/3513120字节。平台/FSBL保留原厂emacps配置初始化、deprecated类型和原PS宏等生成警告；应用无新增警告，没有修改厂商代码来消除这些既有提示。

生成入口为`simulation/axu5ev_prepare_ax02c2_data.m`，仅在独立MATLAB batch经MCP执行，复制薄模型及原model_fixed FOC，不保存用户模型。`axu5ev_generate_ax02c2_adapter.m`可只重新生成薄适配而复用已有数据；最终对应检查脚本位于`verification/ax02c2/verify_adapter.m`。本轮没有重跑C1、完整历史RTL、TTC ABA、ETH02旧板测或另一完整alignment场景。构建入口为`scripts/ax02c2_build.py`（本机原生`vitis.bat -s`，独立任务XILINX_VITIS_DATA_DIR）；已验证候选的保护不变，不覆盖旧Workspace。

操作入口见[唯一指南](../../firmware/r5/ax02c2/FIRST_EXPERIMENT_ZH.md)。MATLAB的`RUN_AX02C2`调用薄Python入口，实际upload/download直接复用ETH02的Connection实现；该共享类只增加默认仍为旧身份的可选expected_build参数。新固件身份0x43324301，原FOC模块身份0x43314301不改。`runtime`计时不含输入复制；`adapter`统计包含Runtime输出复制；提交/读回/结果观察间隔均是本次PMU窗口，不是硬件测频、TTC IRQ相位或WCET。

用户本次原先授权C2新镜像加载及一次完整`current_motion`，并已说明会接回原ETH02直连网卡并设192.168.50.x；之后最新明确要求“完成离线实现后关闭计算机”。因此本轮停在离线实现与Draft PR交付，不连接、复位、加载或运行C2，板测留待后续继续。交接推送完成后正常关机，不强制关闭或代保存未保存窗口。功率级保持断开，不写启动介质；授权不扩展为无限实验轮次。原R1/ETH01/ETH02/C1工作区和数据保留，不自动合并、不关闭Issue15。
