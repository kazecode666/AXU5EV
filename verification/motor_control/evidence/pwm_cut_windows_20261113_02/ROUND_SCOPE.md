# PR41 Review 6846401773 — Task A–D

本轮由服务器独立完成，复用1404轮成功原生导出的PWM cut网表及slow/fast SDF；旧FAIL目录不变，不重打包、不同步本地、不做哈希/提交摘要校验。

A：原DCP一次定向anchor源Q到anchor_delayed D min/max路径/时钟查询，上限600s；没有全量扫描、STA重认证、实现/约束变化。若难以获得分段延迟，按Review允许采用明确安全输入相位，仅声称PWM内部动态验证，原跨层路径仍只保留既有全设计STA。

B：新TB保持源posedge50MHz寄存器语义、单周期anchor；明确外部边界模型及同步/异步输入安排；保留原断言并增启动相位/peak非空覆盖。runner将普通warning与真实SDF/时序错误分离，未知warning需人工审查并停止。

C：每角一次，xvlog600s、xelab3600s、xsim900s墙钟上限；TB5ms仿真时间watchdog，打印场景和模拟时间。慢角完整PASS才快角。真实异常或超时即停止，不移动刺激重试矩阵。

D：精简文本证据与PR41回执，不上传网表/SDF/DCP/缓存；无生产RTL/参数/约束改动、无板卡操作、无全量24h xelab，不自动合并/关闭。

本轮任何局部PASS均不等于FULL_CHAIN_SDF PASS；fast_inhibit在原BD恒零，独立动态覆盖N/A。上游reference commit/sticky inhibit重臂为环境假设，不冒充上游状态机门级覆盖。
