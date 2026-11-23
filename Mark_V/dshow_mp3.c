/*
Copyright (C) 1996-1997 Id Software, Inc.
Copyright (C) 2009-2014 Baker and others

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

/*
================================================================================================================================

DIRECTSHOW INTERFACE

This runs supplementary to, and not instead of, the stock Q1 CD interface.  CD Audio is preferred but - if not initialized,
DirectShow will take over in it's place.

================================================================================================================================
*/

// README - README - README - README - README - README - README - README
// Baker note: In Visual C++ 6 the file has these attributes
//# ADD CPP /I "./dxsdk/sdk8/include"
//# SUBTRACT CPP /I ".\dxsdk\sdk\inc"
// README - README - README - README - README - README - README - README

#if _MSC_VER > 1200 // MSVC6 does not need
#define POINTER_64 __ptr64 // Vile Baker hack ... explanation ...

/*
Visual Studio C++ Express 2008 includes "Additional Include Paths" at higher priority than the standard include paths.  Some sort
of issue with one of the includes DirectX8 includes causes POINTER_64 to not get defined.  The accepted remedies
all suck.  I'll try to remember to list the link MSDN discussion on this here.

But what I did, was made the "Additional Include Paths" specific to this single file instead of the project on
a whole.
*/
#endif

#include "quakedef.h"
#ifdef SUPPORTS_MP3_MUSIC

#include "winquake.h"



#include <objbase.h>

#define COBJMACROS

// QuadEXQ build fix: the project puts the bundled DirectX 3 headers first, and on
// Windows (case-insensitive) MinGW-w64's strmif.h then picks up that old ddraw.h,
// which predates DirectDraw 7. DirectShow only needs the pointer types, so
// declare them opaque when the old header is the one we got.
#include <ddraw.h>
#ifndef DDSCAPS2_CUBEMAP			// only DX6+ ddraw.h has this
	typedef struct IDirectDraw7			*LPDIRECTDRAW7;
	typedef struct IDirectDrawSurface7	*LPDIRECTDRAWSURFACE7;
#endif

#include <dshow.h>

// QuadEXQ: Ogg Vorbis music (the 2021 re-release and many mods ship .ogg).
// stb_vorbis decodes it; DirectShow then plays a .wav of it (see below).
#define STB_VORBIS_NO_STDIO
#define STB_VORBIS_NO_PUSHDATA_API
#include "qx_stb_vorbis.h"

#pragma comment (lib, "ole32.lib") // CoInitialize and friends
#pragma comment (lib, "strmiids.lib") // dxsdk/sdk8/lib/

// this needs to be defined in gl_vidnt.c as well
IGraphBuilder *pGraph = NULL;
IMediaControl *pControl = NULL;
IMediaEventEx *pEvent = NULL;
IBasicAudio	  *pAudio = NULL;
IMediaSeeking *pSeek = NULL;

cbool command_line_disabled;
cbool Playing;
cbool Initialized;
cbool StayOff;
cbool Paused;

float Volume_level;
char last_track [MAX_OSPATH];
static int qx_want_track = -1;		// QuadEXQ: the track to start when its .ogg is decoded
static cbool qx_want_looping;

void MediaPlayer_ChangeVolume (float newvolume);
void MediaPlayer_Stop (void);

// QuadEXQ: give up after a few seconds. It used to wait forever, and when
// DirectShow never got there (the sound device busy, a track it chokes on)
// the game froze on the loading screen.
void WaitForFilterState (OAFilterState DesiredState)
{
	OAFilterState MP3FS;
	HRESULT hr;
	DWORD start = GetTickCount ();

	while (1)
	{
        hr = IMediaControl_GetState(pControl, 1, &MP3FS);

		if (!FAILED (hr) && MP3FS == DesiredState) return;
		if (GetTickCount () - start > 3000) {
			Con_PrintLinef ("Music: DirectShow didn't respond, going on without waiting");
			return;
		}
	}
}


cbool sMediaPlayer_Init (void)
{
	if (COM_CheckParm("-nosound") || StayOff)
		return false;
	else
	{
		HRESULT hr = CoInitialize (NULL);

		if (FAILED (hr))
		{
			Con_PrintLinef ("ERROR - Could not initialize COM library");
			return false;
		}

		Initialized = true;
		Con_DPrintLinef ("Directshow Music initialized");
	}

	return true;
}


