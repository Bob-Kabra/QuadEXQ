/*
chasecam file
player entity variables used:
.dest_x      (HK WEAP)
.dest1_x     (HUD)
.dest1_y      (MSKIN PRO)
.dest2_x,y,z  (CAM)

 #####################
 ### chase cam mod ###
 Rob Albin, 09 Sep 96

 orig functions modified:
	WEAPONS.QC
		W_SetCurrentAmmo
		ImpulseCommands
	CLIENT.QC
		SetChangeParms
		SetNewParms
		DecodeLevelParms
		PutClientInServer
*/
// ref. defs.qc
float	intermission_running;
float	intermission_exittime;
// message protocol defines
float SVC_SETVIEWPORT	= 5;
float SVC_SETVIEWANGLES	= 10;

// free player entity variable
// ('.float speed'  bit-flag defines:) changed:
// player.dest2_x = bit-flag variable
// player.dest2_y = chasecam distance
// player.dest2_z = chasecam zmult (height offset)
float HUD_ON          = 16;
//float CHSCAM_MONSTER  = 8;* deleted *
float CHSCAM_ON       = 4;
float LASERTARG_LIT   = 2;
float LASERTARG_ON    = 1;


void( entity m_e, entity v_e) set_viewport =
{
	msg_entity = m_e;                         // target of message
	WriteByte (MSG_ONE, SVC_SETVIEWPORT);
	WriteEntity (MSG_ONE, v_e);           // view port
};

void() Keep_cam_chasing_owner;
void( float opt ) Remove_chase_cam;

// (moved to defs.qc)
//float chasecam_dist = 118, chasecam_zmult = 0.30000;
// changed to player.dest2_y (distance)
// player.dest2_z (zmult)
// set in client.qc for initial values

// Resets weapon model after changing view
// called by chase cam or player entities
void( entity player_ent ) Chase_cam_setweapon =
{
	local entity e;

	e = self;
	self = player_ent;
	if ( (self.dest2_x & CHSCAM_ON) ) self.weaponmodel = "";
	else                            W_SetCurrentAmmo ();
	self = e;
};

// called either by player or chase cam entities (to restart)
// vpos:
// '0 0 0' = start from player
// (else use as cam origin)
void( entity cam_owner, vector vpos ) Start_chase_cam =
{

	local entity	chase_cam;

	stuffcmd( cam_owner, "fov 80\n" );

	chase_cam = spawn();

	chase_cam.owner=cam_owner;

	// turn on bit-flag
	chase_cam.owner.dest2_x = chase_cam.owner.dest2_x | CHSCAM_ON;

	chase_cam.solid = SOLID_NOT;
	chase_cam.movetype = MOVETYPE_FLY;


	chase_cam.angles = chase_cam.owner.angles;

	setmodel (chase_cam, "progs/eyes.mdl" );
	setsize (chase_cam, '0 0 0', '0 0 0');

	if (vpos == '0 0 0')
		setorigin( chase_cam, chase_cam.owner.origin + '0 0 22' );
	else
		setorigin( chase_cam, vpos );

	chase_cam.classname = "chase_cam";

	chase_cam.nextthink = time + 0.1;
	chase_cam.think = Keep_cam_chasing_owner;

	// set CLOSE to 0 (ref. PlayerPreThink())
	//chase_cam.owner.view_ofs_z = -1;
	//set_viewport( cam_owner, chase_cam);
	chase_cam.skin = 1; // let track function handle the remote view
							  // part, start with "temp. disabled" flag set

	Chase_cam_setweapon( cam_owner );
	// distance clipping
	chase_cam.ammo_shells = cam_owner.dest2_y / 3;

};

// secondary think for cam entities
void() Reable_chase_cam =
{
	self.nextthink = time + 0.1;

	//if (self.owner.health <= 0)
	if (self.owner.solid == SOLID_NOT)
	{
		//owner died in water, reset .dest2_x flag for respawn
		self.owner.dest2_x = self.owner.dest2_x | CHSCAM_ON;
		remove( self );
		return;
	}

	if (self.owner.waterlevel)
		return;

	self.owner.dest2_x = self.owner.dest2_x | CHSCAM_ON;
	Chase_cam_setweapon( self.owner );

	self.skin = 1; // flag temp. disabled flag so track function
						// will reset remote view
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_FLY;
	setmodel (self, "progs/eyes.mdl" );
	setsize (self, '0 0 0', '0 0 0');
	setorigin( self, self.owner.origin);
	self.ammo_shells = self.owner.dest2_y / 3; // distance clipping
	self.think = Keep_cam_chasing_owner;
	//Start_chase_cam( self.owner, '0 0 0' );
	//remove( self );

};


