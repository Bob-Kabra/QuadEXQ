/*
*/
void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;


// called by worldspawn
void() W_Precache =
{
	precache_model ("progs/v_rshot.mdl");
	precache_model ("progs/s_light.spr");
	precache_model ("progs/v_cg.mdl");
	precache_model ("progs/v_lg.mdl");
	precache_model ("progs/g_gren.mdl");	// QuadEXQ: lightning grenade
	precache_model ("progs/v_ion.mdl");
	precache_model ("progs/lavaball.mdl");
	precache_model ("progs/phase.mdl");
	precache_model ("progs/lspike.mdl");
	precache_model ("progs/laser2.mdl");
	precache_model2 ("progs/plusma.spr");
	precache_model2 ("progs/s_plasma.spr");
	precache_model2 ("progs/memissil.mdl");
	precache_model2 ("progs/tracer.mdl");
	precache_model ("progs/s_bfg.spr");
	precache_model ("progs/t_explod.spr");
	precache_model ("progs/v_bfg.mdl");
	
	precache_sound ("player/axehit.wav");	// new axhit
	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/sgun11.wav");
	precache_sound ("weapons/guncock.wav");	// player shotgun
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/phit1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/phit2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/phit3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/lspike.wav");	// lava spikes
	precache_sound ("weapons/phase.wav");	// phase spikes
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");	// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");	// super shotgun
	precache_sound ("weapons/rshotgn.wav");	// zer riot shotgun
	precache_sound ("weapons/rail.wav");	
	precache_sound2 ("enforcer/enfire2.wav");
	precache_sound2 ("enforcer/enfstop.wav");
	precache_sound2 ("me/me_fire2.wav");
	precache_sound2 ("weapons/lex.wav");
	precache_sound2 ("weapons/bfly.wav");
	precache_sound2 ("weapons/dx.wav");
	precache_sound2 ("weapons/zap.wav");
	precache_sound2 ("player/gibcrash.wav");
	precache_sound2 ("player/lpain.wav");
	precache_sound2 ("player/toh.wav");
	precache_sound2 ("player/gib.wav");
	precache_sound2 ("daikon/zama.wav");
	precache_sound2 ("daikon/yoga.wav");
	precache_sound2 ("weapons/delete.wav");
	precache_sound2 ("weapons/bfg.wav");
	precache_sound2 ("weapons/bshot.wav");
	precache_sound2 ("weapons/bshot1.wav");
	precache_sound2 ("weapons/nukex.wav");
	precache_sound2 ("weapons/bfgx.wav");
	precache_sound2 ("weapons/cgshot.wav");
	precache_sound2 ("weapons/cg_strt.wav");
	precache_sound2 ("weapons/cgshot2.wav");
	precache_sound2 ("hknight/attack1.wav");

	// --- QuadUTF port ---
	precache_sound ("player/taunt.wav");	// QuadEXQ auto melee
	precache_model ("progs/laser.mdl");	// QuadEXQ blaster bolt
	precache_sound ("enforcer/enfire.wav");	// QuadEXQ blaster
	precache_sound ("enforcer/enfstop.wav");

	// QuadEXQ: sounds that were played without being precached on every map
	// (only precached by an item / monster that may not be in the map -> error)
	precache_sound ("items/protect3.wav");	// godmode / invulnerability hit (combat.qc)
	precache_sound ("shalrath/smine.wav");	// homing mine (swizard.qc MineHome)
	precache_sound ("dog/idle.wav");		// monster_dog lives in soldier.qc and
	precache_sound ("dog/dsight.wav");		// never precached its own sounds
	precache_sound ("dog/dpain1.wav");
	precache_sound ("dog/ddeath.wav");
	precache_sound ("dog/dattack1.wav");
	precache_sound ("me/pain3.wav");		// enforcertank pain

};

float() crandom =
{
	//Addition of uniform pseudorandom numbers are normal random number
	return (random() + random() + random() + random() + random() + random() + random() + random() + random() + random() + random() + random() - 6) / 1.5;
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	local	vector	source;
	local	vector	org,dir;
	local 	float	ldmg, rdmg;

	makevectors (self.v_angle);
	source = self.origin + '0 0 16';
	traceline (source, source + v_forward*64, FALSE, self);
	if (trace_fraction == 1.0)
		return;
	dir = aim (self, 100000);
	org = trace_endpos - v_forward*4;
	ldmg=(200 - self.health)/2 + 15;
	rdmg = 40;
	if(self.items & IT_LIGHTNING) rdmg=200;

	if (trace_ent.takedamage)
	{
		if(self.health < rdmg){
		sound (self, CHAN_WEAPON, "player/axehit.wav", 1, ATTN_NORM);
		sound (self, CHAN_BODY, "daikon/yoga.wav", 1, ATTN_NORM);
		self.health = self.health + ldmg/3;
		}
		if (other.solid != SOLID_TRIGGER){
		trace_ent.velocity= trace_ent.velocity + dir * ldmg * 10 + '0 0 50';
		trace_ent.axhitme = 1;
		if (trace_ent.flags & FL_ONGROUND)
		trace_ent.flags = trace_ent.flags - FL_ONGROUND;
		}
		SpawnBlood (org, '0 0 0', ldmg);
		T_Damage (trace_ent, self, self, ldmg);
		
		
	}
	else
	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};


//============================================================================


vector() wall_velocity =
{
	local vector	vel;
	
	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;
	
	return vel;
};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local	entity missile, mpuff;
	local	vector	org;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();

	missile.avelocity = '3000 1000 2000';
	
// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, org);
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*2);
};

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel*0.01, vel, damage);
};


