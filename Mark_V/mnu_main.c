/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2002-2009 John Fitzgibbons and others
Copyright (C) 2009-2018 Baker and others

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

// mnu_main.c

#include "menu_local.h" // Special access

#define LOCAL_MENU_STATE		menu_state_Main
#define LOCAL_EVENT(NAME)		void Mnu_ ## Main ## _ ## NAME

#define local_menu				(&menux[LOCAL_MENU_STATE]) // /*static menux_t *menu = &menux[OUR_MENU_STATE]

// Define menu items
// QuadEXQ: two rows are added above the stock picture.
//   Continue  (only when the autosave slot file exists, s19.sav by default)
//   New Game
//   Single Player / Multiplayer / Options / Help / Quit  (gfx/mainmenu.lmp)
typedef enum { ENUM_FORCE_INT_GCC_ (opt)
	opt_continue_0,
	opt_new_game_1,
	opt_single_player_2,
	opt_multiplayer_game_3,
	opt_options_4,
	opt_help_5,
	opt_quit_6,
	opt_COUNT // Ender
} opt_e;

void Mnu_SinglePlayer_Do_NewGame_ (void); // mnu_singleplayer.c

static int qx_has_continue;		// the autosave slot file exists

static int QX_Continue_Slot (void)
{
	int slot = (int)sv_autosave_slot.value;
	return (slot >= 1 && slot <= 20) ? slot - 1 : -1;	// menu slot 20 = s19.sav
}

static void QX_Continue_Scan (void)
{
	char name[MAX_OSPATH];
	int slot = QX_Continue_Slot ();

	qx_has_continue = false;
	if (slot >= 0) {
		FS_FullPath_From_QPath (name, va("s%d.sav", slot));
		qx_has_continue = File_Exists (name);
	}
	local_menu->cursor_solid_count = qx_has_continue ? opt_COUNT : opt_COUNT - 1;
	if (local_menu->cursor >= local_menu->cursor_solid_count)
		local_menu->cursor = 0;
}

// cursor row -> item (row 0 is New Game when there is nothing to continue)
static int QX_Item (int cursor)
{
	return qx_has_continue ? cursor : cursor + 1;
}

static void QX_Do_Continue_ (void)
{
	int slot = QX_Continue_Slot ();
	if (slot < 0)
		return;
	SCR_BeginLoadingPlaque ();
	Key_SetDest (key_game);
	console1.visible_pct = 0;
	Cbuf_AddTextLinef ("load s%d", slot);
}

//=============================================================================
/* MAIN MENU */


//
// Draw
//

LOCAL_EVENT (Draw) (void)
{
	qpic_t	*p;
	int		y = 32;
	M_DrawTransPic (16, 4, Draw_CachePic ("gfx/qplaque.lmp"), NO_HOTSPOTS_0, USE_IMAGE_SIZE_NEG1, USE_IMAGE_SIZE_NEG1);
	p = Draw_CachePic ("gfx/ttl_main.lmp");
		M_DrawPicCentered (4, p);

	// Hotspots are numbered in draw order, so the added rows come first
	if (qx_has_continue) {
		M_DrawTransPic (72, y, Draw_CachePic ("gfx/qx_continue.lmp"), 1, USE_IMAGE_SIZE_NEG1, USE_IMAGE_SIZE_NEG1);
		y += Q_FAT_ROW_SIZE_20;
	}
	M_DrawTransPic (72, y, Draw_CachePic ("gfx/qx_newgame.lmp"), 1, USE_IMAGE_SIZE_NEG1, USE_IMAGE_SIZE_NEG1);
	y += Q_FAT_ROW_SIZE_20;

#ifdef SUPPORTS_NEHAHRA
	if (nehahra_active) // For Nehahra "gamemenu.lmp" is the normal looking one.  Nehahra "mainmenu.lmp" has a "Play Demo" menu.
		M_DrawTransPic (72, y, Draw_CachePic ("gfx/gamemenu.lmp"), 5, USE_IMAGE_SIZE_NEG1, Q_FAT_ROW_SIZE_20);
	else
#endif // !SUPPORTS_NEHAHRA
	M_DrawTransPic (72, y, Draw_CachePic ("gfx/mainmenu.lmp"), 5, USE_IMAGE_SIZE_NEG1, Q_FAT_ROW_SIZE_20);

	if (local_menu->cursor >= local_menu->cursor_solid_count)
		local_menu->cursor = 0;

	{  // The spinning Q cursor on this screen has 6 animation frames.  gfx/menudot1.lmp to gfx/menudot6.lmp
		int q_cursor_animation_frame = (int)(realtime * 10) % 6;
		M_DrawTransPic (54, 32 + local_menu->cursor * Q_FAT_ROW_SIZE_20, Draw_CachePic_Sfmt ("gfx/menudot%d.lmp", q_cursor_animation_frame + 1), NO_HOTSPOTS_0, USE_IMAGE_SIZE_NEG1, USE_IMAGE_SIZE_NEG1);
	}
}


//
// Key
//

// Since key can be upper or lower case it isn't quite a scancode
LOCAL_EVENT (KeyPress) (key_scancode_e key, int hotspot)
{
	switch (key) {
	default:				// Nothing
	case_break K_ESCAPE:		Key_SetDest (key_game);
	case_break K_DOWNARROW: 	MENU_ROW_CHANGE_HARD_SOUND (); if (++local_menu->cursor >= local_menu->cursor_solid_count) local_menu->cursor = 0;
	case_break K_UPARROW: 		MENU_ROW_CHANGE_HARD_SOUND (); if (--local_menu->cursor < 0) local_menu->cursor = local_menu->cursor_solid_count - 1;

	case_break K_ENTER:
		switch (QX_Item (local_menu->cursor)) {
		default:							// Nothing
		case_break opt_continue_0:			if (sv.active)	Mnu_Dialog_Modal_YesNo (QX_Do_Continue_, NULL, "Load the last autosave?" NEWLINE "Unsaved progress will be lost.");
											else			QX_Do_Continue_ ();
		case_break opt_new_game_1:			if (sv.active)	Mnu_Dialog_Modal_YesNo (Mnu_SinglePlayer_Do_NewGame_, NULL, "Are you sure you want to" NEWLINE "start a new game?");
											else			Mnu_SinglePlayer_Do_NewGame_ ();
		case_break opt_single_player_2:		Mnu_SinglePlayer_Enter_f (NULL);
		case_break opt_multiplayer_game_3:	Mnu_MultiPlayer_Enter_f (NULL);
		case_break opt_options_4:			Mnu_Options_Enter_f (NULL);
		case_break opt_help_5:				Mnu_Help_Enter_f (NULL);
		case_break opt_quit_6:				Mnu_Quit_Enter_f (NULL);
		} // end switch (item)
	} // end switch (key)
}


//
// Enter
//

LOCAL_EVENT (Enter_f) (lparse_t *unused)
{
	QX_Continue_Scan ();	// a new autosave may exist since last time
	if (key_dest != key_menu)
		local_menu->cursor = 0;	// opened from the game / console: Continue (or New Game) first
	Key_SetDest (key_menu); Menu_SetDest (LOCAL_MENU_STATE);
}


//
// InitOnce
//

LOCAL_EVENT (InitOnce) (menux_t *self)
{
	DEBUG_COMPILE_TIME_ASSERT (opt_COUNT, opt_COUNT == 7);
	self->cursor_solid_count = opt_COUNT - 1; // QuadEXQ: set again on every Enter (Continue row is optional)
}
