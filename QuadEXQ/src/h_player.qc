/*
==============================================================================

Player head

==============================================================================
*/

$cd /raid/quake/id1/models/h_player
$origin 0 0 24
$base base              

//$skin skin
$skin base
$skin skin2
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

void()  hplyer_stand1    =[      $walk1,         hplyer_stand1    ] {ai_stand();};

void()  hplyer_hang1             =[      $walk1,         hplyer_hang1     ] {ai_stand();};

void()  hplyer_walk1     =[      $walk1,         hplyer_walk2     ] {ai_turn();};
void()  hplyer_walk2     =[      $walk2,         hplyer_walk3     ] {ai_turn();};
void()  hplyer_walk3     =[      $walk3,         hplyer_walk4     ] {ai_turn();};
void()  hplyer_walk4     =[      $walk4,         hplyer_walk5     ] {ai_turn();};
void()  hplyer_walk5     =[      $walk5,         hplyer_walk6     ] {ai_turn();};
void()  hplyer_walk6     =[      $walk6,         hplyer_walk7     ] {ai_turn();};
void()  hplyer_walk7     =[      $walk7,         hplyer_walk8     ] {ai_turn();};
void()  hplyer_walk8     =[      $walk8,         hplyer_walk9     ] {ai_turn();};
void()  hplyer_walk9     =[      $walk9,         hplyer_walk10    ] {ai_turn();};
void()  hplyer_walk10    =[      $walk10,                hplyer_walk11    ] {ai_turn();};
void()  hplyer_walk11    =[      $walk11,                hplyer_walk12    ] {ai_walk(2);};
void()  hplyer_walk12    =[      $walk12,                hplyer_walk13    ] {ai_walk(2);};
void()  hplyer_walk13    =[      $walk13,                hplyer_walk14    ] {ai_walk(2);};
void()  hplyer_walk14    =[      $walk14,                hplyer_walk15    ] {ai_walk(2);};
void()  hplyer_walk15    =[      $walk15,                hplyer_walk16    ] {ai_walk(2);};
void()  hplyer_walk16    =[      $walk16,                hplyer_walk17    ] {ai_walk(2);};
void()  hplyer_walk17    =[      $walk17,                hplyer_walk18    ] {ai_walk(2);};
void()  hplyer_walk18    =[      $walk18,                hplyer_walk19    ] {ai_walk(2);};
void()  hplyer_walk19    =[      $walk19,                hplyer_walk20    ] {ai_walk(2);};
void()  hplyer_walk20    =[      $walk20,                hplyer_walk21    ] {ai_walk(2);};
void()  hplyer_walk21    =[      $walk21,                hplyer_walk22    ] {ai_walk(2);};
void()  hplyer_walk22    =[      $walk22,                hplyer_walk23    ] {ai_walk(2);};
void()  hplyer_walk23    =[      $walk23,                hplyer_walk24    ] {ai_walk(2);};
void()  hplyer_walk24    =[      $walk24,                hplyer_walk25    ] {ai_walk(2);};
void()  hplyer_walk25    =[      $walk25,                hplyer_walk1     ] {ai_walk(2);};

