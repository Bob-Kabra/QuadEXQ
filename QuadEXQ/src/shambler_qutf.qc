/*
==============================================================================

SHAMBLER_QUTF

==============================================================================
*/

$cd id1/models/shams
$origin 0 0 24
$base base
$skin base

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9
$frame stand10 stand11 stand12 stand13 stand14 stand15 stand16 stand17

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7
$frame walk8 walk9 walk10 walk11 walk12

$frame	run1 run2 run3 run4 run5 run6

$frame smash1 smash2 smash3 smash4 smash5 smash6 smash7
$frame smash8 smash9 smash10 smash11 smash12

$frame swingr1 swingr2 swingr3 swingr4 swingr5
$frame swingr6 swingr7 swingr8 swingr9

$frame swingl1 swingl2 swingl3 swingl4 swingl5
$frame swingl6 swingl7 swingl8 swingl9

$frame magic1 magic2 magic3 magic4 magic5
$frame magic6 magic7 magic8 magic9 magic10 magic11 magic12

$frame pain1 pain2 pain3 pain4 pain5 pain6

$frame death1 death2 death3 death4 death5 death6
$frame death7 death8 death9 death10 death11
void() ShamExplode =
{
	T_RadiusDamage (self, self.owner, 200, self.owner);
    sound (self, CHAN_WEAPON, "weapons/nukex.wav", 1, ATTN_NORM);

    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LAVASPLASH);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BfgExplosion ();
};
void() ShamExplode2 =
{
	T_RadiusDamage (self, self.owner, 60, self.owner);
    sound (self, CHAN_WEAPON, "weapons/bfgx.wav", 1, ATTN_NORM);

    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BfgExplosion ();
};
void() ShamFireGrenade2 =
{
	local	entity missile, mpuff,rocket,en;
	local	vector	dir;
	 self.effects = self.effects | EF_MUZZLEFLASH;

    missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;

// set missile speed

	makevectors (self.angles);

	missile.velocity = normalize(self.enemy.origin - self.origin);
	missile.velocity = missile.velocity * 1000;
	missile.velocity_z = 0;

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

// set missile duration
	missile.nextthink = time + 0.005;
	missile.think = ShamExplode2;

	setmodel (missile, "progs/s_light.mdl");	
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};
void() ShamFireGrenade =
{
	local	entity missile, mpuff,rocket,en;
	local	vector	dir;
	 self.effects = self.effects | EF_MUZZLEFLASH;

    missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;

// set missile speed

	makevectors (self.angles);

	missile.velocity = normalize(self.enemy.origin - self.origin);
	missile.velocity = missile.velocity * 0;
	missile.velocity_z = 0;

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);
// set missile duration
	missile.nextthink = time + 0.05;
	missile.think = ShamExplode;

	setmodel (missile, "progs/s_light.mdl");		//ロケットのmodel指定
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);

};

void() sham_QUTF_smash1     =[      $smash1,       sham_QUTF_smash2    ] {
sound (self, CHAN_VOICE, "shambler/melee1.wav", 1, ATTN_NORM);
ai_charge(2);};
void() sham_QUTF_smash2     =[      $smash2,       sham_QUTF_smash3    ] {ai_charge(6);};
void() sham_QUTF_smash3     =[      $smash3,       sham_QUTF_smash4    ] {ai_charge(6);};
void() sham_QUTF_smash4     =[      $smash4,       sham_QUTF_smash5    ] {ai_charge(5);};
void() sham_QUTF_smash5     =[      $smash5,       sham_QUTF_smash6    ] {ai_charge(4);};
void() sham_QUTF_smash6     =[      $smash6,       sham_QUTF_smash7    ] {ai_charge(1);};
void() sham_QUTF_smash7     =[      $smash7,       sham_QUTF_smash8    ] {ai_charge(0);};
void() sham_QUTF_smash8     =[      $smash8,       sham_QUTF_smash9    ] {ai_charge(0);};
void() sham_QUTF_smash9     =[      $smash9,       sham_QUTF_smash10   ] {ai_charge(0);ShamFireGrenade();
};
void() sham_QUTF_smash10    =[      $smash10,      sham_QUTF_smash11   ] {
local vector	delta;
local float 	ldmg;

	if (!self.enemy)
		return;
	ai_charge(0);

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 200)
		return;
	if (!CanDamage (self.enemy, self))
		return;

	ldmg = (random() + random() + random()) * 100;
	T_Damage (self.enemy, self, self, ldmg);
	sound (self, CHAN_VOICE, "shambler/smack.wav", 1, ATTN_NORM);

	SpawnMeatSpray (self.origin + v_forward*16, crandom() * 100 * v_right);
	SpawnMeatSpray (self.origin + v_forward*16, crandom() * 100 * v_right);

 };