/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity	multi_ent;
float	multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	
	T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;
	
	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;

};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir) TraceAttack =
{
	local	vector	vel, org, enknockback;
	
	
	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;
	dir = normalize (dir);	// QuadEXQ: knockback along the pellet (aim() here would clobber trace_ent)

	if (trace_ent.takedamage)
	{
		if(trace_ent.classname == "monster_lord" || trace_ent.classname == "monster_bane"|| trace_ent.classname == "monster_super_hknight" || trace_ent.classname == "monster_aknight")
			{
				damage = damage / 2;	// QuadEXQ: armored foes take 1/2 from bullets (was 1/4)
				sound (trace_ent, CHAN_WEAPON, "weapons/delete.wav", 1, ATTN_NORM);
			}
		SpawnBlood (org, vel*0.2, damage);
		AddMultiDamage (trace_ent, damage);
	if (trace_ent.takedamage == DAMAGE_AIM){
		enknockback = dir * damage *4;
		trace_ent.velocity = trace_ent.velocity + enknockback + '0 0 5';
		if (trace_ent.flags & FL_ONGROUND)
			trace_ent.flags = trace_ent.flags - FL_ONGROUND;
		trace_ent.avelocity = vectoangles (trace_ent.velocity);
	}

	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread) FireBullets =
{
	local	vector direction;
	local	vector	src;
	
	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);	

	self.punchangle_x = -2;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	dir = aim (self, 100000);
	FireBullets (6, dir, '0.04 0.04 0');
};


/*
================
W_FireSuperShotgun
================
*/
void(float ldmg, float lamo) W_FireSuperShotgun =
{
	local vector dir, recoil;

		
	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);	

	self.punchangle_x = -4;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - lamo;
	dir = aim (self, 100000);
	FireBullets (ldmg * 0.3, dir, '0.07 0.04 0');
	FireBullets (ldmg *0.7, dir, '0.14 0.08 0');

	recoil = dir * ldmg *5;
	self.velocity = self.velocity - recoil;
	self.avelocity = vectoangles (self.velocity);

};
void() W_FireRC =
{
	local vector dir, back;
	local float sdmg;

	if (self.ammo_shells < 2)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
		
	if (self.weaponframe < 2)
		sound (self ,CHAN_WEAPON, "weapons/rshotgn.wav", 1, ATTN_NORM);	

	self.punchangle_x = -4;


	self.currentammo = self.ammo_shells = self.ammo_shells - 1;
	makevectors(self.v_angle);
	dir = v_forward; //aim (self, 100000);
	
	sdmg = QX_SSG_PELLETS;	// QuadEXQ: fixed (EXQ: 20, or 35 with the SNG)
	
	FireBullets (sdmg, dir, '0.20 0.15 0');
	
	//dhm do Newton's 3rd law.
	back = dir * sdmg * 5;
	self.velocity = self.velocity - back;
	self.avelocity = vectoangles (self.velocity);
};
/*
================
W_FireJet
================
*/
void()	Player_JumpTouch ;
void() W_FireJet =
{
	local vector dir;
    	local vector recoil;
	local float z;
	
	if (self.ammo_rockets < 2)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 0.05;

	sound (self, CHAN_WEAPON, "hknight/attack1.wav", 1, ATTN_NORM);
	dir = aim (self, 100000);
	recoil = dir * 60;

	if(vlen(self.velocity)<200)
	{
		self.velocity = self.velocity + recoil*5;
		self.velocity_z = self.velocity_z + 50;
	}
	else if (vlen(self.velocity) < 800)
	{
		self.velocity = self.velocity + recoil;
		self.velocity_z = self.velocity_z + 50;
	}
	else
	{
		self.velocity_z = self.velocity_z + 50;
		self.velocity = self.velocity + recoil * 0.5;
	}
	if (self.velocity_z < -400){
		self.velocity_z = self.velocity_z + 200;
	}
	
	self.avelocity = vectoangles (self.velocity);
	self.touch = Player_JumpTouch;
};



//============================================================================
/*
--------------------------------------------
Bullet cannon
--------------------------------------------
*/
void()	s_puff1	=	[0,		s_puff2] {};
void()	s_puff2	=	[1,		s_puff3] {};
void()	s_puff3	=	[2,		s_puff4] {};
void()	s_puff4	=	[3,		s_puff5] {};
void()	s_puff5	=	[4,		s_puff6] {};
void()	s_puff6	=	[5,		s_puff7] {};
void()	s_puff7	=	[6,		s_puff8] {};
void()	s_puff8	=	[8,		s_puff9] {};
void()	s_puff9	=	[10,		s_puff10] {};
void()	s_puff10	=	[12,		s_puff11] {};
void()	s_puff11	=	[14,		s_puff12] {};
void()	s_puff12	=	[16,		SUB_Remove] {};



void(vector org, vector vel, float damage) BC_puff =
{
local entity  puff, temp;

	puff = spawn();

	puff.origin = org;
	puff.solid = SOLID_NOT;
	puff.movetype = MOVETYPE_FLYMISSILE;
	puff.velocity = (vel * 0.4);
	setorigin(puff, puff.origin);
	puff.owner=self;
	
	setmodel(puff, "progs/t_explod.spr");
	sound (puff, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);
	
	
	T_RadiusDamage (puff, puff.owner, damage, other);

	temp = self;
	self = puff;
	s_puff1 ();
	self = temp;

	//remove(temp);
};

void(float damage, vector dir) BC_Attack =
{
	local	vector	vel, org, reverse;
	local entity	temp;
	local float		courage;

	vel = normalize(dir + v_up);
	vel = vel + 2*trace_plane_normal;
	vel = vel * 70;

	org = trace_endpos - dir*4;
	if (trace_ent.takedamage)
		T_Damage (trace_ent, self, self, damage / 2);

		BC_puff (org, vel, damage);
};

void(vector dir) BC_Fire =
{
	local	vector direction;
	local	vector	src;
	local vector recoil;
	
	recoil = dir * 100;
	self.velocity = self.velocity - recoil;
	self.avelocity = vectoangles (self.velocity);
	
	/*
	if (self.ammo_shells < 2)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
	*/
	sound (self, CHAN_WEAPON, "weapons/cgshot.wav", 1, ATTN_NORM);	
	self.effects = self.effects | EF_MUZZLEFLASH;

	self.currentammo = self.ammo_shells = self.ammo_shells - 2;	
	src = self.origin + v_forward*10 + '0 0 12';
	direction = dir + crandom()*0.02*v_right;

	traceline (src, src + direction*2048, FALSE, self);
	
	
	BC_Attack (80*(0.75+random()*0.5), direction);
};
void() Tracer_Remove =
{
	if (other != self.owner)
		remove(self);
};