// called only by chase cam entities
// opt values
// TRUE = remove completely
// FALSE = remove view but keep alive with Reable_chase_cam();
void( float opt ) Remove_chase_cam =
{
	stuffcmd( self.owner, "fov 90\n" );

	// turn off bit-flag
	self.owner.dest2_x = self.owner.dest2_x - (self.owner.dest2_x & CHSCAM_ON);

	// set view-point back to normal
	set_viewport( self.owner, self.owner);


	setmodel( self, "" );
	self.velocity = '0 0 0';

	self.owner.view_ofs_z = 22;

	Chase_cam_setweapon( self.owner );

	if ( !opt )
	{
		self.nextthink = time + 0.1;
		self.think = Reable_chase_cam;
	}
	else
		remove( self );

};

void () cam_deathview =
{
	self.nextthink = time + 0.1;

	if (self.owner.solid != SOLID_NOT)
	{
		remove( self);
		return;
	}

	traceline( self.owner.origin, self.origin, TRUE, self.owner);
	if (trace_inwater)
	{
		set_viewport( self.owner, self.owner);
		self.owner.health = -1;
		remove( self);
		return;
	}
	if (trace_fraction < 1)
	{
		setorigin( self, trace_endpos - self.dest * 8);
		self.velocity = '0 0 0';
	}

	if (self.velocity != '0 0 0')
	{
		traceline( self.origin, self.origin + self.dest * 20, TRUE, self.owner);
		if (trace_fraction < 1 || trace_inwater ||
			 vlen( self.origin - self.owner.origin) > 200)
			self.velocity = '0 0 0';
	}

};

// called only by player ents immediately after being killed, if
// not already in chaseview, and not in water
void() cam_startdeathview =
{
	local entity e;
	local vector goal, ang;
	ang = self.v_angle;
	ang_x = 30; // pretend was a slight down aim
	self.weaponmodel = "";

	e = spawn();
	e.owner = self;
	e.solid = SOLID_NOT;
	e.movetype = MOVETYPE_FLY;
	e.angles = e.owner.angles;
	setmodel (e, "progs/eyes.mdl" );
	setsize (e, '0 0 0', '0 0 0');

	makevectors( ang );
	goal = (self.origin + '0 0 18') - (v_forward * 120);
	traceline( self.origin + '0 0 18', goal, TRUE, self);
	if (trace_inwater)
	{
		remove( e);
		return;
	}
	setorigin( e, trace_endpos + (v_forward * 8));
	e.velocity = '0 0 0' - v_forward * 20;
	e.dest = '0 0 0' - v_forward; // save forward direction, used in cam_deathview
	e.nextthink = time + 0.1;
	e.think = cam_deathview;

	set_viewport( self, e);

};


