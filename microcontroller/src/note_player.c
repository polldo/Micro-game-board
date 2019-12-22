/*
 * note_player.c
 *
 *  Created on: 20 dic 2019
 *      Author: Poldo
 */

#include "note_player.h"

#define FREQUENCY_TIMER TIM3
#define DURATION_TIMER TIM4

static uint8_t volume = 1;
static t_song *current_song;
static volatile uint16_t current_song_index;
static uint8_t current_loop;

static void frequency_timer_setup();
static void duration_timer_setup();
static void note_player_start();

static void frequency_timer_setup()
{
	/* Enable FREQUENCY_TIMER clock -> FREQUENCY TIMER */
	__HAL_RCC_TIM3_CLK_ENABLE();
	/* FREQUENCY_TIMER GPIO Configuration
    	PA7     ------> TIM3_CH2
	 */
	__HAL_RCC_GPIOA_CLK_ENABLE();
	GPIO_InitTypeDef GPIO_InitStruct = {0};
	GPIO_InitStruct.Pin = GPIO_PIN_7;
	GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
	GPIO_InitStruct.Alternate = GPIO_AF2_TIM3;
	HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
	/* FREQUENCY_TIMER base setup */
	FREQUENCY_TIMER->PSC = 40;   /* Prescaler 40 -> timer clock =  2MHz*/
	FREQUENCY_TIMER->ARR = 3974; /* Period = CLK/(ARR*PSC) */
	FREQUENCY_TIMER->DIER = TIM_DIER_UIE;
	/* FREQUENCY_TIMER PWM ch2 setup */
	FREQUENCY_TIMER->CCER &= ~TIM_CCER_CC2E;
	FREQUENCY_TIMER->CCMR1 &= ~ (TIM_CCMR1_OC2M | TIM_CCMR1_CC2S);
	FREQUENCY_TIMER->CCMR1 |= (TIM_OCMODE_PWM1 << 8U);
	FREQUENCY_TIMER->CCER &= ~TIM_CCER_CC2P;
	FREQUENCY_TIMER->CCER |= (TIM_OCPOLARITY_HIGH << 4U);
	FREQUENCY_TIMER->CCR2 = 1800; /* Duty Cycle */
	/* Set the Preload enable bit for channel2 */
	FREQUENCY_TIMER->CCMR1 |= TIM_CCMR1_OC2PE;
	/* Configure the Output Fast mode */
	FREQUENCY_TIMER->CCMR1 &= ~TIM_CCMR1_OC2FE;
	FREQUENCY_TIMER->CCMR1 |= TIM_OCFAST_DISABLE << 8U;
	/* Reset the CCxE Bit and activate the channel */
	FREQUENCY_TIMER->CCER &= ~(TIM_CCER_CC1E << (TIM_CHANNEL_2 & 0x1FU));
	FREQUENCY_TIMER->CCER |= (uint32_t)(TIM_CCx_ENABLE << (TIM_CHANNEL_2 & 0x1FU));
}

static void duration_timer_setup()
{
	/* DURATION_TIMER Clock enable */
	__HAL_RCC_TIM4_CLK_ENABLE();
	/* DURATION_TIMER interrupt Init */
	HAL_NVIC_SetPriority(TIM4_IRQn, 0, 0);
	HAL_NVIC_EnableIRQ(TIM4_IRQn);
	/* DURATION_TIMER setup */
	DURATION_TIMER->ARR = 10;
	DURATION_TIMER->PSC = 8000; /* clk@80MHz -> 100 us per tick */
	DURATION_TIMER->DIER = TIM_DIER_UIE;
	/* DURATION_TIMER start */
	//DURATION_TIMER->CR1 =	TIM_CR1_CEN;
}

void note_player_setup()
{
	frequency_timer_setup();
	duration_timer_setup();
}

void TIM4_IRQHandler(void)
{
	FREQUENCY_TIMER->CR1 &= ~TIM_CR1_CEN;
	DURATION_TIMER->CR1 &= ~TIM_CR1_CEN;
	DURATION_TIMER->SR &= ~TIM_SR_UIF;
	/* Configure frequency and duration timer according to the next note */
	if (current_song_index < current_song->size)
	{
		t_note temp_note = current_song->notes[current_song_index];
		if (temp_note.frequency)
		{
			/* Setup and restart frequency timer */
			FREQUENCY_TIMER->ARR = temp_note.frequency;
			FREQUENCY_TIMER->CCR2 = (temp_note.frequency / 2) * volume / 100 ;
			FREQUENCY_TIMER->CR1 |= TIM_CR1_CEN;
		}
		/* Setup and restart duration timer */
		DURATION_TIMER->CNT = 0;
		DURATION_TIMER->ARR = temp_note.duration * 10; /* period = duration ms */
		DURATION_TIMER->CR1 |= TIM_CR1_CEN;
		/* Update note index */
		current_song_index++;
	} else if(current_loop)
	{
		current_song_index = 0;
		DURATION_TIMER->CNT = 0;
		DURATION_TIMER->ARR = 1;
		DURATION_TIMER->CR1 |= TIM_CR1_CEN;
	}
}

static void note_player_start()
{
	DURATION_TIMER->CNT = 0;
	DURATION_TIMER->ARR = 1;
	DURATION_TIMER->CR1 |= TIM_CR1_CEN;
}

void note_player_stop()
{
	FREQUENCY_TIMER->CR1 &= ~TIM_CR1_CEN;
	DURATION_TIMER->CR1 &= ~TIM_CR1_CEN;
}

void note_player_play(t_song *song, uint8_t loop_en)
{
	note_player_stop();
	current_song_index = 0;
	current_song = song;
	current_loop = loop_en;
	note_player_start();
}
