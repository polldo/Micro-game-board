/*
 * debug_pin.h
 *
 *  Created on: 21 dic 2019
 *      Author: Poldo
 */

#ifndef DEBUG_PIN_H_
#define DEBUG_PIN_H_

#include <hw_common.h>

#define DEBUG_PIN 	GPIO_PIN_9
#define DEBUG_PORT 	GPIOC
#define DEBUG_HIGH 		HAL_GPIO_WritePin(DEBUG_PORT, DEBUG_PIN, GPIO_PIN_SET);
#define DEBUG_LOW 		HAL_GPIO_WritePin(DEBUG_PORT, DEBUG_PIN, GPIO_PIN_RESET);
#define DEBUG_TOGGLE 	HAL_GPIO_TogglePin(DEBUG_PORT, DEBUG_PIN);

void debug_pin_init();

#endif /* DEBUG_PIN_H_ */
