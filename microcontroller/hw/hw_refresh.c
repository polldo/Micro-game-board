/*
 * refresh_timer.c
 *
 *  Created on: 18 mar 2020
 *      Author: Poldo
 */

#include <hw_refresh.h>

volatile uint8_t refresh_flag = 0;

void TIM1_UP_TIM16_IRQHandler()
{
	TIM1->SR &= ~TIM_DIER_UIE;
	refresh_flag = 1;
}

void hw_refresh_setup()
{
	/* TIM1 Clock enable */
    __HAL_RCC_TIM1_CLK_ENABLE();
    /* TIM1 interrupt Init */
    HAL_NVIC_SetPriority(TIM1_UP_TIM16_IRQn, 0, 0);
    HAL_NVIC_EnableIRQ(TIM1_UP_TIM16_IRQn);
	/* TIM1 setup */
#ifdef REFRESH_60HZ
    /* Refresh set to 60 Hz */
	TIM1->ARR = 1666;
#else
    /* Refresh set to 30 Hz */
	TIM1->ARR = 3332;
#endif
	TIM1->PSC = 800;
	TIM1->DIER = TIM_DIER_UIE;
	/* TIM1 start */
	TIM1->CR1 =	TIM_CR1_CEN;
}