void(vector dir) FireTracer =
{
local entity	tracer1;
local vector	src;
local float	calc;

	tracer1 = spawn();
	tracer1.solid = SOLID_BBOX;
	tracer1.owner = self;
	tracer1.movetype = MOVETYPE_FLYMISSILE;
	tracer1.effects = EF_DIMLIGHT;
	tracer1.touch = Tracer_Remove;
	tracer1.velocity = dir*2000;
	tracer1.angles = vectoangles(tracer1.velocity);
	tracer1.origin = src = self.origin + v_forward*5 + '0 0 12';

	setorigin(tracer1, tracer1.origin);
	setsize(tracer1, '0 0 0', '0 0 0');
	setmodel(tracer1, "progs/tracer.mdl");
};

/*
==============================================================================

ROCKETS

==============================================================================
*/

void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
void() T_DMissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 30 + random()*10;
	
	if (other.classname == "monster_shambler")
		damg = damg * 0.5;	// mostly immune
	 
	T_Damage (other, self, self.owner, damg );

	self.origin = self.origin - 8*normalize(self.velocity);
	sound (self, CHAN_WEAPON, "weapons/dx.wav", 1, ATTN_NORM);
	
	BecomeExplosion ();
};

void() T_MissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damg = 100 + random() * 20;		// monsters' rockets (cyber, bane...) unchanged
	if (self.owner.flags & FL_CLIENT)
		damg = QX_RL_DIRECT + random() * 20;	// QuadEXQ: player rockets (EXQ: 100-120, 180-240 with the GL)
	
	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, 120, other);

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};



/*
================
W_FireRocket
================
*/
entity() HomeFindTarget =
{
	local entity head, selected;
	local float dist;
	dist = 100000;
	selected = world;
	head = findradius(self.origin, 100000);
	while(head)
	{
                if( (head.health > 1) && (head != self) && (head != self.owner) && !(head.items & IT_INVISIBILITY) )
		{
			traceline(self.origin,head.origin,TRUE,self);
			if ( (trace_fraction >= 1) && (vlen(head.origin - self.origin) < dist) )
			{
				selected = head;
				dist = vlen(head.origin - self.origin);
			}
		}
		head = head.chain;
	}
/*	if (selected != world)
	{
		sprint (self.owner,"Homing->");
		if (selected.classname == "player")
		{
			sprint (self.owner,selected.netname);
			sprint (selected,self.owner.netname);
			sprint (selected," has locked on you!\n");
		}
		else{
		sprint (self.owner,selected.classname);
		sprint (self.owner,"\n");
		}
	}
*/
	return selected;
};
void() HomeThink =
{
        local vector dir, olddir, vtemp;
        local float turnrate, fluc;
        	
	turnrate= 0.05;
	fluc=0.2;
	

	olddir = normalize(self.velocity);
	
	if ( !(self.enemy) || (self.enemy == world) || (self.enemy.health < 1) )		self.enemy = HomeFindTarget();
		
		if (self.enemy != world) // Arr.. don't be taken on da World!
		{
			vtemp = self.enemy.origin + '0 0 10';
                	dir = normalize(vtemp - self.origin);
                	//Limits the turnrate of the rockets
                	if (olddir_x - dir_x > turnrate)
                        	dir_x = olddir_x - turnrate;
                	else if (olddir_x - dir_x < -1 * turnrate)
                        	dir_x = olddir_x + turnrate;
                	else if (olddir_y - dir_y > turnrate)
                        	dir_y = olddir_y - turnrate;
                	else if (olddir_y - dir_y < -1 * turnrate)
                        	dir_y = olddir_y + turnrate;
                	else if (olddir_z - dir_z > turnrate)
                        	dir_z = olddir_z - turnrate;
                	else if (olddir_z - dir_z < -1 * turnrate)
                        	dir_z = olddir_z + turnrate;
       			else
       				dir = olddir;
				
       			dir_x = dir_x + fluc * (1 - 2 * random());
			dir_y = dir_y + fluc * (1 - 2 * random());
			dir_z = dir_z + fluc * (1 - 2 * random());
			self.velocity = dir * 600;
			if(self.classname == "boss_lava")
				self.velocity = dir * 300;
		}
		else{
			dir_x = olddir_x + fluc * (1 - 2 * random());
			dir_y = olddir_y + fluc * (1 - 2 * random());
			dir_z = olddir_z + fluc * (1 - 2 * random());
			self.velocity = dir * 800;
			if(self.classname == "boss_lava")
				self.velocity = dir * 300;
		}
	if(self.classname == "boss_lava")
		self.nextthink = time + 1.5;
	else
		self.nextthink = time + 0.2;
	self.think=HomeThink;
	self.angles = vectoangles(self.velocity);

};

