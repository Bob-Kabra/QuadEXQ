==============================================================================
  QuadEXQ  v0.6 beta
  "The harder you fight, the slower the world gets.
   The better you play, the smarter they get."
==============================================================================

QuadEXQ is a single-player overhaul of the Quake mod "EXQ" that rebuilds how
the game plays. It runs best with its own engine, quadexq.exe (a Mark V
fork), which adds the HUD, music switching, checkpoints and more.

  - One difficulty setting: PlayerSkill. The better you play, the tougher
    and smarter the enemies get.
  - Bullet time: when your adrenaline builds up, the world slows down.
  - Every map has a boss. The exit stays sealed until the boss is dead.
  - Enemies that dodge, knights with jetpacks, enemies that come back, and
    elite squads.
  - Every weapon sits on a damage-per-second ladder and grows with
    PlayerSkill.
  - A score and a play report for every map you clear.
  - Die, and you're back at the last safe checkpoint, not the start of the
    map.


------------------------------------------------------------------------------
 Contents
------------------------------------------------------------------------------
  1. Installing and running
  2. Single Player menu (Continue)
  3. PlayerSkill - how difficulty works
  4. Adrenaline and bullet time
  5. Map bosses (the exit condition)
  6. Enemies
  7. Weapons
  8. Movement, healing and ammo
  9. Score and map report
 10. QuadEXQ engine features
 11. Console commands and settings
 12. Known issues and notes
 13. Version history
 14. Credits


==============================================================================
 1. Installing and running
==============================================================================

  Lay out your Quake folder like this:

    Quake\
      id1\               <- the original Quake data (pak0.pak / pak1.pak)
      QuadEXQ\           <- this mod
        progs.dat
        maps\towersp.bsp       <- a Rune Hunter arena (included)
        (the EXQ data: pak / progs / sound, etc.)
        music\track01.mp3       <- boss music (included)
        music\track02.mp3 ...   <- normal map music (optional)
        sound\player\taunt.wav  <- auto-melee shout (optional)
      quadexq.exe        <- the QuadEXQ engine (recommended)

  Run:
    quadexq.exe -game QuadEXQ
    (included bat file in QuadEXQ directory. Just double click to run)

  * Other Mark V or QuakeSpasm-family engines can run the mod too. These
    features need the QuadEXQ engine (section 10):
      - the HUD and the intermission report card
      - CONTINUE / start-map choice in the Single Player menu
      - death checkpoints and safe autosaves
      - keeping PlayerSkill between launches
      - the play log file
  * Single player only. Some systems switch off in coop and deathmatch.


==============================================================================
 2. Single Player menu (Continue)
==============================================================================

  The main menu is the stock one. With the QuadEXQ engine, SINGLE PLAYER
  opens this:

    CONTINUE      resume from the latest autosave (s19.sav)
    NEW GAME      start over (go to the start map)
    LOAD / SAVE
    LEVELS        level select

  CONTINUE is drawn in the real Quake menu font, put together at startup
  from your own id1 menu pictures.

  NEW GAME lists the maps you can start on:
    - start.bsp
    - every map in the mod folder with "start" in its name (bbstart, ...)
  The default choice is start (or whatever newgame_map is set to). With
  only one candidate, the game starts right away. Esc goes back.

  CONTINUE only appears once an autosave exists. Until then, NEW GAME is
  at the top. Choosing CONTINUE or NEW GAME during a game asks you to
  confirm.


==============================================================================
 3. PlayerSkill - how difficulty works