/*
	main think function for cam entities
		self.ammo_shells = distance clipping
		self.ammo_nails = hang-up flag
		self.dmg = lifts fix
		self.frags = lifts fix
		self.impulse = lifts fix
		self.dest = deathview vector to save 'v_forward' of fade direction
		self.skin = close proximity temporary disableing

	.v_angle_x:
		78.8 (max down aim)
		-68.9 (max up aim)
*/
void() Keep_cam_chasing_owner =
{
	local vector vtmp1, vtmp2;
	local vector owner_vec, goal, dir;
	local float  dist, cap, f_f;


	//debug var
	//local string s;

	//bprint( "\n\n\nz velocity = " );
	//s = ftos( self.owner.velocity_z);
	//bprint( s);
	//bprint( "\n");
	// (results) velocity_z does move when running on sloped ground

	self.nextthink = time + 0.1;

	// check if player toggled
	if (! (self.owner.dest2_x & CHSCAM_ON))
	{
		Remove_chase_cam( TRUE );
		return;
	}

	if (self.owner.solid == SOLID_NOT)
	{
		stuffcmd( self.owner, "fov 90\n" );

		if (intermission_running)
		{
			set_viewport( self.owner, self.owner);
			remove( self );
		}
		else
		{  // deathview
			self.velocity = '0 0 0' - normalize( self.owner.origin - self.origin) * 20;
			self.angles = vectoangles( self.velocity);
			makevectors( self.angles);
			self.dest = v_forward; // save forward direction, used in cam_deathview
			self.think = cam_deathview;
			if (self.skin) // temp disable flag is set
			{
				self.owner.view_ofs_z = -1;
				set_viewport( self.owner, self);
			}
		}
		return;
	}


	if ( self.owner.waterlevel )
	{
		Remove_chase_cam( FALSE );
		return;
	}

	owner_vec = self.owner.origin + '0 0 22';

	// get player velocity relative to player's
	// current yaw
	// f_f (based on running calcs (maxspeed = 400)
	//  (back ~= 640, forward ~= 0)
	dir_y = self.owner.v_angle_y;
	makevectors( dir );
	f_f = vlen( (v_forward * 320) - self.owner.velocity );

	// held for use after second makevectors call for
	// pulling forward on a down aim
	dir = v_forward;

//   local string s;
//   sprint( self.owner, "\n\n f_f = " );
//   s = ftos( f_f );
//   sprint( self.owner, s );
//   sprint( self.owner, "\n f_r = " );
//   s = ftos( f_r );
//   sprint( self.owner, s );
//   sprint( self.owner, "\n" );

	// increment fade-back variable
	self.ammo_shells = self.ammo_shells + 4.5;
	if (self.ammo_shells > self.owner.dest2_y)
		self.ammo_shells = self.owner.dest2_y;

	makevectors( self.owner.v_angle );

	// set spot before clipping
	//.v_angle_x:
	//	78.8 (max down aim)
	//	-68.9 (max up aim)

	goal = owner_vec - (v_forward * self.ammo_shells);
	goal_z = goal_z + 14 + (self.ammo_shells * self.owner.dest2_z);

	// adjust initial goal
	//////////////////////////////////////////////////
	if (self.owner.v_angle_x > 0)
	{
		// pull forward
		cap = self.owner.v_angle_x;
		if (cap > 56) cap = 56;
		goal = goal + dir * cap;

		// pull down
		goal_z = goal_z - (self.owner.v_angle_x * (self.ammo_shells * 0.01));
		cap = self.owner.origin_z + 28;
		if (goal_z < cap)
			goal_z = cap;
	}

	// increase height if getting under the player
	if (goal_z < owner_vec_z)
	{
		vtmp1 = goal; vtmp1_z = 0;
		vtmp2 = owner_vec; vtmp2_z = 0;
		cap = vlen( vtmp1 - vtmp2 );
		if (cap < 100)
		{
			goal_z = goal_z + ((100 - cap) * 0.6);
			if ( goal_z > owner_vec_z )
				goal_z = owner_vec_z;
		}
	}
	//////////////////////////////////////

	// clip for brushes
	//////////////////////////////////////
	traceline (owner_vec, goal, FALSE, self.owner);
	// pull a little forward, avoids most hang-ups along walls
	goal = trace_endpos + ( v_forward * 2 );

	// clip fade-back variable
	traceline( owner_vec, owner_vec - (v_forward * self.ammo_shells), FALSE, self.owner);
	if (trace_fraction < 1)
	{
		self.ammo_shells = vlen(trace_endpos - owner_vec);
		cap = fabs( self.owner.v_angle_x ) - 10;
		if (cap > 0)
			self.ammo_shells = self.ammo_shells + cap;
	}

	traceline (self.origin, goal, FALSE, self.owner );
	if (trace_fraction < 1)
	{
		// half it if blocked
		dir = normalize(goal - owner_vec);
		dist = vlen(goal - owner_vec) * 0.5;
		goal =  owner_vec + dir * dist;
	}

	// pad for floors and ceilings
	traceline (goal, goal + '0 0 6', FALSE, self.owner );
	if (trace_fraction < 1 ) goal = trace_endpos - '0 0 6';
	else
	{
		traceline (goal, goal - '0 0 6', FALSE, self.owner );
		if (trace_fraction < 1 ) goal = trace_endpos + '0 0 6';
	}
	////////////////////////////////////////

	self.angles = self.owner.angles;

	traceline (self.origin, owner_vec, FALSE, self.owner );
	if (trace_fraction < 1)
	{
		// vtmp1_z:  0 = LOS to head
		//				-1 = LOS to feet, but not head
		//				-2 = no LOS
		traceline (self.origin, self.owner.origin - '0 0 24', FALSE, self.owner );
		if (trace_fraction == 1)
			vtmp1_z = -1;
		else
			vtmp1_z = -2;
	}
	else
		vtmp1_z = 0;
	if (vtmp1_z > -2)
	{
		dir = normalize(goal - self.origin);
		dist = vlen(goal - self.origin);

		cap = dist * 0.16;

		if (cap > 5.2)
			self.velocity = dir * dist * 5.2;
		else if (cap > 1)
			self.velocity = dir * dist * cap;
		else
			self.velocity = dir * dist;

		if (vtmp1_z == -1)
		{
			self.velocity_z = self.velocity_z - 400;
		}

		// tighten up if owner running backwards
		if (f_f > 560)
		{
			cap = self.velocity_z;
			self.velocity = self.velocity * 2;
			self.velocity_z = cap;
		}

		if (! self.owner.velocity_z)
		{
			// rising/lowering lifts fix,
			// quick and dirty hack, player.velocity_z stays at zero when
			// moving on a lift, so check through an alternate route for the
			// condition and amplify the current z velocity.
			if (self.owner.origin_z != self.frags)
				//if (self.dmg &&  (self.owner.flags & FL_ONGROUND)) // avoid landing on ground events that can happen between thinks
					// wierd setup here with the .impulse var, forces a skip for first occurance,
					// avoids logic catching vel_z same/org_z dif. instance that happens when player
					// transitions between sloping to level ground while running, (also took care
					// of the same type of thing for landing after a jump)
					if (self.impulse)
						self.velocity_z = self.velocity_z * 3;
					else
						self.impulse = TRUE;
		}
		else if (self.impulse)
			self.impulse = FALSE;

		// try to avoid hangups common to ceiling clips when player
		// is running
		if( self.oldorigin == self.origin )
		{
			if( dist > 16 )
			{
				self.ammo_nails = self.ammo_nails + 1;
				if( self.ammo_nails > 2 )
				{
					self.ammo_nails = 0;
					self.velocity = '0 0 0';
					setorigin( self, goal );
				}
			}
			else
				self.ammo_nails = 0;
		}
	}
	else
	{
		self.velocity = '0 0 0';
		setorigin( self, goal );
	}

	if (! self.skin) // .skin is 1 if in a temp disable state
	{
		if (vlen(self.owner.origin - self.origin) < 30)
		{
			self.skin = 1;
			self.owner.view_ofs_z = 22;
			set_viewport( self.owner, self.owner);
		}
	}
	else
	{
		if (vlen(self.owner.origin - self.origin) > 39)
		{
			self.skin = 0;
			self.owner.view_ofs_z = -1;
			set_viewport( self.owner, self);
		}
	}


	// hacks (only) section :-)

	// keep flag clear so internal C won't drop movement checks
	if (self.flags & FL_ONGROUND)
		self.flags = self.flags - FL_ONGROUND;

	self.oldorigin = self.origin; // cam hang-up hack
	self.frags = self.owner.origin_z; // 'on lift' hack
	self.dmg = self.owner.flags & FL_ONGROUND; // 'on lift' hack
};


