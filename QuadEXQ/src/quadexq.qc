/*
==============================================================================
QuadEXQ core  (compiled last, after every monster)

  1. Modern aim   : QX_AutoAim / QX_ManualAim (hooked from frikbot's aim())
  2. Adrenaline   : QX_PlayerFrame / QX_PlayerPreBoost / QX_PlayerUnboost
  3. Smart enemies: QX_AIHook / QX_AIRun (dodge, jet knight, elite),
                    revenants (QX_ScheduleRevive)
  4. PlayerSkill  : QX_SetSkill, kill / time gain, death penalty, status log

  impulse 150 : print PlayerSkill / adrenaline status
  impulse 151 : reset PlayerSkill to 0
==============================================================================
*/

void() FoundTarget;
float(entity targ) visible;
float() crandom;

// ======================================================================
// small helpers
// ======================================================================

float() QX_F =
{
	return qx_pskill / QX_SKILL_MAX;	// 0 .. 1
};

void(entity e, string a, string b, string c, string d) QX_Msg =
{
	if (e.ishuman)
		qx_sprint4 (e, a, b, c, d);
};

void(entity e, string a, string b, string c, string d) QX_Center =
{
	if (e.ishuman)
		qx_cprint4 (e, a, b, c, d);
};

void(string a, string b, string c, string d) QX_MsgAll =
{
	local entity p;
	p = find (world, classname, "player");
	while (p)
	{
		QX_Msg (p, a, b, c, d);
		p = find (p, classname, "player");
	}
};

void(string a, string b, string c, string d) QX_CenterAll =
{
	local entity p;
	p = find (world, classname, "player");
	while (p)
	{
		QX_Center (p, a, b, c, d);
		p = find (p, classname, "player");
	}
};

entity() QX_FindLivePlayer =
{
	local entity p;
	p = find (world, classname, "player");
	while (p)
	{
		if (p.health > 0)
		if (p.flags & FL_CLIENT)
			return p;
		p = find (p, classname, "player");
	}
	return world;
};

// ======================================================================
// 4. PlayerSkill
// ======================================================================

void(float v) QX_SetSkill =
{
	local float tier;

	if (v < 0)
		v = 0;
	if (v > QX_SKILL_MAX)
		v = QX_SKILL_MAX;
	if (qx_pskill <= QX_SNG_HOMING_SKILL)
	if (v > QX_SNG_HOMING_SKILL)
		QX_MsgAll ("Super Nailgun: HOMING NAILS online\n", "", "", "");
	qx_pskill = v;				// fractions are kept (log-like curve)
	if (!qx_skillvar)
		qx_skillvar = "temp1";
	cvar_set (qx_skillvar, ftos (qx_pskill + 1));	// survives death-restart, changelevel (and restarts on QuadEXQ engine)
	qx_skill_written = qx_pskill + 1;

	tier = floor (qx_pskill / 10);
	if (tier > qx_lasttier)
	{
		if (qx_pskill >= QX_SKILL_MAX)
		{
			QX_CenterAll ("!!! PLAYER SKILL MAX !!!\n\nONLY ELITES REMAIN", "", "", "");
			QX_MsgAll ("PlayerSkill MAX: every enemy is now an elite\n", "", "", "");
			stuffcmd (QX_FindLivePlayer (), "bf\n");
		}
		else
		{
			QX_CenterAll ("PLAYER SKILL ", ftos (floor (qx_pskill)), "\n\nthe enemies grow stronger...", "");
			QX_MsgAll ("PlayerSkill up: ", ftos (floor (qx_pskill)), " / 100\n", "");
		}
	}
	qx_lasttier = tier;
};

// Gains shrink as PlayerSkill climbs: rate = (100 - skill) / 100, floor QX_SKILL_MINRATE.
// 0 -> 50 is quick, 90 -> 100 is a long grind. Penalties stay flat.
float() QX_GainRate =
{
	local float rate;
	rate = (QX_SKILL_MAX - qx_pskill) / QX_SKILL_MAX;
	if (rate < QX_SKILL_MINRATE)
		rate = QX_SKILL_MINRATE;
	return rate;
};

void(float g) QX_GainSkill =
{
	QX_SetSkill (qx_pskill + g * QX_GainRate ());
};

// starting PlayerSkill from the difficulty chosen in the menu / start map
float() QX_StartSkill =
{
	local float s;
	s = floor (cvar ("skill"));
	if (s < 0)
		s = 0;
	if (s > 3)
		s = 3;
	return s * QX_START_PER_SKILL;
};

void() QX_WorldSpawn =
{
	local float v;

	skill = QX_BASE_SKILL;		// before any spawn function looks at it

	qx_maptrack = world.sounds;	// the map's own soundtrack, restored after the boss
	qx_bossmusic = FALSE;

	qx_timescale = 0;			// force the cvars back to normal
	QX_SetTimescale (1);

	// Where PlayerSkill lives (value + 1; below 1 = nothing stored yet):
	//  QuadEXQ engine: "qx_playerskill", archived in config.cfg -> kept across sessions
	//  other engines : "temp1", kept only while the game is running
	if (cvar ("qx_playerskill") != 0)	// the cvar exists (default -1)
	{
		qx_skillvar = "qx_playerskill";
		qx_persist = TRUE;
	}
	else
	{
		qx_skillvar = "temp1";
		qx_persist = FALSE;
	}
	qx_skill_seen = floor (cvar ("skill"));

	v = cvar (qx_skillvar);
	if (v < 1)
		qx_pskill = QX_StartSkill ();	// first time: start from the difficulty
	else
		qx_pskill = v - 1;
	QX_SetSkill (qx_pskill);
	qx_lasttier = floor (qx_pskill / 10);

	// Quake's own skill (and EXQ's monster swaps: Juggernaut, Cyberdemon...)
	// follows PlayerSkill: / 32 -> 0 easy .. 3 nightmare at 96+. Set before
	// any monster spawns, kept for the whole map, worked out again after a death.
	qx_exq_skill = QX_ExqSkillFor (qx_pskill);
	skill = qx_exq_skill;
	qx_skill_deaths = cvar ("qx_mapdeaths");

	// newer QuadEXQ engine: safe checkpoints (qx_autosave_ok defaults to 1, 0 = no such cvar)
	// (qx_autosave_ok alone was not enough: the progs sets it to 0 while it is
	// unsafe to save - in an arena, or while dead - and a map started right
	// then looked like an old engine: no checkpoints, no revenge matches.
	// qx_playerskill is -1 or more on the QuadEXQ engine and 0 elsewhere.)
	qx_newengine = (cvar ("qx_autosave_ok") != 0 || cvar ("qx_playerskill") != 0);

	// Rune Hunter duel: arena items can appear on any map (practice duels)
	precache_model ("progs/armor.mdl");
	precache_sound ("items/armor1.wav");
	precache_sound ("items/itembk2.wav");
	precache_model ("progs/g_rock.mdl");		// arena weapons and health
	precache_model ("progs/g_rock2.mdl");
	precache_model ("progs/g_nail2.mdl");
	precache_model ("progs/g_light.mdl");
	precache_model ("maps/b_bh25.bsp");
	precache_sound ("items/health1.wav");
	precache_sound ("weapons/pkup.wav");
	precache_model ("progs/g_shot.mdl");		// start.bsp deathmatch layout
	precache_model ("progs/g_nail.mdl");
	precache_model ("progs/quaddama.mdl");
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	precache_model ("maps/b_bh100.bsp");
	precache_sound ("items/r_item2.wav");
	precache_model ("maps/b_bh10.bsp");
	precache_sound ("items/r_item1.wav");
	precache_model ("maps/b_shell0.bsp");
	precache_model ("maps/b_shell1.bsp");
	precache_model ("maps/b_nail0.bsp");
	precache_model ("maps/b_nail1.bsp");
	precache_model ("maps/b_rock0.bsp");
	precache_model ("maps/b_rock1.bsp");
	precache_model ("maps/b_batt0.bsp");
	precache_model ("maps/b_batt1.bsp");
	precache_sound ("weapons/lock4.wav");

	// Runes work as in stock Quake: they live in the game and in its savegames
	// (CONTINUE keeps them, NEW GAME starts without them).

	QX_ArenaInit ();			// arrived here for a Rune Hunter duel?
};

// switch every client's music track (CD audio or Mark V music/trackNN.mp3)
void(float track) QX_PlayTrack =
{
	WriteByte (MSG_ALL, SVC_CDTRACK);
	WriteByte (MSG_ALL, track);	// play
	WriteByte (MSG_ALL, track);	// loop
};

void() QX_BossMusicThink =
{
	local entity p;

	if (qx_bossmusic)
		return;
	if (!qx_boss)
		return;
	if (!qx_boss.qx_isboss || qx_boss.health <= 0)
		return;

	// QuadEXQ: the theme starts when the boss has spotted you (it hunts a
	// player and can see him), not just when you come near it: being near
	// often meant the music ran long before the fight did
	p = qx_boss.enemy;
	if (p.flags & FL_CLIENT)
	if (p.health > 0)
	{
		traceline (qx_boss.origin + qx_boss.view_ofs, p.origin + p.view_ofs, TRUE, qx_boss);
		if (trace_fraction == 1)
		{
			qx_bossmusic = TRUE;		// once triggered it stays until the boss dies
			QX_PlayTrack (QX_BOSS_MUSIC_TRACK);
			// the big entrance: banner + flash for everyone, right as the theme kicks in
			QX_CenterAll ("!!! BOSS !!!\n\n", qx_boss.classname, "", "");
			p = find (world, classname, "player");
			while (p)
			{
				stuffcmd (p, "bf\n");
				p = find (p, classname, "player");
			}
			qx_boss.qx_announced = 1;	// no second banner when it spots you
			return;
		}
	}
};

// ---- Vore (shalrath) splitting: each split halves the health it has left and
// shares it with the new one; one Vore family splits at most QX_VORE_SPLITS times.
float(entity v) QX_VoreCanSplit =
{
	local entity root;

	root = v.qx_vroot;		// family root (the Vore that was placed on the map)
	if (!root)
		root = v;
	return (root.qx_splits < QX_VORE_SPLITS);
};

void(entity parent, entity child) QX_VoreSplit =
{
	local entity root;

	root = parent.qx_vroot;
	if (!root)
		root = parent;
	root.qx_splits = root.qx_splits + 1;

	parent.health = floor (parent.health * 0.5);
	child.health = parent.health;
	child.qx_vroot = root;

	// already scaled to PlayerSkill: don't let QX_MonsterSync scale it again
	child.qx_init = 1;
	child.qx_hpmul = parent.qx_hpmul;
	child.qx_basehp = child.health / parent.qx_hpmul;
	child.qx_tier = parent.qx_tier;
	child.qx_tempo = parent.qx_tempo;
	child.qx_spawnclass = "monster_shalrath";
};

