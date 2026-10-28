/*
==============================================================================

OGRE

==============================================================================
*/

$cd id1/models/ogre_c
$origin 0 0 24
$base base
$skin base

$frame	stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7
$frame walk8 walk9 walk10 walk11 walk12 walk13 walk14 walk15 walk16

$frame run1 run2 run3 run4 run5 run6 run7 run8

$frame swing1 swing2 swing3 swing4 swing5 swing6 swing7
$frame swing8 swing9 swing10 swing11 swing12 swing13 swing14

$frame smash1 smash2 smash3 smash4 smash5 smash6 smash7
$frame smash8 smash9 smash10 smash11 smash12 smash13 smash14

$frame shoot1 shoot2 shoot3 shoot4 shoot5 shoot6

$frame pain1 pain2 pain3 pain4 pain5

$frame painb1 painb2 painb3

$frame painc1 painc2 painc3 painc4 painc5 painc6

$frame paind1 paind2 paind3 paind4 paind5 paind6 paind7 paind8 paind9 paind10
$frame paind11 paind12 paind13 paind14 paind15 paind16

$frame paine1 paine2 paine3 paine4 paine5 paine6 paine7 paine8 paine9 paine10
$frame paine11 paine12 paine13 paine14 paine15

$frame death1 death2 death3 death4 death5 death6
$frame death7 death8 death9 death10 death11 death12
$frame death13 death14

$frame bdeath1 bdeath2 bdeath3 bdeath4 bdeath5 bdeath6
$frame bdeath7 bdeath8 bdeath9 bdeath10

$frame pull1 pull2 pull3 pull4 pull5 pull6 pull7 pull8 pull9 pull10 pull11

//=============================================================================
void() qogre_nailutf1;
void() qogre_nail1;
void() qogre_atat1;
void() qogre_rock1;
void() qogre_nuke1;
void() qogre_swing1;

void() qogre_atka =
{
if(random()<0.15)
	qogre_nailutf1();
else if(vlen(self.enemy.origin - self.origin) < 700 ){
	if(vlen(self.enemy.origin - self.origin) < 150 )
		qogre_swing1();
	else
		qogre_nail1();
}
else
	qogre_rock1();
};
void() qogre_atkb =
{

 if(vlen(self.enemy.origin - self.origin) < 800 ){
	if(vlen(self.enemy.origin - self.origin) < 250 )
		qogre_swing1();
	else
		qogre_atat1();
}
else
	qogre_nail1();
};


void() Nogre_atk =
{
if(random()<0.15)
	qogre_nuke1();
else if(vlen(self.enemy.origin - self.origin) < 700 ){
	if(vlen(self.enemy.origin - self.origin) < 350 )
		qogre_swing1();
		
	qogre_nail1();
}
else
	qogre_rock1();
};


void() qogre_MissileTouch2 =
{
	local float	damg;

	if (other == self.owner)
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 10 + random()*5;	//random()は0.0～1.0間の乱数を返す、ロケットのダメージは50に
						//乱数と10の積を加えたものである

	if (other.health)					//接触した相手に体力がある場合
	{
		if (other.classname == "monster_shambler")	//接触した相手がシャンブラーだった場合
			damg = damg * 0.5;				//ダメージ半減
		T_Damage (other, self, self.owner, damg );	//接触した相手にダメージを与える
	}

	// entity other(接触した相手)に対し、爆風による特定空間内ダメージ処理を行わない
	// 既にロケットが接触した際、ダメージを与えているからである
	T_RadiusDamage (self, self.owner, 15, other);	//特定空間内ダメージ処理(無視する相手にotherを指定)

	self.origin = self.origin - 8*normalize(self.velocity);		//爆発の表示位置を接触地点より8だけ後退

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);	//テンポラリentityのネットワークメッセージ送信
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);	//ここで爆発音を指定している
	WriteCoord (MSG_BROADCAST, self.origin_x);	//爆発音発生地点を指定
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();		//ロケットは爆発へ変身
};
void() qogre_MissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 40 + crandom()*60;

	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;
		T_Damage (other, self, self.owner, damg );
	}

	// entity other(接触した相手)に対し、爆風による特定空間内ダメージ処理を行わない
	// 既にロケットが接触した際、ダメージを与えているからである
	T_RadiusDamage (self, self.owner, damg, other);	//特定空間内ダメージ処理(無視する相手にotherを指定)

	self.origin = self.origin - 8*normalize(self.velocity);		//爆発の表示位置を接触地点より8だけ後退

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);	//テンポラリentityのネットワークメッセージ送信
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);	//ここで爆発音を指定している
	WriteCoord (MSG_BROADCAST, self.origin_x);	//爆発音発生地点を指定
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();		//ロケットは爆発へ変身
};


