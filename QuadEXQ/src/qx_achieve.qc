/*
==============================================================================
QuadEXQ: run stats and achievements (needs the QuadEXQ engine)

  Everything is counted into archived engine cvars, so it all adds up over
  every game you play -- maps, deaths, saves, quitting, new games
  (qx_runreset starts the stats over by hand):
    qx_rs<type>   your kills of each monster type (QX_RsType)
    qx_rd<type>   times that monster type killed you
    qx_run_*      kills, deaths, time, score, maps
    qx_ach        achievements unlocked (QX_ACH_* bits)
    qx_ach2       ... and the rest (QX_A2_* bits: a float holds 24 bits)
    qx_life_*     counters behind the achievements (never reset)
  The engine has the names and draws the tables: qx_runstats,
  qx_achievements, qx_runpage (the third page of THE ENDER's end text).
  The type numbers and achievement bits must match sv_main.c.
==============================================================================
*/

float	QX_ACH_CENTURY		= 1;
float	QX_ACH_BODYCOUNT	= 2;
float	QX_ACH_SHAMBLERS	= 4;
float	QX_ACH_JUGGERNAUT	= 8;
float	QX_ACH_DEATHFIEND	= 16;
float	QX_ACH_GURO			= 32;
float	QX_ACH_K4B			= 64;
float	QX_ACH_G			= 128;
float	QX_ACH_TRES			= 256;
float	QX_ACH_RUNETHIEF	= 512;
float	QX_ACH_TRUECYBER	= 1024;
float	QX_ACH_OVERFLOW		= 2048;
float	QX_ACH_QUAD			= 4096;
float	QX_ACH_SWATS		= 8192;
float	QX_ACH_JET			= 16384;
float	QX_ACH_DELTA		= 32768;
float	QX_ACH_QUADKING		= 65536;
float	QX_ACH_LAVADIVE		= 131072;
float	QX_ACH_1STFRAG		= 262144;
float	QX_ACH_HUMILIATION	= 524288;
float	QX_ACH_MARS			= 1048576;
float	QX_ACH_ELITEDELTA	= 2097152;

// qx_ach2 (in the engine's table these follow on, from entry 22)
float	QX_A2_BTJUNKIE		= 1;
float	QX_A2_MAXSKILL		= 2;
float	QX_A2_ELITES		= 4;
float	QX_A2_PLASMA		= 8;
float	QX_A2_NODELTA		= 16;
float	QX_A2_UNTOUCHABLE	= 32;
float	QX_A2_RIFTS			= 64;
float	QX_A2_HOMERUN		= 128;
float	QX_A2_LORDSWAT		= 256;
float	QX_A2_SELFKILL		= 512;
float	QX_A2_LATE			= 1024;
float	QX_A2_SHUBGATE		= 2048;
float	QX_A2_TELEFRAG		= 4096;
float	QX_A2_RJUMP			= 8192;
float	QX_A2_QUADFAIL		= 16384;
float	QX_A2_SHUBLORD		= 32768;
float	QX_A2_BFGSNIPER		= 65536;
float	QX_A2_DELTAPRIDE	= 131072;
float	QX_A2_NOFF			= 262144;
float	QX_A2_KILLBLOCK		= 524288;

float	QX_RS_JET			= 22;	// (deaths only) a jet charge to the face

float(string c) QX_RsType =
{
	if (c == "monster_army")		return 1;
	if (c == "monster_enforcer" || c == "monster_enft" || c == "monster_enft_commander" || c == "monster_me")
									return 2;
	if (c == "monster_ogre" || c == "monster_ogre_marksman")
									return 3;
	if (c == "monster_qogre")		return 4;
	if (c == "monster_knight")		return 5;
	if (c == "monster_hell_knight" || c == "monster_lord" || c == "monster_super_hknight" || c == "monster_bane")
									return 6;
	if (c == "monster_demon1")		return 7;
	if (c == "monster_demon2")		return 8;
	if (c == "monster_shambler")	return 9;
	if (c == "monster_shambler_QUTF")	return 10;
	if (c == "monster_shalrath")	return 11;
	if (c == "monster_wizard" || c == "monster_superwizard")
									return 12;
	if (c == "monster_zombie" || c == "monster_mummy")
									return 13;
	if (c == "monster_tarbaby")		return 14;
	if (c == "monster_dog")			return 15;
	if (c == "monster_fish" || c == "monster_eel")
									return 16;
	if (c == "monster_runehunter" || c == "monster_hplayer")
									return 17;
	if (c == "monster_cyber")		return 18;
	if (c == "monster_oldone")		return 19;
	if (c == "monster_daikon" || c == "monster_bdaikon")
									return 20;
	return 21;
};

