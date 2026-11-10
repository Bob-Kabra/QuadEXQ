// ==========================================================================
//                                CYBERDEMON
//
// Original code and models by Marc Fontaine
// Modified for the Ultimate Weapons Mod by Andy Brennan
// ==========================================================================

$origin 0 0 64
$base base     
$skin skin

$frame stand1 stand2 stand3 stand4 stand5 stand6

$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7

$frame shoot1 shoot2 shoot3 shoot4 shoot5 shoot6 shoot7 shoot8

//=============================================================================
/*
void() hknightMissileTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner

	if (other.classname == "monster_zombie")
		T_Damage (other, self, self, 110);	
	T_RadiusDamage (self, self.owner, 50, world);
	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	self.velocity = '0 0 0';
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
*/
void() qogre_MissileTouch;
void() hknightMissile =
{
	local	entity 	missile;
	local	vector	dir;
	local	float	dist, flytime;

	dir = normalize((self.enemy.origin + '0 0 10') - self.origin);
	dist = vlen (self.enemy.origin - self.origin);
	flytime = dist * 0.002;
	if (flytime < 0.1)
		flytime = 0.1;

	self.effects = self.effects | EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "weapons/rail.wav", 1, ATTN_NORM);	// QuadEXQ: was hknight/rail.wav (missing)

	missile = spawn ();
	missile.owner = self;

	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	setmodel (missile, "progs/hrail.mdl");

	setsize (missile, '0 0 0', '0 0 0');		

	missile.origin = self.origin + '0 0 10';
	missile.velocity = dir * 2000;
	
	// QuadEXQ: there was no think here, so a rail that missed hit a NULL
	// function when nextthink came round: "PR_ExecuteProgram: NULL function"
	missile.think = SUB_Remove;
	missile.nextthink = time + 3;
	missile.enemy = self.enemy;
	missile.touch = qogre_MissileTouch;
};

void() CyberFireRLG =
{
 local vector org,dir;
local	entity	en;
 		
self.effects = self.effects | EF_MUZZLEFLASH;
org = self.origin + '0 0 16';
en = self.enemy;
	sound (self, CHAN_WEAPON, "weapons/lstart.wav", 1, ATTN_NORM);
	dir = en.origin - en.velocity*0.2;
	
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
   
	LightningDamage (org, trace_endpos, self, 120);
  
};


void(float xco, float yco, float zco) SpawnExplosion;

/*
=====================
CyberDemonFireMissile
=====================
*/
void() CyberDemonFireMissile =
{
   local entity missile;
   local vector org;
   
   self.effects = self.effects | EF_MUZZLEFLASH;

   sound (self, CHAN_WEAPON, "cyber/cybfire.wav", 1, ATTN_NORM);

   missile = spawn ();
   missile.owner = self;
   missile.movetype = MOVETYPE_FLYMISSILE;
   missile.solid = SOLID_BBOX;
      
// set missile speed 

   makevectors (self.angles);

   org = self.origin + '0 0 30' + (v_right * -22);
   missile.velocity = normalize((self.enemy.origin + '0 0 20') - org);
   missile.velocity = missile.velocity * 600;

   missile.angles = vectoangles(missile.velocity);
   
   missile.touch = T_MissileTouch;
   
// set missile duration
   missile.nextthink = time + 5;
   missile.think = SUB_Remove;

   setmodel  (missile, "progs/cmissile.mdl");
   setsize   (missile, '0 0 0', '0 0 0');
   setorigin (missile, self.origin + '0 0 30' + (v_right * -22) );
};

void(float offset) CyberMissile =
{ 
    local   vector  offang; 
    local   vector  org, vec; 
        self.effects = self.effects | EF_MUZZLEFLASH;
	offang = vectoangles (self.enemy.origin - self.origin);
	offang_y = offang_y + offset * 6;
	
	makevectors (offang);

	org = self.origin - 30*normalize(self.velocity);

// set missile speed
	vec = normalize (v_forward);
	vec_z = 0 - vec_z + (random() - 0.5)*0.1;
	
	launch_spike (org, vec);
	newmis.classname = "LaunchNails";
	setmodel (newmis, "progs/missile.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	newmis.velocity = vec*1000;
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

};

void() CyberhMissileTouch;
void() CyberhHome;
void() CyberhMissile =
{
	local	entity 	missile;
	local	float	dist, flytime;
    local	vector	offang;
	local	vector	org, vec;
	
	offang = vectoangles (self.enemy.origin - self.origin);
	offang_y = offang_y ;

	
	makevectors (offang);

	org = self.origin + self.mins + self.size*0.5 + v_forward * 20;


	dist = vlen (self.enemy.origin - self.origin);
	flytime = dist * 0.002;
	if (flytime < 0.1)
		flytime = 0.1;

	self.effects = self.effects | EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "cyber/cyjump.wav", 1, ATTN_NORM);

	missile = spawn ();
	missile.owner = self;

       vec = normalize (v_forward);
	vec_z = 0 - vec_z + (random() - 0.5)*0.1;


	missile.solid = SOLID_BBOX;
	missile.movetype = MOVETYPE_FLYMISSILE;
	setmodel (missile, "progs/w_ball.mdl");

	setsize (missile, '0 0 0', '0 0 0');		

	missile.origin = self.origin + '0 0 10';
	missile.velocity = vec * 200;
	missile.avelocity = '300 300 300';
	missile.nextthink = flytime + time;
	missile.think = CyberhHome;
	missile.ltime = time + 12;		// QuadEXQ: homing balls don't fly around forever
	missile.enemy = self.enemy;
	missile.touch = CyberhMissileTouch;
};

