/*
 * hw_display.h
 *
 *  Created on: 16 mar 2020
 *      Author: Poldo
 */

#ifndef HW_DISPLAY_H_
#define HW_DISPLAY_H_

#define I2C

#include <hw_common.h>

void hw_display_setup();

void hw_display_send(uint8_t *buffer);

#endif /* HW_DISPLAY_H_ */
