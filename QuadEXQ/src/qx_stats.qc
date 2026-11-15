/*
==============================================================================
QuadEXQ map report

  Collects what happened on the current map and, when you reach the exit,
  prints a report to the console and (on the QuadEXQ engine) appends it to
  <gamedir>/quadexq_stats.txt. Deaths, boss kills and map starts are logged
  the moment they happen, so the file is a full play history.

  Numbers are for "this run" of the map (a death restarts the map). Deaths
  are counted by the engine cvar qx_mapdeaths, which survives the restart.

  Score:  kill 10 / scout 20 / elite 30 / boss +300
          secret 100, death -200, no-death clear +3000 x the no-death
          streak (2nd map in a row 6000, 3rd 9000 ..), an episode
          without a death +10000
==============================================================================
*/

float	QX_SC_KILL	= 10;
float	QX_SC_SCOUT	= 20;
float	QX_SC_ELITE	= 30;
float	QX_SC_BOSS	= 300;
float	QX_SC_SECRET	= 100;
float	QX_SC_DEATH	= 200;
float	QX_SC_NODEATH	= 3000;	// (was 300) x the no-death streak
float	QX_SC_EPCLEAN	= 10000;	// a whole episode without a death
float	qx_st_streak;		// this map's place in the no-death streak (0 = died)
float	qx_st_runnew;		// the map report: this run just made a new high score
float	qx_st_mapnew;		// ... and a new best for this map
float	qx_st_mapprev;		// (the map's best before)

// QuadEXQ / Mark V engines concatenate up to 8 strings and keep 16 ftos results
void(entity client, string s1, string s2, string s3, string s4, string s5, string s6, string s7, string s8) qx_cprint8 = #73;

// ---------------------------------------------------------------- per-weapon
.float	qx_ws_id;			// weapon index 1..12
.float	qx_ws_hits, qx_ws_dmg, qx_ws_kills, qx_ws_held;
.float	qx_ws_fire;			// seconds spent firing it (DPS = damage / this)
entity	qx_ws_list;			// first weapon-stat entity (chained by .enemy)

float(float w) QX_WIdx =
{
	if (w == QX_W_FIST)		return 13;
	if (w == IT_AXE)		return 1;
	if (w == IT_BLASTER)		return 2;
	if (w == IT_SHOTGUN)		return 3;
	if (w == IT_SUPER_SHOTGUN)	return 4;
	if (w == IT_NAILGUN)		return 5;
	if (w == IT_SUPER_NAILGUN)	return 6;
	if (w == IT_GRENADE_LAUNCHER)	return 7;
	if (w == IT_ROCKET_LAUNCHER)	return 8;
	if (w == IT_LIGHTNING)		return 9;
	if (w == IT_ION)		return 10;
	if (w == IT_BFG)		return 11;
	return 12;
};

string(float i) QX_WName =
{
	if (i == 13)	return "LeftHand   ";
	if (i == 1)	return "Axe        ";
	if (i == 2)	return "Blaster    ";
	if (i == 3)	return "Shotgun    ";
	if (i == 4)	return "SuperShotgn";
	if (i == 5)	return "Nailgun    ";
	if (i == 6)	return "SuperNailgn";
	if (i == 7)	return "GrenadeL   ";
	if (i == 8)	return "RocketL    ";
	if (i == 9)	return "Lightning  ";
	if (i == 10)	return "Ion        ";
	if (i == 11)	return "BFG        ";
	return "other      ";
};

// the weapon a hit / kill / tick counts for: the auto melee swing is the Axe,
// even though the gun stays selected (a rocket landing mid-swing is still the RL)
float	qx_st_axehit;			// the latest QX_StatHit was a melee swing
float(entity p) QX_StatWeap =
{
	if (p.qx_meleeing == 2)
		return QX_W_FIST;
	if (p.qx_meleeing)
		return IT_AXE;
	return p.weapon;
};