string(float t) QX_RsCvar =
{
	if (t == 1) return "qx_rs1";	if (t == 2) return "qx_rs2";	if (t == 3) return "qx_rs3";
	if (t == 4) return "qx_rs4";	if (t == 5) return "qx_rs5";	if (t == 6) return "qx_rs6";
	if (t == 7) return "qx_rs7";	if (t == 8) return "qx_rs8";	if (t == 9) return "qx_rs9";
	if (t == 10) return "qx_rs10";	if (t == 11) return "qx_rs11";	if (t == 12) return "qx_rs12";
	if (t == 13) return "qx_rs13";	if (t == 14) return "qx_rs14";	if (t == 15) return "qx_rs15";
	if (t == 16) return "qx_rs16";	if (t == 17) return "qx_rs17";	if (t == 18) return "qx_rs18";
	if (t == 19) return "qx_rs19";	if (t == 20) return "qx_rs20";	if (t == 21) return "qx_rs21";
	return "qx_rs22";
};

string(float t) QX_RdCvar =
{
	if (t == 1) return "qx_rd1";
	if (t == 2) return "qx_rd2";
	if (t == 3) return "qx_rd3";
	if (t == 4) return "qx_rd4";
	if (t == 5) return "qx_rd5";
	if (t == 6) return "qx_rd6";
	if (t == 7) return "qx_rd7";
	if (t == 8) return "qx_rd8";
	if (t == 9) return "qx_rd9";
	if (t == 10) return "qx_rd10";
	if (t == 11) return "qx_rd11";
	if (t == 12) return "qx_rd12";
	if (t == 13) return "qx_rd13";
	if (t == 14) return "qx_rd14";
	if (t == 15) return "qx_rd15";
	if (t == 16) return "qx_rd16";
	if (t == 17) return "qx_rd17";
	if (t == 18) return "qx_rd18";
	if (t == 19) return "qx_rd19";
	if (t == 20) return "qx_rd20";
	if (t == 21) return "qx_rd21";
	return "qx_rd22";
};

// add to a counter cvar; returns the new value (0 without the QuadEXQ engine)
float(string name, float add) QX_CvAdd =
{
	local float v;

	if (!qx_newengine || deathmatch)
		return 0;
	v = cvar (name) + add;
	cvar_set (name, ftos (v));
	return v;
};

void(string cv, float bit, string name, string desc) QX_AchIn =
{
	local float a;
	local entity p;

	if (!qx_newengine || deathmatch)
		return;
	a = cvar (cv);
	if (a & bit)
		return;
	cvar_set (cv, ftos (a | bit));

	QX_CenterAll ("ACHIEVEMENT UNLOCKED\n\n", name, "\n", desc);
	p = find (world, classname, "player");
	if (p)
		sound (p, CHAN_ITEM, "misc/talk.wav", 1, ATTN_NONE);
	qx_rep_to = world;
	QX_LB ();
	QX_LS ("    ACHIEVEMENT: ");
	QX_LS (name);
	QX_LS (" -- ");
	QX_LS (desc);
	QX_LE ();
};

void(float bit, string name, string desc) QX_Ach =
{
	QX_AchIn ("qx_ach", bit, name, desc);
};

void(float bit, string name, string desc) QX_Ach2 =
{
	QX_AchIn ("qx_ach2", bit, name, desc);
};

// ---------------------------------------------------------------- the hooks

