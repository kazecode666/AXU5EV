# 统一无功率数字链与本地有限板测

2026-11-11按PR41评论6784312486接续Issue40。服务器执行完整功能PL两角SDF，本地使用hardware_02与vitis_01开展有限无功率板测，两条工作线独立推进，最后统一Review。当前板测和R5采集连续性均为NOT_RUN。用户已确认现场具备接线确认的ADC模块及可靠输入。

## 冻结候选与启动

产物路径和本次SHA256见 [artifact_correspondence.json](../../../verification/motor_control/evidence/parallel_plan_20261111/artifact_correspondence.json)。硬件生成来源、服务器入口来源和当前文档head分别记录，现场使用下表的实际产物。

| 项目 | 本机实际入口 |
| --- | --- |
| bit / ltx / 含bit XSA | `D:/Project/AXU5EV/.runtime/motor_control/hardware_02/ax03b3_adc.bit`、同目录`.ltx`和`.xsa` |
| Workspace | `D:/Project/AXU5EV/.runtime/motor_control/vitis_01` |
| R5应用 | `motor_control_observer/build/motor_control_observer.elf`，相对Workspace |
| A53 FSBL | `motor_control_platform/export/motor_control_platform/sw/boot/fsbl.elf`，相对Workspace |
| Launch配置 | `motor_control_observer/_ide/launch.json`中的`motor_control_manual` |
| 服务器SDF | [WINDOWS_SERVER_SDF_ZH.md](WINDOWS_SERVER_SDF_ZH.md)，slow与fast均显式24h/工具预算 |

现场由用户操作板卡。需要Codex协助下载或采集时，由用户明确授权相应动作。执行前记录板型、ADC模块/接线和可靠输入条件，确认功率驱动及电机处于断开状态。六路PWM为内部观察，physical_link_verified=0，Vdc=48V为数字测试量。

1. 在现有Vivado Hardware Manager中由用户选择冻结bit及配套ltx。保留现有探针和深度。
2. 在Vitis打开上表Workspace与Launch。Launch配置为`programDevice=false`、`resetSystem=true`、RPU split，用户先确认本次复位影响范围，再手动启动。FSBL对应AArch64/A53_0，应用对应ARM32/R5_0，平台使用这份XSA的PS初始化。具体PS初始化文件路径在产物对应记录中。
3. Launch在应用入口暂停，用户继续运行至UART出现`MOTOR_CONTROL 4d435401 WAIT; physical_link_verified=0; no automatic arm`。记录原始启动输出。串口沿用PS UART0，115200/8N1、无流控，COM号按现场端口选择。
4. 单发`s`，应取得`MC sample=... ref=... applied=... flags=... physical=0`。应用在读取时核对MCT1 identity=0x4d435431、schema3、TEST尺度和FOC采样身份，实际BSP基址0x80000000。默认禁止位为flags bit4，首次有效结果前保持禁止。若没有MC状态输出或出现`MC schema/scale absent; stopped`，保存UART及可取得的原始字段并报告，暂停受影响场景。

服务器运行进度单独记录，本地现可开展上述现场启动。

## 分场景操作与记录

每次只发一个命令，等该命令完成及状态确认后继续。开始前创建新的原始记录目录，例如`.runtime/motor_control/board_no_power_01`，保存串口原文、命令顺序、输入条件和ILA文件。命令前后记录时间，末尾回到`d`禁止状态。

| 场景 | 用户逐步操作 | 要记录和核对的内容 |
| --- | --- | --- |
| 启动与数字校准 | `s`，然后`c`，等候状态更新，再`s → r → p` | `c`先禁止，提交N16/gain65536数字校准。观察两路done、有效帧和原码条件。quality bit5/6为两路校准done，bit7为电流有效，bit3/4为OTR。完整校准计数和偏置可在保存的records里查看。记录当前输入对应的数字偏置与状态 |
| 静止参考 | `t`，等候新参考版本，再`r`，采集完成后`p` | 合成ABZ停止，id=0、iq约0.1A、omega=0、Vdc=48V。核对refVersion、sample/focSample、offered/applied、duty和compare以及flags |
| 参考阶跃后状态 | `j`，等候新参考版本，再`r → p` | iq约0.2A，核对新版本与采用身份，结果标为命令后的状态观察。现场数据覆盖到的瞬态另行说明 |
| 合成编码器 | `m`，等候新版本，再`r → p` | 合成源每10us一个有效count，测试尺度0.001mm/count、电周期30mm，正常100us帧约增加10count和0.010mm。连续51项历史后核对sv、history及名义100mm/s。对应omega约20.943951rad/s，Q24=351381190 |
| 禁止及显式重臂 | 采集结束后`d`，再`s → r → p`，随后`t`，等候新版本，再`r → p`，最后`d → s` | 禁止持续、旧参考保持取消、新参考版本显式重臂。联合flags与applied历史解释结果。保存禁止前、禁止后及重臂后三组记录 |
| 局部ILA | 按下节分别触发 | 三相采用、互补死区、禁止和释放分别归档 |