void MediaPlayer_Shutdown (void)
{
	qx_want_track = -1;		// QuadEXQ: a track waiting for its decode isn't wanted any more

	if (!Initialized) return;

//	Con_DPrintLinef ("********************* SHUTDOWN MP3 TRACK *********************");
	// stop anything that's playing
	if (Playing)
	{

		IMediaEventEx_SetNotifyWindow(pEvent, (OAHWND) NULL, 0, 0);
		IMediaControl_Stop(pControl);
		WaitForFilterState (State_Stopped);
		IMediaControl_Release(pControl);
		IMediaEventEx_Release(pEvent);
		IBasicAudio_Release(pAudio);
		IMediaSeeking_Release(pSeek); // 1
		IGraphBuilder_Release(pGraph);

		// nothing playing now
		Playing = false;
		Con_DPrintLinef ("MP3 Tracks: Stop");
	}
//	return;

	CoUninitialize ();
	Con_DPrintLinef ("MP3 Tracks: Shutdown");

	// Reset stuff
	pGraph = NULL;
	pControl = NULL;
	pEvent = NULL;
	pAudio = NULL;
	pSeek = NULL;

	Initialized = Playing = Paused = false;

#if 0 //def _DEBUG
	VID_Set_Window_Title (NULL);
#endif
}

void MediaPlayer_Pause (void)
{

	if (!Initialized) return; // don't try anything if we couldn't start COM
	if (!Playing) return; // don' t try to pause if we're not even playing!!!
	if (Paused) return;

	// don't wait for the filter states here
    IMediaControl_Pause(pControl);

	Paused = true;
// Con_DPrintLinef ("MP3 Tracks: Pause");
}

void MediaPlayer_Resume (void)
{
	if (!Initialized) return; // don't try anything if we couldn't start COM
	if (!Playing) return; // don' t try to pause if we're not even playing!!!
	if (!Paused) return;

	// don't wait for the filter states here
    IMediaControl_Run(pControl);

	Paused = false;
 // Con_DPrintLinef ("MP3 Tracks: Resume");
}

void MediaPlayer_RefreshVolume (void)
{
	long db = 0;

	if (!Initialized) return; // don't try anything if we couldn't start COM
	if (!Playing) return; // don' t try to pause if we're not even playing!!!


	if (Volume_level <= 0)
		db = -10000;
	else if (Volume_level >= 1)
		db = 0;
	else db = log10 (Volume_level) * 2000;

	IBasicAudio_put_Volume	(pAudio, db);
//	Con_DPrintLinef ("MP3 Tracks: Refresh volume");
}


void MediaPlayer_Command_Line_Disabled (void)
{
	command_line_disabled = true;


}


// QuadEXQ: a track that's only inside a pak (Arcane Dimensions keeps its
// music in pak0.pak): DirectShow plays files, so copy it out once to the
// temp folder (QX_music_<game>_<name>) and play that copy.
static char *QX_Music_FromPak (const char *relname)
{
	static char cached[MAX_OSPATH];
	char tmpdir[MAX_PATH];
	const char *base = strrchr (relname, '/');
	byte *buf;
	int len;
	FILE *f;

	if (!GetTempPathA (sizeof(tmpdir), tmpdir))
		return NULL;
	if (!(buf = COM_LoadMallocFile (relname)))	// the paks too
		return NULL;
	len = com_filesize;
	c_snprintf3 (cached, "%sQX_music_%s_%s", tmpdir, gamedir_shortname (), base ? base + 1 : relname);

	if ((f = fopen (cached, "rb"))) {	// copied before? keep it if it's the same size
		long have;
		fseek (f, 0, SEEK_END);
		have = ftell (f);
		fclose (f);
		if (have == len) {
			free (buf);
			return cached;
		}
	}
	if (!(f = fopen (cached, "wb"))) {
		free (buf);
		return NULL;
	}
	fwrite (buf, 1, len, f);
	fclose (f);
	free (buf);
	Con_VerbosePrintLinef ("Track %s copied out of its pak to %s", relname, cached);
	return cached;
}

