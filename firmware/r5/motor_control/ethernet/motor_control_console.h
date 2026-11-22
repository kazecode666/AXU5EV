#ifndef MOTOR_CONTROL_CONSOLE_H
#define MOTOR_CONTROL_CONSOLE_H

#include <stdbool.h>

/* One byte at a time. The returned line stays valid until the next byte. */
bool motor_control_console_input(char byte, char *command, const char **line);

#endif
