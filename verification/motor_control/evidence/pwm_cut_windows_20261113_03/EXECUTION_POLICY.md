# Review6847609985 本轮固定执行边界

仅服务器独立进行。已有原生PWM cut网表与slow/fast SDF直接复用；不查DCP、不重新导出/实现/同步打包，不改生产RTL/约束/参数，不使用SHA核查，不操作板卡。

最多三个TB候选（v1及至多v2/v3），每次修正前必须有具体日志和可定位TB-only原因、保存最小diff；禁止移动原同相50/100MHz、0.2ns发射模型、20ns anchor、屏蔽warning/关键断言来凑PASS。语法预检和正式corner的xvlog均记录，不冒充动态PASS。

每角xvlog600s、xelab600s、xsim3600s墙钟上限，保留5ms模拟watchdog与真实时间/场景进度。slow同版完整PASS且工具自然正常退出、成功SDF注释、唯一完整marker、无异常后才fast。若最终TB修改须重做同版slow才fast。

真实timing/SDF错误、疑似生产DUT、无法归类、第三版本仍失败：立即停止，不自动重试。旧证据、每版原TB及全部实际日志保留。

验收11不同source offer/accept，8谷值整组采用/ack，3取消/恢复，3anchor/start/peak，release、六路互斥、原deadtime门槛、0/5000边界及100us载波和Q事件，全部原断言保留。即使局部两角PASS，FULL_CHAIN_SDF也保持NOT_COMPLETED；真实跨cut/上游FOC/ADC/reference重臂未作局部动态证明，fast_inhibit原BD恒零独立动态N/A。
