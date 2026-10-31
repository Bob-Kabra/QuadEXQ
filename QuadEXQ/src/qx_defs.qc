/*
==============================================================================
QuadEXQ core definitions  (compiled right after defs.qc)

  PlayerSkill   : grows with kills + survival time, drops on death.
                  Scales enemy HP / damage / speed / AI tricks.
  Adrenaline    : fills when enemies are near. Player move + attack speed
                  up to 300%  (Quad Damage = fixed 400%).
  Modern aim    : no autoaim except NG / SNG / LG, movement spread.
  Smart enemies : dodging, jet knights, revenants, elites.
==============================================================================
*/

// ------------------------------------------------------------- tunables
float	QX_SKILL_MAX		= 100;
float	qx_exq_skill;			// Quake / EXQ skill 0..3 = PlayerSkill / 32, fixed for the map (re-rolled after a death)
float(float ps) QX_ExqSkillFor;
.float	qx_leaphit;			// Blarg: this leap has already bitten
.float	qx_leap_next;			// Blarg: no new leap before this time
.float	qx_counted;
.entity	qx_goalitem;			// Rune Hunter: the pickup it is running for
.float	qx_seek_until;
.float	qx_seek_next;
float() QX_HunterItems;			// already in total_monsters
float	qx_skill_deaths;		// qx_mapdeaths when it was last worked out
float	QX_BASE_SKILL		= 1;	// EXQ's own skill-based behaviour is frozen at Normal
float	QX_START_PER_SKILL	= 20;	// starting PlayerSkill = menu skill x this (E0 N20 H40 NM60)
float	QX_SKILL_MINRATE	= 0.05;	// gain rate floor near the top (gain x (100-skill)/100, never below this)
float	QX_SKILL_HURT		= 0.05;	// PlayerSkill lost per point of damage taken from enemies (100 dmg = -5)
float	QX_BOSS_HP		= 2;	// map boss: extra HP on top of elite
float	QX_BOSS_MUSIC_TRACK	= 1;	// music/track01.mp3 (or CD track) while fighting the boss
float	QX_BOSS_MUSIC_RANGE	= 500;	// (unused: the boss music now starts when the boss spots you)
float	QX_SCOUTS		= 2;	// scouts escorting each map boss (squad of 3)
float	QX_SKILL_DEATH		= 20;	// PlayerSkill lost on death
float	QX_SKILL_TIME		= 20;	// seconds alive per +1 PlayerSkill
float	QX_ADREN_RANGE		= 700;	// enemies within this range raise adrenaline
float	QX_ADREN_GAIN		= 0;	// gauge gain per nearby enemy per 0.2s tick (0 = off: gauge comes from hits & kills)
float	QX_ADREN_IDLE		= 1;	// gauge loss per 0.2s tick while not being hit (=5/sec)
float	QX_ADREN_GRACE		= 2;	// seconds after a hit before the idle drain starts
float	QX_REGEN_DELAY		= 5;	// seconds without firing / getting hurt before health regenerates (old EXQ)
float	QX_REGEN_CAP		= 60;	// regenerates up to this much health
float	QX_REGEN_RATE		= 5;	// HP per second (doubled below 20 HP)
float	QX_ADREN_HURT		= 0.3;	// gauge gained per point of damage taken from enemies (30 dmg = +9)
float	QX_ADREN_DECAY		= 2;	// gauge loss per 0.2s tick with no enemy near (=10/sec)
float	QX_ADREN_KILL		= 20;	// gauge gained per kill
float	QX_ADREN_MIN		= 20;	// gauge never drops below this while alive
float	QX_SLOW_START		= 1.5;	// adrenaline 150%: world starts to slow
float	QX_SLOW_MIN		= 0.5;	// adrenaline 300%: world at half speed
float	QX_QUAD_TIMESCALE	= 0.4;	// Quad Damage (400%): world speed
float	QX_JET_MAX		= 3;	// air-jump jet bursts per airtime, at most (one per jetpack found)
float	QX_JET_UP		= 300;	// upward kick per burst
float	QX_SNG_HOMING_SKILL	= 50;	// super nails home in above this PlayerSkill
float	QX_SNG_DAMAGE		= 12;	// super nail damage, grows with PlayerSkill like every weapon (v0.3: 16 -> 12)
float	QX_SNG_FAST_SKILL	= 999;	// above this PlayerSkill the SNG fires every 0.05s (999 = never; was 50)
float	QX_SNG_SPEED		= 2000;	// super nail speed (classic 1000; engine cap sv_maxvelocity = 2000)
float	QX_SNG_TURN		= 0.15;	// homing steer strength per 0.05s (v0.3: 0.3 -> 0.15, gentler)
// ---- weapon ladder (single-target DPS at PlayerSkill 0, before QX_PLAYER_DMG_SCALE)
//   blaster 43 / shotgun 69 / SSG 149 / NG 110 / SNG 160 / GL 140 (+splash) / RL 305 / LG 300 / ION 200
float	QX_NG_DAMAGE		= 11;	// nail damage (vanilla 9) -> 110 DPS
float	QX_SSG_PELLETS		= 13;	// pellets per barrel, x4 dmg, 2 barrels -> 104 per shot
float	QX_ION_DAMAGE		= 20;	// per plasma ball, 4 per volley / 0.4s -> 200 DPS
float	QX_RL_SPEED		= 1500;	// rocket speed (vanilla 1000; EXQ gave 1500 only with the GL)
float	QX_RL_DIRECT		= 120;	// direct hit 120-140 + splash 120 (was 100-120)
float	QX_LG_DAMAGE		= 30;	// per 0.1s -> 300 DPS (vanilla)
float	QX_GL_CLUSTERS		= 6;	// cluster bomblets when you also own the RL (EXQ: 30)
float	QX_GREN_CHAIN		= 80;	// grenade + Thunderbolt: first zap (was 370)
float	QX_GREN_CHAIN_FALLOFF	= 20;	// lost per jump -> 80, 60, 40, 20 (was -5)
float	QX_GREN_CHAIN_RANGE	= 350;	// how far it jumps (was 500)
float	QX_PLAYER_DMG_SCALE	= 1;	// player damage x(1 + this x PlayerSkill/100): matches enemy HP growth
float	QX_BLASTER_DAMAGE	= 15;	// blaster bolt (same as an Enforcer's laser)
float	QX_BLASTER_RATE		= 0.35;	// seconds between bolts
float	QX_BLASTER_SPEED	= 1000;
float	QX_MELEE_GAP		= 30;
float	QX_REV_WARN		= 3;	// seconds of "The slipgate is raging..." before a revenant comes back
float	QX_RESTART_HEALTH	= 100;
float	QX_SAVE_MIN_HEALTH	= 50;	// autosaves (= death checkpoints) only above this health, and only when calm	// after a death the map restarts with at least this much health (QuadEXQ engine)
float	QX_SELF_BLAST		= 0.5;
float	QX_NAIL_PIERCE		= 2;
float	QX_VORE_SPLITS		= 2;	// times one Vore family may split (EXQ: unlimited)	// nails / super nails vs armored knights (lord, bane, super hknight, aknight)	// your own explosions on yourself: x0.5 on top of Quake's x0.5 (= 1/4)
float	QX_DAIKON		= 0;	// 1 = keep EXQ's daikon monster (left out in v0.3)
float	QX_LIQ_LAVA		= 0.04;	// monsters in lava: share of full HP per 0.2s when fully under (20%/s)
float	QX_LIQ_SLIME		= 0.01;	// monsters in slime: 5%/s fully under (feet only = 1/3 of that)	// auto melee when the bounding-box gap is below this

