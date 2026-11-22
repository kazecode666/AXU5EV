#ifndef MOTOR_CONTROL_ETHERNET_H
#define MOTOR_CONTROL_ETHERNET_H

#include "ax05a_online.h"
#include <stddef.h>

bool motor_control_parse_request(const char *line, Ax05aRequest *request);
Ax05aReply motor_control_submit(Ax05aRequest request);
bool motor_control_net_start(void);
void motor_control_net_poll(void);
void motor_control_gem_poll(void);
void motor_control_record_poll(uint32_t now_ms);

/* Transport calls the service once per complete request line. */
size_t motor_control_reply(char *out, size_t capacity, const uint8_t *line, size_t length);
void motor_control_net_identity(uint32_t application, uint32_t profile, uint32_t link_mbps);

#endif