// called by player only
void() Toggle_chase_cam =
{

	if (self.waterlevel)
		return;

	if( (self.dest2_x & CHSCAM_ON) )
	{
		// will be noticed by next think
		// of player's chase cam entity
		self.dest2_x = self.dest2_x - CHSCAM_ON;
	}
	else
		Start_chase_cam( self, '0 0 0' );

};

////////////////////////////////////////////
// laser targeter functions

// targeter ent. think function
void() LaserTargeterTrack = {
	local vector src;

	self.nextthink = time + 0.05;

	if (! (self.owner.dest2_x & LASERTARG_ON))
	{
		if( (self.owner.dest2_x & LASERTARG_LIT) )
		{
			self.owner.dest2_x = self.owner.dest2_x | LASERTARG_ON;
			self.effects = self.effects | EF_DIMLIGHT;
		}
		else
		{
			remove( self );
			return;
		}
	}

	if (self.owner.solid == SOLID_NOT)
	{
		// leave .dest2_x flags alone
		remove( self );
		return;
	}

	if (self.owner.weapon == IT_AXE)
	{
		if (self.model != "")
			setmodel( self, "" );
	}
	else if (self.model == "")
		setmodel( self, "progs/cross1.mdl" );

	makevectors( self.owner.v_angle );
	self.angles = vectoangles( v_forward );

	src = self.owner.origin + v_forward * 10;
	src_z = self.owner.absmin_z + self.owner.size_z * 0.7;

	traceline( src,  src + v_forward * 2048, FALSE, self.owner);

	setorigin( self, (0.1 * src + 0.9 * trace_endpos) );


};

void( entity targ_owner ) LaserTargeterToggle =
{

	local entity e;

	if( (targ_owner.dest2_x & LASERTARG_ON) )
	{
		// don't activate glow in multi-player
		if (! deathmatch  && ! coop)
		{
			if( (targ_owner.dest2_x & LASERTARG_LIT) )
				targ_owner.dest2_x = targ_owner.dest2_x - LASERTARG_LIT;
			else
				targ_owner.dest2_x = targ_owner.dest2_x | LASERTARG_LIT;
		}

		targ_owner.dest2_x = targ_owner.dest2_x - LASERTARG_ON;
	}
	else
	{
		targ_owner.dest2_x = targ_owner.dest2_x | LASERTARG_ON;

		e = spawn();
		e.owner = targ_owner;

		e.movetype = MOVETYPE_NONE;
		e.solid = SOLID_NOT;

		// setmodel( e, "progs/s_bubble.spr" );
		setmodel( e, "progs/cross1.mdl" );
		setsize( e, VEC_ORIGIN, VEC_ORIGIN );
		setorigin( e, e.owner.origin );

		if( (e.owner.dest2_x & LASERTARG_LIT) )
			e.effects = e.effects | EF_DIMLIGHT;

		e.nextthink = time + 0.1;
		e.think = LaserTargeterTrack;

	}

};
////////////////////////////////////////////

void () Spawn_extra_changelevels;
void() Chase_cam_lvlstart_think =
{

	self.owner.skin = self.owner.dest1_y; //mskin pro stuff

	if ( (self.owner.dest2_x & CHSCAM_ON) )
		Start_chase_cam( self.owner, '0 0 0' );

	if ( (self.owner.dest2_x & LASERTARG_ON) )
	{
		self.owner.dest2_x = self.owner.dest2_x - LASERTARG_ON;
		LaserTargeterToggle( self.owner );
	}

	if (world.model == "maps/start.bsp")
		Spawn_extra_changelevels();

	remove( self );
};


