# Module boundary only: ideal 50 MHz fast clock, including both edges.
# External I/O delays, board clock generation/jitter and reset/CDC integration
# remain AX-02C/system responsibilities. No false paths or multicycles.
create_clock -name clk -period 20.000 -waveform {0.000 10.000} [get_ports clk]