entity(float w) QX_WStat =
{
	local entity e;
	local float id;

	id = QX_WIdx (w);
	e = qx_ws_list;
	while (e)
	{
		if (e.qx_ws_id == id)
			return e;
		e = e.enemy;
	}
	e = spawn ();
	e.classname = "qx_wstat";
	e.qx_ws_id = id;
	e.enemy = qx_ws_list;
	qx_ws_list = e;
	return e;
};

// ---------------------------------------------------------------- output
// One line = QX_LB, any number of QX_LS / QX_LN, QX_LE.
// Pieces go to the console of qx_rep_to (if set) and to the log file.
entity	qx_rep_to;

void() QX_LB =
{
	if (qx_persist)
		localcmd ("qx_statlog \"");
};

// card mode: pieces go only to the QuadEXQ engine's intermission card
float	qx_card_mode;

void(string kind) QX_CB =		// begin a card line: qx_statcard <kind> "...
{
	qx_card_mode = 1;
	localcmd ("qx_statcard ");
	localcmd (kind);
	localcmd (" \"");
};

void() QX_CE =
{
	localcmd ("\"\n");
	qx_card_mode = 0;
};

void(string s) QX_LS =
{
	if (qx_card_mode)
	{
		localcmd (s);
		return;
	}
	if (qx_rep_to)
	if (qx_rep_to.ishuman)
		qx_sprint4 (qx_rep_to, s, "", "", "");
	if (qx_persist)
		localcmd (s);
};

void(float n) QX_LN =
{
	QX_LS (ftos (floor (n)));	// one ftos per call: safe on every engine
};

void(float t) QX_LT =			// m:ss
{
	local float m, s;

	t = floor (t);
	m = floor (t / 60);
	s = t - m * 60;
	QX_LN (m);
	if (s < 10)
		QX_LS (":0");
	else
		QX_LS (":");
	QX_LN (s);
};

void() QX_LE =
{
	if (qx_rep_to)
	if (qx_rep_to.ishuman)
		qx_sprint4 (qx_rep_to, "\n", "", "", "");
	if (qx_persist)
		localcmd ("\"\n");
};

float() QX_MapDeaths =
{
	if (!qx_persist)
		return 0;
	return cvar ("qx_mapdeaths");
};

float(float t) QX_RunTime =
{
	return t - qx_st_t0;
};

// ---------------------------------------------------------------- hooks

// first spawn on a map (also after a death restart)
void() QX_StatStart =
{
	if (deathmatch)
		return;
	if (qx_st_init)
		return;
	qx_st_init = 1;
	qx_st_t0 = time;
	qx_st_skill0 = qx_pskill;
	QX_AchMapStart ();
	if (world.model == "maps/start.bsp")
	{
		QX_RunStart ();		// a loop, or a new run
		return;
	}

	if (qx_persist)
		localcmd ("qx_statcard clear\n");

	qx_rep_to = world;		// log only
	QX_LB ();
	QX_LS ("--- ");
	QX_LS (mapname);
	QX_LS (" start   attempt ");
	QX_LN (QX_MapDeaths () + 1);
	QX_LS ("   PlayerSkill ");
	QX_LN (qx_pskill);
	QX_LS ("   health ");
	QX_LN (self.health);
	QX_LS ("  armor ");
	QX_LN (self.armorvalue);
	QX_LE ();
};

// every frame, from QX_PlayerFrame (self = player)
void() QX_StatTick =
{
	local entity e;

	if (deathmatch)
		return;
	if (intermission_running)
		return;
	if (self.health <= 0)
		return;
	e = QX_WStat (QX_StatWeap (self));
	e.qx_ws_held = e.qx_ws_held + frametime;
	// firing: trigger held, or still inside the weapon's refire time
	if (self.button0 || self.attack_finished > time)
		e.qx_ws_fire = e.qx_ws_fire + frametime;
	if (qx_timescale < 1)
		qx_st_slow = qx_st_slow + frametime;
	QX_AchTick ();
};

