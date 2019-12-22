/*
 * debug_pin.c
 *
 *  Created on: 21 dic 2019
 *      Author: Poldo
 */

#include "debug_pin.h"


void debug_pin_init()
{
    GPIO_InitTypeDef GPIO_InitStruct = {0};
    GPIO_InitStruct.Pin = DEBUG_PIN;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_HIGH;
    HAL_GPIO_Init(DEBUG_PORT, &GPIO_InitStruct);
}