// armored knights: bullets do half, nails pierce (x QX_NAIL_PIERCE)
float(entity e) QX_Armored =
{
	local string c;
	c = e.classname;
	if (c == "monster_lord" || c == "monster_bane" || c == "monster_super_hknight" || c == "monster_aknight")
		return TRUE;
	return FALSE;
};

// ---------------------------------------------------------------- monsters in slime / lava
// Stock Quake never hurts monsters in liquids, so a boss knocked into lava
// could swim away forever. Damage is a share of the monster's full health
// so it works the same for a grunt and for a 6000 HP elite boss.

float(entity m) QX_LiquidLevel =		// 0 none, 1 feet, 2 waist, 3 under (lava / slime only)
{
	local float c, lvl;
	local vector p;

	lvl = 0;
	p = m.origin;
	p_z = m.absmin_z + 1;
	c = pointcontents (p);
	if (c != CONTENT_LAVA && c != CONTENT_SLIME)
		return 0;
	qx_liq_type = c;
	lvl = 1;
	p_z = (m.absmin_z + m.absmax_z) * 0.5;
	if (pointcontents (p) == c)
	{
		lvl = 2;
		p_z = m.absmax_z - 2;
		if (pointcontents (p) == c)
			lvl = 3;
	}
	return lvl;
};

void(entity m) QX_MonsterLiquid =
{
	local float lvl, full, d;
	local string c;

	if (m.health <= 0 || !m.takedamage)
		return;
	if (m.flags & FL_SWIM)		// fish / eels live in it
		return;
	c = m.classname;
	if (c == "monster_boss" || c == "monster_oldone")
		return;				// Chthon stands in lava, Shub is scripted

	lvl = QX_LiquidLevel (m);
	if (!lvl)
		return;

	full = m.health;
	if (m.qx_init)
	if (m.qx_basehp > 0)
		full = m.qx_basehp * m.qx_hpmul;

	// per 0.2s, fully under: lava 4% (= 20%/s, dead in ~5s), slime 1% (= 5%/s)
	if (qx_liq_type == CONTENT_LAVA)
		d = full * QX_LIQ_LAVA * lvl / 3;
	else
		d = full * QX_LIQ_SLIME * lvl / 3;
	if (qx_liq_type == CONTENT_LAVA)
	{
		if (d < 6)
			d = 6;
		if (c == "monster_zombie" || c == "monster_mummy")
			d = 200;			// only gibbing kills a zombie
	}
	else if (d < 2)
		d = 2;

	if (m.qx_liq_next < time)		// sizzle now and then
	{
		if (!m.qx_liq_next)
		if (m.qx_isboss)
			QX_MsgAll ("The boss fell in and is burning!\n", "", "", "");
		m.qx_liq_next = time + 1;
		if (qx_liq_type == CONTENT_LAVA)
			sound (m, CHAN_BODY, "player/lburn1.wav", 1, ATTN_NORM);
	}
	T_Damage (m, world, world, d);
};

void() QX_MonstersInLiquid =
{
	local entity m;

	if (time < qx_liq_time)
		return;
	qx_liq_time = time + 0.2;
	m = nextent (world);
	while (m)
	{
		if (m.flags & FL_MONSTER)
			QX_MonsterLiquid (m);
		m = nextent (m);
	}
};

// ---------------------------------------------------------------- safe checkpoints
// The QuadEXQ engine only autosaves while qx_autosave_ok is 1, and a death loads
// that autosave (qx_respawn). So: only save when it is calm.
float() QX_SafeToSave =
{
	local entity p, m;

	p = QX_FindLivePlayer ();
	if (!p)
		return FALSE;
	if (p.health < QX_SAVE_MIN_HEALTH)
		return FALSE;
	if (!(p.flags & FL_ONGROUND))
		return FALSE;
	if (p.waterlevel >= 2 || (p.waterlevel && p.watertype != CONTENT_WATER))
		return FALSE;				// swimming, or standing in slime / lava
	if (time - p.qx_lastpain < 4)
		return FALSE;				// hurt a moment ago
	if (qx_timescale < 1)
		return FALSE;				// bullet time = a fight is on
	if (qx_duel)
		return FALSE;				// Rune Hunter duel
	if (qx_arena || qx_arena_go)
		return FALSE;				// in (or on the way to) a duel arena
	m = findradius (p.origin, 1000);
	while (m)
	{
		if (m.flags & FL_MONSTER)
		if (m.health > 0)
		if (m.enemy == p)
		{
			traceline (m.origin + m.view_ofs, p.origin + p.view_ofs, TRUE, m);
			if (trace_fraction == 1)
				return FALSE;		// something can see you and wants you dead
		}
		if (m.classname == "qx_revive")
		if (m.think == QX_RiftCrackle)
			return FALSE;			// reinforcements about to arrive
		m = m.chain;
	}
	return TRUE;
};

void() QX_SaveGate =
{
	local float ok;

	// re-checked every frame: a savegame can bring back an old FALSE
	if (!qx_newengine)
		qx_newengine = (cvar ("qx_playerskill") != 0);
	if (!qx_newengine || deathmatch || coop)
		return;
	if (time < qx_safe_time)
		return;
	qx_safe_time = time + 0.25;
	ok = QX_SafeToSave ();
	if (ok != cvar ("qx_autosave_ok"))
		cvar_set ("qx_autosave_ok", ftos (ok));
};

float(float ps) QX_ExqSkillFor =
{
	local float k;

	k = floor (ps / 32);
	if (k > 3)	k = 3;
	if (k < 0)	k = 0;
	return k;
};

// after a death (also seen after the checkpoint load: the save holds the old
// count) the skill is worked out again from the PlayerSkill you have now
void() QX_ExqSkillSync =
{
	local float d, ps;

	d = cvar ("qx_mapdeaths");
	if (d == qx_skill_deaths)
		return;
	qx_skill_deaths = d;
	ps = qx_pskill;
	if (cvar (qx_skillvar) >= 1)
		ps = cvar (qx_skillvar) - 1;		// the cvar wins after a load
	qx_exq_skill = QX_ExqSkillFor (ps);
	skill = qx_exq_skill;
};

void() QX_StartFrame =
{
	local float v;

	QX_ExqSkillSync ();
	if (!deathmatch)
		QX_BossMusicThink ();

	QX_SaveGate ();

	QX_MonstersInLiquid ();
	QX_DuelThink ();

	if (!qx_boss_picked)
	if (time > 2)
	if (QX_FindLivePlayer ())
		QX_PickBoss ();

	if (!deathmatch && !coop)
	if (intermission_running || !QX_FindLivePlayer ())
		QX_SetTimescale (1);

	// start map: stepping on a difficulty pad (skill changes) resets PlayerSkill
	// to that difficulty. Just walking into start.bsp keeps your PlayerSkill.
	if (world.model == "maps/start.bsp")
	if (floor (cvar ("skill")) != qx_skill_seen)
	{
		qx_skill_seen = floor (cvar ("skill"));
		QX_SetSkill (QX_StartSkill ());
		QX_MsgAll ("Difficulty changed: PlayerSkill reset to ", ftos (floor (qx_pskill)), "\n", "");
	}

	// autosave shortly after a boss dies (QuadEXQ engine "autosave" command)
	if (qx_autosave_at)
	if (time > qx_autosave_at)
	if (QX_FindLivePlayer ())
	if (!intermission_running)
	{
		qx_autosave_at = 0;
		localcmd ("autosave\n");
		QX_MsgAll ("Autosaved\n", "", "", "");
	}

	// keep the cvar in sync
	if (time > qx_cvar_time)
	{
		qx_cvar_time = time + 1;
		// A loaded savegame brings back its old qx_pskill, but PlayerSkill is
		// global: if the cvar no longer holds what this game last wrote (e.g. a
		// death penalty after the save was made), the cvar wins.
		v = cvar (qx_skillvar);
		if (qx_skill_written > 0)
		if (v >= 1)
		if (fabs (v - qx_skill_written) > 0.15)
		{
			qx_pskill = v - 1;
			qx_lasttier = floor (qx_pskill / 10);
		}
		cvar_set (qx_skillvar, ftos (qx_pskill + 1));
		qx_skill_written = qx_pskill + 1;
		// re-assert the clock (a loaded savegame restores qx_timescale, not the cvars)
		if (!deathmatch && !coop)
		if (qx_timescale > 0)
		{
			cvar_set ("host_timescale", ftos (qx_timescale));
			cvar_set ("sv_accelerate", ftos (10 / qx_timescale));
			cvar_set ("sv_friction", ftos (4 / qx_timescale));
		}
	}
};

void() QX_ShowStatus =
{
	local float f;

	f = QX_F ();
	QX_Msg (self, "\n-- QuadEXQ status --\n", "", "", "");
	QX_Msg (self, "PlayerSkill  : ", ftos (floor (qx_pskill)), " / 100\n", "");
	QX_Msg (self, "  gain rate  : ", ftos (floor (100 * QX_GainRate ())), "%\n", "");
	QX_Msg (self, "  start value: ", ftos (QX_StartSkill ()), " (from difficulty)\n", "");
	QX_Msg (self, "Enemy HP     : x", ftos (1 + f), "\n", "");
	QX_Msg (self, "Your damage  : x", ftos (1 + QX_PLAYER_DMG_SCALE * f), " (vs enemies)\n", "");
	QX_Msg (self, "Enemy damage : x", ftos (1 + 0.5 * f), "\n", "");
	QX_Msg (self, "Enemy speed  : x", ftos (1 + 0.5 * f), "\n", "");
	QX_Msg (self, "Adrenaline   : ", ftos (floor (self.qx_adren)), "%", "");
	QX_Msg (self, "  (", ftos (floor (self.qx_amult * 100)), "%", "");
	QX_Msg (self, "  world time x", ftos (qx_timescale), ")\n", "");
	QX_Msg (self, "Kills (life) : ", ftos (self.qx_kills), "\n", "");
	if (qx_boss)
	if (qx_boss.qx_isboss)
	if (qx_boss.health > 0)
	{
		QX_Msg (self, "BOSS         : ", qx_boss.classname, "", "");
		QX_Msg (self, "  (", ftos (floor (vlen (qx_boss.origin - self.origin))), " units away)\n", "");
	}
};

