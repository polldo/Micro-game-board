/*
 * display.c
 *
 *  Created on: 19 dic 2019
 *      Author: Poldo
 */

#include "display.h"

#define DISPLAY_LENGTH 1024

static uint8_t display_buffer[DISPLAY_LENGTH];

void display_setup()
{
	/* SPI2 and GPIO clock enable */
	__HAL_RCC_SPI2_CLK_ENABLE();
	__HAL_RCC_GPIOC_CLK_ENABLE();
	__HAL_RCC_GPIOB_CLK_ENABLE();
	/* SPI2 GPIO Configuration
	    PC3     ------> SPI2_MOSI
	    PB10     ------> SPI2_SCK
	    PC12	------> SPI_SS
	*/
	GPIO_InitTypeDef GPIO_InitStruct = {0};
	GPIO_InitStruct.Pin = GPIO_PIN_12;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
	GPIO_InitStruct.Pin = GPIO_PIN_3;
	GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	GPIO_InitStruct.Alternate = GPIO_AF5_SPI2;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStruct);
	GPIO_InitStruct.Pin = GPIO_PIN_10;
	GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	GPIO_InitStruct.Alternate = GPIO_AF5_SPI2;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);
	/* SPI2 Configuration
	 	Transmit-only mode
	 	MSB first
	 	Baudrate clk/64
		Master configuration
		Datasize 8 bit
	*/
	SPI2->CR2 = (SPI_CR2_DS_0 | SPI_CR2_DS_1 | SPI_CR2_DS_2 | SPI_CR2_NSSP);
	SPI2->CR1 =
	(
			SPI_CR1_SPE
			| SPI_CR1_BIDIMODE | SPI_CR1_BIDIOE
			| SPI_CR1_BR_1
			//| SPI_CR1_BR_0 | SPI_CR1_BR_2
			| SPI_CR1_MSTR
	);
	/* SPI SS enable */
	HAL_GPIO_WritePin(GPIOC, GPIO_PIN_12, GPIO_PIN_SET);
}

void display_send()
{
	/* Send init cmd */
	for (uint8_t init_count = 0; init_count < 2; init_count++)
	{
		while (! (SPI2->SR & SPI_SR_TXE) );
		*((__IO uint8_t *)&SPI2->DR) = 0x01;
	}
	/* Send the display buffer */
	for (uint16_t transfer_count = 0; transfer_count < DISPLAY_LENGTH; transfer_count++)
	{
		while (! (SPI2->SR & SPI_SR_TXE) );
		*((__IO uint8_t *)&SPI2->DR) = display_buffer[transfer_count];
	}
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

