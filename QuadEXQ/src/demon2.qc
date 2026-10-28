/*
==============================================================================

DEMON

==============================================================================
*/

$cd id1/models/demon3
$scale	0.8
$origin 0 0 24
$base base
$skin base

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8 stand9
$frame stand10 stand11 stand12 stand13

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8

$frame run1 run2 run3 run4 run5 run6

$frame leap1 leap2 leap3 leap4 leap5 leap6 leap7 leap8 leap9 leap10
$frame leap11 leap12

$frame pain1 pain2 pain3 pain4 pain5 pain6

$frame death1 death2 death3 death4 death5 death6 death7 death8 death9

$frame attacka1 attacka2 attacka3 attacka4 attacka5 attacka6 attacka7 attacka8
$frame attacka9 attacka10 attacka11 attacka12 attacka13 attacka14 attacka15

//============================================================================
/*
==============
CheckDemonJump

==============
*/
void()	Demon2_JumpTouch;
void() BfgExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_bfg.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
void(entity zapped) ChainZap =
{
local vector dir, enpull;
local float dist;

	//dprint("zap\n");
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	WriteCoord (MSG_BROADCAST, (zapped.origin_x + zapped.view_ofs_x));
	WriteCoord (MSG_BROADCAST, (zapped.origin_y + zapped.view_ofs_y));
	WriteCoord (MSG_BROADCAST, (zapped.origin_z + zapped.view_ofs_z));

	sound (self, CHAN_WEAPON, "weapons/zap.wav", 1, ATTN_NORM);
	particle (zapped.origin, '0 0 100', 225, 120);
	T_Damage (zapped, self.owner, self.owner, self.dmg);
	
	
	if (zapped.takedamage == DAMAGE_AIM){
		dir =normalize(zapped.origin - self.origin);
		dist = vlen(zapped.origin - self.origin);
		if (dist >100) dist = 100;
		enpull = dir * (100 - dist) * 0.3;
		zapped.velocity = zapped.velocity - enpull + '0 0 5';
		if (zapped.flags & FL_ONGROUND)
			zapped.flags = zapped.flags - FL_ONGROUND;
		zapped.avelocity = vectoangles (zapped.velocity);
	}

};


//Lightning zap for BFG20k!!
void() MakeChainBFG =
{
local entity	head;


  	
 	head = findradius(self.origin, 200 + self.dmg * 5);   //this is how far it will chain
	while (head)
	{
	if( (head.health > 1) && (head != self) && (head != self.owner) && (head != self.owner.owner) && !(head.items & IT_INVISIBILITY) ){
			if (visible(head))
			{
			  ChainZap(head);
			  if(!self.aiment)
				self.aiment = head;
			  else if(!self.enemy)
			     	self.enemy = head;
			  else if(!self.oldenemy)
				self.oldenemy = head;
			  self.origin = (head.origin + head.view_ofs);
			  self.think = MakeChainBFG;
			  self.dmg = self.dmg/2;
			  self.nextthink = time + 0.05;
			  if (self.dmg <= 200)remove(self);
			  return;
			}
		 }
		 //dprint("chain refused ");dprint(head.classname);dprint("\n");
		head = head.chain;
	}
	//dprint("chain ran out of entities?\n");
};

void() Dshotex =
{
local entity	l_chain;
local float	damage;
local float rand;
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	damage=25;
	
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	T_Damage (other, self, self.owner, damage * 5);
	l_chain = spawn();
	l_chain.origin = self.origin;
	l_chain.owner = self;
	l_chain.aiment = trace_ent;
	l_chain.t_width = self.t_width;
	l_chain.dmg = damage;
	l_chain.nextthink = time + 0.05;
	l_chain.think = MakeChainBFG;

	sound (self, CHAN_WEAPON, "weapons/bfgx.wav", 1, ATTN_NORM);
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	self.solid = SOLID_NOT;
	self.origin = self.origin - 8*normalize(self.velocity);
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BfgExplosion ();
};

void()Dshot_Fly =
{
local entity	l_chain;
local float	damage;

sound (self, CHAN_WEAPON, "weapons/bfly.wav", 1, ATTN_NORM);

self.nextthink = time + 0.2;
self.think = Dshot_Fly;
self.effects = self.effects | EF_MUZZLEFLASH;
damage=5;
l_chain = spawn();
l_chain.origin = self.origin;
l_chain.owner = self;
l_chain.aiment = trace_ent;
l_chain.t_width = self.t_width;
l_chain.dmg = damage;
l_chain.nextthink = time + 0.05;
l_chain.think = MakeChainBFG;
};

void(float se, float orz) Dshot =
{
	local	entity missile, mpuff,rocket,en;
	local	vector	dir;
	 self.effects = self.effects | EF_MUZZLEFLASH;

		en = self.enemy;	//enに敵の情報をコピー

	dir = en.origin - en.velocity*0.2;		//敵の移動方向に対しやや後退した地点の座標を得る
	dir = normalize (dir - self.origin);


		rocket = spawn ();
		rocket.owner = self;
		rocket.movetype = MOVETYPE_FLYMISSILE;
		rocket.solid = SOLID_BBOX;
		rocket.classname = "demonBFG";

	//ロケットの速度
		makevectors (self.v_angle);		//前方向のベクトル値v_forwardを得るため
		rocket.velocity = dir * 300*se;		//ロケットの飛行スピードを指定
		rocket.angles = vectoangles(rocket.velocity);		//ロケットの向き(グラフィックの)を指定

		rocket.touch =Dshotex;	//ロケットが何者かに接触した場合に呼び出す関数名

	//ロケットの詳細
		rocket.nextthink = time + 0.1 ;		//次回thinkで指定された関数を呼び出すタイミングを指定
		rocket.think =Dshot_Fly;		//nextthinkで指定したタイミングで呼び出す関数名

		setmodel (rocket, "progs/s_light.spr");		//ロケットのmodel指定
		setsize (rocket, '0 0 0', '0 0 0');		//ロケットのサイズ指定
		setorigin (rocket, self.origin + v_forward*8 + '0 0 1' * orz);


};

