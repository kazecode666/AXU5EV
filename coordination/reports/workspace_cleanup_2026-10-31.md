# 工作区清理候选（2026-10-31）

状态：**仅列清单，未删除任何文件。用户手动处理。** 仓库AGENTS禁止批量删除；本次不生成删除脚本，不用逐次调用包装成批量删除。

当前入口见[工作区指南](../../docs/WORKSPACE_GUIDE_ZH.md)及[HANDOFF](../HANDOFF.md)。workspace、生成源、配套参考、原始板测数据的位置均保留。

## 可手动删除的自动测试临时目录

以下109个目录共892文件、11127885B（约10.6MiB）。路径相对于 `D:/Project/AXU5EV`，均位于被Git忽略的 `.runtime/ax02a`。它们由下列测试的 `tempfile.mkdtemp()` 明确创建，含合成IRQ、桩读回、合成故障或历史数据分析副本，不是原始板测目录：

- [test_ttc_characterize.py](../../verification/ax02a/test_ttc_characterize.py)：ttc_test_、ttc_analysis_。
- [test_ttc_readback_formats.py](../../verification/ax02a/test_ttc_readback_formats.py)：ttc_formats_、ttc_readback_。
- [test_runtime_timer_mapping.py](../../verification/ax02a/test_runtime_timer_mapping.py)：runtime_r1_read_、faults_、legacy_、map_。

测试有意保留这些临时产物，之后重跑会再生成；本轮仅文档整理，不重跑算法测试。请在相关离线测试已结束时按下面确切路径手动删除。不要按“所有runtime”或“所有ttc”扩大匹配，也不要碰 `board_manual/ttc_aba_01`。