// player damages a monster (before the health is taken)
void(entity attacker, entity inflictor, entity targ, float take) QX_StatHit =
{
	local entity e;
	local float real;

	if (deathmatch)
		return;
	qx_st_axehit = (attacker.qx_meleeing && inflictor == attacker);
	qx_ach_infl = inflictor;		// (for the achievements, if this hit kills)
	qx_ach_inflt = time;
	real = take;
	if (targ.health < real)
		real = targ.health;
	if (real < 0)
		real = 0;
	if (qx_st_axehit)
		e = QX_WStat (QX_StatWeap (attacker));
	else
		e = QX_WStat (attacker.weapon);
	e.qx_ws_hits = e.qx_ws_hits + 1;
	e.qx_ws_dmg = e.qx_ws_dmg + real;
	qx_st_dealt = qx_st_dealt + real;
};

// a player takes damage
void(entity targ, entity attacker, float take) QX_StatHurt =
{
	if (deathmatch)
		return;
	qx_st_taken = qx_st_taken + take;
	targ.qx_st_lastatk = attacker;
	targ.qx_st_lastclass = attacker.classname;
	targ.qx_st_lastelite = attacker.qx_elite;
	QX_AchRJump (targ, attacker);
};

void(entity targ, entity attacker) QX_StatKill =
{
	local entity e;

	if (deathmatch)
		return;
	if (!(targ.flags & FL_MONSTER))
		return;

	if (targ.qx_isboss)
	{
		qx_st_bosst = QX_RunTime (time);
		qx_st_bossname = targ.classname;
		qx_rep_to = world;
		QX_LB ();
		QX_LS ("    BOSS ");
		QX_LS (targ.classname);
		QX_LS (" down at ");
		QX_LT (qx_st_bosst);
		QX_LS ("   PlayerSkill ");
		QX_LN (qx_pskill);
		QX_LE ();
	}

	if (attacker.qx_delta)			// Delta team (allies)
	{
		qx_st_delta = qx_st_delta + 1;
		qx_delta_kills = qx_delta_kills + 1;
		QX_AchDeltaKill ();
		return;
	}
	if (!(attacker.flags & FL_CLIENT))
		return;

	if (qx_st_axehit)			// killed by the hit just counted (T_Damage -> Killed)
		e = QX_WStat (QX_StatWeap (attacker));
	else
		e = QX_WStat (attacker.weapon);
	qx_st_axehit = FALSE;
	e.qx_ws_kills = e.qx_ws_kills + 1;
	qx_st_kills = qx_st_kills + 1;
	QX_AchKill (targ, attacker);		// the run stats, achievements

	if (targ.qx_isboss)
		qx_st_points = qx_st_points + QX_SC_ELITE + QX_SC_BOSS;
	else if (targ.qx_elite)
	{
		qx_st_points = qx_st_points + QX_SC_ELITE;
		qx_st_elites = qx_st_elites + 1;
	}
	else if (targ.qx_isscout)
	{
		qx_st_points = qx_st_points + QX_SC_SCOUT;
		qx_st_scouts = qx_st_scouts + 1;
	}
	else
		qx_st_points = qx_st_points + QX_SC_KILL;
};

// from QX_PlayerDied (self = player), after the PlayerSkill penalty
void(float oldskill) QX_StatDeath =
{
	if (deathmatch)
		return;
	if (qx_persist)
		cvar_set ("qx_mapdeaths", ftos (QX_MapDeaths () + 1));
	QX_AchDeath ();						// the run stats, achievements

	qx_rep_to = world;
	QX_LB ();
	QX_LS ("    DEATH at ");
	QX_LT (QX_RunTime (time));
	QX_LS ("  by ");
	if (self.qx_st_lastatk == self)
		QX_LS ("yourself");
	else if (self.qx_st_lastclass == "" || self.qx_st_lastclass == "worldspawn")
		QX_LS ("world (fall / lava / slime / crush)");
	else
		QX_LS (self.qx_st_lastclass);
	if (self.qx_st_lastelite)
		QX_LS (" (elite)");
	QX_LS ("   PlayerSkill ");
	QX_LN (oldskill);
	QX_LS (" -> ");
	QX_LN (qx_pskill);
	QX_LS ("   kills ");
	QX_LN (qx_st_kills);
	QX_LS ("   weapon ");
	QX_LS (QX_WName (QX_WIdx (self.weapon)));
	QX_LE ();
};

