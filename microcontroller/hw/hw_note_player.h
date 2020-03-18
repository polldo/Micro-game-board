/*
 * hw_note_player.h
 *
 *  Created on: 18 mar 2020
 *      Author: Poldo
 */

#ifndef HW_NOTE_PLAYER_H_
#define HW_NOTE_PLAYER_H_

#include <hw_common.h>

void hw_note_player_setup();
void hw_note_player_start();
void hw_note_player_stop();
void TIM4_IRQHandler(void);

#endif /* HW_NOTE_PLAYER_H_ */
