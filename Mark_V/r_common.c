/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2013-2014 Baker

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
// r_common.c

#include "quakedef.h"


//
// view origin
//
vec3_t vup /* qasm */, vpn /* qasm */, vright /* qasm */; // ASM uses for sound only I think
vec3_t r_origin /* qasm */;
mplane_t r_frustum[4];

float r_fovx, r_fovy;

entity_t *currententity;
vec3_t modelorg  /* qasm */;

refdef_t r_refdef /* qasm */;

//
// screen size info
//


//
// refresh flags
//

// Put that into r_light.c



frame_render_t frame; // Baker: Doesn't really belong here.  Need to create an renderer common file?
level_info_t level; // Baker: Likewise, doesn't really belong here.




const byte *demos_lmp;
const byte *levels_lmp;
const byte *qx_continue_lmp;
const byte *qx_newgame_lmp;

/*
QuadEXQ: the main menu's CONTINUE and NEW GAME rows in the real Quake menu
font. They are put together from the player's own id1 menu art at startup
(nothing of id's is shipped): NEW GAME is the top row of gfx/sp_menu.lmp,
CONTINUE is cut letter by letter from gfx/mp_menu.lmp, and its C is the big
O of "Options" (gfx/mainmenu.lmp) opened on the right, about 270 degrees. If those files are missing,
not id1's, or not the expected size, the bundled pictures stay.
*/
#define QX_ROW_W	160
static byte qx_cont_buf[8 + QX_ROW_W * 20];
static byte qx_newg_buf[8 + QX_ROW_W * 24];

static const byte *QX_LoadId1Pic (const char *path, int w, int h)
{
	byte *f = COM_LoadMallocFile (path);
	if (!f)
		return NULL;
	if (!strstr (com_filepath, "/id1/") || LittleLong (((int *)f)[0]) != w || LittleLong (((int *)f)[1]) != h) {
		free (f);
		return NULL;
	}
	return f;
}

static void QX_Blit (byte *dst, int dw, int dx, const byte *src, int sw, int sx0, int sx1, int sy, int rows)
{
	int x, y;
	for (y = 0; y < rows; y++)
		for (x = sx0; x < sx1; x++) {
			byte c = src[8 + (sy + y) * sw + x];
			if (c != 255)
				dst[8 + y * dw + dx + x - sx0] = c;
		}
}

static void QX_BuildMenuRows (void)
{
	// letters of "Continue": source picture (0 sp, 1 mp), x from, x to, top row
	static const int glyphs[8][4] = {
		{2, 0, 22, 40},		// C  (the O of Options, opened up below)
		{1, 14, 36, 0},		// o  (Join)
		{1, 46, 65, 0},		// n  (Join)
		{1, 40, 59, 40},	// t  (Setup)
		{1, 36, 45, 0},		// i  (Join)
		{1, 46, 65, 0},		// n
		{1, 59, 79, 40},	// u  (Setup)
		{1, 22, 40, 40},	// e  (Setup)
	};
	const byte *sp = QX_LoadId1Pic ("gfx/sp_menu.lmp", 232, 64);
	const byte *mp = QX_LoadId1Pic ("gfx/mp_menu.lmp", 232, 64);
	const byte *mm = QX_LoadId1Pic ("gfx/mainmenu.lmp", 240, 112);
	int i, x, y;

	if (sp && mp && mm) {
		((int *)qx_cont_buf)[0] = LittleLong (QX_ROW_W);
		((int *)qx_cont_buf)[1] = LittleLong (20);
		memset (qx_cont_buf + 8, 255, QX_ROW_W * 20);
		for (i = 0, x = 1; i < 8; i++) {
			const int *g = glyphs[i];
			if (g[0] == 2)	QX_Blit (qx_cont_buf, QX_ROW_W, x, mm, 240, g[1], g[2], g[3], 20);
			else			QX_Blit (qx_cont_buf, QX_ROW_W, x, g[0] ? mp : sp, 232, g[1], g[2], g[3], 20);
			x += g[2] - g[1] + 1;
		}
		// O -> C: drop the middle of the right half (rows 6-12, columns 12-21 of
		// the glyph) and close the two cut ends with the outline color
		for (y = 5; y <= 13; y++) {
			for (i = 1 + 12; i <= 1 + 21; i++) {
				byte *px = &qx_cont_buf[8 + y * QX_ROW_W + i];
				if (y == 5 || y == 13)	{ if (*px != 255) *px = 96; }
				else					*px = 255;
			}
		}

		((int *)qx_newg_buf)[0] = LittleLong (QX_ROW_W);
		((int *)qx_newg_buf)[1] = LittleLong (24);
		memset (qx_newg_buf + 8, 255, QX_ROW_W * 24);
		QX_Blit (qx_newg_buf, QX_ROW_W, 0, sp, 232, 0, QX_ROW_W, 0, 20);
		QX_Blit (qx_newg_buf + QX_ROW_W * 20, QX_ROW_W, 78, sp, 232, 78, 93, 20, 4);	// the G's tail only

		qx_continue_lmp = qx_cont_buf;
		qx_newgame_lmp = qx_newg_buf;
	}
	if (sp) free ((void *)sp);
	if (mp) free ((void *)mp);
	if (mm) free ((void *)mm);
}