void() QOgreGrenadeExplode2 =
{
	T_RadiusDamage (self, self.owner, 30, world);
	sound (self, CHAN_VOICE, "weapons/dx.wav", 1, ATTN_NORM);

	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() QOgreNukeExplode =
{
	local float	damg,tmp;
	local entity grenade;

	T_RadiusDamage (self, self.owner, 240, world);
	sound (self, CHAN_VOICE, "weapons/nukex.wav", 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LAVASPLASH);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	while (tmp < 30)
	{
		grenade = spawn();
		grenade.owner = self.owner;
		grenade.movetype = MOVETYPE_BOUNCE;
		grenade.solid = SOLID_BBOX;
		grenade.classname = "cluster";
		grenade.enemy = self.owner.enemy;
		grenade.think = QOgreGrenadeExplode2;
		grenade.nextthink = time + random() * 0.5;
		grenade.velocity_z = 800 * random() - 200;
		grenade.velocity_x = 600 * random() - 300;
		grenade.velocity_y = 600* random() - 300;
		grenade.avelocity = '300 300 300';
        	grenade.angles = vectoangles(grenade.velocity);
		setmodel(grenade,"progs/lavaball.mdl");
		setsize(grenade,'0 0 0','0 0 0');
		setorigin(grenade,self.origin);
		tmp = tmp + 1;
	}

	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() QOgreGrenadeExplode =
{
	local float	damg,tmp;
	local entity grenade;

	T_RadiusDamage (self, self.owner, 30, world);
	sound (self, CHAN_VOICE, "weapons/r_exp3.wav", 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	while (tmp < 5)
	{
		grenade = spawn();
		grenade.owner = self.owner;
		grenade.movetype = MOVETYPE_BOUNCE;
		grenade.solid = SOLID_BBOX;
		grenade.classname = "cluster";
		grenade.enemy = self.owner.enemy;
		grenade.think = QOgreGrenadeExplode2;
		grenade.nextthink = time + random() * 0.5;
		grenade.velocity_z = 800 * random() - 200;
		grenade.velocity_x = 600 * random() - 300;
		grenade.velocity_y = 600* random() - 300;
		grenade.avelocity = '300 300 300';
        	grenade.angles = vectoangles(grenade.velocity);
		setmodel(grenade,"progs/lavaball.mdl");
		setsize(grenade,'0 0 0','0 0 0');
		setorigin(grenade,self.origin);
		tmp = tmp + 1;
	}

	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
void() QOgreGrenadeTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner
		QOgreGrenadeExplode();
		return;
	
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

void() QOgreNukeTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner

	sound (self, CHAN_VOICE, "blob/land1.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};


/*
================
OgreFireGrenade
================
*/
void() QOgreFireNuke =
{
	local	entity missile, mpuff,rocket,en;
	local 	float	cmp;
	
	self.effects = self.effects | EF_MUZZLEFLASH;
    	sound (self, CHAN_WEAPON, "daikon/grenade.wav", 1, ATTN_NORM);
    
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;

// set missile speed

	makevectors (self.v_angle);
	
	cmp=vlen(self.enemy.origin - self.origin);
	missile.velocity = normalize(self.enemy.origin - self.origin);
	missile.velocity = missile.velocity * (600 + cmp);
	missile.velocity_z = missile.velocity_z + cmp/3;

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

	missile.touch = QOgreNukeTouch;

// set missile duration
	missile.nextthink = time + 1.0;
	missile.think = QOgreNukeExplode;

	setmodel (missile, "progs/tarbaby.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

void() QOgreFireTGrenade =
{
	local	entity missile, mpuff,rocket,en;
	local 	float	cmp;
	
	self.effects = self.effects | EF_MUZZLEFLASH;
    	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;

// set missile speed

	makevectors (self.v_angle);
	
	cmp=vlen(self.enemy.origin - self.origin);
	missile.velocity = normalize(self.enemy.origin - self.origin);
	missile.velocity = missile.velocity * (600 + cmp);
	missile.velocity_z = missile.velocity_z + cmp/3;

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

	missile.touch = QOgreGrenadeTouch;

// set missile duration
	missile.nextthink = time + 1.0;
	missile.think = QOgreGrenadeExplode;

	setmodel (missile, "progs/lavaball.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};
void() QOgreFireGrenade =
{
	local	entity missile, mpuff,rocket,en;
	local 	float	cmp;
	
	self.effects = self.effects | EF_MUZZLEFLASH;
    	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;

// set missile speed

	makevectors (self.v_angle);
	
	cmp=vlen(self.enemy.origin - self.origin);
	missile.velocity = normalize(self.enemy.origin - self.origin);
	missile.velocity = missile.velocity * 600;
	missile.velocity_z = missile.velocity_z + cmp/2;

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);

	missile.touch = OgreGrenadeTouch;

// set missile duration
	missile.nextthink = time + 2.5;
	missile.think = OgreGrenadeExplode;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
};

void() QOgreFireMissile =
{
	local entity en, rocket;
	local vector dir;

	en = self.enemy;

	dir = en.origin - en.velocity*0.2;
	dir = normalize (dir - self.origin);
        sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	rocket = spawn ();
	rocket.owner = self;
	rocket.movetype = MOVETYPE_FLYMISSILE;
	rocket.solid = SOLID_BBOX;
	rocket.enemy = self.enemy ;
	rocket.classname = "main";
	
	makevectors (self.v_angle);
	rocket.velocity = dir * 500;
	rocket.angles = vectoangles(rocket.velocity);
	rocket.touch = qogre_MissileTouch;

	setmodel (rocket, "progs/missile.mdl");
	setsize (rocket, '0 0 0', '0 0 0');
	setorigin (rocket, self.origin + v_forward*8 + '0 0 16');
        };


//=============================================================================

/*
================
chainsaw

FIXME
================
*/

void(float side) chainsaw_utf =
{
local vector	delta;
local float 	ldmg;

	if (!self.enemy)
		return;
	if (!CanDamage (self.enemy, self))
		return;

	ai_charge(10);

	delta = self.enemy.origin - self.origin;

	if (vlen(delta) > 100)
		return;
	// QuadEXQ: no more instant kill below 50 HP (was ldmg = 1000)
	ldmg = (random() + random() + random()) * 9;
	T_Damage (self.enemy, self, self, ldmg);

	if (side)
	{
		makevectors (self.angles);
		if (side == 1)
			SpawnMeatSpray (self.origin + v_forward*16, crandom() * 100 * v_right);
		else
			SpawnMeatSpray (self.origin + v_forward*16, side * v_right);
	}
};


void() qogre_stand1	=[	$stand1,	qogre_stand2	] {ai_stand();};
void() qogre_stand2	=[	$stand2,	qogre_stand3	] {ai_stand();};
void() qogre_stand3	=[	$stand3,	qogre_stand4	] {ai_stand();};
void() qogre_stand4	=[	$stand4,	qogre_stand5	] {ai_stand();};
void() qogre_stand5	=[	$stand5,	qogre_stand6	] {
if (random() < 0.2)
	sound (self, CHAN_VOICE, "ogre/ogidle.wav", 1, ATTN_IDLE);
ai_stand();
};
void() qogre_stand6	=[	$stand6,	qogre_stand7	] {ai_stand();};
void() qogre_stand7	=[	$stand7,	qogre_stand8	] {ai_stand();};
void() qogre_stand8	=[	$stand8,	qogre_stand9	] {ai_stand();};
void() qogre_stand9	=[	$stand9,	qogre_stand1	] {ai_stand();};

void() qogre_walk1	=[	$walk1,		qogre_walk2	] {ai_walk(3);};
void() qogre_walk2	=[	$walk2,		qogre_walk3	] {ai_walk(2);};
void() qogre_walk3	=[	$walk3,		qogre_walk4	] {
ai_walk(2);
if (random() < 0.2)
	sound (self, CHAN_VOICE, "ogre/ogidle.wav", 1, ATTN_IDLE);
};
void() qogre_walk4	=[	$walk4,		qogre_walk5	] {ai_walk(2);};
void() qogre_walk5	=[	$walk5,		qogre_walk6	] {ai_walk(2);};
void() qogre_walk6	=[	$walk6,		qogre_walk7	] {
ai_walk(5);
if (random() < 0.1)
	sound (self, CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE);
};
void() qogre_walk7	=[	$walk7,		qogre_walk8	] {ai_walk(3);};
void() qogre_walk8	=[	$walk8,		qogre_walk9	] {ai_walk(2);};
void() qogre_walk9	=[	$walk9,		qogre_walk10	] {ai_walk(3);};
void() qogre_walk10	=[	$walk10,	qogre_walk11	] {ai_walk(1);};
void() qogre_walk11	=[	$walk11,	qogre_walk12	] {ai_walk(2);};
void() qogre_walk12	=[	$walk12,	qogre_walk13	] {ai_walk(3);};
void() qogre_walk13	=[	$walk13,	qogre_walk14	] {ai_walk(3);};
void() qogre_walk14	=[	$walk14,	qogre_walk15	] {ai_walk(3);};
void() qogre_walk15	=[	$walk15,	qogre_walk16	] {ai_walk(3);};
void() qogre_walk16	=[	$walk16,	qogre_walk1	] {ai_walk(4);};

void() qogre_run1	=[	$run1,		qogre_run2	] {ai_run(9);
if (random() < 0.2)
	sound (self, CHAN_VOICE, "ogre/ogidle2.wav", 1, ATTN_IDLE);
};
void() qogre_run2	=[	$run2,		qogre_run3	] {ai_run(12);};
void() qogre_run3	=[	$run3,		qogre_run4	] {ai_run(8);};
void() qogre_run4	=[	$run4,		qogre_run5	] {ai_run(22);};
void() qogre_run5	=[	$run5,		qogre_run6	] {ai_run(16);};
void() qogre_run6	=[	$run6,		qogre_run7	] {ai_run(4);};
void() qogre_run7	=[	$run7,		qogre_run8	] {ai_run(13);};
void() qogre_run8	=[	$run8,		qogre_run1	] {ai_run(24);};

void() qogre_swing1	=[	$swing1,		qogre_swing2	] {ai_charge(11);
sound (self, CHAN_WEAPON, "ogre/ogsawatk.wav", 1, ATTN_NORM);
};
void() qogre_swing2	=[	$swing2,		qogre_swing3	] {ai_charge(1);};
void() qogre_swing3	=[	$swing3,		qogre_swing4	] {ai_charge(4);};
void() qogre_swing4	=[	$swing4,		qogre_swing5	] {ai_charge(13);};
void() qogre_swing5	=[	$swing5,		qogre_swing6	] {ai_charge(9); chainsaw_utf(0);self.angles_y = self.angles_y + random()*25;};
void() qogre_swing6	=[	$swing6,		qogre_swing7	] {chainsaw_utf(200);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing7	=[	$swing7,		qogre_swing8	] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing8	=[	$swing8,		qogre_swing9	] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing9	=[	$swing9,		qogre_swing10 ] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing10	=[	$swing10,		qogre_swing11 ] {chainsaw_utf(-200);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing11	=[	$swing11,		qogre_swing12 ] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing12	=[	$swing12,		qogre_swing13 ] {ai_charge(3);};
void() qogre_swing13	=[	$swing13,		qogre_swing14 ] {ai_charge(8);};
void() qogre_swing14	=[	$swing14,		qogre_swing15	] {ai_charge(9);};
void() qogre_swing15	=[	$swing5,		qogre_swing16	] {ai_charge(9); chainsaw_utf(0);self.angles_y = self.angles_y + random()*25;};
void() qogre_swing16	=[	$swing6,		qogre_swing17	] {chainsaw_utf(200);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing17	=[	$swing7,		qogre_swing18	] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing18	=[	$swing8,		qogre_swing19	] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing19	=[	$swing9,		qogre_swing20 ] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing20	=[	$swing10,		qogre_swing21 ] {chainsaw_utf(-200);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing21	=[	$swing11,		qogre_swing22 ] {chainsaw_utf(0);self.angles_y = self.angles_y + random()* 25;};
void() qogre_swing22	=[	$swing12,		qogre_swing23 ] {ai_charge(3);};
void() qogre_swing23	=[	$swing13,		qogre_swing24 ] {ai_charge(8);};
void() qogre_swing24	=[	$swing14,		qogre_run1	] {ai_charge(9);};

void() qogre_smash1	=[	$smash1,		qogre_smash2	] {ai_charge(6);
sound (self, CHAN_WEAPON, "ogre/ogsawatk.wav", 1, ATTN_NORM);
};
void() qogre_smash2	=[	$smash2,		qogre_smash3	] {ai_charge(0);};
void() qogre_smash3	=[	$smash3,		qogre_smash4	] {ai_charge(0);};
void() qogre_smash4	=[	$smash4,		qogre_smash5	] {ai_charge(1);};
void() qogre_smash5	=[	$smash5,		qogre_smash6	] {ai_charge(4);};
void() qogre_smash6	=[	$smash6,		qogre_smash7	] {ai_charge(4); chainsaw_utf(0);};
void() qogre_smash7	=[	$smash7,		qogre_smash8	] {ai_charge(4); chainsaw_utf(0);};
void() qogre_smash8	=[	$smash8,		qogre_smash9	] {ai_charge(10); chainsaw_utf(0);};
void() qogre_smash9	=[	$smash9,		qogre_smash10 ] {ai_charge(13); chainsaw_utf(0);};
void() qogre_smash10	=[	$smash10,		qogre_smash11 ] {chainsaw_utf(1);};
void() qogre_smash11	=[	$smash11,		qogre_smash12 ] {ai_charge(2); chainsaw_utf(0);
self.nextthink = self.nextthink + random()*0.2;};	// slight variation
void() qogre_smash12	=[	$smash12,		qogre_smash13 ] {ai_charge();};
void() qogre_smash13	=[	$smash13,		qogre_smash14 ] {ai_charge(4);};
void() qogre_smash14	=[	$smash14,		qogre_run1	] {ai_charge(12);};

void() qogre_nail1	=[	$shoot1,		qogre_nail2	] {ai_face();};
void() qogre_nail2	=[	$shoot2,		qogre_nail3	] {ai_face();};
void() qogre_nail3	=[	$shoot2,		qogre_nail4	] {ai_face();};
void() qogre_nail4	=[	$shoot3,		qogre_nail5	] {ai_face();QOgreFireTGrenade();};
void() qogre_nail5	=[	$shoot4,		qogre_nail6	] {ai_face();};
void() qogre_nail6	=[	$shoot5,		qogre_nail7	] {ai_face();};
void() qogre_nail7	=[	$shoot6,		qogre_run1	] {ai_face();};

void() qogre_rock1	=[	$shoot1,		qogre_rock2	] {ai_face();};
void() qogre_rock2	=[	$shoot2,		qogre_rock3	] {ai_face();};
void() qogre_rock3	=[	$shoot2,		qogre_rock4	] {ai_face();};
void() qogre_rock4	=[	$shoot3,		qogre_rock5	] {ai_face();QOgreFireMissile();};
void() qogre_rock5	=[	$shoot4,		qogre_rock6	] {ai_face();};
void() qogre_rock6	=[	$shoot5,		qogre_rock7	] {ai_face();};
void() qogre_rock7	=[	$shoot6,		qogre_run1	] {ai_face();};

void() qogre_cg_fire =
{
	local	vector	dir;
	local	entity	en;
	local	vector	vel, org, reverse;
	
	ai_face();
	self.effects = self.effects | EF_MUZZLEFLASH;

	sound (self, CHAN_WEAPON, "weapons/cgshot2.wav", 1, ATTN_NORM);	

	// fire somewhat behind the player, so a dodging player is harder to hit
	en = self.enemy;
	
	dir = en.origin - en.velocity*0.7;
	dir = normalize (dir - self.origin);
	FireTracer (dir);
	
	org = self.origin  + '0 0 12';
	
	traceline (org, org + dir*2048, FALSE, self);
	
	vel = dir;
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
		T_Damage (trace_ent, self, self, 10);
	
	CG_puff (org, vel, 10 * 2, 0.3);

};

void() qogre_atat1   =[$shoot1, qogre_atat2  ] {sound (self, CHAN_WEAPON, "weapons/cg_strt.wav", 1, ATTN_NORM);self.weaponframe = 0;
self.nextthink=time+0.15;};
void() qogre_atat2   =[$shoot1, qogre_atat3  ] {self.weaponframe = 0;self.nextthink=time+0.15;};
void() qogre_atat3   =[$shoot1, qogre_atat4  ] {self.weaponframe = 0;self.nextthink=time+0.15;};
void() qogre_atat4   =[$shoot1, qogre_atat5  ] {self.weaponframe = 0;self.nextthink=time+0.15;};
void() qogre_atat5   =[$shoot2, qogre_atat6  ] {qogre_cg_fire();};

void() qogre_atat6   =[$shoot3, qogre_atat7  ]{qogre_cg_fire();};
void() qogre_atat7   =[$shoot2, qogre_atat8  ]{qogre_cg_fire();};
void() qogre_atat8   =[$shoot3, qogre_atat9 ]{qogre_cg_fire();};
void() qogre_atat9   =[$shoot2, qogre_atat10  ]{qogre_cg_fire();};
void() qogre_atat10   =[$shoot3, qogre_run1  ]{qogre_cg_fire();self.nextthink=time+0.5;};


void() qogre_nuke1	=[	$shoot1,		qogre_nuke2	] {
ai_face();
self.nextthink=time+1.5;
sound (self, CHAN_WEAPON, "daikon/koredemo.wav", 1, ATTN_NORM);};
void() qogre_nuke2	=[	$shoot2,		qogre_nuke3	] {ai_face();self.nextthink=time+0.3;};
void() qogre_nuke3	=[	$shoot2,		qogre_nuke4	] {ai_face();self.nextthink=time+0.3;};
void() qogre_nuke4	=[	$shoot3,		qogre_nuke5	] {ai_face();QOgreFireNuke();};
void() qogre_nuke5	=[	$shoot4,		qogre_nuke6	] {ai_face();};
void() qogre_nuke6	=[	$shoot5,		qogre_nuke7	] {ai_face();};
void() qogre_nuke7	=[	$shoot6,		qogre_run1	] {ai_face();};


void() qogre_nailutf1	=[	$shoot1,		qogre_nailutf2	] {ai_face();};
void() qogre_nailutf2	=[	$shoot2,		qogre_nailutf3	] {ai_face();};
void() qogre_nailutf3	=[	$shoot2,		qogre_nailutf4	] {ai_face();};
void() qogre_nailutf4	=[	$shoot3,		qogre_nailutf5	] {ai_face();QOgreFireGrenade();};
void() qogre_nailutf5	=[	$shoot2,		qogre_nailutf6	] {ai_face();};
void() qogre_nailutf6	=[	$shoot3,		qogre_nailutf7	] {ai_face();QOgreFireGrenade();};
void() qogre_nailutf7	=[	$shoot2,		qogre_nailutf8	] {ai_face();};
void() qogre_nailutf8	=[	$shoot3,		qogre_nailutf9	] {ai_face();QOgreFireGrenade();};
void() qogre_nailutf9	=[	$shoot4,		qogre_nailutf10	] {ai_face();};
void() qogre_nailutf10	=[	$shoot5,		qogre_nailutf11	] {ai_face();};
void() qogre_nailutf11	=[	$shoot4,		qogre_run1	] {ai_face();};




void()	qogre_pain1	=[	$pain1,		qogre_pain2	] {};
void()	qogre_pain2	=[	$pain2,		qogre_pain3	] {};
void()	qogre_pain3	=[	$pain3,		qogre_pain4	] {};
void()	qogre_pain4	=[	$pain4,		qogre_pain5	] {};
void()	qogre_pain5	=[	$pain5,		qogre_run1	] {};


void()	qogre_painb1	=[	$painb1,	qogre_painb2	] {};
void()	qogre_painb2	=[	$painb2,	qogre_painb3	] {};
void()	qogre_painb3	=[	$painb3,	qogre_run1	] {};


void()	qogre_painc1	=[	$painc1,	qogre_painc2	] {};
void()	qogre_painc2	=[	$painc2,	qogre_painc3	] {};
void()	qogre_painc3	=[	$painc3,	qogre_painc4	] {};
void()	qogre_painc4	=[	$painc4,	qogre_painc5	] {};
void()	qogre_painc5	=[	$painc5,	qogre_painc6	] {};
void()	qogre_painc6	=[	$painc6,	qogre_run1	] {};


void()	qogre_paind1	=[	$paind1,	qogre_paind2	] {};
void()	qogre_paind2	=[	$paind2,	qogre_paind3	] {ai_pain(10);};
void()	qogre_paind3	=[	$paind3,	qogre_paind4	] {ai_pain(9);};
void()	qogre_paind4	=[	$paind4,	qogre_paind5	] {ai_pain(4);};
void()	qogre_paind5	=[	$paind5,	qogre_paind6	] {};
void()	qogre_paind6	=[	$paind6,	qogre_paind7	] {};
void()	qogre_paind7	=[	$paind7,	qogre_paind8	] {};
void()	qogre_paind8	=[	$paind8,	qogre_paind9	] {};
void()	qogre_paind9	=[	$paind9,	qogre_paind10	] {};
void()	qogre_paind10=[	$paind10,	qogre_paind11	] {};
void()	qogre_paind11=[	$paind11,	qogre_paind12	] {};
void()	qogre_paind12=[	$paind12,	qogre_paind13	] {};
void()	qogre_paind13=[	$paind13,	qogre_paind14	] {};
void()	qogre_paind14=[	$paind14,	qogre_paind15	] {};
void()	qogre_paind15=[	$paind15,	qogre_paind16	] {};
void()	qogre_paind16=[	$paind16,	qogre_run1	] {};

void()	qogre_paine1	=[	$paine1,	qogre_paine2	] {};
void()	qogre_paine2	=[	$paine2,	qogre_paine3	] {ai_pain(10);};
void()	qogre_paine3	=[	$paine3,	qogre_paine4	] {ai_pain(9);};
void()	qogre_paine4	=[	$paine4,	qogre_paine5	] {ai_pain(4);};
void()	qogre_paine5	=[	$paine5,	qogre_paine6	] {};
void()	qogre_paine6	=[	$paine6,	qogre_paine7	] {};
void()	qogre_paine7	=[	$paine7,	qogre_paine8	] {};
void()	qogre_paine8	=[	$paine8,	qogre_paine9	] {};
void()	qogre_paine9	=[	$paine9,	qogre_paine10	] {};
void()	qogre_paine10=[	$paine10,	qogre_paine11	] {};
void()	qogre_paine11=[	$paine11,	qogre_paine12	] {};
void()	qogre_paine12=[	$paine12,	qogre_paine13	] {};
void()	qogre_paine13=[	$paine13,	qogre_paine14	] {};
void()	qogre_paine14=[	$paine14,	qogre_paine15	] {};
void()	qogre_paine15=[	$paine15,	qogre_run1	] {};


void(entity attacker, float damage)	qogre_pain =
{
	local float	r;

// don't make multiple pain sounds right after each other
	if (self.pain_finished > time)
		return;

	sound (self, CHAN_VOICE, "ogre/ogpain1.wav", 1, ATTN_NORM);

	r = random();

	if (r < 0.05)
	{
		qogre_pain1 ();
		self.pain_finished = time + 0.1;
	}
	else if (r < 0.05)
	{
		qogre_painb1 ();
		self.pain_finished = time + 0.25;
	}
	else if (r < 0.1)
	{
		qogre_painc1 ();
		self.pain_finished = time + 0.35;
	}
	else if (r < 0.1)
	{
		qogre_paind1 ();
		self.pain_finished = time + 0.15;
	}
	else if (r < 0.1)
	{
		qogre_paine1 ();
		self.pain_finished = time + 0.01;
	}
};

void()	qogre_die1	=[	$death1,	qogre_die2	] {};
void()	qogre_die2	=[	$death2,	qogre_die3	] {};
void()	qogre_die3	=[	$death3,	qogre_die4	]
{self.solid = SOLID_NOT;
self.ammo_rockets = 5;DropBackpack();};
void()	qogre_die4	=[	$death4,	qogre_die5	] {};
void()	qogre_die5	=[	$death5,	qogre_die6	] {};
void()	qogre_die6	=[	$death6,	qogre_die7	] {};
void()	qogre_die7	=[	$death7,	qogre_die8	] {};
void()	qogre_die8	=[	$death8,	qogre_die9	] {};
void()	qogre_die9	=[	$death9,	qogre_die10	] {};
void()	qogre_die10	=[	$death10,	qogre_die11	] {};
void()	qogre_die11	=[	$death11,	qogre_die12	] {};
void()	qogre_die12	=[	$death12,	qogre_die13	] {};
void()	qogre_die13	=[	$death13,	qogre_die14	] {};
void()	qogre_die14	=[	$death14,	qogre_die14	] {};

void()	qogre_bdie1	=[	$bdeath1,	qogre_bdie2	] {};
void()	qogre_bdie2	=[	$bdeath2,	qogre_bdie3	] {ai_forward(5);};
void()	qogre_bdie3	=[	$bdeath3,	qogre_bdie4	]
{self.solid = SOLID_NOT;
self.ammo_rockets = 5;DropBackpack();};
void()	qogre_bdie4	=[	$bdeath4,	qogre_bdie5	] {ai_forward(1);};
void()	qogre_bdie5	=[	$bdeath5,	qogre_bdie6	] {ai_forward(3);};
void()	qogre_bdie6	=[	$bdeath6,	qogre_bdie7	] {ai_forward(7);};
void()	qogre_bdie7	=[	$bdeath7,	qogre_bdie8	] {ai_forward(25);};
void()	qogre_bdie8	=[	$bdeath8,	qogre_bdie9	] {};
void()	qogre_bdie9	=[	$bdeath9,	qogre_bdie10	] {};
void()	qogre_bdie10	=[	$bdeath10,	qogre_bdie10	] {};

void() qogre_die =
{
// check for gib
	if (self.health < -80)
	{
		self.skin= 0;
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		self.ammo_rockets = 3;DropBackpack();
		ThrowHead ("progs/h_ogre.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		ThrowGib ("progs/gib3.mdl", self.health);
		return;
	}

	sound (self, CHAN_VOICE, "ogre/ogdth.wav", 1, ATTN_NORM);

	if (random() < 0.5)
		qogre_die1 ();
	else
		qogre_bdie1 ();
};

void() qogre_melee =
{
	if (random() > 0.5)
		qogre_smash1 ();
	else
		qogre_swing1 ();
};


/*QUAKED monster_ogre (1 0 0) (-32 -32 -24) (32 32 64) Ambush

*/
void() monster_ogre_qutf =
{
	local float skillLevel, spawncont, r;

	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/ogre.mdl");
	precache_model ("progs/h_ogre.mdl");
	precache_model ("progs/grenade.mdl");
	precache_model ("progs/lavaball.mdl");
	precache_model ("progs/tarbaby.mdl");
	precache_sound ("ogre/ogdrag.wav");
	precache_sound ("ogre/ogdth.wav");
	precache_sound ("ogre/ogidle.wav");
	precache_sound ("ogre/ogidle2.wav");
	precache_sound ("ogre/ogpain1.wav");
	precache_sound ("ogre/ogsawatk.wav");
	precache_sound ("ogre/ogwake.wav");
	precache_sound ("weapons/cg_strt.wav");
	precache_sound ("weapons/cgshot2.wav");
	precache_sound ("weapons/dx.wav");
	precache_sound ("weapons/nukex.wav");
	precache_sound ("daikon/grenade.wav");
	precache_sound ("daikon/koredemo.wav");
	precache_sound ("blob/land1.wav");
	
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/ogre.mdl");

	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.health = 366;

	self.th_stand = qogre_stand1;
	self.th_walk = qogre_walk1;
	self.th_run = qogre_run1;
	self.th_die = qogre_die;
	self.th_melee = qogre_melee;
	self.th_missile = qogre_atka;
	self.th_pain = qogre_pain;

	skillLevel = skill;	// QuadEXQ: EXQ skill = PlayerSkill / 32 (0..3), set at map load / after a death
	spawncont = skillLevel * 0.25  + 0.75 * random();
	r=random();
	if(r<0.3)self.th_missile = qogre_atka;
	else if(r < 0.6)
		self.th_missile = qogre_atkb;
	else if(r < 0.9)
		self.th_missile = qogre_rock1;
	else if(spawncont > 1.2)
	{
		self.th_missile = Nogre_atk;
		self.health = 1999;
	}
	else 
		self.th_missile = qogre_atka;

	self.classname="monster_qogre";
	self.skin=1;
	walkmonster_start();
};


