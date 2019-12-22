/*
 * joystick.h
 *
 *  Created on: 20 dic 2019
 *      Author: Poldo
 */

#ifndef JOYSTICK_H_
#define JOYSTICK_H_

#include "common.h"

#define BUTTON_A 0
#define BUTTON_B 1

void TIM2_IRQHandler(void);
void joystick_setup();
uint8_t joystick_pressed(uint8_t button);

#endif /* JOYSTICK_H_ */
