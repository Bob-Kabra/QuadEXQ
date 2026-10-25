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
// QuadEXQ: NEW GAME start-map picker
// Candidates: start.bsp (anywhere, id1 included) + every map in the game folder
// with "start" in its name. With one candidate New Game starts at once; with
// more, the main menu shows a list (Esc goes back). The default choice is
// newgame_map if set, otherwise start.

#define QX_PICK_MAX		16
static int	qx_pick_active;			// the main menu is showing the list
static int	qx_pick_count;
static char	qx_pick[QX_PICK_MAX][MAX_QPATH_64];
static char	qx_pick_chosen[MAX_QPATH_64];
static int	qx_pick_saved_cursor;	// main menu row to come back to

static void QX_Pick_Add (const char *name)
{
	int i;
	if (qx_pick_count >= QX_PICK_MAX)
		return;
	for (i = 0; i < qx_pick_count; i++)
		if (!strcmp (qx_pick[i], name))
			return;
	c_strlcpy (qx_pick[qx_pick_count++], name);
}

static int QX_Pick_Build (void)
{
	clist_t *cursor;
	const char *want = Game_NewGameMap ();
	int i, def = 0;

	qx_pick_count = 0;
	if (COM_FindFile_Obsolete ("maps/start.bsp"))
		QX_Pick_Add ("start");
	if (newgame_map.string[0] && COM_FindFile_Obsolete (va("maps/%s.bsp", newgame_map.string)))
		QX_Pick_Add (newgame_map.string);
	for (cursor = list_info[list_type_map].plist; cursor; cursor = cursor->next)
		if (strstr (cursor->name, "start"))
			QX_Pick_Add (cursor->name);

	for (i = 0; i < qx_pick_count; i++)
		if (!strcmp (qx_pick[i], want)) { def = i; break; }
	return def;
}

static void QX_Do_NewGame_Picked_ (void)
{
	if (sv.active)
		CL_Disconnect ();

	SCR_BeginLoadingPlaque_Force_NoTransition ();
	Key_SetDest (key_game);
	console1.visible_pct = 0;

	Cbuf_AddTextLine ("maxplayers 1");
	Cbuf_AddTextLine ("deathmatch 0");
	Cbuf_AddTextLine ("coop 0");
	Cbuf_AddTextLine ("resetcvar sv_progs");
	Cbuf_AddTextLinef ("map %s", qx_pick_chosen);
}

static void QX_Pick_Start (int which)
{
	c_strlcpy (qx_pick_chosen, qx_pick[which]);
	qx_pick_active = false;
	if (sv.active)	Mnu_Dialog_Modal_YesNo (QX_Do_NewGame_Picked_, NULL, "Are you sure you want to" NEWLINE "start a new game?" NEWLINE "(%s)", qx_pick_chosen);
	else			QX_Do_NewGame_Picked_ ();
}

static void QX_Pick_Leave (void)
{
	qx_pick_active = false;
	QX_Continue_Scan ();					// restores the row count
	local_menu->cursor = qx_pick_saved_cursor;
	if (local_menu->cursor >= local_menu->cursor_solid_count)
		local_menu->cursor = 0;
}

static void QX_NewGame_Selected (void)
{
	int def = QX_Pick_Build ();

	if (qx_pick_count <= 1) {			// nothing to choose: go
		if (qx_pick_count == 1)
			QX_Pick_Start (0);
		else if (sv.active)
			Mnu_Dialog_Modal_YesNo (Mnu_SinglePlayer_Do_NewGame_, NULL, "Are you sure you want to" NEWLINE "start a new game?");
		else
			Mnu_SinglePlayer_Do_NewGame_ ();
		return;
	}
	qx_pick_saved_cursor = local_menu->cursor;
	qx_pick_active = true;
	local_menu->cursor_solid_count = qx_pick_count;
	local_menu->cursor = def;
}

static void QX_Pick_Draw (void)
{
	int i, y = 48;
	const char *def = Game_NewGameMap ();

	M_PrintWhite (72, 36, "Choose where to start:");
	Hotspots_Add (72, y, 24 * 8, qx_pick_count * 8, qx_pick_count, hotspottype_button);
	for (i = 0; i < qx_pick_count; i++, y += 8) {
		const char *s = va("%s%s", qx_pick[i], !strcmp (qx_pick[i], def) ? "  (default)" : "");
		if (i == local_menu->cursor)	M_PrintWhite (80, y, s);
		else							M_Print (80, y, s);
	}
	// blinking cursor like the other text menus
	M_DrawCharacter (68, 48 + local_menu->cursor * 8, 12 + ((int)(realtime * 4) & 1));
	M_Print (72, y + 8, "Enter: start   Esc: back");
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

	if (qx_pick_active) {
		QX_Pick_Draw ();
		return;
	}

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
	if (qx_pick_active) {
		switch (key) {
		default:				// Nothing
		case_break K_ESCAPE:	MENU_ROW_CHANGE_HARD_SOUND (); QX_Pick_Leave ();
		case_break K_DOWNARROW:	MENU_ROW_CHANGE_HARD_SOUND (); if (++local_menu->cursor >= qx_pick_count) local_menu->cursor = 0;
		case_break K_UPARROW:	MENU_ROW_CHANGE_HARD_SOUND (); if (--local_menu->cursor < 0) local_menu->cursor = qx_pick_count - 1;
		case_break K_ENTER:		QX_Pick_Start (local_menu->cursor);
		}
		return;
	}

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
		case_break opt_new_game_1:			QX_NewGame_Selected ();
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
	qx_pick_active = false;
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
