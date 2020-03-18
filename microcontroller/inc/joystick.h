/*
 * joystick.h
 *
 *  Created on: 20 dic 2019
 *      Author: Poldo
 */

#ifndef JOYSTICK_H_
#define JOYSTICK_H_

#include <common.h>

#define BUTTON_A 0
#define BUTTON_B 1

void joystick_setup();
void joystick_update();
uint8_t joystick_held(uint8_t button);
uint8_t joystick_pressed(uint8_t button);

#endif /* JOYSTICK_H_ */