void(float offset,float offsetx) W_FireRocket2 =
{
	local	vector	offang;
	local	vector	org, vec;
	local	entity 	missile, mpuff;




	if (self.ammo_rockets < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
	
	
    if(self.ammo_rockets > 2 && self.items & IT_LIGHTNING){ 
	org = self.origin + self.mins + self.size*0.5 +  v_forward* 200;
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 0.25;
// set missile speed
	offang = self.v_angle;
	offang_y = offang_y + offset * 6;
	offang_x = offang_x + offsetx * 6;

	makevectors (offang);

	vec = aim(self, 1000);
	
	self.punchangle_x = -6;
	
	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "drunky";

// set missile speed
	vec = normalize(vec);
	missile.velocity = vec * 1000;
	missile.angles = vectoangles(missile.velocity);
	missile.touch = T_DMissileTouch;

// set missile duration
	missile.nextthink = time + 0.2;
	missile.think = HomeThink;

	setmodel (missile, "progs/memissil.mdl");
	setsize (missile, '0 0 0', '0 0 0');
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
	}
};
void() W_FireRocket =
{
	local	entity 	missile, mpuff;
	local	float	spd;
	
	
	if(FALSE){ 	// QuadEXQ: GL-owner fast rockets removed
		sound (self, CHAN_WEAPON, "weapons/sgun11.wav", 1, ATTN_NORM);
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
		spd = 1500;
	
	}
	else {
		sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM); 
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;	// QuadEXQ: was free
		spd = QX_RL_SPEED;	// v0.3: the old GL-owner speed for everyone (harder to dodge)
	}

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "missile";
		
// set missile speed	

	makevectors (self.v_angle);
	missile.velocity = aim(self, 1000);
	missile.velocity = missile.velocity * spd;
	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = T_MissileTouch;
	
// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	local entity		e1, e2;
	local vector		f;
	
	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
	if (trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
		if (self.classname == "player")
		{
			if (other.classname == "player")
				trace_ent.velocity_z = trace_ent.velocity_z + 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
	if (trace_ent != e1 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage)
	{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
	}
};

void(vector p1, vector p2, entity from, float damage) ChainLightDamage;
void() W_FireLightning =
{
	local	vector		org;
	local	float		cells;

	if (self.ammo_cells < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

// explode if under water
	if (self.waterlevel > 1)
	{
		cells = self.ammo_cells;
		self.ammo_cells = 0;
		W_SetCurrentAmmo ();
		T_RadiusDamage (self, self, 35*cells, world);
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -2;

	self.currentammo = self.ammo_cells = self.ammo_cells - 1;

	org = self.origin + '0 0 16';
	v_forward = aim (self, 100000);	// QuadEXQ: LG keeps autoaim
	
	traceline (org, org + v_forward*600, TRUE, self);
	if(self.ammo_cells > 90)
		sound (self, CHAN_WEAPON, "weapons/lex.wav", 1, ATTN_NORM);
	
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	if(self.ammo_cells > 90)
		WriteByte (MSG_BROADCAST, TE_LIGHTNING3);
	else if(self.ammo_cells > 40)
		WriteByte (MSG_BROADCAST, TE_LIGHTNING1);
	else
		WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);
	
	// QuadEXQ: fixed 30 per 0.1s (EXQ: 60 above 40 cells, 80 + chain above 90)
	LightningDamage (self.origin, trace_endpos + v_forward*4, self, QX_LG_DAMAGE);
};


//=============================================================================

void() MGrenadeExplode =
{
	local float	damg,tmp;
	local entity grenade;
	
	
	sound (self, CHAN_WEAPON, "weapons/dx.wav", 1, ATTN_NORM);
	
	damg = self.dmg;
	T_RadiusDamage (self, self.owner, damg, self.owner);
/*
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_TAREXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
*/
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};
void() GrenadeExplode =
{
	local float	damg,tmp;
	local entity grenade;

	if (self.qx_lgren)
	{
		self.qx_lgren = 0;
		QX_GrenadeLightning ();
	}

	T_RadiusDamage (self, self.owner, 120, world);	// QuadEXQ: fixed (EXQ: 150/240 with NG/LG)
	
	if(self.owner.items & IT_ROCKET_LAUNCHER && self.owner.ammo_rockets > 2) 
	{
		if(self.owner.weapon == IT_GRENADE_LAUNCHER)
		{
		while (tmp < QX_GL_CLUSTERS)	// QuadEXQ: was 30
		{
			grenade = spawn();
			grenade.owner = self.owner;
			grenade.movetype = MOVETYPE_BOUNCE;
			grenade.solid = SOLID_BBOX;
			grenade.classname = "cluster";
			grenade.dmg = 40 ;
			grenade.think = MGrenadeExplode;
			grenade.nextthink = time  + 0.1 + random() * 0.5;
			grenade.velocity_z = 800 * random() - 200;
			grenade.velocity_x = 800 * random() - 300;
			grenade.velocity_y = 800* random() - 300;
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
		}
	}
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};
void() MGrenadeTouch =
{
	
	if (other == self.owner)
		return;		// don't explode on owner
	if (other.takedamage == DAMAGE_AIM)
	{
		MGrenadeExplode();
		return;
	}
	else{
		sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
		
		if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
	}
	
};

void() GrenadeTouch =
{
	
	if (other == self.owner)
		return;		// don't explode on owner
	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode();
		return;
	}
	else{
		sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
		
		if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
	}
	
};
void() GrenadeFly =
{
	local 	entity	tex;

	T_RadiusDamage (self, self.owner, 40, self.owner);
	sound (self, CHAN_WEAPON, "weapons/dx.wav", 1, ATTN_NORM);
	tex = spawn();
	tex.owner = self;
	setmodel (tex, "progs/s_explod.spr");
	setsize(tex,'0 0 0','0 0 0');
	setorigin(tex,self.origin);
	tex.velocity = '0 0 0';
	tex.think = BecomeExplosion;
	tex.nextthink = time  + 0.1;
	tex.touch = SUB_Null;
	tex.solid = SOLID_NOT;
	self.nextthink = time + 0.1 *(1 + 0.5 * random());
	self.think = GrenadeFly;
};


/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	local	entity missile, mpuff;
	

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";
		
// set missile speed	

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = GrenadeTouch;
	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplode;
	
	if(FALSE)	// QuadEXQ: NG-owner lava grenade with mid-air blasts removed
	{
	}
	else
	{
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;	// QuadEXQ: was free
		setmodel (missile, "progs/grenade.mdl");
	}

	// QuadEXQ: with the Thunderbolt every grenade also carries a lightning charge
	if (self.items & IT_LIGHTNING)
	if (self.ammo_cells >= 3)
	{
		self.ammo_cells = self.ammo_cells - 3;
		missile.qx_lgren = 1;
		setmodel (missile, "progs/g_gren.mdl");	// the old blue lightning grenade
		if (self.ammo_cells < 3)
			W_SetCurrentAmmo ();			// back to the normal launcher model
	}

	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
};
void() W_FireMGrenade =
{
	local	entity missile, mpuff;
	

	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -2;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";
		
// set missile speed	

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*1000 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 1000;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);
	missile.touch = MGrenadeTouch;
	missile.nextthink = time + 0.5;
	missile.think = MGrenadeExplode;
	
	if(self.items & IT_NAILGUN && self.ammo_rockets > 2)
	{
		self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;
		setmodel (missile, "progs/lavaball.mdl");
		missile.dmg = 120;
	}
	else
	{
	self.currentammo = self.ammo_rockets = self.ammo_rockets - 1;	// QuadEXQ: was free
	setmodel (missile, "progs/grenade.mdl");
	missile.dmg = 80;
	}
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
};


//=============================================================================

void() spike_touch;
void() superspike_touch;


/*
===============
launch_spike

Used for both the player and the ogre
===============
*/

void(vector org, vector dir) launch_spike2 =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;
	newmis.effects = EF_DIMLIGHT;
	newmis.angles = vectoangles(dir);
	
	newmis.touch = spike_touch;
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	
	
	if (self.items & IT_SUPER_SHOTGUN)
	{
		if (self.items & IT_LIGHTNING)
		{
			setmodel (newmis, "progs/phase.mdl");
			setsize (newmis, '0 0 0', '0 0 0');		
			setorigin (newmis, org);

			newmis.classname = "pspike";
			newmis.velocity = dir * 1500;
			newmis.solid = SOLID_BBOX;
		}
		else
		{
		setmodel (newmis, "progs/lspike.mdl");
		setsize (newmis, '0 0 0', '0 0 0');
		setorigin (newmis, org);
		
		newmis.classname = "lspike";
		newmis.velocity = dir * 1000;
		}
	}
	
};

