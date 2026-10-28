/*
==============================================================================
MD

==============================================================================
*/

$cd id1/models/bdaikon
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
void() bPoaRail;
void(float offset) bGishiki =
{
	local	vector	offang;
	local	vector	org, vec;
	
   if( vlen( self.origin - self.enemy.origin ) <= 300 )		
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
if(self.health < 200) 
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
void()	bdaikon_stand1	=[	$walk1,		bdaikon_stand1	] {ai_stand();};

void()	bdaikon_hang1		=[	$walk1,		bdaikon_hang1	] {ai_stand();};

void()	bdaikon_walk1	=[	$walk1,		bdaikon_walk4	] {ai_turn();};
void()	bdaikon_walk4	=[	$walk4,		bdaikon_walk5	] {ai_turn();};
void()	bdaikon_walk5	=[	$walk5,		bdaikon_walk6	] {ai_turn();};
void()	bdaikon_walk6	=[	$walk6,		bdaikon_walk7	] {ai_turn();};
void()	bdaikon_walk7	=[	$walk7,		bdaikon_walk8	] {ai_turn();};
void()	bdaikon_walk8	=[	$walk8,		bdaikon_walk9	] {ai_turn();};
void()	bdaikon_walk9	=[	$walk9,		bdaikon_walk10	] {ai_turn();};
void()	bdaikon_walk10	=[	$walk10,		bdaikon_walk11	] {ai_turn();};
void()	bdaikon_walk11	=[	$walk11,		bdaikon_walk12	] {ai_walk(2);};
void()	bdaikon_walk12	=[	$walk12,		bdaikon_walk13	] {ai_walk(2);};
void()	bdaikon_walk13	=[	$walk13,		bdaikon_walk14	] {ai_walk(2);};
void()	bdaikon_walk14	=[	$walk14,		bdaikon_walk15	] {ai_walk(2);};
void()	bdaikon_walk15	=[	$walk15,		bdaikon_walk16	] {ai_walk(2);};
void()	bdaikon_walk16	=[	$walk16,		bdaikon_walk17	] {ai_walk(2);};
void()	bdaikon_walk17	=[	$walk17,		bdaikon_walk18	] {ai_walk(2);};
void()	bdaikon_walk18	=[	$walk18,		bdaikon_walk19	] {ai_walk(2);};
void()	bdaikon_walk19	=[	$walk19,		bdaikon_walk20	] {ai_walk(2);};
void()	bdaikon_walk20	=[	$walk20,		bdaikon_walk21	] {ai_walk(2);};
void()	bdaikon_walk21	=[	$walk21,		bdaikon_walk22	] {ai_walk(2);};
void()	bdaikon_walk22	=[	$walk22,		bdaikon_walk23	] {ai_walk(2);};
void()	bdaikon_walk23	=[	$walk23,		bdaikon_walk24	] {ai_walk(2);};
void()	bdaikon_walk24	=[	$walk24,		bdaikon_walk25	] {ai_walk(2);};
void()	bdaikon_walk25	=[	$walk25,		bdaikon_jump1	] {ai_walk(2);bPoaRail();};

void()	bdaikon_run1	=[	$run1,		bdaikon_run2	] {ai_face();bGishiki(-12);};
void()	bdaikon_run2	=[	$run2,		bdaikon_run3	] {ai_face();bGishiki(-8);};
void()	bdaikon_run3	=[	$run3,		bdaikon_run4	] {ai_face();bGishiki(-4);};
void()	bdaikon_run4	=[	$run4,		bdaikon_run5 ]{ai_face();bGishiki(0);};
void()	bdaikon_run5	=[	$run5,		bdaikon_run6	] {ai_face();bGishiki(4);};
void()	bdaikon_run6	=[	$run6,		bdaikon_run7	] {ai_face();bGishiki(8);};
void()	bdaikon_run7	=[	$run7,		bdaikon_run8	] {ai_face();bGishiki(12);};
void()	bdaikon_run8	=[	$run8,		bdaikon_run9	] {ai_face();};
void()	bdaikon_run9	=[	$run9,		bdaikon_run10	] {ai_face();};
void()	bdaikon_run10	=[	$run10,		bdaikon_run11	] {ai_face();};
void()	bdaikon_run11	=[	$run11,		bdaikon_run12	] {ai_run(2);};
void()	bdaikon_run12	=[	$run12,		bdaikon_run13	] {ai_run(2);};
void()	bdaikon_run13	=[	$run13,		bdaikon_run14	] {ai_run(2);};
void()	bdaikon_run14	=[	$run14,		bdaikon_run15	] {ai_run(2);};
void()	bdaikon_run15	=[	$run15,		bdaikon_run16	] {ai_run(2);};
void()	bdaikon_run16	=[	$run16,		bdaikon_run17	] {ai_run(2);};
void()	bdaikon_run17	=[	$run17,		bdaikon_run18	] {ai_run(2);bGishiki(12);};
void()	bdaikon_run18	=[	$run18,		bdaikon_run19	] {ai_run(2);bPoaRail();bGishiki(8);};
void()	bdaikon_run19	=[	$run19,		bdaikon_run20	] {ai_run(2);bGishiki(4);};
void()	bdaikon_run20	=[	$run20,		bdaikon_run21	] {ai_run(2);bPoaRail();bGishiki(0);};
void()	bdaikon_run21	=[	$run21,		bdaikon_run22	] {ai_run(2);bGishiki(-4);};
void()	bdaikon_run22	=[	$run22,		bdaikon_run23	] {ai_run(2);bGishiki(-8);};
void()	bdaikon_run23	=[	$run23,		bdaikon_run24	] {ai_run(2);bPoaRail();bGishiki(-12);};
void()	bdaikon_run24	=[	$run24,		bdaikon_run25	] {ai_run(2);bPoaRail();};
void()	bdaikon_run25	=[	$run25,		bdaikon_run1	] {ai_run(2);bPoaRail();};


//============================================================================


void() BdGrenadeExplode =
{
	T_RadiusDamage (self, self.owner, 80, self.owner);
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
void() BdFireGrenade =
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
	missile.think = BdGrenadeExplode;

	setmodel (missile, "progs/sgrenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
}
};
void() bRailFly =			//ロケット飛行中の処理
{
	local	vector	dir;		//ローカルvectorオブジェクトdirの宣言
	dir = normalize( self.enemy.origin - self.origin ); //ロケットから見た敵の方向の単位ベクトル(長さ1)を得る
    
   sound (self, CHAN_WEAPON, "daikon/poarail.wav", 1, ATTN_NORM);	
   if(skill == 3)
	self.velocity = dir * 2000;		//ロケットの飛行スピードを指定
	else
    self.velocity = dir * 1200;		
    
     self.angles = vectoangles(dir);		//ロケットの向き(グラフィックの)を指定
	self.nextthink = time + 110 ;		//次回thinkで指定された関数を呼び出すタイミングを指定
	self.think =RailFly;			//nextthinkで指定したタイミングで呼び出す関数名
};
void() bRailTouch =		
{
	local float	damg;		

	if (other == self.owner)	
		return;

	if (pointcontents(self.origin) == CONTENT_SKY)	
	{
		remove(self);
		return;
	}

	damg = 30 + random()*20;	//random()は0.0～1.0間の乱数を返す、ロケットのダメージは50に
						//乱数と10の積を加えたものである
	
	if (other.health)					//接触した相手に体力がある場合
	{
		if (other.classname == "monster_shambler")	//接触した相手がシャンブラーだった場合
			damg = damg * 500;				//ダメージ半減
		T_Damage (other, self, self.owner, damg );	//接触した相手にダメージを与える
	}

	// entity other(接触した相手)に対し、爆風による特定空間内ダメージ処理を行わない
	// 既にロケットが接触した際、ダメージを与えているからである
	T_RadiusDamage (self, self.owner, 40, other);	//特定空間内ダメージ処理(無視する相手にotherを指定)

	self.origin = self.origin - 8*normalize(self.velocity);		//爆発の表示位置を接触地点より8だけ後退

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);	//テンポラリentityのネットワークメッセージ送信
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);	//ここで爆発音を指定している
	WriteCoord (MSG_BROADCAST, self.origin_x);	//爆発音発生地点を指定
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();		//ロケットは爆発へ変身
};
void() bPoaRail =
{
	local	entity missile, mpuff,rocket,en;
	local	vector	dir;

if( vlen( self.origin - self.enemy.origin ) > 600 )		
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
		rocket.velocity = dir * 10;		//ロケットの飛行スピードを指定
		rocket.angles = vectoangles(rocket.velocity);		//ロケットの向き(グラフィックの)を指定
	
		rocket.touch = bRailTouch;	//ロケットが何者かに接触した場合に呼び出す関数名
	
	//ロケットの詳細
		rocket.nextthink = time + 1.5 ;		//次回thinkで指定された関数を呼び出すタイミングを指定
		rocket.think =  bRailFly;		//nextthinkで指定したタイミングで呼び出す関数名

		setmodel (rocket, "progs/mdaikon.mdl");		//ロケットのmodel指定
		setsize (rocket, '0 0 0', '0 0 0');		//ロケットのサイズ指定
		setorigin (rocket, self.origin + v_forward*8 + '0 0 16');
					//ロケット発射位置はGRUNT自身の位置よりも少し前方
	  }
  };