| 确切目录 | 文件数 | 字节 |
|---|---:|---:|
| `.runtime/ax02a/runtime_r1_faults_644aevxa` | 21 | 50528 |
| `.runtime/ax02a/runtime_r1_faults_83n4dhlj` | 21 | 50528 |
| `.runtime/ax02a/runtime_r1_legacy_152vwml4` | 4 | 6014 |
| `.runtime/ax02a/runtime_r1_legacy_6nu6bb7e` | 4 | 6014 |
| `.runtime/ax02a/runtime_r1_legacy_8f9tjaka` | 4 | 6014 |
| `.runtime/ax02a/runtime_r1_legacy_eyy0_pon` | 4 | 6014 |
| `.runtime/ax02a/runtime_r1_legacy_wbsj5d40` | 4 | 6014 |
| `.runtime/ax02a/runtime_r1_legacy_zghr1k38` | 4 | 6014 |
| `.runtime/ax02a/runtime_r1_map_8gx8wryv` | 2 | 55552 |
| `.runtime/ax02a/runtime_r1_map_beaoowvz` | 2 | 55552 |
| `.runtime/ax02a/runtime_r1_map_h1sl_y_m` | 2 | 55552 |
| `.runtime/ax02a/runtime_r1_map_todbky1f` | 2 | 55552 |
| `.runtime/ax02a/runtime_r1_map_wyhlauh3` | 2 | 55552 |
| `.runtime/ax02a/runtime_r1_read_3ey8qguy` | 13 | 789490 |
| `.runtime/ax02a/runtime_r1_read_54lyuei2` | 13 | 789512 |
| `.runtime/ax02a/runtime_r1_read_dz0wbxhd` | 13 | 789490 |
| `.runtime/ax02a/runtime_r1_read_qvba5xhg` | 13 | 789490 |
| `.runtime/ax02a/ttc_analysis_0coklf8f` | 12 | 85257 |
| `.runtime/ax02a/ttc_analysis_31cir2zx` | 6 | 118738 |
| `.runtime/ax02a/ttc_analysis_35lu2ftg` | 7 | 64157 |
| `.runtime/ax02a/ttc_analysis_3z_kowqi` | 6 | 155602 |
| `.runtime/ax02a/ttc_analysis_4cc4kiam` | 6 | 118644 |
| `.runtime/ax02a/ttc_analysis_6gmdxvyy` | 16 | 154599 |
| `.runtime/ax02a/ttc_analysis_6zwymfv0` | 7 | 66495 |
| `.runtime/ax02a/ttc_analysis_7eoui4n_` | 36 | 238437 |
| `.runtime/ax02a/ttc_analysis_7yvorinm` | 7 | 66384 |
| `.runtime/ax02a/ttc_analysis_9zw4lsom` | 3 | 21375 |
| `.runtime/ax02a/ttc_analysis__01jrymq` | 7 | 66384 |
| `.runtime/ax02a/ttc_analysis__pnzt4_q` | 3 | 21375 |
| `.runtime/ax02a/ttc_analysis__rm47vd_` | 7 | 66495 |
| `.runtime/ax02a/ttc_analysis_a7f9rjpr` | 6 | 118804 |
| `.runtime/ax02a/ttc_analysis_aowtohar` | 16 | 163589 |
| `.runtime/ax02a/ttc_analysis_azqznsiu` | 6 | 118738 |
| `.runtime/ax02a/ttc_analysis_c8gq6ww9` | 16 | 163589 |
| `.runtime/ax02a/ttc_analysis_ceahc2es` | 6 | 154865 |
| `.runtime/ax02a/ttc_analysis_cs4ozhn2` | 7 | 66384 |
| `.runtime/ax02a/ttc_analysis_d5_o7wqp` | 36 | 239001 |
| `.runtime/ax02a/ttc_analysis_dlzkdswf` | 12 | 85389 |
| `.runtime/ax02a/ttc_analysis_dmsuplxs` | 3 | 21342 |
| `.runtime/ax02a/ttc_analysis_f5y1z0w7` | 8 | 81869 |
| `.runtime/ax02a/ttc_analysis_g5517eci` | 8 | 81647 |
| `.runtime/ax02a/ttc_analysis_gnvhmh_y` | 3 | 20635 |
| `.runtime/ax02a/ttc_analysis_hnsqie10` | 12 | 82743 |
| `.runtime/ax02a/ttc_analysis_i6b6ner0` | 8 | 77375 |
| `.runtime/ax02a/ttc_analysis_iorsupiy` | 16 | 154599 |
| `.runtime/ax02a/ttc_analysis_jb47xmx4` | 36 | 239397 |
| `.runtime/ax02a/ttc_analysis_jdv7z804` | 3 | 21342 |
| `.runtime/ax02a/ttc_analysis_k5xpvzct` | 8 | 77375 |
| `.runtime/ax02a/ttc_analysis_kbqiu7rv` | 3 | 21256 |
| `.runtime/ax02a/ttc_analysis_kui8yrgl` | 16 | 163145 |
| `.runtime/ax02a/ttc_analysis_l344mc84` | 16 | 163145 |
| `.runtime/ax02a/ttc_analysis_l9jp1chv` | 7 | 66495 |
| `.runtime/ax02a/ttc_analysis_lban0hea` | 12 | 82743 |
| `.runtime/ax02a/ttc_analysis_lox95t3j` | 6 | 118644 |
| `.runtime/ax02a/ttc_analysis_ltiizjnb` | 36 | 239397 |
| `.runtime/ax02a/ttc_analysis_mkuk74ve` | 8 | 81869 |
| `.runtime/ax02a/ttc_analysis_mrvo0tk8` | 12 | 85389 |
| `.runtime/ax02a/ttc_analysis_mwk0_yr7` | 6 | 118804 |
| `.runtime/ax02a/ttc_analysis_n60_i3xo` | 6 | 154865 |
| `.runtime/ax02a/ttc_analysis_n7nypmgd` | 36 | 238437 |
| `.runtime/ax02a/ttc_analysis_nfjou5_m` | 8 | 81869 |
| `.runtime/ax02a/ttc_analysis_ngm4yn4u` | 3 | 21375 |
| `.runtime/ax02a/ttc_analysis_ptiw99jm` | 6 | 155602 |
| `.runtime/ax02a/ttc_analysis_pxnfuwi7` | 6 | 118644 |
| `.runtime/ax02a/ttc_analysis_qe4ceddy` | 6 | 118804 |
| `.runtime/ax02a/ttc_analysis_rhska0yu` | 6 | 155536 |
| `.runtime/ax02a/ttc_analysis_rk3jfkzg` | 36 | 239397 |
| `.runtime/ax02a/ttc_analysis_scwnwe1t` | 6 | 155602 |
| `.runtime/ax02a/ttc_analysis_segy2ki4` | 3 | 21342 |
| `.runtime/ax02a/ttc_analysis_sqqt9483` | 36 | 239001 |
| `.runtime/ax02a/ttc_analysis_sul1sg6o` | 12 | 85257 |
| `.runtime/ax02a/ttc_analysis_t6m9z0sp` | 3 | 20595 |
| `.runtime/ax02a/ttc_analysis_tzo4c1qp` | 12 | 85389 |
| `.runtime/ax02a/ttc_analysis_ugtr9swv` | 3 | 21223 |
| `.runtime/ax02a/ttc_analysis_un49420b` | 8 | 81647 |
| `.runtime/ax02a/ttc_analysis_vhc6qx2l` | 3 | 21256 |
| `.runtime/ax02a/ttc_analysis_w2d564d9` | 3 | 20595 |
| `.runtime/ax02a/ttc_analysis_w64jfayi` | 16 | 163589 |
| `.runtime/ax02a/ttc_analysis_xbts31vr` | 3 | 21256 |
| `.runtime/ax02a/ttc_analysis_ybk5thr_` | 3 | 20718 |
| `.runtime/ax02a/ttc_analysis_ymrnp23u` | 6 | 155536 |
| `.runtime/ax02a/ttc_analysis_yvpw2fxm` | 3 | 21223 |
| `.runtime/ax02a/ttc_formats_2bgmjt13` | 2 | 19380 |
| `.runtime/ax02a/ttc_formats_2h8xt3ps` | 2 | 19380 |
| `.runtime/ax02a/ttc_formats_c4i_zlz2` | 2 | 19380 |
| `.runtime/ax02a/ttc_formats_csw_xtiu` | 2 | 19380 |
| `.runtime/ax02a/ttc_formats_knycpcng` | 2 | 19380 |
| `.runtime/ax02a/ttc_formats_pd5sdybk` | 1 | 5629 |
| `.runtime/ax02a/ttc_formats_re9dshld` | 1 | 5629 |
| `.runtime/ax02a/ttc_readback_2007c7qc` | 5 | 33486 |
| `.runtime/ax02a/ttc_readback_2wpaqtti` | 1 | 99 |
| `.runtime/ax02a/ttc_readback__tnu8yw1` | 5 | 33486 |
| `.runtime/ax02a/ttc_readback_m31mq3wz` | 1 | 99 |
| `.runtime/ax02a/ttc_readback_rha5s36f` | 5 | 33486 |
| `.runtime/ax02a/ttc_readback_whz2jo6n` | 5 | 33486 |
| `.runtime/ax02a/ttc_test_0dynfbz_` | 5 | 17654 |
| `.runtime/ax02a/ttc_test_1h_9efbl` | 5 | 17654 |
| `.runtime/ax02a/ttc_test_1yi1ntpg` | 1 | 59549 |
| `.runtime/ax02a/ttc_test_5sz63kn2` | 5 | 17658 |
| `.runtime/ax02a/ttc_test_6sdvh675` | 1 | 59549 |
| `.runtime/ax02a/ttc_test_83ptl8bl` | 1 | 59549 |
| `.runtime/ax02a/ttc_test_8ciu_k8y` | 1 | 59549 |
| `.runtime/ax02a/ttc_test__5y6xdaa` | 1 | 59549 |
| `.runtime/ax02a/ttc_test__s1fd6o4` | 5 | 17658 |
| `.runtime/ax02a/ttc_test_a2h_7ccy` | 5 | 17654 |
| `.runtime/ax02a/ttc_test_l1egl76d` | 1 | 59549 |
| `.runtime/ax02a/ttc_test_lncki_hm` | 1 | 59549 |
| `.runtime/ax02a/ttc_test_mcie496w` | 5 | 17654 |
| `.runtime/ax02a/ttc_test_xq0mosmj` | 5 | 17658 |