void R_Init (void)
{
	Cmd_AddCommands (R_Init);

	Sky_Init (); //johnfitz

	R_InitParticles (); // After R_InitTextures ?

	R_Init_Local (); // Runs either the rest of software or GL initialization

	// Loads fixed menus

	{
		const char *sname; const void *mem;
		demos_lmp  = mem = Bundle_File_Memory_Pointer ( (sname = "demos.lmp"),  NULL); if (!mem) System_Error ("Couldn't load %s", sname);
		levels_lmp = mem = Bundle_File_Memory_Pointer ( (sname = "levels.lmp"), NULL); if (!mem) System_Error ("Couldn't load %s", sname);
		qx_continue_lmp = mem = Bundle_File_Memory_Pointer ( (sname = "qx_continue.lmp"), NULL); if (!mem) System_Error ("Couldn't load %s", sname);
		qx_newgame_lmp  = mem = Bundle_File_Memory_Pointer ( (sname = "qx_newgame.lmp"),  NULL); if (!mem) System_Error ("Couldn't load %s", sname);
	}
	QX_BuildMenuRows ();	// the real Quake font, from your own id1 data
}


void R_NewMap (void)
{
// Note that this is NOT the server.
	int		i;

	for (i=0 ; i < 256 ; i++)
		d_lightstylevalue[i] = 264;		// normal light value

// clear out efrags in case the level hasn't been reloaded
// FIXME: is this one short?

	for (i = 0 ; i < cl.worldmodel->numleafs ; i++)
		cl.worldmodel->leafs[i].efrags = NULL;

	R_ClearParticles ();

	View_NewMap ();			// Baker: Clear viewshifts

#ifdef SUPPORTS_CUTSCENE_PROTECTION
	Cvar_Clear_Untrusted ();	// Baker: Ensure that cut-scenes and demos restore to correct values by firewalling cvar sets.
#endif // SUPPORTS_CUTSCENE_PROTECTION

	{
		const char *key = NULL;
		char buf[32] = {0};

		if ((key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "lavaalpha"))) {
			Cvar_SetQuick (&r_lavaalpha, va("%f", r_lavaalpha.value) );  // Dumb but effective.  The extra zeros means next set will not string match, triggering the change action.
			level.is_lavaalpha = true, level.lavaalpha = CLAMP(0, atof(key), 1);
		}
		if ((key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "slimealpha"))) {
			Cvar_SetQuick (&r_slimealpha, va("%f", r_slimealpha.value) );  // Dumb but effective.  The extra zeros means next set will not string match, triggering the change action.
			level.is_slimealpha = true, level.slimealpha = CLAMP(0, atof(key), 1);
		}
		if ((key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "wateralpha"))) {
			Cvar_SetQuick (&r_wateralpha, va("%f", r_wateralpha.value) );  // Dumb but effective.  The extra zeros means next set will not string match, triggering the change action.
			level.is_wateralpha = true, level.wateralpha = CLAMP(0, atof(key), 1);
		}
		if ((key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "mirroralpha"))) {
			Cvar_SetQuick (&gl_mirroralpha, va("%f", gl_mirroralpha.value) );  // Dumb but effective.  The extra zeros means next set will not string match, triggering the change action.
			level.is_mirroralpha = true, level.mirroralpha = CLAMP(0, atof(key), 1);
		}

		level.sound_nominal_clip_dist = SOUND_NOMINAL_CLIP_DIST_DEFAULT_1000;
		if ((key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "sound_clipdistance"))) {
			level.is_sound_nominal_clip_dist = true;
			level.sound_nominal_clip_dist = CLAMP(10, atof(key), 8192);	// 8192 cap for now, 10 to avoid division by zero.
		}


		// Scan for prefixes?
	}

	Sky_NewMap (); //johnfitz -- skybox in worldspawn


	R_NewMap_Local ();
}