void() QX_PlayerSpawned =
{
	// back after a death on this map: restart with at least 100 health
	// (the level-start values could be very low, e.g. 71 HP / 7 armor)
	if (!deathmatch && !coop)
	if (qx_persist)
	if (cvar ("qx_mapdeaths") > 0)
	if (self.health < QX_RESTART_HEALTH)
		self.health = QX_RESTART_HEALTH;

	self.qx_adren = QX_ADREN_MIN;
	self.qx_amult = 1 + 2 * QX_ADREN_MIN / 100;
	self.qx_vmul = 0;
	self.gravity = 1;
	self.qx_jets = 0;
	self.qx_hs_full = 0;			// re-send the whole HUD
	self.qx_lastpain = time;		// no instant regen right after spawning
	self.qx_lastfire = 0;
	self.qx_regen_on = 0;
	self.qx_meleeing = 0;
	self.qx_melee_next = 0;
	self.qx_adren_shown = 0;
	self.qx_nt_seen = 0;
	self.qx_af_seen = 0;
	self.qx_alive_time = 0;
	self.qx_kills = 0;
	if (!deathmatch)
		QX_Msg (self, "QuadEXQ  PlayerSkill ", ftos (floor (qx_pskill)), " / 100   (impulse 150 = status)\n", "");
	QX_StatStart ();
};

void() QX_PlayerDied =
{
	local float old;

	self.qx_adren = 0;
	self.qx_amult = 1;
	self.qx_adren_shown = 0;
	self.gravity = 1;
	if (!deathmatch && !coop)
		QX_SetTimescale (1);		// dying ends bullet time at once
	if (deathmatch)
		return;
	if (!self.ishuman)
		return;

	if (qx_duel)
	{	// Rune Hunter duel: just a frag for the hunter, no penalty
		QX_HunterScored ();
		return;
	}

	old = qx_pskill;
	QX_SetSkill (qx_pskill - QX_SKILL_DEATH);
	// (ftos shares one buffer in classic engines: one number per print)
	QX_Msg (self, "PlayerSkill ", ftos (floor (old)), "", "");
	QX_Msg (self, " -> ", ftos (floor (qx_pskill)), "", "");
	QX_Msg (self, "   (died after ", ftos (self.qx_kills), " kills)\n", "");
	QX_StatDeath (old);
	self.qx_alive_time = 0;
	self.qx_kills = 0;
	QX_RevengeRoll ();			// the Rune Hunter may offer a revenge match
};

// ======================================================================
// 2. Adrenaline = bullet time
// ======================================================================
//
// Gauge 0..100 shows as 100%..300%. From 150% up the WORLD slows down
// (engine host_timescale, Mark V / QuakeSpasm), down to x0.5 at 300%.
// Quad Damage = 400% = x0.4. The player is compensated so he keeps
// moving / shooting at normal real-time speed:
//
//   * velocity x 1/s between PreThink and PostThink (the engine moves the
//     player inside that window), gravity field x 1/s^2
//   * sv_accelerate / sv_friction x 1/s (they run on game time)
//   * player animation + attack_finished x s
//
// Single player only (one shared clock).

float(float a, float q) QX_TimescaleFor =
{
	local float s;
	if (q)
		return QX_QUAD_TIMESCALE;
	if (a <= QX_SLOW_START)
		return 1;
	s = 1 - (1 - QX_SLOW_MIN) * (a - QX_SLOW_START) / (3 - QX_SLOW_START);
	if (s < QX_SLOW_MIN)
		s = QX_SLOW_MIN;
	s = floor (s * 10 + 0.5) / 10;	// 0.1 steps (ftos prints one decimal)
	return s;
};

void(float s) QX_SetTimescale =
{
	local entity p;

	if (s == qx_timescale)
		return;
	qx_timescale = s;
	cvar_set ("host_timescale", ftos (s));
	cvar_set ("sv_accelerate", ftos (10 / s));
	cvar_set ("sv_friction", ftos (4 / s));
	if (s >= 1)
	{
		p = find (world, classname, "player");
		while (p)
		{
			p.gravity = 1;
			p = find (p, classname, "player");
		}
	}
};

void() QX_PlayerPreBoost =
{
	local float c;

	self.qx_vmul = 0;
	if (self.health <= 0 || qx_timescale >= 0.999 || qx_timescale <= 0)
	{
		self.gravity = 1;
		return;
	}
	c = 1 / qx_timescale;
	self.velocity = self.velocity * c;
	self.gravity = c * c;
	self.qx_vmul = c;
};

void() QX_PlayerUnboost =
{
	if (!self.qx_vmul)
		return;
	self.velocity = self.velocity * (1 / self.qx_vmul);
	self.qx_vmul = 0;
};

// ---------------------------------------------------------------- air jet
// Jump again in mid-air = jetpack burst. QX_JET_MAX bursts per airtime.
void() QX_AirJet =
{
	local vector f;

	if (self.flags & FL_ONGROUND)
	{
		self.qx_jets = 0;
		return;
	}
	if (!self.qx_hasjet)
		return;				// find a jet knight's backpack first
	if (!self.button2)
		return;
	if (!(self.flags & FL_JUMPRELEASED))
		return;
	if (self.waterlevel >= 2)
		return;
	if (self.health <= 0)
		return;
	if (self.qx_jets >= QX_JET_MAX)
		return;

	self.qx_jets = self.qx_jets + 1;
	qx_st_jets = qx_st_jets + 1;
	self.flags = self.flags - FL_JUMPRELEASED;

	if (self.velocity_z < 0)
		self.velocity_z = 0;
	self.velocity_z = self.velocity_z + QX_JET_UP;
	if (self.velocity_z > 600)
		self.velocity_z = 600;
	makevectors (self.v_angle);
	f = v_forward;
	f_z = 0;
	self.velocity = self.velocity + normalize (f) * 60;
	self.jump_flag = 0;			// no fall damage from the old fall

	sound (self, CHAN_BODY, "hknight/attack1.wav", 1, ATTN_NORM);
	particle (self.origin - '0 0 24', '0 0 -150', 230, 40);
	if (self.qx_jets == QX_JET_MAX)
		QX_Center (self, "JET EMPTY", "", "", "");
};

// ---------------------------------------------------------------- auto melee
float(float amin, float amax, float bmin, float bmax) QX_AxisGap =
{
	if (bmin > amax)
		return bmin - amax;
	if (amin > bmax)
		return amin - bmax;
	return 0;
};

// An enemy right in your face (box gap < QX_MELEE_GAP) gets the axe / fist
// automatically. Your weapon stays selected, but you can't shoot meanwhile.
void() QX_AutoMelee =
{
	local entity e, best;
	local vector f, d, g;
	local float gap, bestgap;

	if (!self.ishuman)
		return;
	if (self.health <= 0)
		return;
	if (self.qx_meleeing)
		return;
	if (time < self.attack_finished)
		return;
	if (time < self.qx_melee_next)
		return;
	if (self.weapon == IT_AXE)
		return;					// already melee: the fire button does it

	makevectors (self.v_angle);
	f = v_forward;
	f_z = 0;
	f = normalize (f);

	best = world;
	bestgap = QX_MELEE_GAP;
	e = findradius (self.origin, 200);
	while (e)
	{
		if (e.flags & FL_MONSTER)
		if (e.health > 0)
		if (e.takedamage)
		if (QX_AxisGap (self.absmin_z, self.absmax_z, e.absmin_z, e.absmax_z) < 8)
		{
			g = '0 0 0';
			g_x = QX_AxisGap (self.absmin_x, self.absmax_x, e.absmin_x, e.absmax_x);
			g_y = QX_AxisGap (self.absmin_y, self.absmax_y, e.absmin_y, e.absmax_y);
			gap = vlen (g);
			if (gap < bestgap)
			{
				d = e.origin - self.origin;
				d_z = 0;
				if (normalize (d) * f > 0.5)	// roughly in front, or the swing misses
				{
					bestgap = gap;
					best = e;
				}
			}
		}
		e = e.chain;
	}
	if (!best)
		return;

	sound (self, CHAN_VOICE, "player/taunt.wav", 1, ATTN_NORM);
	self.qx_meleeing = 1;
	self.weaponmodel = "progs/v_axe.mdl";
	sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
	player_axe1 ();
	self.attack_finished = time + 0.5;
	// a short window to shoot before the next auto swing
	self.qx_melee_next = self.attack_finished + 0.6;
};

// ---------------------------------------------------------------- engine HUD
// The QuadEXQ engine (quadexq.exe / patched Mark V) draws a HUD from client
// stats 20..26. Other engines just store them and ignore them.

void(float idx, float val) QX_Stat =
{
	msg_entity = self;
	WriteByte (MSG_ONE, 3);		// svc_updatestat
	WriteByte (MSG_ONE, idx);
	WriteLong (MSG_ONE, val);
};

void() QX_SendHUD =
{
	local float full, fl, v;
	local entity tgt;

	full = FALSE;
	if (time >= self.qx_hs_full)
	{
		full = TRUE;			// every 2s, and after spawn / load
		self.qx_hs_full = time + 2;
	}

	fl = 1;						// QX_F_ACTIVE
	if (self.qx_hasjet)
		fl = fl | 2;
	tgt = world;
	if (qx_boss)
	if (qx_boss.qx_isboss)
	if (qx_boss.health > 0)
		tgt = qx_boss;
	if (qx_duel)				// during a duel the compass finds the Rune Hunter
	if (qx_hunter)
	if (qx_hunter.health > 0)
	{
		tgt = qx_hunter;
		fl = fl | 32;			// QX_F_HUNTER
	}
	if (tgt)
		fl = fl | 4;
	if (self.super_damage_finished > time)
		fl = fl | 8;
	if (qx_pskill >= QX_SKILL_MAX)
		fl = fl | 16;
	if (full || fl != self.qx_hs_flags)
	{
		self.qx_hs_flags = fl;
		QX_Stat (20, fl);
	}

	v = floor (self.qx_adren);
	if (full || v != self.qx_hs_adren)
	{
		self.qx_hs_adren = v;
		QX_Stat (21, v);
	}

	v = floor (qx_pskill * 10);
	if (full || v != self.qx_hs_skill)
	{
		self.qx_hs_skill = v;
		QX_Stat (22, v);
	}

	v = 100;
	if (qx_timescale > 0)
		v = floor (qx_timescale * 100 + 0.5);
	if (full || v != self.qx_hs_time)
	{
		self.qx_hs_time = v;
		QX_Stat (23, v);
	}

	v = 0;
	if (self.qx_hasjet)
		v = QX_JET_MAX - self.qx_jets;
	if (full || v != self.qx_hs_jets)
	{
		self.qx_hs_jets = v;
		QX_Stat (24, v);
	}

	if (fl & 4)
	{
		v = floor (vectoyaw (tgt.origin - self.origin) / 5) * 5;
		if (full || v != self.qx_hs_byaw)
		{
			self.qx_hs_byaw = v;
			QX_Stat (25, v);
		}
		v = floor (vlen (tgt.origin - self.origin) / 10) * 10;
		if (full || v != self.qx_hs_bdist)
		{
			self.qx_hs_bdist = v;
			QX_Stat (26, v);
		}
	}

	// the duel score for the Tab scoreboard (QuadEXQ engine)
	v = 0;
	if (qx_duel)
		v = 4096 + qx_duel_pf + qx_duel_hf * 16 + QX_HunterIdx (qx_hunter_name) * 256;
	if (full || v != self.qx_hs_duel)
	{
		self.qx_hs_duel = v;
		QX_Stat (27, v);
	}
};

