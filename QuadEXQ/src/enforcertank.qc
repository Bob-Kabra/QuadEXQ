/*
==============================================================================

ENFORCERTANK

==============================================================================
*/

$cd id1/models/enforcer
$origin 0 -6 24
$base base		
$skin skin

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10
$frame walk11 walk12 walk13 walk14 walk15 walk16

$frame run1 run2 run3 run4 run5 run6 run7 run8

$frame attack1 attack2 attack3 attack4 attack5 attack6
$frame attack7 attack8 attack9 attack10
$frame attack11 attack12 attack13 attack14 attack15 attack16
$frame attack17 attack18 attack19 attack20

$frame death1 death2 death3 death4 death5 death6 death7 death8
$frame death9 death10 death11 death12 death13 death14

$frame fdeath1 fdeath2 fdeath3 fdeath4 fdeath5 fdeath6 fdeath7 fdeath8
$frame fdeath9 fdeath10 fdeath11

$frame paina1 paina2 paina3 paina4

$frame painb1 painb2 painb3 painb4 painb5

$frame painc1 painc2 painc3 painc4 painc5 painc6 painc7 painc8

$frame paind1 paind2 paind3 paind4 paind5 paind6 paind7 paind8
$frame paind9 paind10 paind11 paind12 paind13 paind14 paind15 paind16
$frame paind17 paind18 paind19

$frame attackp1 attackp2 attackp3 attackp4 attackp5 attackp6 attackp7

$frame fieldon1 fieldon2 fieldon3 fieldon4 fieldon5 fieldon6 fieldon7
void() enft_atka1; 
void() enft_atkb1; 
void() enft_atkc1; 
void() enft_atkd1; 
void() enf_atkrc1; 

void() enft_atkn =
{
	if( vlen( self.origin - self.enemy.origin ) < 350 )		
		enft_atka1();
	else
	enft_atkc1();
};

void() enft_atkcom =
{
	if( vlen( self.origin - self.enemy.origin ) < 500 )		
		if( vlen( self.origin - self.enemy.origin ) < 250 )
			enf_atkrc1();
		else if(random()<0.8){enft_atkd1();}
		else{enft_atkb1();}
	else
	enft_atkb1();
};

void() PlasmaExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_plasma.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
void() BfgExplosion;
void() Plasma_Fly;
void() Dshotex;
void() enf_plasma_Touch =
{
	local vector org;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
	org = self.origin - 8*normalize(self.velocity);
	T_Damage (other, self, self.owner, 30 );
	
	if(self.owner.classname == "monster_enft_commander") Dshotex();
	else PlasmaExplosion();
};
void(vector org, vector vec, float spd) Launchplasma =
{
	local	vector	vec;
	

	vec = normalize(vec);

	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;

	setmodel (newmis, "progs/plusma.spr");
	setsize (newmis, '0 0 0', '0 0 0');

	setorigin (newmis, org);

	newmis.velocity = vec * spd *(1+0.3*random());
	newmis.angles = vectoangles(newmis.velocity);
	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	

	newmis.touch = plasma_Touch;
	
};

void(vector org, vector vec, float spd) Launchenfplasma =
{
	local	vector	vec;
	
	sound (self, CHAN_WEAPON, "enforcer/enfire2.wav", 1, ATTN_NORM);

	vec = normalize(vec);

	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;

	setmodel (newmis, "progs/plusma.spr");
	setsize (newmis, '0 0 0', '0 0 0');

	setorigin (newmis, org);

	newmis.velocity = vec * spd *(1+0.3*random());
	newmis.angles = vectoangles(newmis.velocity);
	
	/*
	if(self.classname == "monster_enft_commander") 
	{
		newmis.nextthink = time + 0.1; 
		newmis.think = Plasma_Fly;
	}
	*/
	//else
	//{
	newmis.nextthink = time + 5; 
	newmis.think = SUB_Remove;
	//}
	newmis.touch = enf_plasma_Touch;
};

void(vector org, vector vec) LaunchLaser2 =
{
	local	vector	vec;
		
	//if (self.classname == "monster_enforcer")
		sound (self, CHAN_WEAPON, "enforcer/enfire3.wav", 1, ATTN_NORM);

	vec = normalize(vec);
	
	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLY;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;

	setmodel (newmis, "progs/laser2.mdl");
	setsize (newmis, '0 0 0', '0 0 0');		

	setorigin (newmis, org);

	newmis.velocity = vec * 1000;
	newmis.angles = vectoangles(newmis.velocity);

	newmis.nextthink = time + 5;
	newmis.think = SUB_Remove;
	newmis.touch = Laser_Touch;
};