void() sham_QUTF_smash11    =[      $smash11,      sham_QUTF_smash12   ] {ai_charge(5);};
void() sham_QUTF_smash12    =[      $smash12,      sham_run1	   ] {ai_charge(4);};

void() sham_QUTF_swingr1;

void() sham_QUTF_swingl1	=[      $swingl1,      sham_QUTF_swingl2   ] {
sound (self, CHAN_VOICE, "shambler/melee2.wav", 1, ATTN_NORM);
ai_charge(5);};
void() sham_QUTF_swingl2 =[      $swingl2,      sham_QUTF_swingl3   ] {ai_charge(3);};
void() sham_QUTF_swingl3 =[      $swingl3,      sham_QUTF_swingl4   ] {ai_charge(7);};
void() sham_QUTF_swingl4 =[      $swingl4,      sham_QUTF_swingl5   ] {ai_charge(3);};
void() sham_QUTF_swingl5 =[      $swingl5,      sham_QUTF_swingl6   ] {ai_charge(7);};
void() sham_QUTF_swingl6 =[      $swingl6,      sham_QUTF_swingl7   ] {ai_charge(9);};
void() sham_QUTF_swingl7 =[      $swingl7,      sham_QUTF_swingl8   ] {ai_charge(5); ShamClaw(250);ShamFireGrenade2();};
void() sham_QUTF_swingl8 =[      $swingl8,      sham_QUTF_swingl9   ] {ai_charge(4);};
void() sham_QUTF_swingl9 =[      $swingl9,      sham_run1  ] {
ai_charge(8);
if (random()<0.5)
	self.think = sham_QUTF_swingr1;
};

void() sham_QUTF_swingr1	=[      $swingr1,      sham_QUTF_swingr2   ] {
sound (self, CHAN_VOICE, "shambler/melee1.wav", 1, ATTN_NORM);
ai_charge(1);};
void() sham_QUTF_swingr2	=[      $swingr2,      sham_QUTF_swingr3   ] {ai_charge(8);};
void() sham_QUTF_swingr3 =[      $swingr3,      sham_QUTF_swingr4   ] {ai_charge(14);};
void() sham_QUTF_swingr4 =[      $swingr4,      sham_QUTF_swingr5   ] {ai_charge(7);};
void() sham_QUTF_swingr5 =[      $swingr5,      sham_QUTF_swingr6   ] {ai_charge(3);};
void() sham_QUTF_swingr6 =[      $swingr6,      sham_QUTF_swingr7   ] {ai_charge(6);};
void() sham_QUTF_swingr7 =[      $swingr7,      sham_QUTF_swingr8   ] {ai_charge(6); ShamClaw(-250);ShamFireGrenade2();};
void() sham_QUTF_swingr8 =[      $swingr8,      sham_QUTF_swingr9   ] {ai_charge(3);};
void() sham_QUTF_swingr9 =[      $swingr9,      sham_run1  ] {ai_charge(1);
ai_charge(10);
if (random()<0.5)
	self.think = sham_QUTF_swingl1;
};

void() sham_QUTF_melee =
{
	local float chance;

	chance = random();
	if (chance > 0.6 || self.health == 600)
		sham_QUTF_smash1 ();
	else if (chance > 0.3)
		sham_QUTF_swingr1 ();
	else
		sham_QUTF_swingl1 ();
};


//============================================================================

void() CastLightning_HP =
{
	local	vector	org, dir;
    local	entity	en;
	self.effects = self.effects | EF_MUZZLEFLASH;

	ai_face ();

	org = self.origin + '0 0 40';
    	en = self.enemy;

	dir = en.origin - en.velocity*0.17*random();

	dir = normalize (dir - org);

	traceline (org, self.origin + dir*6000, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING3);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (org, trace_endpos, self, 80);
};