// called in CLIENT.QC by void() PutClientInServer
// player.dest2_x is set and saved between levels using parm16
// in CLIENT.QC
void() Chase_cam_level_start =
{

	local entity e;

	e = spawn();
	e.owner = self;
	e.nextthink = time + 0.2;
	e.think = Chase_cam_lvlstart_think;

};


// opt:
// 0 = minus
// 1 = plus
// 2 = read cvar temp1 for value
// (player.dest2_y holds cam distance)
void(float opt) Chase_cam_change_dist =
{
	local string s;

	if (!opt)
	{
		self.dest2_y = self.dest2_y - 2;
		if (self.dest2_y < 10)
			self.dest2_y = 10;
	}
	else if (opt == 1)
		self.dest2_y = self.dest2_y + 2;
	else
		self.dest2_y = cvar( "temp1" );

	sprint( self, "chasecam distance = " );
	s = ftos( self.dest2_y );
	sprint( self, s );
	sprint( self, "\n" );


};

// opt:
// 0 = minus
// 1 = plus
// 2 = read cvar temp1 for value
// (player.dest2_z holds zmult)
void(float opt) Chase_cam_change_zmult =
{
	local string str;
	local float f;

	if (!opt)
	{
		self.dest2_z = self.dest2_z - 0.02;
		if (self.dest2_z < 0)
			self.dest2_z = 0;
	}
	else if (opt == 1)
		self.dest2_z = self.dest2_z + 0.02;
	else
	{
		f = cvar( "temp1" );
		self.dest2_z = f * 0.01;
	}

	sprint( self, "chasecam verticle offset = " );

	// convert and strip for display
	// apparantly,
	//	.dest2_z = .dest2_z +- 0.02;
	// don't _exactly_ add/sub 0.02
	f = self.dest2_z * 100;
	f = rint( f );
	str = ftos( f );

	sprint( self, str );
	sprint( self, "\n" );


};

/*
Reads current values of cvar temp1:
opt:
	0 = into player.dest2_y (chasecam distance)
	1 = into player.dest2_z (zmult)
*/
void(float opt) Chase_cam_read_temp1 =
{
	if (!opt)
		Chase_cam_change_dist(2);
	else
		Chase_cam_change_zmult(2);
};

// ### chase cam mod ###
// #####################

// ###############
// ### HUD mod ###

/*
player.dest1_x

to hold last player.health for automaticly printing health changes.

 Axe, Sh, D_brl, Nl, S_Nl, Grnd, Rckt, Ltng
.armortype  (0.3, 0.6, 0.8)
.armorvalue
.currentammo
.weapon
*/


// opt:
// 0 = print only health
// 1 = print full status
// called only by player in ImpulseCommands() and   W_WeaponFrame()
void( float opt ) HUD_print_info =
{
	local string str;
	local float cap, c, c2, c_inc;

	if (! (self.dest2_x & HUD_ON) ) return;

	if (opt == 1) // player selected full update
	{
		self.dest1_x = self.health;

		// ammo
		c2 = 15;
		if (self.ammo_shells  > 9.5 ) c2 = c2 - 0.5;
		if (self.ammo_shells  > 99.5) c2 = c2 - 0.5;
		if (self.ammo_nails   > 9.5 ) c2 = c2 - 0.5;
		if (self.ammo_nails   > 99.5) c2 = c2 - 0.5;
		if (self.ammo_rockets > 9.5 ) c2 = c2 - 0.5;
		if (self.ammo_rockets > 99.5) c2 = c2 - 0.5;
		if (self.ammo_cells   > 9.5 ) c2 = c2 - 0.5;
		if (self.ammo_cells   > 99.5) c2 = c2 - 0.5;
		c = 0;
		while (c < c2) {sprint( self, " " ); c = c + 1;}

		str = ftos( self.ammo_shells );
			sprint( self, str );
			sprint( self, "é");
		str = ftos( self.ammo_nails );
			sprint( self, str );
			sprint( self, "é");
		str = ftos( self.ammo_rockets );
			sprint( self, str );
			sprint( self, "é");
		str = ftos( self.ammo_cells );
			sprint( self, str );

		// armor                                  1234 : 33 left
		if      (self.armortype > 0.78) {str = "\nÉÉÉ "; cap = 200;}
		else if (self.armortype > 0.58) {str = "\nÉÉ  "; cap = 150;}
		else if (self.armortype > 0.28) {str = "\nÉ   "; cap = 100;}
		else                            {str = "\n    "; cap = 0;}
		sprint( self, str );

		if (cap > 0.5)
		{
			c_inc = cap * 0.0303;
			c = c_inc;
			sprint( self, "ù" );
			c2 = 0;
			while (c2 < 32)
			{
				c = c + c_inc;
				if (c < self.armorvalue)
				{
					if (c > (cap - c_inc) )
						sprint( self, "ü" );
					else
						sprint( self, "û" );
				}
				c2 = c2 + 1;
			}

		}

		sprint( self, "\n" );
	}
	else // automatic health print
	{
		cap = self.dest1_x;
		self.dest1_x = self.health;

		// don't print health rots
		if (self.health > 100.5 && cap == self.health + 1) return;

		sprint( self, "\n\n" );
	}

	c = 2.777;
	cap = self.health;
	if (cap > 100 - c ) cap = 100 - c;

	sprint( self, "Ä" );
	while (c < cap)
	{
		sprint( self, "Å" );
		c = c + 2.777;
	}
	if (self.health > 99.5)
		sprint( self, "Ç" );

	if (opt == 1)
	{
		if (self.items & IT_KEY1) sprint( self, "\nS" );
		else                      sprint( self, "\n " );
		if (self.items & IT_KEY2) sprint( self, "G" );
		else                      sprint( self, " " );


		if ( (self.dest2_x & CHSCAM_ON) )
		{
				  if (self.weapon == IT_SHOTGUN)				str = "   Shotgun    ";
			else if (self.weapon == IT_SUPER_SHOTGUN) 	str = "   Dbl Brl    ";
			else if (self.weapon == IT_NAILGUN) 			str = "   Nailgun    ";
			else if (self.weapon == IT_SUPER_NAILGUN) 	str = "   Sup Nailgun";
			else if (self.weapon == IT_GRENADE_LAUNCHER) str = "   Grenades   ";
			else if (self.weapon == IT_ROCKET_LAUNCHER) 	str = "   Rockets    ";
			else if (self.weapon == IT_LIGHTNING)			str = "   Lghtng Gun ";
			else //(self.weapon == IT_AXE)
																		str = "   Axe        ";
		}
		else															str = "              ";

		sprint( self, str );

	}
	else
		sprint( self, "\n                " );


	if (self.health < 100.5)
		sprint( self, "\n" );
	else
	{
						// kkwwwwwwwwwwwwww
					  //  123456789.123456789.123456789.1234567
		sprint( self,                 "               " );
		c = 225;
		while (c > 99) // 225 200 175 150 125 100
		{
			if (self.health > c)
				sprint( self, "é" );
			else
				sprint( self, " " );
			c = c - 25;
		}
		sprint( self, "\n" );
	}

};

