/*
==============================================================================
MD

==============================================================================
*/

$cd id1/models/daikon
$origin 0 0 24
$base base

$skin skin

$frame walk1 walk2 walk3 walk4  walk5 walk6 walk7 walk8 walk9 walk10
$frame walk11 walk12 walk13 walk14 walk15 walk16 walk17 walk18 walk19
$frame walk20 walk21 walk22 walk23 walk24 walk25

$frame run1 run2 run3 run4 run5 run6  run7 run8 run9 run10 run11 run12 run13
$frame run14 run15 run16 run17 run18 run19 run20 run21 run22 run23
$frame run24 run25

$frame jump1 jump2 jump3 jump4 jump5 jump6

$frame fly1 fly2 fly3 fly4

$frame exp


void() PoaRail;
void() gishiki_touch =
{
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

// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (9);
		T_Damage (other, self, self.owner, 9999999999);
	}


	remove(self);

};

void(vector org, vector dir) launch_gishiki =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);

	newmis.touch = gishiki_touch;
	newmis.classname = "gishiki";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	newmis.avelocity='0 0 900';
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);

	newmis.velocity = dir * 200;
};

void(float offset) Gishiki =
{
	local	vector	offang;
	local	vector	org, vec;


    offang = vectoangles (self.enemy.origin - self.origin);
	offang_y = offang_y + offset * 6;

	makevectors (offang);

	org = self.origin + self.mins + self.size*0.5 + v_forward * 20;

// set missile speed
	vec = normalize (v_forward);
	vec_z = 0 - vec_z + (random() - 0.5)*0.1;

	launch_gishiki (org, vec);
	newmis.classname = "goshiki";
	setmodel (newmis, "progs/gishiki.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	newmis.velocity = vec*200;
	sound (self, CHAN_WEAPON, "daikon/gishiki.wav", 1, ATTN_NORM);

if(self.health < 2000)
{
offang = vectoangles (self.enemy.origin - self.origin);
	offang_y = offang_y + offset * 6;

	makevectors (offang);

	org = self.origin + self.mins + self.size*0.5 + v_forward * 20;

// set missile speed
	vec = normalize (v_forward);
	vec_z = 0 - vec_z + (random() - 0.5)*0.1;

	launch_gishiki (org, vec);
	newmis.classname = "goshiki";
	setmodel (newmis, "progs/gishiki.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	newmis.velocity = vec*200;
	sound (self, CHAN_WEAPON, "daikon/gishiki.wav", 1, ATTN_NORM);
}
};


void()	daikon_stand1	=[	$walk1,		tbaby_stand1	] {ai_stand();};

void()	daikon_hang1		=[	$walk1,		tbaby_hang1	] {ai_stand();};

void()	daikon_walk1	=[	$walk1,		daikon_walk2	] {ai_turn();};
void()	daikon_walk2	=[	$walk2,		daikon_walk3	] {ai_turn();};
void()	daikon_walk3	=[	$walk3,		daikon_walk4	] {ai_turn();};
void()	daikon_walk4	=[	$walk4,		daikon_walk5	] {ai_turn();};
void()	daikon_walk5	=[	$walk5,		daikon_walk6	] {ai_turn();};
void()	daikon_walk6	=[	$walk6,		daikon_walk7	] {ai_turn();};
void()	daikon_walk7	=[	$walk7,		daikon_walk8	] {ai_turn();};
void()	daikon_walk8	=[	$walk8,		daikon_walk9	] {ai_turn();};
void()	daikon_walk9	=[	$walk9,		daikon_walk10	] {ai_turn();};
void()	daikon_walk10	=[	$walk10,		daikon_walk11	] {ai_turn();};
void()	daikon_walk11	=[	$walk11,		daikon_walk12	] {ai_walk(2);};
void()	daikon_walk12	=[	$walk12,		daikon_walk13	] {ai_walk(2);};
void()	daikon_walk13	=[	$walk13,		daikon_walk14	] {ai_walk(2);};
void()	daikon_walk14	=[	$walk14,		daikon_walk15	] {ai_walk(2);};
void()	daikon_walk15	=[	$walk15,		daikon_walk16	] {ai_walk(2);};
void()	daikon_walk16	=[	$walk16,		daikon_walk17	] {ai_walk(2);};
void()	daikon_walk17	=[	$walk17,		daikon_walk18	] {ai_walk(2);};
void()	daikon_walk18	=[	$walk18,		daikon_walk19	] {ai_walk(2);};
void()	daikon_walk19	=[	$walk19,		daikon_walk20	] {ai_walk(2);};
void()	daikon_walk20	=[	$walk20,		daikon_walk21	] {ai_walk(2);};
void()	daikon_walk21	=[	$walk21,		daikon_walk22	] {ai_walk(2);};
void()	daikon_walk22	=[	$walk22,		daikon_walk23	] {ai_walk(2);};
void()	daikon_walk23	=[	$walk23,		daikon_walk24	] {ai_walk(2);};
void()	daikon_walk24	=[	$walk24,		daikon_walk25	] {ai_walk(2);};
void()	daikon_walk25	=[	$walk25,		daikon_jump1	] {ai_walk(2);PoaRail();};

void()	daikon_run1	=[	$run1,		daikon_run2	] {ai_face();Gishiki(-12);};
void()	daikon_run2	=[	$run2,		daikon_run3	] {ai_face();Gishiki(-8);};
void()	daikon_run3	=[	$run3,		daikon_run4	] {ai_face();Gishiki(-4);};
void()	daikon_run4	=[	$run4,		daikon_run5	] {ai_face();Gishiki(0);};
void()	daikon_run5	=[	$run5,		daikon_run6	] {ai_face();Gishiki(4);};
void()	daikon_run6	=[	$run6,		daikon_run7	] {ai_face();Gishiki(8);};
void()	daikon_run7	=[	$run7,		daikon_run8	] {ai_face();Gishiki(12);};
void()	daikon_run8	=[	$run8,		daikon_run9	] {ai_face();};
void()	daikon_run9	=[	$run9,		daikon_run10	] {ai_face();};
void()	daikon_run10	=[	$run10,		daikon_run11	] {ai_face();};
void()	daikon_run11	=[	$run11,		daikon_run12	] {ai_run(2);};
void()	daikon_run12	=[	$run12,		daikon_run13	] {ai_run(2);};
void()	daikon_run13	=[	$run13,		daikon_run14	] {ai_run(2);};
void()	daikon_run14	=[	$run14,		daikon_run15	] {ai_run(2);};
void()	daikon_run15	=[	$run15,		daikon_run16	] {ai_run(2);};
void()	daikon_run16	=[	$run16,		daikon_run17	] {ai_run(2);};
void()	daikon_run17	=[	$run17,		daikon_run18	] {ai_run(2);Gishiki(12);};
void()	daikon_run18	=[	$run18,		daikon_run19	] {ai_run(2);Gishiki(8);};
void()	daikon_run19	=[	$run19,		daikon_run20	] {ai_run(2);Gishiki(4);};
void()	daikon_run20	=[	$run20,		daikon_run21	] {ai_run(2);Gishiki(0);};
void()	daikon_run21	=[	$run21,		daikon_run22	] {ai_run(2);Gishiki(-4);};
void()	daikon_run22	=[	$run22,		daikon_run23	] {ai_run(2);Gishiki(-8);};
void()	daikon_run23	=[	$run23,		daikon_run24	] {ai_run(2);Gishiki(-12);};
void()	daikon_run24	=[	$run24,		daikon_run25	] {ai_run(2);};
void()	daikon_run25	=[	$run25,		daikon_run1	] {ai_run(2);PoaRail();};


//============================================================================


void() MdGrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 300, self.owner);
	sound (self, CHAN_WEAPON, "daikon/poax.wav", 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
void() MdFireGrenade =
{
	local	entity missile, mpuff,rocket,en;
	local	vector	dir;
	 self.effects = self.effects | EF_MUZZLEFLASH;
    if( vlen( self.origin - self.enemy.origin ) < 600 )
	{



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
	missile.nextthink = time + 0.1;
	missile.think = MdGrenadeExplode;

	setmodel (missile, "progs/sgrenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin);
}
};
void() RailFly =			//ロケット飛行中の処理
{
	local	vector	dir;		//ローカルvectorオブジェクトdirの宣言
	dir = normalize( self.enemy.origin - self.origin ); //ロケットから見た敵の方向の単位ベクトル(長さ1)を得る

   sound (self, CHAN_WEAPON, "daikon/poarail.wav", 1, ATTN_NORM);
   if(skill == 3)
	self.velocity = dir * 2000;		//ロケットの飛行スピードを指定
	else
    self.velocity = dir * 1800;

     self.angles = vectoangles(dir);		//ロケットの向き(グラフィックの)を指定
	self.nextthink = time + 1.0 ;		//次回thinkで指定された関数を呼び出すタイミングを指定
	self.think =RailFly;			//nextthinkで指定したタイミングで呼び出す関数名
};
void() RailTouch =
{
	local float	damg;

	if (other == self.owner)
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 100 + random()*20;	//random()は0.0～1.0間の乱数を返す、ロケットのダメージは50に
						//乱数と10の積を加えたものである

	if (other.health)					//接触した相手に体力がある場合
	{
		if (other.classname == "monster_shambler")	//接触した相手がシャンブラーだった場合
			damg = damg * 500;				//ダメージ半減
		T_Damage (other, self, self.owner, damg );	//接触した相手にダメージを与える
	}

	// entity other(接触した相手)に対し、爆風による特定空間内ダメージ処理を行わない
	// 既にロケットが接触した際、ダメージを与えているからである
	 sound (self, CHAN_WEAPON, "daikon/koredemo.wav", 1, ATTN_NORM);

	T_RadiusDamage (self, self.owner, 100, other);	//特定空間内ダメージ処理(無視する相手にotherを指定)

	self.origin = self.origin - 8*normalize(self.velocity);		//爆発の表示位置を接触地点より8だけ後退

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);	//テンポラリentityのネットワークメッセージ送信
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);	//ここで爆発音を指定している
	WriteCoord (MSG_BROADCAST, self.origin_x);	//爆発音発生地点を指定
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();		//ロケットは爆発へ変身
};
void() PoaRail =
{
	local	entity missile, mpuff,rocket,en;
	local	vector	dir;

if( vlen( self.origin - self.enemy.origin ) > 400 )
	{
        en = self.enemy;	//enに敵の情報をコピー

	    dir = en.origin - en.velocity*0.2;		//敵の移動方向に対しやや後退した地点の座標を得る
	    dir = normalize (dir - self.origin);
        sound (self, CHAN_WEAPON, "daikon/poa.wav", 1, ATTN_NORM);

		rocket = spawn ();
		rocket.owner = self;
		rocket.movetype = MOVETYPE_FLYMISSILE;
		rocket.solid = SOLID_BBOX;
		rocket.enemy = self.enemy ;
		rocket.classname = "poarail";

	//ロケットの速度
		makevectors (self.v_angle);		//前方向のベクトル値v_forwardを得るため
		rocket.velocity = dir * 10 + '0 0 100';		//ロケットの飛行スピードを指定
	//	rocket.avelocity = '300 300 300';		
		rocket.angles = vectoangles(rocket.velocity);		//ロケットの向き(グラフィックの)を指定

		rocket.touch = RailTouch;	//ロケットが何者かに接触した場合に呼び出す関数名

	//ロケットの詳細
		rocket.nextthink = time + 1.5 ;		//次回thinkで指定された関数を呼び出すタイミングを指定
		rocket.think =  RailFly;		//nextthinkで指定したタイミングで呼び出す関数名

		setmodel (rocket, "progs/mdaikon.mdl");		//ロケットのmodel指定
		setsize (rocket, '0 0 0', '0 0 0');		//ロケットのサイズ指定
		setorigin (rocket, self.origin + v_forward*8 + '0 0 100');
					//ロケット発射位置はGRUNT自身の位置よりも少し前方
	  }
  };

void()	daikon_jump1;

void()	daikon_JumpTouch =
{
	local	float	ldmg;

	if (other.takedamage && other.classname != self.classname)
	{
		if ( vlen(self.velocity) > 400 )
		{
			ldmg = 100000000 + 10*random();
			T_Damage (other, self, self, ldmg);

		}
	}



	if (!checkbottom(self))
	{
		if (self.flags & FL_ONGROUND)
		{	// jump randomly to not get hung up
//dprint ("popjump\n");
	self.touch = SUB_Null;
	self.think = daikon_run1;
	self.movetype = MOVETYPE_STEP;
	self.nextthink = time + 0.1;

//			self.velocity_x = (random() - 0.5) * 600;
//			self.velocity_y = (random() - 0.5) * 600;
//			self.velocity_z = 200;
//			self.flags = self.flags - FL_ONGROUND;
		}
		return;	// not on ground yet
	}

	self.touch = SUB_Null;
	self.think = daikon_jump1;
	self.nextthink = time + 0.1;
};

void()	daikon_jump5;

void()	daikon_fly1		=[	$fly1,	daikon_fly2	] {
if(skill >= 3)
{
PoaRail ();Gishiki(-12);Gishiki(-8);Gishiki(-4);Gishiki(0);Gishiki(4);Gishiki(8);Gishiki(12);
}
};
void()	daikon_fly2		=[	$fly2,	daikon_fly3	] {
};
void()	daikon_fly3		=[	$fly3,	daikon_fly4	] {
if(skill == 3)
PoaRail ();
};
void()	daikon_fly4		=[	$fly4,	daikon_fly1	] {
self.cnt = self.cnt + 1;

if(random()<0.2)
PoaRail ();
if (self.cnt == 4)
{
//dprint ("spawn hop\n");
daikon_jump5 ();
}
};

void()	daikon_jump1		=[	$jump1,	daikon_jump2		] {ai_face();};
void()	daikon_jump2		=[	$jump2,	daikon_jump3		] {ai_face();MdFireGrenade();};
void()	daikon_jump3		=[	$jump3, daikon_jump4		] {ai_face();};
void()	daikon_jump4		=[	$jump4,	daikon_jump5		] {ai_face();Gishiki(-12);Gishiki(-8);Gishiki(-4);Gishiki(0);Gishiki(4);Gishiki(8);Gishiki(12);};
void()	daikon_jump5		=[	$jump5, daikon_jump6		]
{
 	if (skill==4)
    {
    if(random()<0.7)
    {
    sound (self, CHAN_WEAPON, "daikon/amai.wav", 1, ATTN_NORM);
    self.movetype = MOVETYPE_BOUNCE;
	self.touch = daikon_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 1000 + '0 0 200';
	self.velocity_z = self.velocity_z + random()*0;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;
    }
    else
    {
    self.movetype = MOVETYPE_BOUNCE;
	self.touch = daikon_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 70 + '0 0 600';
	self.velocity_z = self.velocity_z + random()*0;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;
    }
    }
    else if(random()>0.1)
    {
     self.movetype = MOVETYPE_BOUNCE;
	self.touch = daikon_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 70 + '0 0 600';
	self.velocity_z = self.velocity_z + random()*0;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;
    }
    else
    {
    sound (self, CHAN_WEAPON, "daikon/amai.wav", 1, ATTN_NORM);
    self.movetype = MOVETYPE_BOUNCE;
	self.touch = daikon_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 1000 + '0 0 200';
	self.velocity_z = self.velocity_z + random()*0;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;
    }
if(self.health < 300)
{
 sound (self, CHAN_WEAPON, "daikon/amai.wav", 1, ATTN_NORM);
    self.movetype = MOVETYPE_BOUNCE;
	self.touch = daikon_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 1000 + '0 0 200';
	self.velocity_z = self.velocity_z + random()*0;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;

}
};
void()	daikon_jump6	=[	$jump6,daikon_fly1	] {};



//=============================================================================

void()	daikon_die1	=[	$exp,		daikon_die2	] {
self.takedamage = DAMAGE_NO;
};
void()	daikon_die2	=[	$exp,		daikon_run1	]
{
	T_RadiusDamage (self, self, 500, world);

	sound (self, CHAN_VOICE, "daikon/death1.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LAVASPLASH);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

//=============================================================================


/*QUAKED monster_tarbaby (1 0 0) (-16 -16 -24) (16 16 24) Ambush
*/
void() monster_daikon =
{
	if (deathmatch || !QX_DAIKON)	// QuadEXQ v0.3: daikon left out for now
	{
		remove(self);
		return;
	}
	precache_model ("progs/daikon.mdl");
   	precache_model ("progs/mdaikon.mdl");
   	precache_model ("progs/gishiki.mdl");
     	precache_model ("progs/sgrenade.mdl");
	precache_sound ("daikon/poax.wav");
	precache_sound ("daikon/poarail.wav");
	precache_sound ("daikon/poa.wav");
   	precache_sound ("daikon/amai.wav");
    	precache_sound ("daikon/gishiki.wav");
	precache_sound ("daikon/death1.wav");
	precache_sound ("daikon/koredemo.wav");
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/daikon.mdl");



    setsize (self, '-16 -16 -24', '16 16 40');

	if(skill<=3)
	self.health = 6666;
	else
	self.health =16666;

	self.th_stand = daikon_stand1;
	self.th_walk = daikon_walk1;
	self.th_run = daikon_run1;
	self.th_missile = daikon_jump1;
	self.th_melee = daikon_jump1;
	self.th_die = daikon_die1;

	walkmonster_start ();
};