// QuadEXQ: no .mp3 for the track, but an .ogg (in a folder or a pak):
// decode it once to a .wav in the temp folder (QX_music_<game>_<name>_<size>.wav)
// and play that.  A long track takes ~10 seconds to decode, so it's done in
// the background: the game goes on, and the track starts when it's ready
// (MediaPlayer_QX_Poll).  Only the first time; after that the .wav is there.
static char qx_ogg_pending[] = "";		// QX_Music_FromOgg: "decoding, wait"
static volatile LONG qx_dec_state;		// 0 idle, 1 decoding, 2 done, 3 failed
static HANDLE qx_dec_thread;
static struct {
	byte	*buf;
	int		len;
	char	oggname[MAX_QPATH_64];
	char	cached[MAX_OSPATH];
	char	partname[MAX_OSPATH];
} qx_dec;
static char qx_dec_failed[MAX_OSPATH];	// don't try this one again (play the .mp3 if any)

// The decode thread: no engine calls in here (not thread safe), only the C library
static DWORD WINAPI QX_Ogg_Decode_Thread (LPVOID unused)
{
	static short chunk[4096 * 2];
	stb_vorbis *v;
	stb_vorbis_info info;
	cbool ok = false;
	int err;
	FILE *f;

	if ((v = stb_vorbis_open_memory (qx_dec.buf, qx_dec.len, &err, NULL))) {
		info = stb_vorbis_get_info (v);
		// mono or stereo (the chunk is sized for 2), and the .part file opens
		if (info.channels >= 1 && info.channels <= 2 && (f = fopen (qx_dec.partname, "wb"))) {
			#define W32(x) (u32 = (x), fwrite (&u32, 4, 1, f))
			#define W16(x) (u16 = (x), fwrite (&u16, 2, 1, f))
			int channels = info.channels, rate = (int)info.sample_rate, n;
			unsigned int datasize = 0, u32;
			unsigned short u16;

			fwrite ("RIFF", 1, 4, f);	W32 (36);	fwrite ("WAVE", 1, 4, f);	// sizes filled in below
			fwrite ("fmt ", 1, 4, f);	W32 (16);	W16 (1);	W16 (channels);
			W32 (rate);	W32 (rate * channels * 2);	W16 (channels * 2);	W16 (16);
			fwrite ("data", 1, 4, f);	W32 (0);

			while ((n = stb_vorbis_get_samples_short_interleaved (v, channels, chunk, 4096 * channels)) > 0) {
				fwrite (chunk, 2, n * channels, f);
				datasize += n * channels * 2;
			}
			fseek (f, 4, SEEK_SET);		W32 (36 + datasize);
			fseek (f, 40, SEEK_SET);	W32 (datasize);
			ok = datasize > 0 && !ferror (f);
			fclose (f);
			#undef W32
			#undef W16
		}
		stb_vorbis_close (v);
	}
	free (qx_dec.buf);
	qx_dec.buf = NULL;

	if (ok) {
		remove (qx_dec.cached);
		ok = rename (qx_dec.partname, qx_dec.cached) == 0;
	}
	if (!ok)
		remove (qx_dec.partname);
	InterlockedExchange (&qx_dec_state, ok ? 2 : 3);
	return 0;
}