void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};
void()MakeChainBFG;
void()Plasma_Fly =
{
local entity	l_chain;
local float	damage;
local vector vel;

sound (self, CHAN_WEAPON, "weapons/bfly.wav", 1, ATTN_NORM);

self.nextthink = time + 0.1;
self.think = Plasma_Fly;
self.effects = self.effects | EF_MUZZLEFLASH;

l_chain = spawn();
l_chain.origin = self.origin;
l_chain.owner = self;
l_chain.aiment = trace_ent;
l_chain.t_width = self.t_width;
l_chain.dmg = self.dmg;
l_chain.nextthink = time + 0.1;
l_chain.think = MakeChainBFG;

vel = normalize(self.velocity);
self.velocity = vel * 1000;
self.nextthink = time + 0.2;
};
void() MakeChainBFG;
void() BfgExplosion;
void() PlasmaExplosion;
void() plasma_Touch =
{
	local vector org;
	local float damage;
	local entity l_chain;
	
	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
	org = self.origin - 8*normalize(self.velocity); 
	
	damage = 15;
	if (self.owner.flags & FL_CLIENT)
		damage = QX_ION_DAMAGE;
	
	if (FALSE){	// QuadEXQ: LG-owner ion bonus removed
		 damage = 25;
			if(other.health < 90 && other.takedamage == DAMAGE_AIM) 
			{
				if(deathmatch) damage=200;
				else damage=500;
				sound (self, CHAN_WEAPON, "weapons/bfgx.wav", 1, ATTN_NORM);
			}
			
			if(other.health < 150) damage = other.health / 20 + damage;
		T_Damage (other, self, self.owner, damage);
		damage = damage /4;
	l_chain = spawn();
	l_chain.origin = self.origin;
	l_chain.owner = self;
	l_chain.aiment = trace_ent;
	l_chain.t_width = self.t_width;
	l_chain.dmg = damage * 0.5;
	l_chain.nextthink = time + 0.05;
	l_chain.think = MakeChainBFG;
	BfgExplosion();
	}
	else{
		if(other.health < 30 && other.takedamage == DAMAGE_AIM)
		{
			if(deathmatch) damage=200;
			else damage = 500;
			sound (self, CHAN_WEAPON, "weapons/bfgx.wav", 0.5, ATTN_NORM);
		}
	if(other.health < 200) damage = other.health / 40 + damage;
	T_Damage (other, self, self.owner,  damage);
	PlasmaExplosion();
	}
	
};
void(vector org, vector vec, float spd) Launchlaser2 =
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
	
	newmis.avelocity = '0 0 900';
	newmis.velocity = vec * spd *(1+0.3*random());
	newmis.angles = vectoangles(newmis.velocity);
	newmis.nextthink = time + 0.2;
	newmis.dmg = 5;
	newmis.think = Plasma_Fly;
	newmis.touch = plasma_Touch;
	

	sound (self, CHAN_WEAPON, "weapons/bshot.wav", 1, ATTN_NORM);
	self.attack_finished = time + 0.2;
	self.currentammo = self.ammo_cells = self.ammo_cells - 1;
};
void() BFG_touch =
{
local entity	l_chain;
local float	damage,rand,tmp;

	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	damage=300;
	self.effects = self.effects | EF_MUZZLEFLASH;
	T_Damage (other, self, self.owner, damage);
	while(tmp<3)
	{
	  l_chain = spawn();
	  l_chain.origin = self.origin;
	  l_chain.owner = self;
	  l_chain.aiment = trace_ent;
	  l_chain.t_width = self.t_width;
	  l_chain.dmg = damage;
	  l_chain.nextthink = time + 1*random();
	  l_chain.think = MakeChainBFG;
	  tmp=tmp+1;
	}
	
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


void() W_FireBFG =
{
	local	entity missile, mpuff;
	
	if (self.ammo_cells < 30)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
	self.currentammo = self.ammo_cells = self.ammo_cells - 30;
	
	sound (self, CHAN_WEAPON, "weapons/bshot1.wav", 1, ATTN_NORM);

	self.punchangle_x = -30;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
	missile.classname = "b1";
		
	// set missile speed	

	makevectors (self.v_angle);
	missile.velocity = aim(self, 1000);
	missile.velocity = missile.velocity * 300;
	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = BFG_touch;
	
	// set missile duration
	missile.nextthink = time + 0.01;
	missile.dmg = 20;
	missile.think = Plasma_Fly;
	
	setmodel (missile, "progs/s_light.spr");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
};


void() W_FireSuperSpikes =
{
	local vector	dir;
	local entity	old;
	if (self.ammo_cells < 5)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
	makevectors (self.v_angle);
	dir = aim (self, 1000);
	Launchlaser2 (self.origin + '0 0 4', dir, 1000);
	Launchlaser2 (self.origin + '0 0 5', dir, 950);
	Launchlaser2 (self.origin + '0 0 6', dir, 900);
	Launchlaser2 (self.origin + '0 0 7', dir, 850);

	self.punchangle_x = -2;
};

void(float ox) W_FireSpikes =
{
	local vector	dir, recoil;
	local entity	old;
	
	makevectors (self.v_angle);
	
	if (self.ammo_nails < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}
	dir = aim (self, 1000);
	makevectors (self.v_angle);
	
if (FALSE){	// QuadEXQ: SSG/LG-owner nails removed
	if (self.items & IT_SUPER_SHOTGUN)
	{
		if (self.items & IT_LIGHTNING)
		{
		sound (self, CHAN_WEAPON, "weapons/phase.wav", 1, ATTN_NORM);
		self.currentammo = self.ammo_nails = self.ammo_nails - 1;
		launch_spike2 (self.origin + '0 0 16' + v_right*ox, dir);
		recoil = dir * 20;
		self.velocity = self.velocity - recoil +'0 0 10';
		self.avelocity = vectoangles (self.velocity);
		}
		else
		{
		sound (self, CHAN_WEAPON, "weapons/lspike.wav", 1, ATTN_NORM);
		self.currentammo = self.ammo_nails = self.ammo_nails - 1;
		launch_spike2 (self.origin + '0 0 16' + v_right*ox, dir);
		}
	}
	else
	{
	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.currentammo = self.ammo_nails = self.ammo_nails - 1;	// QuadEXQ: was free without the SSG
	launch_spike (self.origin + '0 0 16' + v_right*ox, dir);
	}
}
else{
sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
self.currentammo = self.ammo_nails = self.ammo_nails - 1;	// QuadEXQ: was free with 2 or fewer nails
launch_spike (self.origin + '0 0 16' + v_right*ox, dir);
	
}
	self.punchangle_x = -2;
};



.float hit_z;
void() MakeChainBFG;
void(vector p1, vector p2, entity from, float damage) ChainLightDamage =
{
local entity	l_chain;

	traceline (p1, p2, FALSE, self);
	//if (trace_ent.health > 0 && trace_ent.takedamage)
	//{
		particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, (damage - 5));
		l_chain = spawn();
		l_chain.origin = trace_ent.origin;
		l_chain.owner = self;
		l_chain.aiment = trace_ent;
		l_chain.t_width = self.t_width;
		l_chain.dmg = damage / 2;
		l_chain.nextthink = time + 0.1;
		l_chain.think = MakeChainBFG;
	//}
};