// you killed a monster (from QX_StatKill)
void(entity targ, entity attacker) QX_AchKill =
{
	local float n;

	QX_CvAdd (QX_RsCvar (QX_RsType (targ.classname)), 1);
	QX_CvAdd ("qx_run_kills", 1);

	n = QX_CvAdd ("qx_life_kills", 1);
	if (n >= 100)
		QX_Ach (QX_ACH_CENTURY, "Century", "Kill 100 enemies");
	if (n >= 1000)
		QX_Ach (QX_ACH_BODYCOUNT, "Body Count", "Kill 1000 enemies");

	if (attacker.items & IT_QUAD)
	if (QX_CvAdd ("qx_life_quadkills", 1) >= 1000)
		QX_Ach (QX_ACH_QUADKING, "Quad King", "Kill 1000 enemies with Quad Damage");

	if (targ.classname == "monster_shambler")
	if (QX_CvAdd ("qx_life_shamblers", 1) >= 100)
		QX_Ach (QX_ACH_SHAMBLERS, "Shambler Shredder", "Kill 100 Shamblers");
	if (targ.classname == "monster_shambler_QUTF")
		QX_Ach (QX_ACH_JUGGERNAUT, "Juggernaut Down", "Kill your first Juggernaut");
	if (targ.classname == "monster_demon2")
		QX_Ach (QX_ACH_DEATHFIEND, "Death Fiend Down", "Kill a Death Fiend");
	if (targ.classname == "monster_cyber")
	if (targ.qx_ender_boss)
		QX_Ach (QX_ACH_TRUECYBER, "True Cyber", "Destroy the Cyber Delta");

	if (targ.qx_elite)
	if (QX_CvAdd ("qx_life_elites", 1) >= 100)
		QX_Ach2 (QX_A2_ELITES, "Elite Hunter", "Kill 100 elite enemies");
	if (targ.qx_gen > 0)
	if (QX_CvAdd ("qx_life_rifts", 1) >= 100)
		QX_Ach2 (QX_A2_RIFTS, "Rift Walker", "Kill 100 monsters that came through a rift");
	if (qx_ach_inflt == time)
	if (qx_ach_infl)
	{
		if (qx_ach_infl.think == Plasma_Fly)
		if (QX_CvAdd ("qx_life_plasma", 1) >= 100)
			QX_Ach2 (QX_A2_PLASMA, "Plasma Storm", "Kill 100 enemies with plasma");
		if (qx_ach_infl.qx_ach_swatfrom == targ)
		{
			QX_Ach2 (QX_A2_HOMERUN, "Home Run", "Kill a monster with its own shot, swatted back");
			if (QX_RsType (targ.classname) == 3 || QX_RsType (targ.classname) == 4)
				QX_Ach2 (QX_A2_KILLBLOCK, "Kill block!", "Kill an Ogre with its own shot, swatted back");
		}
	}
};

// you died (from QX_StatDeath, self = the player)
void() QX_AchDeath =
{
	local float t;

	QX_CvAdd ("qx_run_deaths", 1);
	if (qx_newengine && !deathmatch)
		cvar_set ("qx_ach_streak", "0");	// Untouchable starts over
	if (self.super_damage_finished > time)
		QX_Ach2 (QX_A2_QUADFAIL, "Quad Fail", "Die with Quad Damage running");
	if (qx_delta_call || find (world, classname, "qx_delta_wait"))
		QX_Ach2 (QX_A2_LATE, "Sorry We're Late", "Die while Delta Team is on the way");
	if (self.qx_st_lastclass == "teledeath")
		QX_Ach2 (QX_A2_TELEFRAG, "Telefragged", "Get telefragged");
	if (self.qx_st_lastatk == self)
		QX_Ach2 (QX_A2_SELFKILL, "Friendly Fire?", "Kill yourself");
	if (self.watertype == CONTENT_LAVA)
		QX_Ach (QX_ACH_LAVADIVE, "Lava Dive!", "Die in lava");
	if (self.health < -40)
		QX_Ach (QX_ACH_1STFRAG, "1st Frag!", "Get blown to bits");
	if (self.qx_st_lastatk == self || self.qx_st_lastclass == "" || self.qx_st_lastclass == "worldspawn"
	 || self.qx_st_lastclass == "teledeath")
		return;			// (yourself, a fall, lava: no monster to blame)
	t = QX_RsType (self.qx_st_lastclass);
	QX_CvAdd (QX_RdCvar (t), 1);
	if (self.qx_st_lastatk.qx_charging)
	{	// a jet charge to the face
		QX_CvAdd (QX_RdCvar (QX_RS_JET), 1);
		if (QX_CvAdd ("qx_life_jetdeaths", 1) >= 10)
			QX_Ach (QX_ACH_JET, "Face, Meet Jet", "Die to a jet charge 10 times");
	}
};