static char *QX_Music_FromOgg (const char *relname)
{
	static char cached[MAX_OSPATH];
	char oggname[MAX_QPATH_64], basename[MAX_QPATH_64], tmpdir[MAX_PATH];
	const char *slash = strrchr (relname, '/');
	char *dot;
	byte *buf;
	int len;
	FILE *f;

	c_strlcpy (oggname, relname);
	if ((dot = strrchr (oggname, '.')) && !strchr (dot, '/'))
		*dot = 0;
	c_strlcpy (basename, slash ? slash + 1 : relname);
	if ((dot = strrchr (basename, '.')))
		*dot = 0;
	c_strlcat (oggname, ".ogg");

	if (!GetTempPathA (sizeof(tmpdir), tmpdir))
		return NULL;
	if (!(buf = COM_LoadMallocFile (oggname)))	// a folder or a pak
		return NULL;
	len = com_filesize;
	c_snprintf4 (cached, "%sQX_music_%s_%s_%d.wav", tmpdir, gamedir_shortname (), basename, len);

	if ((f = fopen (cached, "rb"))) {	// decoded before
		fclose (f);
		free (buf);
		return cached;
	}
	if (!strcmp (cached, qx_dec_failed)) {	// it didn't decode before
		free (buf);
		return NULL;
	}
	if (qx_dec_state != 0) {			// busy with a track: this one comes after it
		free (buf);
		return qx_ogg_pending;
	}

	qx_dec.buf = buf;
	qx_dec.len = len;
	c_strlcpy (qx_dec.oggname, oggname);
	c_strlcpy (qx_dec.cached, cached);
	c_snprintf1 (qx_dec.partname, "%s.part", cached);	// renamed when it's all there
	qx_dec_state = 1;
	if (!(qx_dec_thread = CreateThread (NULL, 0, QX_Ogg_Decode_Thread, NULL, 0, NULL))) {
		qx_dec_state = 0;
		qx_dec.buf = NULL;
		free (buf);
		return NULL;
	}
	Con_VerbosePrintLinef ("Decoding %s in the background", oggname);
	return qx_ogg_pending;
}

// Every frame (CDAudio_Update): when a background decode is done, start the
// track that was waiting for it, if it's still the one wanted.
void MediaPlayer_QX_Poll (void)
{
	LONG state = qx_dec_state;
	int track;

	if (state != 2 && state != 3)
		return;

	WaitForSingleObject (qx_dec_thread, INFINITE);	// it has finished: returns at once
	CloseHandle (qx_dec_thread);
	qx_dec_thread = NULL;
	if (state == 3) {
		Con_PrintLinef ("Couldn't decode %s", qx_dec.oggname);
		c_strlcpy (qx_dec_failed, qx_dec.cached);
	}
	else Con_VerbosePrintLinef ("Track %s decoded to %s", qx_dec.oggname, qx_dec.cached);
	qx_dec_state = 0;

	if ((track = qx_want_track) >= 0) {
		qx_want_track = -1;
		CDAudio_Play ((byte)track, qx_want_looping);	// the .wav now, or the .mp3 if it failed
	}
}

// QuadEXQ: where in the search path a file is (0 = the mod, higher = towards
// id1), or -1 if it's nowhere.  So a mod's .ogg beats id1's .mp3.
static int QX_Music_Rank (const char *relname)
{
	FILE *f = NULL;
	int rank;

	if (COM_FOpenFile (relname, &f) < 0 || !f)
		return -1;
	fclose (f);
	rank = COM_SearchPathRank ();
	return rank < 0 ? 0 : rank;
}

// The .ogg of the track sits ahead of (or instead of) its .mp3
static cbool QX_Music_OggFirst (const char *relname)
{
	char oggname[MAX_QPATH_64], *dot;
	int r_mp3, r_ogg;

	c_strlcpy (oggname, relname);
	if ((dot = strrchr (oggname, '.')) && !strchr (dot, '/'))
		*dot = 0;
	c_strlcat (oggname, ".ogg");
	if ((r_ogg = QX_Music_Rank (oggname)) < 0)
		return false;
	r_mp3 = QX_Music_Rank (relname);
	return r_mp3 < 0 || r_ogg < r_mp3;
}

