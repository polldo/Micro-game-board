/*
 * refresh_timer.h
 *
 *  Created on: 19 dic 2019
 *      Author: Poldo
 */

#ifndef REFRESH_TIMER_H_
#define REFRESH_TIMER_H_

#include <hw_common.h>

void refresh_timer_interrupt();
void refresh_timer_setup();
uint8_t refresh_timer_req();

void refresh_timer_reset();
uint8_t refresh_timer_get();

#endif /* REFRESH_TIMER_H_ */
