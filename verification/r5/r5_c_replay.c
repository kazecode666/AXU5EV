/* Host replay of generated model C; no controller implementation here. */
#include "AXU5EV_R5_Control.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char **argv)
{
    char line[4096];
    double row[27], worst = 0.0;
    unsigned long count = 0;
    if (argc != 2) return 2;
    FILE *input = fopen(argv[1], "r");
    if (!input) return 2;
    AXU5EV_R5_Control_initialize();
    while (fgets(line, sizeof(line), input)) {
        char *cursor = line, *end;
        for (int i = 0; i < 27; ++i) {
            row[i] = strtod(cursor, &end);
            if (end == cursor || !isfinite(row[i])) return 3;
            if (i < 26 && *end != ',') return 3;
            cursor = end + 1;
        }
        ExtU_AXU5EV_R5_Control_T *u = &AXU5EV_R5_Control_U;
        u->x_ref_mm = row[1]; u->x_mm = row[2]; u->v_mmps = row[3];
        u->Position_Loop_EN = row[4]; u->Close_Loop_EN = row[5];
        u->v_ref_cmd = row[6]; u->id_ref_cmd = row[7];
        u->iq_test_mode = row[8]; u->iq_test_ref = row[9];
        u->PI_Reset_EN = row[10]; u->Alignment_Enable = row[11];
        u->Init_Start = row[12]; u->Init_Reset = row[13];
        u->travel_fault_latch = row[14];
        AXU5EV_R5_Control_step();
        ExtY_AXU5EV_R5_Control_T *y = &AXU5EV_R5_Control_Y;
        const double actual[] = {y->id_ref_A, y->iq_ref_A, y->v_ref_mmps,
            y->Init_Done, y->Init_State_Num, y->id_init_ref, y->Angle_Init_EN,
            y->Theta_Offset_auto, y->x_align_mm_latch, y->alignment_ready,
            y->done_or_bypass, y->alignment_fault};
        for (int j = 0; j < 12; ++j) {
            double error = fabs(actual[j] - row[j+15]);
            if (!isfinite(actual[j]) || error > 1e-12) {
                fprintf(stderr,"FAIL row=%lu output=%d actual=%.17g expected=%.17g\n",
                    count, j+1, actual[j], row[j+15]);
                return 1;
            }
            if (error > worst) worst = error;
        }
        ++count;
    }
    fclose(input);
    AXU5EV_R5_Control_terminate();
    if (!count) return 3;
    printf("HOST_C_PASS samples=%lu max_error=%.17g\n", count, worst);
    return 0;
}