void()	bdaikon_jump1;

void()	bdaikon_JumpTouch =
{
	local	float	ldmg;

	if (other.takedamage && other.classname != self.classname)
	{
		if ( vlen(self.velocity) > 50 )
		{
			ldmg = 50 + 80*random();
			T_Damage (other, self, self, ldmg);	
			
		}
	}
	


	if (!checkbottom(self))
	{
		if (self.flags & FL_ONGROUND)
		{	// jump randomly to not get hung up
//dprint ("popjump\n");
	self.touch = SUB_Null;
	self.think = bdaikon_run1;
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
	self.think = bdaikon_jump1;
	self.nextthink = time + 0.1;
};

void()	bdaikon_jump5;

void()	bdaikon_fly1		=[	$fly1,	bdaikon_fly2	] {
if(skill >= 3)
{
bPoaRail ();bGishiki(-12);bGishiki(-8);bGishiki(-4);bGishiki(0);bGishiki(4);bGishiki(8);bGishiki(12);
}
};
void()	bdaikon_fly2		=[	$fly2,	bdaikon_fly3	] {bPoaRail ();
};
void()	bdaikon_fly3		=[	$fly3,	bdaikon_fly4	] {
if(skill == 3)
bPoaRail ();
};
void()	bdaikon_fly4		=[	$fly4,	bdaikon_fly1	] {
self.cnt = self.cnt + 1;

if(random()<0.1)
bPoaRail ();
if (self.cnt == 4)
{
//dprint ("spawn hop\n");
daikon_jump5 ();
}
};

void()	bdaikon_jump1		=[	$jump1,	bdaikon_jump2		] {ai_face();};
void()	bdaikon_jump2		=[	$jump2,	bdaikon_jump3		] {ai_face();BdFireGrenade();};
void()	bdaikon_jump3		=[	$jump3, bdaikon_jump4		] {ai_face();bPoaRail ();};
void()	bdaikon_jump4		=[	$jump4,	bdaikon_jump5		] {ai_face();bGishiki(-12);bGishiki(-8);bGishiki(-4);bGishiki(0);bGishiki(4);bGishiki(8);bGishiki(12);};
void()	bdaikon_jump5		=[	$jump5, bdaikon_jump6		]
{	
 	if (skill==4)
    {
    if(random()<0.7)
    {
    sound (self, CHAN_WEAPON, "daikon/amai.wav", 1, ATTN_NORM);
    self.movetype = MOVETYPE_BOUNCE;
	self.touch = bdaikon_JumpTouch;
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
	self.touch = bdaikon_JumpTouch;
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
	self.touch = bdaikon_JumpTouch;
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
	self.touch = bdaikon_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 1000 + '0 0 200';
	self.velocity_z = self.velocity_z + random()*0;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;
    }
if(self.health < 50) 
{ 
 sound (self, CHAN_WEAPON, "daikon/amai.wav", 1, ATTN_NORM);
    self.movetype = MOVETYPE_BOUNCE;
	self.touch = bdaikon_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 1000 + '0 0 200';
	self.velocity_z = self.velocity_z + random()*0;
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;

}
};
void()	bdaikon_jump6	=[	$jump6,bdaikon_fly1	] {};



//=============================================================================

void()	bdaikon_die1	=[	$exp,		bdaikon_die2	] {
self.takedamage = DAMAGE_NO;
};
void()	bdaikon_die2	=[	$exp,		bdaikon_run1	] 
{
	T_RadiusDamage (self, self, 200, world);

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
void() monster_bdaikon =
{
	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model ("progs/bdaikon.mdl");
    precache_model ("progs/mdaikon.mdl");
    precache_model ("progs/gishiki.mdl");
    precache_model ("progs/sgrenade.mdl");
	precache_sound ("daikon/poax.wav");
	precache_sound ("daikon/poarail.wav");
	precache_sound ("daikon/poa.wav");
    	precache_sound ("daikon/amai.wav");
	precache_sound ("daikon/gishiki.wav");
	precache_sound ("daikon/death1.wav");
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/bdaikon.mdl");
    
	

    setsize (self, '-16 -16 -24', '16 16 40');
	self.health = 300;

	self.th_stand = bdaikon_stand1;
	self.th_walk = bdaikon_walk1;
	self.th_run = bdaikon_run1;
	self.th_missile = bdaikon_jump1;
	self.th_melee = bdaikon_jump1;
	self.th_die = bdaikon_die1;
	
	walkmonster_start ();
};