void() spike_touch =
{
local entity l_chain;
local float rand,damg;

	if (other == self.owner)
		return;

	//if (other.solid == SOLID_TRIGGER)
	//	return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
	damg = 9;
	if (self.owner.flags & FL_CLIENT)
		damg = QX_NG_DAMAGE;	// QuadEXQ: one fixed value for the player's nailgun

	if(deathmatch)	damg = damg*0.5;
	

	 if (other.health)
	{
	  if (QX_Armored (other))
    	  damg = damg * QX_NAIL_PIERCE;	// armor penetration!! (EXQ x2, back to x2 in v0.3)
	 
	 }
	// don't do radius damage to the other, because all the damage
	// was done in the impact
	/*
		if(self.owner.ammo_cells>90 && self.classname == "pspike")
	  	{
	  	self.owner.ammo_cells=self.owner.ammo_cells - 1;
		l_chain = spawn();
	  	l_chain.origin = self.origin;
	  	l_chain.owner = self;
	  	l_chain.aiment = trace_ent;
	  	l_chain.t_width = self.t_width;
	  	l_chain.dmg = damg/5;
	  	l_chain.nextthink = time + 0.05;
	  	l_chain.think = MakeChainBFG;
 	  	}
	*/

	self.origin = self.origin - 8*normalize(self.velocity);
	if (other.takedamage)
	{
		 spawn_touchblood (damg);
		 T_Damage (other, self, self.owner, damg );  
	}
	else
	{
		if (self.classname == "pspike")
		{
			rand = random();
			if (rand < 0.3)
				sound (self, CHAN_WEAPON, "weapons/phit1.wav", 1, ATTN_NORM);
			else if (rand < 0.5)
				sound (self, CHAN_WEAPON, "weapons/phit2.wav", 1, ATTN_NORM);
			else
				sound (self, CHAN_WEAPON, "weapons/phit3.wav", 1, ATTN_NORM);
						T_RadiusDamage (other, self.owner, damg, other);
			BecomeExplosion();
			return;
		}
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		if (self.classname == "wizspike" || self.classname == "acospike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	 	
	 	
	}
	remove(self);

};

void() superspike_touch =
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
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

/*
==============================================================================
QuadUTF port: lightning chain (used by the grenade launcher's Thunderbolt bonus)
==============================================================================
*/

// ---- lightning grenade : chain lightning that jumps between targets ----
// (named LG_* so they don't clash with demon2.qc's ChainZap / MakeChainBFG)
void(entity zapped) LG_ChainZap =
{
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING1);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	WriteCoord (MSG_BROADCAST, (zapped.origin_x + zapped.view_ofs_x));
	WriteCoord (MSG_BROADCAST, (zapped.origin_y + zapped.view_ofs_y));
	WriteCoord (MSG_BROADCAST, (zapped.origin_z + zapped.view_ofs_z));

	sound (self, CHAN_WEAPON, "weapons/zap.wav", 1, ATTN_NORM);
	particle (zapped.origin, '0 0 100', 225, 120);
	T_Damage (zapped, self, self.owner, self.dmg);	// owner = the player (kills count)
};

