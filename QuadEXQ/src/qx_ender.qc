/*
==============================================================================

QuadEXQ: THE ENDER -- the end map's own story

  1. end.bsp: Shub-Niggurath is the SHUB-NIGGURATH LORD (blood red, sparkling),
     and the slipgates rage all the way to her: monsters keep coming through.
  2. Right before her gate: "Ummm... Something's wrong!?" -- and the gate
     telefrags YOU. The slipgate spits you out on ender.bsp.
  3. ender.bsp (QuadEXQ's own arena: a big hall with pillars): the CYBER DELTA (the reworked Cyberdemon) and two Cyber Delta scouts. Here your
     only weapon is the BFG, with endless cells; only its direct hits hurt the
     boss (QX_ENDER_HITS of them). When it goes badly,
     DELTA TEAM drops in ("Sorry we're late! This one's our job.", music track
     12), makes short work of the scouts, and leaves the boss to you.
  4. Back on end.bsp (where you stood before the gate), Delta Team with you.
     At the gate they stop you: "This time, we go in first." They go through,
     one by one; then it's your turn, and the stock ending -- with a last line
     about Delta Team.

State across the level changes: serverflags QX_ENDER_WON (set once the
Cyberdemon boss is down, so the second visit to end.bsp goes to the finale).
The trip to ender.bsp uses the arena machinery: scratch1 = 5 (QX_ENDER_MODE),
qx_back.sav / the qx_back alias for the way back, scratch3 for the flags.
Needs the QuadEXQ engine (qx_arena_ok >= 2); elsewhere end.bsp plays stock.
==============================================================================
*/

float	QX_ENDER_HITS		= 10;		// BFG hits that bring the Cyberdemon boss down
float	QX_ENDER_DELTA_HP	= 0.4;		// Delta Team drops in when your health is this low (of 100) ...
float	QX_ENDER_DELTA_TIME	= 30;		// ... or this many seconds into the fight
float	QX_ENDER_SCOUT_HURT	= 8;		// Delta Team's hits on the scouts count this many times
float	QX_ENDER_SCOUT_HP	= 3;		// the scouts' health, times this (and times 1 + PlayerSkill / 100)
float	QX_ENDER_RAGE_MAX	= 12;		// raging-slipgate monsters alive at once (at most)
float	QX_ENDER_REGEN		= 20;		// ender.bsp: health and armor come back after this many seconds
float	QX_ENDER_TRACK		= 12;		// music/track12.mp3: Delta Team's song
string	QX_ENDER_MAP		= "ender";	// maps/ender.bsp: the Cyberdemon boss hall

float	qx_ender_setup;			// end.bsp: Shub Lord done
float	qx_ender_warned;		// end.bsp: "Something's wrong" shown
entity	qx_ender_gate;			// end.bsp: the trigger_teleport into Shub
float	qx_ender_rage_next;		// end.bsp: next raging slipgate
float	qx_ender_phase;			// end.bsp second visit: 1 Delta goes in, 2 your turn, 3 you go
float	qx_ender_next;			// ... time of the next step
float	qx_ender_allow;			// TRUE: this teleport is the real one (let it through)
entity	qx_ender_boss_e;		// ender.bsp: the Cyberdemon boss
float	qx_ender_t0;			// ender.bsp: when the fight began
float	qx_ender_delta;			// ender.bsp: Delta Team is here
float	qx_ender_hunted;		// ender.bsp: boss and scouts sent at you
float	qx_ender_hits;			// ender.bsp: BFG hits landed
float	qx_ender_hint;			// ender.bsp: next "it shrugs it off" hint
float	qx_ender_won_at;		// ender.bsp: back to end.bsp at this time
float	qx_ender_regen_scan;		// ender.bsp: next look for taken health / armor
.float	qx_ender_regen;			// (an item) comes back at this time

void(entity p) QX_EnderBFG;