void() CyberhHome =
{
	local vector	dir, vtemp;
	vtemp = self.enemy.origin + '0 0 10';
	if (self.enemy.health < 1 || time > self.ltime)
	{
		remove(self);
		return;
	}
	dir = normalize(vtemp - self.origin);
	if (skill == 3)
		self.velocity = dir * 2000;
	else
		self.velocity = dir * 1500;
	self.nextthink = time + 0.5;		// QuadEXQ: steer twice a second (was once, then 20 s)
	self.think = CyberhHome;	
};

void() CyberhMissileTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner

	if (other.classname == "monster_zombie")
		T_Damage (other, self, self, 110);	
	T_RadiusDamage (self, self.owner, 35, world);
	

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


// ============================================================================
// QuadEXQ: the Cyberdemon, reworked as the CYBER DELTA -- THE ENDER's boss
// (ender.bsp only: anywhere else monster_cyber turns into a BFG fiend)
//
//  * moves like Delta Team: runs fast and circle-strafes, even while shooting
//  * three weapons, a bullet storm to show off the QuadEXQ engine: 64 QUTF
//    Ogre rockets in fans, 256 four-barrel chaingun bursts (twice the
//    Ogre's rate), 256 Mega Enforcer homing (drunk) rockets in swarms
//    (a quarter of it on other engines)
//  * no more sky-high jump: a jetpack instead -- up to QX_CY_JETS full
//    jumps in mid-air
//  * BFG dodge: a BFG ball coming its way -> it jumps (or jets) aside,
//    fires two rockets as it goes, and lobs an Ogre lava-ball grenade
//    when it lands (one time in five: four thunderbolts, 120 damage each,
//    then it stands frozen for QX_CY_STUN seconds)
//  * your BFG's lightning fries its jetpack for QX_CY_JETLOCK seconds
//  * now and then the jet knight's rocket-propelled body slam (QX_JetStart)
//  * up close: a punch, QX_CY_PUNCH damage
// ============================================================================

float	QX_CY_RUN		= 24;	// run speed per frame (Delta Team: 24; was 12-15)
float	QX_CY_STRAFE	= 14;	// sideways per frame while running / shooting
float	QX_CY_JETS		= 3;	// jetpack jumps in mid-air
float	QX_CY_JUMP		= 420;	// a jump / jet: upward speed
float	QX_CY_SIDE		= 450;	// a dodge: sideways speed
float	QX_CY_DODGE_GAP	= 0.6;	// seconds between BFG dodges
float	QX_CY_DODGE_CHANCE = 0.8;	// how often it sees a BFG ball in time
// saturation fire
// (on the QuadEXQ engine; other engines get a quarter, see CyberMass --
//  the full storm is more than their packets and entity lists can carry)
float	QX_CY_ROCKETS	= 64;	// QUTF Ogre rockets: a fan of 4 a frame
float	QX_CY_CG_SHOTS	= 256;	// chaingun bursts at twice the Ogre's rate (0.05 s),
float	QX_CY_CG_BARRELS = 4;	//   each this many tracers (one of them aimed: 10 damage)
float	QX_CY_DRUNK		= 256;	// homing rockets: 8 a frame
float	QX_CY_ROCK_FAN	= 4;
float	QX_CY_DRUNK_FAN	= 8;
float	QX_CY_BOLTS		= 4;	// thunderbolts, one a frame
float	QX_CY_PUNCH		= 70;	// melee: a punch when you get close
float	QX_CY_PUNCH_RANGE	= 110;	// how close is close
float	QX_CY_BOLT_CHANCE	= 0.2;	// landing after a BFG dodge: the thunderbolts instead of the lava grenade

