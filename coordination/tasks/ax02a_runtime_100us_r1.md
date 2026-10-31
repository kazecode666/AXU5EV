## 下一轮任务规划｜AX-02A：把 TTC 板测映射用于 R5 Runtime，复验 P1000

规划基点 `54abd787fb64355d8039c9f39eb6cf77f2d12555`，接续 Issue15 和 TTC-only 任务。以下是待办，不是已实现或已启动 Codex/硬件。只在现有分支小步提交；Codex 离线实施 → Review → 用户本人上板。保持 PR Draft、不合并。

**为什么现在回到 Runtime：**用户的 `ttc_aba_01` 三组各 1000 次真实 IRQ。A1/B/A2 的 raw 寄存器读回为 10000/9999/10000，复算的事件周期约 10000.99999/9999.99999/10000.99970 个计数。在副本上按 uint32 还原两个通道基址和 build_id 后，按全窗口判据得到 `RAW_PLUS_ONE_COMPATIBLE`、`repeatable=true`、无 issues。证据只覆盖本板 TTC0 内部同源、不分频、间隔模式；未运行生成算法，不能把它写成完整 A5 PASS。无需重复 A—B—A，也不做可选 C。

**T1｜离线闭合实测证据与读回问题，独立提交。** 保留 `ttc_aba_01/{A1,B,A2}` 的原始 run.json/samples.bin 不变。在新分析目录复现三个数值和联合结论，保存精简报告。正式修复 `readback_ttc_characterize.tcl`：XSDB 符号地址支持单个整数及4个小端字节（`48 107 16 0` → `0x00106B30`），验证字节长度和值域并与本候选地址核对；写 JSON 时仅对协议中相应 uint32 元数据做有检查的无符号序列化，尤其 `periodic_base=0xFF110000`、`timestamp_base=0xFF110004`、此次构建编号 `3113983656`。旧数据只读兼容；不删/改样本、不跳过地址或构建身份核对，负面测试覆盖越界/错地址/错构建/短读。项目状态应区分“ABA 实测完成”和“Runtime 候选未上板”。

**T2｜核心：最小修正带生成 Runtime 的定时平台层。** 在 `firmware/r5/ax02a/timing.c::ax02a_timing_prepare()` 先确定逻辑计数，再映射寄存器；对已验证的 TTC0 通道、内部同源/100 MHz 配置、无分频、10 kHz 目标，`hardware_interval=9999`，`logical_period_ticks=10000`。快照/`timer.interval` 保存真实硬件值；`timer.period_ticks`、expected、deadline、释放超时及防回绕检查保持按10000。其他配置不无条件套用减一。**同步修正 `scripts/ax02a_analyze_run.py::validate_timer()`**：现实现要求 `interval × divisor == period_ticks`，会误拒新配置。通过明确的映射版本/候选身份区分历史与修正版（可用 run.json 元数据或候选记录，不必改 v2 二进制协议），旧数据按旧约定回放；新候选严查 9999/10000，拒绝配置不符。不要放宽趋势、数值或截止期判据。先写正反例，再改实现：覆盖旧漂移仍检出、新映射、raw 不符、逻辑周期误成 9999、错时钟/分频及漏拍超期。无需改 TTC-only 应用或厂商 BSP。

**T3｜离线构建，提交供 Review 即停止。** 应用为带原算法的 `ax02a_replay`，非 `ax02a_ttc_characterize`；复用已通过的 XSA、A53 FSBL→R5_0 split、生成 Runtime 和相同输入/参考、O2/FP/cache/布局。候选使用新 workspace（建议 `.runtime/ax02a/vitis_runtime_100us_r1`）；保留全部旧 workspace、ELF 和数据。交付 SHA、测试/构建实际结果、ELF/FSBL 路径、`--check-startup` 和简短 GUI 指南。禁改 Simulink、生成 C/H/SV、控制参数；不重跑 RTL、不改 JTAG/PLL、不连接探测/复位/运行板卡，不动功率级。

**T4｜Review 后用户手动验证。** 新候选 `mode=1, frames=1000`，current_motion 从第0帧起同一输入、参考、描述符，启用一次性后处理。保存计数器启动前 raw=9999/逻辑=10000 的只读快照；测量中不暂停/单步/读写。结束记录同一次独立目录的 run.json、output.bin 328000 B、timing.bin 64000 B、report_v2.bin 2400 B。成功必须同时满足：候选及 experiment 正确、未中断、1000帧完成；1000×41 数值按原容差0失败；序号正常、零截止期超限、最小余量>0；按既有相位阈值（回放软件首帧排除，999个ISR样本）无显著持续趋势，报告斜率/阈值与旧+0.99779 tick/帧对照；板上报告与PC原始数据分析一致。任一项失败/证据不足，保留首个异常、原始数据并停，不减到9998、不改expected、不放宽deadline。

**后续：**通过也只记“带 Runtime 的 100 µs 短段通过”。再补 A4 第二次独立完整运动＋对齐/复位，之后完整 A5；延长测试须先检查读回工具支持帧数，不能机械修改 P1000 参数。本轮不做 ADC/QEP/PS–PL/实物 FOC，不把 TTC 指定为最终电流环触发源。