/*
====================
R_Novis_f -- johnfitz
====================
*/
void R_Level_Key_Alpha_SkyFog_Changed (cvar_t *var)
{
	if (var == &r_lavaalpha && level.is_lavaalpha == true) {
		level.is_lavaalpha = -1; // Set but overridden
	}
	if (var == &r_wateralpha && level.is_wateralpha == true) {
		level.is_wateralpha = -1; // Set but overridden
	}
	if (var == &r_slimealpha && level.is_slimealpha == true) {
		level.is_slimealpha = -1; // Set but overridden
	}

	if (var == &gl_mirroralpha && level.is_mirroralpha == true) {
		level.is_mirroralpha = -1; // Set but overridden
	}

	if (var == &gl_skyfog && level.is_skyfog == true) {
		level.is_skyfog = -1; // Set but overridden
	}
#ifdef GLQUAKE_RENDERER_SUPPORT
	if (var == &gl_mirroralpha && level.is_mirroralpha == true) {
		extern int vis_changed;
		vis_changed = 1;
	}
#endif // GLQUAKE_RENDERER_SUPPORT
}


/*
====================
R_TimeRefresh_f

For program optimization
====================
*/
void R_TimeRefresh_f (lparse_t *unused)
{
	int			i;
	float		start, stop, elapsedtime;

	if (cls.state != ca_connected)
	{
		Con_PrintLinef ("No map running");
		return;
	}

	start = System_DoubleTime ();
	for (i = 0 ; i < 128 ; i++)
	{
		VID_BeginRendering (&clx, &cly, &clwidth, &clheight);
		r_refdef.viewangles[1] = i/128.0*360.0;
		R_RenderView ();
		VID_EndRendering ();
	}

	stop = System_DoubleTime ();
	elapsedtime = stop-start;
	Con_PrintLinef ("%f seconds (%f fps)", elapsedtime, 128/elapsedtime);
}


void R_SetLiquidAlpha (void)
{
	if (!level.water_vis_known && frame.has_abovewater && frame.has_underwater)
	{
		// Baker: Don't let this scenario lock us into a false reading.
		// Although this would be an extremely hard scenario to generate, would take an incredibly well placed saved game
		// and I tried hard to stand somewhere a save game cause this problem and couldn't despite my best efforts.

		if (!frame.nearwaterportal && !r_novis.value)
		{
			Con_DPrintLinef ("AUTO WATER VIS:  Level is vised!");
			level.water_vis_known = true;
			level.water_vis = true;
		}
	}

	if (r_novis.value)											frame.liquid_alpha = true;   // r_novis 1
	else if (level.water_vis_known && level.water_vis)			frame.liquid_alpha = true;   // Known to be watervised
	else if (level.water_vis_known && !level.water_vis)			frame.liquid_alpha = false;  // Known to be not watervised
	else if (frame.has_abovewater && frame.has_underwater)		frame.liquid_alpha = true;	 // Weird situation almost impossible
	else														frame.liquid_alpha = false;	 // Vis not known yet, but no water brushes in scene

	if (frame.liquid_alpha)
	{
		frame.lavaalpha		= level.is_lavaalpha  > 0 ? level.lavaalpha  : CLAMP(0, r_lavaalpha.value,  1.0);
		frame.slimealpha	= level.is_slimealpha > 0 ? level.slimealpha : CLAMP(0, r_slimealpha.value, 1.0);
		frame.wateralpha	= level.is_wateralpha > 0 ? level.wateralpha : CLAMP(0, r_wateralpha.value, 1.0);
	} else frame.wateralpha = frame.slimealpha = frame.lavaalpha = 1;

#if 0
	if (frame.has_mirror) {
		frame.mirroralpha   = level.is_mirroralpha > 0 ? level.mirroralpha : CLAMP(0, gl_mirroralpha.value, 1.0);
	} else frame.mirroralpha = 1;
#endif // See Scan_For_Mirrors ... this is too late.  Mirrors must be drawn first.
}



// Baker: Look for cvars and commands in common

/*
===============
R_TextureAnimation -- johnfitz -- added "frame" param to eliminate use of "currententity" global

Returns the proper texture for a given time and base texture
===============
*/
texture_t *R_TextureAnimation (texture_t *base, int frame)
{
	int		relative;
	int		count;

	if (frame)
	{
		if (base->alternate_anims)
			base = base->alternate_anims;
	}

	if (!base->anim_total)
		return base;

	relative = (int)(cl.ctime*10) % base->anim_total;

	count = 0;
	while (base->anim_min > relative || base->anim_max <= relative)
	{
		base = base->anim_next;
		if (!base)
			Host_Error ("R_TextureAnimation: broken cycle");
		if (++count > 100)
			Host_Error ("R_TextureAnimation: infinite cycle");
	}

	return base;
}