float() QX_EnderEndMap =
{
	return (world.model == "maps/end.bsp");
};

// precache a monster kind at map load (spawning it later is then allowed)
void(string c) QX_PrecacheMonster =
{
	local entity e, oself;
	local float tm;

	tm = total_monsters;
	e = spawn ();
	e.classname = c;
	setorigin (e, '0 0 0');
	oself = self;
	self = e;
	QX_CallSpawn (c);
	self = oself;
	remove (e);
	total_monsters = tm;
};

// from QX_WorldSpawn
void() QX_EnderWorldSpawn =
{
	if (deathmatch || coop)
		return;
	if (mapname != "end")
		return;
	// the raging slipgates bring these -- and what EXQ may turn them into
	// (a spawn function rolls its swap again when the monster comes through)
	QX_PrecacheMonster ("monster_hell_knight");
	QX_PrecacheMonster ("monster_shalrath");
	QX_PrecacheMonster ("monster_ogre");
	QX_PrecacheMonster ("monster_ogre_qutf");
	QX_PrecacheMonster ("monster_demon1");
	QX_PrecacheMonster ("monster_demon2");
	QX_PrecacheMonster ("monster_shambler");
	QX_PrecacheMonster ("monster_shambler_QUTF");
	QX_PrecacheMonster ("monster_bdaikon");
	QX_PrecacheMonster ("monster_enforcer");
	QX_PrecacheMonster ("monster_enforcertank");
	QX_PrecacheMonster ("monster_me");
};

// from QX_ArenaInit, mode QX_ENDER_MODE (still loading the map)
void() QX_EnderArenaInit =
{
	qx_ender_arena = TRUE;
	QX_PrecacheMonster ("monster_cyber");
};

float() QX_EnderOn =
{
	if (deathmatch || coop)
		return FALSE;
	return (cvar ("qx_arena_ok") >= 2);	// needs the QuadEXQ engine's way back
};

// ---------------------------------------------------------------- end.bsp

// the gate into Shub: a teleporter whose destination is INSIDE her (that's
// the telefrag) -- not one that only lands you near her
float(entity trig) QX_EnderInside =
{
	local entity t;
	local vector o;

	if (!shub)
		return FALSE;
	if (trig.classname != "trigger_teleport")
		return FALSE;
	t = find (world, targetname, trig.target);
	if (!t)
		return FALSE;
	o = t.origin;
	if (o_x < shub.absmin_x || o_x > shub.absmax_x)	return FALSE;
	if (o_y < shub.absmin_y || o_y > shub.absmax_y)	return FALSE;
	if (o_z < shub.absmin_z || o_z > shub.absmax_z)	return FALSE;
	return TRUE;
};

// end.bsp: the gate (*3) sends you to the misc_teleporttrain, the spiked
// ball that circles through her -- a telefrag only while it is inside her.
// (On another end map: a destination inside her, or the one picked at setup.)
float(entity trig) QX_EnderIsGate =
{
	local entity t;

	if (trig.classname != "trigger_teleport")
		return FALSE;
	t = find (world, targetname, trig.target);
	if (t)
	if (t.classname == "misc_teleporttrain")
		return TRUE;
	if (QX_EnderInside (trig))
		return TRUE;
	return (trig == qx_ender_gate && qx_ender_gate != world);
};