float() QX_F;
void() FireDrunkMissile;
void() DrunkExplode;
void() drunkthink;
void() QOgreFireTGrenade;
void() QOgreGrenadeExplode;
void() QOgreGrenadeTouch;

void() cyber_run1;
void() cyber_punch1;

// frozen for a moment after its thunderbolts: no moving, no dodging
void() cyber_stun =[ $stand1, cyber_stun ]
{
	if (time > self.qx_cy_stun)
		self.think = cyber_run1;
};

// all the extra models and sounds (shambler.qc calls this too: it can turn
// into a Cyberdemon after the map has loaded)
void() cyber_precache =
{
	precache_model ("progs/missile.mdl");
	precache_model ("progs/lavaball.mdl");
	precache_model ("progs/memissil.mdl");
	precache_model ("progs/s_explod.spr");
	precache_sound ("weapons/sgun1.wav");		// QUTF Ogre rocket
	precache_sound ("weapons/cg_strt.wav");		// chaingun
	precache_sound ("weapons/cgshot2.wav");
	precache_sound ("me/me_fire2.wav");			// drunk rocket
	precache_sound ("weapons/grenade.wav");		// lava-ball grenade
	precache_sound ("weapons/r_exp3.wav");
	precache_sound ("weapons/rocket1i.wav");	// jetpack
	precache_sound ("knight/ksight.wav");		// the jet knight's body slam (QX_JetStart / QX_JetTouch)
	precache_sound ("knight/sword2.wav");
	precache_sound ("player/land2.wav");
	precache_sound ("shambler/smack.wav");		// the punch
	precache_model ("progs/tracer.mdl");
};

// the bullet storm, sized for the engine: everything on the QuadEXQ engine,
// a quarter elsewhere (a packet overflow / too many entities there)
float() CyberMass =
{
	if (qx_newengine)
		return 1;
	return 0.25;
};

// the gun arm
vector() CyberMuzzle =
{
	makevectors (self.angles);
	return self.origin + '0 0 30' + v_right * -22;
};

// QUTF Ogre rocket (qogre_MissileTouch: 40 +- 60 damage), from the arm
void(float spread) CyberQRocket =
{
	local entity en, rocket;
	local vector dir, org;

	en = self.enemy;
	org = CyberMuzzle ();
	dir = normalize (en.origin - en.velocity * 0.2 - org);
	if (spread)
	{
		dir = vectoangles (dir);
		dir_x = 0 - dir_x;
		dir_y = dir_y + spread;
		makevectors (dir);
		dir = v_forward;
	}
	self.effects = self.effects | EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	rocket = spawn ();
	rocket.owner = self;
	rocket.movetype = MOVETYPE_FLYMISSILE;
	rocket.solid = SOLID_BBOX;
	rocket.enemy = en;
	rocket.classname = "main";
	rocket.velocity = dir * 500;
	rocket.angles = vectoangles (rocket.velocity);
	rocket.touch = qogre_MissileTouch;
	rocket.qx_nodeflect = self.qx_ender_boss;	// the boss's rockets can't be swatted back
	rocket.nextthink = time + 6;
	rocket.think = SUB_Remove;
	setmodel (rocket, "progs/missile.mdl");
	setsize (rocket, '0 0 0', '0 0 0');
	setorigin (rocket, org);
};

// Ogre chaingun round, from the arm (aims behind a moving target, 10 damage)
// a chaingun tracer: SOLID_TRIGGER so a spray of them from one muzzle
// doesn't collide with itself
void(vector org, vector dir) CyberTracer =
{
	local entity t;

	t = spawn ();
	t.owner = self;
	t.solid = SOLID_TRIGGER;
	t.movetype = MOVETYPE_FLYMISSILE;
	t.effects = EF_DIMLIGHT;
	t.touch = Tracer_Remove;
	t.velocity = dir * 2000;
	t.angles = vectoangles (t.velocity);
	t.nextthink = time + 1.5;
	t.think = SUB_Remove;
	setmodel (t, "progs/tracer.mdl");
	setsize (t, '0 0 0', '0 0 0');
	setorigin (t, org);
};