// ------------------------------------------------------------- globals
float	qx_pskill;			// PlayerSkill 0..100 (shared, coop-friendly)
float	qx_lasttier;			// last announced skill tier (every 10)
float	qx_cvar_time;			// next time to mirror qx_pskill into cvar temp1
string	qx_skillvar;		// cvar holding PlayerSkill+1: qx_playerskill (QuadEXQ engine, archived) or temp1
float	qx_persist;			// TRUE on the QuadEXQ engine: PlayerSkill survives restarts via config.cfg
float	qx_skill_seen;		// menu skill when the map loaded (start map difficulty pads)
float	qx_autosave_at;		// pending autosave time (after a boss dies)
float	qx_timescale;		// current world speed (host_timescale), 1 = normal
float	qx_respawning;
entity	qx_boss;			// this map's boss (must die before the exit opens)
float	qx_boss_picked;
float	qx_bossmusic;		// TRUE while the boss theme is playing
float	qx_maptrack;		// the map's own CD/MP3 track (worldspawn "sounds")
float	qx_exitmsg_time;
float	qx_liq_time;			// next monster liquid check
float	qx_newengine;			// engine has qx_respawn / qx_autosave_ok (death checkpoints)
float	qx_safe_time;			// next autosave-safety check
float	qx_skill_written;
float	qx_duel;			// Rune Hunter duel running (qx_hunter.qc)
float	qx_duel_reload;
float	qx_duel_test;
float	QX_DUEL_ADREN_MIN	= 50;	// duel: adrenaline floor (50 = 200%, world at 0.8x)			// impulse 152 practice duel (no stakes)			// time to reload the start map after losing a rune		// PlayerSkill + 1 this game last wrote to the cvar
float	qx_liq_type;			// CONTENT_LAVA / CONTENT_SLIME found by QX_LiquidLevel

