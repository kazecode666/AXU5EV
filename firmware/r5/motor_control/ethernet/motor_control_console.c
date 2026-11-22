#include "motor_control_console.h"
#include <stddef.h>

bool motor_control_console_input(char byte, char *command, const char **line)
{
    static char pending, buffer[192];
    static size_t used;
    static bool overflow;
    *line = NULL;
    if (!pending) {
        if (byte == 'g' || byte == 'o') {
            pending = byte;
        } else {
            *command = byte;
            return true;
        }
    } else if (byte == '\r' || byte == '\n') {
        buffer[used] = '\0';
        *command = pending;
        *line = overflow ? "" : buffer;
        pending = 0;
        used = 0;
        overflow = false;
        return true;
    } else if (used < sizeof(buffer) - 1u) {
        buffer[used++] = byte;
    } else {
        overflow = true;
    }
    return false;
}