void() sham_QUTF_magic1     =[      $magic1,       sham_QUTF_magic2    ] {ai_face();
	sound (self, CHAN_WEAPON, "shambler/sattck1.wav", 1, ATTN_NORM);
};
void() sham_QUTF_magic2     =[      $magic2,       sham_QUTF_magic3    ] {ai_face();};
void() sham_QUTF_magic3     =[      $magic3,       sham_QUTF_magic4    ] {ai_face();self.nextthink = self.nextthink + 0.2;
local entity o;

self.effects = self.effects | EF_MUZZLEFLASH;
ai_face();
self.owner = spawn();
o = self.owner;
setmodel (o, "progs/s_light.mdl");
setorigin (o, self.origin);
o.angles = self.angles;
o.nextthink = time + 0.7;
o.think = SUB_Remove;
};
void() sham_QUTF_magic4     =[      $magic4,       sham_QUTF_magic5    ]
{
self.effects = self.effects | EF_MUZZLEFLASH;
self.owner.frame = 1;
};
void() sham_QUTF_magic5     =[      $magic5,       sham_QUTF_magic6    ]
{
self.effects = self.effects | EF_MUZZLEFLASH;
self.owner.frame = 2;
};
void() sham_QUTF_magic6     =[      $magic6,       sham_QUTF_magic9    ]
{
remove (self.owner);


};
void() sham_QUTF_magic9     =[      $magic9,       sham_QUTF_magic10   ]{};
void() sham_QUTF_magic10    =[      $magic10,      sham_QUTF_magic11   ]
{
sound (self, CHAN_WEAPON, "shambler/sboom.wav", 1, ATTN_NORM);
if(random()<0.7)
CastLightning_HP();
else
Dshot(1, 40);

};
void() sham_QUTF_magic11    =[      $magic11,      sham_QUTF_magic12   ]{};
void() sham_QUTF_magic12    =[      $magic12,      sham_run1	   ] {};

void(float offset) hknight_shot;
void() shamboss_magic1     =[      $magic1,       shamboss_magic2    ] {ai_face();
	sound (self, CHAN_WEAPON, "shambler/sattck1.wav", 1, ATTN_NORM);
};
void() shamboss_magic2     =[      $magic2,       shamboss_magic3    ] {ai_face();};
void() shamboss_magic3     =[      $magic3,       shamboss_magic4    ] {ai_face();self.nextthink = self.nextthink + 0.2;
local entity o;

self.effects = self.effects | EF_MUZZLEFLASH;
ai_face();
self.owner = spawn();
o = self.owner;
setmodel (o, "progs/s_light.mdl");
setorigin (o, self.origin);
o.angles = self.angles;
o.nextthink = time + 0.7;
o.think = SUB_Remove;
};
void() shamboss_magic4     =[      $magic4,       shamboss_magic5    ]
{
self.effects = self.effects | EF_MUZZLEFLASH;
self.owner.frame = 1;
};
void() shamboss_magic5     =[      $magic5,       shamboss_magic6    ]
{
self.effects = self.effects | EF_MUZZLEFLASH;
self.owner.frame = 2;
};
void() shamboss_magic6     =[      $magic6,       shamboss_magic9    ]
{
remove (self.owner);


};
void() shamboss_magic9     =[      $magic9,       shamboss_magic10   ]{};
void() shamboss_magic10    =[      $magic10,      shamboss_magic11   ]
{
sound (self, CHAN_WEAPON, "shambler/sboom.wav", 1, ATTN_NORM);
hknight_shot(-0.3);
hknight_shot(-0.2);hknight_shot(-0.1);hknight_shot(0);hknight_shot(0.1);hknight_shot(0.2);
hknight_shot(0.3);
};
void() shamboss_magic11    =[      $magic11,      shamboss_magic12   ]{};
void() shamboss_magic12    =[      $magic12,      sham_run1	   ] {};

//============================================================================

