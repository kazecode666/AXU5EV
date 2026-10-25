# PR53 p3 复现与操作

当前接受状态以本轮最终验收JSON为准。p3的硬件/数值、协议、OOC和重复生成必须分别通过；单个smoke或WNS为正不代表整体验收完成。原始B3失败构建、p1时序失败、p2生成失败、p3第一次状态映射失败均保留。

## 日常模型

原工程普通初始化与Run保持原流程。HDL开发运行在独立MATLAB `-batch`进程中，只给隔离副本应用属性；不要在已加载同名用户模型的交互会话里调用开发入口。脚本会拒绝这种调用，避免替换未保存内容。没有加入HDL到日常init/Run，也没有调整用户源的布局、连线或PI。

`candidates/p3/model/PMLSM_FOC_FixedPoint.slx`是带HDL/TB设置的构建副本，供检查配置；它保留最新本地源的21个系统布局/连线。不要把它覆盖到原模型，或在已有同名源窗口时再次打开。`generated_models/`中的gm/validation是本次实际生成模型，算法不手改；gm只有原9路数据接口，硬件global reset/CE由RTL测试验证。

## 从冻结输入精确复现

要求与报告一致的MATLAB/Simulink R2026b工具环境、Python、PowerShell7及Vivado2026.1。已验证Vivado路径为`E:/AMDDesignTools/2026.1/Vivado/bin`，MATLAB路径为`D:/Program Files/MATLAB/R2026b/bin/matlab.exe`。保持50MHz/20ns、5000拍/100us和2500拍/50us边界。

**裸调用`m3_foc_hdl('all')`保留原B3配置行为。要生成p3，必须先把实际候选JSON放入新的run目录。** 下列命令还复制8份实际冻结输入，避免当前用户文件的新改动改变来源身份；只创建/复制，不删除文件。

```powershell
$pr53Root = 'D:/Project/FPGA_XC7A200T'
$pr53Run = "$pr53Root/.runtime/pr53_frozen_recheck_001"
$pr53Report = "$pr53Root/docs/reports/m3_foc_hdl/pr53_pipeline_revision"
if (Test-Path -LiteralPath $pr53Run) { throw '请换一个新的run目录，保留已有证据' }
New-Item -ItemType Directory -Path "$pr53Run/source" -Force | Out-Null
$pr53Inputs = (Get-Content "$pr53Report/source_snapshot/identity.json" -Raw | ConvertFrom-Json).files
foreach ($pr53Input in $pr53Inputs) {
    Copy-Item -LiteralPath "$pr53Report/source_snapshot/$($pr53Input.path)" -Destination "$pr53Run/source/$($pr53Input.path)"
}
Copy-Item -LiteralPath "$pr53Report/candidates/p3/candidate.json" -Destination "$pr53Run/candidate.json"
& 'D:/Program Files/MATLAB/R2026b/bin/matlab.exe' -batch "addpath('$pr53Root/scripts'); r=m3_foc_hdl('all','$pr53Run'); assert(strcmp(r.status,'PASS'),'M3 full run failed; inspect retained results');" -logfile "$pr53Run/full.log"
if ($LASTEXITCODE -ne 0) { throw '本轮复验未通过，请查看run目录，不能覆盖旧记录' }
```

若要检查以后最新本地源，创建新目录、放入同一candidate.json，省略冻结source复制；入口会从原工程复制最新8份输入。新来源必须重新执行门禁，不能借用本次PASS。原B3复现则使用无candidate.json的新目录。

各阶段入口仍为`preflight/generate/model/rtl/synth/repro/all`。生成结束及普通TB生成之后锁定清单；候选属性先应用再回读，最终输出相位来自HDL Coder延迟报告。`repro`真实启动新子进程，重复使用同一候选JSON及源快照，比较全部原始SV/TB/data、配置和8源SHA；进程失败必须非零退出。

## 当前事务合同

九路输入在本帧第1拍之前的negedge建立，保持到第5000拍后才换下一组。正常clk_enable恒1；ce_out是快时钟使能。三相在第314拍post-edge共同观察。没有共同9路输入捕获器或原生frame-valid，外部协议按冻结相位判断；输出提交寄存器仍是预留1拍预算，不声称已实现外围适配。

PI/AW源递推与原100us采样不变。p3在PI状态旁路后增加1个快寄存器，PI观察提交在下一帧第1拍；原旧态消费仍检查第5000拍pre-edge。每拍D输入、保持、CE、同步global reset和原PI_Reset_EN分别检查，不以简单平移源状态取代。源/gm四个状态实际日志仍为100us、fi64/40；实际gm映射见`state_mapping_p3.csv`。初次p3旧提交映射FAIL另存，不能抹掉。

314+预留提交1+至少裕量1=316，须不超过2500。综合预检、理想时钟RTL仿真、板级/布线后时序属于不同证据；本轮外部I/O和布线后时序未签核。CE暂停21个物理边沿只作协议诊断，不改变正常deadline。

## 文件与复验结果

当前最终发布目录由主报告指明，候选原字节包在`generated/m3_foc_candidates/`。普通TB smoke用于依赖/搬移检查，严格source→gm及独立RTL位/状态检查才是数值门禁。1bit负例和实际第313拍提前观察负例必须被拒绝；工具原生exit0不等于PASS，严格运行器会检查错误、有效计数和退出。

原始MAT/DCP及完整工作目录保留在`.runtime/pr53_20261025/`。版本化报告包含实际SLX副本、配置、生成报告、逐位CSV、RTL计数/日志及OOC结果。冻结源副本保存了本次实际来源，原路径用户文件及未暂存修改仍保持原状。

已知两处辅助文字仍沿用基线：`m3_build_scoreboard.py`的cycle-negative描述/help写273，state_mapping文字写5000提交。它们不是判定逻辑；以manifest绑定的314/313数值、PI提交1/消费5000字段和实际checker日志为准。此两项已明确列为deferred Minor，没有据此放行任何测试。

完成后保持PR53开放等待Review；本轮不执行M4、place/route、bitstream或硬件操作。