// map report (qx_stats.qc): this run of the current map
float	qx_st_init, qx_st_t0, qx_st_skill0, qx_st_slow, qx_st_dealt, qx_st_taken;
float	qx_st_bosst, qx_st_kills, qx_st_points, qx_st_elites, qx_st_scouts, qx_st_jets;
float	qx_st_ended, qx_st_endt, qx_st_score;
string	qx_st_bossname;
.entity	qx_st_lastatk;		// who hurt this player last
.string	qx_st_lastclass;
.float	qx_st_lastelite;
.float	qx_st_cardtime;
.float	qx_liq_next;
.float	qx_splits;			// Vore family: splits used so far (on the root Vore)
.entity	qx_vroot;			// Vore: the map-placed Vore this one split from		// monster: next lava sizzle sound / boss message

// ------------------------------------------------------------- player fields
.float	qx_adren;			// adrenaline 0..100
.float	qx_amult;			// current speed multiplier (1..3, quad 4)
.float	qx_adren_tick;
.float	qx_adren_shown;		// last announced adrenaline step
.float	qx_vmul;			// velocity multiplier applied this frame (0 = none)
.float	qx_nt_seen;			// last nextthink we already rescaled
.float	qx_af_seen;			// last attack_finished we already rescaled
.float	qx_alive_time;		// seconds alive since last +1 skill
.float	qx_kills;
.float	qx_life;			// homing nail lifetime
.float	qx_isboss;
.entity	qx_leader;			// scout: the squad leader it follows
.float	qx_isscout;
.float	qx_slot;			// scout: flank side (+1 / -1)
.float	qx_volley;			// leader: time it last opened fire
.float	qx_volley_seen;		// scout: last volley joined
.float	qx_lastaf;			// leader: last attack_finished seen
.float	qx_rage;
.float	qx_following;		// scout walking back to its leader			// scout whose leader died
.float	qx_hasjet;
// last values sent to the QuadEXQ engine HUD (STAT_QX_*)
.float	qx_hs_flags, qx_hs_adren, qx_hs_skill, qx_hs_time, qx_hs_jets, qx_hs_byaw, qx_hs_bdist, qx_hs_full;			// jetpack owned (from a jet knight's backpack), kept in parm10
.float	qx_lasthurt;
.float	qx_lastpain;		// time of any damage (regen delay)
.float	qx_regen_on;		// regen running (for the gasp sound)
.float	qx_lastfire;		// time the fire button was last held		// time an enemy last hurt this player
.float	qx_jets;			// air-jet bursts used this airtime
.float	qx_lgren;			// grenade carries a lightning charge (Thunderbolt owner)
.float	qx_meleeing;
.float	qx_melee_next;
.float	gravity;			// engine field (Mark V / QuakeSpasm): per-entity gravity			// kills this life

// ------------------------------------------------------------- monster fields
.string	qx_spawnclass;		// classname the spawn function was called with
.float	qx_init;			// variants rolled
.float	qx_basehp;			// HP before any PlayerSkill scaling
.float	qx_tier;			// skill tier the stats were synced to (+1)
.float	qx_hpmul;			// current HP multiplier applied
.float	qx_tempo;			// think-speed multiplier (1 = normal)
.float	qx_elite;			// bot-like super enemy
.float	qx_revenant;		// comes back after death
.float	qx_gen;			// how many times it already came back
.float	qx_hunt;			// respawned: go straight for the player
.float	qx_jet;			// jetpack knight
.float	qx_jet_next;
.float	qx_jet_end;
.float	qx_charging;
.void(entity attacker, float damage) qx_savepain;
.float	qx_dodge_next;
.float	qx_dodging;
.float	qx_strafe_next;
.float	qx_announced;
.vector	qx_home;			// spawn origin   (revenant)
.vector	qx_homeang;		// spawn angles   (revenant)
.float	qx_homeflags;		// spawnflags     (revenant)

// ------------------------------------------------------------- precache wrappers
// Revenants re-run their spawn function in the middle of a level, where the
// engine forbids precache calls. Everything is already precached by then,
// so the wrappers simply skip the call while qx_respawning is set.
string(string s) precache_sound =
{
	if (!self.qx_spawnclass)
		self.qx_spawnclass = self.classname;
	if (qx_respawning)
		return s;
	return precache_sound_real (s);
};
string(string s) precache_model =
{
	if (!self.qx_spawnclass)
		self.qx_spawnclass = self.classname;
	if (qx_respawning)
		return s;
	return precache_model_real (s);
};
string(string s) precache_sound2 =
{
	if (!self.qx_spawnclass)
		self.qx_spawnclass = self.classname;
	if (qx_respawning)
		return s;
	return precache_sound2_real (s);
};
string(string s) precache_model2 =
{
	if (!self.qx_spawnclass)
		self.qx_spawnclass = self.classname;
	if (qx_respawning)
		return s;
	return precache_model2_real (s);
};

