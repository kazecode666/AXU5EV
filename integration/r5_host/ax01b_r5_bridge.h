#ifndef AX01B_R5_BRIDGE_H
#define AX01B_R5_BRIDGE_H
void ax01b_runtime_init(void);
void ax01b_runtime_step(const double *u);
void ax01b_runtime_output(double *y);
void ax01b_runtime_end(void);
#endif
