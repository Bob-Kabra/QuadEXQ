/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2009-2014 Baker and others

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

#include "quakedef.h"

static void CL_FinishTimeDemo (void);



typedef struct framepos_s
{
	long				baz;
	struct framepos_s	*next;
} framepos_t;

framepos_t	*dem_framepos = NULL;
cbool	start_of_demo = false;
cbool	bumper_on = false;

/*
==============================================================================

DEMO CODE

When a demo is playing back, all NET_SendMessages are skipped, and
NET_GetMessages are read from the demo file.

Whenever cl.time gets past the last received message, another message is
read from the demo file.
==============================================================================
*/

// from ProQuake: space to fill out the demo header for record at any time
static byte	demo_head[3][MAX_MARK_V_MSGLEN];
static int		demo_head_size[2];




/*
==============
CL_StopPlayback

Called when a demo file runs out, or the user starts a game
==============
*/

void CL_StopPlayback (void)
{
	if (!cls.demoplayback)
		return;

	FS_fclose (cls.demofile);

	cls.demoplayback = false;
	cls.demofile = NULL;
	cls.state = ca_disconnected;

#ifdef BUGFIX_DEMO_RECORD_NOTHING_FIX
	SCR_EndLoadingPlaque ();
#endif // BUGFIX_DEMO_RECORD_NOTHING_FIX

#ifdef SUPPORTS_CUTSCENE_PROTECTION // Baker: Revert any cvars a demo set to the user's settings
	Cvar_Clear_Untrusted ();
#endif // SUPPORTS_CUTSCENE_PROTECTION

	// If a dz temp file demo is playing (a .dem extracted from a .dz), delete it  
	//if (cls.dz_temp_url[0])  Mar 6 2018 - Bye dzip
	//{
	//	File_Delete (cls.dz_temp_url);
	//	cls.dz_temp_url[0] = 0;
	//}

	if (cls.timedemo)
		CL_FinishTimeDemo ();

#ifdef SUPPORTS_AVI_CAPTURE
	if (cls.capturedemo)
		VID_Set_Window_Title (NULL); // Restores it to default of "engine name"

	Movie_StopPlayback ();
#endif

	if (cls.titledemo)
	{
		vid.recalc_refdef = true; // also triggers sbar refresh
		cls.titledemo = 0;
	}
}

/*
====================
CL_WriteDemoMessage

Dumps the current net message, prefixed by the length and view angles
====================
*/
static void CL_WriteDemoMessage (void)
{
	int		len;
	int		i;
	float	f;

	len = LittleLong (net_message.cursize);
	fwrite (&len, 4 /*sizeof int*/, 1, cls.demofile);

	for (i=0 ; i<3 ; i++)
	{
		f = LittleFloat (cl.viewangles[i]);
		fwrite (&f, 4 /*sizeof float*/, 1, cls.demofile);
	}

	fwrite (net_message.data, net_message.cursize, 1, cls.demofile);
	fflush (cls.demofile);
}

void PushFrameposEntry (long fbaz)
{
	framepos_t	*newf;

	newf = (framepos_t *)malloc (sizeof(framepos_t)); // Demo rewind
	newf->baz = fbaz;

	if (!dem_framepos)
	{
		newf->next = NULL;
		start_of_demo = false;
	}
	else
	{
		newf->next = dem_framepos;
	}

	dem_framepos = newf;
}


static void EraseTopEntry (void)
{
	framepos_t	*top;

	top = dem_framepos;
	dem_framepos = dem_framepos->next;
	if (top) free (top);
}


/*
====================
CL_GetMessage

Handles recording and playback of demos, on top of NET_ code
====================
*/

int CL_GetMessage (void)
{
	int		r, i;
	float	f;

	if (cl.paused & 2)
		return 0;

	if (cls.demoplayback)
	{
		if (start_of_demo && cls.demorewind)
			return 0;

		if (cls.signon < SIGNONS)	// clear stuffs if new demo
			while (dem_framepos)
				EraseTopEntry ();

	// decide if it is time to grab the next message
		if (cls.signon == SIGNONS)	// always grab until fully connected
		{
			if (cls.timedemo)
			{
				if (host_framecount == cls.td_lastframe)
					return 0;		// already read this frame's message

				cls.td_lastframe = host_framecount;

			// if this is the second frame, grab the real td_starttime
			// so the bogus time on the first frame doesn't count
				if (host_framecount == cls.td_startframe + 1)
					cls.td_starttime = realtime;
			}
			else if (!cls.demorewind && cl.ctime <= cl.mtime[0])
				return 0;		// don't need another message yet
			else if (cls.demorewind && cl.ctime >= cl.mtime[0])
				return 0;

			// joe: fill in the stack of frames' positions
			// enable on intermission or not...?
			// NOTE: it can't handle fixed intermission views!
			if (!cls.demorewind /*&& !cl.intermission*/)
				PushFrameposEntry (ftell(cls.demofile));

		}

	// get the next message
		cls.demo_offset_current = ftell(cls.demofile);
		fread (&net_message.cursize, 4, 1, cls.demofile);
		VectorCopy (cl.mviewangles[0], cl.mviewangles[1]);

		for (i=0 ; i < 3 ; i++)
		{
			r = fread (&f, 4, 1, cls.demofile);
			cl.mviewangles[0][i] = LittleFloat (f);
		}

		net_message.cursize = LittleLong (net_message.cursize);

		if (net_message.cursize > MAX_MARK_V_MSGLEN)
			Host_Error ("Demo message > MAX_MARK_V_MSGLEN");

		r = fread (net_message.data, net_message.cursize, 1, cls.demofile);

		if (r != 1)
		{
			CL_StopPlayback ();
			return 0;
		}

		// joe: get out framestack's top entry
		if (cls.demorewind /*&& !cl.intermission*/)
		{
			if (dem_framepos/* && dem_framepos->baz*/)	// Baker: in theory, if this occurs we ARE at the start of the demo with demo rewind on
			{
				fseek (cls.demofile, dem_framepos->baz, SEEK_SET);
				EraseTopEntry (); // Baker: we might be able to improve this better but not right now.
			}
			if (!dem_framepos)
				bumper_on = start_of_demo = true;
		}

		return 1;
	}

	while (1)
	{
		r = NET_GetMessage (cls.netcon);

		if (r != 1 && r != 2)
			return r;

	// discard nop keepalive message
		if (net_message.cursize == 1 && net_message.data[0] == svc_nop)
			Con_PrintLinef ("<-- server to client keepalive");
// Could have svc_download handled here to keep it out of demo file? 
		else
			break;
	}

	if (cls.demorecording)
		CL_WriteDemoMessage ();

	if (cls.signon < 2)
	{
	// record messages before full connection, so that a
	// demo record can happen after connection is done
		memcpy(demo_head[cls.signon], net_message.data, net_message.cursize);
		demo_head_size[cls.signon] = net_message.cursize;
	}

	return r;
}


