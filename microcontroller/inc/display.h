/*
 * display.h
 *
 *  Created on: 19 dic 2019
 *      Author: Poldo
 */

#ifndef DISPLAY_H_
#define DISPLAY_H_

#include <common.h>

void display_setup();
void display_send();
void display_draw(uint8_t x, uint8_t y, uint8_t color);

#endif /* DISPLAY_H_ */