void() QX_EnderShubLord =
{
	local entity e, t;
	local float bd;

	qx_ender_setup = TRUE;
	if (!shub)
		return;
	shub.netname = "Shub-Niggurath Lord";
	if (cvar ("qx_colormap_ok") >= 2)
		shub.colormap = 255;		// blood red (the QuadEXQ engine)
	else
		shub.effects = shub.effects | EF_DIMLIGHT;
	shub.effects = shub.effects | EF_BRIGHTFIELD;
	qx_ender_gate = world;
	bd = 400;
	e = find (world, classname, "trigger_teleport");
	while (e)
	{
		t = find (world, targetname, e.target);
		if (QX_EnderInside (e) || (t && t.classname == "misc_teleporttrain"))
		{
			qx_ender_gate = e;
			bd = -1;
		}
		else if (bd > 0)
		{
			t = find (world, targetname, e.target);
			if (t)
			if (vlen (t.origin - shub.origin) < bd)
			{
				bd = vlen (t.origin - shub.origin);
				qx_ender_gate = e;
			}
		}
		e = find (e, classname, "trigger_teleport");
	}
	if (!(serverflags & QX_ENDER_WON))
	{
		QX_CenterAll ("!!! BOSS !!!\n\nSHUB-NIGGURATH LORD\n\nthe slipgates are raging...", "", "", "");
		QX_MsgAll ("BOSS on this map: Shub-Niggurath Lord\n", "", "", "");
		qx_ender_rage_next = time + 6;
	}
};

// a raging slipgate somewhere around you: a monster comes through
void(entity p) QX_EnderRage =
{
	local entity e, t;
	local float n, tries, r, ok, i;
	local vector a, spot, fl;
	local string c;

	qx_ender_rage_next = time + 4 + random () * 4;

	n = 0;
	e = nextent (world);
	while (e)
	{
		if (e.classname == "qx_revive")
			n = n + 1;
		else if (e.flags & FL_MONSTER)
		if (e.health > 0)
		if (e.qx_hunt)
			n = n + 1;
		e = nextent (e);
	}
	if (n >= QX_ENDER_RAGE_MAX)
		return;

	tries = 0;
	ok = FALSE;
	while (tries < 10 && !ok)
	{
		tries = tries + 1;
		a = '0 0 0';
		a_y = random () * 360;
		makevectors (a);
		spot = p.origin + v_forward * (320 + random () * 480);
		traceline (p.origin + '0 0 16', spot + '0 0 16', TRUE, p);
		spot = trace_endpos - v_forward * 56 - '0 0 16';
		if (vlen (spot - p.origin) < 240)
			continue;
		traceline (spot + '0 0 16', spot - '0 0 512', TRUE, world);
		if (trace_fraction == 1)
			continue;			// a pit
		fl = trace_endpos;
		spot = fl + '0 0 32';
		if (pointcontents (spot) != CONTENT_EMPTY || pointcontents (fl + '0 0 96') != CONTENT_EMPTY)
			continue;
		// room to stand
		ok = TRUE;
		i = 0;
		while (i < 4 && ok)
		{
			a = '0 0 0';
			a_y = i * 90;
			makevectors (a);
			traceline (spot, spot + v_forward * 40, FALSE, world);
			if (trace_fraction < 1)
				ok = FALSE;
			i = i + 1;
		}
	}
	if (!ok)
		return;

	r = random ();
	if (r < 0.22)		c = "monster_hell_knight";
	else if (r < 0.40)	c = "monster_shalrath";
	else if (r < 0.58)	c = "monster_ogre";
	else if (r < 0.74)	c = "monster_demon1";
	else if (r < 0.86)	c = "monster_enforcer";
	else			c = "monster_shambler";

	t = spawn ();
	t.classname = "qx_revive";
	t.qx_spawnclass = c;
	t.qx_home = spot;
	t.qx_homeang = '0 0 0';
	t.qx_homeang_y = vectoyaw (p.origin - spot);
	t.qx_gen = 2;				// they don't come back again
	t.think = QX_RiftWarn;			// the warning, then QX_ReviveThink
	t.nextthink = time + 0.1;
};