// QuadEXQ: the replay (see the end of this file)
static cbool qx_replay_quiet;		// CL_Record_f / CL_Stop_f: nothing in the console

/*
====================
CL_Stop_f

stop recording a demo
====================
*/
void CL_Stop_f (lparse_t *unused)
{
	if (cmd_source != src_command)
		return;

	if (!cls.demorecording)
	{
		Con_PrintLinef ("Not recording a demo.");
		return;
	}

// write a disconnect message to the demo file
	SZ_Clear (&net_message);
	MSG_WriteByte (&net_message, svc_disconnect);
	CL_WriteDemoMessage ();

// finish up
	FS_fclose (cls.demofile);
	Recent_File_Set_FullPath (cls.demo_url); // Close demo instance #2 (record end)

	cls.demofile = NULL;
	cls.demorecording = false;
	Lists_Update_Demolist ();
	if (qx_replay_quiet || !strcmp (File_URL_SkipPath (cls.demo_url), "qx_replay.dem"))
		;	// QuadEXQ: the replay's own recording
	else if (!cls.autodemo)
		Con_PrintLinef ("Completed demo %s, type " QUOTEDSTR ("showfile") " to open folder", File_URL_SkipPath (cls.demo_url));
	else
	{
		Con_DPrintLinef ("Completed demo %s", File_URL_SkipPath (cls.demo_url) );
		cls.autodemo = false;
	}
}

void CL_Clear_Demos_Queue (void)
{
	int i;
	for (i = 0;i < MAX_DEMOS_32; i ++)	// Clear demo loop queue
		cls.demos[i][0] = 0;
	cls.demonum = -1;				// Set next demo to none
}
#pragma message ("All the demo code is ugly")
#pragma message ("All rendering code ugly")
#pragma message ("All disconnect and cls.maprunning code is ugly")

/*
====================
CL_Record_f

record <demoname> <map> [cd track]
====================
*/
void CL_Record_f (lparse_t *line)
{
	int			c;
	char		record_name_url[MAX_OSPATH];
	int			track;
	cbool	is_automatic = false;

	if (cmd_source != src_command)
		return;

	if (cls.demoplayback)
	{
		Con_PrintLinef ("Can't record during demo playback");
		return;
	}

	c = line->count;
	if (c != 2 && c != 3 && c != 4)
	{
		Con_PrintLinef ("record <demoname> [<map> [cd track]]");
		return;
	}

	if (strstr(line->args[1], ".."))
	{
		Con_PrintLinef ("Relative pathnames are not allowed.");
		return;
	}

	if (c == 2 && cls.state == ca_connected)
	{
#if 0
		Con_PrintLinef ("Can not record - already connected to server" NEWLINE "Client demo recording must be started before connecting");
		return;
#endif
		if (cls.signon < 2)
		{
			Con_PrintLinef ("Can't record - try again when connected");
			return;
		}
	}

	if (cls.demorecording)
		CL_Stop_f(NULL);

// write the forced cd track number, or -1
	if (c == 4)
	{
		track = atoi(line->args[3]);
		Con_PrintLinef ("Forcing CD track to %d", cls.forcetrack);
	}
	else
	{
		track = -1;
	}

	if (!strcmp(AUTO_DEMO_NAME, line->args[1])  )
	{
		// Automatic demo
		char autodemo2_url[MAX_OSPATH];
		char autodemo1_url[MAX_OSPATH];
		char autodemo0_url[MAX_OSPATH];
		int checkit;

		FS_FullPath_From_QPath (autodemo2_url, "auto_demo_2.dem");
		FS_FullPath_From_QPath (autodemo1_url, "auto_demo_1.dem");
		FS_FullPath_From_QPath (autodemo0_url, "auto_demo_0.dem");

		if (File_Exists (autodemo2_url))
			checkit = File_Delete (autodemo2_url);
		if (File_Exists (autodemo1_url))
			checkit = File_Rename (autodemo1_url, autodemo2_url);
		if (File_Exists (autodemo0_url))
			checkit = File_Rename (autodemo0_url, autodemo1_url);

		c_strlcpy (record_name_url, autodemo0_url);

		cls.autodemo = is_automatic = true;
	}
	else FS_FullPath_From_QPath (record_name_url, line->args[1]);

	CL_Clear_Demos_Queue (); // timedemo is a very intentional action

// start the map up

	if (c > 2)
	{
		Cmd_ExecuteString ( va("map %s", line->args[2]), src_command);
		if (cls.state != ca_connected)
			return;
	}

// open the demo file
	File_URL_Edit_Force_Extension (record_name_url, ".dem", sizeof(record_name_url));

	if (!is_automatic && !qx_replay_quiet)	// QuadEXQ: not for the replay's own
		Con_PrintLinef ("recording to %s", record_name_url);
	else Con_DPrintLinef ("recording to %s", record_name_url);

	cls.demofile = FS_fopen_write (record_name_url, "wb");
	if (!cls.demofile)
	{
		Con_PrintLinef ("ERROR: couldn't create %s", File_URL_SkipPath(record_name_url));
		return;
	}

	// Officially recording ... copy the name for reference
	c_strlcpy (cls.demo_url, record_name_url);

	cls.forcetrack = track;
	fprintf (cls.demofile, "%d\n", cls.forcetrack);

	cls.demorecording = true;

	// from ProQuake: initialize the demo file if we're already connected
	if (c == 2 && cls.state == ca_connected)
	{
		byte *data = net_message.data;
		int cursize = net_message.cursize;
		int i;

		for (i = 0 ; i < 2 ; i++)
		{
			net_message.data = demo_head[i];
			net_message.cursize = demo_head_size[i];
			CL_WriteDemoMessage();
		}

		net_message.data = demo_head[2];
		SZ_Clear (&net_message);

		// current names, colors, and frag counts
		for (i=0 ; i < cl.maxclients ; i++)
		{
			MSG_WriteByte (&net_message, svc_updatename);
			MSG_WriteByte (&net_message, i);
			MSG_WriteString (&net_message, cl.scores[i].name);
			MSG_WriteByte (&net_message, svc_updatefrags);
			MSG_WriteByte (&net_message, i);
			MSG_WriteShort (&net_message, cl.scores[i].frags);
			MSG_WriteByte (&net_message, svc_updatecolors);
			MSG_WriteByte (&net_message, i);
			MSG_WriteByte (&net_message, cl.scores[i].colors);
		}

		// send all current light styles
		for (i = 0 ; i < MAX_LIGHTSTYLES ; i++)
		{
			MSG_WriteByte (&net_message, svc_lightstyle);
			MSG_WriteByte (&net_message, i);
			MSG_WriteString (&net_message, cl.lightstyle[i].map);
		}

		// what about the CD track or SVC fog... future consideration.
		MSG_WriteByte (&net_message, svc_updatestat);
		MSG_WriteByte (&net_message, STAT_TOTALSECRETS);
		MSG_WriteLong (&net_message, cl.stats[STAT_TOTALSECRETS]);

		MSG_WriteByte (&net_message, svc_updatestat);
		MSG_WriteByte (&net_message, STAT_TOTALMONSTERS);
		MSG_WriteLong (&net_message, cl.stats[STAT_TOTALMONSTERS]);

		MSG_WriteByte (&net_message, svc_updatestat);
		MSG_WriteByte (&net_message, STAT_SECRETS);
		MSG_WriteLong (&net_message, cl.stats[STAT_SECRETS]);

		MSG_WriteByte (&net_message, svc_updatestat);
		MSG_WriteByte (&net_message, STAT_MONSTERS);
		MSG_WriteLong (&net_message, cl.stats[STAT_MONSTERS]);

		// view entity
		MSG_WriteByte (&net_message, svc_setview);
		MSG_WriteShort (&net_message, cl.viewentity_player);

		// signon
		MSG_WriteByte (&net_message, svc_signonnum);
		MSG_WriteByte (&net_message, 3);

		CL_WriteDemoMessage();

		// restore net_message
		net_message.data = data;
		net_message.cursize = cursize;
	}
}