void() sham_QUTF_death1      =[      $death1,       sham_QUTF_death2     ] {};
void() sham_QUTF_death2      =[      $death2,       sham_QUTF_death3     ] {};
void() sham_QUTF_death3      =[      $death3,       sham_QUTF_death4     ] {self.solid = SOLID_NOT;};
void() sham_QUTF_death4      =[      $death4,       sham_QUTF_death5     ] {};
void() sham_QUTF_death5      =[      $death5,       sham_QUTF_death6     ] {ShamFireGrenade2();ThrowGib ("progs/gib1.mdl",-1000);
		ThrowGib ("progs/gib2.mdl", -1000);
};
void() sham_QUTF_death6      =[      $death6,       sham_QUTF_death7     ] {ShamFireGrenade2();ThrowGib ("progs/gib1.mdl",-1000);
		ThrowGib ("progs/gib2.mdl", -1000);
};
void() sham_QUTF_death7      =[      $death7,       sham_QUTF_death8     ] {ShamFireGrenade2();};
void() sham_QUTF_death8      =[      $death8,       sham_QUTF_death9     ] {ShamFireGrenade2();};
void() sham_QUTF_death9      =[      $death9,       sham_QUTF_death10    ] {ShamFireGrenade2();};
void() sham_QUTF_death10     =[      $death10,      sham_QUTF_death11    ] {sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		self.skin=0;
		ThrowHead ("progs/h_shams.mdl", -1000);
		ThrowGib ("progs/gib1.mdl",-1000);
		ThrowGib ("progs/gib2.mdl", -1000);
		ThrowGib ("progs/gib3.mdl",-1000);
		ThrowGib ("progs/gib1.mdl",-1000);
		ThrowGib ("progs/gib2.mdl", -1000);
		ThrowGib ("progs/gib3.mdl",-1000);
        	ThrowGib ("progs/gib1.mdl",-1000);
		ThrowGib ("progs/gib2.mdl", -1000);
		ThrowGib ("progs/gib3.mdl",-1000);
        	ThrowGib ("progs/gib2.mdl", -1000);
		ThrowGib ("progs/gib3.mdl",-1000);
        	ThrowGib ("progs/gib1.mdl",-1000);
		ThrowGib ("progs/gib2.mdl", -1000);
		ThrowGib ("progs/gib3.mdl",-1000);


     return;};
void() sham_QUTF_death11     =[      $death11,      sham_QUTF_death11    ] {};

void() sham_QUTF_die =
{
// check for gib


// regular death
	sound (self, CHAN_VOICE, "shambler/sdeath.wav", 1, ATTN_NORM);
	sham_QUTF_death1 ();
};

//============================================================================


/*QUAKED monster_shambler (1 0 0) (-32 -32 -24) (32 32 64) Ambush
*/
void() monster_shambler_QUTF =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/shambler.mdl");
	precache_model ("progs/s_light.mdl");
	precache_model ("progs/h_shams.mdl");
	precache_model ("progs/bolt.mdl");
	precache_model ("progs/s_bfg.spr");
	precache_model ("progs/s_light.spr");
	
	precache_sound ("shambler/sattck1.wav");
	precache_sound ("shambler/sboom.wav");
	precache_sound ("shambler/sdeath.wav");
	precache_sound ("shambler/shurt2.wav");
	precache_sound ("shambler/sidle.wav");
	precache_sound ("shambler/ssight.wav");
	precache_sound ("shambler/melee1.wav");
	precache_sound ("shambler/melee2.wav");
	precache_sound ("shambler/smack.wav");
	precache_sound ("weapons/nukex.wav");
	precache_sound ("weapons/bfgx.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	setmodel (self, "progs/shambler.mdl");

	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	if(random()<0.5) {
		self.health = 1666;
		self.th_die = sham_QUTF_die;
		self.th_melee = sham_QUTF_melee;
		self.th_missile = sham_QUTF_magic1;
		self.skin=2;
	}
	else
	{
		self.skin=1;
		self.health = 966;
		self.th_die = sham_die;
		self.th_melee = sham_melee;
		self.th_missile = shamboss_magic1;
	}
	self.th_stand = sham_stand1;
	self.th_walk = sham_walk1;
	self.th_run = sham_run1;
	self.th_pain = sham_pain;

	walkmonster_start();
};