void() enft_laser =
{
	local vector org;

	self.effects = self.effects | EF_MUZZLEFLASH;
	makevectors (self.angles);
	
	org = self.origin + '0 0 28'+(v_right * 6);
	LaunchLaser2(org, self.enemy.origin - self.origin);
};

void() enft_fire =
{
	local vector spd;
  	local vector org,dir;
   	local	entity	rocket,en;
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	en = self.enemy;
	spd = en.origin;
	makevectors (self.angles);
    	org = self.origin + v_forward * 30 + v_right * 8.5 + '0 0 16';
		
	Launchenfplasma(org, spd - org, 300);
	newmis.classname="enfplasma";
};
void() enft_fireb =
{
  local vector spd;
   local vector org,dir;
   local	entity	en;
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	org = self.origin + '0 0 28'+(v_right * 6);
	en = self.enemy;
	sound (self, CHAN_WEAPON, "enforcer/rail1.wav", 1, ATTN_NORM);
	dir = en.origin - en.velocity * 0.15 * random();
	dir = normalize (dir - org);

	traceline (org, self.origin + dir*5000, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING1);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (org, trace_endpos, self, 10+random()*15);
};


void() enf_rshot =
{
	local	vector	dir;
	local	entity	en;
	
	ai_face();

	en = self.enemy;
	dir = en.origin - en.velocity*0.2;
	dir = normalize (dir - self.origin);
	//sound (self, CHAN_WEAPON, "weapons/rshotgun.wav", 1, ATTN_NORM);
	FireBullets (15, dir, '0.35 0.2 0');
};


//============================================================================

void()	enft_stand1	=[	$stand1,	enft_stand2	] {ai_stand();};
void()	enft_stand2	=[	$stand2,	enft_stand3	] {ai_stand();};
void()	enft_stand3	=[	$stand3,	enft_stand4	] {ai_stand();};
void()	enft_stand4	=[	$stand4,	enft_stand5	] {ai_stand();};
void()	enft_stand5	=[	$stand5,	enft_stand6	] {ai_stand();};
void()	enft_stand6	=[	$stand6,	enft_stand7	] {ai_stand();};
void()	enft_stand7	=[	$stand7,	enft_stand1	] {ai_stand();};

void()	enft_walk1	=[	$walk1 ,	enft_walk2	] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "me/meidle.wav", 1, ATTN_IDLE);
ai_walk(2);self.nextthink=time+0.3;self.takedamage = DAMAGE_NO;};
void()	enft_walk2	=[	$walk2 ,	enft_walk3	] {ai_walk(4);self.nextthink=time+0.3;};
void()	enft_walk3	=[	$walk3 ,	enft_walk4	] {ai_walk(4);self.nextthink=time+0.3;};
void()	enft_walk4	=[	$walk4 ,	enft_walk5	] {ai_walk(3);self.nextthink=time+0.3;};
void()	enft_walk5	=[	$walk5 ,	enft_walk6	] {ai_walk(1);self.nextthink=time+0.3;};
void()	enft_walk6	=[	$walk6 ,	enft_walk7	] {ai_walk(2);self.nextthink=time+0.3;};
void()	enft_walk7	=[	$walk7 ,	enft_walk8	] {ai_walk(2);self.nextthink=time+0.3;};
void()	enft_walk8	=[	$walk8 ,	enft_walk9	] {ai_walk(1);self.nextthink=time+0.3;};
void()	enft_walk9	=[	$walk9 ,	enft_walk10	] {ai_walk(2);self.nextthink=time+0.3;};
void()	enft_walk10	=[	$walk10,	enft_walk11	] {ai_walk(4);self.nextthink=time+0.3;};
void()	enft_walk11	=[	$walk11,	enft_walk12	] {ai_walk(4);self.nextthink=time+0.3;};
void()	enft_walk12	=[	$walk12,	enft_walk13	] {ai_walk(1);self.nextthink=time+0.3;};
void()	enft_walk13	=[	$walk13,	enft_walk14	] {ai_walk(2);self.nextthink=time+0.3;};
void()	enft_walk14	=[	$walk14,	enft_walk15	] {ai_walk(3);self.nextthink=time+0.3;};
void()	enft_walk15	=[	$walk15,	enft_walk16	] {ai_walk(4);self.nextthink=time+0.3;};
void()	enft_walk16	=[	$walk16,	enft_walk1	] {ai_walk(2);self.nextthink=time+0.3;};