/*
====================
CL_PlayDemo_f

play [demoname]
====================
*/



// Baker: So we know this is a real start demo
cbool play_as_start_demo = false;
void CL_PlayDemo_NextStartDemo_f (lparse_t *line)
{
	play_as_start_demo = true;
	CL_PlayDemo_f (line); // Inherits the cmd_argc and cmd_argv
	play_as_start_demo = false;
}

// cls.demofile is already opened, just pass us the name
void CL_PlayDemo_Opened (const char *in_demo_name_url)
{
	int c;
	cbool neg = false;

	c_strlcpy (cls.demo_url, in_demo_name_url);

	// Revert
	cls.demorewind = false;
	cls.demospeed = 0; // 0 = Don't use
	bumper_on = false;

	cls.demo_offset_start = ftell (cls.demofile);	// qfs_lastload.offset instead?
	cls.demo_file_length = com_filesize;
	cls.demo_hosttime_start	= cls.demo_hosttime_elapsed = 0; // Fill this in ... host_time;
	cls.demo_cltime_start = cls.demo_cltime_elapsed = 0; // Fill this in

	// Title demos get no HUD, no crosshair, no con_notify, FOV 90, viewsize 120
	if (COM_ListMatch (cl_titledemos_list.string, cls.demo_url))
	{
		vid.recalc_refdef = true;
		cls.titledemo = true;
	}

	if (!play_as_start_demo)
	{
		CL_Clear_Demos_Queue ();
		SCR_BeginLoadingPlaque_Force_NoTransition ();
		Key_SetDest (key_game);
		console1.visible_pct = 0;
	}

	cls.demoplayback = true;
	cls.state = ca_connected;
	cls.forcetrack = 0;

	// QuadEXQ: only digits count. Scourge of Armagon's demo1 starts " 2"
	// (a space before the track): the space was read as a digit, -16, and
	// forced track 98, which isn't there -- no music. ("\r\n" line ends did
	// the same.) QuakeSpasm / vkQuake read it this way too.
	while ((c = getc(cls.demofile)) != '\n' && c != EOF)
		if (c == '-')
			neg = true;
		else if (c >= '0' && c <= '9')
			cls.forcetrack = cls.forcetrack * 10 + (c - '0');

	if (neg)
		cls.forcetrack = -cls.forcetrack;
// ZOID, fscanf is evil
//	fscanf (cls.demofile, "%d\n", &cls.forcetrack);

}


