/*
 * refresh_timer.h
 *
 *  Created on: 18 mar 2020
 *      Author: Poldo
 */

#ifndef HW_REFRESH_H_
#define HW_REFRESH_H_

#include <hw_common.h>

extern volatile uint8_t refresh_flag;

void TIM1_UP_TIM16_IRQHandler();
void hw_refresh_setup();


#endif /* HW_REFRESH_H_ */