// ---------------------------------------------------------------- per frame
void() QX_PlayerFrame =
{
	local entity e;
	local float n, a, s, m, step, base, rdt;

	if (!self.ishuman)
		return;

	QX_StatTick ();

	// last safe footing: a revenge match / arena challenge brings you back here
	if (self.health > 0)
	if (!qx_arena && !qx_duel)
	if (self.flags & FL_ONGROUND)
	if (self.groundentity == world)
	if (!self.waterlevel)
	if (time > self.qx_safe_next)
	{
		self.qx_safe_next = time + 0.5;
		self.qx_safe_org = self.origin;
		self.qx_safe_ang = self.v_angle;
	}

	// end of an auto melee swing: bring the real weapon back
	if (self.qx_meleeing)
	if (time >= self.attack_finished)
	{
		self.qx_meleeing = 0;
		W_SetCurrentAmmo ();
	}

	rdt = frametime;			// real seconds this frame
	if (qx_timescale > 0)
	if (qx_timescale < 1)
		rdt = frametime / qx_timescale;

	// ---- health regen (from the old EXQ): hold fire and stay unhurt for a while
	//      and you catch your breath back up to QX_REGEN_CAP. Not with the
	//      Thunderbolt out (it turns health into cells instead).
	if (self.button0)
		self.qx_lastfire = time;
	if (self.weapon != IT_LIGHTNING)
	if (time - self.qx_lastpain > QX_REGEN_DELAY)
	if (time - self.qx_lastfire > QX_REGEN_DELAY)
	if (self.health < QX_REGEN_CAP)
	{
		if (!self.qx_regen_on)
		{
			self.qx_regen_on = 1;
			if (self.health < 20)
				sound (self, CHAN_BODY, "player/gasp2.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_BODY, "player/gasp1.wav", 1, ATTN_NORM);
		}
		if (self.health < 20)
			self.health = self.health + QX_REGEN_RATE * 2 * rdt;
		else
			self.health = self.health + QX_REGEN_RATE * rdt;
		if (self.health > QX_REGEN_CAP)
			self.health = QX_REGEN_CAP;
	}
	else
		self.qx_regen_on = 0;

	// ---- survival time -> PlayerSkill
	if (!deathmatch)
	{
		self.qx_alive_time = self.qx_alive_time + rdt;
		if (self.qx_alive_time >= QX_SKILL_TIME)
		{
			self.qx_alive_time = self.qx_alive_time - QX_SKILL_TIME;
			QX_GainSkill (1);
		}
	}

	// ---- adrenaline gauge (ticks every 0.2 REAL seconds)
	if (time >= self.qx_adren_tick)
	{
		s = qx_timescale;
		if (s <= 0)
			s = 1;
		self.qx_adren_tick = time + 0.2 * s;
		n = 0;
		e = findradius (self.origin, QX_ADREN_RANGE);
		while (e)
		{
			if (e.flags & FL_MONSTER)
			if (e.health > 0)
			{
				n = n + 1;
				if (e.qx_elite)
					n = n + 2;
			}
			e = e.chain;
		}
		// Hits taken and kills fill it. Alone: -10/sec. Enemies around but
		// nobody is hurting you: -5/sec (after a short grace period).
		if (n > 0)
		{
			self.qx_adren = self.qx_adren + QX_ADREN_GAIN * n;
			if (time - self.qx_lasthurt > QX_ADREN_GRACE)
				self.qx_adren = self.qx_adren - QX_ADREN_IDLE;
		}
		else
			self.qx_adren = self.qx_adren - QX_ADREN_DECAY;	// -10/sec when alone
		if (self.qx_adren > 100)
			self.qx_adren = 100;
		if (self.qx_adren < QX_ADREN_MIN)
			self.qx_adren = QX_ADREN_MIN;
		if (qx_duel)
		if (self.qx_adren < QX_DUEL_ADREN_MIN)
			self.qx_adren = QX_DUEL_ADREN_MIN;	// duel: never below 200% (world at 0.8x)

		step = floor (self.qx_adren / 25);
		if (step > self.qx_adren_shown)
		if (self.super_damage_finished < time)
		{
			if (step == 1)
				QX_Center (self, "ADRENALINE 150%\n[###.........]", "", "", "");
			else if (step == 2)
				QX_Center (self, "ADRENALINE 200%\n[######......]\ntime is slowing", "", "", "");
			else if (step == 3)
				QX_Center (self, "ADRENALINE 250%\n[#########...]\ntime is slowing", "", "", "");
			else
			{
				QX_Center (self, "!! ADRENALINE MAX 300% !!\n[############]\nBULLET TIME", "", "", "");
				stuffcmd (self, "bf\n");
			}
		}
		self.qx_adren_shown = step;
	}

	a = 1 + 2 * self.qx_adren / 100;		// 100% .. 300%
	if (self.super_damage_finished > time)
	{
		if (self.qx_amult < 3.99)
			QX_Center (self, "QUAD RUSH 400%\n\nthe world crawls", "", "", "");
		a = 4;						// the Quad rule
	}
	self.qx_amult = a;

	if (!deathmatch && !coop)
		QX_SetTimescale (QX_TimescaleFor (a, self.super_damage_finished > time));

	// ---- keep the player's own animation / refire at real-time speed
	if (qx_timescale > 0)
	if (qx_timescale < 0.999)
	{
		m = 1 / qx_timescale;
		if (self.nextthink > time)
		if (self.nextthink != self.qx_nt_seen)
		{
			base = time;
			if (self.qx_nt_seen > time - 0.2)
			if (self.qx_nt_seen <= time)
				base = self.qx_nt_seen;	// the frame actually started here
			self.nextthink = base + (self.nextthink - base) / m;
			self.qx_nt_seen = self.nextthink;
		}
		if (self.attack_finished > time)
		if (self.attack_finished != self.qx_af_seen)
		{
			self.attack_finished = time + (self.attack_finished - time) / m;
			self.qx_af_seen = self.attack_finished;
		}
	}

	QX_SendHUD ();
};

// ======================================================================
// 1. Aim
// ======================================================================

float(entity e) QX_UsesAutoAim =
{
	if (e.weapon == IT_SUPER_NAILGUN)
		return TRUE;
	if (e.weapon == IT_LIGHTNING)
		return TRUE;
	return FALSE;
};

// Own autoaim, so it works even on engines where sv_aim is off by default.
vector(entity e) QX_AutoAim =
{
	local entity t, best;
	local vector start, dir, mid;
	local float d, bestd, ok;

	makevectors (e.v_angle);
	start = e.origin + '0 0 16';
	bestd = 0.95;			// about 18 degrees
	best = world;

	t = findradius (e.origin, 2000);
	while (t)
	{
		ok = FALSE;
		if (t.flags & FL_MONSTER)
			ok = TRUE;
		if (deathmatch)
		if (t.flags & FL_CLIENT)
			ok = TRUE;
		if (t == e)
			ok = FALSE;
		if (t.health <= 0)
			ok = FALSE;
		if (t.takedamage != DAMAGE_AIM)
			ok = FALSE;
		if (t.classname == "monster_runehunter")	// Tres can't be locked
		if (t.qx_hskill >= 2)
			ok = FALSE;

		if (ok)
		{
			mid = t.origin + (t.mins + t.maxs) * 0.5;
			dir = normalize (mid - start);
			d = dir * v_forward;
			if (d > bestd)
			{
				traceline (start, mid, FALSE, e);
				if (trace_ent == t)
				{
					bestd = d;
					best = t;
				}
			}
		}
		t = t.chain;
	}

	if (best)
		return normalize ((best.origin + (best.mins + best.maxs) * 0.5) - start);
	return v_forward;
};

// No autoaim: you hit what the crosshair is on. Moving / airborne = spread.
vector(entity e) QX_ManualAim =
{
	local vector hv;
	local float spd, sp, m;

	makevectors (e.v_angle);
	hv = e.velocity;
	hv_z = 0;
	m = e.qx_vmul;			// bullet-time compensation isn't "sloppy"
	if (m < 1)
		m = 1;
	spd = vlen (hv) / (320 * m);
	if (spd > 1.2)
		spd = 1.2;
	sp = 0.004 + 0.045 * spd;
	if (!(e.flags & FL_ONGROUND))
		sp = sp + 0.035;
	return normalize (v_forward + v_right * crandom () * sp + v_up * crandom () * sp);
};

// ======================================================================
// 3. Smart enemies
// ======================================================================

float() QX_CanDodge =
{
	local string c;
	c = self.qx_spawnclass;
	if (c == "monster_boss" || c == "monster_oldone" || c == "monster_zombie")
		return FALSE;
	if (c == "monster_fish" || c == "monster_eel" || c == "monster_smine")
		return FALSE;
	if (c == "monster_mummy")
		return FALSE;
	return TRUE;
};

float() QX_CanElite =
{
	if (!self.th_missile)
		return FALSE;
	if (!QX_CanDodge ())
		return FALSE;
	if (self.qx_spawnclass == "monster_tarbaby")
		return FALSE;
	return TRUE;
};

void() QX_MakeElite =
{
	self.qx_elite = 1;
	self.effects = self.effects | EF_DIMLIGHT;
	// elite ogres wear the Tyrant Ogre skin
	if (self.qx_spawnclass == "monster_ogre" || self.qx_spawnclass == "monster_ogre_marksman")
		self.skin = 1;
};

// at PlayerSkill MAX anything but the big bosses turns elite
float() QX_CanEliteMax =
{
	local string c;
	c = self.qx_spawnclass;
	if (c == "monster_boss" || c == "monster_oldone" || c == "monster_smine")
		return FALSE;
	return TRUE;
};

float() QX_CanRevive =
{
	local string c;
	c = self.qx_spawnclass;
	if (c == "monster_boss" || c == "monster_oldone" || c == "monster_smine")
		return FALSE;
	if (self.qx_gen >= 2)
		return FALSE;
	return TRUE;
};

// roll variants once, then keep HP / tempo in step with PlayerSkill
void() QX_MonsterSync =
{
	local float tier, f, m;

	if (self.health <= 0)
		return;
	// Chthon / Shub: their "health" is a count of scripted hits (lightning,
	// telefrag), so PlayerSkill must not scale it
	if (self.classname == "monster_boss" || self.classname == "monster_oldone")
		return;
	if (self.classname == "monster_runehunter" || self.qx_delta)
		return;				// its stats are set when it spawns

	if (!self.qx_init)
	{
		self.qx_init = 1;
		self.qx_hpmul = 1;
		self.qx_tempo = 1;
		self.qx_basehp = self.health;
		if (!self.qx_spawnclass)
			self.qx_spawnclass = self.classname;
		if (self.qx_home == '0 0 0')
		{
			self.qx_home = self.origin;
			self.qx_homeang = self.angles;
			self.qx_homeflags = self.spawnflags;
		}

		f = QX_F ();
		if (!deathmatch)
		{
			if (self.qx_spawnclass == "monster_knight")
			if (random () < 0.3 + 0.4 * f)
			{
				self.qx_jet = 1;
				self.qx_jet_next = time + 1 + random () * 2;
			}
			if (QX_CanRevive ())
			if (random () < 0.08 + 0.22 * f)
				self.qx_revenant = 1;
			if (QX_CanElite ())
			if (random () < 0.02 + 0.08 * f)
				QX_MakeElite ();
		}
	}

	// PlayerSkill MAX: every enemy turns elite, including ones already spawned
	if (qx_pskill >= QX_SKILL_MAX)
	if (!self.qx_elite)
	if (QX_CanEliteMax ())
	{
		QX_MakeElite ();
		self.qx_announced = 1;		// no per-monster banner spam at MAX
		self.qx_tier = 0;			// force HP / tempo recompute below
	}

	tier = floor (qx_pskill / 5);
	if (self.qx_tier != tier + 1)
	{
		self.qx_tier = tier + 1;
		f = tier * 5 / QX_SKILL_MAX;
		m = 1 + f;
		if (self.qx_elite)
			m = m * 2.5;
		if (self.qx_isboss)
			m = m * QX_BOSS_HP;
		self.health = self.health * m / self.qx_hpmul;
		self.qx_hpmul = m;

		self.qx_tempo = 1 + 0.5 * f;
		if (self.qx_elite)
			self.qx_tempo = self.qx_tempo * 1.35;
		if (self.qx_rage)
			self.qx_tempo = self.qx_tempo * 1.3;
	}
};

// called at the top of every ai_* movement / attack helper
void() QX_AIHook =
{
	local entity p;

	if (!(self.flags & FL_MONSTER))
	if (!self.qx_delta)				// Delta team (allies) get the tempo / dodge handling too
		return;
	if (self.health <= 0)
		return;

	QX_MonsterSync ();

	// landed after a dodge / elite hop: kill the leftover velocity
	if (self.qx_dodging)
	if (self.flags & FL_ONGROUND)
	{
		self.velocity = '0 0 0';
		self.qx_dodging = 0;
	}

	// faster animations = faster everything
	if (self.qx_tempo > 1.01)
	if (self.nextthink > time)
	if (self.nextthink != self.qx_nt_seen)
	{
		self.nextthink = time + (self.nextthink - time) / self.qx_tempo;
		self.qx_nt_seen = self.nextthink;
	}

	if (self.qx_isscout)
		QX_ScoutHook ();

	// a revenant comes back angry
	if (self.qx_hunt)
	{
		self.qx_hunt = 0;
		p = QX_FindLivePlayer ();
		if (p)
		if (self.enemy != p)
		{
			self.enemy = p;
			FoundTarget ();
		}
	}
};

// ---------------------------------------------------------------- scouts (squads)
//
// A squad = leader (the map boss for now) + QX_SCOUTS scouts of the same kind.
//  * they spawn together
//  * idle scouts follow the leader around
//  * the moment the leader picks a target, every scout takes it too
//  * scouts flank: each holds its own side while closing in
//  * when the leader fires, scouts get a free shot right away (volley)
//  * leader dies -> scouts go berserk (faster)

void() QX_ScoutHook =
{
	local entity L, en;
	local float d;

	L = self.qx_leader;
	if (!L || L.health <= 0)
	{
		self.qx_leader = world;
		if (self.goalentity == L)
			self.goalentity = self;
		return;
	}

	// share the leader's target
	en = L.enemy;
	if (en.health > 0)
	if (en.flags & FL_CLIENT)
	if (self.enemy != en)
	{
		self.enemy = en;
		FoundTarget ();
		return;
	}

	// no fight yet: stay with the leader
	if (self.enemy.health <= 0)
	{
		d = vlen (L.origin - self.origin);
		if (d > 160)
		{
			self.goalentity = L;
			self.qx_following = 1;
			self.pausetime = 0;		// ai_stand -> th_walk toward the leader
		}
		else if (self.qx_following)
		{
			self.qx_following = 0;		// caught up: stand guard again
			self.goalentity = self;
			self.pausetime = 99999999;
			self.th_stand ();
		}
	}
};

void() QX_ScoutRun =
{
	local entity L;
	local float yaw, d;

	L = self.qx_leader;
	if (!L || L.health <= 0)
		return;
	if (self.enemy.health <= 0)
		return;
	if (!visible (self.enemy))
		return;

	// volley: the leader just fired, so may we
	if (L.qx_volley > time - 0.4)
	if (self.qx_volley_seen != L.qx_volley)
	{
		self.qx_volley_seen = L.qx_volley;
		if (self.attack_finished > time)
			self.attack_finished = time;
	}

	// flank: drift to our own side while closing in
	d = vlen (self.enemy.origin - self.origin);
	if (d > 200)
	{
		yaw = vectoyaw (self.enemy.origin - self.origin);
		walkmove (yaw + 70 * self.qx_slot, 8);
	}
};

void(entity L) QX_LeaderDown =
{
	local entity e;

	e = nextent (world);
	while (e)
	{
		if (e.qx_isscout)
		if (e.qx_leader == L)
		if (e.health > 0)
		{
			e.qx_leader = world;
			e.qx_rage = 1;
			e.qx_tier = 0;			// recompute tempo with the rage bonus
			e.effects = e.effects | EF_DIMLIGHT;
			if (e.goalentity == L)
				e.goalentity = e;
		}
		e = nextent (e);
	}
	QX_MsgAll ("The scouts go berserk!\n", "", "", "");
};

// find a free spot next to the leader
float(entity L, vector spot) QX_SpotFree =
{
	local entity p;

	traceline (L.origin, spot, FALSE, L);
	if (trace_fraction < 1)
		return FALSE;
	traceline (spot, spot - '0 0 128', TRUE, L);
	if (trace_fraction == 1)
		return FALSE;			// no floor
	if (pointcontents (spot) != CONTENT_EMPTY)
		return FALSE;
	p = findradius (spot, 48);
	while (p)
	{
		if (p.solid == SOLID_SLIDEBOX || p.solid == SOLID_BBOX)
		if (p != L)
			return FALSE;
		p = p.chain;
	}
	return TRUE;
};

void(entity L) QX_SpawnScouts =
{
	local entity m, oself;
	local vector a, spot;
	local float i, tries, side, made, r;

	if (!L.qx_spawnclass)
		return;
	a = '0 0 0';
	a_y = L.angles_y;
	made = 0;
	tries = 0;
	side = 1;
	r = L.maxs_x + 56;			// clear the leader's box
	while (made < QX_SCOUTS && tries < 8)
	{
		makevectors (a);
		if (tries < 2)
			spot = L.origin + v_right * side * r;
		else if (tries < 4)
			spot = L.origin + v_right * side * r - v_forward * r;
		else if (tries < 6)
			spot = L.origin - v_forward * r * 2 + v_right * side * 32;
		else
			spot = L.origin + v_forward * r + v_right * side * r;
		tries = tries + 1;

		if (QX_SpotFree (L, spot))
		{
			m = spawn ();
			m.classname = L.qx_spawnclass;
			m.qx_spawnclass = L.qx_spawnclass;
			m.angles = L.angles;
			m.qx_home = spot;
			m.qx_homeang = L.angles;
			m.qx_gen = 2;			// scouts never come back
			setorigin (m, spot);

			oself = self;
			self = m;
			qx_respawning = TRUE;
			i = QX_CallSpawn (m.qx_spawnclass);
			qx_respawning = FALSE;
			self = oself;

			if (!i)
			{
				remove (m);
				return;			// unknown kind: no squad
			}
			m.qx_isscout = 1;
			m.qx_leader = L;
			m.qx_slot = side;
			spawn_tfog (spot);
			made = made + 1;
		}
		side = 0 - side;
	}

	if (made > 0)
	{
		WriteByte (MSG_ALL, 3);		// svc_updatestat
		WriteByte (MSG_ALL, 12);	// STAT_TOTALMONSTERS
		WriteLong (MSG_ALL, total_monsters);
	}
};

// ---------------------------------------------------------------- dodge

float(float side) QX_DodgeClear =
{
	local vector dest;
	local float c;

	dest = self.origin + v_right * side * 96;
	traceline (self.origin, dest, FALSE, self);
	if (trace_fraction < 1)
		return FALSE;
	if (self.flags & (FL_FLY | FL_SWIM))
		return TRUE;
	traceline (dest, dest - '0 0 160', TRUE, self);
	if (trace_fraction == 1)
		return FALSE;				// would jump into a pit
	c = pointcontents (trace_endpos + '0 0 4');
	if (c == CONTENT_LAVA || c == CONTENT_SLIME)
		return FALSE;
	return TRUE;
};

void() QX_Dodge =
{
	local vector a;
	local float side, spd;

	a = '0 0 0';
	a_y = self.angles_y;
	makevectors (a);

	side = 1;
	if (random () < 0.5)
		side = -1;
	if (!QX_DodgeClear (side))
	{
		side = 0 - side;
		if (!QX_DodgeClear (side))
			return;
	}

	if (self.flags & (FL_FLY | FL_SWIM))
	{
		walkmove (self.angles_y + 90 * side, 32);
		walkmove (self.angles_y + 90 * side, 32);
		return;
	}

	spd = 260 + 160 * QX_F ();
	if (self.qx_elite)
		spd = spd + 80;
	self.velocity = v_right * side * spd + '0 0 220';
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.qx_dodging = 1;
	if (self.classname == "monster_runehunter")	// the deathmatch "huh!"
		sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
};

void() QX_TryDodge =
{
	local entity e, en;
	local vector to;
	local float threat, chance, f;

	if (time < self.qx_dodge_next)
		return;
	if (!QX_CanDodge ())
		return;
	self.qx_dodge_next = time + 0.2;
	if (!(self.flags & (FL_ONGROUND | FL_FLY | FL_SWIM)))
		return;

	f = QX_F ();
	chance = 0.15 + 0.45 * f;
	if (self.qx_elite)
		chance = 0.85;

	// incoming player projectiles
	threat = FALSE;
	e = findradius (self.origin, 450);
	while (e)
	{
		if (e.owner.flags & FL_CLIENT)
		if (e != self)
		if (e.movetype == MOVETYPE_FLYMISSILE || e.movetype == MOVETYPE_BOUNCE)
		if (vlen (e.velocity) > 100)
		{
			to = normalize (self.origin - e.origin);
			if (normalize (e.velocity) * to > 0.9)
				threat = TRUE;
		}
		e = e.chain;
	}

	// being aimed at by a player who is firing (hitscan): react, but worse
	en = self.enemy;
	if (!threat)
	if (en.flags & FL_CLIENT)
	if (en.button0)
	if (visible (en))
	{
		makevectors (en.v_angle);
		to = normalize (self.origin - (en.origin + en.view_ofs));
		if (v_forward * to > 0.985)
		{
			threat = TRUE;
			chance = chance * 0.5;
		}
	}

	if (!threat)
		return;
	if (random () > chance)
		return;

	QX_Dodge ();
	self.qx_dodge_next = time + 1.2 - 0.6 * f;
	if (self.qx_elite)
		self.qx_dodge_next = time + 0.5;
};

// ---------------------------------------------------------------- elite

void() QX_EliteMove =
{
	local vector a;
	local float yaw, ofs;

	if (time > self.qx_strafe_next)
	{
		self.lefty = 1 - self.lefty;
		self.qx_strafe_next = time + 0.6 + random () * 0.9;
	}
	ofs = 90;
	if (self.lefty)
		ofs = -90;
	yaw = vectoyaw (self.enemy.origin - self.origin);

	// circle-strafe like a deathmatch bot
	if (!walkmove (yaw + ofs, 12))
		self.lefty = 1 - self.lefty;

	// bunny hop now and then (the Rune Hunter hops like a real DM player)
	if (self.flags & FL_ONGROUND)
	if (random () < 0.04 || (self.classname == "monster_runehunter" && random () < 0.06))
	{
		a = '0 0 0';
		a_y = yaw + ofs;
		makevectors (a);
		self.velocity = v_forward * 220 + '0 0 260';
		self.flags = self.flags - (self.flags & FL_ONGROUND);
		self.qx_dodging = 1;
		if (self.classname == "monster_runehunter")
			sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	}
};

// ---------------------------------------------------------------- jet knight

void(entity attacker, float damage) QX_NoPain = {};

void() QX_JetEnd =
{
	self.qx_charging = 0;
	if (self.movetype == MOVETYPE_FLY)
		self.movetype = MOVETYPE_STEP;
	self.touch = SUB_Null;
	if (self.qx_savepain)
		self.th_pain = self.qx_savepain;
	if (!self.qx_elite)
		self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	self.velocity = '0 0 0';
	self.flags = self.flags - (self.flags & FL_ONGROUND);	// fall to the floor
	if (self.health > 0)
	{
		self.think = self.th_run;
		self.nextthink = time + 0.1;
	}
};

void() QX_JetTouch =
{
	if (!self.qx_charging)
		return;
	if (other.solid == SOLID_TRIGGER)
		return;

	if (other.takedamage)
	{
		T_Damage (other, self, self, 25 + 25 * QX_F ());
		other.velocity = other.velocity + normalize (self.velocity) * 350 + '0 0 220';
		sound (self, CHAN_WEAPON, "knight/sword2.wav", 1, ATTN_NORM);
	}
	else
		sound (self, CHAN_BODY, "player/land2.wav", 1, ATTN_NORM);

	QX_JetEnd ();
};

void() QX_JetThink =
{
	local vector dir, v;
	local float spd;

	if (self.health <= 0 || time > self.qx_jet_end)
	{
		QX_JetEnd ();
		return;
	}

	// light homing
	spd = vlen (self.velocity);
	if (self.enemy.health > 0)
	{
		dir = normalize ((self.enemy.origin + '0 0 8') - self.origin);
		v = normalize (self.velocity) + dir * 0.25;
		self.velocity = normalize (v) * spd;
	}
	self.angles_y = vectoyaw (self.velocity);

	// jet flame
	particle (self.origin - normalize (self.velocity) * 24, '0 0 0' - self.velocity * 0.1, 230, 12);
	self.nextthink = time + 0.05;
};

void() QX_JetStart =
{
	local vector dir;
	local float spd;

	self.qx_charging = 1;
	self.qx_savepain = self.th_pain;
	self.th_pain = QX_NoPain;			// can't be staggered mid-flight
	self.qx_jet_next = time + 3.5 + random () * 3 - 1.5 * QX_F ();
	self.qx_jet_end = time + 1.3;

	self.ideal_yaw = vectoyaw (self.enemy.origin - self.origin);
	self.angles_y = self.ideal_yaw;
	spd = 650 + 300 * QX_F ();
	dir = normalize ((self.enemy.origin + '0 0 8') - self.origin);

	self.movetype = MOVETYPE_FLY;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	setorigin (self, self.origin + '0 0 4');
	self.velocity = dir * spd + '0 0 40';
	self.touch = QX_JetTouch;
	self.effects = self.effects | EF_DIMLIGHT;
	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	sound (self, CHAN_VOICE, "knight/ksight.wav", 1, ATTN_NORM);

	self.think = QX_JetThink;
	self.nextthink = time + 0.05;
};

// called from ai_run; TRUE = ai_run must stop here
float() QX_AIRun =
{
	local entity en;
	local float d;

	en = self.enemy;
	if (en.health <= 0)
		return FALSE;
	if (self.qx_charging)
		return TRUE;
	if (self.classname == "monster_runehunter")
	if (QX_HunterItems ())		// running for health / armor
		return TRUE;

	if (self.qx_elite)
	if (self.classname != "monster_runehunter")	// the hunter has its own fire rates
	if (!self.qx_delta)				// so has Delta team
	{
		// fire twice as often
		if (self.attack_finished > time)
		if (self.attack_finished != self.qx_af_seen)
		{
			self.attack_finished = time + (self.attack_finished - time) * 0.5;
			self.qx_af_seen = self.attack_finished;
		}
		if (!self.qx_announced)
		if (en.flags & FL_CLIENT)
		{
			self.qx_announced = 1;
			if (self.qx_isboss)
				QX_Center (en, "!!! BOSS ", self.classname, " !!!\n\nkill it to open the exit", "");
			else
				QX_Center (en, "!! ELITE ", self.classname, " !!\n\nit fights like a player", "");
			sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NONE);
		}
	}

	// jetpack knight: rocket-propelled body slam
	if (self.qx_jet)
	if (time > self.qx_jet_next)
	if (self.flags & FL_ONGROUND)
	{
		d = vlen (en.origin - self.origin);
		if (d > 160)
		if (d < 900)
		if (visible (en))
		{
			if (random () < 0.25)
			{
				QX_JetStart ();
				return TRUE;
			}
			self.qx_jet_next = time + 0.3;
		}
	}

	// squad leader: remember when it opens fire, the scouts join in
	if (self.attack_finished > time + 0.1)
	if (self.attack_finished != self.qx_lastaf)
	{
		self.qx_lastaf = self.attack_finished;
		self.qx_volley = time;
	}

	if (self.qx_isscout)
		QX_ScoutRun ();

	QX_TryDodge ();
	if (self.qx_elite)
	if (QX_CanDodge ())
		QX_EliteMove ();
	return FALSE;
};