void() LG_MakeChain =
{
	local entity	head;

	if (self.dmg <= 0)
	{
		remove(self);
		return;
	}

	head = findradius(self.origin, QX_GREN_CHAIN_RANGE);   //this is how far it will chain
	while (head)
	{
		if (head.flags & FL_MONSTER || head.flags & FL_CLIENT)
		if (head != self.owner)
		if (head != self.aiment)
		if (head != self.enemy)
		if (head != self.oldenemy)
		if (head.health > 0 && head.takedamage)
		if (visible(head))
		{
			LG_ChainZap(head);
			if(!self.aiment)
				self.aiment = head;
			else if(!self.enemy)
				self.enemy = head;
			else if(!self.oldenemy)
				self.oldenemy = head;
			self.origin = (head.origin + head.view_ofs);
			self.think = LG_MakeChain;
			self.dmg = self.dmg - QX_GREN_CHAIN_FALLOFF;
			self.nextthink = time + 0.05;
			return;
		}
		head = head.chain;
	}
	// nothing left to jump to
	remove(self);
};

// QuadEXQ: grenade + Thunderbolt = the old lightning grenade's chain on every blast
void() QX_GrenadeLightning =
{
	local entity c;

	c = spawn ();
	c.origin = self.origin;
	c.owner = self.owner;			// the player
	c.dmg = QX_GREN_CHAIN;
	if (deathmatch)
		c.dmg = c.dmg * 0.5;
	c.nextthink = time + 0.05;
	c.think = LG_MakeChain;
	sound (self, CHAN_AUTO, "weapons/lex.wav", 1, ATTN_NORM);
};

//=============================================================================

void() W_SetCurrentAmmo =
{
	player_run ();		// get out of any weapon firing states

	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );
	
	if (self.weapon == IT_AXE)
	{
		self.currentammo = 0;
		self.weaponmodel = "progs/v_axe.mdl";
		self.weaponframe = 0;
	}
	else if (self.weapon == IT_BLASTER)
	{
		self.currentammo = 0;
		self.weaponmodel = "progs/v_shot.mdl";	// stand-in model
		self.weaponframe = 0;
	}
	else if (self.weapon == IT_JET)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_rshot.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";	// QuadEXQ: classic SNG
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		if (self.items & IT_LIGHTNING)
		if (self.ammo_cells >= 3)
			self.weaponmodel = "progs/v_lg.mdl";	// QuadEXQ: lightning charge ready
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
	else if (self.weapon == IT_ION)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_ion.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
	else if (self.weapon == IT_BFG)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_bfg.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
	else
	{
		self.currentammo = 0;
		self.weaponmodel = "";
		self.weaponframe = 0;
	}
};

float() W_BestWeapon =
{
	local	float	it;
	
	it = self.items;

	if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & IT_LIGHTNING) )
			return IT_LIGHTNING;
	if(self.ammo_nails >= 4 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;
	if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) )
		return IT_SUPER_SHOTGUN;
	if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
		return IT_NAILGUN;
	if(self.ammo_shells >= 1 && (it & IT_SHOTGUN) )
		return IT_SHOTGUN;
	return IT_BLASTER;	// QuadEXQ: out of ammo -> the free blaster
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;
	if (self.weapon == IT_BLASTER)
		return TRUE;
	//if (self.weapon == IT_JET)
	//	return TRUE;

	self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();
	
// drop the weapon down
	return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()	player_jet1;
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;
void()	player_shot1;
void()	player_rc1;
void()	player_bfg1;
void()	player_nail1;
void()	player_light1;
void()	player_rocket1;
void()	player_atat1;
void()	player_beam1;
void()	player_snail1;
void()	QX_FireBlaster;