// a map cleared (from QX_StatMapEnd)
void(float runtime, float score) QX_AchMapEnd =
{
	QX_CvAdd ("qx_run_time", runtime);
	QX_CvAdd ("qx_run_score", score);
	QX_CvAdd ("qx_run_maps", 1);
	if (QX_MapDeaths () == 0)
	if (QX_CvAdd ("qx_ach_streak", 1) >= 5)
		QX_Ach2 (QX_A2_UNTOUCHABLE, "Untouchable", "Clear 5 maps in a row without dying");
};

// an arena win (from QX_DuelEnd): its score, and the hunter achievements
void(float pts, string hunter, float perfect) QX_AchDuelWin =
{
	QX_CvAdd ("qx_run_score", pts);
	if (hunter == "GuroFighter")
		QX_Ach (QX_ACH_GURO, "GuroFighter Down", "Beat GuroFighter in the arena");
	if (!perfect)
		return;
	if (hunter == "K4B")
		QX_Ach (QX_ACH_K4B, "K4B, 10 - 0", "Beat K4B without dying");
	if (hunter == "G")
		QX_Ach (QX_ACH_G, "G, 10 - 0", "Beat G without dying");
	if (hunter == "Tres")
		QX_Ach (QX_ACH_TRES, "Just as id intended", "Beat Tres 10 - 0");
};

void() QX_AchRuneLost =
{
	QX_Ach (QX_ACH_RUNETHIEF, "Rune Thief", "Lose a rune to a Rune Hunter");
};

void() QX_AchSwat =
{
	if (QX_CvAdd ("qx_life_swats", 1) >= 100)
		QX_Ach (QX_ACH_SWATS, "Return to Sender", "Swat back 100 shots");
};

void() QX_AchDeltaLost =
{
	if (QX_CvAdd ("qx_life_deltadeaths", 1) >= 100)
		QX_Ach (QX_ACH_DELTA, "Join the Delta Team", "Delta Team loses 100 men (they need you)");
};

void() QX_AchOverflow =
{
	QX_Ach (QX_ACH_OVERFLOW, "Packet Overflow", "Live through a whole Cyber Delta chaingun burst");
};

void() QX_AchQuad =
{
	QX_Ach (QX_ACH_QUAD, "QUAD!", "Finish THE ENDER");
};

void() QX_AchHumiliation =
{
	QX_Ach (QX_ACH_HUMILIATION, "Humiliation!", "Get axed by a Rune Hunter");
};

void() QX_AchMars =
{
	QX_Ach (QX_ACH_MARS, "Mars Mission!", "Delta Team pulls out with heavy losses");
};

void() QX_AchDeltaKill =
{
	if (QX_CvAdd ("qx_life_deltakills", 1) >= 1000)
		QX_Ach (QX_ACH_ELITEDELTA, "Elite Delta!", "Delta Team kills 1000 enemies");
};

// ---------------------------------------------------------------- qx_ach2

// every frame, from QX_StatTick (self = the living player)
void() QX_AchTick =
{
	if (qx_timescale < 1 && qx_timescale > 0)
		qx_ach_bt = qx_ach_bt + frametime / qx_timescale;	// (real seconds)
	if (qx_ach_bt >= 5)
	{
		if (QX_CvAdd ("qx_life_bttime", floor (qx_ach_bt)) >= 600)
			QX_Ach2 (QX_A2_BTJUNKIE, "Bullet Time Junkie", "Spend 10 minutes in bullet time");
		qx_ach_bt = qx_ach_bt - floor (qx_ach_bt);
	}
};