// ---------------------------------------------------------------- damage

float(entity attacker, entity targ) QX_DamageMult =
{
	local float m;

	// the Rune Hunter fights with deathmatch numbers (its skill is in aim and speed)
	if (attacker.classname == "monster_runehunter")
	if (targ.flags & FL_CLIENT)
		return 1;

	// B: the player's weapons grow at the same rate as enemy HP, so time-to-kill
	//    stays the same at any PlayerSkill. Difficulty comes from enemy behaviour.
	if (attacker.flags & FL_CLIENT || attacker.qx_delta)	// Delta team hits like you
	if (targ.flags & FL_MONSTER)
		return 1 + QX_PLAYER_DMG_SCALE * QX_F ();

	if (!(attacker.flags & FL_MONSTER))
		return 1;
	if (targ.flags & FL_MONSTER)
		return 1;					// infighting unchanged
	m = 1 + 0.5 * QX_F ();
	if (attacker.qx_elite)
		m = m * 1.3;
	return m;
};

// ---------------------------------------------------------------- revenant

float(string c) QX_CallSpawn =
{
	if (c == "monster_ogre")		{ monster_ogre (); return TRUE; }
	if (c == "monster_ogre_marksman")	{ monster_ogre_marksman (); return TRUE; }
	if (c == "monster_ogre_qutf")		{ monster_ogre_qutf (); return TRUE; }
	if (c == "monster_demon1")		{ monster_demon1 (); return TRUE; }
	if (c == "monster_demon2")		{ monster_demon2 (); return TRUE; }
	if (c == "monster_shambler")		{ monster_shambler (); return TRUE; }
	if (c == "monster_shambler_QUTF")	{ monster_shambler_QUTF (); return TRUE; }
	if (c == "monster_knight")		{ monster_knight (); return TRUE; }
	if (c == "monster_army")		{ monster_army (); return TRUE; }
	if (c == "monster_dog")			{ monster_dog (); return TRUE; }
	if (c == "monster_wizard")		{ monster_wizard (); return TRUE; }
	if (c == "monster_superwizard")		{ monster_superwizard (); return TRUE; }
	if (c == "monster_hplayer")		{ monster_hplayer (); return TRUE; }
	if (c == "monster_zombie")		{ monster_zombie (); return TRUE; }
	if (c == "monster_mummy")		{ monster_mummy (); return TRUE; }
	if (c == "monster_tarbaby")		{ monster_tarbaby (); return TRUE; }
	if (c == "monster_hell_knight")		{ monster_hell_knight (); return TRUE; }
	if (c == "monster_bane")		{ monster_bane (); return TRUE; }
	if (c == "monster_cyber")		{ monster_cyber (); return TRUE; }
	if (c == "monster_fish")		{ monster_fish (); return TRUE; }
	if (c == "monster_eel")			{ monster_eel (); return TRUE; }
	if (c == "monster_shalrath")		{ monster_shalrath (); return TRUE; }
	if (c == "monster_enforcer")		{ monster_enforcer (); return TRUE; }
	if (c == "monster_enforcertank")	{ monster_enforcertank (); return TRUE; }
	if (c == "monster_me")			{ monster_me (); return TRUE; }
	if (c == "monster_blarg")		{ monster_blarg (); return TRUE; }
	if (c == "monster_daikon")		{ monster_daikon (); return TRUE; }
	if (c == "monster_bdaikon")		{ monster_bdaikon (); return TRUE; }
	return FALSE;
};

