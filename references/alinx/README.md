# ALINX 本地资料索引说明

`VENDOR_ROOT` 对应项目根目录下忽略的 `资料/`。原厂文件留在原位，Git内只有原创说明、事实表及元数据。`包.zip!/成员`表示在内存中只读查看的成员，不表示已解压或复制入库；factory/S2则是实际展开文件。

- [ALINX_MATERIALS_INVENTORY.csv](ALINX_MATERIALS_INVENTORY.csv)：14,289个实际文件的大小/SHA256，加57个实际读取的ZIP/XSA成员，共14,346行。原件约59.63GB，未上传。
- [READING_LOG.csv](READING_LOG.csv)：317个实际内容读取/检索定位，不含仅哈希/枚举文件。PDF页码1基，范围表示本轮所读文字/原图；不是全书逐网审阅。新增本地UG1085 v1.7的12个RPU相关页及封面/修订页，不把它当最新文档或运行结果。
- `CONTENT_INSPECTED`：聚焦实际内容；`KEYWORD_SCANNED`：只做文件内容关键词检索；`TITLE_SCANNED`：只核页标题/元数据；`MEMBER_CONTENT_INSPECTED`：外层包的部分成员已读；`NOT_INSPECTED`：仅枚举/哈希，不能据此推断功能。
- `DOC_VERIFIED`只确认相应页中的资料事实，`PROJECT_INSPECTED`只确认源文件/工程静态参数；所有工具/硬件执行均`NOT_RUN`。部分高优先级辅助原件（例如XLS/结构图）未解析，按行保留NOT_INSPECTED。
- 每行发布状态唯一：`INDEX_ONLY`（原件本地、只提交索引）或`EXCLUDE`（生成缓存/二进制/非本轮大包，不导入）；本轮没有`APPROVED_COPY`。`P0/P1/P3`是面向当前用途的优先级，不是阅读完成状态。
- 个别`ax_pwm.v`/`ad7606_if.v`文件头有条件分发声明，只记录文件级证据，不扩大为工程/PDF许可；本轮仍不复制任何厂商代码。图纸带ALINX Confidential，未知许可的PDF/原理图/压缩包、BSP和XSA/bit都不上传。

S1只核18个XPR及选定RTL/XDC/IP/TB；S2核40个创建脚本、重点BD/外设源码和部分辅助文件。未运行原厂脚本或示例。Cortex-R5F实际启动/内存/中断、板卡丝印与完整器件料号及新版工具兼容性仍待后续核实。结果入口：[核查报告](../../coordination/reports/ax00b_vendor_review.md)。