// ### HUD mod ###
// ###############





/*
 #####################
 ### Multiskin Pro ###

 player.dest1_y   holds real current skin at all times
						(for powerup changes to use when switching back)

 Orig. functions modifyed:
	WEAPONS.QC
		ImpulseCommands
	CLIENT.QC
		PutClientInServer

*/

// opt:
// 0 = up
// 1 = down
void( float opt ) Choose_multiskin =
{
	local string str;
	if (opt == 0)
	{
		self.dest1_y = self.dest1_y + 1;
		if (self.dest1_y > 20)
			self.dest1_y = 0;
	}
	else
	{
		self.dest1_y = self.dest1_y - 1;
		if (self.dest1_y < 0)
			self.dest1_y = 20;
	}

	self.skin = self.dest1_y;

	str = ftos( self.skin);
	sprint( self, "Skin ");
	sprint( self, str);
	sprint( self, "\n");
};

// ### Multiskin Pro ###
// #####################

/*
 #######################
 ### Hot Key Weapons ###

 player.dest_x : holds previous weapon
 player.dest_y : HK mode; 0=normal (default), 1=multi-explosives
 player.dest_z : flag for previous weapon switch to continue

 Rob Albin, Oct 7 96

 Orig. functions modifyed:
	WEAPONS.QC
		ImpulseCommands

 Abstract:
	Provides hot-key impulses for axe, grenade, and rocket launcher
	that return to previous weapon.
	New cycle weapons impulses that don't select these weapons.

	uses free player entity variable (float point of vector) dest_x
	(only used for doors)


 CFG file use:

 alias +axe_hotkey "impulse 41; +attack"
 alias -axe_hotkey "impulse 40; -attack"

 alias +grenade_hotkey "impulse 42; +attack"
 alias -grenade_hotkey "impulse 40; -attack"

 alias +rocket_hotkey "impulse 43; +attack"
 alias -rocket_hotkey "impulse 40; -attack"

 bind "<key>" "+axe_hotkey"
 bind "<key>" "+grenade_hotkey"
 bind "<key>" "+rocket_hotkey"

 // new weapons cycle commands (skips hot-key weapons)
 bind "<key>" "impulse 44"
 bind "<key>" "impulse 45"

*/


