# AX-02A：离线目标准备与数值验证

日期2026-10-27；仓库`kazecode666/AXU5EV`，[Issue #15](https://github.com/kazecode666/AXU5EV/issues/15)。基点为PR14合并`ae9a11d2d59abc952cce0b979d004a315878639a`，分支`codex/ax02a-r5-target`。本报告记录实际成果；不展开AX-02B/C或AX-03。

## 当前验收状态

| 项目 | 本次结果 | 依据/未完成项 |
|---|---|---|
| A1 / TARGET_BUILD | **BLOCKED** | Vivado2026.1实际`get_parts *zu5*`为空；手册器件不可用，XSA未生成。可见安装没有`armr5-none-eabi-gcc`；Vitis R5平台探测在SDT生成失败，无BSP/ELF/map |
| A2 | **生成/ARM对象编译PASS，standalone链接NOT_RUN** | 临时Cortex-R配置生成C/H并恢复PC配置；现有Arm GNU交叉编译Runtime/bridge/runner为真实R5对象/静态库，尚无完整应用ELF |
| A3 | **离线PASS** | 原MAT64536帧完整导出，当前模型同输入参考与43100帧对齐/复位/故障参考；20/41字段、LE double全文件回读一致 |
| A4 / BOARD_REPLAY | **NOT_RUN** | 当前生成C主机回放通过，两次独立初始化；尚无真实R5输出 |
| A5 / BOARD_PERIODIC_100US | **NOT_RUN** | 定时执行层、TTC适配源码及比较器已准备；漏序号/超期策略定向测试通过，无硬件计时值 |
| A6 | **离线成果PR** | 可提交源码、入口及精简证据；不能据此关闭板上验收 |
| BOARD_BOOT、托管SIL/PIL、5EV综合/布线、AXI/ADC/编码器/PWM、ARM/实机、烧录/上电 | **NOT_RUN** | 本次未获硬件操作授权，连接状态未确认 |
| 完整RTL重跑 | **NOT_RUN** | 复用PR14原始记录，没有再跑c_rtl |

## 来源、工具与目标配置

保留用户已有Hybrid/Runtime/Reference SLX、`init_AXU5EV.m`和本地wrapper/S-function修改，未保存/覆盖这些模型，未将用户修改纳入本次提交。模型当前版本1.50；本次参考基于这些本地状态，不能称它们是PR14原算法/参数的已提交快照。

本次会话最初无已加载初始化参数，运行唯一`simulation/init_AXU5EV.m`一次。当前参数Vmax20mm/s、Amax200mm/s²、Jmax1000mm/s³、minRamp0.2s、速度设置变化率100；旧PR14为V10/A100/minRamp0.1/rate50。PI与采样周期未改：Ts100µs/1ms/10ms，Kp_ASR=0.018033474852681124、Ki_ASR=1.4426779882144898、Kp_pos=22。对齐仍10000/30000/2000拍与0.5A。

实际工具：MATLAB26.2.0.3386108/R2026b；Vivado2026.1 SW6511674；Vitis2026.1 SW6497934；主机MinGW64 GCC由已安装MATLAB支持包提供。主机构建`-O2 -fno-fast-math -ffp-contract=off`。补充检查发现既有STM32CubeCLT的`arm-none-eabi-gcc`12.3.1，可支持Cortex-R5；未安装新工具。

`simulation/axu5ev_build_r5_target.m`查询本机`target.get('Processor','ARM Compatible-ARM Cortex-R')`后，复制活动配置集；ERT、C、nonreusable、GenCodeOnly。实际产物头注明`ARM Compatible->ARM Cortex-R`，little-endian、char8/short16/int32/long32/longlong64、word32、double64。仅生成C/H，没有交叉编译。退出已核对活动配置`Configuration`、`Intel->x86-64 (Windows64)`、Dirty=off，原fileGen目录恢复；PC生成目录/MEX不重建。两份新增.m的Code Analyzer检查无问题。

用既有Arm GNU12.3.1实际交叉编译了6个Runtime/bridge/runner对象并打包`libax02a_runtime.a`，选项`-O2 -fno-fast-math -ffp-contract=off -mcpu=cortex-r5 -marm -mlittle-endian -mfpu=vfpv3-d16 -mfloat-abi=hard`。readelf实际显示ELF32/ARM、CPU7-R、v7/Realtime、VFPv3-D16、VFP寄存器传参；精简证据见`verification/ax02a/arm_runtime_build.json`和`arm_runtime_attributes.txt`。Runtime单对象text6196B/bss852B；这是对象占用，**不代表含BSP/数学库/栈的最终链接占用**。

该静态库没有启动代码/BSP或可执行入口，不能冒称standalone ELF。实际BSP、最终ELF ABI/段/TCM/栈及ARM运行仍**NOT_RUN**。生成日志的MinGW不是R5工具链。`scripts/ax02a_build_r5.py`的完整平台路径使用Vitis2026.1 Python API，独立`--runtime-only`使用上述已有GNU工具；尚未通过实际平台创建。

## 原始输入与当前模型参考

输入来自`.runtime/ax01c/c_fixed_continuous.mat`的真实`r5_snapshot`，输出历史参考为`r5_commit`；20/41列、同一时间轴、100µs步长、64536帧，末时6.4535s。Send翻转帧k=20915/21016/52999，对应2.0915/2.1016/5.2999s。未使用10ms抽样CSV插值。

`simulation/axu5ev_export_r5_replay.m`导出三个明确分开的场景：

| 场景 | 帧数 | 参考来源 |
|---|---:|---|
| `pr14_original` | 64536 | 原MAT，保持旧V10/A100输出，仅历史保留 |
| `current_motion` | 64536 | 原100µs输入/反馈不变，喂当前Runtime模型产生新参考 |
| `current_alignment_reset` | 43100 | 当前Runtime模型，手动Start、原五态完整计数、独立PI/PWM/Init/fault切换 |

`current_motion`是**当前Runtime在记录反馈上的回放参考**，未重跑电机对象闭环，不能称为当前新参数的电机闭环验收。历史PR14的10→0→−2mm闭环验收继续有效于其原版本。

输入逐帧20个double（运动10,325,760B），输出逐帧41个double（运动21,167,808B）；显式转置写little-endian，全部回读与原矩阵相等，包含首末帧和三次命令行。完整MAT/二进制/生成C和日志留`.runtime/ax02a/`；简明证据在`verification/ax02a/`。

## 数值结果（HOST，非ARM）

相同Cortex-R类型配置生成源、现有bridge及同一runner编译成主机程序，和当前Simulink Runtime参考逐字段比较：

| 运行 | 帧数×字段 | 最大绝对差 | 离散字段不一致 |
|---|---:|---:|---:|
| 运动实验1 | 64536×41 | 1.7763568394002505e−15 | 0 |
| 运动实验2（独立新初始化） | 64536×41 | 1.7763568394002505e−15 | 0 |
| 手动对齐/复位/故障 | 43100×41 | 0 | 0 |

运动接受3/拒绝1/段号3；三次发送结果2/3/2，首次Ready为1.9199/3.9599/6.3499s；末拍Ready仍0。逐信号max/RMS/首次不一致及事件见`verification/ax02a/host_motion_1`、`host_motion_2`、`host_alignment_reset`。连续量门限`1e−9+1e−9*abs(reference)`，布尔/枚举/计数/段号精确比较，非有限值失败。

对齐状态转换k=10→1、10010→2、40010→3、42010→4；完整原始10000/30000/2000拍。x=3.25mm，偏置5.942846103040692rad，一次性锁存；随后Init_Reset在k42300返回0、手动重启k42310、故障k42400返回0。软件序列不证明实物转子对齐。PI_Reset输入k42150–42160、PWM禁用k42200–42210与Init_Reset、fault分别施加。

比较器9项定向测试通过：相等、缺帧、离散微小差异、NaN、连续门限、有效计时、超期、漏释放，以及拒绝将1ms周期误判为100µs通过。独立审查发现最后一项缺口，先复现失败再修复：实际周期只能偏离100µs至多一个源时钟tick。通用runner链接真实生成源的测试通过：k0在epoch、漏释放停止、超期停止。合成计时测试只验证判错逻辑，不能转换成R5实测µs。

## 平台依据与失败证据

用户确认核心板参考`ACU5EV核心板原理图.pdf`、底板参考`AXU5EVB-E开发板原理图.pdf`；底板与AXU3EG共用，标题不能据此否定。用户实物确认以太网收发芯片JL2121；本阶段不使用以太网。芯片以用户指定的《AXU5EVB-E开发板用户手册》PDF p10–11为依据：`XCZU5EV-2SFVC784I`，Vivado器件名`xczu5ev-sfvc784-2-i`；实物PCB修订尚未提供。

手册p11：PS DDR4为4×MT40A512M16LY-062E，64bit/4GB；p20：PS参考33.333MHz；p39：UART0 MIO42/43。厂商hello BD对应64bit、16bit DRAM、8192Mbit/颗、DDR4_2400P及MIO42/43。原BD实际R5请求500MHz/配置499.994995MHz、TTC0100MHz，**不是当前平台配置或实测频率**。厂商XA/-1仍与手册XC/-2不同。

真实执行：

- Vivado最小平台入口在`get_parts xczu5ev-sfvc784-2-i`报`part unavailable`并退出；额外只读`get_parts *zu5*`为空。没有改用XA或其他芯片生成“通过”平台。
- Vitis2026.1 Python API用厂商旧XSA做一次独立R5域探测，原中文路径与ASCII复制路径均在`Error in generating SDT`退出；探测XSA不是新目标交付。没有调用XSCT或原位升级厂商工程。
- 目标构建入口preflight实际报`missing PS-only XSA`并返回非零。当前可见2026.1没有R5 GNU编译器；未安装/升级工具。

日志：`.runtime/ax02a/ps_minimal.console.txt`、`parts.console.txt`、`probe_vitis_ascii.log`、`r5_preflight.txt`。真正下一步是补齐这套安装的MPSoC器件与嵌入式R5构建组件，再执行同一入口；不是再跑RTL。

## 板上待验收与可复用点

`firmware/r5/ax02a/main.c`为standalone回放应用，等待内存命令后执行；D-cache关闭、I-cache开启，输入/输出/计时DDR窗口与ELF装载段由构建入口核对不重叠。实际DDR初始化/容量/可达性、split启动、BSP时钟和中断仍须在平台可构建后核实。

`timing.c`依BSP表选择两路TTC，第一路释放、第二路独立计数。ISR仅记录时间/递增序号；唯一前台执行Runtime。检测丢拍/重复/序号与独立时间，失败停止。记录预期/实际释放、开始、纯Runtime与完成；比较器可生成普通/速度/位置/命令/对齐分类的样本数、均值/P99/max/最小slack。计数频率、读计数开销、周期量化、启动窗口和真实帧记录均待板上采集，**当前无任何R5执行时间或截止期通过结论**。

最短实际入口、数据格式、目标源码边界和待验证启动条件见[应用README](../../firmware/r5/ax02a/README.md)。板卡复位、JTAG加载/运行需要本次明确授权与连接确认；功率级保持隔离。未加载PL镜像、未写启动介质、未上电功率级、未自动合并。A4/A5完成后才能判定BOARD_REPLAY/BOARD_PERIODIC_100US，不能以本报告的主机结果关闭Issue15。

实现所用API依据为本机Vitis2026.1 Python源码/示例与SDT TTC3.23驱动，以及[AMD UG1400迁移说明](https://docs.amd.com/r/en-US/ug1400-vitis-embedded/XSCT-to-Python-API-Migration)、[官方TTC例程](https://xilinx.github.io/embeddedsw.github.io/ttcps/doc/html/api/xttcps__intr__example_8c.html)。