#if 0 // RIP DZDEMOS  ... #ifndef SERVER_ONLY
void CL_PlayDZDemo (const char *dz_quake_folder_url)
{
	extern int dzip_runner(int argc, char **argv);
	
	char safedir_dem_url[MAX_OSPATH];	// c:\Users\ ....\Roaming\...\mydem.dem
	struct arg_buckets_64_s argbuckets_dz = {0};
	int expected_dem_exists;
	//cls.dz_handle = System_Process_Create (PATH_TO_DZIP, cmdline, com_safedir);    
	
	cls.dz_temp_url[0] = 0;

	// check if the file exists
	if (!File_Exists(dz_quake_folder_url))
	{
		Con_PrintLinef ("ERROR: couldn't open %s", File_URL_SkipPath(dz_quake_folder_url));
		return;
	}

	// 2. Construct the safedir url
	c_snprintf2 (safedir_dem_url, "%s/%s", com_safedir, File_URL_SkipPath(dz_quake_folder_url));
	File_URL_Edit_Change_Extension (safedir_dem_url, ".dem", sizeof(safedir_dem_url));

	// 4.  If we are here, we have work to do.
	Con_PrintLinef ("\x02" "\nunpacking demo. please wait..." NEWLINE);
	
	FS_SafeDirClean (); // Remove anything in our safe dir
	File_Chdir (com_safedir); // Change directory to our safe directory.
	c_snprintf1 (argbuckets_dz.cmdline, "anything -x -f " QUOTED_S, dz_quake_folder_url);
	String_To_Arg_Buckets (&argbuckets_dz, argbuckets_dz.cmdline);
	dzip_runner (argbuckets_dz.argcount, argbuckets_dz.argvs);

	// 5. Ran DZip now see if we got the expected file.
	expected_dem_exists = File_Exists(safedir_dem_url);
	cls.demofile = expected_dem_exists ? FS_fopen_read(safedir_dem_url, "rb") : NULL;

	if (!cls.demofile)
	{
		const char *msg_no_exist = "File " QUOTED_S " was not able to be extracted from archive";
		const char *msg_exists_couldnt_play  = "ERROR: couldn't open " QUOTED_S;
		const char *msg = expected_dem_exists ? msg_exists_couldnt_play : msg_no_exist;
		Con_PrintLinef (msg, File_URL_SkipPath(safedir_dem_url));
		cls.demonum = -1;
		FS_SafeDirClean (); // We are done with the safedir temps
		return; // Get out, right?
	}
		
	// start playback
	cls.demoplayback = true;
	com_filesize = File_Length(safedir_dem_url); // Outside the file system!!
	CL_PlayDemo_Opened (safedir_dem_url);
	c_strlcpy (cls.dz_temp_url, safedir_dem_url); // old-->new  ... Rename is a move
}
#endif // #if 0 // RIP DZDEMOS !SERVER_ONLY


void CL_PlayDemo_f (lparse_t *line)
{
	char	playdemo_name_qpath[MAX_QPATH_64];
	char	playdemo_name_url[MAX_OSPATH];

	if (cmd_source != src_command)
		return;

	if (line->count != 2)
	{
		Con_PrintLinef ("playdemo <demoname> : plays a demo");
		return;
	}

// disconnect from server
	CL_Disconnect ();

// open the demo file
	FS_FullPath_From_QPath (playdemo_name_url, line->args[1]);

#if 0 // RIP DZDEMOS #ifndef SERVER_ONLY
	// If a dzipped demo ending in .dz handling playing differently
	if (String_Does_End_With (playdemo_name_url, ".dz"))
	{
		CL_PlayDZDemo (playdemo_name_url);
		return;
	}
#endif // #if 0 // RIP DZDEMOS SERVER_ONLY
	
	c_strlcpy (playdemo_name_qpath, line->args[1]);
	File_URL_Edit_Force_Extension (playdemo_name_qpath, ".dem", sizeof(playdemo_name_qpath));
	Con_PrintLinef ("Playing demo from %s.", playdemo_name_qpath);

	COM_FOpenFile (playdemo_name_qpath, &cls.demofile);
	if (!cls.demofile)
	{
		Con_PrintLinef ("ERROR: couldn't open %s", playdemo_name_qpath);
		cls.demonum = -1;		// stop demo loop
		return;
	}

	CL_PlayDemo_Opened (playdemo_name_qpath);
}

/*
====================
CL_FinishTimeDemo

====================
*/
static void CL_FinishTimeDemo (void)
{
	int		frames;
	float	time;

	cls.timedemo = false;

// the first frame didn't count
	frames = (host_framecount - cls.td_startframe) - 1;
	time = realtime - cls.td_starttime;

	if (!time)
		time = 1;

	Con_PrintLinef ("%d frames %5.1f seconds %5.1f fps", frames, time, frames/time);
}

/*
====================
CL_TimeDemo_f

timedemo [demoname]
====================
*/
void CL_TimeDemo_f (lparse_t *line)
{
	if (cmd_source != src_command)
		return;

	if (line->count != 2)
	{
		Con_PrintLinef ("timedemo <demoname> : gets demo speeds");
		return;
	}


	CL_Clear_Demos_Queue (); // timedemo is a very intentional action

	CL_PlayDemo_f (line);

	// don't trigger timedemo mode if playdemo fails
	if (!cls.demofile)
		return;

// cls.td_starttime will be grabbed at the second frame of the demo, so
// all the loading time doesn't get counted

	cls.timedemo = true;
	cls.td_startframe = host_framecount;
	cls.td_lastframe = -1;		// get a new message this frame

	// Baker: This is a performance benchmark.  No reason to have console up.
	SCR_BeginLoadingPlaque_Force_NoTransition ();
	Key_SetDest (key_game);
	console1.visible_pct = 0;
}


/*
==============================================================================

QuadEXQ: THE REPLAY

QuadEXQ (the quadexq folder, or progs that say they are QuadEXQ), once it's
unlocked; in another game, if the player turns it on there (qx_replay_mods,
Options > QuadEXQ Settings, kept per game) -- the engine then times each
clear itself for the fastest one. All its files go in the game's demos folder.

Every map is recorded to qx_replay.dem from the moment you are in (a
checkpoint or a load starts it over, so it holds the last try). When the
map ends in an intermission, JUMP there means "show me": the next map is
saved the moment it is in (qx_replay_resume.sav), the replay plays, and the
game goes on from that save. FIRE skips the replay.

The replay runs at the game's real pace: bullet time (STAT_QX_TIME, the
world's timescale x100) is played back sped up by as much as it slowed the
world, so the whole map goes by as fast as it was really fought.
qx_replay 0 turns it all off.

Any demo (playdemo too) plays bullet time at that real pace; hold SHIFT to
see it slow, as it was played. A MAP BEST saves the replay by itself as
QX_<game>_<map>_0000.dem (and qx_best_<map>.dem, the map's best), and
qx_replay_save keeps one any time it isn't being recorded.

The ghost: alongside the recording, where the player is goes into a small
track of its own (qx_replay.ghost, 20 a second); the map's fastest clear
(FASTEST CLEAR on the map report) keeps it as qx_fast_<map>.ghost, with
the replay as qx_fast_<map>.dem, and next time on that map the fastest run
plays along as a see-through player, by the map's clock (qx_ghost 0 hides it).

==============================================================================
*/