void() W_Attack =
{
	local	float	r;
	local	vector dir;
	
	if (!W_CheckNoAmmo ())
		return;

	makevectors	(self.v_angle);			// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up

	if (self.weapon == IT_AXE)
	{
		sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);

		r = random();
		if (self.health >= 40)
			{
			if(r > 0.5) player_axe1 ();
			else player_axec1 ();
			self.attack_finished = time + 0.5;
			}
		else
			{
			player_axeb1 ();
			sound (self, CHAN_WEAPON, "player/toh.wav", 1, ATTN_NORM);
			self.attack_finished = time + 0.25;
			}
		
		
	}
	else if (self.weapon == IT_BLASTER)
	{
		player_shot1 ();
		QX_FireBlaster ();
		self.attack_finished = time + QX_BLASTER_RATE;
	}
	else if (self.weapon == IT_JET)
	{
		player_jet1 ();
		self.attack_finished = time + 0.05;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		
		if(FALSE)	// QuadEXQ: RL-owner slug shot removed
		{
		self.attack_finished = time + 0.5;
		self.punchangle_x = -4+2*random();
		self.punchangle_y = -4+8*random();
		makevectors(self.v_angle);
		dir = v_forward; 
		FireTracer (dir);
		BC_Fire(dir);
		}
		else
		{
			self.attack_finished = time + 0.7;
			W_FireSuperShotgun (12,1);	// QuadEXQ: costs a shell now (was free)
		}
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_rc1 ();
		self.attack_finished = time + 0.7;	// QuadEXQ: no LG-owner fast reload
	}
	else if (self.weapon == IT_NAILGUN)
	{
		player_nail1 ();
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		player_snail1 ();		// QuadEXQ: classic SNG (was the chaingun)
		self.attack_finished = time + 0.1;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1();
		W_FireGrenade();
		self.attack_finished = time + 0.6;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1();
		W_FireRocket();
		
		//if(self.items & IT_SUPER_NAILGUN) self.attack_finished = time + 0.6;
		//else 
		self.attack_finished = time + 0.7;
		
		if(FALSE){	// QuadEXQ: LG-owner extra rockets removed
			W_FireRocket2(0,-0.6);
			W_FireRocket2(-0.6,0);
			W_FireRocket2(0.6,0);
			W_FireRocket2(0,0.6);
		}	
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		player_light1();
		self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}
	else if (self.weapon == IT_ION)
	{
		W_FireSuperSpikes();
		self.attack_finished = time + 0.4;
	}
	else if (self.weapon == IT_BFG)
	{
		player_beam1 ();
		//sound (self, CHAN_AUTO, "weapons/bfg.wav", 1, ATTN_NORM);
		//W_FireBFG();
		self.attack_finished = time + 3.5;
	}
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local	float	it, am, fl;
	
	it = self.items;
	am = 0;
	
	if (self.impulse == 1)
	{
		// QuadEXQ: axe <-> blaster (the jetpack is a mid-air jump now)
		if (self.weapon == IT_AXE)
			fl = IT_BLASTER;
		else
			fl = IT_AXE;
	}
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 2)
			am = 1;
	}		
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 1)	// QuadEXQ: SNG uses 1 per shot
			am = 1;
	}
	else if (self.impulse == 6)
	{
		fl = IT_GRENADE_LAUNCHER;	// QuadEXQ: one launcher (Thunderbolt adds the lightning charge)
		if (self.ammo_rockets < 1)
			am = 1;

	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 8)
	{
		if (self.weapon == IT_LIGHTNING)
		{
			fl = IT_ION;
			
			if (self.ammo_cells < 5)
				am = 1;
		}
		else if (self.weapon == IT_ION)
		{
			fl = IT_BFG;
			if (self.ammo_cells < 30)
                        am = 1;
		}
		else if (self.weapon == IT_BFG)
		{
			fl = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;

		}
		else
			fl=IT_LIGHTNING;

	}
	else if (self.impulse == 119)
	{
                fl = IT_JET;
	}

	self.impulse = 0;
	
	if (!(self.items & fl))
	{	// don't have the weapon or the ammo
		sprint (self, "no weapon.\n");
		return;
	}
	
	if (am)
	{	// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

//
// set weapon, set ammo
//
	self.weapon = fl;		
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	if (deathmatch || coop)
		return;

	self.ammo_rockets = 100;
	self.ammo_nails = 200;
	self.ammo_shells = 100;
	self.items = self.items | 
		IT_AXE |IT_JET |
		IT_SHOTGUN |
		IT_SUPER_SHOTGUN |
		IT_NAILGUN |
		IT_SUPER_NAILGUN |
		IT_GRENADE_LAUNCHER |
		IT_ROCKET_LAUNCHER;

	self.ammo_cells = 100;
	self.items = self.items | 
		IT_LIGHTNING | IT_ION;

	self.weapon = IT_ROCKET_LAUNCHER;
	self.impulse = 0;
	W_SetCurrentAmmo ();
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local	float	it, am;
	
	it = self.items;
	self.impulse = 0;
	
	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE || self.weapon == IT_BLASTER)
		{
			self.weapon = IT_SHOTGUN;	// QuadEXQ: jetpack weapon removed
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_JET)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}		
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 5 )
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
	
		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
CycleWeaponReverseCommand

Go to the prev weapon with ammo
============
*/
void() CycleWeaponReverseCommand =
{
	local	float	it, am;
	
	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 5)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 4)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}		
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN) {
			self.weapon = IT_AXE;		// QuadEXQ: jetpack weapon removed
		}
		else if (self.weapon == IT_AXE || self.weapon == IT_BLASTER || self.weapon == IT_JET) 
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
	
		if ( (it & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
	if (deathmatch || coop)
		return;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items = self.items | IT_QUAD;
	dprint ("quad cheat\n");
};

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();

	if (self.impulse == 9)
		CheatCommand ();
	if (self.impulse == 10)
		CycleWeaponCommand ();
	if (self.impulse == 11)
		ServerflagsCommand ();
	if (self.impulse == 12)
		CycleWeaponReverseCommand ();

	if (self.impulse == 255)
		QuadCheat ();

	if (self.impulse == 150)		// QuadEXQ status
		QX_ShowStatus ();
	if (self.impulse == 152)		// QuadEXQ: practice duel with the Rune Hunter
		QX_DuelPractice ();
	if (self.impulse == 153)		// QuadEXQ: practice duel in a random arena
		QX_ArenaPractice ();
	if (self.impulse == 154)		// QuadEXQ: test the revenge match
		QX_RevengeTest ();
	if (self.impulse == 155)		// QuadEXQ: test the arena challenge
		QX_ChallengeTest ();
	if (self.impulse == 151)		// QuadEXQ: reset PlayerSkill
	{
		QX_SetSkill (QX_StartSkill ());
		sprint (self, "PlayerSkill reset to the difficulty start value\n");
	}
		
	self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
.float  powertime;      // Time which player gains a percent of charge.
void() GibPlayer;
void() W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;

	ImpulseCommands ();
	
// check for attack
	if (self.button0)
	{
		SuperDamageSound ();
		W_Attack ();
	}
	else
	{
	if (self.ammo_cells < 100 && self.weapon == IT_LIGHTNING && self.health > 1)
		{
        	if (self.powertime > time)  return;
		self.ammo_cells = self.ammo_cells + 0.5;  // Add 0.5%
		self.health = self.health - 1;

		if(self.health < 20){ 
			sound (self, CHAN_BODY, "player/lpain.wav", 1, ATTN_NORM);
		}
		else if(random()<0.2) sound (self, CHAN_BODY, "player/gibcrash.wav", 1, ATTN_NORM);
		
		if(self.health < 1.5){
			sound (self, CHAN_BODY, "player/gib.wav", 1, ATTN_NORM);
			self.health = self.health - 1000;
			GibPlayer();
		T_RadiusDamage (self, self.owner, 1000, self.owner);
    sound (self, CHAN_WEAPON, "weapons/nukex.wav", 1, ATTN_NORM);

    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LAVASPLASH);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

		}
		
		W_SetCurrentAmmo ();
		self.powertime = time + 0.5;
		if(self.health < 8) self.powertime = time + 0.15;
		}
	}
	
	
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
};


