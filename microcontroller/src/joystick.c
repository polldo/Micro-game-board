/*
 * joystick.c
 *
 *  Created on: 20 dic 2019
 *      Author: Poldo
 */

#include <joystick.h>
#include <hw_joystick.h>

volatile uint8_t button_state = 0x00;
volatile uint8_t button_state_old = 0x00;
volatile uint8_t button_pressed = 0x00;

void joystick_setup()
{
	hw_joystick_setup();
}

/* Must be called at the beginning of every frame */
void joystick_update()
{
	/* Sample button state to prevent abnormalities */
	uint8_t button_state_current = button_state;
	/* Check whether some button has been pressed */
	button_pressed = (button_state_old ^ button_state_current) & (button_state_current ^ 0x00);
	/* Update old button values */ 
	button_state_old = button_state_current;
}

uint8_t joystick_held(uint8_t button)
{
	return button_state & (1 << button);
}

uint8_t joystick_pressed(uint8_t button)
{
	return button_pressed & (1 << button);
}