#define QX_DEMO_DIR			"demos"					// the replays, map bests and ghosts go in here
#define QX_REPLAY_NAME		QX_DEMO_DIR "/qx_replay"
#define QX_REPLAY_RESUME	"qx_replay_resume"

static cbool	qx_replay_recording;	// this map is going into qx_replay.dem
static cbool	qx_replay_ready;		// it holds a map that ended in an intermission
static cbool	qx_replay_wanted;		// JUMP at that intermission
static int		qx_replay_playing;		// 1 = asked to play, 2 = playing
static cbool	qx_replay_resuming;		// loading qx_replay_resume after it
static double	qx_replay_started;
static float	qx_replay_chase;		// chase_active before it (JUMP switches the camera in it)
static cbool	qx_replay_jump_held;
static char		qx_replay_map[MAX_QPATH_64];	// the map in it
static cbool	qx_replay_cheated;		// cheats on that map: watch it, keep nothing (SV_QX_Cheated)
static cbool	qx_replay_quadexq;		// .. and QuadEXQ's (else another game, qx_replay_mods on)
static cbool	qx_replay_mapbest;		// the map report says MAP BEST
static cbool	qx_replay_fastest;		// .. or FASTEST CLEAR
static cbool	qx_replay_best_saved, qx_replay_fast_saved, qx_replay_numbered;	// .. and they have been kept
static cbool	qx_pace_set;			// QX_Replay_Frame set cls.demospeed for bullet time
extern cbool	keydown[];

// The ghost track
typedef struct
{
	float	time;		// cl.time
	float	origin[3];
	float	angles[3];
	int		frame;
} qx_ghost_t;

#define QX_GHOST_MAX		(20 * 60 * 30)	// 30 minutes at 20 a second
#define QX_GHOST_STEP		0.05
static qx_ghost_t	*qx_ghost_rec;			// this try, as it goes
static int			qx_ghost_rec_count;
static qx_ghost_t	*qx_ghost_best;			// the map's best, playing along
static int			qx_ghost_best_count, qx_ghost_cursor;

static void QX_Ghost_Write (const char *name)
{
	char url[MAX_OSPATH];
	FILE *f;

	FS_FullPath_From_QPath (url, name);
	if (!qx_ghost_rec || !qx_ghost_rec_count || !(f = fopen (url, "wb")))
		return;
	fwrite ("QXG1", 1, 4, f);
	fwrite (&qx_ghost_rec_count, sizeof(int), 1, f);
	fwrite (qx_ghost_rec, sizeof(qx_ghost_t), qx_ghost_rec_count, f);
	fclose (f);
}

// Signon: this map's best run, if there is one
static void QX_Ghost_Load (const char *map)
{
	char name[MAX_QPATH_64], url[MAX_OSPATH], magic[4];
	int count = 0;
	FILE *f;

	qx_ghost_best_count = qx_ghost_cursor = 0;
	if (!qx_ghost.value || !map[0])
		return;
	c_snprintf1 (name, QX_DEMO_DIR "/qx_fast_%s.ghost", map);	// the fastest you
	FS_FullPath_From_QPath (url, name);
	if (!(f = fopen (url, "rb")))
	{
		c_snprintf1 (name, QX_DEMO_DIR "/qx_best_%s.ghost", map);	// (from before there were fastest clears)
		FS_FullPath_From_QPath (url, name);
		if (!(f = fopen (url, "rb")))
			return;
	}
	if (fread (magic, 1, 4, f) == 4 && !memcmp (magic, "QXG1", 4)
		&& fread (&count, sizeof(int), 1, f) == 1 && count > 0 && count <= QX_GHOST_MAX)
	{
		if (!qx_ghost_best)
			qx_ghost_best = (qx_ghost_t *) malloc (QX_GHOST_MAX * sizeof(qx_ghost_t));
		if (qx_ghost_best)
			qx_ghost_best_count = (int)fread (qx_ghost_best, sizeof(qx_ghost_t), count, f);
	}
	fclose (f);
}

static float QX_LerpAngle (float a, float b, float f)
{
	float d = b - a;
	while (d > 180) d -= 360;
	while (d < -180) d += 360;
	return a + d * f;
}

// CL_UpdateTEnts, every frame: keep the track, and show the best run
void QX_Ghost_Frame (entity_t *(*new_ent)(void))
{
	entity_t	*me, *ent;
	qx_ghost_t	*a, *b;
	float		f;
	int			i;

	if (cls.demoplayback || cls.state != ca_connected || cls.signon != SIGNONS || cl.intermission)
		return;
	me = &cl_entities[cl.viewentity_player];

	// the track of this try
	if (qx_replay_recording && me->model)
	{
		if (!qx_ghost_rec)
			qx_ghost_rec = (qx_ghost_t *) malloc (QX_GHOST_MAX * sizeof(qx_ghost_t));
		if (qx_ghost_rec && qx_ghost_rec_count < QX_GHOST_MAX
			&& (!qx_ghost_rec_count || cl.time >= qx_ghost_rec[qx_ghost_rec_count - 1].time + QX_GHOST_STEP))
		{
			qx_ghost_t *g = &qx_ghost_rec[qx_ghost_rec_count++];
			g->time = cl.time;
			VectorCopy (me->origin, g->origin);
			VectorCopy (me->angles, g->angles);
			g->frame = me->frame;
		}
	}

	// the best run, along with you
	if (!qx_ghost.value || qx_ghost_best_count < 2 || !me->model)
		return;
	if (cl.time < qx_ghost_best[0].time || cl.time > qx_ghost_best[qx_ghost_best_count - 1].time)
		return;
	if (qx_ghost_cursor >= qx_ghost_best_count - 1 || qx_ghost_best[qx_ghost_cursor].time > cl.time)
		qx_ghost_cursor = 0;	// time went back (a load): from the start
	while (qx_ghost_cursor < qx_ghost_best_count - 2 && qx_ghost_best[qx_ghost_cursor + 1].time <= cl.time)
		qx_ghost_cursor++;
	a = &qx_ghost_best[qx_ghost_cursor];
	b = a + 1;
	f = b->time > a->time ? (cl.time - a->time) / (b->time - a->time) : 0;
	f = CLAMP (0, f, 1);

	if (!(ent = new_ent ()))
		return;
	for (i = 0; i < 3; i++)
	{
		ent->origin[i] = a->origin[i] + (b->origin[i] - a->origin[i]) * f;
		ent->angles[i] = QX_LerpAngle (a->angles[i], b->angles[i], f);
	}
	ent->model = me->model;
	ent->frame = f < 0.5 ? a->frame : b->frame;
	ent->alpha = ENTALPHA_ENCODE (0.35f);
	ent->lerpflags = LERP_RESETANIM | LERP_RESETMOVE;
}

