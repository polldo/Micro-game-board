/*
 * display.c
 *
 *  Created on: 19 dic 2019
 *      Author: Poldo
 */

#include <display.h>
#include <hw_display.h>

/* Buffer display definition. 
 * Buffer description: each bit represents a pixel, 128 cols and 64 rows bit mapping 
 */
#define DISPLAY_LENGTH 1024
static uint8_t display_buffer[DISPLAY_LENGTH];

void display_fill(uint8_t color)
{
	for(int index = 0; index < DISPLAY_LENGTH; index++)
	{
		display_buffer[index] = color;
	}
}

void display_setup()
{
	hw_display_setup();
}

void display_send()
{
	hw_display_send(display_buffer);
}

void display_draw(uint8_t x, uint8_t y, uint8_t color)
{
	uint8_t row = (uint8_t)y / 8;
	if (color == 0)
		display_buffer[(row*128) + (uint8_t)x] |= 1 << ((uint8_t)y % 8);
	else if (color == 1)
		display_buffer[(row*128) + (uint8_t)x] &= ~ ( 1 << ((uint8_t)y % 8) );
	else if (color == 2)
		display_buffer[(row*128) + (uint8_t)x] ^=  ( 1 << ((uint8_t)y % 8) );
}

