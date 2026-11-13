# Issue40 模型精简证据

- **最终RTL06**：`rtl06_front_result.json`、`rtl06_foc_result.json`、`rtl06_foc_results.csv`来自`.runtime/motor_control/combined_oracle_02`。一次联合入口比较Current20事件/280输出字、Angle19事件及原p3 FOC单次连续19帧/57个Q30字，全部零差，包含pending-arm后disarm及重新显式提交的新增帧。前端JSON中的`source_current/source_angle`是本次受控dependencies目录的实际which路径，运行时已断言来源。
- `layout_result.json`来自`.runtime/motor_control/layout_02`：新系统根层18个Outport及11个Terminator解除重叠，常量原有3px交叠一并最小移开；系统根层、映射根层及映射DUT层块重叠对为0，端口/线/Stateflow检查healthy。仅改排版，系统数值不重跑。
- `system_result.json`、`system_frames.csv`：`.runtime/motor_control/system_04`，唯一入口真实执行统一系统SLX，55个逻辑帧PASS。包含无效帧九字段安全输入、与FOC边界一致的冻结valid、非零电流/角度/三相占空比/比较值/谷值保持，以及51项位置历史后的speed_valid。静止测试速度为0。
- `front_model_result.json`：此前`.runtime/motor_control/front_oracle_01`，`rtl_04`事件表送回原Current与Angle数值源，16个电流事件/224个输出字及15个角度事件零差。
- `foc_model_result.json`、`foc_model_results.csv`：此前`.runtime/motor_control/foc_oracle_08`，同一`rtl_04/foc_frames.txt`送回原p3 FOC模型，单次连续15帧、45个Q30输出字零差。CSV列为sample_id、tick、reference_version、三路Q30 duty、三路compare。
- `combined_front_result.json`、`combined_foc_result.json`：`.runtime/motor_control/combined_oracle_01`，实际验证`motor_control_run(new_dir, rtl_04_dir)`统一目录入口顺序运行前端与FOC比较，两段均PASS。
- `mapper_model_result.json`：`.runtime/motor_control/mapper_01`，31组定向Q30输入、3输出与一拍寄存延迟PASS；实际生成RTL的31向量结果另见`../rtl/mapper_summary.json`。

原始MAT、完整日志、旧失败目录及所有产物均留在各自`.runtime`目录。系统模型的FOC数值参考固定后移一个逻辑帧，不代表实际PL时序；实际P128捕获、目标谷值、互补输出及死区由RTL/SDF证据独立验证。所有板卡操作为NOT_RUN。运行与单源生成说明见`simulation/motor_control/README.md`。
