/*
==============================================================================

WIZARD

==============================================================================
*/

$cd id1/models/a_wizard
$origin 0 0 24
$base wizbase	
$skin wizbase

$frame hover1 hover2 hover3 hover4 hover5 hover6 hover7 hover8
$frame hover9 hover10 hover11 hover12 hover13 hover14 hover15

$frame fly1 fly2 fly3 fly4 fly5 fly6 fly7 fly8 fly9 fly10
$frame fly11 fly12 fly13 fly14

$frame magatt1 magatt2 magatt3 magatt4 magatt5 magatt6 magatt7
$frame magatt8 magatt9 magatt10 magatt11 magatt12 magatt13

$frame pain1 pain2 pain3 pain4

$frame death1 death2 death3 death4 death5 death6 death7 death8

/*
==============================================================================

Super WIZARD

If the player moves behind cover before the missile is launched, launch it
at the last visible spot with no velocity leading, in hopes that the player
will duck back out and catch it.
==============================================================================
*/

/*
=============
LaunchMissile

Sets the given entities velocity and angles so that it will hit self.enemy
if self.enemy maintains it's current velocity
0.1 is moderately accurate, 0.0 is totally accurate
=============
*/
/*
void(entity missile, float mspeed, float accuracy) LaunchMissile =
{
	local	vector	vec, move;
	local	float	fly;

	makevectors (self.angles);
		
// set missile speed
	vec = self.enemy.origin + self.enemy.mins + self.enemy.size * 0.7 - missile.origin;

// calc aproximate time for missile to reach vec
	fly = vlen (vec) / mspeed;
	
// get the entities xy velocity
	move = self.enemy.velocity;
	move_z = 0;

// project the target forward in time
	vec = vec + move * fly;
	
	vec = normalize(vec);
	vec = vec + accuracy*v_up*(random()- 0.5) + accuracy*v_right*(random()- 0.5);
	
	missile.velocity = vec * mspeed;

	missile.angles = '0 0 0';
	missile.angles_y = vectoyaw(missile.velocity);

// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;	
};
*/

void() wiz_run1;
void() wiz_side1;

/*
=================
WizardCheckAttack
=================
*/
/* deleted because redecrerad
float()	WizardCheckAttack =
{
	local vector	spot1, spot2;	
	local entity	targ;
	local float		chance;

	if (time < self.attack_finished)
		return FALSE;
	if (!enemy_vis)
		return FALSE;

	if (enemy_range == RANGE_FAR)
	{
		if (self.attack_state != AS_STRAIGHT)
		{
			self.attack_state = AS_STRAIGHT;
			swiz_run1 ();
		}
		return FALSE;
	}
		
	targ = self.enemy;
	
// see if any entities are in the way of the shot
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline (spot1, spot2, FALSE, self);

	if (trace_ent != targ)
	{	// don't have a clear shot, so move to a side
		if (self.attack_state != AS_STRAIGHT)
		{
			self.attack_state = AS_STRAIGHT;
			swiz_run1 ();
		}
		return FALSE;
	}
			
	if (enemy_range == RANGE_MELEE)
		chance = 0.9;
	else if (enemy_range == RANGE_NEAR)
		chance = 0.6;
	else if (enemy_range == RANGE_MID)
		chance = 0.2;
	else
		chance = 0;

	if (random () < chance)
	{
		self.attack_state = AS_MISSILE;
		return TRUE;
	}

	if (enemy_range == RANGE_MID)
	{
		if (self.attack_state != AS_STRAIGHT)
		{
			self.attack_state = AS_STRAIGHT;
			swiz_run1 ();
		}
	}
	else
	{
		if (self.attack_state != AS_SLIDING)
		{
			self.attack_state = AS_SLIDING;
			swiz_side1 ();
		}
	}
	
	return FALSE;
};
*/
/*
=================
WizardAttackFinished
=================
*/
/*
float()	WizardAttackFinished =
{
	if (enemy_range >= RANGE_MID || !enemy_vis)
	{
		self.attack_state = AS_STRAIGHT;
		self.think = swiz_run1;
	}
	else
	{
		self.attack_state = AS_SLIDING;
		self.think = swiz_side1;
	}
};
*/
/*
==============================================================================

FAST ATTACKS

==============================================================================
*/
void() HomeThink3 =
{
        local vector dir, olddir, vtemp;
	
	olddir = normalize(self.velocity);
	dir_x = olddir_x + 0.1 - random()*0.2;
	dir_y = olddir_y +0.1 - random()*0.2;
	dir_z = olddir_z +0.1 - random()*0.2;
	self.velocity = dir * 500*(0.8+random()*0.2);
	self.angles = vectoangles(self.velocity);
   	self.nextthink = time + 0.1;
	self.think=HomeThink3;
};