`r`是阻塞式采集，最多128条新seq，结束时打印records和attempts，随后`p`打印已保存数据。采集期间到达的UART命令会等待主循环处理，测试用`d`在采集结束后发送。精确P0禁止、ready晚到和失锁注入继续由原SDF/RTL事件测试台覆盖。

电流、参考、位置和duty均按本轮数字尺度解读。校准记录为N16数字流程结果，参考给定和实际反馈分别观察。若compare达到0或5000造成持续电平，ILA切换场景记录实际未观察项。

## 身份、采集连续性与完整字段

`p`打印20列选定字段，即sample、tickLo、count、quality、refVersion、focSample、offered、applied、三路duty、三路compare、flags、position_mm、speed_mm_s、pv、sv、history。完整80字仍保存在R5的`records[i].p[0..79]`，snapshot seq在`records[i].seq`，软件状态在`records[i].status`。

- 正常选样帧的sample_id为uint32，正常增量+500，50MHz tick为uint64，正常增量+5000。UART只打印tick低32位，按模2^32计算差值，完整tick由word5与word4组合。缺帧记录实际间隔，重复sample与重复seq分别说明。
- `capture`跳过相同seq的轮询。保存records/attempts及实际打印行数，attempts还包含重复轮询。R5连续逐帧服务结论单独归档，记录最大ID/tick间隔、缺帧数、历史重建和sv情况。
- 速度使用100us位置历史的50间隔，即51项连续位置。启动、配置变化或缺帧会影响历史有效性，重复帧保持历史。现有模型处理32位count回绕，采集核对按既有字段宽度与有效位解释。
- 需要完整同帧字段时，在采集结束后的现有Vitis调试会话查看`recorded`及`records[i].p`，读取已保存的首/末条或相关条目。依据该ELF调试类型或map确认地址和布局，保存实际读到的80字及seq。字段未取得时在结果中标NOT_OBSERVED。
- 同帧检查关注word42=word3、word43/44=word4/5，word45参考版本和word46–56冻结输入。word57–59为Q30 duty，word60–62为0..5000比较值，word63为提交sample，word64为最后确认采用sample，word70/71为目标谷值tick。若字段不同，保存具体条目并报告影响范围。

flags对应word41。bit0 core_started、bit1 capture_valid、bit2 hold_violation、bit3 auto_valid、bit4 auto_inhibit、bit5 lock_blocked、bit6 frame_late、bit7 foc_pi。word64/applied保留最后采用历史，判断当前许可时同时看flags及六路波形。

快照为MCT1/schema3共80字，BEGIN=0x00冻结，payload从0x0c开始，最后word79在0x148读响应后释放。现有应用负责完整读取和释放。

电流和id/iq采用signed32/Q24 A，角度为signed40/Q32 rad，omega为signed40/Q24 rad/s，Vdc为unsigned32/Q24 V，duty为unsigned32/Q30。生成mapper将duty限于[0,1]后乘5000并half-up舍入。word70/71的目标谷值为capture_tick+2500个50MHz拍，名义50us。既有调度为反馈约2.2us准备完成、P128首次送入原FOC、P442附近捕获结果，随后在目标谷值整组采用。

## 局部ILA

PWM ILA为4096点、名义100MHz，连续窗口约40.96us。采用、死区、禁止/释放各自触发，配合原子快照判断更长时间关系。100us完整周期和采样至目标谷值的50us跨越需要多次采集和身份记录。

现有128位probe0中，high[2:0]、low[5:3]、phase[19:6]、valley[20]、peak[21]、started[22]、accepted[23]、applied[24]、pending[25]、high_request[28:26]、use_permission[35:29]、active_seq[67:36]、active_compare[106:68]。三路compare分别在[80:68]、[93:81]、[106:94]。

| 局部采集 | 触发和观察 |
| --- | --- |
| 三相采用 | 触发applied或active_seq变化，观察谷值与三路active_compare共同更新，记录该seq与UART/快照身份 |
| 死区 | 在有切换的相位上观察high/low边沿，核对互补和名义100个100MHz拍的死区。记录采样分辨率及实际可见边沿 |
| 禁止/释放 | 在采集窗口外发送`d`或新`t`，按许可/started或六路变化分别触发，保存实际窗口及对应参考版本 |

## 归档与后续Review

精简板测回执使用`verification/motor_control/evidence/board_no_power_01/`，服务器SDF使用`verification/motor_control/evidence/server_sdf_20261111/`，原始大日志保留在各自新结果目录。每项填写PASS/FAIL/NOT_RUN和实际覆盖字段，R5连续性另列。现场问题先提交UART、快照/ILA及产物身份，说明受影响场景。

当前状态集中在`verification/motor_control/results.json`的server_sdf_slow_max、server_sdf_fast_min、board_no_power、r5_capture_continuity。两条线证据收齐后统一Review，PR41保持Draft。

## 已有数值与生成入口

统一模型`simulation/motor_control/AXU5EV_Motor_Control_System.slx`及`motor_control_run`，原电流/角度库、原p3 FOC与模型生成mapper，继续沿已验收来源复用。生成和工程索引见motor_control README。既有55帧模型、19帧FOC比较、RTL、STA/CDC及R5构建证据按原结果保留，第二次固定六帧oracle历史为NOT_RUN/NOT_REQUIRED_DUPLICATE。