// opt:
// 1 = axe
// 2 = grenade launcher
// 3 = rocket launcher
void( float opt ) HotKey_weapon =
{
	local float w, flg;

	if (self.weapon != IT_GRENADE_LAUNCHER &&
		 self.weapon != IT_ROCKET_LAUNCHER  &&
		 self.weapon != IT_AXE)
		self.dest_x = self.weapon;

	flg = TRUE;

	if (opt == 1)
	{	w = IT_AXE;
	}
	else if (opt == 2)
	{
		if ((self.items & IT_GRENADE_LAUNCHER) &&
			  self.ammo_rockets > 0)
			w = IT_GRENADE_LAUNCHER;
		else
			flg = FALSE;
	}
	else
	{
		if ((self.items & IT_ROCKET_LAUNCHER) &&
			  self.ammo_rockets > 0)
			w = IT_ROCKET_LAUNCHER;
		else
			flg = FALSE;
	}

	if (flg)
	{
		self.weapon = w;
		W_SetCurrentAmmo();
		stuffcmd( self, "+attack\n");
		self.dest_z = TRUE; // flag HK switch happened
	}
	else
		sprint( self, "no weapon/ammo\n");
};

void() HotKey_previous_weapon =
{
	if (! self.dest_z)
		return;

	if (self.dest_x)
	{
		self.weapon = self.dest_x;
		W_SetCurrentAmmo();
	}

	self.dest_z = FALSE; // reset switch flag
};

void() HotKey_CycleWeaponCommand =
{
	local float w, it, am, c;

	c = 0;
	w = self.weapon;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

		if (w == IT_AXE)
		{  w = IT_SHOTGUN;
			if (self.ammo_shells < 1) am = 1;
		}
		else if (w == IT_SHOTGUN)
		{  w = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2) am = 1;
		}
		else if (w == IT_SUPER_SHOTGUN)
		{  w = IT_NAILGUN;
			if (self.ammo_nails < 1) am = 1;
		}
		else if (w == IT_NAILGUN)
		{  w = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2) am = 1;
		}
		else if (w == IT_SUPER_NAILGUN)
		{  w = IT_LIGHTNING;
			if (self.ammo_cells < 1) am = 1;
		}
		else if (w == IT_GRENADE_LAUNCHER)
		{  w = IT_LIGHTNING;
			if (self.ammo_cells < 1) am = 1;
		}
		else if (w == IT_ROCKET_LAUNCHER)
		{  w = IT_LIGHTNING;
			if (self.ammo_cells < 1) am = 1;
		}
		else if (w == IT_LIGHTNING)
		{  w = IT_SHOTGUN;
			if (self.ammo_shells < 1) am = 1;
		}

		if ( (it & w) && am == 0)
		{
			self.weapon = w;
			W_SetCurrentAmmo ();
			return;
		}

		if (c > 9) return;
		c = c + 1;
	}

};


void() HotKey_CycleWeaponReverseCommand =
{
	local float w, it, am, c;

	c = 0;
	w = self.weapon;

	it = self.items;
	self.impulse = 0;

	while (1)
	{
		am = 0;

		if (w == IT_LIGHTNING)
		{	w = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2) am = 1;
		}
		else if (w == IT_ROCKET_LAUNCHER)
		{	w = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2) am = 1;
		}
		else if (w == IT_GRENADE_LAUNCHER)
		{	w = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2) am = 1;
		}
		else if (w == IT_SUPER_NAILGUN)
		{	w = IT_NAILGUN;
			if (self.ammo_nails < 1) am = 1;
		}
		else if (w == IT_NAILGUN)
		{	w = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2) am = 1;
		}
		else if (w == IT_SUPER_SHOTGUN)
		{	w = IT_SHOTGUN;
			if (self.ammo_shells < 1) am = 1;
		}
		else if (w == IT_SHOTGUN)
		{  w = IT_LIGHTNING;
			if (self.ammo_cells < 1) am = 1;
		}
		else if (w == IT_AXE)
		{  w = IT_LIGHTNING;
			if (self.ammo_cells < 1) am = 1;
		}

		if ( (it & w) && am == 0)
		{
			self.weapon = w;
			W_SetCurrentAmmo ();
			return;
		}

		if (c > 9) return;
		c = c + 1;
	}

};

// ### Hot Key Weapons mod ###
// ###########################


// #########################
// ### Start.bsp Marquee ###

void () S_E_CLVLS_marquee =
{
	self.nextthink = time + 1;
	self.ammo_shells = self.ammo_shells + 1;
	centerprint( self.owner, "≠ √Ë·ÛÂ„·Ì …… QuakeC mod ≠\n\n≠  written by Rob Albin  ≠" );
	if (self.ammo_shells > 3)
		remove( self );
};

// float S_E_CLVLS_flag;
void () Spawn_extra_changelevels =
{
	local float i;
	local entity e;

	if (time < 5)
	{
		e = spawn();
		e.owner = self.owner;
		e.nextthink = time + 3;
		e.think = S_E_CLVLS_marquee;
	}

};

// ### Start.bsp Marquee ###
// #########################


// #####################################
// ### Single Player Alternate Rules ###

	//altrules_itemremove( "weapon_supershotgun" );
	//altrules_itemremove( "weapon_nailgun" );
	//altrules_itemremove( "weapon_supernailgun" );
	//altrules_itemremove( "weapon_grenadelauncher" );
	//altrules_itemremove( "weapon_rocketlauncher" );
	//altrules_itemremove( "weapon_lightning" );
	//altrules_itemremove( "item_shells" );
	//altrules_itemremove( "item_spikes" );
	//altrules_itemremove( "item_rockets" );
	//altrules_itemremove( "item_cells" );