==============================================================================

  There is only one difficulty: PlayerSkill, from 0 to 100.
  The Easy / Normal / Hard / Nightmare choice (menu or start map) only sets
  your starting PlayerSkill:

    Easy 0 / Normal 20 / Hard 40 / Nightmare 60

  Raised by:
    - kills: +1, big monsters +2, elites +5, bosses +5
    - staying alive: +1 every 20 seconds
    The higher it is, the slower it rises: you gain (100 - PlayerSkill)%
    of each amount, never less than 5%.

  Lowered by:
    - dying: -20
    - taking enemy damage: -5 per 100 damage. Your own explosions, lava and
      falling don't count.

  As PlayerSkill rises (it takes effect in steps of 5):
    enemy health      x (1 + PlayerSkill/100)
    enemy damage      x (1 + 0.5 x PlayerSkill/100)
    enemy speed       x (1 + 0.5 x PlayerSkill/100)
    more dodging, more jet knights, more revenants and more elites
    YOUR damage       x (1 + PlayerSkill/100)   <- grows as fast as enemy health

    -> Enemies take the same time to kill at any PlayerSkill.
       What changes is how dangerous they are.

  Quake's own skill also follows PlayerSkill: PlayerSkill / 32, so
  0-31 Easy, 32-63 Normal, 64-95 Hard, 96+ Nightmare. It is set when a map
  loads (and worked out again after a death), and it decides EXQ's monster
  swaps too: the higher it is, the more Shamblers turn into Juggernauts,
  Vores or (Nightmare only) the Cyberdemon, Ogres into QUTF Ogres, Zombies
  into Mummies, and so on.

  Milestones:
    above 50   the Super Nailgun fires homing nails
    at 100     every enemy becomes an elite, including the ones already
               on the map

  Saving:
    QuadEXQ engine: PlayerSkill is stored in your config, so it carries
                    over to the next launch.
    other engines:  it lasts until you quit.
    Stepping on a difficulty pad in the start map resets PlayerSkill to that
    difficulty's starting value.


==============================================================================
 4. Adrenaline and bullet time
==============================================================================

  The adrenaline gauge reads 100% to 300% (400% during Quad Damage).

  Fills when:
    - you take enemy damage: about +18% per 30 damage
    - you kill something: +40% per kill

  Drains:
    - 2 seconds after the last hit you took: -10% per second
    - with no enemies around: -20% per second
    It never drops below 140%.

  Bullet time:
    Above 150% the WORLD slows down:
      200% -> 0.8x / 250% -> 0.7x / 300% -> 0.5x / Quad Damage -> 0.4x
    You still move, shoot and reload at normal speed. Your projectiles are
    part of the world, so they fly slowly too. With the QuadEXQ engine, the
    sound pitch also drops as the world slows.

    Bullet time ends at once when you die or reach the intermission.


==============================================================================
 5. Map bosses (the exit condition)