// multi-string print builtins (engine concatenates every argument)
void(entity client, string s1, string s2, string s3, string s4) qx_sprint4 = #24;
void(entity client, string s1, string s2, string s3, string s4) qx_cprint4 = #73;

// ------------------------------------------------------------- prototypes
void()	QX_AIHook;
float()	QX_AIRun;
void(entity targ, entity attacker) QX_OnKilled;
float(entity attacker, entity targ) QX_DamageMult;
void()	QX_PlayerPreBoost;
void()	QX_PlayerUnboost;
void()	QX_PlayerFrame;
void()	QX_PlayerSpawned;
void()	QX_PlayerDied;
void()	QX_StartFrame;
void()	QX_WorldSpawn;
void()	QX_ShowStatus;
void()	QX_AirJet;
void()	QX_GrenadeLightning;
float(entity p) QX_ExitBlocked;
void() QX_PickBoss;
void(entity boss) QX_SpawnScouts;
void() QX_ScoutHook;
void() QX_ScoutRun;
void(entity L) QX_LeaderDown;
float(string c) QX_CallSpawn;
void() QX_MakeElite;
void(entity m) QX_DropAmmo;
void(vector spot, string what) QX_RiftTell;
float(entity e) QX_Armored;
float(entity v) QX_VoreCanSplit;
void() QX_RiftCrackle;
void() QX_DuelThink;
void(entity targ, entity attacker) QX_HunterDown;
void() QX_HunterScored;
void() QX_DuelRespawn;
void() QX_DuelPractice;
void(entity parent, entity child) QX_VoreSplit;
void(entity targ, entity attacker, float take) QX_PlayerHurt;
void()	W_FireSuperNail;
// map report (qx_stats.qc)
void()	QX_StatStart;
void()	QX_StatTick;
void(entity attacker, entity inflictor, entity targ, float take) QX_StatHit;
void(entity targ, entity attacker, float take) QX_StatHurt;
void(entity targ, entity attacker) QX_StatKill;
void(float oldskill) QX_StatDeath;
void(entity p) QX_StatMapEnd;
void()	QX_StatInterFrame;
void(float s) QX_SetTimescale;
void()	QX_AutoMelee;
void(float v) QX_SetSkill;
float() QX_StartSkill;
void(float g) QX_GainSkill;
float() QX_GainRate;
vector(entity e) QX_ManualAim;
vector(entity e) QX_AutoAim;
float(entity e) QX_UsesAutoAim;
.float	qx_hs_duel;			// last duel score sent to the HUD
float(string n) QX_HunterIdx;
string	qx_hunter_name;
entity	qx_hunter;
float	qx_duel_pf;
float	qx_duel_hf;
float	qx_arena;			// this map is a Rune Hunter arena (dm1 / dm6 / towersp)
float	qx_arena_go;			// leaving for the arena at this time
void() QX_ArenaInit;
void() QX_ArenaPractice;
float	qx_revenge_pending;		// died while the hunter holds a rune: revenge match on respawn
void() QX_RevengeGo;
.vector	qx_safe_org;		// last safe footing on this map (revenge / challenge comes back here)
.vector	qx_safe_ang;
.float	qx_safe_next;
.float	qx_back_prot;
.float	qx_delta;			// Delta team member 1..3 (an ally, qx_hunter.qc)
.float	qx_dl_lost;			// last time it saw what it was after
.float	qx_dl_look;			// next target search
float	qx_arena_title_at;
float	QX_DEFLECT_ADREN	= 75;	// adrenaline gauge for deflecting (75 = 250%), or Quad
float	QX_DEFLECT_RANGE	= 110;	// enemy shots this close get swatted back
float	QX_W_FIST		= -1;	// the Golden Left Hand, for the map report
.float	qx_deflect_msg;			// last "DEFLECT!" banner
float	qx_st_deflects;			// enemy shots swatted back on this map (map report)
void(float dash) QX_FireFist;
float	QX_EEL_DAMAGE		= 0.75;	// the eel's electric zap was brutal: x0.75
void() QX_AutoDeflect;		// show the arena's map name and title at this time
float	qx_delta_call;			// call Delta team in at this time (after an arena win)
float	qx_delta_losses;		// members down since the team arrived (3 = they pull out)
float	qx_delta_kills;			// monsters Delta team killed since it arrived
float	qx_st_delta;			// monsters Delta team killed on this map (map report)
void() QX_DeltaArrive;		// no damage until this time (just back from the arena)
void() QX_RevengeRoll;
void() QX_RevengeTest;
void() QX_ChallengeTest;
.float	qx_hskill;		// Rune Hunter skill 0..2 (2 = Tres: no autoaim lock)