cbool MediaPlayer_Play (int tracknum, cbool looping)
{
	char track_file[MAX_QPATH_64];
	char *absolute_filename;
	wchar_t W_absolute_filename[MAX_OSPATH];
	cbool alt_track = false;
//	int   i;

	// Disabled by a command line option like -nosound, -nocdaudio or "-dedicated server".
	if (command_line_disabled)
		return false;

	if (!external_music.value)
		return false; // User has it off

	Playing = false;

	if (!Initialized)
	{
		sMediaPlayer_Init (); // Try to turn it on
		if (!Initialized)
		{
			Con_DPrintLinef ("MediaPlayer_Play: Couldn't turn it on");
			return false; // Couldn't turn it on
		}
	}

	if (!cls.music_run)
	{
		extern cbool exec_silent;
		exec_silent = true;
		Cbuf_AddTextLinef ("exec %s", SETMUSIC_CFG_FULL);
		Cbuf_Execute (); // Will set exec_silent to false

		cls.music_run  = true;
	}

	if (0 <= tracknum && tracknum < 100 && musicmaps[tracknum][0] && musicmaps[tracknum][0] != '.')
	{
		c_snprintf1 (track_file, "music/%s", &musicmaps[tracknum][0]);
		alt_track = true;
	}
	else c_snprintf1 (track_file, "music/track%02d", tracknum);

	// Build relative file name

	File_URL_Edit_Default_Extension (track_file, ".mp3", sizeof(track_file));

	// Build absolute file name
	// QuadEXQ: the mod's own music first, .ogg or .mp3, in a folder or a pak
	absolute_filename = QX_Music_OggFirst (track_file) ? QX_Music_FromOgg (track_file) : NULL;
	if (!absolute_filename)
		absolute_filename = COM_FindFile_NoPak (track_file);
	if (!absolute_filename)
		absolute_filename = QX_Music_FromPak (track_file);	// QuadEXQ
	if (!absolute_filename)
		absolute_filename = QX_Music_FromOgg (track_file);	// QuadEXQ

	if (absolute_filename == qx_ogg_pending)	// QuadEXQ: being decoded, starts when it's done
	{
		qx_want_track = tracknum;
		qx_want_looping = looping;
		return true;
	}

	if (!absolute_filename)
	{
		Con_VerbosePrintLinef ("Track: %s not found", track_file);
		MediaPlayer_Shutdown ();
		return false; // Doesn't exist
	}

	c_strlcpy (last_track, absolute_filename);
	if (alt_track)
		Con_VerbosePrintLinef ("Current music track (%02d): %s", tracknum, track_file);
	else Con_VerbosePrintLinef ("Current music track: %s", track_file);

	// We could improve this a little as this function has the typical
	// edge case issues
	mbstowcs (W_absolute_filename, absolute_filename, sizeof(W_absolute_filename));

	do
	{
		#define FAILED_SETUP(x) { Con_PrintLinef (x); return false; }
		HRESULT hr = S_OK;

		// Create the filter graph manager and query for interfaces.
		if (FAILED (hr = CoCreateInstance (&CLSID_FilterGraph, NULL, CLSCTX_INPROC_SERVER, &IID_IGraphBuilder, (void **) &pGraph)))
			FAILED_SETUP ("CoCreateInstance Failed");
		if (FAILED (hr =IGraphBuilder_QueryInterface(pGraph, &IID_IMediaControl, (void **) &pControl)))
			FAILED_SETUP ("IID_IMediaControl Failed");
		if (FAILED (hr =IGraphBuilder_QueryInterface(pGraph, &IID_IMediaEventEx, (void **) &pEvent)))
			FAILED_SETUP ("IID_IMediaEventEx Failed");
		if (FAILED (hr =IGraphBuilder_QueryInterface(pGraph, &IID_IBasicAudio, (void **) &pAudio)))
			FAILED_SETUP ("IID_IBasicAudio Failed");
		if (FAILED (hr =IGraphBuilder_QueryInterface(pGraph, &IID_IMediaSeeking, (void **) &pSeek)))
			FAILED_SETUP ("IID_IMediaSeeking Failed");
		// Baker: This generates an exception but according to docs it looks right.
		if (FAILED (hr =IGraphBuilder_RenderFile(pGraph, W_absolute_filename, NULL))) // Baker _Render can point into a pak?
			FAILED_SETUP ("IGraphBuilder_RenderFile Failed");

		// send events through the standard window event handler
	   if (FAILED (hr = IMediaEventEx_SetNotifyWindow(pEvent, (OAHWND) sysplat.mainwindow, WM_GRAPHNOTIFY, 0)))
			FAILED_SETUP ("IMediaEventEx_SetNotifyWindow Failed");

		// Run the graph.
	   if (FAILED (hr = IMediaControl_Run(pControl) ))
			FAILED_SETUP ("IMediaControl_Run Failed");

		#undef FAILED_SETUP
	} while (0);

	// tell us globally that we can play OK
	Playing = true;
	Paused = false;

	// wait until it reports playing
	WaitForFilterState (State_Running);

	MediaPlayer_RefreshVolume ();
	// examples in the SDK will wait for the event to complete here, but this is totally inappropriate for a game engine.

	Con_DPrintLinef ("MP3 Tracks: Playing");
//	Con_DPrintLinef ("********************* PLAYING MP3 TRACK *********************");
	return Playing;

}