/*
=================
R_SetupAliasFrame -- johnfitz -- rewritten to support lerping
=================
*/
void R_SetupAliasFrame (aliashdr_t *paliashdr, int frame, lerpdata_t *lerpdata)
{
	entity_t		*e = currententity;
	int				posenum, numposes;

	if ((frame >= paliashdr->numframes) || (frame < 0))
	{
		Con_DPrintLinef ("R_AliasSetupFrame: no such frame %d", frame);
		frame = 0;
	}


	posenum = paliashdr->frames[frame].firstpose;
	numposes = paliashdr->frames[frame].numposes;

	if (numposes > 1)
	{
		e->lerptime = paliashdr->frames[frame].interval;
		posenum += (int)(cl.ctime / e->lerptime) % numposes;
	}
	else
		e->lerptime = 0.1;

	if (e->lerpflags & LERP_RESETANIM) //kill any lerp in progress
	{
		e->lerpstart = 0;
		e->previouspose = posenum;
		e->currentpose = posenum;
		e->lerpflags -= LERP_RESETANIM;
	}
	else if (e->currentpose != posenum) // pose changed, start new lerp
	{
		if (e->lerpflags & LERP_RESETANIM2) //defer lerping one more time
		{
			e->lerpstart = 0;
			e->previouspose = posenum;
			e->currentpose = posenum;
			e->lerpflags -= LERP_RESETANIM2;
#if 1 // Baker: Special exception :(
			if (cls.demoplayback && cls.demorewind)
				e->lerpflags -= LERP_RESETANIM;
#endif
		}
		else
		{
			e->lerpstart = cl.ctime;
			e->previouspose = e->currentpose;
			e->currentpose = posenum;
		}
	}

	//set up values
	if (r_lerpmodels.value && !((e->model->modelflags & MOD_NOLERP) && r_lerpmodels.value != 2))
	{
		if (e->lerpflags & LERP_FINISH && numposes == 1)
			lerpdata->blend = CLAMP (0, (cl.ctime - e->lerpstart) / (e->lerpfinish - e->lerpstart), 1);
		else
			lerpdata->blend = CLAMP (0, (cl.ctime - e->lerpstart) / e->lerptime, 1);
		lerpdata->pose1 = e->previouspose;
		lerpdata->pose2 = e->currentpose;
	}
	else //don't lerp
	{
		lerpdata->blend = 1;
		lerpdata->pose1 = posenum;
		lerpdata->pose2 = posenum;
	}
}

/*
=================
R_SetupEntityTransform -- johnfitz -- set up transform part of lerpdata
=================
*/
void R_SetupEntityTransform (entity_t *e, lerpdata_t *lerpdata)
{
	float blend;
	vec3_t d;
	int i;
#ifdef WINQUAKE_RENDERER_SUPPORT
// We aren't really sharing using the lerpdata input structure pointer externally
	lerpdata_t _lerpdata;
	lerpdata = &_lerpdata;
#endif // WINQUAKE_RENDERER_SUPPORT

	// if LERP_RESETMOVE, kill any lerps in progress
	if (e->lerpflags & LERP_RESETMOVE)
	{
		e->movelerpstart = 0;
		VectorCopy (e->origin, e->previousorigin);
		VectorCopy (e->origin, e->currentorigin);
		VectorCopy (e->angles, e->previousangles);
		VectorCopy (e->angles, e->currentangles);
		e->lerpflags -= LERP_RESETMOVE;
	}
	else if (!VectorCompare (e->origin, e->currentorigin) || !VectorCompare (e->angles, e->currentangles)) // origin/angles changed, start new lerp
	{
		e->movelerpstart = cl.ctime;
		VectorCopy (e->currentorigin, e->previousorigin);
		VectorCopy (e->origin,  e->currentorigin);
		VectorCopy (e->currentangles, e->previousangles);
		VectorCopy (e->angles,  e->currentangles);
	}

	//set up values
	if (r_lerpmove.value && e != &cl.viewent_gun && e->lerpflags & LERP_MOVESTEP)
	{
		if (e->lerpflags & LERP_FINISH)
			blend = CLAMP (0, (cl.ctime - e->movelerpstart) / (e->lerpfinish - e->movelerpstart), 1);
		else
			blend = CLAMP (0, (cl.ctime - e->movelerpstart) / 0.1, 1);

		//translation
		VectorSubtract (e->currentorigin, e->previousorigin, d);
		lerpdata->origin[0] = e->previousorigin[0] + d[0] * blend;
		lerpdata->origin[1] = e->previousorigin[1] + d[1] * blend;
		lerpdata->origin[2] = e->previousorigin[2] + d[2] * blend;

		//rotation
		VectorSubtract (e->currentangles, e->previousangles, d);
		for (i = 0; i < 3; i++)
		{
			if (d[i] > 180)  d[i] -= 360;
			if (d[i] < -180) d[i] += 360;
		}
		lerpdata->angles[0] = e->previousangles[0] + d[0] * blend;
		lerpdata->angles[1] = e->previousangles[1] + d[1] * blend;
		lerpdata->angles[2] = e->previousangles[2] + d[2] * blend;
	}
	else //don't lerp
	{
		VectorCopy (e->origin, lerpdata->origin);
		VectorCopy (e->angles, lerpdata->angles);
	}
#ifdef WINQUAKE_RENDERER_SUPPORT
// Baker: Software uses these fields in too many places
	VectorCopy (lerpdata->origin, e->origin);
	VectorCopy (lerpdata->angles, e->angles);
#endif // WINQUAKE_RENDERER_SUPPORT
}