==============================================================================

  Two seconds after a map starts, one enemy is picked as the BOSS. Big
  monsters are picked first.

    - It sparkles. When you first see it: "!!! BOSS !!!"
    - It is always an elite, with double health on top of that.
      Like every enemy, it gets stronger with PlayerSkill.
    - The exit stays sealed while the boss is alive.
    - It leads a squad of 3, with two "scouts" of the same kind:
        - They follow the boss around.
        - When the boss spots a target, the whole squad goes after it.
        - They split left and right to flank you, and fire together
          whenever the boss fires.
        - When the boss dies, the scouts go berserk: faster, and glowing.
    - When the boss spots you, the music switches to the boss theme
      (track01). Killing it switches back to the map's own track. Rune
      Hunter duels always play the boss theme.
    - Killing it triggers an autosave (QuadEXQ engine).

  * There is no sealed exit on maps with Chthon or Shub-Niggurath, or on
    maps with no suitable boss.
  * THE RUNE HUNTER: come back to the start map holding 2 or more runes
    and a rival who looks just like you calls you out. Three seconds later
    you are both taken to an arena for a deathmatch duel, first to 10
    frags, and back to start when it's over, win or lose.
      - The arena is picked at random from every map you have with "dm"
        in its name (DM1-DM6 from registered Quake, custom DM maps in your
        folders), plus Q1Edge and Towersp (The Tower of Nightmare, by Bob
        Kabura, included in maps\). Maps you don't have are skipped.
        (Needs the QuadEXQ engine's qx_arena command; with other engines
        the arena is one of DM1-DM6 or Towersp.)
      - "Welcome to EXQ Arena!!" greets you when you arrive.
      - Hold Tab for the duel scoreboard, and the HUD compass points at
        the hunter with its distance, like the boss compass. (QuadEXQ
        engine.)
      - !!! YOU WIN !!! or YOU LOSE shows when it's over.
      - Each hunter wears its own colors (QuadEXQ engine): GuroFighter
        purple, G white, K4B blue, Tres red.
      - The arena's own items respawn like in deathmatch, and its
        monsters stay out of it. The exits stay shut.
      - Who comes depends on your PlayerSkill: GuroFighter (0-49),
        G or K4B (50-99, a coin toss each duel) or Tres (100), the
        strongest.
          G      also fires super nailgun bursts (nails led at you).
          K4B    mostly swaps the rockets for the grenade launcher and lobs
                 lead shots that land where you're running to, often (a
                 rocket now and then).
          Tres   uses a thunderbolt at mid range (no auto-aim: it aims
                 where you were a moment ago, so keep strafing) and jumps
                 around on a jetpack. He can't be locked by your auto-aim
                 or homing nails: you have to aim at him yourself.
      - Like a deathmatch bot it grabs health and armor: hurt, it runs
        for the nearest one it can see (shooting on the way), and it takes
        any it walks over. Deny it the megahealth and the red armor!
      - It moves like an elite, uses a super shotgun up close and rockets
        at range, and better hunters aim tighter and lead their rockets.
      - You get an arena kit for the duel: super shotgun, nailgun and
        ammo. Every time you frag the hunter it drops its rocket launcher.
        The kit goes back when the duel ends.
      - Practice duels on start.bsp (impulse 152) bring back the map's own deathmatch
        layout, which single player never loads: all six DM spawn spots,
        every weapon, armor, health and ammo box, the Quad Damage, and the
        DM walls and teleporters. Items come back 20 seconds after they
        are taken (the Quad after 60), and both of you respawn on a
        random spot away from the other.
      - On other maps (practice duels) items go on the spawn spots
        instead (up to 8: armor, health and weapons).
      - Weapons you pick up are gone again when the duel ends; your own
        inventory comes back.
      - Your adrenaline never drops below 200% during the duel, hits pump
        it twice as fast, and frags pump it too.
      - Both of you respawn on the spot during the duel (no PlayerSkill
        penalty; you get 100 health and some ammo back).
      - The exits are locked until it is over.
      - Win: +1000 score, or +10000 for a PERFECT 10 - 0.
        Lose: it takes the rune you got last and runs,
        and you are back in the start map.
      - Each rune count (2, 3, 4) is fought once; your saves remember it.
      - !! REVENGE MATCH !!: while the hunter holds one of your runes,
        each death has a 30% chance of a revenge match instead of the
        checkpoint. You go to an arena with nothing to lose; win and the
        rune is yours again. Either way you come back to where you died
        (the last safe spot you stood on), with 100 health and 3 seconds
        of safety. (QuadEXQ engine.)
      - !! ARENA CHALLENGE !!: when it holds none of your runes, each death
        still has a 30% chance of a challenge instead: nothing to lose,
        and a win lets you keep the weapons you had in the arena (with
        some ammo) plus the score (+1000, PERFECT +10000). Back to where
        you died afterwards, like a revenge match.
      - Arenas need at least two deathmatch spawn spots; maps with fewer
        are never picked.
  * Chthon: hit him with the lightning trap. While he is stunned (and for a
    moment when he attacks) your normal weapons hurt him too.


==============================================================================
 6. Enemies
==============================================================================

  Dodging      Enemies sidestep shots flying at them, and sidestep when you
               aim at them while firing. They won't jump into pits or lava.
  Jet knights  Some knights charge at you with a jetpack. A hit does heavy
               damage and knocks you back. They drop their jetpack when
               killed (section 8).
  Revenants    A few seconds after you kill one, it teleports back to where
               it started and comes straight for you. It returns at most
               twice.
               Three seconds before it returns, you get a warning: lightning
               and sparks at the spot, and "The slipgate is raging..." with
               the direction (ahead / on your left / on your right /
               BEHIND YOU / far away). Then: "REINFORCEMENTS!"
  Liquids      Enemies now take damage in slime and lava (they never did in
               stock Quake). Damage is a share of their full health: lava
               20% per second fully under, slime 5% per second. A boss that
               falls into lava burns. Fish, eels, Chthon and Shub are immune.
  Elites       Glowing pale-blue enemies with 2.5x health. They move faster,
               hit harder, dodge often and fire often. They circle-strafe
               and bunny-hop. An elite ogre looks like the TyrantOgre.

  Vores        When a Vore splits, the health it has left is shared
               half-and-half with the new one. One Vore can split at most
               twice (in EXQ it never stopped).
  Spike mines  The homing mines some Wizards fire can be shot down: any
               hit makes them blow up early.

  Almost every enemy drops an ammo backpack. Elites drop double, bosses
  triple.


==============================================================================
 7. Weapons
