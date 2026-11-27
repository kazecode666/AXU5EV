# AXU5EV Motor Control Studio

Windows 桌面上位机通过 GEM3 TCP 操作无功率候选。启动时保持断开。SELFTEST 是内部自测，REAL IO 用于采集实机输入且保持功率硬禁。已运行的候选模式由固件报告。

## Windows 启动

在仓库根目录安装到本地虚拟环境，再运行启动脚本。

```powershell
python -m venv .runtime/studio/venv
.\.runtime\studio\venv\Scripts\python.exe -m pip install -r scripts/requirements-motor-control-studio.txt
.\scripts\start_motor_control_studio.ps1
```

使用 Python 3.10 或更新版本。Studio 使用 PySide6 Essentials 和 pyqtgraph，也可通过 `-Python <路径>` 使用已有环境。连接默认 `192.168.50.10:5002`，可按实验网实际设置修改。没有实板时可启动本机 C 服务／模拟 PL，窗口通过“离线回环”标识。

```powershell
.\scripts\start_motor_control_studio.ps1 -Demo SELFTEST
.\scripts\start_motor_control_studio.ps1 -Demo REAL
```

演示使用 PATH 或本机 MATLAB 支持包里的 GCC。也可用 `-HostCompiler <gcc.exe 路径>`。该入口编译并运行主机夹具，生成文件留在 `.runtime/studio/demo/`。

## 加载候选

| 用途 | 候选（位于 `.runtime/experiment/final/`） | Vitis 启动项 |
| --- | --- | --- |
| 无功率内部自测（旧版对照） | `GEM3_Control_SELFTEST_R01` | `Motor_Control_GEM3_SELFTEST_NoPower_R01` |
| Issue #44 timing（SELFTEST、复用 PR61 硬件） | `P61_TIMING_R02` | `Motor_Control_GEM3_SELFTEST_P61_Timing_R02` |
| PR61 无功率内部自测 + dq | `GEM3_Control_SELFTEST_P61_R01` | `Motor_Control_GEM3_SELFTEST_P61_NoPower_R01` |
| 真实输入、功率硬禁（B6-1） | `GEM3_Control_REAL_IO_R03` | `Motor_Control_GEM3_REAL_IO_NoPower_R03` |

“实验准备”页核对本地候选并生成 XSDB 辅助文件。也可通过命令行生成到新路径。

```powershell
.\scripts\start_motor_control_studio.ps1 -Prepare SELFTEST -Output .\selftest_no_power.tcl
.\scripts\start_motor_control_studio.ps1 -Prepare REAL -Output .\real_io_no_power.tcl
```

生成脚本时只读取本地文件。SELFTEST 选 Issue #44 timing R02，REAL 选 B6-1 R03。经现场授权后使用对应 Workspace 的专用启动项，在 R5_0 入口暂停时手动下载配套 bit 和执行 PS–PL 初始化，再手动继续 R5_0。[REAL IO 分段首板步骤](../firmware/r5/motor_control/FIRST_BOARD_REAL_R03_ZH.md) · [Issue #44 timing 候选](../firmware/r5/motor_control/IRQ_TIMING_ZH.md)

## 运行与回读

PR61 的 A/B/C 验收先用 Studio 完成 STOP、校准、CURRENT 选择与确认、CLEAR 和 ARM。断开 Studio 后再用 CLI 采 A、执行单次 START、采 B/C 并显式 STOP。Studio 和 CLI 不并发连接。用业务 sample 的 `mode` 核对实际运行。[实板验收记录](../coordination/reports/motor_control_gem3.md#pr61-无功率-current-实板验收)

- 在 SELFTEST，先点 **STOP 停止**，选择电流、速度、位置或对齐模式并提交相应给定，再点“确认选择”。清除故障并核对 CLEAR 后，显式申请 ARM，再执行 START 或“开始对齐”。运行给定单独提交。IDLE 通过 STOP 进入。模式下拉框编辑拟提交的模式，状态区显示固件已选择和实际运行的模式。
- 回执区显示命令的接受或拒绝和接受版本。帧回读分列模型消费、Host 回执、COMMIT 接受及当前 P0 采用，按数据有效性显示。连接和重连只读取身份、状态及观测。
- REAL IO 禁用运行和驱动复位。零偏校准会请求打开 J16 共享控制／反馈缓冲。满足 R03 首板指南的现场前提后，暂存两路本机实测的非零有符号 Q24 ADC 增益，再在真实零电流条件下显式发“零偏校准”。
- 图表按 PL 50 MHz 的 tick 绘制约 10 Hz 业务量。时间窗可切换为 10、20 或 60 秒，默认 20 秒。切换仅调整图表视野，保留最近 60 秒的显示缓存。通道可选，无效值、断连和新会话保留数据边界。“暂停绘图”冻结已绘制数据，仍可切换时间窗。STOP 始终位于顶部，在当前请求返回后优先发送。在途请求超时时连接中断，需重新核对设备状态和 STOP 回执。

## 记录与底层诊断

- **PC 实时趋势 CSV** 在“实时运行”页点击“开始保存趋势”，选择新文件。Studio 逐行保存现有约 10 Hz 样本响应，原样写入 PL tick、sample_id 和 groups，并记录有效标志、带单位的电流、电压、位置、速度及参考值。无效值留空。暂停绘图或切换时间窗时继续记录。点击“停止保存趋势”、断线或关闭 Studio 时结束当前文件。CSV 可用于较长的低频趋势记录，独立于显示缓存和固件 Trace。
- **固件 Trace** 在“实验记录”页依次“开始记录”“读取状态”“冻结记录”“下载 NDJSON”。既有固件最多保留 256 条，每至少 2 ms 尝试读取最近帧，连续满窗约 0.5 s，具体间隔以 tick 为准。下载按两帧分批进行，中断保留 `.partial`。可打开已完成 NDJSON 回看和导出 CSV，保留捕获 ID、原始 tick、采样 ID、有效组及有效标志。记录元数据保留跳过、重复及不连续状态。

底层诊断页按按钮读取一次。ADC、QEP、PWM 采用值、RTL 输出逻辑及实时计数均来自既有快照。Ud/Uq 图显示控制器计算电压。高速 PWM、100 μs 帧时序和实际引脚电平仍由现场 ILA 或仪器验证。[GEM3 通信协议](../integration/r5_ethernet/MOTOR_CONTROL_GEM3_ZH.md)

在本机回归时为夹具选用一个新输出目录。

```powershell
.\.runtime\studio\venv\Scripts\python.exe tests/test_motor_control_studio.py --output .runtime/studio/recheck -v
```