void() QX_AchMaxSkill =
{
	QX_Ach2 (QX_A2_MAXSKILL, "Max Skill", "Reach PlayerSkill 100");
};

// a map starts (QX_StatStart): the first map of an episode starts the
// No Delta Needed run (qx_ach_ep = the episode, 0 = Delta Team came)
void() QX_AchMapStart =
{
	if (!qx_newengine || deathmatch)
		return;
	if (mapname == "e1m1")	cvar_set ("qx_ach_ep", "1");
	if (mapname == "e2m1")	cvar_set ("qx_ach_ep", "2");
	if (mapname == "e3m1")	cvar_set ("qx_ach_ep", "3");
	if (mapname == "e4m1")	cvar_set ("qx_ach_ep", "4");
};

void() QX_AchDeltaHere =
{
	if (qx_newengine && !deathmatch)
		cvar_set ("qx_ach_ep", "0");
};

// a rune picked up (sigil_touch: its spawnflags 1, 2, 4, 8)
void(float sflags) QX_AchSigil =
{
	local float ep;

	ep = 0;
	if (sflags & 1) ep = 1;
	if (sflags & 2) ep = 2;
	if (sflags & 4) ep = 3;
	if (sflags & 8) ep = 4;
	if (ep)
	if (cvar ("qx_ach_ep") == ep)
		QX_Ach2 (QX_A2_NODELTA, "No Delta Needed", "Finish an episode without Delta Team");
};

// you swatted e back (QX_AutoDeflect, before e.owner is you)
void(entity e) QX_AchSwatShot =
{
	if (e.qx_ach_vlord)
		QX_Ach2 (QX_A2_LORDSWAT, "Lord of the Swat", "Swat back a shot a Vore Lord swatted at you");
	e.qx_ach_vlord = 0;
	e.qx_ach_swatfrom = e.owner;
};

// you hurt yourself (QX_StatHurt): a rocket jump if it sends you up
void(entity targ, entity attacker) QX_AchRJump =
{
	if (attacker != targ || targ.velocity_z < 200)
		return;
	if (time < targ.qx_ach_rjt + 0.5)
		return;
	targ.qx_ach_rjt = time;
	if (QX_CvAdd ("qx_life_rjumps", 1) >= 100)
		QX_Ach2 (QX_A2_RJUMP, "Rocket Jumper", "Rocket jump 100 times");
};

// your BFG ball hit a Delta Team man (T_Damage; it does him no harm)
void(entity inflictor) QX_AchBFGDelta =
{
	if (inflictor.qx_ach_ff)
		return;
	inflictor.qx_ach_ff = 1;
	if (QX_CvAdd ("qx_life_bfgdelta", 1) >= 10)
		QX_Ach2 (QX_A2_NOFF, "It's alright! No friendly fire!", "Hit Delta Team with the BFG 10 times");
};

void() QX_AchShubGate =
{
	QX_Ach2 (QX_A2_SHUBGATE, "Shub's Revenge", "Get telefragged by Shub-Niggurath's gate");
};

// finale_1 (Shub-Niggurath is done)
void() QX_AchShubLord =
{
	local entity p;

	p = find (world, classname, "player");
	if (p)
	if (p.qx_adren >= 100)
		QX_Ach2 (QX_A2_SHUBLORD, "Shub Lord at 300%", "Finish off Shub-Niggurath at 300% adrenaline");
};

// THE ENDER: the 10th BFG hit
void() QX_AchBFGSniper =
{
	if (!qx_ach_bfgground)
		QX_Ach2 (QX_A2_BFGSNIPER, "BFG Sniper", "Land all 10 BFG hits on the Cyber Delta in midair");
};

// THE ENDER: the Cyber Delta is down
void(float deltahere) QX_AchDeltaPride =
{
	if (deltahere)
	if (qx_delta_losses == 0)
		QX_Ach2 (QX_A2_DELTAPRIDE, "Delta's Pride", "Down the Cyber Delta with Delta Team, and lose no man");
};
