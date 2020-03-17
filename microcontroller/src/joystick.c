/*
 * joystick.c
 *
 *  Created on: 20 dic 2019
 *      Author: Poldo
 */

#include "joystick.h"

#define BUTTON_PORT GPIOC
#define BUTTON_A_PIN GPIO_PIN_10
#define BUTTON_B_PIN GPIO_PIN_11
#define BUTTON_A 0
#define BUTTON_B 1

static volatile uint8_t button_state = 0x00;
static volatile uint8_t button_state_old = 0x00;
static volatile uint8_t button_pressed = 0x00;
static volatile uint8_t button_a_count;
static volatile uint8_t button_b_count;

void TIM2_IRQHandler(void)
{
	TIM2->SR &= ~TIM_SR_UIF;
	/* Button A debounce */
	uint8_t temp_button_state = HAL_GPIO_ReadPin(BUTTON_PORT, BUTTON_A_PIN);
	button_a_count = (button_a_count << 1) | temp_button_state;
	if (button_a_count == 0xFF)
		button_state |= (1U << BUTTON_A);
	else if (!button_a_count)
		button_state &= ~ (1U << BUTTON_A);
	/* Button B debounce */
	temp_button_state = HAL_GPIO_ReadPin(BUTTON_PORT, BUTTON_B_PIN);
	button_b_count = (button_b_count << 1) | temp_button_state;
	if (button_b_count == 0xFF)
		button_state |= (1U << BUTTON_B);
	else if (!button_b_count)
		button_state &= ~ (1U << BUTTON_B);
}

void joystick_setup()
{
	/* GPIO Port C clock enable */
	__HAL_RCC_GPIOC_CLK_ENABLE();
	/* TIM2 Clock enable */
	__HAL_RCC_TIM2_CLK_ENABLE();
	/* TIM2 interrupt Init */
	HAL_NVIC_SetPriority(TIM2_IRQn, 0, 0);
	HAL_NVIC_EnableIRQ(TIM2_IRQn);
	/* TIM2 setup */
	TIM2->ARR = 10;
	TIM2->PSC = 8000;
	TIM2->DIER = TIM_DIER_UIE;
	/* TIM2 start */
	TIM2->CR1 =	TIM_CR1_CEN;
	/* Configure GPIO pins : PC10 PC11 */
	GPIO_InitTypeDef GPIO_InitStruct = {0};
	GPIO_InitStruct.Pin = GPIO_PIN_10|GPIO_PIN_11;
	GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
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