void() MineDie =
{
	self.takedamage = DAMAGE_NO;	// QuadEXQ: mines can be shot down
	self.touch = SUB_Null;
	T_RadiusDamage (self, self, 50, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	BecomeExplosion();
};
void() MineHome =
{
	local vector	dir, vtemp;
	vtemp = self.enemy.origin + '0 0 10';

    if (self.enemy.health < 1)
	{
		remove(self);
		return;
	}
	
	dir = normalize(vtemp - self.origin);
	sound (self, CHAN_WEAPON, "shalrath/smine.wav", 1, ATTN_NORM);
    if (skill == 3)
		self.velocity = dir * 800 * (0.7 + 0.3*random());
	else
		self.velocity = dir * 400 * (0.7 + 0.3*random());
	self.nextthink = time + 1.0;
	self.think = MineHome;
	if (vlen(vtemp - self.origin) < 150)
		MineDie();

};

void() SMineTouch =
{
	local entity grenade;
	local float tmp;
	if (other == self.owner)
		return;		// don't explode on owner
	self.takedamage = DAMAGE_NO;
	T_RadiusDamage (self, self, 25, world);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	BecomeExplosion();
};

void() SMineShot =
{
	local	entity 	missile;
	local	vector	dir;
	local	float	dist, flytime;

	dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	dist = vlen (self.enemy.origin - self.origin);
	flytime = dist * 0.003;
	if (flytime < 0.1)
		flytime = 0.1;

	self.effects = self.effects | EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "wizard/wattack.wav", 1, ATTN_NORM);

	missile = spawn ();
	missile.owner = self;

	missile.solid = SOLID_SLIDEBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	
	setmodel (missile, "progs/smine.mdl");

	setsize (missile, '0 0 0', '0 0 0');

	missile.origin = self.origin + '0 0 10';
	if(dist > 2000) dist=2000;
	missile.velocity = dir * dist;
	missile.avelocity = '300 300 300';
	missile.nextthink = time + 0.1;

	missile.think = MineHome;
    	missile.enemy = self.enemy;
	missile.touch = SMineTouch;

	// QuadEXQ: shoot it and it blows up early (any hit kills it)
	setsize (missile, '-6 -6 -6', '6 6 6');
	missile.classname = "spikemine";
	missile.takedamage = DAMAGE_AIM;
	missile.health = 1;
	missile.th_die = MineDie;
};

void() swiz_FastFire =
{
	local vector		vec;
	local vector		dst;

	if (self.owner.health > 0)
	{
		self.owner.effects = self.owner.effects | EF_MUZZLEFLASH;

		makevectors (self.enemy.angles);	
		dst = self.enemy.origin - 13*self.movedir;
	
		vec = normalize(dst - self.origin);
		sound (self, CHAN_WEAPON, "wizard/wattack.wav", 1, ATTN_NORM);
		launch_spike (self.origin, vec);
		newmis.velocity = vec*300*(1+random());
		newmis.owner = self.owner;
		newmis.classname = "wizspike";
		setmodel (newmis, "progs/w_spike.mdl");
		setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
		newmis.nextthink=time+0.5;
		newmis.think=HomeThink3;
	}

	remove (self);
};


void() swiz_StartFast =
{
	local	entity	missile;
	
	sound (self, CHAN_WEAPON, "wizard/wattack.wav", 1, ATTN_NORM);
	self.v_angle = self.angles;
	makevectors (self.angles);

	missile = spawn ();
	missile.owner = self;
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + '0 0 30' + v_forward*14 + v_right*14);
	missile.enemy = self.enemy;
	missile.nextthink = time + 0.1;
	missile.think = swiz_FastFire;
	missile.movedir = v_right;

	missile = spawn ();
	missile.owner = self;
	missile.nextthink = time + 1;
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + '0 0 30' + v_forward*14 + v_right* -14);
	missile.enemy = self.enemy;
	missile.nextthink = time + 0.3;
	missile.think = swiz_FastFire;
	missile.movedir = VEC_ORIGIN - v_right;
};



void() swiz_idlesound =
{
local float wr;
	wr = random() * 5;

	if (self.waitmin < time)
	{
	 	self.waitmin = time + 2;
	 	if (wr > 4.5) 
	 		sound (self, CHAN_VOICE, "wizard/widle1.wav", 1,  ATTN_IDLE);
	 	if (wr < 1.5)
	 		sound (self, CHAN_VOICE, "wizard/widle2.wav", 1, ATTN_IDLE);
	}
	return;
};