void()  hplyer_run1      =[      $run1,          hplyer_run2      ] {ai_face();};
void()  hplyer_run2      =[      $run2,          hplyer_run3      ] {ai_face();};
void()  hplyer_run3      =[      $run3,          hplyer_run4      ] {ai_face();};
void()  hplyer_run4      =[      $run4,          hplyer_run5      ] {ai_face();};
void()  hplyer_run5      =[      $run5,          hplyer_run6      ] {ai_face();};
void()  hplyer_run6      =[      $run6,          hplyer_run7      ] {ai_face();};
void()  hplyer_run7      =[      $run7,          hplyer_run8      ] {ai_face();};
void()  hplyer_run8      =[      $run8,          hplyer_run9      ] {ai_face();};
void()  hplyer_run9      =[      $run9,          hplyer_run10     ] {ai_face();};
void()  hplyer_run10     =[      $run10,         hplyer_run11     ] {ai_face();};
void()  hplyer_run11     =[      $run11,         hplyer_run12     ] {ai_run(2);};
void()  hplyer_run12     =[      $run12,         hplyer_run13     ] {ai_run(2);};
void()  hplyer_run13     =[      $run13,         hplyer_run14     ] {ai_run(2);};
void()  hplyer_run14     =[      $run14,         hplyer_run15     ] {ai_run(2);};
void()  hplyer_run15     =[      $run15,         hplyer_run16     ] {ai_run(2);};
void()  hplyer_run16     =[      $run16,         hplyer_run17     ] {ai_run(2);};
void()  hplyer_run17     =[      $run17,         hplyer_run18     ] {ai_run(2);};
void()  hplyer_run18     =[      $run18,         hplyer_run19     ] {ai_run(2);};
void()  hplyer_run19     =[      $run19,         hplyer_run20     ] {ai_run(2);};
void()  hplyer_run20     =[      $run20,         hplyer_run21     ] {ai_run(2);};
void()  hplyer_run21     =[      $run21,         hplyer_run22     ] {ai_run(2);};
void()  hplyer_run22     =[      $run22,         hplyer_run23     ] {ai_run(2);};
void()  hplyer_run23     =[      $run23,         hplyer_run24     ] {ai_run(2);};
void()  hplyer_run24     =[      $run24,         hplyer_run25     ] {ai_run(2);};
void()  hplyer_run25     =[      $run25,         hplyer_run1      ] {ai_run(2);};


//============================================================================


//void()  hplyer_jump1;

void()  hplyer_JumpTouch =
{
	local   float   ldmg;

	if (other.takedamage && other.classname != self.classname)
	{
		if ( vlen(self.velocity) > 400 )
		{
			ldmg = 10 + 10*random();
			T_RadiusDamage (self, self.owner, 200, other);
		}
	}
	
		return; // not on ground yet
};

void()  hplyer_jump5;

void()  hplyer_fly1              =[      $fly1,  hplyer_fly2      ] {};
void()  hplyer_fly2              =[      $fly2,  hplyer_fly3      ] {};
void()  hplyer_fly3              =[      $fly3,  hplyer_fly4      ] {};
void()  hplyer_fly4              =[      $fly4,  hplyer_fly1      ] {
self.cnt = self.cnt + 1;
if (self.cnt == 4)
{
//dprint ("spawn hop\n");
hplyer_jump5 ();
}
};

void()  hplyer_jump5             =[      $jump5, hplyer_jump6             ] 
{
	ai_face();
	self.movetype = MOVETYPE_BOUNCE;
	self.touch = hplyer_JumpTouch;
	makevectors (self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * 400 + '0 0 200';
	self.velocity_z = self.velocity_z + random()*150;
	self.avelocity = '3000 1000 2000';

	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;
	self.cnt = 0;
};
void()  hplyer_jump6     =[      $jump6,hplyer_fly1       ] {};



//=============================================================================

void()  hplyer_die1      =[      $exp,           hplyer_die2      ] {
self.takedamage = DAMAGE_NO;
};
void()  hplyer_die2      =[      $exp,           hplyer_run1      ] 
{
	T_RadiusDamage (self, self, 200, world);

	sound (self, CHAN_VOICE, "daikon/amai.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_TAREXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	
	BecomeExplosion ();
};

//=============================================================================


/*QUAKED monster_tarbaby (1 0 0) (-16 -16 -24) (16 16 24) Ambush Blue Green Spots
The Spawn (and hellspawn)

The spawn type is random by default.
If you want a specific type, select "Blue", "Green", or "Spots".
*/
void() monster_hplayer =
{
    local float     myRand;
    local float     skillLevel;

	if (deathmatch)
	{
		remove(self);
		return;
	}
	precache_model2 ("progs/h_player.mdl");

	precache_sound2 ("blob/death1.wav");
	precache_sound2 ("blob/hit1.wav");
	precache_sound2 ("daikon/amai.wav");
	precache_sound2 ("player/death1.wav");
	precache_sound2 ("blob/mytosis.wav");

	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	setmodel (self, "progs/h_player.mdl");

	setsize (self, '-2 -2 -3', '2 2 3');
	self.health = 1;

	self.th_stand = hplyer_stand1;
	self.th_walk = hplyer_walk1;
	self.th_run = hplyer_run1;
	self.th_missile = hplyer_jump5;
	self.th_melee = hplyer_jump5;
	self.th_die = hplyer_die1;

	walkmonster_start ();
};