void() QX_ReviveThink =
{
	local entity m, p, oself;
	local float ok;

	// don't pop up inside a player: wait
	p = findradius (self.qx_home, 80);
	while (p)
	{
		if (p.flags & FL_CLIENT)
		if (p.health > 0)
		{
			self.nextthink = time + 2;
			return;
		}
		p = p.chain;
	}

	m = spawn ();
	m.classname = self.qx_spawnclass;
	m.qx_spawnclass = self.qx_spawnclass;
	m.qx_home = self.qx_home;
	m.qx_homeang = self.qx_homeang;
	m.qx_homeflags = self.qx_homeflags;
	m.angles = self.qx_homeang;
	m.spawnflags = self.qx_homeflags;
	m.qx_gen = self.qx_gen;
	m.qx_hunt = 1;
	setorigin (m, self.qx_home);

	oself = self;
	self = m;
	qx_respawning = TRUE;
	ok = QX_CallSpawn (m.qx_spawnclass);
	qx_respawning = FALSE;
	self = oself;

	if (!ok)
	{
		remove (m);
		remove (self);
		return;
	}

	spawn_tfog (self.qx_home);
	// tell the HUD the monster total grew
	WriteByte (MSG_ALL, 3);		// svc_updatestat
	WriteByte (MSG_ALL, 12);	// STAT_TOTALMONSTERS
	WriteLong (MSG_ALL, total_monsters);
	QX_RiftTell (self.qx_home, "REINFORCEMENTS!");
	QX_MsgAll ("Something came back from the dead...\n", "", "", "");
	remove (self);
};

