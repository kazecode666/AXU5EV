# AX-00 最小复验

工具实测：MATLAB/Simulink R2026b `26.2.0.3386108`，Vivado/xsim 2026.1，Python 3.14，PowerShell 7.6.5。使用本机已有安装，不升级或重装。以下从新仓库根目录运行；MATLAB每条命令是独立进程。日志和大数据输出到忽略的 `.runtime`。

```powershell
# matlab.exe 使用本机实际安装的绝对路径；下列是本机路径。
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('D:/Project/AXU5EV/scripts');ax00_run_case('frozen',0)"
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('D:/Project/AXU5EV/scripts');ax00_run_case('active',0)"
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('D:/Project/AXU5EV/scripts');ax00_run_case('frozen',1)"
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('D:/Project/AXU5EV/scripts');ax00_run_case('active',1)"
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('D:/Project/AXU5EV/scripts');ax00_compare"
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('D:/Project/AXU5EV/scripts');ax00_run_units('live')"
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('D:/Project/AXU5EV/scripts');ax00_run_units('alignment')"
python scripts/ax00_verify_assets.py
```

每条命令检查退出码。标准工况显式设为1 mm、1.2 s、V5/A50，初始化文件的用户默认不变。比较每个同名信号完整时间与数据，不做插值、容差放宽或PI修改。独立进程加载清单和 `which -all` 记录在 `coordination/reports/path_*.json`。资产校验默认仅依赖新库；`--check-source` 只供本机迁移保护审计，额外读取忽略的原始快照及旧源。

RTL smoke（每次用新的输出目录；示例目录已存在时不要覆盖或删除证据）：

```powershell
python scripts/m3_build_scoreboard.py --manifest generated/legacy_m3_p3/manifest.json --golden verification/m3_foc/directed_probe_source_hex.csv --out .runtime/ax00/rtl_stage/manifest.json --case ax00_p3_smoke --mode normal --frames 17 --timeout-seconds 600
pwsh -NoProfile -File scripts/m3_run_xsim.ps1 -Manifest .runtime/ax00/rtl_stage/manifest.json -RunDir .runtime/ax00/rtl_run -Mode rtl -Case ax00_p3_smoke -TimeoutSeconds 600
```

短RTL只重放PR53已保存的17帧源向量并检查状态/位/协议，不在此重新运行HDL生成或长随机测试。原生generated TB只是历史载荷；本轮用独立计数scoreboard，不以普通成功marker冒充位检查。

完整4.2 s机电对齐未重跑；对齐chart单元使用原10000/30000/2000计数，比较normal/no_start/reset/fault/reset_after_done五个7 s工况。旧MIL/DSP和StudyL1仅参考，未整套重跑。固定FOC已有sin/cos参数量化warning保留，不以旧M2例外放行新的溢出或平台问题。
