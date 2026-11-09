# 新时序测试的功能预跑

按Issue40评论6740612318补充现有 `timing_tb.sv`，由原RTL入口新增的 `-Suite timing-preflight` 编译同一个测试台。只替代PS/AXI事务源和MMCM时钟模型，使用同一实际ADC/QEP、原生成FOC/mapper及PWM RTL；不包含SmartConnect/真实时钟树或SDF。**这些结果仅为新刺激/监视器自检，不是实现后动态PASS。**

最终 `.runtime/motor_control/timing_preflight_03`：3035检查、15次事件驱动快照、6次实际active采用、7次offer、5次三相组变化、36次输出开通沿、1次晚到、1次失锁、2次显式重臂、2项disarm优先级、1次真实slave AW/W在P0握手、5次两级下降沿释放，全部PASS。15帧是本次事件序列的结果，不是固定验收帧数；不要求六帧。

采用监视器从实际debug中的active_seq/active_compare取值，按PWM时钟事件检查同一采样peak+5000个PWM沿整组采用，同时记录Q传播偏差。记录冻结offer并与实际三相比较；覆盖参考阶跃与shadow污染、真实接收器前OTR、取消后跨后续P0/谷值不复活、LOCKED恢复不自动许可、显式重臂、互补/1000ns内部死区、80字/0x148响应释放。绝不force最终compare或active。

晚到只在已声明的共享ready反馈接口置0；失锁在实际MMCM LOCKED接口注入（RTL预跑为其模型）。为精确覆盖P0握手，一笔disarm直接驱动实际ADC slave AXI输入，PS master保持空闲；它核对原phase8消费，不宣称验证了SmartConnect传输延迟。其余事务仍从PS侧测试接口发出。

`counterexample.json`：`.runtime/motor_control/timing_counterexample_01` 只把测试端预期比较值翻转1位，原DUT不变；首次实际采用250514ns报 `ACTIVE_TRIPLET_MISMATCH`，运行退出1、无PASS，属于预期反例。它证实监视器被真实触发，不计作DUT故障。

早期 `timing_preflight_01` 因RTL内部名latest_seq与网表名latest_seq_reg不同在展开失败，仅修测试观察适配；02已通过，03为最终RT/网表名称适配版本再通过。全部失败/中间目录保留。未重跑原chain套件、模型、19帧FOC比较、综合实现或R5；未操作板卡。