void( string n ) altrules_itemremove =
{
	local entity ent, t_ent;

	ent = find (world, classname, n);
	while (ent)
	{
		t_ent = find (ent, classname, n);
		// leave any with .target/.killtarget names
		if (ent.target == "" && ent.killtarget == "")
			remove( ent );
		else
		{
			ent.health = 1;
			ent.max_health = 1;
		}
		ent = t_ent;
	}
};

// ### Items2 Rules ###

void () items2_levelstart_think =
{
	local	entity ent;
	local	float num_b, total_h, avg_h;
	//local string s;

	num_b = 0;
	total_h = 0;

	// get total boxes and health in world
	ent = find (world, classname, "item_health");
	while (ent)
	{
		if (!(ent.spawnflags & H_MEGA))
		{
			num_b = num_b + 1;
			total_h = total_h + ent.max_health;
		}
		ent = find (ent, classname, "item_health");
	}

	if (num_b < 2)
		return;
	avg_h = rint(total_h / num_b);

	// reset boxes for items2 rules
	ent = find (world, classname, "item_health");
	while (ent)
	{
		if (!(ent.spawnflags & H_MEGA))
		{
			ent.health = avg_h;
			ent.max_health = avg_h;
			setmodel(ent, "maps/b_bh25.bsp");
			ent.noise = "items/health1.wav";
		}
		ent = find (ent, classname, "item_health");
	}

	//s = ftos(num_b);
	//bprint("Total boxes = ");
	//bprint(s);

	//s = ftos(total_h);
	//bprint("\nTotal health points = ");
	//bprint(s);

	//s = ftos(avg_h);
	//bprint("\nAvg. health points = ");
	//bprint(s);

	//bprint("\n");

	bprint( "Items2 rules on\n" );
	remove( self );
};

void () items2_levelstart =
{
	local entity ent;

	ent = spawn();
	ent.nextthink = time + 1;
	ent.think = items2_levelstart_think;
};


// ### Vampire Rules ###
entity player_ent; // ruins coop

float MAX_HEALTH_MULT = 2.5;  // multiplyer for .max_health for monsters
										// also used to divide back down for normal health
										// when player kills a monster

// called by T_Damage() in vampire rules, conditions coming in:
// -both targ and att(acker) are player or monster
// -take has just been subtracted from targ.health
void( entity targ, entity attacker, float take ) vamp_checkdamage =
{
	local float d;
	local entity att;

	att = attacker; // just to make sure, not sure on by value/ref. in QC

	if (targ == att)
			return;

	if ((att.flags & FL_CLIENT) ||
		  !(att.flags & FL_MONSTER))
	{
		// set to player if client or something in world killed targ
		att = player_ent;
		if(targ.health < 1)
			d = rint((targ.max_health / MAX_HEALTH_MULT) * 0.1);
		else
			return;
	}
	else
	{
		if (targ.health < 0)
			// subtract off damage past 0
			d = take + targ.health;
		else
			d = take;
		if ((targ.flags & FL_CLIENT))
			d = take * 2;
	}

	att.health = att.health + d;
	if (att.health > att.max_health)
		att.health = att.max_health;
};


void() vamp_levelstart_think =
{
	local	entity ent;
	//local string s;

	altrules_itemremove( "item_health" );

	// set player and monsters .max_health for vampire rules
	ent = nextent(world);
	while (ent != world)
	{
		if ((ent.flags & FL_MONSTER))
			ent.max_health = ent.health * 2.5;
		else if ((ent.flags & FL_CLIENT))
		{
			ent.max_health = 150;
			player_ent = ent;
		}

		ent = nextent(ent);
	}

	bprint( "Vampire rules on\n" );
	remove( self );
};

void () vamp_levelstart =
{
	local entity ent;

	ent = spawn();
	ent.nextthink = time + 1;
	ent.think = vamp_levelstart_think;
};

// ### Single Player Alternate Rules ###
// #####################################


// ### debug cheat

void() CheatCommand;

void() neverend_ammo_think =
{
	self.nextthink = time + 0.3;

	if (self.owner.ammo_shells < 30)
		self.owner.ammo_shells = 30;
	if (self.owner.ammo_nails < 30)
		self.owner.ammo_nails = 30;
	if (self.owner.ammo_rockets < 30)
		self.owner.ammo_rockets = 30;
	if (self.owner.ammo_cells < 30)
		self.owner.ammo_cells = 30;
};
float neverend_ammo_flag;
void() neverend_ammo =
{
	local entity e;

	if (neverend_ammo_flag)
		return;
	neverend_ammo_flag = TRUE;
	CheatCommand();

	e = spawn();
	e.owner = self;
	e.nextthink = time + 0.3;
	e.think = neverend_ammo_think;
};
