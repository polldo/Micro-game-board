/*
 * refresh_timer.c
 *
 *  Created on: 19 dic 2019
 *      Author: Poldo
 */

#include <refresh.h>
#include <hw_refresh.h>

extern volatile uint8_t refresh_flag;

void refresh_setup()
{
	hw_refresh_setup();
}

uint8_t refresh_check()
{
	uint8_t temp_flag = refresh_flag;
	refresh_flag = 0;
	return temp_flag;
}

void refresh_reset()
{
	refresh_flag = 0;
}

uint8_t refresh_get()
{
	return refresh_flag;
}