float() QX_StatScore =
{
	local float sc, d;

	d = QX_MapDeaths ();
	sc = qx_st_points + found_secrets * QX_SC_SECRET - d * QX_SC_DEATH;
	qx_st_streak = 0;
	if (d == 0)
	{	// the streak (qx_ach_streak: QuadEXQ engine; elsewhere every clear is the 1st)
		qx_st_streak = 1;
		if (qx_newengine)
			qx_st_streak = cvar ("qx_ach_streak") + 1;
		sc = sc + QX_SC_NODEATH * qx_st_streak;
	}
	if (sc < 0)
		sc = 0;
	return sc;
};

// ---------------------------------------------------------------- the run
// A run is a game from New Game on, over every loop (the end text's
// ONE MORE TIME?). Its score adds up in qx_run_cur; the best is qx_hiscore,
// and every map keeps its own best (the engine's quadexq_scores.txt).
// QuadEXQ engine only (elsewhere these return 0).

void() QX_RunLoopTell;

float() QX_RunLoop =
{
	if (cvar ("qx_run_loop") < 1)
		return 1;
	return cvar ("qx_run_loop");
};

// add to this run's score: TRUE = past the high score
float(float pts) QX_RunAdd =
{
	local float r;

	if (!qx_newengine || deathmatch)
		return FALSE;
	r = cvar ("qx_run_cur") + pts;
	cvar_set ("qx_run_cur", ftos (r));
	if (r > cvar ("qx_hiscore"))
	{
		cvar_set ("qx_hiscore", ftos (r));
		return TRUE;
	}
	return FALSE;
};

// the start map (QX_StatStart, self = player): a loop, or a new run?
void() QX_RunStart =
{
	local float n;
	local entity e;

	if (!qx_newengine || deathmatch)
		return;
	if (cvar ("qx_loopnext"))
	{	// round again (oldone.qc)
		cvar_set ("qx_loopnext", "0");
		n = cvar ("qx_run_loop");
		if (n < 1)
			n = 1;
		n = n + 1;
		cvar_set ("qx_run_loop", ftos (n));
		e = spawn ();					// say so once the player is in
		e.owner = self;
		e.cnt = n;
		e.think = QX_RunLoopTell;
		e.nextthink = time + 1.5;
	}
	else if (serverflags == 0 && cvar ("qx_mapdeaths") == 0)
	{	// New Game
		cvar_set ("qx_run_cur", "0");
		cvar_set ("qx_run_loop", "1");
	}
};

void() QX_RunLoopTell =
{
	QX_Center (self.owner, "LOOP ", ftos (self.cnt), "\n\nThe slipgates are open again.", "");
	remove (self);
};