void MediaPlayer_Update (void)
{
#if 0 //def _DEBUG
	if (!Initialized) return; // don't try anything if we couldn't start COM
	if (!Playing) return; // don't try to stop if we're not even playing!!!

	{
		static int k;
		LONGLONG pos1, pos2;
		k++;
		IMediaSeeking_GetPositions (pSeek, &pos1, &pos2);
		VID_Set_Window_Title ("%d - CD track position: pos1 %d pos2 %d", k, (int)pos1/10000000, (int)(pos2/10000000));
	}
#endif
}


cbool MediaPlayer_Force_On (void)
{
	if (command_line_disabled)
		return false;

	if (COM_CheckParm("-nosound"))
		return false;

	if (COM_CheckParm("-nocdaudio"))
		return false;

	StayOff = false;
	if (host_post_initialized)
		Con_PrintLinef ("MP3 Tracks: Forced on");
	return true;
}


void MediaPlayer_Force_Off (void)
{
	StayOff = true;
	if (host_post_initialized)
		Con_PrintLinef ("MP3 Tracks: Forced off");
}

void MediaPlayer_ChangeVolume (float newvolume)
{
	Volume_level = newvolume;	// QuadEXQ: kept even when nothing plays yet (a track waiting for its decode uses it)

	if (!Initialized) return; // don't try anything if we couldn't start COM
	if (!Playing) return; // don' t try to pause if we're not even playing!!!

	// put_Volume uses an exponential decibel-based scale going from -10000 (no sound) to 0 (full volume)
	// each 100 represents 1 db.  i could do the maths, but this is faster and more maintainable.
	// whoever in ms designed this must have really prided themselves on being so technically correct.  bastards.
	// decibels are great if you're an audio engineer, but if you're just writing a simple sliding volume control...

	Volume_level = newvolume;
	MediaPlayer_RefreshVolume ();

//	Con_DPrintLinef ("MP3 Tracks: Effective volume is %f", newvolume);
}

/*
===================
MesgMP3DShow

MP3 Message handler.  The only one we're interested in is a stop message.
Everything else is handled within the engine code.
===================
*/
void MediaPlayer_Message (int looping)
{
	LONG      evCode;
	LONG_PTR   evParam1, evParam2;
    HRESULT      hr = S_OK;

	if (!Initialized) return; // don't try anything if we couldn't start COM
	if (!Playing) return; // don' t try to pause if we're not even playing!!!

#if 0 //def _DEBUG
	{
		static int k;
		LONGLONG pos1, pos2;
		k++;
		IMediaSeeking_GetPositions (pSeek, &pos1, &pos2);
		VID_Set_Window_Title ("%d - CD track position: pos1 %d pos2 %d", k, (int)pos1, (int)pos2);
	}


#pragma message ("Baker: In Engine X I altered this a bit")
#endif
    // Process all queued events
   while (SUCCEEDED (IMediaEventEx_GetEvent (pEvent, &evCode, &evParam1, &evParam2, 0)))
    {

        // Free memory associated with callback, since we're not using it
        hr = IMediaEventEx_FreeEventParams(pEvent, evCode, evParam1, evParam2);

        // If this is the end of the clip, reset to beginning
        if (evCode == EC_COMPLETE && looping)
        {
            LONGLONG pos = 0;

            // Reset to first frame of movie
			 hr = IMediaSeeking_SetPositions(pSeek, &pos, AM_SEEKING_AbsolutePositioning, NULL, AM_SEEKING_NoPositioning);
			 Con_DPrintLinef ("MP3 Tracks: Looped");
        }
		else if (evCode == EC_COMPLETE)
		{
			// have to explicitly stop it when it completes otherwise the interfaces will remain open
			// when the next MP3 is played, and both will play simultaneously...!
			MediaPlayer_Shutdown ();
		}
    }
    return;
}

#endif