## 本轮明确保留

- 全部六套 `vitis_*` workspace、ELF/map/FSBL及候选来源记录；不能以“旧版”判为垃圾。约470MiB，是AX-02A主要占用，当前规则要求保留。
- `board_manual/`全部真实原始/失败/中断数据及压缩包、开始前配置、replay全部输入/参考、phase_p1000_descriptor。
- `ps_target/` XSA、`target/codegen/`算法源、成功构建完整日志和verification精简证据。
- 既有AX00/AX01/Issue8证据及MEX/XSI；baselines、generated/legacy_m3_p3、references和厂商资料。
- 用户本地SLX/参数修改、`simulation/ax01b_r5_sfun.c`、`simulink模型/AXU5EV_R5_Control_wrapper.slx`，不猜测其无用。

## 暂不列入删除的中间目录

`probe_*`、`ps_minimal*`、`ps_platform*`、`diagnostic_bd`、target_recheck、安装/探测日志和本地辅助脚本仍保留。本轮未逐项闭合它们与阶段证据的引用，不能仅凭名称认定可删。

根目录 `.srcs/`、`.Xil/` 当前无文件，但本轮不改；`slprj/` 和 `AXU5EV_R5_Runtime.slxc` 为工具缓存，未核实当前MATLAB会话是否使用，暂不删除。无需为了10.6MiB清理而关闭模型或保存窗口。

## 已实施的整理

新增统一工作区指南；将堆叠的交接分为当前HANDOFF与同目录历史存档；同步根README、固件README、上板指南导航、状态JSON与阶段报告入口。保留物理目录避免破坏已有launch/构建/来源路径。GitHub沿当前PR16提交供Review，不合并；最终提交SHA见PR记录。