void()	enft_run1	=[	$run1  ,	enft_run2	] {
self.takedamage = DAMAGE_NO;
ai_run(18);self.nextthink=time+0.2;};
void()	enft_run2	=[	$run2  ,	enft_run3	] {ai_run(14);self.nextthink=time+0.2;};
void()	enft_run3	=[	$run3  ,	enft_run4	] {ai_run(7);self.nextthink=time+0.2;};
void()	enft_run4	=[	$run4  ,	enft_run5	] {ai_run(12);self.nextthink=time+0.2;};
void()	enft_run5	=[	$run5  ,	enft_run6	] {ai_run(14);self.nextthink=time+0.2;};
void()	enft_run6	=[	$run6  ,	enft_run7	] {ai_run(14);self.nextthink=time+0.2;};
void()	enft_run7	=[	$run7  ,	enft_run8	] {ai_run(7);self.nextthink=time+0.2;};
void()	enft_run8	=[	$run8  ,	enft_run1	] {ai_run(11);self.nextthink=time+0.2;};

void()	enft_atka1	=[	$attack1,	enft_atka2	] {ai_face();self.nextthink=time+0.2;self.takedamage = DAMAGE_AIM;
sound (self, CHAN_AUTO, "me/me_soff.wav", 1, ATTN_NORM);};
void()	enft_atka2	=[	$attack2,	enft_atka3	] {ai_face();self.nextthink=time+0.2;};
void()	enft_atka3	=[	$attack3,	enft_atka4	] {ai_face();self.nextthink=time+0.2;};
void()	enft_atka4	=[	$attack4,	enft_atka5	] {enft_fire();ai_face();self.nextthink=time+0.2;};
void()	enft_atka5	=[	$attack5,	enft_atka6	] {enft_fire();ai_face();self.nextthink=time+0.2;};
void()	enft_atka6	=[	$attack6,	enft_atka7	] {enft_fire();ai_face();self.nextthink=time+0.2;};
void()	enft_atka7	=[	$attack7,	enft_atka8	] {self.nextthink=time+0.2;};
void()	enft_atka8	=[	$attack8,	enft_run1	] {self.nextthink=time+0.5;};

void()	enft_atkb1	=[	$attackp1,	enft_atkb2	] {ai_face();self.nextthink=time+0.3;self.takedamage = DAMAGE_AIM;
sound (self, CHAN_AUTO, "me/sboom2.wav", 1, ATTN_NORM);};
void()	enft_atkb2	=[	$attackp2,	enft_atkb3	] {ai_face();self.nextthink=time+1.5;};
void()	enft_atkb3	=[	$attackp3,	enft_atkb4	] {ai_face();self.nextthink=time+1.5;};
void()	enft_atkb4	=[	$attackp4,	enft_atkb5	] {enft_fireb();ai_face();self.nextthink=time+0.2;};
void()	enft_atkb5	=[	$attackp5,	enft_atkb6	] {enft_fireb();ai_face();self.nextthink=time+0.2;};
void()	enft_atkb6	=[	$attackp6,	enft_atkb7	] {enft_fireb();ai_face();self.nextthink=time+0.2;};
void()	enft_atkb7	=[	$attackp7,	enft_atkb8	] {enft_fireb();ai_face();self.nextthink=time+0.2;};
void()	enft_atkb8	=[	$attackp7,	enft_run1	] {enft_fireb();ai_face();self.nextthink=time+0.2;};

void()	enft_atkc1	=[	$attackp1,	enft_atkc2	] {ai_face();self.nextthink=time+0.5;self.takedamage = DAMAGE_AIM;
sound (self, CHAN_AUTO, "weapons/bfg.wav", 1, ATTN_NORM);};
void()	enft_atkc2	=[	$attackp2,	enft_atkc3	] {self.nextthink=time+0.5;};
void()	enft_atkc3	=[	$attackp3,	enft_atkc4	] {self.nextthink=time+0.5;};
void()	enft_atkc4	=[	$attackp4,	enft_atkc5	] {enft_laser();ai_face();};
void()	enft_atkc5	=[	$attackp5,	enft_atkc6	] {enft_laser();ai_face();};
void()	enft_atkc6	=[	$attackp6,	enft_atkc7	] {enft_laser();ai_face();};
void()	enft_atkc7	=[	$attackp7,	enft_atkc8	] {enft_laser();ai_face();};
void()	enft_atkc8	=[	$attackp7,	enft_run1	] {enft_laser();ai_face();};