==============================================================================

  Aiming:
    Only the Super Nailgun and the Lightning Gun auto-aim. Every other weapon
    fires exactly where you point, with a little spread while you run or
    are in the air. (The Rune Hunter Tres is the one target auto-aim
    won't lock onto.)

  Balance:
    EXQ's "owning weapon X makes weapon Y stronger" bonuses are almost all
    gone. Each higher slot is stronger than the one below.

    Single-target DPS at PlayerSkill 0:

      1 Blaster          43    no ammo; the Enforcer's laser
      2 Shotgun          69
      3 Super Shotgun   149
      4 Nailgun         110
      5 Super Nailgun   120    auto-aim, double nail speed, homing above 50
      6 Grenade L.      140    + splash damage
      7 Rocket L.       305    fast rockets (1500 units/s)
      8 Lightning       300    auto-aim
        Ion             200
        BFG

    Every weapon's damage grows with PlayerSkill (section 3).

  Slot 1: Axe <-> Blaster
    Even with no ammo left, you always have the Blaster.

  Slot 6: Grenade Launcher upgrades (only these two)
    - With the Rocket Launcher: each blast throws 6 small cluster bomblets.
      They can't hurt you.
    - With the Lightning Gun and at least 3 cells: each blast also sets off
      a chain of lightning that jumps from enemy to enemy, 80 -> 60 -> 40
      -> 20 damage, up to 350 units per jump.
      The launcher and grenades turn into the blue lightning-grenade models
      while this is ready, so you can tell at a glance.

  Your own rockets and grenades do 1/4 of their blast damage to you
  (stock Quake already halves it; QuadEXQ halves it again).

  Armored enemies (Armor Knight, Lord, Bane, Super Hell Knight) take half
  damage from bullets and double damage from nails and super nails.


==============================================================================
 8. Movement, healing and ammo
==============================================================================

  Jetpack:
    Pick up the glowing backpack a jet knight drops to unlock it.
    Jump again in mid-air to fire a burst; you get 3 bursts before you land.
    Once you have it, you keep it on later maps.
    Picking up another one while you have it gives +5 rockets. Dropped
    jetpacks vanish after 120 seconds.

  Auto melee:
    When an enemy is right in front of you, you swing the axe automatically.
    You can't shoot during the swing.

  Health regeneration:
    Go 5 seconds without firing or taking damage and you heal up to 60 HP:
    5 HP per second, or 10 per second below 20 HP.
    You don't heal while holding the Lightning Gun.


==============================================================================
 9. Score and map report
==============================================================================

  When you reach the exit, the map's report is printed to the console
  (press ~ to read it):

    === e1m3 CLEAR   SCORE 1840 ===
      - clear time, deaths, and PlayerSkill at the start -> at the end
      - kills (elites and scouts listed separately) and secrets
      - when the boss died, seconds spent in bullet time, and jet bursts
      - damage dealt and damage taken
      - for each weapon: time held, time firing, hits, damage, kills and
        DPS (damage per second spent firing)

  Intermission screen (QuadEXQ engine): the stock "kills x / total" is
  replaced by a report card:
    - SCORE in big numbers
    - time, kills, deaths, secrets, and PlayerSkill at the start -> at the end
    - when the boss died
    - a weapon table: time held, damage, kills, and DPS (damage per
      second spent firing, misses included)

  Score:
    kill 10 / scout 20 / elite 30 / boss +300
    secret 100 / death -200 / clear without dying +300

  Play log (QuadEXQ engine):
    quadexq_stats.txt in the QuadEXQ folder grows with every session. It
    records:
      - map starts
      - deaths: when, what killed you, and the weapon you were holding
      - boss kills
      - clear reports
    Please attach this file to test-play reports.

  * The numbers cover your current attempt at the map. After a death they
    go back to what they were at the checkpoint (or reset if the map
    restarts); only the death count carries over.


==============================================================================
 10. QuadEXQ engine features
==============================================================================

  quadexq.exe is a QuadEXQ build of the Mark V engine. With any other mod it
  behaves like plain Mark V.
  Source code (GPL v2): https://github.com/Bob-Kabra/QuadEXQ

  - HUD (bottom center):
      ADR   Adrenaline bar and %.
            - a tick mark at 150%
            - orange above 150%, red at max, gold during Quad Damage
            - "TIME x0.7" (or similar) while the world is slowed
      SKL   PlayerSkill bar ("MAX" at 100)
      JET   Jet bursts left (only once you have the jetpack)
      BOSS  Direction and distance to the boss (while it is alive)
  - Sound pitch drops during bullet time.
  - MP3 music (music\trackXX.mp3), with the boss theme switching in and
    out.
  - Checkpoints: when you die, you go back to the map's latest autosave
    instead of the start of the map. If there is no autosave yet, the map
    restarts, with at least 100 health. PlayerSkill keeps its death penalty
    (loading any save never undoes it).
  - Autosave:
      - when it happens: 10 seconds into a map, every 90 seconds after
        that, right after a boss dies, and when you open the menu or quit
        (so stopping right after a map change keeps the new map)
      - only when it is calm: 50+ health, on the ground, out of liquids,
        not hit for 4 seconds, no bullet time, and no enemy in sight that
        is after you. Otherwise it waits, so a checkpoint never drops you
        into a hopeless spot.
      - it is also written to load slot 20 (s19.sav), which the CONTINUE
        menu entry loads
  - PlayerSkill saved in your config.
  - Runes work as in stock Quake: they live in your game and its saves.
    CONTINUE (or loading a save) keeps them, NEW GAME starts without them.
    Loading a save brings its runes back right away (stock Quake only did
    that at the next level change).
  - The play log, quadexq_stats.txt.
  - CONTINUE / NEW GAME in the Single Player menu.
  - Fixed a stock Mark V bug where the fire button could stay held after
    you let go (lost mouse-button events with fast mice).


==============================================================================
 11. Console commands and settings
==============================================================================

  impulse 150              status: PlayerSkill, enemy multipliers,
                           adrenaline, world speed, distance to the boss
  impulse 151              reset PlayerSkill to your difficulty's start value
  impulse 152              practice duel with the Rune Hunter, on any map,
                           right now. Nothing is won or lost. The hunter
                           follows your PlayerSkill (GuroFighter / G or K4B / Tres).
  impulse 153              practice duel in a random arena (any dm map,
                           Q1Edge, Towersp), then back to start. Nothing is won or
                           lost.
  impulse 154              revenge match test: the hunter "holds" your
                           episode 1 rune and your next death calls a
                           revenge match (win it and you get that rune).
  impulse 155              arena challenge test: your next death calls an
                           arena challenge.

  QuadEXQ engine:
  scr_qxhud 0/1            show the HUD (default 1)
  snd_qxpitch 0-1          how far the pitch drops in slow motion
                           (default 0.7, 0 = off)
  snd_qxpitch_self 0/1     also lower the pitch of your own sounds (default 0)
  sv_autosave_slot 0-20    load slot the autosave is copied to
                           (default 20, 0 = off)
  sv_autosave 0            turn autosave off completely
  autosave                 autosave right now
  qx_playerskill           saved PlayerSkill + 1 (-1 = nothing saved yet)
  newgame_map <map>        map that NEW GAME starts on (QuadEXQ ships
                           "newgame_map start" in autoexec.cfg; empty =
                           guess from the maps in the mod folder)


==============================================================================
 12. Known issues and notes
==============================================================================

  - This is a beta. Balance is still being tuned.
  - The boss can end up somewhere hard to find. impulse 150 shows how far
    away it is, and the BOSS arrow on the HUD shows the direction.
  - Near PlayerSkill 100 the game is meant to be very hard.
  - Teleporters and jump pads push a little weaker during bullet time.
  - If a map places some monsters only on certain difficulties (for
    example, "not on Easy"), the menu difficulty still decides those.
  - Coop and deathmatch are not supported.
  - EXQ's daikon monster is left out of this release.
  - The final map (end) is very hard. Take it slowly.


==============================================================================
 13. Version history
==============================================================================

  v0.6 beta
    Game:
    - The Rune Hunter: come back to start with 2+ runes and a rival calls
      you out to a first-to-10 duel (GuroFighter / G or K4B / Tres by
      PlayerSkill). Lose and it steals a rune.
    - EXQ Arena: duels are fought on a random map with "dm" in its name,
      plus Q1Edge and Towersp (maps you don't have, or with fewer than 2
      DM spawns, are skipped). Health, armor and weapons laid out as in DM.
    - Revenge match: while the hunter holds your rune, each death has a 30%
      chance to call a rematch. Win it back.
    - After a revenge match or an arena challenge you come back to where
      you died, not to the checkpoint.
    - Arena challenge: with no rune at stake, each death has a 30% chance
      to call a challenge. Win and keep the arena weapons and the score.
      10-0 is a PERFECT (10000 points).
    - Hunters: G fires SNG bursts, K4B leads grenades and sometimes fires
      rockets, Tres uses the LG and a jetpack. They bunnyhop and pick up
      health and armor. No autoaim against them.
    - Quake skill now follows PlayerSkill (PlayerSkill / 32), so EXQ
      monster swaps happen again (the Cyberdemon only at Nightmare).
    - Boss music starts when the boss sees you.
    - Fixes: Cyberdemon crash, double-counted monsters, Blarg's endless
      leap, armor display after the arena, missing sounds.
    QuadEXQ engine:
    - qx_arena / qx_return, the duel scoreboard (Tab) and hunter compass.
    - Colored skins for the hunters.
    - Single Player menu: Continue / New Game / Load / Save / Levels, in
      the real Quake menu font.
    - crosshair 3: a dot with two translucent arcs (scr_crosshairscale 2
      is a good size).
    - Opening the menu or quitting autosaves too, when it is safe.
    - Other mods and plain Quake get the safe autosave and CONTINUE too:
      the engine itself checks that it is calm before it saves.
    - ...and death checkpoints: when their progs restarts the map after a
      death, the engine loads the map's autosave instead
      (qx_checkpoints 0 turns this off).

  v0.5.1 beta
    - Runes are back to stock Quake rules: kept in savegames (CONTINUE),
      cleared by NEW GAME. The config copy from v0.5 is gone.
    - QuadEXQ engine: loading a save sets its runes at once, so a restart
      after loading can't bring back an older game's runes.

  v0.5 beta (first public release)
    Game:
    - Map bosses with scout squads, boss music, and a sealed exit until the
      boss dies.
    - Weapon balance reworked: a DPS ladder, and every weapon grows with
      PlayerSkill. Most "owning X boosts Y" bonuses removed.
    - Grenade Launcher: no more mid-air explosions, clusters cut from 30 to
      6, a weaker lightning chain, and blue lightning-grenade models while
      the chain is ready.
    - Rocket Launcher: faster rockets (1500) and direct hits of 120-140.
    - Super Nailgun: damage 16 -> 12, gentler homing; classic pickup model.
    - Lightning Gun: the same damage no matter how many cells you carry.
    - Your own explosions do 1/4 of their blast damage to you.
    - Nails and super nails do double damage to armored knights.
    - Adrenaline fills from taking hits and from kills, and drains when
      nothing is happening.
    - Health regeneration.
    - Enemies take damage in slime and lava.
    - Revenants are announced 3 seconds before they come back.
    - Vores split at most twice and share their health when they do.
    - Spike mines can be shot down.
    - Zombie backpacks carry 1 rocket.
    - The QuadUTF ogre's chainsaw no longer kills instantly below 50 health.
    - Chthon's health is no longer multiplied by PlayerSkill.
    - Map score, report card and the quadexq_stats.txt play log.
    - Fixed: the Nailgun sometimes not using ammo.
    QuadEXQ engine:
    - Death checkpoints, and autosaves only when it is safe.
    - CONTINUE / NEW GAME (with a start-map list) in the main menu.
    - Runes and PlayerSkill kept between launches.
    - Intermission report card.
    - Fixed the fire button sticking after you let go.

  Earlier (development builds)
    - PlayerSkill, bullet time, smarter enemies, jetpack, ammo drops, auto
      melee, modern aiming.
    - QuadEXQ engine: HUD, pitch-shifted slow motion, MP3 music, autosave,
      saved PlayerSkill.


==============================================================================
 14. Credits
==============================================================================

  QuadEXQ             Bob Kabura
  Base mod            EXQ - Bob Kabura
  Some weapon ideas   QuadUTF - Bob Kabura
  Boss music          track01 - Bob Kabura (made with Mureka, an AI music
                      generator)
  Bots                FrikBot - Ryan "Frika C" Smith
  Engine              Mark V - Baker and others (FitzQuake / QuakeSpasm lineage)
  Quake               id Software

  The engine is GPL v2, like Mark V. Its source code (and this mod's
  QuakeC source) is at:

    https://github.com/Bob-Kabra/QuadEXQ
