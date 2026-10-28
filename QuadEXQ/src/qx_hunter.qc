/*
==============================================================================
QuadEXQ: the RUNE HUNTER

  A player-like rival that wants your runes. When you come back to the start
  map holding 2 or more runes, it teleports in and challenges you to a
  deathmatch-style duel: first to QX_DUEL_FRAGS frags wins.

    - It is a monster built on the player model, with elite movement
      (circle-strafe, bunny-hop, dodging) and player weapons: a super
      shotgun up close and rockets at range.
    - Its skill is PlayerSkill / 50 (0 .. 2): faster reactions, tighter aim
      and rockets that lead you.
    - During the duel you respawn on the spot (no PlayerSkill penalty, health
      and some ammo back), and so does the hunter, far from you.
    - Win: score bonus. Lose: it takes the rune you got last and runs.
    - The exits are locked while the duel is on.

  Fought once per rune count: serverflags bits 32 / 64 / 128 remember that
  the duel at 2 / 3 / 4 runes is done (they travel with the game and its
  saves, like the runes themselves).
==============================================================================
*/

$frame axrun1 axrun2 axrun3 axrun4 axrun5 axrun6
$frame rockrun1 rockrun2 rockrun3 rockrun4 rockrun5 rockrun6
$frame stand1 stand2 stand3 stand4 stand5
$frame axstnd1 axstnd2 axstnd3 axstnd4 axstnd5 axstnd6
$frame axstnd7 axstnd8 axstnd9 axstnd10 axstnd11 axstnd12
$frame axpain1 axpain2 axpain3 axpain4 axpain5 axpain6
$frame pain1 pain2 pain3 pain4 pain5 pain6
$frame axdeth1 axdeth2 axdeth3 axdeth4 axdeth5 axdeth6
$frame axdeth7 axdeth8 axdeth9
$frame deatha1 deatha2 deatha3 deatha4 deatha5 deatha6 deatha7 deatha8
$frame deatha9 deatha10 deatha11
$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9
$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11 deathc12 deathc13 deathc14 deathc15
$frame deathd1 deathd2 deathd3 deathd4 deathd5 deathd6 deathd7
$frame deathd8 deathd9
$frame deathe1 deathe2 deathe3 deathe4 deathe5 deathe6 deathe7
$frame deathe8 deathe9
$frame nailatt1 nailatt2
$frame ion1 ion2 ion3
$frame light1 light2
$frame rockatt1 rockatt2 rockatt3 rockatt4 rockatt5 rockatt6
$frame shotatt1 shotatt2 shotatt3 shotatt4 shotatt5 shotatt6

float	QX_DUEL_FRAGS		= 10;	// first to this many frags wins
float	QX_HUNTER_LG_DAMAGE	= 16;	// Tres's thunderbolt, per 0.1 s (yours: 30)
float	QX_DUEL_SCORE		= 1000;	// score bonus for beating the hunter
float	QX_HUNTER_HP		= 150;	// + 50 per skill step (150 / 200 / 250), x PlayerSkill growth
float	QX_HUNTER_RESPAWN	= 2.5;	// seconds before it comes back after a frag
float	QX_DUEL_ARMOR_RESPAWN	= 20;	// arena armor comes back this long after pickup (DM: 20s)

.float	qx_duelitem;			// armor spawned for the duel
.float	qx_regen_at;			// when it comes back

// duel state (globals: saved with the game; qx_duel / qx_duel_reload live in qx_defs.qc)
float	qx_duel_checked;		// this start map visit was already checked
float	qx_duel_pf, qx_duel_hf;		// frags: player, hunter
float	qx_duel_runes;			// rune count when the duel began
entity	qx_hunter;			// the hunter currently in play (world while respawning)
// your inventory before the duel: the arena kit is taken back afterwards
float	qx_duel_items, qx_duel_weapon, qx_duel_sh, qx_duel_na, qx_duel_ro, qx_duel_ce;
float	qx_duel_armt, qx_duel_armv;	// armor before the duel (type, value)
float	qx_duel_restore;		// TRUE: give the saved inventory back once you're alive

//.float	qx_hskill;	// declared in qx_defs.qc			// hunter skill 0..2
string	qx_hunter_name;			// who came for you this time
float	qx_arena_pending;		// 1 / 2: start the duel once you're in
float	qx_arena_pick;			// hunter for this arena duel (QX_HunterNameIdx)
string	qx_arena_map;
void() QX_ArenaItems;
float() QX_RevengeRune;
float(float bit) QX_RuneEpisode;
float	qx_back_failsafe;		// still here 3 s after qx_back: go to start
float() QX_DuelWinScore;
void(entity p, float v) QX_ArenaPrize;
float	qx_duel_bonus;			// this arena duel is an arena challenge (no rune at stake)
float	qx_revenge_mode;		// 3 = revenge match, 4 = arena challenge (picked when you die)
float	QX_PERFECT_SCORE	= 10000;	// 10 - 0
float	qx_duel_revenge;		// this arena duel is a revenge match
float	qx_revenge_back;		// after it, go back with the qx_back alias (not to start)

#define QX_REVENGE_CHANCE	0.3		// chance per death while the hunter holds a rune
// serverflags 256 / 512 / 1024 / 2048: the hunter holds the rune of episode 1-4
float(float rune) QX_HoldBit = { return rune * 256; };	// rune bit 1/2/4/8 -> 256..2048

// hunters, by skill (PlayerSkill / 50): GuroFighter < G or K4B < Tres
// (the middle one is a coin toss each duel; K4B fights with the grenade launcher)
float	qx_hunter_gl;			// TRUE: this duel's hunter lobs lead grenades (K4B)

string(float s) QX_HunterName =
{
	if (s >= 2)	return "Tres";
	if (s >= 1)
	{
		if (random () < 0.5)
			return "K4B";
		return "G";
	}
	return "GuroFighter";
};

string(float i) QX_HunterNameIdx =
{
	if (i >= 3)	return "Tres";
	if (i >= 2)	return "K4B";
	if (i >= 1)	return "G";
	return "GuroFighter";
};

float(string n) QX_HunterIdx =
{
	if (n == "Tres")	return 3;
	if (n == "K4B")		return 2;
	if (n == "G")		return 1;
	return 0;
};

float(float n) bitof_n =		// episode 1-4 -> rune bit 1/2/4/8
{
	if (n == 4) return 8;
	if (n == 3) return 4;
	if (n == 2) return 2;
	return 1;
};

float(float sf) QX_RuneCount =
{
	local float n;
	n = 0;
	if (sf & 1) n = n + 1;
	if (sf & 2) n = n + 1;
	if (sf & 4) n = n + 1;
	if (sf & 8) n = n + 1;
	return n;
};

float(float n) QX_DuelDoneBit =	// serverflags bit: duel at n runes is done
{
	if (n == 2) return 32;
	if (n == 3) return 64;
	if (n == 4) return 128;
	return 0;
};

// ---------------------------------------------------------------- weapons

void() QX_HunterFaceEnemy =
{
	local vector dir, at;
	local float lead;

	at = self.enemy.origin + '0 0 12';
	// better hunters lead their rockets
	if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		lead = vlen (at - self.origin) / 1000 * (self.qx_hskill * 0.5);
		at = at + self.enemy.velocity * lead;
	}
	dir = normalize (at - (self.origin + '0 0 16'));
	makevectors (vectoangles (dir));	// right / up around the aim line
	// worse hunters miss more
	dir = dir + (random () - 0.5) * (0.16 - 0.06 * self.qx_hskill) * v_right
	          + (random () - 0.5) * (0.10 - 0.04 * self.qx_hskill) * v_up;
	self.v_angle = vectoangles (normalize (dir));
	self.v_angle_x = 0 - self.v_angle_x;	// vectoangles pitch is up, view pitch is down
	self.angles_y = self.v_angle_y;
};

void() QX_HunterShotgun =
{
	local vector dir;

	QX_HunterFaceEnemy ();
	makevectors (self.v_angle);
	dir = v_forward;
	sound (self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
	self.effects = self.effects | EF_MUZZLEFLASH;
	FireBullets (14, dir, '0.14 0.08 0');
};

// K4B: a ballistic lead shot. Grenades fly 600 u/s flat and fall at
// sv_gravity, so solve for the launch that lands where you'll be.
void() QX_HunterGrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 120, world);
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	BecomeExplosion ();
};

