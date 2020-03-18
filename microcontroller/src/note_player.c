/*
 * note_player.c
 *
 *  Created on: 20 dic 2019
 *      Author: Poldo
 */

#include <note_player.h>
#include <hw_note_player.h>

uint8_t volume = 1;
t_song *current_song;
volatile uint16_t current_song_index;
uint8_t current_loop;

void note_player_setup()
{
	hw_note_player_setup();
}

void note_player_stop()
{
	hw_note_player_stop();
}

void note_player_play(t_song *song, uint8_t loop_en)
{
	hw_note_player_stop();
	current_song_index = 0;
	current_song = song;
	current_loop = loop_en;
	hw_note_player_start();
}

void note_player_volume_set(uint8_t vol)
{
	volume = vol;
}
