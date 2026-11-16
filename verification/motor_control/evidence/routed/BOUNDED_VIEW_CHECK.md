# 一轮有界裁剪核对：未证明可行，停止

按Issue40评论6740612318，仅执行一次 `routed_boundary_probe.tcl`，读取原 `hardware_02/pwm_adc_routed.dcp`。没有修改单元/网络，没有写DCP/bit/XSA，也没有重新综合、布线、编辑网表/SDF。独立新目录为 `.runtime/motor_control/routed_boundary_probe_01`，主机运行上限600秒。

已完成DCP读取、实际对象查询与沿连线的first-receiver/output-source集合；到边界 `get_timing_paths` 循环时触及上限，终止本次专属进程树，核查PID31356/23748及子进程剩余0。`boundary_paths.tsv`为空/未完成，后续reset-driver查询、分支细分和decision输出未执行。不能将脚本中未执行的命令当成已完成证据。

| 实际对象 | 原DCP数量 | 本轮结论 |
| --- | ---: | --- |
| P127九字段寄存器 | 270 | 找到；不是裁剪后保留证明 |
| 原下降沿保持寄存器 | 270 | 找到其实际fanout |
| 原核内首次接收顺序对象 | 628 | 整个core黑盒会删除这些必须保留的对象 |
| 原核输出侧顺序源对象 | 192 | 整个core黑盒会删除原输出边界，不能直接理想值替代 |
| 原帧壳结果寄存器 | 102 | 找到其actual fanin；数量含实现优化对象，不是接口宽度 |
| 生成mapper / offer | 40 / 39 | 原DCP对象存在，未证明局部视图保留 |
| 冻结邮箱 / pending / active | 各39 | 原DCP对象存在，未证明跨层网络/SDF在裁剪后保留 |
| 采用回执 / auto_release | 32 / 2 | 原DCP对象存在，未证明裁剪后的完整恢复/移除路径 |

完整对象示例见 `bounded_probe_groups.tsv`，原始628/192项清单保留在新runtime目录。此前完整STA的下降沿→原核最差数据路径经过InversePark内部DSP/CARRY，且原reset报告显示core内算术层级的BUFG驱动外层保持寄存器；这些既有报告说明不能按逻辑模块名猜测切点，但**不能代替临时裁剪视图的实际保留证明**。

因此只排除“整核黑盒”这个直接切点；没有在本轮上限内建立保留真实首次接收端、输出边界、共享时钟/复位树与跨层互连的局部切点。**这不是证明所有裁剪方案均不可能。**若要继续需要额外的切点/路径工作，不能用新增长xelab替本轮判明可行性。

按用户停止条件到此停止：临时视图导出0次，routed xelab0次，裁剪后SDF匹配/注释及slow/max、fast/min动态均NOT_RUN；不启动完整网表回退、不再试切点、不关闭SDF验收缺项。原全设计STA及所有旧产物保留，未宣称 `AFFECTED_BOUNDARIES_SDF_PASS` 或 `FULL_CHAIN_SDF_PASS`。后续由用户决定另行验证方案或明确延期。