void()	swiz_stand1	=[	$hover1,		swiz_stand2	] {ai_stand();};
void()	swiz_stand2	=[	$hover2,		swiz_stand3	] {ai_stand();};
void()	swiz_stand3	=[	$hover3,		swiz_stand4	] {ai_stand();};
void()	swiz_stand4	=[	$hover4,		swiz_stand5	] {ai_stand();};
void()	swiz_stand5	=[	$hover5,		swiz_stand6	] {ai_stand();};
void()	swiz_stand6	=[	$hover6,		swiz_stand7	] {ai_stand();};
void()	swiz_stand7	=[	$hover7,		swiz_stand8	] {ai_stand();};
void()	swiz_stand8	=[	$hover8,		swiz_stand1	] {ai_stand();};

void()	swiz_walk1	=[	$hover1,		swiz_walk2	] {ai_walk(8);
swiz_idlesound();};
void()	swiz_walk2	=[	$hover2,		swiz_walk3	] {ai_walk(8);};
void()	swiz_walk3	=[	$hover3,		swiz_walk4	] {ai_walk(8);};
void()	swiz_walk4	=[	$hover4,		swiz_walk5	] {ai_walk(8);};
void()	swiz_walk5	=[	$hover5,		swiz_walk6	] {ai_walk(8);};
void()	swiz_walk6	=[	$hover6,		swiz_walk7	] {ai_walk(8);};
void()	swiz_walk7	=[	$hover7,		swiz_walk8	] {ai_walk(8);};
void()	swiz_walk8	=[	$hover8,		swiz_walk1	] {ai_walk(8);};

void()	swiz_side1	=[	$hover1,		swiz_side2	] {ai_run(8);
swiz_idlesound();};
void()	swiz_side2	=[	$hover2,		swiz_side3	] {ai_run(8);};
void()	swiz_side3	=[	$hover3,		swiz_side4	] {ai_run(8);};
void()	swiz_side4	=[	$hover4,		swiz_side5	] {ai_run(8);};
void()	swiz_side5	=[	$hover5,		swiz_side6	] {ai_run(8);};
void()	swiz_side6	=[	$hover6,		swiz_side7	] {ai_run(8);};
void()	swiz_side7	=[	$hover7,		swiz_side8	] {ai_run(8);};
void()	swiz_side8	=[	$hover8,		swiz_side1	] {ai_run(8);};

void()	swiz_run1	=[	$fly1,		swiz_run2	] {ai_run(30);
swiz_idlesound();
};
void()	swiz_run2	=[	$fly2,		swiz_run3	] {ai_run(32);};
void()	swiz_run3	=[	$fly3,		swiz_run4	] {ai_run(32);};
void()	swiz_run4	=[	$fly4,		swiz_run5	] {ai_run(32);};
void()	swiz_run5	=[	$fly5,		swiz_run6	] {ai_run(32);};
void()	swiz_run6	=[	$fly6,		swiz_run7	] {ai_run(32);};
void()	swiz_run7	=[	$fly7,		swiz_run8	] {ai_run(32);};
void()	swiz_run8	=[	$fly8,		swiz_run9	] {ai_run(32);};
void()	swiz_run9	=[	$fly9,		swiz_run10	] {ai_run(32);};
void()	swiz_run10	=[	$fly10,		swiz_run11	] {ai_run(32);};
void()	swiz_run11	=[	$fly11,		swiz_run12	] {ai_run(32);};
void()	swiz_run12	=[	$fly12,		swiz_run13	] {ai_run(32);};
void()	swiz_run13	=[	$fly13,		swiz_run14	] {ai_run(32);};
void()	swiz_run14	=[	$fly14,		swiz_run1	] {ai_run(32);};

void()	swiz_fast1	=[	$magatt1,		swiz_fast2	] {ai_face();};
void()	swiz_fast2	=[	$magatt2,		swiz_fast3	] {ai_face();};
void()	swiz_fast3	=[	$magatt3,		swiz_fast4	] {ai_face();swiz_StartFast();};
void()	swiz_fast4	=[	$magatt4,		swiz_fast5	] {ai_face();swiz_StartFast();};
void()	swiz_fast5	=[	$magatt5,		swiz_fast6	] {ai_face();};
void()	swiz_fast6	=[	$magatt6,		swiz_fast7	] {ai_face();};
void()	swiz_fast7	=[	$magatt5,		swiz_fast8	] {ai_face();};
void()	swiz_fast8	=[	$magatt4,		swiz_fast9	] {ai_face();swiz_StartFast();};
void()	swiz_fast9	=[	$magatt3,		swiz_fast10	] {ai_face();swiz_StartFast();};
void()	swiz_fast10	=[	$magatt2,		swiz_run1	] {ai_face();SUB_AttackFinished(2);WizardAttackFinished ();};