void() CyberChaingun =
{
	local entity en;
	local vector dir, org, vel;
	local float n;

	en = self.enemy;
	org = CyberMuzzle ();
	self.effects = self.effects | EF_MUZZLEFLASH;
	sound (self, CHAN_WEAPON, "weapons/cgshot2.wav", 1, ATTN_NORM);

	dir = normalize (en.origin - en.velocity * 0.7 - org);
	CyberTracer (org, dir);
	n = floor (QX_CY_CG_BARRELS * CyberMass ()) - 1;
	while (n > 0)
	{	// the other barrels: tracers sprayed around the aim (looks, no damage)
		makevectors (vectoangles (dir));
		CyberTracer (org, normalize (dir + v_right * (random () - 0.5) * 0.25 + v_up * (random () - 0.5) * 0.18));
		n = n - 1;
	}
	traceline (org, org + dir * 2048, FALSE, self);
	vel = (dir + 2 * trace_plane_normal) * 200;
	if (trace_ent.takedamage)
		T_Damage (trace_ent, self, self, 10);
	CG_puff (trace_endpos - dir * 4, vel, 20, 0.3);
};

// Mega Enforcer drunk rocket, from the arm
void(float loud) CyberDrunk =
{
	local entity missile;
	local vector org;

	org = CyberMuzzle ();
	self.effects = self.effects | EF_MUZZLEFLASH;
	if (loud)
		sound (self, CHAN_WEAPON, "me/me_fire2.wav", 1, ATTN_NORM);

	missile = spawn ();
	missile.owner = self;
	missile.enemy = self.enemy;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_TRIGGER;	// (a swarm from one muzzle mustn't blow itself up)
	missile.velocity = normalize (self.enemy.origin - org) * (450 + random () * 50);
	makevectors (missile.velocity);
	missile.velocity = missile.velocity + v_up * (random () * 20 - 10) + v_right * (random () * 80 - 40);
	missile.angles = vectoangles (missile.velocity);
	missile.touch = DrunkExplode;
	missile.cnt = 1;
	missile.nextthink = time + 0.25;
	missile.think = drunkthink;
	setmodel (missile, "progs/memissil.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, org + v_right * (random () * 16 - 8) + v_up * (random () * 16 - 8));
};

// ---------------------------------------------------------------- movement

void() CyberJetPuff =
{
	sound (self, CHAN_BODY, "weapons/rocket1i.wav", 1, ATTN_NORM);
	particle (self.origin + '0 0 -20', '0 0 -120', 230, 40);
	particle (self.origin + '0 0 -20', '0 0 -80', 233, 30);
};

// one jump: on the ground a plain jump, in the air a jetpack jump (if any left)
float(vector side) CyberJump =
{
	if (self.flags & FL_ONGROUND)
	{
		self.qx_cy_jets = QX_CY_JETS;
		sound (self, CHAN_VOICE, "cyber/cyjump.wav", 1, ATTN_NORM);
	}
	else
	{
		if (self.qx_cy_jets < 1)
			return FALSE;
		if (time < self.qx_cy_jetlock)
			return FALSE;			// fried by your BFG's lightning
		self.qx_cy_jets = self.qx_cy_jets - 1;
		CyberJetPuff ();
	}
	self.origin_z = self.origin_z + 1;
	self.velocity = side;
	self.velocity_z = QX_CY_JUMP;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.qx_dodging = 1;			// (QX_AIHook stops the slide on landing)
	return TRUE;
};

// a BFG ball that will pass close to us?
float() CyberBFGThreat =
{
	local entity e;
	local vector to, v;
	local float d, miss;

	e = findradius (self.origin, 520);
	while (e)
	{
		if (e.classname == "b1")
		if (e.owner != self)
		{
			v = normalize (e.velocity);
			to = self.origin - e.origin;
			d = v * to;				// how far ahead of the ball we are
			if (d > 0)
			{
				miss = vlen (to - v * d);	// how close it passes
				if (miss < 90)
					return TRUE;
			}
		}
		e = e.chain;
	}
	return FALSE;
};

// called every run / attack frame
void() CyberAct =
{
	local vector a, side;
	local float yaw, s;

	if (self.health <= 0)
		return;

	// landed after a BFG dodge: the lava-ball grenade
	if (self.flags & FL_ONGROUND)
	{
		self.qx_cy_jets = QX_CY_JETS;
		if (self.qx_cy_lava)
		{
			self.qx_cy_lava = 0;
			if (self.enemy.health > 0)
			{
				ai_face ();
				if (random () < QX_CY_BOLT_CHANCE)
					self.qx_cy_bolts = QX_CY_BOLTS;	// now and then thunderbolts instead (120 damage each)
				else
					QOgreFireTGrenade ();
			}
		}
	}

	// too close: it drops whatever it is doing and punches
	if (self.think != cyber_punch1)
	if (self.qx_cy_bolts < 1)
	if (time > self.qx_cy_punch_next)
	if (self.enemy.health > 0)
	if (vlen (self.enemy.origin - self.origin) < QX_CY_PUNCH_RANGE)
	{
		self.qx_cy_punch_next = time + 1;
		self.think = cyber_punch1;
		self.nextthink = time + 0.05;
		return;
	}

	// thunderbolts still to fire, one a frame; after the last one it freezes
	if (self.qx_cy_bolts > 0)
	{
		self.qx_cy_bolts = self.qx_cy_bolts - 1;
		if (self.enemy.health > 0)
		{
			ai_face ();
			CyberFireRLG ();
		}
		if (self.qx_cy_bolts < 1)
		{
			self.qx_cy_stun = time + QX_CY_STUN;
			self.think = cyber_stun;
			self.nextthink = time + 0.1;
			return;
		}
	}

	// BFG dodge: aside (jump or jet), two rockets on the way
	if (time > self.qx_cy_dodge_next)
	if (CyberBFGThreat ())
	{
		self.qx_cy_dodge_next = time + QX_CY_DODGE_GAP;
		if (random () < QX_CY_DODGE_CHANCE)
		{
			a = '0 0 0';
			a_y = vectoyaw (self.enemy.origin - self.origin);
			makevectors (a);
			s = 1;
			if (random () < 0.5)
				s = -1;
			side = v_right * s * QX_CY_SIDE;
			if (CyberJump (side))
			{
				if (self.enemy.health > 0)
				{
					CyberQRocket (-4);
					CyberQRocket (4);
				}
				self.qx_cy_lava = 1;
			}
		}
	}

	if (self.enemy.health <= 0)
		return;

	// circle-strafe like Delta Team
	if (time > self.qx_strafe_next)
	{
		self.lefty = 1 - self.lefty;
		self.qx_strafe_next = time + 0.6 + random () * 0.9;
	}
	yaw = vectoyaw (self.enemy.origin - self.origin);
	if (self.lefty)
		yaw = yaw - 90;
	else
		yaw = yaw + 90;
	if (self.flags & FL_ONGROUND)
	if (!walkmove (yaw, QX_CY_STRAFE))
		self.lefty = 1 - self.lefty;

	// a hop now and then, sometimes topped up with the jetpack
	if (self.flags & FL_ONGROUND)
	{
		if (random () < 0.03)
		{
			a = '0 0 0';
			a_y = yaw;
			makevectors (a);
			CyberJump (v_forward * 260);
		}
	}
	else if (self.velocity_z < 0)
	if (self.qx_cy_jets > 0)
	if (random () < 0.04)
	{
		a = '0 0 0';
		a_y = yaw;
		makevectors (a);
		CyberJump (v_forward * 200);
	}
};

// ---------------------------------------------------------------- attacks

// melee: one big punch (QX_CY_PUNCH damage), it sends you flying
void() CyberPunch =
{
	local vector d;

	if (self.enemy.health <= 0)
		return;
	d = self.enemy.origin - self.origin;
	if (vlen (d) > QX_CY_PUNCH_RANGE + 30)
		return;					// you got away
	if (!infront (self.enemy))
		return;
	sound (self, CHAN_WEAPON, "shambler/smack.wav", 1, ATTN_NORM);
	T_Damage (self.enemy, self, self, QX_CY_PUNCH);
	d_z = 0;
	self.enemy.velocity = self.enemy.velocity + normalize (d) * 450 + '0 0 250';
	self.enemy.flags = self.enemy.flags - (self.enemy.flags & FL_ONGROUND);
	SpawnBlood (self.enemy.origin, '0 0 0', QX_CY_PUNCH);
};

void() cyber_punch1 =[ $shoot1, cyber_punch2 ] {ai_face(); self.qx_cy_punch_next = time + 1;};
void() cyber_punch2 =[ $walk2,  cyber_punch3 ] {ai_charge (12); CyberPunch();};
void() cyber_punch3 =[ $walk3,  cyber_punch4 ] {ai_face();};
void() cyber_punch4 =[ $walk4,  cyber_run1   ] {ai_face(); SUB_AttackFinished (0.3);};


// (a long burst stops when the target is dead or out of sight)
float() CyberKeepFiring =
{
	if (self.enemy.health <= 0)
		return FALSE;
	if (!visible (self.enemy))
		return FALSE;
	return TRUE;
};

// QUTF Ogre rockets: 16, one a frame, a little spread
void() cyber_rock2;
void() cyber_rock1 =[ $shoot1, cyber_rock2 ] {ai_face(); CyberAct(); self.cnt = 0;};
// a fan of rockets
void() CyberRocketFan =
{
	local float n, k;

	n = floor (QX_CY_ROCK_FAN * CyberMass ());
	if (n < 1)
		n = 1;
	k = 0;
	while (k < n)
	{
		CyberQRocket ((k - (n - 1) / 2) * 9 + random () * 6 - 3);
		k = k + 1;
	}
	self.cnt = self.cnt + n;
};

void() cyber_rock2 =[ $shoot3, cyber_rock3 ] {ai_face(); CyberAct(); CyberRocketFan();};
void() cyber_rock3 =[ $shoot6, cyber_rock2 ]
{
	ai_face(); CyberAct(); CyberRocketFan();
	if (self.cnt >= QX_CY_ROCKETS * CyberMass () || !CyberKeepFiring ())
	{
		SUB_AttackFinished (0.4 + random () * 0.6);
		self.think = cyber_run1;
	}
};

// Ogre chaingun: 256 rounds at twice the Ogre's rate
void() cyber_cg2;
void() cyber_cg1 =[ $shoot1, cyber_cg2 ]
{
	ai_face(); CyberAct();
	sound (self, CHAN_WEAPON, "weapons/cg_strt.wav", 1, ATTN_NORM);
	self.cnt = 0;
	self.nextthink = time + 0.3;
};
void() cyber_cg2 =[ $shoot2, cyber_cg3 ]
{
	ai_face(); CyberChaingun();
	self.cnt = self.cnt + 1;
	self.nextthink = time + 0.05;
};
void() cyber_cg3 =[ $shoot3, cyber_cg2 ]
{
	ai_face(); CyberAct(); CyberChaingun();		// (it moves every other round)
	self.cnt = self.cnt + 1;
	self.nextthink = time + 0.05;
	if (self.cnt >= QX_CY_CG_SHOTS || !CyberKeepFiring ())
	{
		SUB_AttackFinished (0.4 + random () * 0.6);
		self.think = cyber_run1;
		self.nextthink = time + 0.1;
	}
};

// Mega Enforcer drunk rockets: 64, two a frame
void() cyber_drunk2;
void() cyber_drunk1 =[ $shoot1, cyber_drunk2 ] {ai_face(); CyberAct(); self.cnt = 0;};
// a swarm of homing rockets
void() CyberDrunkSwarm =
{
	local float n, k;

	n = floor (QX_CY_DRUNK_FAN * CyberMass ());
	if (n < 1)
		n = 1;
	k = 0;
	while (k < n)
	{
		CyberDrunk (k == 0);
		k = k + 1;
	}
	self.cnt = self.cnt + n;
};

void() cyber_drunk2 =[ $shoot4, cyber_drunk3 ] {ai_face(); CyberAct(); CyberDrunkSwarm();};
void() cyber_drunk3 =[ $shoot5, cyber_drunk2 ]
{
	ai_face(); CyberAct(); CyberDrunkSwarm();
	if (self.cnt >= QX_CY_DRUNK * CyberMass () || !CyberKeepFiring ())
	{
		SUB_AttackFinished (0.5 + random () * 0.7);
		self.think = cyber_run1;
	}
};

void() cyber_attack =
{
	local float d, r;

	d = vlen (self.enemy.origin - self.origin);
	r = random ();
	if (d > 900)
	{	// far: the homing rockets find their way
		if (r < 0.6)
			cyber_drunk1 ();
		else
			cyber_rock1 ();
	}
	else if (d > 350)
	{
		if (r < 0.4)
			cyber_cg1 ();
		else if (r < 0.7)
			cyber_rock1 ();
		else
			cyber_drunk1 ();
	}
	else
	{	// close: the chaingun
		if (r < 0.65)
			cyber_cg1 ();
		else
			cyber_rock1 ();
	}
};


//=============================================================================

void() cyber_stand1   =[ $stand1, cyber_stand1 ] {ai_stand();};

// walk

void() cyber_walk1 =[ $walk1,     cyber_walk2  ] {ai_walk(8);};
void() cyber_walk2 =[ $walk2,     cyber_walk3  ] {ai_walk(7);};
void() cyber_walk3 =[ $walk3,     cyber_walk4  ] 
   {  ai_walk(7);
      sound (self, CHAN_WEAPON, "cyber/cybmet.wav", 1, ATTN_NORM);
   };
void() cyber_walk4 =[ $walk4,     cyber_walk5  ] {ai_walk(7);};
void() cyber_walk5 =[ $walk5,     cyber_walk6  ] 
   {  ai_walk(7);
      sound (self, CHAN_WEAPON, "cyber/cybhoof.wav", 1, ATTN_NORM);
   };
void() cyber_walk6 =[ $walk6,     cyber_walk7  ] {ai_walk(9);};
void() cyber_walk7 =[ $walk7,     cyber_walk1  ] {ai_walk(8);};

// run (same as walk really, just a little faster)

void() cyber_run1 =[ $walk1,     cyber_run2  ] {ai_run(QX_CY_RUN); CyberAct();};
void() cyber_run2 =[ $walk2,     cyber_run3  ] {ai_run(QX_CY_RUN); CyberAct();};
void() cyber_run3 =[ $walk3,     cyber_run4  ] 
   {  ai_run(QX_CY_RUN); CyberAct();
      sound (self, CHAN_WEAPON, "cyber/cybmet.wav", 1, ATTN_NORM);
   };
void() cyber_run4 =[ $walk4,     cyber_run5  ] {ai_run(QX_CY_RUN); CyberAct();};
void() cyber_run5 =[ $walk5,     cyber_run6  ] 
   {
      sound (self, CHAN_WEAPON, "cyber/cybhoof.wav", 1, ATTN_NORM);
      ai_run(QX_CY_RUN); CyberAct();
   };
void() cyber_run6 =[ $walk6,     cyber_run7  ] {ai_run(QX_CY_RUN); CyberAct();};
void() cyber_run7 =[ $walk7,     cyber_run1  ] {ai_run(QX_CY_RUN); CyberAct();};


// void() cyber_pain1;
// A Cyberdemon doesn't show pain!

/////////////////////////////////////////////////////////

void(entity attacker, float damage) cyber_pain =
{
// don't make multiple pain sounds right after each other
   if (self.pain_finished > time)
      return;

   if (random() < 0.1)
      sound (self, CHAN_VOICE, "cyber/cybpain.wav", 1, ATTN_NORM);    

   if (self.flags )
        self.pain_finished = time + 3;
   else
        self.pain_finished = time + 2;

};


void()   cyber_die1   =[ $walk1, cyber_die2   ] 
   { 
      sound (self, 7, "cyber/cybdie.wav", 1, ATTN_NORM);
      ai_pain(3);
   };
void()   cyber_die2   =[ $walk2, cyber_die3   ] {ai_pain(3);};
void()   cyber_die3   =[ $walk3, cyber_die4   ] {ai_pain(3);};
void()   cyber_die4   =[ $walk4, cyber_die5   ] {ai_pain(3);};
void()   cyber_die5   =[ $walk5, cyber_die6   ] {ai_pain(3);};
void()   cyber_die6   =[ $walk6, cyber_die7   ] {ai_pain(3);};
void()   cyber_die7   =[ $walk7, cyber_die8   ] {ai_pain(3);};
void()   cyber_die8   =[ $walk1, cyber_die9   ] 
   {
     ai_pain(3);
     sound (self, 5, "cyber/servo.wav", 1, ATTN_NORM);
   };
void()   cyber_die9   =[ $shoot1, cyber_die10   ] 
   { ai_pain(3);
     SpawnExplosion (self.origin_x, self.origin_y + 20, self.origin_z + 60);
     sound (self, 1, "weapons/r_exp3.wav", 0.4, ATTN_NORM);
   };
void()   cyber_die10   =[ $shoot2, cyber_die11  ] {ai_pain(3);};
void()   cyber_die11   =[ $shoot2, cyber_die12   ] 
   { ai_pain(3);
     SpawnExplosion (self.origin_x, self.origin_y - 20, self.origin_z + 40);
     sound (self, 2, "weapons/r_exp3.wav", 0.4, ATTN_NORM);
   };
void()   cyber_die12   =[ $shoot3, cyber_die13   ]
   { sound (self, CHAN_VOICE, "cyber/cybdie.wav", 1, ATTN_NORM);
     ai_pain(3);
   };
void()   cyber_die13   =[ $shoot3, cyber_die14   ] 
   { sound (self, 3, "weapons/r_exp3.wav", 0.4, ATTN_NORM);
     SpawnExplosion (self.origin_x - 20, self.origin_y, self.origin_z+20);
     SpawnExplosion (self.origin_x + 20, self.origin_y, self.origin_z+20);
     SpawnExplosion (self.origin_x, self.origin_y - 20, self.origin_z+20);
     SpawnExplosion (self.origin_x, self.origin_y + 20, self.origin_z+20);
     ai_pain(3);
   };
void()   cyber_die14   =[ $shoot3, cyber_die15   ]  {ai_pain(3);};
void()   cyber_die15   =[ $shoot2, cyber_die16   ] 
   { SpawnExplosion (self.origin_x - 20, self.origin_y, self.origin_z+40);
     SpawnExplosion (self.origin_x + 20, self.origin_y, self.origin_z+40);
     SpawnExplosion (self.origin_x, self.origin_y - 20, self.origin_z+40);
     SpawnExplosion (self.origin_x, self.origin_y + 20, self.origin_z+40);
     ai_pain(2);
   };
void()   cyber_die16   =[ $shoot2, cyber_die17   ] {ai_pain(3);};
void()   cyber_die17   =[ $shoot3, cyber_die18   ] 
   { ai_pain(1);
     SpawnExplosion (self.origin_x - 10, self.origin_y, self.origin_z+70);
     SpawnExplosion (self.origin_x + 10, self.origin_y, self.origin_z+70);
     SpawnExplosion (self.origin_x, self.origin_y - 10, self.origin_z+70);
     SpawnExplosion (self.origin_x, self.origin_y + 10, self.origin_z+70);
   };
void()   cyber_die18   =[ $shoot3, SUB_Remove   ] 
   {
      SpawnExplosion (self.origin_x - 10, self.origin_y, self.origin_z+40);
      SpawnExplosion (self.origin_x + 10, self.origin_y, self.origin_z+40);
      SpawnExplosion (self.origin_x, self.origin_y - 10, self.origin_z+40);
      SpawnExplosion (self.origin_x, self.origin_y + 10, self.origin_z+40);
      sound (self, 4, "weapons/r_exp3.wav", 1, ATTN_NORM);
      sound (self, 5, "cyber/boom.wav", 1, ATTN_NORM);
      ThrowHead ("progs/h_cyber.mdl", -100 - (random()*50) );
      ThrowGib ("progs/gib3.mdl", -150 - (random()*100) );
      ThrowGib ("progs/gib3.mdl", -100 - (random()*100) );
      ThrowGib ("progs/gib1.mdl", -150 - (random()*100) );
      ThrowGib ("progs/gib3.mdl", -100 - (random()*100) );
      ThrowGib ("progs/gib3.mdl", -70 - (random()*100) );
      ThrowGib ("progs/gib3.mdl", -120 - (random()*100) );
      return; 
   };

void() cyber_die =
{
   cyber_die1 ();
};


/*QUAKED monster_cyber (1 0 0) (-32 -32 -24) (32 32 64) Ambush

*/
void() monster_cyber =
{
   if (deathmatch)
   {
          remove(self);
          return;
         }
   // QuadEXQ: the Cyber Delta is THE ENDER's alone (too much for the rest of
   // the game): anywhere else it comes as a BFG fiend
   if (!qx_ender_arena)
   {
      self.classname = "monster_demon2";
      monster_demon2 ();
      return;
   }
   precache_model ("progs/cyber.mdl");
   precache_model ("progs/h_cyber.mdl");
   precache_model ("progs/missile.mdl");
   precache_model ("progs/w_ball.mdl");
   precache_model ("progs/hrail.mdl");
   precache_model ("progs/k_spike.mdl");
   precache_model ("progs/cmissile.mdl");


   precache_sound ("cyber/cybsee.wav");
   precache_sound ("cyber/cybdie.wav");
   precache_sound ("cyber/cybhoof.wav");
   precache_sound ("cyber/cybpain.wav");
   precache_sound ("cyber/cybmet.wav");
   precache_sound ("cyber/cybfire.wav");
   precache_sound ("cyber/boom.wav");
   precache_sound ("cyber/servo.wav");
   precache_sound ("cyber/cyjump.wav");
   precache_sound ("weapons/rail.wav");
   precache_sound ("boss1/throw.wav");		// QuadEXQ: hknight_shot (the fan of lava balls)
   cyber_precache ();						// QuadEXQ: the reworked weapons and jetpack


   self.solid    = SOLID_SLIDEBOX;
   self.movetype = MOVETYPE_STEP;

   setmodel (self, "progs/cyber.mdl");

  setsize (self, '-16 -16 -24', '16 16 40');
   
   if(skill ==3)
   	self.health = 2666; // Approximately the Daikon health...
   else
	self.health = 1666; // Approximately the Daikon health...
   
   self.classname = "monster_cyber";
   self.th_stand   = cyber_stand1;
   self.th_walk    = cyber_walk1;
   self.th_run     = cyber_run1;
   self.th_die     = cyber_die;
   self.th_melee = cyber_punch1;		// QuadEXQ: a punch up close
   self.th_missile = cyber_attack;
   self.th_pain    = cyber_pain;
   self.netname    = "Cyber Delta";
   self.qx_jet     = 1;						// QuadEXQ: the jet knight's body slam, now and then
   self.qx_jet_next = time + 2 + random () * 3;
   
   walkmonster_start();
};

