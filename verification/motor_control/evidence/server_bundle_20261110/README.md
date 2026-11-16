# Issue40服务器SDF包及干净解包自检PASS

先独立提交运行器修复0bd081a902397d5365f0b608f1678c6d4ce04d0a及12项短测试，再执行本次打包。未调用真实Vivado、长xelab、-O0或服务器。

交付zip仅存本地：

`D:\Project\AXU5EV\.runtime\motor_control\server_bundle_01\AXU5EV_Issue40_SDF_hardware_02_0bd081a.zip`

大小 **38,281,015字节**；SHA256：

`6932398ee982936da54521c60d5bd978234c5bd55698e76de720910fb509e05b`

相邻 `.zip.sha256` 可核对整个传输文件；包内SHA256SUMS校验9个文件（另含清单本身，共10文件）。本目录保留同一清单、来源、依赖审计与精简结果，未将大网表/SDF/zip加入Git或上传外部服务。

实际解压目录：

`C:\Users\lww\AppData\Local\Temp\AXU5EV_Issue40_unpack_20261110_01\AXU5EV_Issue40_SDF_hardware_02_0bd081a`

从其包外 `outside_cwd` 启动实际解包脚本，确认不依赖原仓库：

- 解压CRC及9项SHA256/完整文件清单PASS；原网表95,227,427字节、slow SDF485,670,050字节、fast SDF489,460,046字节、当前事件TB27,225字节原字节保留。
- 可见源include/readmem/输入fopen及文件参数扫描：无额外项目输入或未解析表达式。TB的foc_frames.txt、motor_frames.txt为输出。1个原厂商保护块原样保留，匹配的Vivado库/glbl由服务器工具提供，不打包安装目录。
- slow/max、fast/min均DRY_RUN_PASS_NOT_SDF：3阶段命令、包内输入定位、可配置工具/glbl路径正确，未定义MC_TIMING_RTL，未加-O0。
- 使用另建的短假工具安装目录运行解包入口：正常流程与xelab非零失败传播PASS，失败后xsim未启动。假注释/PASS只用于入口测试。

自检入口为 `scripts/motor_control_package_sdf.py`，实际命令及路径见本目录package_report.json；操作说明 `firmware/r5/motor_control/SDF_SERVER_ZH.md`，包内为README_ZH.md。所有原始自检目录/日志保留，未清理旧产物。

本地执行平台仅Windows；Linux/服务器实际运行NOT_RUN，不冒称已验证。真实slow注释NOT_COMPLETED、动态NOT_RUN，fast NOT_RUN；同帧/三相/谷值/晚到/disarm/失锁重臂/死区/80字快照的两角SDF验收仍开放。保持PR41 Draft，停在Review；不登录服务器、不操作板卡、不自动关机。