// The replay, the ghost and the title demos are QuadEXQ's, and they are
// unlocked by beating the game once: Shub-Niggurath down (the progs set
// qx_unlocked then), or a save that already has the QUAD! achievement
// (THE ENDER finished, which only comes after her).
static cbool QX_Replay_Unlocked (void)
{
	return qx_unlocked.value || ((int)qx_ach.value & 4096 /* QX_ACH_QUAD */);
}

static cbool QX_Replay_IsQuadEXQ (void)
{
	return String_Does_Match_Caseless (gamedir_shortname (), "quadexq") || (cl.stats[STAT_QX_FLAGS] & QX_F_ACTIVE);
}

// startdemos (the title screen's demo loop): your newest map bests come
// first -- qx_titledemos of them, the newest first -- then the game's own.
// Returns the new number of demos in cls.demos.
int QX_TitleDemos (int count)
{
	char	names[8][MAX_DEMONAME_64];
	double	times[8];
	int		n = 0, i, j, want = CLAMP (0, (int)qx_titledemos.value, 8);
	DIR		*dir_p;
	struct dirent *dir_t;

	char	dir_url[MAX_OSPATH];

	FS_FullPath_From_QPath (dir_url, QX_DEMO_DIR);
	if (!want || !QX_Replay_Unlocked () || !QX_Replay_IsQuadEXQ () || !(dir_p = opendir (dir_url)))
		return count;
	while ((dir_t = readdir (dir_p)) != NULL)
	{
		char url[MAX_OSPATH], name[MAX_DEMONAME_64];
		size_t len = strlen (dir_t->d_name);
		double t;

		if (len < 13 || len + sizeof(QX_DEMO_DIR) >= sizeof(name) || !String_Does_Start_With_Caseless (dir_t->d_name, "qx_best_")
			|| !String_Does_End_With_Caseless (dir_t->d_name, ".dem"))
			continue;
		c_snprintf2 (url, "%s/%s", dir_url, dir_t->d_name);
		t = File_Time (url);
		c_snprintf1 (name, QX_DEMO_DIR "/%s", dir_t->d_name);
		name[strlen (name) - 4] = 0;	// playdemo takes it without .dem

		// keep the newest 'want', newest first
		for (i = 0; i < n && times[i] >= t; i++)
			;
		if (i >= want)
			continue;
		for (j = c_min (n, want - 1); j > i; j--)
		{
			times[j] = times[j - 1];
			c_strlcpy (names[j], names[j - 1]);
		}
		times[i] = t;
		c_strlcpy (names[i], name);
		if (n < want)
			n++;
	}
	closedir (dir_p);

	if (!n)
		return count;
	count = c_min (count, MAX_DEMOS_32 - n);	// the game's own, after them
	for (i = count - 1; i >= 0; i--)
		c_strlcpy (cls.demos[i + n], cls.demos[i]);
	for (i = 0; i < n; i++)
		c_strlcpy (cls.demos[i], names[i]);
	Con_DPrintLinef ("Title demos: %d map best(s) first", n);
	return count + n;
}

// host.c: bullet time sped back up in a title-screen demo too
cbool QX_Demo_Paced (void)
{
	return qx_pace_set;
}

// Keeps a copy of qx_replay.dem: QX_<game>_<map>_0000.dem (the first free
// number), or the given name
static cbool QX_Replay_Copy (const char *to_name)
{
	char from_url[MAX_OSPATH], to_url[MAX_OSPATH], name[MAX_QPATH_64];
	int i;

	FS_FullPath_From_QPath (from_url, QX_REPLAY_NAME ".dem");
	if (!File_Exists (from_url))
	{
		Con_PrintLinef ("No replay to save");
		return false;
	}

	if (to_name)
		c_strlcpy (name, to_name);
	else for (i = 0; ; i++)
	{
		if (i == 10000)
		{
			Con_PrintLinef ("Replay: couldn't find an unused file name");
			return false;
		}
		c_snprintf3 (name, QX_DEMO_DIR "/QX_%s_%s_%04d.dem", gamedir_shortname (), qx_replay_map[0] ? qx_replay_map : "map", i);
		FS_FullPath_From_QPath (to_url, name);
		if (!File_Exists (to_url))
			break;
	}

	FS_FullPath_From_QPath (to_url, name);
	if (!File_Copy (from_url, to_url))
	{
		Con_PrintLinef ("Replay: couldn't write %s", name);
		return false;
	}
	if (!to_name)
		Con_PrintLinef ("Replay saved as %s", name);
	return true;
}