void()	enft_atkd1	=[	$attack1,	enft_atkd2	] {ai_face();self.nextthink=time+0.5;self.takedamage = DAMAGE_AIM;
sound (self, CHAN_AUTO, "weapons/bfg.wav", 1, ATTN_NORM);};
void()	enft_atkd2	=[	$attack2,	enft_atkd3	] {self.nextthink=time+1.5;};
void()	enft_atkd3	=[	$attack3,	enft_atkd4	] {self.nextthink=time+1.5;};
void()	enft_atkd4	=[	$attack4,	enft_atkd5	] {enft_fire();ai_face();self.nextthink=time+1.0;};
void()	enft_atkd5	=[	$attack5,	enft_atkd6	] {enft_fire();ai_face();self.nextthink=time+0.8;};
void()	enft_atkd6	=[	$attack6,	enft_atkd7	] {enft_fire();ai_face();self.nextthink=time+0.6;};
void()	enft_atkd7	=[	$attack7,	enft_atkd8	] {enft_fire();ai_face();self.nextthink=time+0.4;};
void()	enft_atkd8	=[	$attack8,	enft_run1	] {enft_fire();ai_face();self.nextthink=time+0.4;};

void()	enf_atkrc1	=[	$attack1,	enf_atkrc2	] {ai_face();self.takedamage = DAMAGE_AIM;
sound (self, CHAN_AUTO, "weapons/bfg.wav", 1, ATTN_NORM);self.nextthink=time+1.0;};
void()	enf_atkrc2	=[	$attack2,	enf_atkrc3	] {ai_face();self.nextthink=time+1.0;};
void()	enf_atkrc3	=[	$attack3,	enf_atkrc4	] {ai_face();};
void()	enf_atkrc4	=[	$attack4,	enf_atkrc5	] {ai_face();};
void()	enf_atkrc5	=[	$attack5,	enf_atkrc6	] {ai_face();};
void()	enf_atkrc6	=[	$attack6,	enf_atkrc7	] {
enf_rshot();
sound (self, CHAN_WEAPON, "weapons/rshotgn.wav", 1, ATTN_NORM);};
void()	enf_atkrc7	=[	$attack7,	enf_atkrc8	] {ai_face();};
void()	enf_atkrc8	=[	$attack8,	enf_atkrc9	] {ai_face();};
void()	enf_atkrc9	=[	$attack5,	enf_atkrc10	] {ai_face();};
void()	enf_atkrc10	=[	$attack6,	enf_atkrc11	] {enf_rshot();};
void()	enf_atkrc11	=[	$attack7,	enf_atkrc12	] {ai_face();};
void()	enf_atkrc12	=[	$attack8,	enf_atkrc13	] {ai_face();};
void()	enf_atkrc13	=[	$attack9,	enf_atkrc14	] {ai_face();};
void()	enf_atkrc14	=[	$attack10,	enf_run1	] {ai_face();
SUB_CheckRefire (enf_atkrc1);
};

void()	enft_paina1	=[	$paina1,	enft_paina2	] {};
void()	enft_paina2	=[	$paina2,	enft_paina3	] {};
void()	enft_paina3	=[	$paina3,	enft_paina4	] {};
void()	enft_paina4	=[	$paina4,	enft_run1	] {};

void()	enft_painb1	=[	$painb1,	enft_painb2	] {};
void()	enft_painb2	=[	$painb2,	enft_painb3	] {};
void()	enft_painb3	=[	$painb3,	enft_painb4	] {};
void()	enft_painb4	=[	$painb4,	enft_painb5	] {};
void()	enft_painb5	=[	$painb5,	enft_run1	] {};

void()	enft_painc1	=[	$painc1,	enft_painc2	] {};
void()	enft_painc2	=[	$painc2,	enft_painc3	] {};
void()	enft_painc3	=[	$painc3,	enft_painc4	] {};
void()	enft_painc4	=[	$painc4,	enft_painc5	] {};
void()	enft_painc5	=[	$painc5,	enft_painc6	] {};
void()	enft_painc6	=[	$painc6,	enft_painc7	] {};
void()	enft_painc7	=[	$painc7,	enft_painc8	] {};
void()	enft_painc8	=[	$painc8,	enft_run1	] {};

