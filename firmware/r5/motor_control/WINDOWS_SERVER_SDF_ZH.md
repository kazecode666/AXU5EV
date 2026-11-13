# Issue40 / PR41：Windows服务器手动SDF

> 2026-11-13当前状态按[PR41 Task 1](https://github.com/kazecode666/AXU5EV/pull/41#issuecomment-6850181652)整理。本页归档已结束的完整SDF尝试，以下O0/24h计划和命令均属历史。完整网表O0后端编译ICE、O2 xelab 24h超时，FULL_CHAIN_SDF=NOT_COMPLETED，完整fast/min仍NOT_RUN。最终PWM cut局部slow/max与fast/min均PASS，见[结果报告](../../../verification/motor_control/evidence/pwm_cut_windows_20261113_04/RESULT_REPORT.md)。服务器暂停，局部SDF工作线收口，当前没有待执行的仿真命令。板测与R5采集连续性仍NOT_RUN，尚无现场执行授权；当前验收见[HANDOFF](../../../coordination/HANDOFF.md)。

按PR41评论6784312486执行并行计划。用户在Windows服务器运行hardware_02完整功能PL的两角SDF，本地同时按FIRST_RUN_ZH.md准备现有产物的有限无功率板测。两条线各自推进并归档，最后统一Review，PR41保持Draft。

2026-11-10 14:18本机O0候选停止及所属进程剩余0的记录保留为历史，注释和动态尚未完成。本指南由用户在服务器手动执行，服务器状态依据实际启动和结果回执更新。GitHub Release继续提供既有运行包，产物对应关系以本轮HANDOFF/results核对记录为准。

## 1. 下载并分开解压

从[本轮Release](https://github.com/kazecode666/AXU5EV/releases/tag/issue40-windows-sdf-20261110)下载三个附件：

- [原完整输入包](https://github.com/kazecode666/AXU5EV/releases/download/issue40-windows-sdf-20261110/AXU5EV_Issue40_SDF_hardware_02_0bd081a.zip)：`AXU5EV_Issue40_SDF_hardware_02_0bd081a.zip`
- [Windows入口小包](https://github.com/kazecode666/AXU5EV/releases/download/issue40-windows-sdf-20261110/AXU5EV_Windows_SDF_Entry_20261110.zip)：`AXU5EV_Windows_SDF_Entry_20261110.zip`
- [两个zip的SHA256清单](https://github.com/kazecode666/AXU5EV/releases/download/issue40-windows-sdf-20261110/SHA256SUMS.txt)：`SHA256SUMS.txt`

若已有同一候选正在运行，先核对其原始启动命令、commands.json及当前阶段process.json中的timeout_ms，保留现有结果目录并让该任务继续。新预算在启动前设置，现有入口不支持运行中热改预算。以下下载、解压和启动示例供尚未启动的新任务使用。

把附件放到一个新目录，以下示例用`D:\AXU5EV_Issue40_20261111`，按服务器实际盘符修改。已有文件与结果目录保留，解压时不用Force覆盖。

```powershell
$TaskRoot = 'D:\AXU5EV_Issue40_20261111'
# 先将三个附件放到TaskRoot，再校验两个zip
Get-Content -LiteralPath (Join-Path $TaskRoot 'SHA256SUMS.txt') | ForEach-Object {
    if ($_ -match '^([0-9a-fA-F]{64})\s+\*?(.+)$') {
        $ExpectedHash = $Matches[1]
        $AssetPath = Join-Path $TaskRoot $Matches[2]
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $AssetPath).Hash -ine $ExpectedHash) {
            throw "SHA256不匹配：$AssetPath"
        }
    } elseif ($_.Trim()) { throw 'SHA256SUMS.txt格式不正确' }
}
Expand-Archive -LiteralPath (Join-Path $TaskRoot 'AXU5EV_Issue40_SDF_hardware_02_0bd081a.zip') -DestinationPath $TaskRoot
Expand-Archive -LiteralPath (Join-Path $TaskRoot 'AXU5EV_Windows_SDF_Entry_20261110.zip') -DestinationPath $TaskRoot
$PackageRoot = Join-Path $TaskRoot 'AXU5EV_Issue40_SDF_hardware_02_0bd081a'
$EntryRoot = Join-Path $TaskRoot 'windows_sdf_entry'
$Start = Join-Path $EntryRoot 'START_SDF_WINDOWS.ps1'
```

原zip保持38,281,015字节，SHA256为`6932398ee982936da54521c60d5bd978234c5bd55698e76de720910fb509e05b`。入口小包展开为`windows_sdf_entry`，包含START_SDF_WINDOWS.ps1、sdf_runner.py、README_ZH.md和SHA256SUMS。新入口位于原包之外，显式把Hardware和TB指向原包；不替换原包脚本、不修改网表/SDF，因此原包9项输入校验继续有效。入口每次启动前会核对原包完整性。

## 2. 配置已有工具并dry-run

使用服务器已有的Vivado/XSim2026.1和Python3.10或以上，令`python`命令指向该安装。Vivado须具备匹配的simprims_ver、unisims_ver、secureip及glbl；本地来源为SW Build6511674，已知额外补丁未在原日志标识。工具、许可证及凭据不在附件中，不自动安装或修改服务器配置。

```powershell
python --version
$VivadoBin = 'C:\AMDDesignTools\2026.1\Vivado\bin'  # 改为已有安装的实际bin路径
$CheckRoot = Join-Path $TaskRoot 'checks_01'          # 使用全新路径
& $Start -PackageRoot $PackageRoot -VivadoBin $VivadoBin -ResultRoot $CheckRoot -Corner slow -DryRun
```

DryRun只做输入与命令检查，不启动工具。核对`checks_01\dry_slow_01\commands.json`：使用原hardware_02完整网表、slow SDF及当前事件TB；xelab只增加O0编译候选，保留debug off、原mt策略、1ps精度和全部时序参数，不定义MC_TIMING_RTL。不要直接调用旧包中的旧入口启动本次候选。

先用`& (Join-Path $VivadoBin 'xelab.bat') --version`核对2026.1。旧入口默认每工具60分钟，本计划在启动前通过`-ToolTimeoutMs 86400000`显式设置24小时/工具预算。该值用于资源预算，用户也可在启动前选择更大值。若下载标记拦截项目脚本，在完成SHA256校验后对所下载zip使用Unblock-File再解压。不要为本任务修改全局执行策略。

新入口只传入`--xelab-o0`，实际xelab参数为`--O0`，不带`--xelab-diagnostics`或verbose1。此前verbose1的INFO实例路径`error_register_out1_reg`会触发现有宽匹配规则；本轮保持真实timing、SDF error/warning及动态判据，不启用该详细日志选项。O0仍是单变量候选，未证明解决旧xelab性能瓶颈。

## 3. 先slow/max，通过后再fast/min

```powershell
$ResultRoot = Join-Path $TaskRoot 'run_parallel_01' # 本轮全新结果根目录
$TimeoutMs = 86400000                            # 24小时/工具，启动前设定
& $Start -PackageRoot $PackageRoot -VivadoBin $VivadoBin -ResultRoot $ResultRoot -Corner slow -ToolTimeoutMs $TimeoutMs
```

允许同一配置在既定预算内自然长运行，超过六小时本身不判失败。必要观察限于进程存活、明确错误和资源状态，日志暂时不增长时继续保留运行状态。本轮沿用现有O0配置，停止参数搜索与性能诊断支线。

等待命令完成，查看`run_parallel_01\slow_01\summary.json`。只有status为PASS、corner为slow、xelab_o0为true且使用同一hardware路径，才允许启动fast。入口也会校验这些条件；自然退出0、kernel生成或注释完成中的任一项都不能单独代替最终PASS。

```powershell
$SlowSummary = Join-Path $ResultRoot 'slow_01\summary.json'
Get-Content -LiteralPath $SlowSummary -Raw
& $Start -PackageRoot $PackageRoot -VivadoBin $VivadoBin -ResultRoot $ResultRoot -Corner fast -SlowSummary $SlowSummary -ToolTimeoutMs $TimeoutMs
```

服务器两角依次执行，fast使用同一ResultRoot下新的`fast_01`，不覆盖`slow_01`，也不复用其SDF快照。明确失败、超时或用户取消时保存完整现场并报告，后续执行等待Review决定。结果目录已有时选择新的根目录，旧现场保留。

服务器SDF与本地有限无功率板测各自推进，本地使用现有bit/ltx/XSA与匹配R5产物，步骤见FIRST_RUN_ZH.md。工具或资源故障单独记录，本地板测可继续。若取得DUT时序或功能失败证据，暂停受影响的本地功能场景并报告具体范围。

## 4. 取消、判定与回收

需取消时，在另一个PowerShell终端设置相同ResultRoot并创建对应文件：

```powershell
$ResultRoot = 'D:\AXU5EV_Issue40_20261111\run_parallel_01'  # 与运行终端一致
New-Item -ItemType File -Path (Join-Path $ResultRoot 'CANCEL_slow_01')
# 取消fast时改用CANCEL_fast_01；两者各只创建一次
```

等待运行器保存日志并清理本轮Windows Job，不按进程名批杀其他Vivado/Python任务。缺最终summary、仍为RUNNING、清理失败或缺注释确认均不能认PASS；保留实际自然退出码与监督终止原因，不把停止记成DUT断言失败。

通过仍要求成功SDF注释确认、唯一动态PASS、无真实SDF警告/错误或时序违例，以及同帧捕获、三相整组、目标谷值、晚到取消、disarm、失锁显式重臂、互补死区、80字快照的全部事件检查。不得用RTL预跑、STA或减少场景替代。

回收整个ResultRoot，包含两个角的commands.json、summary.json、所有process/启动记录、stdout/stderr/console及厂商原生日志、foc_frames.txt、motor_frames.txt和取消文件；另附两个zip的SHA256、服务器Python/Vivado版本与实际命令。失败目录同样完整保留。未运行的角写NOT_RUN，未完成注释写NOT_COMPLETED，局部通过只记实际边界。服务器精简回执可归档至verification/motor_control/evidence/server_sdf_20261111，完整大日志保留原产物位置。

服务器结果与本地板测、R5采集连续性在results/HANDOFF分别记录。两条线完成后回到同一PR41统一Review，保留所有未完成项。板卡现场操作及协助授权按FIRST_RUN_ZH.md执行，PR41保持Draft，不自动合并、关闭Issue或关机。