// ---- warning before a revenant comes back: a raging slipgate at its spawn spot
// Players get a centerprint with the direction (ahead / left / right / behind),
// and the spot itself crackles with lightning and light for QX_REV_WARN seconds.

string(entity p, vector spot) QX_DirWord =
{
	local float d;

	if (vlen (spot - p.origin) > 1500)
		return "(far away)";
	d = vectoyaw (spot - p.origin) - p.v_angle_y;
	while (d > 180)		d = d - 360;
	while (d < -180)	d = d + 360;
	if (d > -45 && d < 45)		return "(ahead)";
	if (d >= 135 || d <= -135)	return "(BEHIND YOU)";
	if (d > 0)			return "(on your left)";
	return "(on your right)";
};

void(vector spot, string what) QX_RiftTell =
{
	local entity p;

	p = find (world, classname, "player");
	while (p)
	{
		if (p.health > 0)
			QX_Center (p, what, "\n", QX_DirWord (p, spot), "");
		p = find (p, classname, "player");
	}
};

void() QX_RiftCrackle =
{
	local vector top;

	if (time >= self.ltime)
	{
		self.effects = 0;
		setmodel (self, "");
		QX_ReviveThink ();		// may wait (player standing on the spot)
		return;
	}
	// a bolt from above into the spot, sparks and a crackle
	top = self.qx_home + '0 0 96';
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, top_x);
	WriteCoord (MSG_BROADCAST, top_y);
	WriteCoord (MSG_BROADCAST, top_z);
	WriteCoord (MSG_BROADCAST, self.qx_home_x);
	WriteCoord (MSG_BROADCAST, self.qx_home_y);
	WriteCoord (MSG_BROADCAST, self.qx_home_z);
	particle (self.qx_home, '0 0 60', 244, 24);
	if (random () < 0.5)
		sound (self, CHAN_BODY, "weapons/lhit.wav", 1, ATTN_NORM);
	self.nextthink = time + 0.3;
};

void() QX_RiftWarn =
{
	self.ltime = time + QX_REV_WARN;
	setorigin (self, self.qx_home);
	setmodel (self, "progs/s_light.spr");
	self.effects = EF_DIMLIGHT;
	sound (self, CHAN_VOICE, "weapons/lstart.wav", 1, ATTN_NORM);
	QX_RiftTell (self.qx_home, "The slipgate is raging...");
	self.think = QX_RiftCrackle;
	self.nextthink = time + 0.1;
};

void(entity mon) QX_ScheduleRevive =
{
	local entity t;

	if (deathmatch)
		return;
	t = spawn ();
	t.classname = "qx_revive";
	t.qx_spawnclass = mon.qx_spawnclass;
	t.qx_home = mon.qx_home;
	t.qx_homeang = mon.qx_homeang;
	t.qx_homeflags = mon.qx_homeflags;
	t.qx_gen = mon.qx_gen + 1;
	t.think = QX_RiftWarn;		// warn first, then QX_ReviveThink
	t.nextthink = time + 4 + random () * 8 - QX_REV_WARN;
};

// ---------------------------------------------------------------- PlayerSkill: getting hit

void(entity targ, entity attacker, float take) QX_PlayerHurt =
{
	if (take > 0)
	{
		targ.qx_lastpain = time;	// any damage delays health regen
		targ.qx_regen_on = 0;
	}
	if (deathmatch)
		return;
	if (!targ.ishuman)
		return;
	if (attacker == targ || attacker == world)
		return;				// rocket jumps, lava, falling don't count
	if (take <= 0)
		return;
	if (!qx_duel)				// no PlayerSkill loss in a Rune Hunter duel
		QX_SetSkill (qx_pskill - take * QX_SKILL_HURT);

	// getting hurt pumps adrenaline (twice as much in a duel)
	targ.qx_lasthurt = time;
	targ.qx_adren = targ.qx_adren + take * QX_ADREN_HURT;
	if (qx_duel)
		targ.qx_adren = targ.qx_adren + take * QX_ADREN_HURT;
	if (targ.qx_adren > 100)
		targ.qx_adren = 100;
};

// ---------------------------------------------------------------- ammo drops

// Monsters that don't drop ammo in their own death code get a backpack here.
void(entity m) QX_DropAmmo =
{
	local entity oself;
	local string c;
	local float mul, w;

	w = 0;			// QuakeC locals keep old values between calls
	if (deathmatch)
		return;
	c = m.qx_spawnclass;
	if (!c)
		c = m.classname;

	// these already drop a backpack themselves
	if (c == "monster_army" || c == "monster_enforcer" || c == "monster_me" || c == "monster_enforcertank")
		return;
	if (c == "monster_ogre" || c == "monster_ogre_marksman" || c == "monster_ogre_qutf")
		return;
	// nothing to drop / unreachable
	if (c == "monster_boss" || c == "monster_oldone" || c == "monster_smine")
		return;
	if (c == "monster_fish" || c == "monster_eel")
		return;

	m.ammo_shells = 0;
	m.ammo_nails = 0;
	m.ammo_rockets = 0;
	m.ammo_cells = 0;

	if (c == "monster_knight" || c == "monster_hell_knight" || c == "monster_bane")
		m.ammo_nails = 15;
	else if (c == "monster_wizard" || c == "monster_superwizard")
		m.ammo_nails = 10;
	else if (c == "monster_shambler" || c == "monster_shambler_QUTF")
		m.ammo_cells = 15;
	else if (c == "monster_tarbaby")
		m.ammo_cells = 5;
	else if (c == "monster_demon1" || c == "monster_demon2" || c == "monster_shalrath")
		m.ammo_rockets = 3;
	else if (c == "monster_cyber")
		m.ammo_rockets = 5;
	else if (c == "monster_hplayer")
	{
		m.ammo_shells = 10;
		m.ammo_nails = 10;
	}
	else if (c == "monster_zombie" || c == "monster_mummy")
	{
		m.ammo_shells = 5;
		m.ammo_rockets = 1;		// they only die to explosives: pay back the rocket
	}
	else if (c == "monster_runehunter")
	{	// deathmatch style: its backpack has its rocket launcher
		m.ammo_shells = 10;
		m.ammo_nails = 15;
		m.ammo_rockets = 5;
		w = IT_ROCKET_LAUNCHER;
	}
	else
		m.ammo_shells = 5;		// dogs and everything else

	mul = 1;
	if (m.qx_elite)
		mul = 2;
	if (m.qx_isboss)
		mul = 3;
	m.ammo_shells = m.ammo_shells * mul;
	m.ammo_nails = m.ammo_nails * mul;
	m.ammo_rockets = m.ammo_rockets * mul;
	m.ammo_cells = m.ammo_cells * mul;

	oself = self;
	self = m;
	m.weapon = w;
	DropBackpack ();
	self = oself;
};

// ---------------------------------------------------------------- map boss

float() QX_CanBoss =
{
	local string c;
	if (!(self.flags & FL_MONSTER))
		return FALSE;
	if (self.health <= 0)
		return FALSE;
	c = self.qx_spawnclass;
	if (!c)
		c = self.classname;
	if (c == "monster_smine" || c == "monster_fish" || c == "monster_eel")
		return FALSE;
	if (c == "monster_zombie" || c == "monster_mummy")
		return FALSE;			// need gibbing: bad boss
	if (c == "monster_daikon" || c == "monster_mdaikon")
		return FALSE;			// blows itself up right away
	if (c == "monster_runehunter")
		return FALSE;
	return TRUE;
};