void()	enft_paind1	=[	$paind1,	enft_paind2	] {};
void()	enft_paind2	=[	$paind2,	enft_paind3	] {};
void()	enft_paind3	=[	$paind3,	enft_paind4	] {};
void()	enft_paind4	=[	$paind4,	enft_paind5	] {ai_painforward(2);};
void()	enft_paind5	=[	$paind5,	enft_paind6	] {ai_painforward(1);};
void()	enft_paind6	=[	$paind6,	enft_paind7	] {};
void()	enft_paind7	=[	$paind7,	enft_paind8	] {};
void()	enft_paind8	=[	$paind8,	enft_paind9	] {};
void()	enft_paind9	=[	$paind9,	enft_paind10	] {};
void()	enft_paind10	=[	$paind10,	enft_paind11	] {};
void()	enft_paind11	=[	$paind11,	enft_paind12	] {ai_painforward(1);};
void()	enft_paind12	=[	$paind12,	enft_paind13	] {ai_painforward(1);};
void()	enft_paind13	=[	$paind13,	enft_paind14	] {ai_painforward(1);};
void()	enft_paind14	=[	$paind14,	enft_paind15	] {};
void()	enft_paind15	=[	$paind15,	enft_paind16	] {};
void()	enft_paind16	=[	$paind16,	enft_paind17	] {ai_pain(1);};
void()	enft_paind17	=[	$paind17,	enft_paind18	] {ai_pain(1);};
void()	enft_paind18	=[	$paind18,	enft_paind19	] {};
void()	enft_paind19	=[	$paind19,	enft_run1	] {};

void(entity attacker, float damage)	enft_pain =
{
	local float r;

	r = random ();
	if (self.pain_finished > time)
		return;
	

	if (r < 0.09)
	{
		self.pain_finished = time + 2;
		enft_paina1 ();
	}
	else if (r < 0.08)
	{
		sound (self, CHAN_VOICE, "me/mepain1.wav", 1, ATTN_NORM);
		self.pain_finished = time + 3;
		enft_painb1 ();
	}
	else if (r < 0.07)
	{
		sound (self, CHAN_VOICE, "me/mepain2.wav", 1, ATTN_NORM);
		self.pain_finished = time + 4;
		enft_painc1 ();
	}
	else if (r < 0.06)
	{
		sound (self, CHAN_VOICE, "me/pain3.wav", 1, ATTN_NORM);
		self.pain_finished = time + 5;
		enft_paind1 ();
	}
};

//============================================================================


void(float xco, float yco, float zco) SpawnExplosion =
{

   WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
   WriteByte (MSG_BROADCAST, TE_EXPLOSION);
   WriteCoord (MSG_BROADCAST, xco);
   WriteCoord (MSG_BROADCAST, yco);
   WriteCoord (MSG_BROADCAST, zco);
};

void()	enft_die1	=[	$death1,	enft_die2	] {};
void()	enft_die2	=[	$death2,	enft_die3	] {};
void()	enft_die3	=[	$death3,	enft_die4	]
{self.solid = SOLID_NOT;self.ammo_cells = 15;self.ammo_nails = 15;DropBackpack();};
void()	enft_die4	=[	$death4,	enft_die5	] {ai_forward(14);
     SpawnExplosion (self.origin_x, self.origin_y + 20, self.origin_z + 60);ai_pain(3);
     sound (self, 1, "weapons/r_exp3.wav", 0.4, ATTN_NORM);};
void()	enft_die5	=[	$death5,	enft_die6	] {ai_forward(2);
     SpawnExplosion (self.origin_x, self.origin_y + 20, self.origin_z + 60);ai_pain(3);
     sound (self, 1, "weapons/r_exp3.wav", 0.4, ATTN_NORM);};
void()	enft_die6	=[	$death6,	enft_die7	] {};
void()	enft_die7	=[	$death7,	enft_die8	] {};
void()	enft_die8	=[	$death8,	enft_die9	] {};
void()	enft_die9	=[	$death9,	enft_die10	] {ai_forward(3);
     SpawnExplosion (self.origin_x, self.origin_y - 20, self.origin_z + 40);ai_pain(3);
     sound (self, 2, "weapons/r_exp3.wav", 0.4, ATTN_NORM);};