void()	demon2_jump1	=[	$leap1,		demon2_jump2	] {ai_face();


};
void()	demon2_jump2	=[	$leap2,		demon2_jump3	] {
ai_face();

};
void()	demon2_jump3	=[	$leap3,		demon2_jump4	] {ai_face();};
void()	demon2_jump4	=[	$leap4,		demon2_jump5	]
{

     ai_face();

	 self.touch = Demon2_JumpTouch;
	 makevectors (self.angles);
	 self.origin_z = self.origin_z + 1;
	 self.velocity = v_forward * 500 + '0 0 650';
	 if (self.flags & FL_ONGROUND)
		 self.flags = self.flags - FL_ONGROUND;

};
void()	demon2_jump5	=[	$leap5,		demon2_jump6	] {
};
void()	demon2_jump6	=[	$leap6,		demon2_jump7	] {};
void()	demon2_jump7	=[	$leap7,		demon2_jump8	] {
Dshot(0.7,16);sound (self, CHAN_WEAPON, "demon/dshot1.wav", 1, ATTN_NORM);
};
void()	demon2_jump8	=[ 	$leap8,		demon2_jump9	] {};
void()	demon2_jump9	=[ 	$leap9,		demon2_jump10	] {
};
void()	demon2_jump10	=[ 	$leap10,	demon2_jump1	] {
self.nextthink = time + 3;
// if three seconds pass, assume demon is stuck and jump again
};

void()	demon2_jump11	=[ 	$leap11,	demon2_jump12	] {};
void()	demon2_jump12	=[ 	$leap12,	demon1_run1	] {};

void()	demon2_jmp	=
{
if(random()<0.5){demon2_jump1;}
else{demonb_jump1;}
};


void() demon2_die =
{
	local entity l_chain;
	local float damage;
		
	sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM);
		ThrowHead ("progs/h_demon.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
		ThrowGib ("progs/gib1.mdl", self.health);
	
			
	damage=50;
	self.effects = self.effects | EF_MUZZLEFLASH;
	l_chain = spawn();
	l_chain.origin = self.origin;
	l_chain.owner = self;
	l_chain.aiment = trace_ent;
	l_chain.t_width = self.t_width;
	l_chain.dmg = damage;
	l_chain.nextthink = time + 0.05;
	l_chain.think = MakeChainBFG;

	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	self.solid = SOLID_NOT;
	self.origin = self.origin - 8*normalize(self.velocity);
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BfgExplosion ();
	return;

};



void() monster_demon2 =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/demon2.mdl");
	precache_model ("progs/h_demon.mdl");
	precache_model ("progs/s_bfg.spr");
   	precache_model ("progs/s_light.spr");
	precache_sound ("weapons/zap.wav");
	precache_sound ("demon/dshot1.wav");
	precache_sound ("demon/ddeath.wav");
	precache_sound ("demon/dhit2.wav");
	precache_sound ("demon/djump.wav");
	precache_sound ("demon/dpain1.wav");
	precache_sound ("demon/idle1.wav");
	precache_sound ("demon/sight2.wav");
    
	precache_sound ("weapons/bfgx.wav");
  	precache_sound ("weapons/dx.wav");
  	precache_sound ("weapons/bfly.wav");
    	
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/demon2.mdl");

	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.health = 1666;
	
	self.classname="monster_demon2";
	self.th_stand = demon1_stand1;
	self.th_walk = demon1_walk1;
	self.th_run = demon1_run1;
	self.th_die = demon2_die;
	self.th_melee = demonb_atta1;		// one of two attacks
	self.th_missile = demon2_jump1;			// jump attack
	self.th_pain = demon1_pain;

	walkmonster_start();
};


/*
==============================================================================

DEMON

==============================================================================
*/


void()	Demon2_JumpTouch =
{
	local	float	ldmg;

	if (self.health <= 0)
		return;

	if (other.takedamage)
	{
		if ( vlen(self.velocity) > 200 )
		{
			ldmg = 80 + 40*random();
			T_Damage (other, self, self, ldmg);
		}
	}

	if (!checkbottom(self))
	{
		if (self.flags & FL_ONGROUND)
		{	// jump randomly to not get hung up
//dprint ("popjump\n");
	self.touch = SUB_Null;
	self.think = demon2_jump1;
	self.nextthink = time + 0.1;

//			self.velocity_x = (random() - 0.5) * 600;
//			self.velocity_y = (random() - 0.5) * 600;
//			self.velocity_z = 200;
//			self.flags = self.flags - FL_ONGROUND;
		}
		return;	// not on ground yet
	}

	self.touch = SUB_Null;
	self.think = demon2_jump11;
	self.nextthink = time + 0.1;
};