// A record, once the map's recording is complete: keep it -- one numbered
// copy (QX_<game>_<map>_0000.dem), and the map's best score
// (qx_best_<map>.dem, for the title screen) and fastest clear
// (qx_fast_<map>.dem, and its ghost)
static void QX_Replay_SaveBest (void)
{
	char name[MAX_QPATH_64];

	if (!qx_replay_ready || qx_replay_cheated)
		return;
	if ((qx_replay_mapbest && !qx_replay_best_saved) || (qx_replay_fastest && !qx_replay_fast_saved))
	if (!qx_replay_numbered)
	{
		qx_replay_numbered = true;
		QX_Replay_Copy (NULL);
	}
	if (qx_replay_mapbest && !qx_replay_best_saved)
	{
		qx_replay_best_saved = true;
		c_snprintf1 (name, QX_DEMO_DIR "/qx_best_%s.dem", qx_replay_map);
		QX_Replay_Copy (name);
	}
	if (qx_replay_fastest && !qx_replay_fast_saved)
	{
		qx_replay_fast_saved = true;
		c_snprintf1 (name, QX_DEMO_DIR "/qx_fast_%s.dem", qx_replay_map);
		QX_Replay_Copy (name);
		c_snprintf1 (name, QX_DEMO_DIR "/qx_fast_%s.ghost", qx_replay_map);
		QX_Ghost_Write (name);	// the ghost is the fastest you
	}
}

// Sbar_QX_StatCard_f: the map report's gold line has MAP BEST in it ..
void QX_Replay_MapBest (void)
{
	qx_replay_mapbest = true;
	QX_Replay_SaveBest ();	// if the intermission came first
}

// .. or FASTEST CLEAR
void QX_Replay_Fastest (void)
{
	qx_replay_fastest = true;
	QX_Replay_SaveBest ();
}

// qx_replay_save: keep the replay (once the map is over, or while it plays)
void QX_Replay_Save_f (lparse_t *unused)
{
	if (qx_replay_recording && cls.demorecording)
	{
		Con_PrintLinef ("The map is still being recorded: save it at the intermission or in the replay");
		return;
	}
	QX_Replay_Copy (NULL);
}

// Stops it, also in the middle of reading a server message (signon 4, the
// intermission): CL_Stop_f writes its svc_disconnect into net_message, which
// would wreck the message being read, so it gets a buffer of its own for that.
static void QX_Replay_StopRecording (void)
{
	static byte	scratch[16];
	sizebuf_t	saved = net_message;

	if (!qx_replay_recording)
		return;
	qx_replay_recording = false;
	if (!cls.demorecording)
		return;

	net_message.data = scratch;
	net_message.maxsize = sizeof(scratch);
	net_message.cursize = 0;
	qx_replay_quiet = true;
	Cmd_ExecuteString ("stop", src_command);
	qx_replay_quiet = false;
	net_message = saved;
}

// CL_SignonReply, signon 4: fully in a map (a new one, a load, a checkpoint)
void QX_Replay_Signon (void)
{
	char resume_url[MAX_OSPATH];

	if (cls.demoplayback)
		return;

	if (qx_replay_resuming)
	{	// back from the replay
		qx_replay_resuming = false;
		if (key_dest == key_console)
			Key_SetDest (key_game);	// the demo's end left the console up
	}

	if (!sv.active || svs.maxclients_internal != 1)	// single player only
	{
		qx_replay_wanted = qx_replay_ready = false;
		return;
	}

	if (qx_replay_wanted && qx_replay_ready)
	{	// the last map's replay, before this one starts: save this map as it is now ..
		qx_replay_wanted = qx_replay_ready = false;
		QX_Replay_StopRecording ();
		Cmd_ExecuteString ("save " QX_REPLAY_RESUME, src_command);
		FS_FullPath_From_QPath (resume_url, QX_REPLAY_RESUME ".sav");
		if (File_Exists (resume_url))
		{	// .. play the replay (not in the middle of this message: after it), then load it back
			CL_Clear_Demos_Queue ();
			qx_replay_playing = 1;
			qx_replay_started = realtime;
			Cbuf_AddTextLine ("playdemo " QX_REPLAY_NAME);
			return;
		}
		Con_PrintLinef ("Replay: couldn't save the game, so no replay");
	}
	qx_replay_wanted = qx_replay_ready = false;

	// QuadEXQ only (the progs say so, or it's the quadexq folder: the stats may not be in yet),
	// once it's unlocked
	// .. or any other game where the player has turned it on (qx_replay_mods, kept per game)
	qx_replay_quadexq = QX_Replay_IsQuadEXQ ();
	if (!qx_replay.value || (qx_replay_quadexq ? !QX_Replay_Unlocked () : !qx_replay_mods.value))
	{
		QX_Replay_StopRecording ();
		return;
	}
	if (cls.demorecording && !qx_replay_recording)
		return;		// a demo of the player's own (record, cl_autodemo): leave it be

	QX_Replay_StopRecording ();	// first, safely (record would stop it right into net_message)
	{
		char dir_url[MAX_OSPATH];
		FS_FullPath_From_QPath (dir_url, QX_DEMO_DIR);
		File_Mkdir (dir_url);	// the first time (already there: nothing happens)
	}
	qx_replay_quiet = true;
	Cmd_ExecuteString ("record " QX_REPLAY_NAME, src_command);	// (puts its own buffer in net_message, and back)
	qx_replay_quiet = false;
	qx_replay_recording = cls.demorecording;
	c_strlcpy (qx_replay_map, cl.worldname);
	qx_replay_mapbest = qx_replay_best_saved = false;
	qx_replay_fastest = qx_replay_fast_saved = qx_replay_numbered = qx_replay_cheated = false;
	qx_ghost_rec_count = 0;			// the ghost track starts over with it
	QX_Ghost_Load (qx_replay_map);	// and the map's best plays along
}