void()	enft_die10	=[	$death10,	enft_die11	] {ai_forward(5);};
void()	enft_die11	=[	$death11,	enft_die12	] {ai_forward(5);};
void()	enft_die12	=[	$death12,	enft_die13	] {ai_forward(5);
     SpawnExplosion (self.origin_x - 20, self.origin_y, self.origin_z+20);

     };
void()	enft_die13	=[	$death13,	enft_die14	] {};
void()	enft_die14	=[	$death14,	enft_die14	] {ai_pain(3);
		ThrowHead ("progs/h_me.mdl", -1000);
		ThrowGib ("progs/gib1.mdl", -1000);
		ThrowGib ("progs/gib2.mdl", -1000);
		ThrowGib ("progs/gib3.mdl", -1000);
		ThrowGib ("progs/gib3.mdl", -1000);
        ThrowGib ("progs/gib3.mdl", -1000);
        ThrowGib ("progs/gib3.mdl", -1000);
         return;};

void()	enft_fdie1	=[	$fdeath1,	enft_fdie2	] {

};
void()	enft_fdie2	=[	$fdeath2,	enft_fdie3	] {};
void()	enft_fdie3	=[	$fdeath3,	enft_fdie4	]
{self.solid = SOLID_NOT;self.ammo_cells = 5;DropBackpack();};
void()	enft_fdie4	=[	$fdeath4,	enft_fdie5	] {};
void()	enft_fdie5	=[	$fdeath5,	enft_fdie6	] {};
void()	enft_fdie6	=[	$fdeath6,	enft_fdie7	] {};
void()	enft_fdie7	=[	$fdeath7,	enft_fdie8	] {};
void()	enft_fdie8	=[	$fdeath8,	enft_fdie9	] {};
void()	enft_fdie9	=[	$fdeath9,	enft_fdie10	] {};
void()	enft_fdie10	=[	$fdeath10,	enft_fdie11	] {};
void()	enft_fdie11	=[	$fdeath11,	enft_fdie11	] {};


void() enft_die =
{
// check for gib

// regular death
	sound (self, CHAN_VOICE, "enforcer/death1.wav", 1, ATTN_NORM);

		enft_die1 ();

};


/*QUAKED monster_enforcer (1 0 0) (-16 -16 -24) (16 16 40) Ambush

*/
void() monster_enforcertank =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model2 ("progs/enforce2.mdl");
    	precache_model2 ("progs/laser2.mdl");
	precache_model2 ("progs/plusma.spr");
	// QuadEXQ: weapons/rail1.wav was precached but never played (and not in any pak)
	precache_sound2 ("enforcer/death1.wav");
	precache_sound ("weapons/bfg.wav");

	precache_sound2 ("enforcer/enfire2.wav");
	precache_sound2 ("enforcer/enfire3.wav");
	
	precache_sound2 ("enforcer/rail1.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("enforcer/sight1.wav");
	precache_sound2 ("enforcer/sight2.wav");
	precache_sound2 ("enforcer/sight3.wav");
	precache_sound2 ("enforcer/sight4.wav");
	precache_model2 ("progs/h_me.mdl");
	precache_model2 ("progs/memissil.mdl");

	precache_sound2 ("me/meidle.wav");
	precache_sound2 ("me/mepain1.wav");
	precache_sound2 ("me/mepain2.wav");
	precache_sound2 ("me/mepain3.wav");
	precache_sound2 ("me/mesight1.wav");
	precache_sound2 ("me/sboom2.wav");

	precache_sound2 ("me/mesight2.wav");
	precache_sound2 ("me/mesight3.wav");
	precache_sound2 ("me/me_son.wav");
	precache_sound2 ("me/me_soff.wav");
	precache_sound2 ("weapons/bfgx.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/enforce2.mdl");

	setsize (self, '-16 -16 -24', '16 16 40');
	

	self.th_stand = enft_stand1;
	self.th_walk = enft_walk1;
	self.th_run = enft_run1;
	self.th_pain = enft_pain;
	self.th_die = enft_die;
	
	if((random()+random()+random()+random()+random()+random())/6 <0.8){//normally 0.8
	self.th_missile = enft_atkn;
	self.health = 160;
	self.classname = "monster_enft";
	}
	else{self.th_missile = enft_atkcom;self.health = 500; self.classname = "monster_enft_commander";}

	walkmonster_start();
};
