# Issue40 模型精简证据

- `system_result.json`、`system_frames.csv`：`.runtime/motor_control/system_04`，唯一入口真实执行统一系统SLX，55个逻辑帧PASS。包含无效帧九字段安全输入、与FOC边界一致的冻结valid、非零电流/角度/三相占空比/比较值/谷值保持，以及51项位置历史后的speed_valid。静止测试速度为0。
- `front_model_result.json`：`.runtime/motor_control/front_oracle_01`，同一最终`rtl_04`事件表送回原Current与Angle数值源，16个电流事件/224个输出字及15个角度事件零差。
- `foc_model_result.json`、`foc_model_results.csv`：`.runtime/motor_control/foc_oracle_08`，同一最终`rtl_04/foc_frames.txt`送回原p3 FOC模型，单次连续15帧、45个Q30输出字零差。CSV列为sample_id、tick、reference_version、三路Q30 duty、三路compare。
- `combined_front_result.json`、`combined_foc_result.json`：`.runtime/motor_control/combined_oracle_01`，实际验证`motor_control_run(new_dir, rtl_04_dir)`统一目录入口顺序运行前端与FOC比较，两段均PASS。
- `mapper_model_result.json`：`.runtime/motor_control/mapper_01`，31组定向Q30输入、3输出与一拍寄存延迟PASS；实际生成RTL的31向量结果另见`../rtl/mapper_summary.json`。

原始MAT、完整日志、旧失败目录及所有产物均留在各自`.runtime`目录。系统模型的FOC数值参考固定后移一个逻辑帧，不代表实际PL时序；实际P128捕获、目标谷值、互补输出及死区由RTL/SDF证据独立验证。所有板卡操作为NOT_RUN。运行与单源生成说明见`simulation/motor_control/README.md`。