void()	swiz_mine1	=[	$magatt1,		swiz_mine2	] {ai_face();};
void()	swiz_mine2	=[	$magatt2,		swiz_mine3	] {ai_face();};
void()	swiz_mine3	=[	$magatt3,		swiz_mine4	] {ai_face();SMineShot();};
void()	swiz_mine4	=[	$magatt4,		swiz_mine5	] {ai_face();SMineShot();};
void()	swiz_mine5	=[	$magatt5,		swiz_mine6	] {ai_face();};
void()	swiz_mine6	=[	$magatt6,		swiz_mine7	] {ai_face();};
void()	swiz_mine7	=[	$magatt5,		swiz_mine8	] {ai_face();};
void()	swiz_mine8	=[	$magatt4,		swiz_mine9	] {ai_face();SMineShot();};
void()	swiz_mine9	=[	$magatt3,		swiz_mine10	] {ai_face();SMineShot();};
void()	swiz_mine10	=[	$magatt2,		swiz_run1	] {ai_face();SUB_AttackFinished(2);WizardAttackFinished ();};


void()	swiz_pain1	=[	$pain1,		swiz_pain2	] {};
void()	swiz_pain2	=[	$pain2,		swiz_pain3	] {ai_run(-64);};
void()	swiz_pain3	=[	$pain3,		swiz_pain4	] {};
void()	swiz_pain4	=[	$pain4,		swiz_run1	] {};

void()	swiz_death1	=[	$death1,		swiz_death2	] {

self.velocity_x = -400 + 800*random();
self.velocity_y = -400 + 800*random();
self.velocity_z = 100 + 500*random();
self.flags = self.flags - (self.flags & FL_ONGROUND);
sound (self, CHAN_VOICE, "wizard/wdeath.wav", 1, ATTN_NORM);
};
void()	swiz_death2	=[	$death2,		swiz_death3	] {};
void()	swiz_death3	=[	$death3,		swiz_death4	]{self.solid = SOLID_NOT;};
void()	swiz_death4	=[	$death4,		swiz_death5	] {};
void()	swiz_death5	=[	$death5,		swiz_death6	] {};
void()	swiz_death6	=[	$death6,		swiz_death7	] {};
void()	swiz_death7	=[	$death7,		swiz_death8	] {};
void()	swiz_death8	=[	$death8,		swiz_death8	] {};


void() swiz_die =
{
// check for gib
	if (self.health < -400)
	{
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		ThrowHead ("progs/h_wizard.mdl", self.health);
		ThrowGib ("progs/gib2.mdl", self.health);
		ThrowGib ("progs/gib2.mdl", self.health);
		ThrowGib ("progs/gib2.mdl", self.health);
		return;
	}

	swiz_death1 ();
};


void(entity attacker, float damage) swiz_Pain =
{
	sound (self, CHAN_VOICE, "wizard/wpain.wav", 1, ATTN_NORM);
	if (random()*10 > damage)
		return;		// didn't flinch

	swiz_pain1 ();
};


void() swiz_Missile =
{
	if(random() > 0.8) swiz_fast1();
	else swiz_mine1();
};

/*QUAKED monster_wizard (1 0 0) (-16 -16 -24) (16 16 40) Ambush
*/
void() monster_superwizard =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/wizard.mdl");
	precache_model ("progs/h_wizard.mdl");
	precache_model ("progs/w_spike.mdl");
	precache_model ("progs/smine.mdl");
	precache_sound ("wizard/hit.wav");		// used by c code
	precache_sound ("wizard/wattack.wav");
	precache_sound ("wizard/wdeath.wav");
	precache_sound ("wizard/widle1.wav");
	precache_sound ("wizard/widle2.wav");
	precache_sound ("wizard/wpain.wav");
	precache_sound ("wizard/wsight.wav");
	precache_sound ("shalrath/smine.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/wizard.mdl");

	setsize (self, '-16 -16 -24', '16 16 40');
	self.health =160;

	self.th_stand = swiz_stand1;
	self.th_walk = swiz_walk1;
	self.th_run = swiz_run1;
	if(random() > 0.2) 
		self.th_missile = swiz_fast1;
	else 
		self.th_missile = swiz_mine1;
	self.th_pain = swiz_Pain;
	self.th_die = swiz_die;
	self.skin=1;
	self.classname ="monster_wizard";
	flymonster_start ();
};
