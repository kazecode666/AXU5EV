# 混合闭环运行入口

日常操作已统一到 **[simulation/README_运行说明.md](../simulation/README_运行说明.md)**。进入`simulation/`，只编辑`init_AXU5EV.m`，运行`START_HERE.m`，再点击Hybrid的Run。默认`model_fixed`、10 mm、5 s、V10/A100；停止后可选`c_fixed`或`c_rtl`。

普通Run不编译，不反复恢复默认目标。首次C/RTL允许构建缺少的产物；修改Runtime算法、向量顺序或编入C的参数后，使用当前已初始化参数显式重建：

```matlab
axu5ev_prepare('c_fixed',true);
```

Hybrid是带电机的完整闭环；Runtime是Host/轨迹/外环/原对齐的C生成入口；Control是独立组件来源，修改不会自动同步Runtime或MEX。三个模型及活动依赖均在`simulation/`，保留用户紫色区域布局。

输入Mux/Demux同步采用`[11 3 1 1 1 1 1 1]`；1:11命令、12:14 replay、15速度、16:19对齐/Start/Reset/故障、20位置。两端有旁注，详见[接口](../integration/ps_pl/INTERFACE.md)。

同次Run的目标确认、Send双向翻转、Ready/Busy、手动对齐、复位及重建条件以同目录说明为准。Dashboard绑定通过MCP核对；本轮不使用Computer Use，真实鼠标/输入框操作验证NOT_RUN，说明中提供最短人工步骤。

[Issue #8修复结果及边界](../coordination/reports/issue8_manual_run.md)。PR #7已合并，其[原报告](../coordination/reports/ax01b_runtime_hybrid.md)及`ax01b_run_closedloop`的1 mm脚本结果作为历史保留，不替代当前10 mm默认验收。原p3 SV、100 µs软件/1 ms速度/10 ms位置、1 µs对象、50 µs应用及一次死区继续复用。

当前仍为Windows主机功能仿真；R5执行、AXI、5EV综合/布线、ARM实测和实机均NOT_RUN。禁止自动烧录、功率级上电或合并PR。
