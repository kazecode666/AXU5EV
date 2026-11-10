# Windows单变量候选与手动服务器交接

按Issue40评论6759938887、PR41评论6759942425及Review5835164071，先读取两个旧现场：均仅650份解析sdb，无生成源/对象/kernel，不能定位旧六小时根因。本机2026.1帮助确认禁用优化实际拼写--O0、mt默认auto、--stats及--verbose 1。选项help和命令差异短核对通过；没有重跑旧12项进程测试或Linux专项。

13:50在sdf_o0_slow_01进行唯一一次完整slow/max候选：编译策略只新增--O0，另加两项诊断，debug off、mt、1ps、所有时序开关和事件测试台不变；每工具预算60min。xvlog通过，随后日志明确进入FOC各层SDF port delay处理，但没有生成源/对象/kernel或成功注释确认。

用户随后改为Windows服务器手动执行，明确不需远程操作并允许GitHub下载交接。14:18:11核实监督器及Job成员身份后停止本机任务，成员句柄退出检查剩余0。监督器终止触发其kill-on-close Job；原RUNNING JSON及日志保留，user_stop_result.json另记CANCELLED_BY_USER_FOR_WINDOWS_SERVER_HANDOFF。这是用户取消，**不是60min超时或原生工具自然失败**。本轮未恢复/重试，fast未启动。

结果：slow注释NOT_COMPLETED、动态NOT_RUN，fast NOT_RUN；--O0提速和旧根因均未证实。完整原始现场在.runtime/motor_control/sdf_o0_slow_01；精简result、命令差异、阶段样本及限量日志摘录在本目录。

最终原生日志274,507,031字节，实际ERROR/FATAL/WARNING前缀0、成功注释确认0；原宽泛匹配式命中23处，均为INFO XSIM43-3453中error_register信号路径，不能当DUT或注释错误。本轮没有删除检查或过滤真实告警；服务器入口只开--O0并保留原默认verbosity0，避免新增verbose1的映射INFO噪声。对应检查器本身不改。

服务器下载交接由用户手动操作：原server_bundle_01字节保持，另提供小Windows入口包和单独指南。新入口在旧包外，显式指向旧网表/SDF/TB，因此旧9项校验不失效；fast入口强制核对slow PASS/O0及相同hardware。新包装的两角dry-run、fast前置拒绝及假工具slow→fast共5项通过，另测试小包解压后的入口定位；均非SDF验证。服务器实际执行NOT_RUN。

DUT/算法/约束、hardware_02/vitis_01、用户修改及全部旧产物保留。不登录服务器、不操作板卡、不关机，PR41仍Draft。