// One random tough monster per map becomes an elite boss.
// Maps with a real boss (Chthon / Shub) or no candidates have no lock.
void() QX_PickBoss =
{
	local entity e, oself, pick;
	local float n, tier, want, i;

	qx_boss_picked = 1;
	qx_boss = world;
	if (deathmatch)
		return;

	e = find (world, classname, "monster_boss");
	if (e)
		return;
	e = find (world, classname, "monster_oldone");
	if (e)
		return;

	// tougher monsters first: HP >= 200, then >= 80, then anything
	oself = self;
	tier = 200;
	n = 0;
	while (n == 0 && tier >= 0)
	{
		e = nextent (world);
		while (e)
		{
			self = e;
			if (QX_CanBoss ())
			if (e.health >= tier)
				n = n + 1;
			e = nextent (e);
		}
		if (n == 0)
		{
			if (tier == 200)
				tier = 80;
			else if (tier == 80)
				tier = 0;
			else
				tier = -1;
		}
	}
	if (n == 0)
	{
		self = oself;
		return;
	}

	want = floor (random () * n);
	if (want >= n)
		want = n - 1;
	i = 0;
	pick = world;
	e = nextent (world);
	while (e)
	{
		self = e;
		if (QX_CanBoss ())
		if (e.health >= tier)
		{
			if (i == want)
				pick = e;
			i = i + 1;
		}
		e = nextent (e);
	}

	if (pick)
	{
		self = pick;
		self.qx_isboss = 1;
		self.qx_revenant = 0;
		self.qx_announced = 0;
		if (!self.qx_elite)
			QX_MakeElite ();
		self.effects = self.effects | EF_BRIGHTFIELD;	// sparkle so you can find it
		self.qx_tier = 0;				// recompute HP with the boss factor
		qx_boss = self;
		QX_MsgAll ("BOSS on this map: ", self.classname, "  - the exit stays sealed until it dies\n", "");
		QX_SpawnScouts (self);
		self = pick;
	}
	self = oself;
};

float(entity p) QX_ExitBlocked =
{
	if (deathmatch)
		return FALSE;
	if (qx_duel || qx_arena)
	{
		if (time > qx_exitmsg_time)
		{
			qx_exitmsg_time = time + 2;
			QX_Center (p, "THE EXITS ARE SEALED\n\nbeat the RUNE HUNTER first", "", "", "");
		}
		return TRUE;
	}
	if (!qx_boss)
		return FALSE;
	if (!qx_boss.qx_isboss || qx_boss.health <= 0)
		return FALSE;
	if (time > qx_exitmsg_time)
	{
		qx_exitmsg_time = time + 2;
		QX_Center (p, "THE EXIT IS SEALED\n\nkill the BOSS: ", qx_boss.classname, "", "");
	}
	return TRUE;
};

// ---------------------------------------------------------------- jetpack pickup

void() QX_JetpackTouch =
{
	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if (other.qx_hasjet)
	{
		// already have one: take the fuel as rockets
		if (other.ammo_rockets >= 100)
			return;
		other.ammo_rockets = other.ammo_rockets + 5;
		if (other.ammo_rockets > 100)
			other.ammo_rockets = 100;
		sprint (other, "You got 5 rockets\n");
	}
	else
	{
		other.qx_hasjet = 1;
		QX_Center (other, "JETPACK ACQUIRED\n\njump again in mid-air", "", "", "");
		sprint (other, "You got the Jetpack\n");
	}
	sound (other, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
	stuffcmd (other, "bf\n");
	self.touch = SUB_Null;
	remove (self);
};

void(vector org) QX_DropJetpack =
{
	local entity item;

	item = spawn ();
	item.classname = "qx_jetpack";
	item.origin = org - '0 0 24';
	item.flags = FL_ITEM;
	item.solid = SOLID_TRIGGER;
	item.movetype = MOVETYPE_TOSS;
	item.velocity_z = 300;
	item.velocity_x = -100 + (random () * 200);
	item.velocity_y = -100 + (random () * 200);
	item.effects = EF_DIMLIGHT;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = QX_JetpackTouch;
	item.nextthink = time + 120;
	item.think = SUB_Remove;
};

// called from Killed() before th_die (self == targ)
void(entity targ, entity attacker) QX_OnKilled =
{
	local float g;

	if (targ.qx_charging)
	{
		targ.qx_charging = 0;
		targ.movetype = MOVETYPE_STEP;
		targ.velocity = '0 0 0';
		targ.flags = targ.flags - (targ.flags & FL_ONGROUND);
		if (targ.qx_savepain)
			targ.th_pain = targ.qx_savepain;
	}

	if (!(targ.flags & FL_MONSTER))
		return;

	QX_StatKill (targ, attacker);	// map report
	if (targ.classname == "monster_runehunter")
		QX_HunterDown (targ, attacker);

	if (attacker.flags & FL_CLIENT)
	if (!deathmatch)
	{
		g = 1;
		if (targ.qx_basehp >= 300)
			g = 2;
		if (targ.qx_elite)
		{
			g = 5;
			QX_Msg (attacker, "ELITE DOWN!\n", "", "", "");
		}
		attacker.qx_kills = attacker.qx_kills + 1;
		QX_GainSkill (g);

		attacker.qx_adren = attacker.qx_adren + QX_ADREN_KILL;
		if (attacker.qx_adren > 100)
			attacker.qx_adren = 100;
	}

	QX_DropAmmo (targ);

	if (targ.qx_isboss)
		QX_LeaderDown (targ);

	if (targ.qx_isboss)
	{
		targ.qx_isboss = 0;
		targ.qx_revenant = 0;
		qx_boss = world;
		if (qx_bossmusic)
		{
			qx_bossmusic = FALSE;
			QX_PlayTrack (qx_maptrack);	// back to the map's soundtrack
		}
		QX_CenterAll ("BOSS DEFEATED\n\nthe exit is open", "", "", "");
		QX_MsgAll ("The boss is dead. The exit is open.\n", "", "", "");
		if (attacker.flags & FL_CLIENT)
		if (!deathmatch)
			QX_GainSkill (5);
		if (qx_persist)
		if (!deathmatch && !coop)
			qx_autosave_at = time + 1.5;
	}

	if (targ.qx_revenant)
		QX_ScheduleRevive (targ);

	if (targ.qx_jet)
		QX_DropJetpack (targ.origin);
};

// ======================================================================
// Super Nailgun (classic, revived): autoaim + homing above PlayerSkill 50
// ======================================================================

// pick the target closest to the nail's flight line
entity() QX_NailTarget =
{
	local entity t, best;
	local vector fwd, mid;
	local float d, bestd;

	fwd = normalize (self.velocity);
	best = world;
	bestd = 0.6;				// about 53 degrees cone
	t = findradius (self.origin, 1200);
	while (t)
	{
		if (t.health > 0)
		if (t.takedamage == DAMAGE_AIM)
		if (t != self.owner)
		if (!(t.classname == "monster_runehunter" && t.qx_hskill >= 2))
		if ((t.flags & FL_MONSTER) || (deathmatch && (t.flags & FL_CLIENT)))
		{
			mid = t.origin + (t.mins + t.maxs) * 0.5;
			d = normalize (mid - self.origin) * fwd;
			if (d > bestd)
			{
				traceline (self.origin, mid, TRUE, self);
				if (trace_fraction == 1)
				{
					bestd = d;
					best = t;
				}
			}
		}
		t = t.chain;
	}
	return best;
};

// smooth steering, no random wobble
void() QX_NailHome =
{
	local vector want, dir;
	local float spd;

	if (time > self.qx_life)
	{
		remove (self);
		return;
	}
	if (self.enemy.health <= 0 || !self.enemy.takedamage)
		self.enemy = QX_NailTarget ();
	if (self.enemy)
	{
		want = normalize ((self.enemy.origin + (self.enemy.mins + self.enemy.maxs) * 0.5) - self.origin);
		dir = normalize (normalize (self.velocity) + want * QX_SNG_TURN);
		spd = vlen (self.velocity);
		self.velocity = dir * spd;
		self.angles = vectoangles (self.velocity);
	}
	self.nextthink = time + 0.05;
};

// own touch so the damage can scale (superspike_touch is shared with traps)
void() QX_SuperNailTouch =
{
	if (other == self.owner)
		return;
	if (other.solid == SOLID_TRIGGER)
		return;
	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}
	if (other.takedamage)
	{
		spawn_touchblood (self.dmg);
		if (QX_Armored (other))		// super nails pierce armor too
			T_Damage (other, self, self.owner, self.dmg * QX_NAIL_PIERCE);
		else
			T_Damage (other, self, self.owner, self.dmg);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}
	remove (self);
};

void() W_FireSuperNail =
{
	local vector dir;

	if (self.ammo_nails < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;	// QuadEXQ: 1 nail per shot

	makevectors (self.v_angle);
	dir = aim (self, 1000);			// SNG keeps autoaim
	launch_spike (self.origin + '0 0 16', dir);
	newmis.touch = QX_SuperNailTouch;
	newmis.classname = "superspike";
	newmis.dmg = QX_SNG_DAMAGE;	// PlayerSkill growth now applies to every weapon (QX_DamageMult)
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	newmis.velocity = dir * QX_SNG_SPEED;

	if (qx_pskill > QX_SNG_HOMING_SKILL)
	{
		newmis.enemy = world;
		newmis.qx_life = time + 3;
		newmis.think = QX_NailHome;
		newmis.nextthink = time + 0.05;
	}
	self.punchangle_x = -2;
};

// ======================================================================
// Blaster (slot 1): free ammo, Enforcer-style laser bolt
// ======================================================================

void() QX_BlasterTouch =
{
	local vector org;

	if (other == self.owner)
		return;
	if (other.solid == SOLID_TRIGGER)
		return;
	if (pointcontents (self.origin) == CONTENT_SKY)
	{
		remove (self);
		return;
	}
	sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
	org = self.origin - 8 * normalize (self.velocity);
	if (other.health)
	{
		SpawnBlood (org, self.velocity * 0.2, QX_BLASTER_DAMAGE);
		T_Damage (other, self, self.owner, QX_BLASTER_DAMAGE);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
	remove (self);
};

void() QX_FireBlaster =
{
	local vector dir;

	makevectors (self.v_angle);
	dir = aim (self, 1000);			// no autoaim (modern aim)
	sound (self, CHAN_WEAPON, "enforcer/enfire.wav", 1, ATTN_NORM);
	self.effects = self.effects | EF_MUZZLEFLASH;
	self.punchangle_x = -1;

	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;
	newmis.classname = "qx_blaster";
	setmodel (newmis, "progs/laser.mdl");
	setsize (newmis, '0 0 0', '0 0 0');
	setorigin (newmis, self.origin + v_forward * 8 + '0 0 16');
	newmis.velocity = dir * QX_BLASTER_SPEED;
	newmis.angles = vectoangles (newmis.velocity);
	newmis.touch = QX_BlasterTouch;
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
};