// Another game (no QuadEXQ map report): the engine keeps each map's fastest
// clear itself, in demos/qx_times.txt ("<map> <tenths of a second>"), by the
// time the intermission shows -- Quake's own "Time", the speedrunners' too.
static void QX_Replay_FastestHere (void)
{
	char	url[MAX_OSPATH], names[256][MAX_QPATH_64], name[MAX_QPATH_64];
	int		tenths[256], n = 0, i, t, now = (int)(cl.completed_time * 10 + 0.5);
	FILE	*f;

	if (now <= 0 || !qx_replay_map[0])
		return;
	FS_FullPath_From_QPath (url, QX_DEMO_DIR "/qx_times.txt");
	if ((f = fopen (url, "r")))
	{
		while (n < 256 && fscanf (f, "%63s %d", name, &t) == 2)
		{
			c_strlcpy (names[n], name);
			tenths[n++] = t;
		}
		fclose (f);
	}
	for (i = 0; i < n; i++)
		if (!strcasecmp (names[i], qx_replay_map))
			break;
	if (i < n && tenths[i] <= now)
		return;		// not faster
	if (i < n)
		Con_PrintLinef ("FASTEST CLEAR!  %d:%02d  (was %d:%02d)", now / 600, (now / 10) % 60, tenths[i] / 600, (tenths[i] / 10) % 60);
	else if (n < 256)
	{
		Con_PrintLinef ("FASTEST CLEAR!  %d:%02d", now / 600, (now / 10) % 60);
		c_strlcpy (names[n], qx_replay_map);
		n++;
	}
	else return;
	tenths[i] = now;

	if ((f = fopen (url, "w")))
	{
		for (i = 0; i < n; i++)
			fprintf (f, "%s %d\n", names[i], tenths[i]);
		fclose (f);
	}
	qx_replay_fastest = true;	// keep the replay and its ghost
}

// svc_intermission, svc_finale, svc_cutscene
void QX_Replay_Intermission (void)
{
	if (cls.demoplayback || !qx_replay_recording)
		return;
	QX_Replay_StopRecording ();
	qx_replay_ready = true;
	qx_replay_cheated = SV_QX_Cheated ();
	QX_Ghost_Write (QX_DEMO_DIR "/qx_replay.ghost");
	if (!qx_replay_quadexq && !qx_replay_cheated)
		QX_Replay_FastestHere ();	// another game: the engine keeps the times
	QX_Replay_SaveBest ();	// if the map report came first
}

// CL_SendMove, at an intermission: the last of JUMP / FIRE pressed decides
void QX_Replay_Buttons (int bits)
{
	if (!qx_replay_ready || cl.intermission != 1)
		return;
	if (bits & 2)
		qx_replay_wanted = true;
	else if (bits & 1)
		qx_replay_wanted = false;
}

// Every frame, before the frame time is worked out
void QX_Replay_Frame (void)
{
	// Any demo, the title screen's too: bullet time at the real pace (SHIFT held: slow, as it was played)
	if (cls.demoplayback && !cls.timedemo)
	{
		int t = cl.stats[STAT_QX_TIME];

		if (t > 0 && t < 100)
		{
			cls.demospeed = (keydown[K_LSHIFT] || keydown[K_RSHIFT]) ? 1.0f : 100.0f / t;
			qx_pace_set = true;
		}
		else if (qx_pace_set || qx_replay_playing)
		{
			cls.demospeed = qx_replay_playing ? 1.0f : 0;	// the replay: never host_timescale
			qx_pace_set = false;
		}
	}
	else if (qx_pace_set)
	{
		cls.demospeed = 0;
		qx_pace_set = false;
	}

	if (!qx_replay_playing)
		return;

	if (cls.demoplayback)
	{
		if (qx_replay_playing == 1)
		{	// it has just begun
			qx_replay_playing = 2;
			qx_replay_chase = chase_active.value;
			qx_replay_jump_held = true;		// not the JUMP that asked for it
		}
		if (!(in_jump.state & 1))
			qx_replay_jump_held = false;
		else if (!qx_replay_jump_held && key_dest == key_game)
		{	// JUMP: first person <-> third person
			qx_replay_jump_held = true;
			Cvar_SetValueQuick (&chase_active, chase_active.value ? 0 : 1);
		}
		if ((in_attack.state & 1) && key_dest == key_game && realtime > qx_replay_started + 1)
			Cbuf_AddTextLine ("stopdemo");	// FIRE: skip it
		return;
	}

	if (qx_replay_playing == 1 && realtime < qx_replay_started + 3)
		return;		// playdemo hasn't run yet

	// over (or it never started): back to the game, unless something else has begun
	if (qx_replay_playing == 2)
		Cvar_SetValueQuick (&chase_active, qx_replay_chase);	// the camera as it was
	qx_replay_playing = 0;
	cls.demospeed = 0;
	if (cls.state == ca_disconnected && !sv.active)
	{
		qx_replay_resuming = true;
		Cbuf_AddTextLine ("load " QX_REPLAY_RESUME);
	}
}

// The prompt at the intermission, and the label while it plays (SCR_UpdateScreen)
void QX_Replay_Draw (void)
{
	const char *s = NULL, *s2 = NULL;

	if (qx_replay_playing && cls.demoplayback)
	{
		s2 = (qx_pace_set && cls.demospeed == 1.0f) ? "REPLAY (SLOW, AS PLAYED)" : "REPLAY (REAL SPEED)";
		s = "SHIFT: slow  JUMP: camera  FIRE: skip";
	}
	else if (qx_pace_set && cls.demoplayback)	// a saved one, in bullet time
	{
		s2 = cls.demospeed == 1.0f ? "SLOW, AS PLAYED" : "REAL SPEED";
		s = "SHIFT: slow";
	}
	else if (cl.intermission == 1 && qx_replay_ready && !cls.demoplayback)
	{
		s2 = qx_replay_cheated ? "CHEATS USED - NO RECORD" : qx_replay_quadexq ? "ARE YOU READY TO LAUGH?" : NULL;	// (QuadEXQ's joke only)
		s = qx_replay_wanted ? "REPLAY NEXT  -  FIRE: no replay" : "JUMP: watch the replay";
	}

	if (!s)
		return;
	// The menu canvas is 320x200 and the map card fills it from y 24 down: so on top
	Draw_SetCanvas (CANVAS_MENU);
	if (s2)
		Draw_String ((320 - (int)strlen (s2) * 8) / 2, 2, s2);
	Draw_String ((320 - (int)strlen (s) * 8) / 2, s2 ? 12 : 2, s);
}
