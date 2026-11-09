# ENCF 无功率离线候选与手动观察

本轮不连接、发现、下载或运行板卡，真实读头/驱动板/电机均未连接。ABZ物理引脚、电平、实际位移尺度和实际逐帧R5服务能力均未签核，physical_link_verified=0。以下手动步骤仅供用户后续另行授权后使用，不运行对齐、FOC或Runtime，也不使能PWM。

## 唯一入口与产物

- 统一PL仍为 `hardware/axu5ev/motor_control/build.tcl`；本次ENCF构建包装入口及实际新硬件结果见HANDOFF首节，不复制ADC/PWM工程。
- 软件数值源 `simulation/encoder/encoder_position_speed.m`，生成入口 `encoder_generate_c.m`，活动C在 `generated/encoder/feedback_c/`。R5手写部分只取帧、传配置、调用生成C及记录。
- R5构建入口 `scripts/encoder_feedback_build.py`，配置 `firmware/r5/encoder_feedback/build_config.json`。
- 新Workspace `.runtime/encoder_feedback/vitis_01`；平台 `encoder_feedback_platform`，应用 `encoder_feedback_observer`，Launch `encoder_feedback_manual`。
- 匹配本次XSA/bit/ltx的实际路径由build_config指定；不使用PR37的hardware_05/vitis_02替代新增设计。
- ELF为Workspace下 `encoder_feedback_observer/build/encoder_feedback_observer.elf`，A53 FSBL为 `encoder_feedback_platform/export/encoder_feedback_platform/sw/boot/fsbl.elf`。

```powershell
# 新软件生成/比较目录必须未占用，MATLAB MCP中调用：
# addpath('D:/Project/AXU5EV/simulation/encoder'); encoder_generate_c('<新软件结果目录>');
# 新硬件完成后，Vitis离线构建：
vitis.bat -s scripts/encoder_feedback_build.py
python scripts/encoder_feedback_build.py --check-startup
```

原Workspace和原始数据保留；完成目录不重建，失败候选不删除。构建/主机验证不代表ARM实测或实板采集通过。

## 尺度、同帧与历史

显式TEST尺度为1000nm/count=0.001mm/count，电周期30000count=30mm；一个有效解码count只换算一次，不额外乘/除4。AB正向00→01→11→10→00。Z只观察，不清连续计数或自动归相。测试源每10us走一步，理想每100us增加10count，对应100mm/s；暂停TEST保持当前AB/Z相位。

新快照identity=ENCF(0x454e4346)、schema2，共41字。BEGIN=0x00冻结，payload从0x0c开始，最后word40在0xac读响应后释放；不能沿用旧32字的0x88释放位置。字段详见motor_control README：sample_id是转换编号，正常每帧+500；sample_tick为原50MHz tick、正常每帧+5000。计数/Z/非法统计锁存在ADC phase0，随原码/电流/电角度带同一采样身份发布；生成数值流水改变发布时刻，不改变采样时间戳。

word32/33为有符号Q32弧度电角度的低/高32位，word34配置版本、35手动位置零点count、36相位偏置count、37方向标志、38编码器/角度/TEST标志、39电周期count、40nm/count。电流已校准、编码器ready、角度有效及速度历史有效分别标记；ADC未校准时仍可观察编码器位置/速度，不能据此取得功率许可。

软件保存51个100us位置历史项，速度严格使用x[k]−x[k−50]及两帧PL tick差，名义窗口5ms。第51个连续有效样本才speed_valid=1；没有改成1ms历史或50ms窗口。位置零点、方向或配置版本变化重建测速历史，不制造速度脉冲。位置以mm、速度以mm/s保存为double，打印只在采集停止后进行。

原始计数/ID按模2^32、tick按模2^64处理。接收帧间计数变化必须严格小于2^31；恰好半圈差不可消歧，当前帧无效并丢弃历史，下一合格帧建立新坐标epoch。首次/重新锚定以signed_mod32(raw−zero)定义最近参考。合法整数缺帧可保留此范围内计数连续性，但测速历史清空并从当前帧重建；非整帧ID/tick变化、非法计数增加或未ready使当前无效并在下一合格帧重建。相同ID/tick重复读取不推进历史；内容冲突的重复身份按无效重启处理。

数值status位：0启动、1重复、2缺帧、3配置历史重建、4编码器/非法输入无效、5半回绕歧义、6重启。位置有效与速度有效各有独立输出。原始快照保留这些判断所需的ID/tick/count/illegal/config；不要用UART打印时间计算速度。

## 后续获准后的手动顺序

1. 显式选本次bit/ltx、匹配平台的PS初始化，按原A53 FSBL+R5路径手动加载；Launch不自动下载PL。应用只停在 `ENCODER_FEEDBACK 45464301 WAIT`，不自动启动TEST或输出许可。
2. `s`只读一次快照。`t`提交默认TEST启动；`u`提交TEST停止，保持AB/Z最后状态。TEST标志为数字来源，不表示真实编码器链接。
3. `r`轮询PL新快照，最多记录128个不同发布序号，期间不打印。正常需要约12.8ms；无发布时有有界轮询退出。记录后应用打印实际记录数，`p`才导出CSV，包含原始同帧字段、mm位置、mm/s速度和有效位。
4. `z`以当前快照count提交手动位置零点；`q`把相位偏置增加7500count；`d`切换方向。每次显式配置版本递增，等待快照word34确认实际采用。它们都不是电机对齐。再执行`r`/`p`观察历史重建，前50个新样本的速度不能当有效值。
5. 结束用`u`停TEST；本应用没有PWM许可命令。打印/人工间隔造成缺帧时，下一批将按PL身份显式重建历史，不能把稀疏记录当连续5ms。

128帧轮询能否在真实R5上无漏帧服务仍为NOT_RUN，须以后授权板测。当前数据通路没有DMA、自动恢复、通信框架或软件定时器替代采样证据。PWM原ILA连续窗口仍约40.96us，使用PR37指南分别观察边界，不能据单屏宣称完整100us周期。
