## 承接 Review6847609985：统一源握手后在native cut接受条件处硬停止（1/3候选）

服务器DeepSeek Harness（GPT-6.1 Sol）独立完成，未用本地Codex、未操作板卡。

- v1唯一同步源驱动器闭合实际valid&&ready&&!inhibit握手及同沿+0.2ns撤销；offer/finish_offer/取消恢复统一协议。全部44关键check完整保留，fixed-task wait提示已消除，没有force、改相位/CQ或放宽断言。
- 独立xvlog预检1.047s exit0；正式slow xvlog0.766s、xelab10.250s均自然exit0，XSIM43-3452注释成功，无warning。
- **首笔910ns源握手，910.2ns实际valid下降；930ns没有重复源握手。** 但真实native capture_ce0、busy/request0，模拟100–500us仍offers1/accepts0/adoptions0/acks0。不是只凭exit0或runner心跳判定。
- 新的只读native证据：冻结使能LUT5 INIT08000000仅bit27=1，即cut输入inhibit=1才成立；RTL合法inhibit=0握手地址19的CE为0。request_i_1 LUT2 INIT7在inhibit=0时使busy/request同步reset为1。ready可同时为1，与实测吻合。
- **现有native cut端口直接语义与RTL接口接收条件不一致**。可能涉及RETARGET/跨层pin inversion/导出边界模型，尚不能断言生产RTL或硅实现有错；也没有依据认定为新的TB-only小错。因此触发“疑似DUT/无法归类”硬停止，而非反转inhibit、延长valid或更改0.2ns试PASS。使用1/3候选，未创建v2/v3。

|验收项|本轮状态|
|---|---|
|PWM_CUT_SDF_SLOW|FAIL_HARD_STOP：native边界疑点|
|PWM_CUT_SDF_FAST|NOT_RUN：slow未完整通过|
|FULL_CHAIN_SDF|NOT_COMPLETED|
|原全设计STA/全链RTL|原证据不变，未重跑|

最后runner记录xsim84.469s/模拟500000ns；整受管作业95.992s后监督终止，进程确认已清理，不是自然完成、预算耗尽或5ms watchdog报错。无完整PASS marker，无新timing/SDF/fatal诊断记录，但完整时序/功能覆盖远未完成。3次anchor/start/peak、11/11交易、8采用/回执、3取消恢复以及完整死区/边界场景均未签收。旧summary保留RUNNING中断快照，最终判定在HARD_STOP/results另记。

[集中报告](<https://github.com/kazecode666/AXU5EV/blob/codex/motor-control-chain/verification/motor_control/evidence/pwm_cut_windows_20261113_03/RESULT_REPORT.md>) · [首笔真实trace](<https://github.com/kazecode666/AXU5EV/blob/codex/motor-control-chain/verification/motor_control/evidence/pwm_cut_windows_20261113_03/v1/slow/xsim.stdout.log#L18-L31>) · [原生cone只读摘录](<https://github.com/kazecode666/AXU5EV/blob/codex/motor-control-chain/verification/motor_control/evidence/pwm_cut_windows_20261113_03/native_cone_excerpt.txt>) · [最终矩阵](<https://github.com/kazecode666/AXU5EV/blob/codex/motor-control-chain/verification/motor_control/evidence/pwm_cut_windows_20261113_03/results.json>) · [TB](<https://github.com/kazecode666/AXU5EV/blob/codex/motor-control-chain/verification/motor_control/evidence/pwm_cut_windows_20261113_03/v1/pwm_cut_tb.sv>) · [runner](<https://github.com/kazecode666/AXU5EV/blob/codex/motor-control-chain/verification/motor_control/evidence/pwm_cut_windows_20261113_03/v1/run_corner.py>)。

旧_01/_02失败证据不覆盖。既有结构保留不等于边界逻辑极性功能等价，需要Review现有native边界映射语义后再授权下一步。未重新查询/导出DCP、重综合/实现、修改生产RTL/约束/电机参数或网表/SDF，未SHA核查、打包同步；fast_inhibit原BD恒零独立动态N/A。PR41继续Draft、Issue40开放，未自动合并或关闭。
