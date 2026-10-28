/*
==============================================================================

WIZARD

==============================================================================
*/

$cd id1/models/a_wizard
$origin 0 0 24
$base wizbase	
$skin wizbase

$frame spike1.asc spike2.asc spike3.asc spike4.asc spike5.asc
$frame spike6.asc spike7.asc spike8.asc spike9.asc 

void()	smine_stand1  =[	$spike1.asc,		smine_stand2	] {};
void()	smine_stand2  =[	$spike2.asc,		smine_stand3	] {};
void()	smine_stand3  =[	$spike3.asc,		smine_stand4	] {};
void()	smine_stand4  =[	$spike4.asc,		smine_stand5	] {};
void()	smine_stand5  =[	$spike5.asc,		smine_stand6	] {};
void()	smine_stand6  =[	$spike6.asc,		smine_stand7	] {};
void()	smine_stand7  =[	$spike7.asc,		smine_stand8	] {};
void()	smine_stand8  =[	$spike8.asc,		smine_stand9	] {};
void()	smine_stand9  =[	$spike9.asc,		smine_stand1	] {};

void()	wizs_run1	=[	$spike1.asc,		wizs_run2	] {ai_run(16);
sound (self, CHAN_VOICE, "smine/srun.wav", 1, ATTN_IDLE);
};
void()	wizs_run2	=[	$spike2.asc,		wizs_run3	] {ai_run(16);};
void()	wizs_run3	=[	$spike3.asc,		wizs_run4	] {ai_run(16);};
void()	wizs_run4	=[	$spike4.asc,		wizs_run5	] {ai_run(16);};
void()	wizs_run5	=[	$spike5.asc,		wizs_run6	] {ai_run(16);};
void()	wizs_run6	=[	$spike6.asc,		wizs_run7	] {ai_run(16);};
void()	wizs_run7	=[	$spike7.asc,		wizs_run8	] {ai_run(16);};
void()	wizs_run8	=[	$spike8.asc,		wizs_run9	] {ai_run(16);};
void()	wizs_run9	=[	$spike9.asc,		wizs_run1	] {ai_run(16);};


void()	smine_die1 	=[	$spike1.asc,		smine_die2	] 
{
self.takedamage = DAMAGE_NO;
};
void()	smine_die2	=[	$spike2.asc,		smine_die1	] 
{
	T_RadiusDamage (self, self, 250, world);

	sound (self, CHAN_VOICE, "smine/death.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	
	BecomeExplosion ();
};


void() smine_MeleeAttack =
{
	smine_die1 ();
};

/*QUAKED monster_smine (1 0 0) (-16 -16 -24) (16 16 40) Ambush
*/
void() monster_smine =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/smine.mdl");
	
	precache_sound ("smine/death.wav");		
	precache_sound ("smine/srun.wav");
	
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
    self.avelocity = '300 300 300';
	setmodel (self, "progs/smine.mdl");

	setsize (self, '-16 -16 -24', '16 16 40');
	self.health = 60;		// QuadEXQ: shootable (was 1300)

	self.th_stand = smine_stand1;
	self.th_walk = wizs_run1;
	self.th_run = wizs_run1;
	self.th_missile = wizs_run1;
	self.th_melee = smine_MeleeAttack;	
	self.th_die = smine_die1 ;
		
	flymonster_start ();
};


float()	ChecksmineMelee =
{
	if (enemy_range == RANGE_MELEE)
	{	// FIXME: check canreach
		self.attack_state = AS_MELEE;
		return TRUE;
	}
	return FALSE;
};

float()	smineCheckAttack =
{
	local	vector	vec;
	
// if close enough for slashing, go for it
	if (ChecksmineMelee ())
	{
		self.attack_state = AS_MELEE;
		return TRUE;
	}
		
	return FALSE;
};


//===========================================================================

void(float side)	smine_Melee =
{
	local	float	ldmg;
	local vector	delta;
	
	ai_face ();
	walkmove (self.ideal_yaw, 12);	// allow a little closing

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 100)
		return;
	if (!CanDamage (self.enemy, self))
		return;
		
    sound (self, CHAN_WEAPON, "demon/dhit2.wav", 1, ATTN_NORM);
	ldmg = 150 + 5*random();
	T_Damage (self.enemy, self, self, ldmg);	

	makevectors (self.angles);
	SpawnMeatSpray (self.origin + v_forward*16, side * v_right);
};

