# PR41 Review6846401773 Task A–D 实际执行报告

## 最终判定

**PWM_CUT_SDF_SLOW=FAIL（新TB握手唯一性断言）；FAST=NOT_RUN；FULL_CHAIN_SDF保持NOT_COMPLETED。没有完整动态PASS。** 本轮不是诊断计划：已实际查询DCP、修复源边界和runner、执行slow门级注释与首次动态。首次动态断言失败后停止，未改激励重跑，未运行fast。

## A：实际DCP查询

原DCP定向anchor源Q→anchor_delayed_reg/D查询154.512s完成。真实源50MHz posedge FDRE，目的同相100MHz FDPE；hold +0.244ns、setup +8.759ns。报告与路径定位留原1522目录，Git精简归档另收于task_a。未重做全设计STA/实现。

## B：实际修复

anchor及auto valid/compare/seq/inhibit使用posedge50MHz源寄存器+0.2ns局部Q模型；anchor仅一个50MHz周期20ns。保留同相2:1原关系，不用任意大延迟绕过时序；0.2ns并非真实物理路由值，未提取cut外/内分段延迟，不宣称跨层SDF覆盖。异步rstn/locked避开采样沿。旧36条断言全部保留，新44条，并要求最终3次anchor/start/peak非空。

真实35端口全部接线，原未接rresp提示已消除；finish_offer任务增加guard但两条XSIM43-4328固定参数wait提示仍存在，精确逐条归类，未放宽时序或SDF错误。普通WARNING不再一律误判为注释失败，未知warning仍停止。

## 前置构建失败原样保留

1522候选首次xvlog0.781s、exit1：VRFC10-3380 anchor在reg声明前使用，未到xelab/xsim。这是本轮我提交TB的声明顺序错误。其runner还错误利用日志附加路径中的sdf字样分类，原summary原样保留，不冒充SDF错误。

新buildfix候选仅将源always移至相关reg声明之后，并修runner诊断匹配不使用文件路径；刺激相位、0.2ns模型和所有断言没有改变。该前置编译纠正没有消耗xelab/动态尝试，实际新xelab及动态各一次。未隐藏第二次xvlog，见[前置纠正记录](<BUILD_CORRECTION.md>)。

## C：实际slow/max

|阶段|实际墙钟|退出/结果|
|---|---:|---|
|xvlog|0.782s|自然exit0|
|xelab O2（唯一一次）|10.250s|自然exit0，XSIM43-3452成功注释|
|xsim（唯一一次）|3.468s|930ns触发TB fatal，无PASS|

实际固定上限为600/3600/900秒；没有超时，没有关闭timingcheck/SDF互连/pulse检查。没有任何full design xelab。原native网表/SDF复用未编辑、未重导出，无文件哈希检查。

[动态日志](<slow/xsim.stdout.log#L14-L21>)：
- 804ns settled检查记录phase4997，源Q→对应PWM沿9.800ns。
- 810.200ns记录anchor宽20.000ns，pulse计数1。
- 834ns settled检查记录phase5000，第一组启动/peak序列已执行。
- 880.200ns首次offer seq1；930ns触发 **PWM_CUT_FAIL unique source offer**，phase5009、active_seq0。说明同一seq被源侧monitor判定为重复握手，尚未到第一次谷值采用。

截至930ns未记录到真实setup/hold/recovery/removal或SDF注释异常，只能说明已运行这一短区间；不能据此证明两角所有时序或所有场景通过。只读复核已识别我本轮TB的撤销语义缺陷：新增源寄存器后，task仍在握手后的negedge才撤销valid_request，实际valid要到下一posedge+0.2ns才撤销，于930ns又暴露一个源采样沿。旧直驱task与新源寄存器撤销延迟没有闭合。这足以解释源监视器重复握手断言，但没有记录两沿间ready变化，也不能证明内部DUT重复接收，不能据此认定生产DUT失败。Fatal中的seq=0是active_seq，不是首笔源seq1。按TaskD不修正再跑。整组、谷值、取消/锁定/重臂、死区与0/5000完整覆盖均未完成，启动最终3次条件也未完成。

## 退出状态解释

xsim日志明确fatal及930ns $finish后正常关闭工具。runner检测到fatal时尝试仅终止本次PID树，taskkill128表示这些PID已退出；原summary保留supervisor_stop、natural_exit=false及process exit0这一退出竞态。**process exit0不是动态PASS**，fatal和无PASS marker决定FAIL。全部本轮PID64880/69732/29992/66492确认不再运行。

## D：覆盖与收口

fast从未启动。保留1404旧hold FAIL及1522编译失败，不覆盖或改判；buildfix真动态结果见[summary](<slow/summary.json>)及[矩阵](<results.json>)。局部先前导出成果保留，未返回全量24h xelab。

fast_inhibit原BD恒零，其独立动态覆盖N/A。原全设计STA及整链RTL证据不变，上游FOC/ADC/reference重臂、外部clock/reset tree、真实跨切点互连均不由局部模型证明。任何后续修复需要另行Review授权，本轮不再调相位、延迟或删除断言重试。

无生产RTL/算法/参数/约束改动，无硬件实现/板卡操作，不合并PR、不关闭Issue。精简文本证据更新PR41；DCP/网表/SDF/缓存仅本地保存，不重新打包。