/*
=================
Sky_NewMap
=================
*/
void Sky_NewMap (void)
{
	const char *sky_key = NULL;

#ifdef GLQUAKE_RENDERER_SUPPORT
	// On a new map, these pointers are invalid
	extern gltexture_t *skybox_textures[SKYBOX_SIDES_COUNT_6];
	int i;
	for (i = 0; i < SKYBOX_SIDES_COUNT_6; i++)
		skybox_textures[i] = NULL;
#endif

	//
	// initially no sky
	//

	Sky_LoadSkyBox ("");

#ifdef WINQUAKE_SOFTWARE_SKYBOX
#if defined(PLATFORM_LINUX) // ANDROID IT WORKED OK FOR ME.
	return; // Linux isn't liking fast gamma.  Is it the pointer size?
#endif // PLATFORM_LINUX
	if (!sw_sky_load_skyboxes.value)
		return; // User doesn't want it
#endif // WINQUAKE_SOFTWARE_SKYBOX

	if ((sky_key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "sky")))
		Sky_LoadSkyBox (sky_key);
	//also accept non-standard keys (Fitz 0.85)
	else if ((sky_key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "skyname"))) //half-life
		Sky_LoadSkyBox (sky_key);
	else if ((sky_key = COM_CL_Worldspawn_Value_For_Key (cl.worldmodel->entities, "q1sky"))) //quake lives
		Sky_LoadSkyBox (sky_key);
#ifdef SUPPORTS_NEHAHRA
	// Baker: Nehahra stores stuff in info_start
	else if ((sky_key = COM_CL_Value_For_Key_Find_Classname ("info_start", "sky")))
		Sky_LoadSkyBox (sky_key);
#endif // SUPPORTS_NEHAHRA

	if (sky_key) // Set the map's sky
		c_strlcpy (level.sky_key, sky_key);
	else if (cl_sky.string[0] ) // Set the user's sky (if they have one)
		Sky_LoadSkyBox (cl_sky.string);
}

/*
=================
Sky_SkyCommand_f
=================
*/
void Sky_SkyCommand_f (lparse_t *line)
{
	switch (line->count)
	{
	case 1:
		Con_PrintLinef (QUOTEDSTR("sky") " is " QUOTED_S " (gfx/env folder)", skybox_name);
		if (skybox_name[0])
			Con_PrintLinef ("to set to none type: sky " QUOTEDSTR(""));
		break;
	case 2:
		if (!cmd_from_server || cls.demoplayback)
		{
			// Server command shall not overwrite user preference
			// Nor shall a demo playing such.
			Cvar_SetQuick (&cl_sky, line->args[1]);
#ifdef WINQUAKE_SOFTWARE_SKYBOX
// Baker: Is this still needed?
			if (cl.worldmodel)
				Sky_LoadSkyBox (line->args[1]);
			else skybox_name[0] = 1; // Baker: Dirty cheat to force a refresh
			break;
#endif // WINQUAKE_SOFTWARE_SKYBOX
		}
		Sky_LoadSkyBox (line->args[1]);

		break;
	default:
		Con_PrintLinef ("usage: sky <skyname>");
	}

}

/*
=============
Sky_Init
=============
*/
void Sky_Init (void)
{
	Cmd_AddCommands (Sky_Init);
}
