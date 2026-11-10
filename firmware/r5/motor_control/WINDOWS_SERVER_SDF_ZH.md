# Issue40 / PR41：Windows服务器手动SDF

本机O0候选已按用户要求于2026-11-10 14:18停止，所属进程剩余0；注释和动态未完成。本指南供用户在Windows服务器手动执行。Codex不登录、安装或运行服务器，不操作板卡，不自动关机。GitHub Release为文件分发预发布，PR41仍为Draft，两角验收继续开放。

## 1. 下载并分开解压

从[本轮Release](https://github.com/kazecode666/AXU5EV/releases/tag/issue40-windows-sdf-20261110)下载三个附件：

- [原完整输入包](https://github.com/kazecode666/AXU5EV/releases/download/issue40-windows-sdf-20261110/AXU5EV_Issue40_SDF_hardware_02_0bd081a.zip)：`AXU5EV_Issue40_SDF_hardware_02_0bd081a.zip`
- [Windows入口小包](https://github.com/kazecode666/AXU5EV/releases/download/issue40-windows-sdf-20261110/AXU5EV_Windows_SDF_Entry_20261110.zip)：`AXU5EV_Windows_SDF_Entry_20261110.zip`
- [两个zip的SHA256清单](https://github.com/kazecode666/AXU5EV/releases/download/issue40-windows-sdf-20261110/SHA256SUMS.txt)：`SHA256SUMS.txt`

把附件放到一个新目录，以下示例用`D:\AXU5EV_Issue40_20261110`，按服务器实际盘符修改。已有文件与结果目录保留，解压时不用Force覆盖。

```powershell
$TaskRoot = 'D:\AXU5EV_Issue40_20261110'
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

先用`& (Join-Path $VivadoBin 'xelab.bat') --version`核对2026.1。入口每工具默认60分钟上限；需要另定预算时在启动前显式传入`-ToolTimeoutMs`，不在失败后自动加时重试。若下载标记拦截项目脚本，在完成SHA256校验后对所下载zip使用Unblock-File再解压；不要为本任务修改全局执行策略。

新入口只传入`--xelab-o0`，实际xelab参数为`--O0`，不带`--xelab-diagnostics`或verbose1。此前verbose1的INFO实例路径`error_register_out1_reg`会触发现有宽匹配规则；本轮保持真实timing、SDF error/warning及动态判据，不启用该详细日志选项。O0仍是单变量候选，未证明解决旧xelab性能瓶颈。

## 3. 先slow/max，通过后再fast/min

```powershell
$ResultRoot = Join-Path $TaskRoot 'run_01'  # 本轮全新结果根目录
& $Start -PackageRoot $PackageRoot -VivadoBin $VivadoBin -ResultRoot $ResultRoot -Corner slow
```

等待命令完成，查看`run_01\slow_01\summary.json`。只有status为PASS、corner为slow、xelab_o0为true且使用同一hardware路径，才允许启动fast。入口也会校验这些条件；自然退出0、kernel生成或注释完成中的任一项都不能单独代替最终PASS。

```powershell
$SlowSummary = Join-Path $ResultRoot 'slow_01\summary.json'
Get-Content -LiteralPath $SlowSummary -Raw
& $Start -PackageRoot $PackageRoot -VivadoBin $VivadoBin -ResultRoot $ResultRoot -Corner fast -SlowSummary $SlowSummary
```

fast使用同一ResultRoot下新的`fast_01`，不覆盖`slow_01`，也不复用其SDF快照。任何失败、超时、取消或未完成状态都停止并报告，不启动下一角，不自动重试或加时，不更换参数穷举。结果目录已有时选择新的根目录，旧现场保留。

## 4. 取消、判定与回收

需取消时，在另一个PowerShell终端设置相同ResultRoot并创建对应文件：

```powershell
$ResultRoot = 'D:\AXU5EV_Issue40_20261110\run_01'  # 与运行终端一致
New-Item -ItemType File -Path (Join-Path $ResultRoot 'CANCEL_slow_01')
# 取消fast时改用CANCEL_fast_01；两者各只创建一次
```

等待运行器保存日志并清理本轮Windows Job，不按进程名批杀其他Vivado/Python任务。缺最终summary、仍为RUNNING、清理失败或缺注释确认均不能认PASS；保留实际自然退出码与监督终止原因，不把停止记成DUT断言失败。

通过仍要求成功SDF注释确认、唯一动态PASS、无真实SDF警告/错误或时序违例，以及同帧捕获、三相整组、目标谷值、晚到取消、disarm、失锁显式重臂、互补死区、80字快照的全部事件检查。不得用RTL预跑、STA或减少场景替代。

回收整个ResultRoot，包含两个角的commands.json、summary.json、所有process/启动记录、stdout/stderr/console及厂商原生日志、foc_frames.txt、motor_frames.txt和取消文件；另附两个zip的SHA256、服务器Python/Vivado版本与实际命令。失败目录同样完整保留。未运行的角写NOT_RUN，未完成注释写NOT_COMPLETED，局部通过只记实际边界。

本轮仅无功率离线验证；不接完整Runtime、不改DUT/算法/时钟/PI/约束、不重建硬件/R5、不重跑旧全量、不裁剪、不连接或下载板卡。服务器运行结果回到同一PR41，保持Draft等待Review，不自动合并、关闭Issue或关机。