void() QX_HunterGrenadeTouch =
{
	if (other == self.owner)
		return;
	if (other.takedamage == DAMAGE_AIM)
	{
		QX_HunterGrenadeExplode ();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

void() QX_HunterGrenade =
{
	local entity g;
	local vector src, at, flat, hv;
	local float t, d, g8, i;

	src = self.origin + '0 0 16';
	hv = self.enemy.velocity;
	hv_z = 0;					// jumps don't move the landing spot much
	g8 = cvar ("sv_gravity");
	if (g8 <= 0)
		g8 = 800;

	at = self.enemy.origin;
	t = 0;
	i = 0;
	while (i < 3)				// refine: flight time depends on where you'll be
	{
		flat = at - src;
		flat_z = 0;
		t = vlen (flat) / 600;
		if (t > 2.2)
			t = 2.2;
		at = self.enemy.origin + hv * t;
		i = i + 1;
	}
	// a little human error
	at_x = at_x + crandom () * 24;
	at_y = at_y + crandom () * 24;

	flat = at - src;
	d = flat_z;
	flat_z = 0;
	if (t < 0.1)
		t = 0.1;

	self.v_angle = vectoangles (at - src);
	self.v_angle_x = 0 - self.v_angle_x;
	self.angles_y = self.v_angle_y;

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	self.effects = self.effects | EF_MUZZLEFLASH;

	g = spawn ();
	g.owner = self;
	g.movetype = MOVETYPE_BOUNCE;
	g.solid = SOLID_BBOX;
	g.classname = "grenade";
	g.velocity = flat * (1 / t);
	g.velocity_z = d / t + 0.5 * g8 * t;
	g.avelocity = '300 300 300';
	g.angles = vectoangles (g.velocity);
	g.touch = QX_HunterGrenadeTouch;
	g.think = QX_HunterGrenadeExplode;
	g.nextthink = time + 2.5;
	setmodel (g, "progs/grenade.mdl");
	setsize (g, '0 0 0', '0 0 0');
	setorigin (g, src);
};

void() QX_HunterRocket =
{
	local entity missile;

	QX_HunterFaceEnemy ();
	makevectors (self.v_angle);
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
	self.effects = self.effects | EF_MUZZLEFLASH;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";
	missile.velocity = v_forward * 1000;		// your rockets are faster: an edge
	missile.angles = vectoangles (missile.velocity);
	missile.touch = T_MissileTouch;
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;
	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + v_forward * 8 + '0 0 16');
};

// G: super nailgun bursts, nails led at 1000 u/s
void() QX_HunterNail =
{
	local vector at, dir;

	at = self.enemy.origin + '0 0 8';
	at = at + self.enemy.velocity * (vlen (at - self.origin) / 1000) * 0.7;
	dir = normalize (at - (self.origin + '0 0 16'));
	makevectors (vectoangles (dir));
	dir = normalize (dir + crandom () * 0.035 * v_right + crandom () * 0.025 * v_up);
	self.v_angle = vectoangles (dir);
	self.v_angle_x = 0 - self.v_angle_x;
	self.angles_y = self.v_angle_y;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.effects = self.effects | EF_MUZZLEFLASH;
	launch_spike (self.origin + '0 0 16' + dir * 8, dir);
	newmis.touch = superspike_touch;
	newmis.classname = "spike";
	setmodel (newmis, "progs/s_spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	newmis.velocity = dir * 1000;
};

// Tres: the thunderbolt. It aims where you WERE a moment ago (no auto-aim,
// just a very good hand), so strafing still gets you out of the beam.
void() QX_HunterBolt =
{
	local vector org, at, dir;

	if (self.enemy.health <= 0)
		return;
	org = self.origin + '0 0 16';
	at = self.enemy.origin + '0 0 4' - self.enemy.velocity * 0.12;
	dir = normalize (at - org);
	makevectors (vectoangles (dir));
	dir = normalize (dir + crandom () * 0.03 * v_right + crandom () * 0.02 * v_up);
	self.v_angle = vectoangles (dir);
	self.v_angle_x = 0 - self.v_angle_x;
	self.angles_y = self.v_angle_y;

	traceline (org, org + dir * 600, TRUE, self);
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);
	LightningDamage (org, trace_endpos + dir * 4, self, QX_HUNTER_LG_DAMAGE);
};

// Tres: jetpack hops (sideways, a bit toward or away), shooting on the way
void() QX_HunterJetTrail =
{
	if (time > self.ltime || self.owner.health <= 0)
	{
		remove (self);
		return;
	}
	particle (self.owner.origin - '0 0 20', '0 0 -60', 230, 10);
	self.nextthink = time + 0.05;
};

void() QX_HunterJet =
{
	local entity t;
	local vector side;
	local float d;

	if (self.netname != "Tres")
		return;
	if (time < self.qx_jet_next)
		return;
	if (!(self.flags & FL_ONGROUND))
		return;
	if (self.enemy.health <= 0 || !visible (self.enemy))
		return;
	self.qx_jet_next = time + 0.4;
	if (random () > 0.3)
		return;
	self.qx_jet_next = time + 2.5 + random () * 2;

	makevectors (self.angles);
	side = v_right;
	if (random () < 0.5)
		side = '0 0 0' - side;
	d = vlen (self.enemy.origin - self.origin);
	if (d > 600)		side = side + v_forward * 0.6;	// close in
	else if (d < 250)	side = side - v_forward * 0.6;	// back off
	side_z = 0;
	self.velocity = normalize (side) * 380 + '0 0 430';
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	setorigin (self, self.origin + '0 0 2');
	sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
	sound (self, CHAN_AUTO, "weapons/rocket1i.wav", 1, ATTN_NORM);

	t = spawn ();
	t.owner = self;
	t.ltime = time + 0.7;
	t.classname = "qx_hunter_jet";
	t.think = QX_HunterJetTrail;
	t.nextthink = time + 0.05;
};

// ---------------------------------------------------------------- pickups
// Like a FrikBot, the hunter grabs health and armor: when it is hurt (or
// has little armor) it runs for the nearest one it can see, and it takes
// any it walks over. The pickups come back as usual (arena / duel items).

// can it use this item now? 0 = no, else how much it wants it
float(entity it) QX_HunterWants =
{
	local float t, v;

	if (!(it.flags & FL_ITEM) || it.model == "" || it.solid != SOLID_TRIGGER)
		return 0;
	if (it.qx_duelitem != 1)		// only arena / duel pickups (they come back)
		return 0;
	if (it.classname == "item_health")
	{
		if (it.healamount >= 100)		// megahealth: always nice
			return 3;
		if (self.health < self.max_health)
			return 2;
		return 0;
	}
	t = 0;
	if (it.classname == "item_armor1")		{ t = 0.3; v = 100; }
	if (it.classname == "item_armor2")		{ t = 0.6; v = 150; }
	if (it.classname == "item_armorInv")	{ t = 0.8; v = 200; }
	if (t)
	if (self.armortype * self.armorvalue < t * v)
		return 1;
	return 0;
};

void(entity it) QX_HunterTake =
{
	local float t, v;

	if (it.classname == "item_health")
	{
		if (it.healamount >= 100)
			self.health = self.health + 100;
		else if (self.health < self.max_health)
			self.health = self.health + it.healamount;
		if (self.health > self.max_health + 100)
			self.health = self.max_health + 100;
		if (it.healamount < 100)
		if (self.health > self.max_health)
			self.health = self.max_health;
	}
	else
	{
		t = 0.3; v = 100;
		if (it.classname == "item_armor2")		{ t = 0.6; v = 150; }
		if (it.classname == "item_armorInv")	{ t = 0.8; v = 200; }
		self.armortype = t;
		self.armorvalue = v;
		sound (it, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
	}
	if (it.noise != "")
		sound (it, CHAN_ITEM, it.noise, 1, ATTN_NORM);
	// gone, and back later like any pickup (SUB_regen; the duel / arena
	// item think brings back the ones marked qx_duelitem)
	it.model = string_null;
	it.solid = SOLID_NOT;
	it.think = SUB_regen;
	if (deathmatch)
		it.nextthink = time + 20;
	if (self.qx_goalitem == it)
		self.qx_goalitem = world;
};

// from QX_AIRun for the hunter; TRUE = it is running for an item this frame
float() QX_HunterItems =
{
	local entity e, best;
	local float d, bestd, want;

	if (!qx_duel)
		return FALSE;

	// take whatever is in reach
	e = findradius (self.origin, 48);
	while (e)
	{
		if (QX_HunterWants (e))
			QX_HunterTake (e);
		e = e.chain;
	}

	// pick a target now and then
	if (time > self.qx_seek_next)
	{
		self.qx_seek_next = time + 0.5;
		if (!self.qx_goalitem)
		if (self.health < self.max_health * 0.6 || self.armorvalue < 40)
		{
			best = world;
			bestd = 700;
			e = findradius (self.origin, 700);
			while (e)
			{
				want = QX_HunterWants (e);
				if (want)
				if (want >= 2 || self.health >= self.max_health * 0.6)	// hurt: health first
				{
					d = vlen (e.origin - self.origin);
					if (d < bestd)
					{
						traceline (self.origin + '0 0 16', e.origin + '0 0 16', TRUE, self);
						if (trace_fraction == 1)
						{
							bestd = d;
							best = e;
						}
					}
				}
				e = e.chain;
			}
			if (best)
			{
				self.qx_goalitem = best;
				self.qx_seek_until = time + 3;
			}
		}
	}

	if (!self.qx_goalitem)
		return FALSE;
	if (time > self.qx_seek_until || !QX_HunterWants (self.qx_goalitem))
	{
		self.qx_goalitem = world;
		return FALSE;
	}

	// run for it, still shooting when it can
	self.ideal_yaw = vectoyaw (self.qx_goalitem.origin - self.origin);
	ChangeYaw ();
	if (!walkmove (self.ideal_yaw, movedist * 1.2))
		movetogoal (movedist);
	if (time > self.attack_finished)
	if (visible (self.enemy))
	if (random () < 0.25)
	{
		self.qx_seek_until = self.qx_seek_until + 0.6;
		self.th_missile ();
	}
	return TRUE;
};

// ---------------------------------------------------------------- frames

void() rh_stand1;
void() rh_run1;
void() rh_shot1;
void() rh_rock1;

void() QX_HunterAcquire =
{
	local entity p;

	p = QX_FindLivePlayer ();
	if (!p)
		return;
	self.enemy = p;
	HuntTarget ();
};

void() rh_stand1 =[ $stand1, rh_stand2 ] { ai_stand (); if (qx_duel) QX_HunterAcquire (); };
void() rh_stand2 =[ $stand2, rh_stand3 ] { ai_stand (); };
void() rh_stand3 =[ $stand3, rh_stand4 ] { ai_stand (); };
void() rh_stand4 =[ $stand4, rh_stand5 ] { ai_stand (); };
void() rh_stand5 =[ $stand5, rh_stand1 ] { ai_stand (); };

void() QX_HunterRunCheck =
{
	// always knows where you are during the duel
	if (qx_duel)
	if (self.enemy.health <= 0 || !(self.enemy.flags & FL_CLIENT))
		QX_HunterAcquire ();
	QX_HunterJet ();
};

void() rh_run1 =[ $rockrun1, rh_run2 ] { QX_HunterRunCheck (); ai_run (24); };
void() rh_run2 =[ $rockrun2, rh_run3 ] { ai_run (24); };
void() rh_run3 =[ $rockrun3, rh_run4 ] { ai_run (24); };
void() rh_run4 =[ $rockrun4, rh_run5 ] { QX_HunterRunCheck (); ai_run (24); };
void() rh_run5 =[ $rockrun5, rh_run6 ] { ai_run (24); };
void() rh_run6 =[ $rockrun6, rh_run1 ] { ai_run (24); };

void() rh_shot1 =[ $shotatt1, rh_shot2 ] { ai_face (); self.weapon = IT_SUPER_SHOTGUN; QX_HunterShotgun (); };
void() rh_shot2 =[ $shotatt2, rh_shot3 ] { ai_face (); };
void() rh_shot3 =[ $shotatt3, rh_shot4 ] { ai_face (); };
void() rh_shot4 =[ $shotatt4, rh_shot5 ] { ai_face (); };
void() rh_shot5 =[ $shotatt5, rh_shot6 ] { ai_face (); };
void() rh_shot6 =[ $shotatt6, rh_run1  ] { ai_face (); SUB_AttackFinished (1.0 - 0.15 * self.qx_hskill); };

void() rh_rock1 =[ $rockatt1, rh_rock2 ] { ai_face ();
	// K4B: mostly grenades, a rocket now and then (always past 1300)
	if (qx_hunter_gl && vlen (self.enemy.origin - self.origin) < 1300 && random () < 0.7)
	{
		self.weapon = IT_GRENADE_LAUNCHER;
		QX_HunterGrenade ();
	}
	else
	{
		self.weapon = IT_ROCKET_LAUNCHER;
		QX_HunterRocket ();
	}
};
void() rh_rock2 =[ $rockatt2, rh_rock3 ] { ai_face (); };
void() rh_rock3 =[ $rockatt3, rh_rock4 ] { ai_face (); };
void() rh_rock4 =[ $rockatt4, rh_rock5 ] { ai_face (); };
void() rh_rock5 =[ $rockatt5, rh_rock6 ] { ai_face (); };
void() rh_rock6 =[ $rockatt6, rh_run1  ] { ai_face ();
	if (self.weapon == IT_GRENADE_LAUNCHER)
		SUB_AttackFinished (0.75);		// K4B lobs them often
	else
		SUB_AttackFinished (1.3 - 0.25 * self.qx_hskill);
};

// G: super nailgun, a 0.8 s burst
void() rh_nail1 =[ $nailatt1, rh_nail2 ] { ai_face (); self.weapon = IT_SUPER_NAILGUN; QX_HunterNail (); };
void() rh_nail2 =[ $nailatt2, rh_nail3 ] { ai_face (); QX_HunterNail (); };
void() rh_nail3 =[ $nailatt1, rh_nail4 ] { ai_face (); QX_HunterNail (); };
void() rh_nail4 =[ $nailatt2, rh_nail5 ] { ai_face (); QX_HunterNail (); };
void() rh_nail5 =[ $nailatt1, rh_nail6 ] { ai_face (); QX_HunterNail (); };
void() rh_nail6 =[ $nailatt2, rh_nail7 ] { ai_face (); QX_HunterNail (); };
void() rh_nail7 =[ $nailatt1, rh_nail8 ] { ai_face (); QX_HunterNail (); };
void() rh_nail8 =[ $nailatt2, rh_run1  ] { ai_face (); QX_HunterNail (); SUB_AttackFinished (0.7); };

// Tres: thunderbolt, a 0.6 s beam
void() rh_bolt1 =[ $light1, rh_bolt2 ] { ai_face (); self.weapon = IT_LIGHTNING; sound (self, CHAN_WEAPON, "weapons/lstart.wav", 1, ATTN_NORM); QX_HunterBolt (); };
void() rh_bolt2 =[ $light2, rh_bolt3 ] { ai_face (); QX_HunterBolt (); };
void() rh_bolt3 =[ $light1, rh_bolt4 ] { ai_face (); sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM); QX_HunterBolt (); };
void() rh_bolt4 =[ $light2, rh_bolt5 ] { ai_face (); QX_HunterBolt (); };
void() rh_bolt5 =[ $light1, rh_bolt6 ] { ai_face (); QX_HunterBolt (); };
void() rh_bolt6 =[ $light2, rh_run1  ] { ai_face (); QX_HunterBolt (); SUB_AttackFinished (0.6); };

void() rh_attack =
{
	local float d;

	d = vlen (self.enemy.origin - self.origin);
	if (d < 260)
		rh_shot1 ();
	else if (self.netname == "Tres" && d < 600 && random () < 0.7)
		rh_bolt1 ();
	else if (self.netname == "G" && d < 900 && random () < 0.5)
		rh_nail1 ();
	else
		rh_rock1 ();
};

void() rh_pain1 =[ $pain1, rh_pain2 ] {};
void() rh_pain2 =[ $pain2, rh_pain3 ] {};
void() rh_pain3 =[ $pain3, rh_run1  ] {};

void(entity attacker, float damage) rh_pain =
{
	if (self.pain_finished > time)
		return;
	self.pain_finished = time + 1.5;
	sound (self, CHAN_VOICE, "player/pain2.wav", 1, ATTN_NORM);
	if (random () < 0.3 - 0.1 * self.qx_hskill)	// good hunters rarely flinch
		rh_pain1 ();
};

void() rh_die1  =[ $deatha1,  rh_die2  ] {};
void() rh_die2  =[ $deatha2,  rh_die3  ] {};
void() rh_die3  =[ $deatha3,  rh_die4  ] { self.solid = SOLID_NOT; };
void() rh_die4  =[ $deatha4,  rh_die5  ] {};
void() rh_die5  =[ $deatha5,  rh_die6  ] {};
void() rh_die6  =[ $deatha6,  rh_die7  ] {};
void() rh_die7  =[ $deatha7,  rh_die8  ] {};
void() rh_die8  =[ $deatha8,  rh_die9  ] {};
void() rh_die9  =[ $deatha9,  rh_die10 ] {};
void() rh_die10 =[ $deatha10, rh_die11 ] {};
void() rh_die11 =[ $deatha11, rh_die11 ] { self.nextthink = time + 10; self.think = SUB_Remove; };

void() rh_die =
{
	self.effects = 0;
	if (self.health < -40)
	{
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		ThrowHead ("progs/h_player.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib2.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		return;
	}
	sound (self, CHAN_VOICE, "player/death1.wav", 1, ATTN_NORM);
	rh_die1 ();
};

// ---------------------------------------------------------------- spawning

// the spawn spot farthest from the player
// a deathmatch spawn spot away from 'from': a random one of those more than
// 512 units off, or the farthest if none is
entity(entity from) QX_DuelFarSpot =
{
	local entity e, best, pick;
	local float d, bestd, n;

	best = world;
	pick = world;
	bestd = -1;
	n = 0;
	e = nextent (world);
	while (e)
	{
		if (e.classname == "info_player_deathmatch" || e.classname == "info_player_start"
		 || e.classname == "info_player_start2" || e.classname == "info_player_coop")
		{
			d = 0;
			if (from)
				d = vlen (e.origin - from.origin);
			if (d > bestd)
			{
				bestd = d;
				best = e;
			}
			if (d > 512)
			{
				n = n + 1;
				if (random () * n < 1)		// each far spot equally likely
					pick = e;
			}
		}
		e = nextent (e);
	}
	if (pick)
		return pick;
	return best;
};

entity() QX_HunterSpot =
{
	return QX_DuelFarSpot (QX_FindLivePlayer ());
};

void() QX_HunterSpawn =
{
	local entity spot, h, oself;

	spot = QX_HunterSpot ();
	if (!spot)
		return;

	h = spawn ();
	h.classname = "monster_runehunter";
	h.qx_hskill = floor (qx_pskill / 50);		// 0 .. 2
	if (h.qx_hskill > 2)
		h.qx_hskill = 2;
	h.netname = qx_hunter_name;			// picked once per duel
	setorigin (h, spot.origin + '0 0 1');
	h.angles = spot.angles;
	h.solid = SOLID_SLIDEBOX;
	h.movetype = MOVETYPE_STEP;
	setmodel (h, "progs/player.mdl");
	// each hunter wears its own colors (QuadEXQ engine: qx_colormap_ok).
	// Quake colors: 0 white, 4 red, 8 purple, 13 blue. colormap = 32 + shirt * 14 + pants
	if (cvar ("qx_colormap_ok"))
	{
		if (h.netname == "Tres")		h.colormap = 32 + 4 * 14 + 4;
		else if (h.netname == "K4B")	h.colormap = 32 + 13 * 14 + 13;
		else if (h.netname == "G")		h.colormap = 32 + 0 * 14 + 0;
		else							h.colormap = 32 + 8 * 14 + 8;
	}
	setsize (h, VEC_HULL_MIN, VEC_HULL_MAX);
	h.view_ofs = '0 0 22';

	h.health = (QX_HUNTER_HP + 50 * h.qx_hskill) * (1 + QX_F ());
	h.max_health = h.health;
	h.qx_elite = 1;					// elite movement: strafe, bunny-hop, dodge
	h.qx_announced = 1;				// no "ELITE" banner
	h.qx_init = 1;					// stats are set here, not by QX_MonsterSync
	h.qx_tempo = 1 + 0.15 * h.qx_hskill;
	h.effects = EF_DIMLIGHT;

	h.th_stand = rh_stand1;
	h.th_walk = rh_stand1;
	h.th_run = rh_run1;
	h.th_missile = rh_attack;
	h.th_melee = rh_attack;
	h.th_pain = rh_pain;
	h.th_die = rh_die;

	spawn_tfog (h.origin);
	qx_hunter = h;

	oself = self;
	self = h;
	walkmonster_start ();
	self = oself;
};

void() QX_HunterRespawnThink =
{
	if (qx_duel)
		QX_HunterSpawn ();
	remove (self);
};

void() QX_HunterScheduleRespawn =
{
	local entity t;

	t = spawn ();
	t.classname = "qx_hunter_respawn";
	t.think = QX_HunterRespawnThink;
	t.nextthink = time + QX_HUNTER_RESPAWN;
};

// ---------------------------------------------------------------- arena items
// Deathmatch feel: armor, health and weapons on every spawn spot except the
// one you stand on, coming back 20 seconds after they are taken. Removed
// when the duel ends. (The item functions read self.classname, so it has
// to be set: without it armor_touch saw "no armor" and did nothing.)

// spawn one arena item. The item functions read self.classname, so it has to
// be set (without it armor_touch saw "no armor" and did nothing).
void(string cls, vector org, float sf) QX_DuelItem =
{
	local entity a, oself;

	a = spawn ();
	setorigin (a, org);
	a.classname = cls;
	a.spawnflags = sf;			// 1 = big ammo box, 2 = megahealth
	a.qx_duelitem = 1;
	oself = self;
	self = a;
	qx_respawning = TRUE;		// precache calls are skipped (done in worldspawn)
	if (cls == "item_armor1") item_armor1 ();
	else if (cls == "item_armor2") item_armor2 ();
	else if (cls == "item_armorInv") item_armorInv ();
	else if (cls == "item_artifact_super_damage") item_artifact_super_damage ();
	else if (cls == "item_cells") item_cells ();
	else if (cls == "item_health") item_health ();
	else if (cls == "item_rockets") item_rockets ();
	else if (cls == "item_shells") item_shells ();
	else if (cls == "item_spikes") item_spikes ();
	else if (cls == "weapon_grenadelauncher") weapon_grenadelauncher ();
	else if (cls == "weapon_lightning") weapon_lightning ();
	else if (cls == "weapon_nailgun") weapon_nailgun ();
	else if (cls == "weapon_rocketlauncher") weapon_rocketlauncher ();
	else if (cls == "weapon_supernailgun") weapon_supernailgun ();
	else if (cls == "weapon_supershotgun") weapon_supershotgun ();
	qx_respawning = FALSE;
	self = oself;
	spawn_tfog (a.origin);
};

// an extra deathmatch spawn spot for the duel (removed when it ends)
void(vector org, float ang) QX_DuelSpot =
{
	local entity e;

	e = spawn ();
	e.classname = "info_player_deathmatch";
	e.qx_duelitem = 2;
	setorigin (e, org);
	e.angles = '0 0 0';
	e.angles_y = ang;
};

// deathmatch-only brushes of start.bsp: walls and teleporters. Inline brush
// models ("*30") are part of the map, so they need no precache.
void(string m) QX_DuelWall =
{
	local entity e, p, oself;

	e = spawn ();
	e.classname = "func_wall";
	e.model = m;
	e.qx_duelitem = 2;
	oself = self;
	self = e;
	func_wall ();
	self = oself;
	// never wall the player in: skip it if you stand inside
	p = QX_FindLivePlayer ();
	if (p)
	if (p.absmax_x > e.absmin_x && p.absmin_x < e.absmax_x)
	if (p.absmax_y > e.absmin_y && p.absmin_y < e.absmax_y)
	if (p.absmax_z > e.absmin_z && p.absmin_z < e.absmax_z)
		remove (e);
};

void(string m, string targ) QX_DuelTele =
{
	local entity e, oself;

	e = spawn ();
	e.classname = "trigger_teleport";
	e.model = m;
	e.target = targ;
	e.spawnflags = SILENT;		// no ambient hum: static sounds can't be added mid-game
	e.qx_duelitem = 2;
	oself = self;
	self = e;
	trigger_teleport ();
	self = oself;
};

void(vector org, float ang, string nm) QX_DuelDest =
{
	local entity e, oself;

	e = spawn ();
	e.classname = "info_teleport_destination";
	e.targetname = nm;
	e.qx_duelitem = 2;
	setorigin (e, org);
	e.angles = '0 0 0';
	e.angles_y = ang;
	oself = self;
	self = e;
	info_teleport_destination ();
	self = oself;
};

// start.bsp keeps its whole deathmatch layout behind "not in single player"
// spawnflags (the red armor in the pool, the Quad Damage, the weapons, four of
// the six DM spawn spots...). In single player none of it exists, so the
// duel brings it back. Positions are taken from id's start.bsp.
float() QX_DuelStartLayout =
{
	if (mapname != "start")
		return FALSE;
	QX_DuelSpot ('-64 1728 104', 0);
	QX_DuelSpot ('1248 1728 128', 180);
	QX_DuelSpot ('1184 2320 88', 180);
	QX_DuelSpot ('0 2368 88', 0);
	QX_DuelItem ("item_armorInv", '1104 1728 16', 0);
	QX_DuelItem ("weapon_supernailgun", '1940 1728 -268', 0);
	QX_DuelItem ("item_spikes", '1568 1712 -384', 1);
	QX_DuelItem ("weapon_rocketlauncher", '800 2320 64', 0);
	QX_DuelItem ("item_rockets", '1392 3120 208', 0);
	QX_DuelItem ("item_rockets", '1664 3120 208', 0);
	QX_DuelItem ("weapon_grenadelauncher", '-96 2368 64', 0);
	QX_DuelItem ("item_rockets", '-544 2240 112', 1);
	QX_DuelItem ("item_armor2", '-528 2480 112', 0);
	QX_DuelItem ("weapon_supershotgun", '-200 1552 80', 0);
	QX_DuelItem ("item_shells", '56 1536 80', 1);
	QX_DuelItem ("weapon_nailgun", '864 1232 -32', 0);
	QX_DuelItem ("item_spikes", '736 1312 -32', 1);
	QX_DuelItem ("item_health", '320 1312 -32', 0);
	QX_DuelItem ("item_health", '640 1312 -32', 0);
	QX_DuelItem ("item_health", '944 1312 -32', 1);
	QX_DuelItem ("weapon_lightning", '1544 2928 208', 0);
	QX_DuelItem ("item_cells", '1424 2952 208', 1);
	QX_DuelItem ("item_cells", '1632 2952 208', 1);
	QX_DuelItem ("item_artifact_super_damage", '64 1872 -360', 0);
	QX_DuelItem ("item_rockets", '-264 1864 -384', 1);
	QX_DuelItem ("item_cells", '-200 1912 -384', 1);
	QX_DuelItem ("item_shells", '536 2144 -224', 0);
	QX_DuelItem ("item_spikes", '648 2072 -208', 0);
	QX_DuelItem ("item_health", '144 2192 -304', 2);
	QX_DuelWall ("*30");
	QX_DuelWall ("*31");
	QX_DuelWall ("*32");
	QX_DuelWall ("*33");
	QX_DuelTele ("*45", "t7");
	QX_DuelDest ('-104 1976 -376', 270, "t7");
	QX_DuelWall ("*46");
	QX_DuelWall ("*47");
	QX_DuelTele ("*49", "t8");
	QX_DuelDest ('1224 1728 112', 180, "t8");
	QX_DuelWall ("*53");
	return TRUE;
};

// any other map (practice duels): items on the spawn spots
void() QX_DuelArmorSpawn =
{
	local entity p, e;
	local float n;
	local vector o;

	if (QX_DuelStartLayout ())
		return;

	p = QX_FindLivePlayer ();
	n = 0;
	e = nextent (world);
	while (e && n < 8)
	{
		if (e.classname == "info_player_deathmatch" || e.classname == "info_player_start"
		 || e.classname == "info_player_start2" || e.classname == "info_player_coop")
		if (!p || vlen (e.origin - p.origin) > 200)
		{
			o = e.origin + '0 0 8';
			if (n == 1)      QX_DuelItem ("weapon_grenadelauncher", o, 0);
			else if (n == 2) QX_DuelItem ("item_health", o, 0);
			else if (n == 3) QX_DuelItem ("weapon_rocketlauncher", o, 0);
			else if (n == 4) QX_DuelItem ("item_armor2", o, 0);
			else if (n == 5) QX_DuelItem ("weapon_supernailgun", o, 0);
			else if (n == 6) QX_DuelItem ("item_health", o, 0);
			else if (n == 7) QX_DuelItem ("weapon_lightning", o, 0);
			else             QX_DuelItem ("item_armor1", o, 0);
			n = n + 1;
		}
		e = nextent (e);
	}
};

void() QX_DuelArmorThink =		// pickups come back like in deathmatch
{
	local entity e, oself;

	e = nextent (world);
	while (e)
	{
		if (e.qx_duelitem == 1)
		if (e.model == "")
		{
			if (!e.qx_regen_at)
			{
				e.qx_regen_at = time + QX_DUEL_ARMOR_RESPAWN;
				if (e.classname == "item_artifact_super_damage" || e.classname == "item_artifact_invulnerability"
				 || e.classname == "item_artifact_invisibility" || e.classname == "item_artifact_envirosuit")
					e.qx_regen_at = time + 60;		// powerups: as in deathmatch
			}
			else if (time > e.qx_regen_at)
			{
				e.qx_regen_at = 0;
				oself = self;
				self = e;
				SUB_regen ();
				self = oself;
			}
		}
		e = nextent (e);
	}
};

void() QX_DuelArmorRemove =
{
	local entity e, next;

	e = nextent (world);
	while (e)
	{
		next = nextent (e);
		if (e.qx_duelitem)
			remove (e);
		e = next;
	}
};

// ---------------------------------------------------------------- the duel

void() QX_DuelScoreboard =
{
	local entity p;

	p = QX_FindLivePlayer ();
	if (!p)
		p = find (world, classname, "player");
	if (!p || !p.ishuman)
		return;
	qx_cprint8 (p, "YOU  ", ftos (qx_duel_pf), "  :  ", ftos (qx_duel_hf),
		"  ", qx_hunter_name, "\n\nfirst to 10", "");
};

// the arena kit: super shotgun + nailgun and ammo. The rocket launcher is in
// the hunter's backpack each time you frag it.
void(entity p) QX_DuelKit =
{
	p.items = p.items | IT_SUPER_SHOTGUN | IT_NAILGUN;
	if (p.ammo_shells < 50)	p.ammo_shells = 50;
	if (p.ammo_nails < 100)	p.ammo_nails = 100;
	if (p.weapon == IT_AXE || p.weapon == IT_SHOTGUN || p.weapon == IT_BLASTER)
		p.weapon = IT_SUPER_SHOTGUN;
	if (p.health < 100)
		p.health = 100;
	p.qx_adren = QX_DUEL_ADREN_MIN;
	self = p;
	W_SetCurrentAmmo ();
};

void() QX_DuelStart =
{
	local entity p, oself;

	p = QX_FindLivePlayer ();
	if (!p)
		return;
	qx_duel_items = p.items;
	qx_duel_weapon = p.weapon;
	qx_duel_sh = p.ammo_shells;
	qx_duel_na = p.ammo_nails;
	qx_duel_ro = p.ammo_rockets;
	qx_duel_ce = p.ammo_cells;
	qx_duel_armt = p.armortype;
	qx_duel_armv = p.armorvalue;
	oself = self;
	QX_DuelKit (p);
	self = oself;

	qx_duel = TRUE;
	qx_duel_pf = 0;
	qx_duel_hf = 0;
	qx_duel_runes = QX_RuneCount (serverflags);
	if (qx_arena)
		qx_hunter_name = QX_HunterNameIdx (qx_arena_pick);	// announced before the trip
	else
		qx_hunter_name = QX_HunterName (floor (qx_pskill / 50));
	qx_hunter_gl = (qx_hunter_name == "K4B");
	QX_HunterSpawn ();
	if (!qx_hunter)
	{
		qx_duel = FALSE;
		return;
	}
	if (qx_arena)
		QX_ArenaItems ();		// the arena's own pickups respawn as in deathmatch
	else
		QX_DuelArmorSpawn ();
	QX_PlayTrack (QX_BOSS_MUSIC_TRACK);
	if (qx_duel_bonus)
		qx_cprint8 (p, "Welcome to EXQ Arena!!\n\n!! ARENA CHALLENGE !!\n\n", qx_hunter_name, " wants a fight\nnothing to lose\n\narena: ", mapname, "\n", world.message, "\n\nfirst to 10 frags", "");
	else if (qx_duel_revenge)
		qx_cprint8 (p, "Welcome to EXQ Arena!!\n\n!! REVENGE MATCH !!\n\n", qx_hunter_name, " has your rune of episode ",
			ftos (QX_RuneEpisode (QX_RevengeRune ())), "\nnothing to lose - win it back\n\narena: ", mapname, "\nfirst to 10 frags", "");
	else if (qx_arena)
		qx_cprint8 (p, "Welcome to EXQ Arena!!\n\n!!! RUNE HUNTER: ", qx_hunter_name, " !!!\n\narena: ", mapname, "\n", world.message, "\n\nfirst to 10 frags", "");
	else
		QX_CenterAll ("!!! RUNE HUNTER: ", qx_hunter_name, " !!!\n\nwants your runes\nfirst to 10 frags", "");
	sound (world, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NONE);

	qx_rep_to = world;
	QX_LB ();
	QX_LS ("    RUNE HUNTER ");
	QX_LS (qx_hunter_name);
	QX_LS (" - duel begins   runes ");
	QX_LN (qx_duel_runes);
	QX_LS ("   hunter skill ");
	QX_LN (floor (qx_pskill / 50));
	QX_LS ("   PlayerSkill ");
	QX_LN (qx_pskill);
	QX_LE ();
};

void(float won) QX_DuelEnd =
{
	local float bit, n, pts, wb;
	local entity e, p;

	qx_duel = FALSE;
	qx_duel_restore = TRUE;		// the arena kit goes back once you're on your feet
	QX_DuelArmorRemove ();
	QX_PlayTrack (qx_maptrack);

	// remove the hunter and any pending respawn
	e = find (world, classname, "qx_hunter_respawn");
	while (e)
	{
		remove (e);
		e = find (world, classname, "qx_hunter_respawn");
	}
	if (qx_hunter)
	if (qx_hunter.health > 0)
	{
		spawn_tfog (qx_hunter.origin);
		remove (qx_hunter);
	}
	qx_hunter = world;

	// the hunter's backpacks (with its rocket launcher) belong to the arena
	e = nextent (world);
	while (e)
	{
		if (e.touch == BackpackTouch)
		if (e.items == IT_ROCKET_LAUNCHER)
		{
			e.touch = SUB_Null;
			e.think = SUB_Remove;
			e.nextthink = time + 0.1;
		}
		e = nextent (e);
	}

	qx_rep_to = world;
	QX_LB ();
	if (qx_duel_revenge)
	{	// revenge match: nothing to lose, the rune to win back
		qx_duel_revenge = FALSE;
		qx_revenge_back = TRUE;
		bit = QX_RevengeRune ();
		if (won && bit)
		{
			serverflags = serverflags | bit;
			serverflags = serverflags - (serverflags & QX_HoldBit (bit));
			cvar_set ("scratch3", ftos (bit));	// survives the checkpoint load on the way back
			pts = QX_DuelWinScore ();
			cvar_set ("scratch4", ftos (pts * 128));	// score, given after the trip back
			if (pts == QX_PERFECT_SCORE)
				QX_CenterAll ("!!! PERFECT !!!\n\n", qx_hunter_name, " DEFEATED 10 - 0\nyour rune is back\nSCORE +", ftos (pts));
			else
				QX_CenterAll ("!!! YOU WIN !!!\n\n", qx_hunter_name, " DEFEATED\nyour rune is back\nSCORE +", ftos (pts));
			QX_LS ("    RUNE HUNTER revenge match won, rune back, score ");
			QX_LN (pts);
			QX_LS ("  ");
		}
		else
		{
			QX_CenterAll ("YOU LOSE\n\n", qx_hunter_name, " keeps your rune...\nmaybe next time", "");
			QX_LS ("    RUNE HUNTER revenge match lost  ");
		}
	}
	else if (qx_duel_bonus)
	{	// arena challenge: nothing to lose, the arena weapons and a score to win
		qx_duel_bonus = FALSE;
		qx_revenge_back = TRUE;
		if (won)
		{
			p = find (world, classname, "player");
			wb = 0;
			if (p)
				wb = p.items & (IT_SUPER_SHOTGUN | IT_NAILGUN | IT_SUPER_NAILGUN | IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER | IT_LIGHTNING);
			pts = QX_DuelWinScore ();
			cvar_set ("scratch4", ftos (wb + pts * 128));	// weapons + score, given after the trip back
			if (pts == QX_PERFECT_SCORE)
				QX_CenterAll ("!!! PERFECT !!!\n\n", qx_hunter_name, " DEFEATED 10 - 0\nyou keep the arena weapons\nSCORE +", ftos (pts));
			else
				QX_CenterAll ("!!! YOU WIN !!!\n\n", qx_hunter_name, " DEFEATED\nyou keep the arena weapons\nSCORE +", ftos (pts));
			QX_LS ("    RUNE HUNTER arena challenge won, score ");
			QX_LN (pts);
			QX_LS ("  ");
		}
		else
		{
			QX_CenterAll ("YOU LOSE\n\n", qx_hunter_name, " WINS\nno harm done", "");
			QX_LS ("    RUNE HUNTER arena challenge lost  ");
		}
	}
	else if (qx_duel_test)
	{	// impulse 152 practice duel: nothing is won or lost
		qx_duel_test = FALSE;
		if (won)
			QX_CenterAll ("!!! YOU WIN !!!\n\nPRACTICE: ", qx_hunter_name, " DEFEATED", "");
		else
			QX_CenterAll ("YOU LOSE\n\nPRACTICE: ", qx_hunter_name, " WINS", "");
		QX_LS ("    RUNE HUNTER practice duel  ");
	}
	else if (won)
	{
		bit = QX_DuelDoneBit (qx_duel_runes);
		serverflags = serverflags | bit;
		pts = QX_DuelWinScore ();
		qx_st_points = qx_st_points + pts;
		if (pts == QX_PERFECT_SCORE)
			QX_CenterAll ("!!! PERFECT !!!\n\n", qx_hunter_name, " DEFEATED 10 - 0\nyour runes are safe\nSCORE +", ftos (pts));
		else
			QX_CenterAll ("!!! YOU WIN !!!\n\n", qx_hunter_name, " DEFEATED\nyour runes are safe\nSCORE +", ftos (pts));
		QX_LS ("    RUNE HUNTER ");
		QX_LS (qx_hunter_name);
		QX_LS (" defeated  ");
	}
	else
	{
		// it takes the rune you got last (the highest episode) and runs
		if (serverflags & 8)		{ serverflags = serverflags - 8; n = 4; }
		else if (serverflags & 4)	{ serverflags = serverflags - 4; n = 3; }
		else if (serverflags & 2)	{ serverflags = serverflags - 2; n = 2; }
		else if (serverflags & 1)	{ serverflags = serverflags - 1; n = 1; }
		serverflags = serverflags | QX_HoldBit (bitof_n (n));	// it has it now: revenge matches
		// don't pounce again right away at the new, lower count
		serverflags = serverflags | QX_DuelDoneBit (QX_RuneCount (serverflags));
		QX_CenterAll ("YOU LOSE\n\n", qx_hunter_name, " took the rune of episode ", ftos (n));
		QX_LS ("    RUNE HUNTER ");
		QX_LS (qx_hunter_name);
		QX_LS (" won, took the rune of episode ");
		QX_LN (n);
		QX_LS ("  ");
		// reload the start map so the episode gates match the runes
		qx_duel_reload = time + 4;
	}
	QX_LN (qx_duel_pf);
	QX_LS (" - ");
	QX_LN (qx_duel_hf);
	QX_LE ();

	if (qx_arena)
		qx_duel_reload = time + 4;	// back to start, win or lose
};

// 1000 for a win, 10000 for a perfect 10 - 0
float() QX_DuelWinScore =
{
	if (qx_duel_hf == 0)
		return QX_PERFECT_SCORE;
	return QX_DUEL_SCORE;
};

// the hunter was killed (from QX_OnKilled)
void(entity targ, entity attacker) QX_HunterDown =
{
	if (!qx_duel)
		return;
	if (targ != qx_hunter)
		return;
	qx_hunter = world;
	qx_duel_pf = qx_duel_pf + 1;
	if (attacker.flags & FL_CLIENT)
	{	// a frag pumps you up
		attacker.qx_adren = attacker.qx_adren + QX_ADREN_KILL;
		if (attacker.qx_adren > 100)
			attacker.qx_adren = 100;
	}
	if (qx_duel_pf >= QX_DUEL_FRAGS)
	{
		QX_DuelEnd (TRUE);
		return;
	}
	QX_DuelScoreboard ();
	QX_HunterScheduleRespawn ();
};

// the player died during the duel (from QX_PlayerDied): a frag for the hunter
void() QX_HunterScored =
{
	qx_duel_hf = qx_duel_hf + 1;
	if (qx_duel_hf >= QX_DUEL_FRAGS)
	{
		QX_DuelEnd (FALSE);
		return;
	}
	QX_DuelScoreboard ();
};

// respawn() during the duel: back in at once, deathmatch style (self = player)
void() QX_DuelRespawn =
{
	local float it, w, sh, na, ro, ce, jet;
	local entity oself, spot;

	it = self.items;
	w = self.weapon;
	sh = self.ammo_shells;
	na = self.ammo_nails;
	ro = self.ammo_rockets;
	ce = self.ammo_cells;
	jet = self.qx_hasjet;

	CopyToBodyQue (self);
	PutClientInServer ();
	if (qx_duel)						// deathmatch: respawn away from the hunter
	{
		spot = QX_DuelFarSpot (qx_hunter);
		if (spot)
		{
			setorigin (self, spot.origin + '0 0 1');
			self.angles = spot.angles;
			self.fixangle = TRUE;
			spawn_tfog (self.origin);
		}
	}

	// (not the armor icon: a fresh life has no armor)
	self.items = self.items | (it - (it & (IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD | IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3)));
	self.ammo_shells = sh;   if (self.ammo_shells < 25)  self.ammo_shells = 25;
	self.ammo_nails = na;    if (self.ammo_nails < 50)   self.ammo_nails = 50;
	self.ammo_rockets = ro;  if (self.ammo_rockets < 10) self.ammo_rockets = 10;
	self.ammo_cells = ce;    if (self.ammo_cells < 20)   self.ammo_cells = 20;
	self.qx_hasjet = jet;
	self.weapon = w;
	if (qx_duel)
	{
		oself = self;
		QX_DuelKit (self);
		self = oself;
	}
	W_SetCurrentAmmo ();
	self.health = 100;
	if (qx_duel)
		QX_DuelScoreboard ();
};

// impulse 152: practice duel on any map, right now (self = player).
// Pick the hunter first with PlayerSkill, e.g. "qx_playerskill 101" (= 100: Tres).
// Nothing is won or lost. Runes, saves and the real duels are untouched.
void() QX_DuelPractice =
{
	if (deathmatch || coop)
		return;
	if (qx_duel)
	{
		sprint (self, "A duel is already on\n");
		return;
	}
	qx_duel_test = TRUE;
	QX_DuelStart ();
	if (!qx_duel)
		qx_duel_test = FALSE;
};

// ---------------------------------------------------------------- arenas
// The real duel doesn't happen in start.bsp: the hunter calls you out and
// you both go to a deathmatch map, fight there, and come back to start.
// A changelevel forgets every QC global, so the call crosses over in the
// engine's spare cvars: scratch1 = 1 real duel / 2 practice, scratch2 = who.
// Runes and the "duel done" bits are serverflags, which do carry over.


string() QX_ArenaPick =
{
	local float r;

	r = random () * 7;
	if (r < 1)	return "dm1";
	if (r < 2)	return "dm2";
	if (r < 3)	return "dm3";
	if (r < 4)	return "dm4";
	if (r < 5)	return "dm5";
	if (r < 6)	return "dm6";
	return "towersp";
};

void(float mode) QX_ArenaCall =
{
	local string nm;

	nm = QX_HunterName (floor (qx_pskill / 50));
	if (cvar ("qx_arena_ok"))
		qx_arena_map = "";			// the engine picks (qx_arena): any dm map you have
	else
		qx_arena_map = QX_ArenaPick ();	// older engine: fixed list
	cvar_set ("scratch1", ftos (mode));
	cvar_set ("scratch2", ftos (QX_HunterIdx (nm)));
	qx_arena_go = time + 3;
	if (mode == 2)
		QX_CenterAll ("PRACTICE DUEL: ", nm, "\n\noff to an arena...", "");
	else
		QX_CenterAll ("!!! RUNE HUNTER: ", nm, " !!!\n\nwants your runes\nmeet me in the arena...", "");
	sound (world, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NONE);
};

// from QX_WorldSpawn on every new map
void() QX_ArenaInit =
{
	qx_arena_go = 0;
	qx_arena = FALSE;
	qx_arena_pending = floor (cvar ("scratch1"));
	if (qx_arena_pending < 1 || qx_arena_pending > 4 || deathmatch || coop)
	{
		qx_arena_pending = 0;
		return;
	}
	qx_arena_pick = floor (cvar ("scratch2"));
	cvar_set ("scratch1", "0");	// one trip only
	qx_arena = TRUE;
	qx_boss_picked = 1;		// no map boss in an arena
};

// nobody else is invited (towersp has wizards)
void() QX_ArenaClear =
{
	local entity e, next;

	e = nextent (world);
	while (e)
	{
		next = nextent (e);
		if (e.flags & FL_MONSTER)
		if (e != qx_hunter)
		if (e.classname != "monster_runehunter")
		{
			total_monsters = total_monsters - 1;
			remove (e);
		}
		e = next;
	}
	if (total_monsters < 0)
		total_monsters = 0;
};

void() QX_ArenaItems =
{
	local entity e;

	e = nextent (world);
	while (e)
	{
		if (e.flags & FL_ITEM)
		if (e.touch != BackpackTouch)
			e.qx_duelitem = 1;
		e = nextent (e);
	}
};

// ---------------------------------------------------------------- revenge match
// While the hunter holds one of your runes, every death has a chance
// (QX_REVENGE_CHANCE) of a REVENGE MATCH instead of the checkpoint: off to
// an arena, nothing to lose, and a win brings the rune back. Afterwards you
// return to the map you died on (its checkpoint, via the qx_back alias).

// the rune bit the hunter holds (the latest episode first), 0 = none
float() QX_RevengeRune =
{
	if (serverflags & 2048) return 8;
	if (serverflags & 1024) return 4;
	if (serverflags & 512)  return 2;
	if (serverflags & 256)  return 1;
	return 0;
};

float(float bit) QX_RuneEpisode =
{
	if (bit == 8) return 4;
	if (bit == 4) return 3;
	if (bit == 2) return 2;
	return 1;
};

// scratch4 = weapon bits (below 128) + score * 128
void(entity p, float v) QX_ArenaPrize =
{
	local float wb, pts;
	local entity oself;

	cvar_set ("scratch4", "0");
	pts = floor (v / 128);
	wb = v - pts * 128;
	if (wb)
	{
		p.items = p.items | wb;
		if (wb & IT_SUPER_SHOTGUN)		if (p.ammo_shells < 40)		p.ammo_shells = 40;
		if (wb & (IT_NAILGUN | IT_SUPER_NAILGUN))	if (p.ammo_nails < 80)	p.ammo_nails = 80;
		if (wb & (IT_GRENADE_LAUNCHER | IT_ROCKET_LAUNCHER))	if (p.ammo_rockets < 20)	p.ammo_rockets = 20;
		if (wb & IT_LIGHTNING)			if (p.ammo_cells < 50)		p.ammo_cells = 50;
		oself = self;
		self = p;
		W_SetCurrentAmmo ();
		self = oself;
		sprint (p, "Arena prize: you keep the arena weapons\n");
	}
	if (pts)
	{
		qx_st_points = qx_st_points + pts;
		sprint (p, "Arena prize: SCORE +");
		sprint (p, ftos (pts));
		sprint (p, "\n");
	}
};

// from QX_PlayerDied (self = the player)
void() QX_RevengeRoll =
{
	local string why;

	qx_revenge_pending = FALSE;
	why = "";
	if (deathmatch || coop)		why = "not single player";
	else if (!qx_newengine)		why = "needs the QuadEXQ engine";
	else if (qx_duel)			why = "a duel is on";
	else if (qx_arena)			why = "already in an arena";
	else if (qx_arena_go)		why = "already leaving for an arena";
	else if (qx_duel_reload)	why = "a duel is just ending";
	if (why != "")
	{
		if (serverflags & 4096)		// impulse 154 test: say why not
		{
			sprint (self, "Revenge test: no revenge match - ");
			sprint (self, why);
			sprint (self, "\n");
			QX_LB ();
			QX_LS ("    RUNE HUNTER revenge test blocked: ");
			QX_LS (why);
			QX_LE ();
		}
		return;
	}
	// serverflags 4096 = impulse 154 test: the next death is sure to call it.
	// (A serverflag, not a global: globals are reset on every new map.)
	if (!(serverflags & 4096))
	if (random () >= QX_REVENGE_CHANCE)
		return;
	serverflags = serverflags - (serverflags & 4096);
	qx_revenge_pending = TRUE;
	if (QX_RevengeRune ())
	{
		qx_revenge_mode = 3;
		QX_Center (self, "!! REVENGE MATCH !!\n\nthe RUNE HUNTER has your rune\nof episode ",
			ftos (QX_RuneEpisode (QX_RevengeRune ())), "\n\nrespawn to take it back", "");
	}
	else
	{
		qx_revenge_mode = 4;
		QX_Center (self, "!! ARENA CHALLENGE !!\n\nthe RUNE HUNTER wants a fight\nnothing to lose: win and keep\nthe arena weapons", "", "", "");
	}
	sound (world, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NONE);
};

// the dead player stands up again at its last safe footing (on this map),
// with QX_RESTART_HEALTH, and 3 s safe from damage once back from the arena
void() QX_ReviveHere =
{
	if (self.qx_safe_next)
	{
		self.origin = self.qx_safe_org;
		self.angles = self.qx_safe_ang;
		self.angles_x = 0;
		self.angles_z = 0;
		self.fixangle = TRUE;
	}
	self.health = QX_RESTART_HEALTH;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.deadflag = DEAD_NO;
	self.velocity = '0 0 0';
	self.air_finished = time + 12;
	self.dmg = 2;
	self.pausetime = 0;
	self.attack_finished = time;
	self.view_ofs = '0 0 22';
	setmodel (self, "progs/player.mdl");
	modelindex_player = self.modelindex;
	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	setorigin (self, self.origin);
	W_SetCurrentAmmo ();
	player_stand1 ();
	self.qx_back_prot = time + 3;
};

// from respawn() instead of the checkpoint (self = the dead player)
void() QX_RevengeGo =
{
	local string nm;

	qx_revenge_pending = FALSE;
	// the way back: this map from its checkpoint (classic trick: localcmd
	// text is joined in the command buffer, so the map name can go in the middle)
	// ("changelevel X; qx_respawn" was two level changes at once: Host_Error
	// "received signon 1 when at 1". qx_return does it in one step.)
	if (cvar ("qx_arena_ok") >= 2)
	{	// back to where you died: stand up again at your last safe footing,
		// save that to a hidden save (qx_back.sav, not one of the menu slots)
		// and load it after the arena
		QX_ReviveHere ();
		localcmd ("save qx_back\n");
		localcmd ("alias qx_back \"load qx_back\"\n");
	}
	else
		localcmd ("alias qx_back \"load s19\"\n");	// older engine: the autosave slot

	nm = QX_HunterName (floor (qx_pskill / 50));
	cvar_set ("scratch1", ftos (qx_revenge_mode));
	cvar_set ("scratch2", ftos (QX_HunterIdx (nm)));
	QX_LB ();
	if (qx_revenge_mode == 4)
		QX_LS ("    RUNE HUNTER arena challenge called  ");
	else
		QX_LS ("    RUNE HUNTER revenge match called  ");
	QX_LE ();
	if (cvar ("qx_arena_ok"))
		localcmd ("qx_arena\n");
	else
		changelevel (QX_ArenaPick ());
};

// impulse 154 (test): the hunter "holds" your episode 1 rune and your next
// death is sure to bring a revenge match. Win it and you get that rune.
void() QX_RevengeTest =
{
	if (deathmatch || coop)
		return;
	serverflags = serverflags | 256 | 4096;
	QX_LB ();
	QX_LS ("    RUNE HUNTER revenge test armed on ");
	QX_LS (mapname);
	QX_LE ();
	sprint (self, "Revenge test: the hunter holds your episode 1 rune. Your next death calls a revenge match.\n");
};

// impulse 155 (test): your next death is sure to call an arena challenge
// (or a revenge match, if the hunter holds one of your runes)
void() QX_ChallengeTest =
{
	if (deathmatch || coop)
		return;
	serverflags = serverflags | 4096;
	sprint (self, "Arena test: your next death calls an arena challenge.\n");
	QX_LB ();
	QX_LS ("    RUNE HUNTER arena challenge test armed on ");
	QX_LS (mapname);
	QX_LE ();
};

// impulse 153: practice duel in a random arena, then back to start
void() QX_ArenaPractice =
{
	if (deathmatch || coop)
		return;
	if (qx_duel || qx_arena_go || qx_arena)
	{
		sprint (self, "Not now: a duel is already on\n");
		return;
	}
	QX_ArenaCall (2);
};

// every frame from QX_StartFrame
void() QX_DuelThink =
{
	local float n;
	local entity p, oself;

	if (deathmatch || coop)
		return;

	// give back what you had before the duel (the arena kit was a loan)
	if (qx_duel_restore)
	if (!qx_duel)
	{
		p = QX_FindLivePlayer ();
		if (p)
		{
			qx_duel_restore = FALSE;
			p.items = qx_duel_items | (p.items & (IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD));
			p.weapon = qx_duel_weapon;
			p.ammo_shells = qx_duel_sh;
			p.ammo_nails = qx_duel_na;
			p.ammo_rockets = qx_duel_ro;
			p.ammo_cells = qx_duel_ce;
			// the armor too: the items above bring back the old armor icon,
			// so its value has to match (it was the arena's, or 0 after a frag)
			p.armortype = qx_duel_armt;
			p.armorvalue = qx_duel_armv;
			oself = self;
			self = p;
			W_SetCurrentAmmo ();
			self = oself;
		}
	}

	if (qx_duel_reload)
	if (time > qx_duel_reload)
	if (QX_FindLivePlayer ())		// wait until you're back on your feet
	{
		qx_duel_reload = 0;
		if (qx_revenge_back)
		{
			qx_revenge_back = FALSE;
			localcmd ("qx_back\n");	// back to where you died (load qx_back)
			qx_back_failsafe = time + 3;	// (no qx_back alias after a restart: start instead)
		}
		else
			changelevel ("start");
		return;
	}

	// a revenge match / arena challenge won: the prize is handed out after the
	// trip back (a checkpoint load would undo anything given in the arena)
	if (cvar ("scratch3"))
	if (!qx_arena)
	{
		n = floor (cvar ("scratch3"));
		cvar_set ("scratch3", "0");
		serverflags = serverflags | n;
		serverflags = serverflags - (serverflags & QX_HoldBit (n));
	}
	if (cvar ("scratch4"))
	if (!qx_arena && !qx_arena_go)
	{
		p = QX_FindLivePlayer ();
		if (p)
			QX_ArenaPrize (p, floor (cvar ("scratch4")));
	}

	if (qx_back_failsafe)
	if (time > qx_back_failsafe)
	{
		qx_back_failsafe = 0;
		changelevel ("start");
		return;
	}

	if (qx_arena_go)
	if (time > qx_arena_go)
	{
		qx_arena_go = 0;
		if (qx_arena_map == "")
			localcmd ("qx_arena\n");
		else
			changelevel (qx_arena_map);
		return;
	}

	if (qx_arena_pending)
	{
		QX_ArenaClear ();
		if (time > 1.5)
		if (QX_FindLivePlayer ())
		{
			if (qx_arena_pending == 2)
				qx_duel_test = TRUE;
			if (qx_arena_pending == 3)
				qx_duel_revenge = TRUE;
			if (qx_arena_pending == 4)
				qx_duel_bonus = TRUE;
			qx_arena_pending = 0;
			QX_DuelStart ();
			if (!qx_duel)			// no spot for the hunter: just go back
			{
				if (qx_duel_revenge || qx_duel_bonus)
					qx_revenge_back = TRUE;
				qx_duel_test = FALSE;
				qx_duel_revenge = FALSE;
				qx_duel_bonus = FALSE;
				qx_duel_reload = time + 2;
			}
		}
		return;
	}

	if (qx_duel)
	{
		QX_DuelArmorThink ();
		return;
	}
	if (qx_arena_go)
		return;
	if (qx_duel_checked)
		return;
	if (world.model != "maps/start.bsp")
		return;
	if (time < 4)
		return;
	if (!QX_FindLivePlayer ())
		return;

	qx_duel_checked = TRUE;
	n = QX_RuneCount (serverflags);
	if (n < 2)
		return;
	if (serverflags & QX_DuelDoneBit (n))
		return;					// already settled at this rune count
	QX_ArenaCall (1);			// off to an arena
};
