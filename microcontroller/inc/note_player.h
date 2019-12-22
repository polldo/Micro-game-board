/*
 * note_player.h
 *
 *  Created on: 20 dic 2019
 *      Author: Poldo
 */

#ifndef NOTE_PLAYER_H_
#define NOTE_PLAYER_H_

#include "common.h"

#define LOOP_DISABLED 0
#define LOOP_ENABLED 1

typedef struct note
{
	uint16_t frequency;
	uint16_t duration;
} t_note;

typedef struct song
{
	t_note *notes;
	uint16_t size;
} t_song;

void note_player_setup();
void note_player_stop();
void note_player_play(t_song *song, uint8_t loop_en);
void TIM4_IRQHandler(void);

#endif /* NOTE_PLAYER_H_ */