// the player reached the exit (self = trigger, p = player)
void(entity p) QX_StatMapEnd =
{
	local entity e;
	local float i, t;

	if (deathmatch)
		return;
	if (qx_st_ended)
		return;
	if (world.model == "maps/start.bsp")
		return;
	qx_st_ended = 1;
	qx_st_endt = QX_RunTime (time);
	qx_st_score = QX_StatScore ();
	QX_AchMapEnd (qx_st_endt, qx_st_score);	// the run stats
	qx_st_runnew = QX_RunAdd (qx_st_score);		// this run, and the high score
	qx_st_mapnew = FALSE;
	qx_st_mapprev = 0;
	if (qx_newengine)
	{	// this map's best
		qx_st_mapprev = cvar ("qx_map_best");
		if (qx_st_score > qx_st_mapprev)
		{
			qx_st_mapnew = TRUE;
			localcmd ("qx_mapbest ");
			localcmd (ftos (qx_st_score));
			localcmd ("\n");
		}
	}

	qx_rep_to = p;
	QX_LB (); QX_LE ();
	QX_LB ();
	QX_LS ("=== ");
	QX_LS (mapname);
	QX_LS (" CLEAR   SCORE ");
	QX_LN (qx_st_score);
	QX_LS (" ===");
	QX_LE ();
	if (qx_st_streak)
	{
		QX_LB ();
		QX_LS ("  NO DEATHS: ");
		QX_LN (qx_st_streak);
		QX_LS (" in a row  +");
		QX_LN (QX_SC_NODEATH * qx_st_streak);
		QX_LE ();
	}
	if (qx_newengine)
	{
		QX_LB ();
		QX_LS ("  RUN SCORE ");
		QX_LN (cvar ("qx_run_cur"));
		QX_LS ("  (loop ");
		QX_LN (QX_RunLoop ());
		QX_LS (")   HIGH SCORE ");
		QX_LN (cvar ("qx_hiscore"));
		QX_LS ("   map best ");
		if (qx_st_mapnew)
			QX_LN (qx_st_score);
		else
			QX_LN (qx_st_mapprev);
		QX_LE ();
		if (qx_st_runnew || qx_st_mapnew)
		{
			QX_LB ();
			if (qx_st_runnew)
				QX_LS ("  *** NEW HIGH SCORE! ***");
			if (qx_st_mapnew)
			{
				QX_LS ("  *** MAP BEST! ***");
				if (qx_st_mapprev > 0)
				{
					QX_LS (" (was ");
					QX_LN (qx_st_mapprev);
					QX_LS (")");
				}
			}
			QX_LE ();
		}
	}

	QX_LB ();
	QX_LS ("  time ");
	QX_LT (qx_st_endt);
	QX_LS ("   deaths ");
	QX_LN (QX_MapDeaths ());
	QX_LS ("   PlayerSkill ");
	QX_LN (qx_st_skill0);
	QX_LS (" -> ");
	QX_LN (qx_pskill);
	QX_LE ();

	QX_LB ();
	QX_LS ("  kills ");
	QX_LN (killed_monsters);
	QX_LS ("/");
	QX_LN (total_monsters);
	QX_LS ("  (by you ");
	QX_LN (qx_st_kills);
	if (qx_st_delta)
	{
		QX_LS (", Delta team ");
		QX_LN (qx_st_delta);
	}
	QX_LS (", elite ");
	QX_LN (qx_st_elites);
	QX_LS (", scout ");
	QX_LN (qx_st_scouts);
	QX_LS (")   secrets ");
	QX_LN (found_secrets);
	QX_LS ("/");
	QX_LN (total_secrets);
	QX_LE ();

	QX_LB ();
	if (qx_st_bossname != "")
	{
		QX_LS ("  boss ");
		QX_LS (qx_st_bossname);
		QX_LS (" at ");
		QX_LT (qx_st_bosst);
	}
	else
		QX_LS ("  boss -");
	QX_LS ("   bullet time ");
	QX_LN (qx_st_slow);
	QX_LS ("s   jets ");
	QX_LN (qx_st_jets);
	if (qx_st_deflects)
	{
		QX_LS ("   deflects ");
		QX_LN (qx_st_deflects);
	}
	QX_LE ();

	QX_LB ();
	QX_LS ("  damage dealt ");
	QX_LN (qx_st_dealt);
	QX_LS ("   taken ");
	QX_LN (qx_st_taken);
	QX_LE ();

	QX_LB ();
	QX_LS ("  weapon        held  firing  hits   damage kills  dps(firing)");
	QX_LE ();
	i = 1;
	while (i <= 13)
	{
		e = qx_ws_list;
		while (e)
		{
			if (e.qx_ws_id == i)
			if (e.qx_ws_held >= 1 || e.qx_ws_dmg > 0)
			{
				QX_LB ();
				QX_LS ("  ");
				QX_LS (QX_WName (i));
				QX_LS ("  ");
				QX_LT (e.qx_ws_held);
				QX_LS ("  ");
				QX_LT (e.qx_ws_fire);
				QX_LS ("  ");
				QX_LN (e.qx_ws_hits);
				QX_LS ("  ");
				QX_LN (e.qx_ws_dmg);
				QX_LS ("  ");
				QX_LN (e.qx_ws_kills);
				QX_LS ("  ");
				t = e.qx_ws_fire;
				if (t < 1)
					t = 1;
				QX_LN (e.qx_ws_dmg / t);
				QX_LE ();
			}
			e = e.enemy;
		}
		i = i + 1;
	}
	qx_rep_to = world;
	if (p.ishuman)
		qx_sprint4 (p, "(toggle the console to read the full report)\n", "", "", "");

	// ---- intermission card (QuadEXQ engine)
	if (!qx_persist)
		return;
	localcmd ("qx_statcard clear\n");
	QX_CB ("score"); QX_LN (qx_st_score); QX_CE ();

	QX_CB ("text");
	QX_LS ("TIME "); QX_LT (qx_st_endt);
	QX_LS ("   KILLS "); QX_LN (qx_st_kills);
	QX_LS ("   DEATHS "); QX_LN (QX_MapDeaths ());
	QX_CE ();

	QX_CB ("text");
	QX_LS ("SECRETS "); QX_LN (found_secrets); QX_LS ("/"); QX_LN (total_secrets);
	QX_LS ("   PlayerSkill "); QX_LN (qx_st_skill0); QX_LS (" -> "); QX_LN (qx_pskill);
	QX_CE ();

	if (qx_st_bossname != "")
	{
		QX_CB ("text");
		QX_LS ("BOSS DOWN AT "); QX_LT (qx_st_bosst);
		QX_CE ();
	}

	QX_CB ("text");
	QX_LS ("RUN "); QX_LN (cvar ("qx_run_cur"));
	QX_LS ("  LOOP "); QX_LN (QX_RunLoop ());
	if (qx_st_streak)
	{
		QX_LS ("  NO DEATHS x"); QX_LN (qx_st_streak);
	}
	QX_CE ();
	if (qx_st_runnew || qx_st_mapnew)
	{	// a record: in gold
		QX_CB ("text");
		QX_LS ("*");
		if (qx_st_runnew)
			QX_LS ("NEW HIGH SCORE!  ");
		if (qx_st_mapnew)
			QX_LS ("MAP BEST!");
		QX_CE ();
	}

	QX_CB ("row"); QX_LS ("WEAPON|TIME|DMG|KILL|DPS"); QX_CE ();
	i = 1;
	while (i <= 13)
	{
		e = qx_ws_list;
		while (e)
		{
			if (e.qx_ws_id == i)
			if (e.qx_ws_held >= 1 || e.qx_ws_dmg > 0)
			{
				t = e.qx_ws_fire;
				if (t < 1)
					t = 1;
				QX_CB ("row");
				QX_LS (QX_WName (i)); QX_LS ("|");
				QX_LT (e.qx_ws_held); QX_LS ("|");
				QX_LN (e.qx_ws_dmg); QX_LS ("|");
				QX_LN (e.qx_ws_kills); QX_LS ("|");
				QX_LN (e.qx_ws_dmg / t);
				QX_CE ();
			}
			e = e.enemy;
		}
		i = i + 1;
	}
};

// IntermissionThink hook. Up to v0.2 this re-sent a centerprint score card;
// the QuadEXQ engine now draws the full card itself (qx_statcard), so it is empty.
void() QX_StatInterFrame =
{
};