// first visit, at the gate: it turns on you
void(entity p) QX_EnderBackfire =
{
	qx_ender_go = TRUE;
	spawn_tfog (p.origin);
	sound (p, CHAN_AUTO, "misc/r_tele1.wav", 1, ATTN_NORM);
	if (shub)
		sound (shub, CHAN_VOICE, "boss2/sight.wav", 1, ATTN_NONE);
	p.invincible_finished = 0;
	p.items = p.items - (p.items & IT_INVULNERABILITY);
	p.armortype = 0;
	p.armorvalue = 0;
	p.items = p.items - (p.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
	p.qx_back_prot = 0;
	T_Damage (p, shub, shub, 50000);
	QX_Center (p, "TELEFRAGGED!\n\nSHUB-NIGGURATH LORD\nturned the gate on you", "", "", "");
	QX_LB ();
	QX_LS ("    THE ENDER: the gate turned on you");
	QX_LE ();
};

// from teleport_touch (self = the trigger): TRUE = no teleport this time
float(entity p, entity trig) QX_EnderTeleport =
{
	local entity e;

	if (qx_ender_allow)
		return FALSE;
	if (p.classname != "player")
		return FALSE;
	if (!QX_EnderOn ())
		return FALSE;
	if (!QX_EnderEndMap ())
		return FALSE;
	if (!QX_EnderIsGate (trig))
		return FALSE;
	if (!(serverflags & QX_ENDER_WON))
	{
		if (!qx_ender_go)
			QX_EnderBackfire (p);
		return TRUE;
	}
	// second visit: Delta Team goes first
	if (qx_ender_phase >= 3)
		return FALSE;			// your turn: in you go
	if (qx_ender_phase)
		return TRUE;
	e = find (world, classname, "qx_delta");
	while (e)
	{
		if (e.qx_delta && e.health > 0)
			break;
		e = find (e, classname, "qx_delta");
	}
	if (!e)
	{	// not here (yet): call them
		if (!qx_delta_call && !find (world, classname, "qx_delta_wait"))
			qx_delta_call = time + 0.5;
		QX_Center (p, "DELTA TEAM:\n\nWait for us!", "", "", "");
		return TRUE;
	}
	qx_ender_phase = 1;
	qx_ender_next = time + 2;
	qx_ender_gate = trig;			// this is the one (for your turn)
	QX_Center (p, "DELTA TEAM:\n\nHold it!\nThis time, we go in first.", "", "", "");
	sound (p, CHAN_AUTO, "misc/talk.wav", 1, ATTN_NONE);
	p.velocity = '0 0 0';			// (no shove: the gate may stand over the void)
	return TRUE;
};

// end.bsp, second visit: the team goes through, then you
void(entity p) QX_EnderFinaleThink =
{
	local entity e, n, oself, ootheR;

	if (time < qx_ender_next)
		return;
	if (qx_ender_phase == 1)
	{	// the next member steps through the gate
		e = find (world, classname, "qx_delta");
		while (e)
		{
			if (e.qx_delta && e.health > 0)
				break;
			e = find (e, classname, "qx_delta");
		}
		if (e)
		{
			spawn_tfog (e.origin);
			qx_sprint4 (p, e.netname, " steps through the gate.\n", "", "");
			remove (e);
			qx_ender_next = time + 0.9;
			return;
		}
		e = find (world, classname, "qx_delta_wait");	// no stragglers
		while (e)
		{
			n = find (e, classname, "qx_delta_wait");
			remove (e);
			e = n;
		}
		qx_ender_phase = 2;
		qx_ender_next = time + 1.5;
		return;
	}
	if (qx_ender_phase == 2)
	{
		QX_Center (p, "Delta Team is through.\n\nYour turn.", "", "", "");
		qx_ender_phase = 3;
		qx_ender_next = time + 2;
		return;
	}
	if (qx_ender_phase == 3)
	{	// in you go (the stock ending from here)
		qx_ender_phase = 4;
		if (!qx_ender_gate)
			return;
		// the ball must be inside her right now, or there's no telefrag: put it there
		e = find (world, targetname, qx_ender_gate.target);
		if (e)
		if (shub)
		if (!QX_EnderInside (qx_ender_gate))
			setorigin (e, shub.origin + '0 0 100');
		oself = self;
		ootheR = other;
		self = qx_ender_gate;
		other = p;
		if (self.targetname)
			self.nextthink = time + 0.2;	// (a gate that waits for a trigger: it has been)
		qx_ender_allow = TRUE;
		activator = p;
		teleport_touch ();
		qx_ender_allow = FALSE;
		self = oself;
		other = ootheR;
	}
};

// from respawn (self = the dead player), after the gate turned on you
void() QX_EnderGo =
{
	qx_ender_go = 2;		// leaving (no second backfire while the save is made)
	// the way back: right here (where you stood before the gate)
	QX_ReviveHere ();
	localcmd ("save qx_back\n");
	localcmd ("alias qx_back \"load qx_back\"\n");
	cvar_set ("scratch1", ftos (QX_ENDER_MODE));
	cvar_set ("scratch2", "0");
	changelevel (QX_ENDER_MAP);
};

// impulse 157 (test): the Cyberdemon boss fight now; win it and you come back
// here (with QX_ENDER_WON set: on end.bsp that's the Delta-goes-first finale)
void() QX_EnderTest =
{
	if (!QX_EnderOn ())
	{
		sprint (self, "THE ENDER needs the QuadEXQ engine (single player)\n");
		return;
	}
	if (self.health <= 0 || qx_arena || qx_duel || qx_arena_go)
		return;
	localcmd ("save qx_back\n");
	localcmd ("alias qx_back \"load qx_back\"\n");
	cvar_set ("scratch1", ftos (QX_ENDER_MODE));
	cvar_set ("scratch2", "0");
	QX_LB ();
	QX_LS ("    THE ENDER test (impulse 157) on ");
	QX_LS (mapname);
	QX_LE ();
	changelevel (QX_ENDER_MAP);
};

// ---------------------------------------------------------------- ender.bsp

void() QX_EnderArenaStart =
{
	local entity p, e, best, m, oself;
	local float d, bestd;

	p = QX_FindLivePlayer ();
	if (!p)
		return;

	// the boss: at a deathmatch spot not too far (not too far for it to come at you)
	best = world;
	bestd = 0;
	e = find (world, classname, "info_player_deathmatch");
	while (e)
	{
		d = vlen (e.origin - p.origin);
		if (d > 350 && d < 1500 && d > bestd)
		{
			best = e;
			bestd = d;
		}
		e = find (e, classname, "info_player_deathmatch");
	}
	if (!best)
		best = QX_DuelFarSpot (p);

	m = spawn ();
	m.classname = "monster_cyber";
	m.qx_spawnclass = "monster_cyber";
	m.angles = '0 0 0';
	m.angles_y = vectoyaw (p.origin - best.origin);
	m.qx_home = best.origin;
	m.qx_homeang = m.angles;
	m.qx_gen = 2;				// never comes back
	setorigin (m, best.origin);
	oself = self;
	self = m;
	qx_respawning = TRUE;
	QX_CallSpawn ("monster_cyber");
	qx_respawning = FALSE;
	self = oself;
	m.qx_ender_boss = 1;
	m.netname = "CYBER DELTA";
	m.effects = m.effects | EF_BRIGHTFIELD;
	m.skin = 1;				// the boss's green paint (progs/cyber.mdl skin 1)
	spawn_tfog (m.origin);
	qx_ender_boss_e = m;

	QX_SpawnScouts (m);
	e = nextent (world);
	while (e)
	{
		if (e.qx_isscout)
		if (e.qx_leader == m)
		{
			e.qx_ender_scout = 1;
			e.skin = 0;			// (the scouts keep the stock colours)
			// tough enough to last until Delta Team comes, and tougher still
			// for a skilled player: PlayerSkill 100 doubles it again
			e.health = e.health * QX_ENDER_SCOUT_HP * (1 + qx_pskill / 100);
			e.max_health = e.health;
		}
		e = nextent (e);
	}

	qx_ender_t0 = time;
	qx_ender_hits = 0;
	QX_EnderBFG (p);
	QX_Center (p, "THE SLIPGATE SPAT YOU OUT\n\n!!! CYBER DELTA !!!\nand two of its scouts\n\nall you've got: the BFG", "", "", "");
	stuffcmd (p, "bf\n");
	QX_LB ();
	QX_LS ("    THE ENDER: Cyber Delta on ");
	QX_LS (mapname);
	QX_LE ();
};

void(entity p) QX_EnderDeltaIn =
{
	qx_ender_delta = TRUE;
	QX_DeltaArrive ();
	QX_Center (p, "!! DELTA TEAM !!\n\nSorry we're late!\nThis one's our job.", "", "", "");
	QX_PlayTrack (QX_ENDER_TRACK);
};

// ender.bsp: the BFG is your only weapon here, and it never runs dry
void(entity p) QX_EnderBFG =
{
	local entity oself;

	if (p.ammo_cells < 100)
		p.ammo_cells = 100;
	if (p.weapon != IT_BFG)
	{
		oself = self;
		self = p;
		self.weapon = IT_BFG;
		W_SetCurrentAmmo ();
		self = oself;
	}
	else
		p.currentammo = p.ammo_cells;
};

// ender.bsp: taken health and armor come back (single player keeps them gone)
void() QX_EnderRegen =
{
	local entity e;

	if (time < qx_ender_regen_scan)
		return;
	qx_ender_regen_scan = time + 1;
	e = nextent (world);
	while (e)
	{
		if (e.classname == "item_health" || e.classname == "item_armor1"
		 || e.classname == "item_armor2" || e.classname == "item_armorInv")
		if (e.model == "")
		if (e.mdl != "")
		{
			if (!e.qx_ender_regen)
				e.qx_ender_regen = time + QX_ENDER_REGEN;
			else if (time > e.qx_ender_regen)
			{
				e.qx_ender_regen = 0;
				e.model = e.mdl;		// as SUB_regen (the size stays)
				e.solid = SOLID_TRIGGER;
				setorigin (e, e.origin);
				sound (e, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);
			}
		}
		e = nextent (e);
	}
};

void(entity p) QX_EnderArenaThink =
{
	local entity e, oself;
	local float n;

	if (!qx_ender_boss_e)
		return;				// not started yet

	if (qx_ender_won_at)
	{
		if (qx_ender_won_at > 0)
		if (time > qx_ender_won_at)
		{	// back to end.bsp, where you stood before the gate, with Delta Team
			qx_ender_won_at = -1;		// (once)
			n = floor (cvar ("scratch3"));
			n = n - (n & (QX_ENDER_WON | 32 | 16));
			cvar_set ("scratch3", ftos (n + QX_ENDER_WON + 32 + 16));
			localcmd ("qx_back\n");
			qx_back_failsafe = time + 3;
		}
		return;
	}

	QX_EnderBFG (p);

	// boss and scouts come for you
	if (!qx_ender_hunted)
	if (time > qx_ender_t0 + 1)
	{
		qx_ender_hunted = TRUE;
		e = nextent (world);
		while (e)
		{
			if (e.qx_ender_boss || e.qx_ender_scout)
			if (e.health > 0)
			{
				oself = self;
				self = e;
				self.enemy = p;
				HuntTarget ();
				self = oself;
			}
			e = nextent (e);
		}
	}

	if (qx_ender_boss_e.health <= 0 || qx_ender_boss_e.classname != "monster_cyber")
	{
		qx_ender_won_at = time + 5;
		QX_Center (p, "!!! CYBER DELTA DOWN !!!\n\nDELTA TEAM:\nNice shot. Now let's finish this.", "", "", "");
		QX_LB ();
		QX_LS ("    THE ENDER: Cyber Delta down");
		QX_LE ();
		return;
	}

	if (!qx_ender_delta)
	if (p.health <= 100 * QX_ENDER_DELTA_HP || time > qx_ender_t0 + QX_ENDER_DELTA_TIME)
		QX_EnderDeltaIn (p);

	QX_EnderBFG (p);
	QX_EnderRegen ();
};

// from T_Damage when qx_ender_arena: the damage to use (0 = none)
float(entity targ, entity inflictor, entity attacker, float damage) QX_EnderDamage =
{
	local entity oself;

	if (targ.qx_ender_scout)
	if (attacker.qx_delta)
		return damage * QX_ENDER_SCOUT_HURT;	// Delta Team makes short work of them

	if (targ.qx_delta)
	if (attacker.classname == "b1")
		return 0;				// your BFG's chain lightning spares the team

	if (!targ.qx_ender_boss)
		return damage;

	// only your BFG, a direct hit (its chain lightning doesn't count)
	if (!(attacker.flags & FL_CLIENT) || inflictor.classname != "b1" || inflictor.owner != attacker)
	{
		if (attacker.flags & FL_CLIENT)
		if (time > qx_ender_hint)
		{
			qx_ender_hint = time + 4;
			QX_Center (attacker, "IT SHRUGS IT OFF!\n\nonly a BFG HIT hurts it", "", "", "");
		}
		return 0;
	}
	if (inflictor.qx_ender_counted)
		return 0;
	inflictor.qx_ender_counted = 1;

	if (!targ.qx_ender_hp0)
		targ.qx_ender_hp0 = targ.health;
	qx_ender_hits = qx_ender_hits + 1;
	if (qx_ender_hits >= QX_ENDER_HITS)
		return targ.health * 10 + 1000;		// down it goes

	targ.health = targ.qx_ender_hp0 * (QX_ENDER_HITS - qx_ender_hits) / QX_ENDER_HITS;
	QX_Center (attacker, "CYBER DELTA\n\nHIT  ", ftos (qx_ender_hits), " / 10", "");	// (one ftos per call: a shared buffer)
	if (targ.th_pain)
	{
		oself = self;
		self = targ;
		self.th_pain (attacker, damage);
		self = oself;
	}
	return 0;
};

// from respawn (self = the dead player): the fight starts over
void() QX_EnderRetry =
{
	cvar_set ("scratch1", ftos (QX_ENDER_MODE));
	cvar_set ("scratch2", "0");
	localcmd ("restart\n");
};

// ---------------------------------------------------------------- every frame

void() QX_EnderThink =
{
	local entity p;

	if (deathmatch || coop)
		return;
	if (intermission_running)
		return;
	p = QX_FindLivePlayer ();
	if (!p)
		return;

	if (qx_ender_arena)
	{
		QX_EnderArenaThink (p);
		return;
	}

	if (!QX_EnderEndMap ())
		return;
	if (!QX_EnderOn ())
		return;
	if (!qx_ender_setup)
	{
		if (time > 1)
			QX_EnderShubLord ();
		return;
	}

	if (serverflags & QX_ENDER_WON)
	{
		qx_ender_go = 0;		// (the save made on the way out still had it)
		if (qx_ender_phase)
			QX_EnderFinaleThink (p);
		return;
	}

	if (qx_ender_go)
		return;

	// "Ummm... Something's wrong!?" as you near the gate
	if (!qx_ender_warned)
	if (qx_ender_gate)
	if (vlen (p.origin - (qx_ender_gate.absmin + qx_ender_gate.absmax) * 0.5) < 360)
	{
		qx_ender_warned = TRUE;
		QX_Center (p, "Ummm...\n\nSomething's wrong!?", "", "", "");
		sound (p, CHAN_AUTO, "misc/talk.wav", 1, ATTN_NONE);
	}

	if (time > qx_ender_rage_next)
		QX_EnderRage (p);
};
