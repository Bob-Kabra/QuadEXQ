==============================================================================
  QuadEXQ  v1.03
  "The harder you fight, the slower the world gets.
   The better you play, the smarter they get."
==============================================================================

QuadEXQ is a single-player overhaul of the Quake mod "EXQ" that rebuilds how
the game plays. It runs best with its own engine, QX.exe (a Mark V
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
        music\track02.mp3 ...   <- map music (optional: your own or
                                   Quake's; a QuadEXQ soundtrack for
                                   track02-11 is on the way)
        music\track12.mp3       <- "Quad EXQ Theme", the end map's
                                   music (included)
        sound\player\taunt.wav  <- auto-melee shout (optional)
      QX.exe             <- the QuadEXQ engine (recommended)

  Run:
    QX.exe -game QuadEXQ
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

    CONTINUE      resume from the latest autosave (qx_continue.sav)
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
  swaps too: the higher it is, the more Shamblers turn into Juggernauts
  or Vores, Ogres into QUTF Ogres, Zombies into Mummies, and so on.

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
    - you just SEE a Shambler, a Vore, a BFG fiend or the Cyber Delta: it
      climbs while one is in sight, and never stays under 200%

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
  * THE RUNE HUNTER: come back to the start map holding 1 to 3 runes and
    a rival who looks just like you calls you out -- every time. (With all
    4 runes the way to the end map is open, and it leaves you alone.)
    Three seconds later you are both taken to an arena for a deathmatch
    duel, first to 10 frags, and back to start when it's over, win or
    lose.
      - The arena is picked at random from every map you have with "dm"
        in its name (DM1-DM6 from registered Quake, custom DM maps in your
        folders) or named "d" + a number (D1, D12 ...), plus Q1Edge and
        Towersp (The Tower of Nightmare, by Bob Kabura, included in
        maps\). Maps you don't have are skipped.
        (Needs the QuadEXQ engine's qx_arena command; with other engines
        the arena is one of DM1-DM6 or Towersp.)
      - "Welcome to EXQ Arena!!" greets you when you arrive, and a moment
        later the arena's map name and title (e.g. dm6 / The Dark Zone).
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
                 rocket now and then), and fires the super shotgun twice
                 in a row from further out.
          Tres   uses a thunderbolt at mid range (no auto-aim: it aims
                 where you were a moment ago, so keep strafing) and jumps
                 around on a jetpack. He can't be locked by your auto-aim
                 or homing nails: you have to aim at him yourself.
      - Like a deathmatch bot it grabs health and armor: hurt, it runs
        for the nearest one it can see (shooting on the way), and it takes
        any it walks over. Deny it the megahealth and the red armor!
      - It goes for the Quad too. On Quad it does x4 damage and moves and
        fires 2.5 x as fast (glowing blue) for 30 seconds.
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
      - Win: 1000 points. A PERFECT 10 - 0 is worth the hunter: Tres
        10000, K4B / G 5000, GuroFighter 2000. The score is the
        arena map's own (its own line in the stats), not added to the map
        you came from.
        Lose: it takes the rune you got last and runs,
        and you are back in the start map.
      - Coming back from the duel itself doesn't call the next one.
      - !! REVENGE MATCH !!: while the hunter holds one of your runes,
        each death has a 20% chance of a revenge match instead of the
        checkpoint. You go to an arena with nothing to lose; win and the
        rune is yours again. Either way you come back to where you died
        (the last safe spot you stood on), with 100 health and 3 seconds
        of safety. (QuadEXQ engine.)
      - !! ARENA CHALLENGE !!: when it holds none of your runes, each death
        still has a 20% chance of a challenge instead: nothing to lose,
        and a win lets you keep the weapons you had in the arena (with
        some ammo); the arena scores 1000 (PERFECT 2000-10000). Back to where
        you died afterwards, like a revenge match.
      - !! DELTA TEAM !!: win a revenge match or an arena challenge and,
        back on the map, three allies come to help for the rest of that
        map. They fight like the Rune Hunter (Delta 1 super nailgun,
        Delta 2 rockets, Delta 3 thunderbolt, all super shotgun up
        close), follow you around, never hurt you and can't be hurt by
        you. No armor. A fallen member is back next to you 6 seconds later,
        but after 3 losses in all the team pulls out (Delta Labs calls).
      - Arenas need at least two deathmatch spawn spots; maps with fewer
        are never picked.
  * Chthon: hit him with the lightning trap. While he is stunned (and for a
    moment when he attacks) your normal weapons hurt him too.


==============================================================================
 6. Enemies
==============================================================================

  Dodging      Enemies sidestep shots flying at them, and sidestep when you
               aim at them while firing. They won't jump into pits or lava.
  Jet knights  Some knights, and half the Death Knights (Lord, Bane and
               Super ones too), charge at you with a jetpack. A hit does
               heavy damage and knocks you back. They drop their jetpack
               when killed (section 8).
  Revenants    A few seconds after you kill one, it teleports back to where
               it started and comes straight for you. It returns at most
               twice.
               Three seconds before it returns, you get a warning: a dark
               purple ball, lightning and sparks at the spot, and "The
               slipgate is raging..." with
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
               About one Vore in four is a VORE LORD: blood red, half again
               as tough, and with a Golden Left Hand of its own -- your
               rockets, grenades and nails that get close are swatted
               straight back at you. The Thunderbolt is a beam -- it can't
               swat that, nor the Thunderbolt's plasma. (The red needs the QuadEXQ engine; on another
               engine a Vore Lord just glows.)
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
      8 Lightning       300    auto-aim. Above PlayerSkill 50 with adrenaline
                               at 300% it also throws a plasma volley every
                               0.2 s, for free (the old Ion cannon)
        (the Ion cannon and the BFG are not weapons any more; the BFG turns
         up somewhere special)

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
    Jump again in mid-air to fire a burst. Every jetpack you find is one
    more stage, 6 in all:
      1-3  one more burst per jump, up to 3 before you land -- at half
           power (yellow on the HUD)
      4-6  bursts 1, 2, 3 go up to full power (orange); full ones fire first
    Picking one up at stage 6 gives +5 rockets. You keep the jetpack on
    later maps, and from one episode to the next. But lightning that hits
    you with no armor left fries a stage (at most one every 2 seconds).
    Dropped jetpacks vanish after 120 seconds.

  Auto melee:
    When an enemy is right in front of you, you hit it automatically: the
    axe if it is on your right, the Golden Left Hand if it is on your left
    -- even with the axe in hand (your left hand is free). The left hand is
    a glowing punch that throws you at the enemy, and it hits harder the
    higher your adrenaline and the faster you move. You can't shoot during
    the swing.
    At 250% adrenaline or more (or with Quad), enemy shots that come
    close from IN FRONT of you -- rockets, grenades, nails, magic -- are
    swatted back at whoever fired them, and they count as yours. Shots
    from behind still hit you.

  Health regeneration:
    Go 5 seconds without firing or taking damage and you heal up to 60 HP:
    5 HP per second, or 10 per second below 20 HP.
    You don't heal while holding the Lightning Gun: instead, while you
    hold it without firing, it drinks your health to make cells (up to
    100 cells). It stops at 1 HP -- it won't kill you.

  Ammo:
    You can carry up to 200 cells (Quake: 100). Shells, nails and rockets
    keep the usual limits.

  Weapon pickups:
    Picking up a weapon doesn't switch to it -- you switch with your keys,
    like in any modern shooter. The Thunderbolt is the exception: grab it
    and it's in your hands, as Quake intended. (qx_autoswitch changes
    this; section 11.)


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
    secret 100 / death -200 / clear without dying +3000 x the no-death
    streak: the 2nd map in a row without dying is +6000, the 3rd +9000 ..
    (one death and it starts over; on other engines always +3000)
    a whole episode without dying (from its first map to the rune) +10000

  Loops and high scores (QuadEXQ engine):
    Beat Shub-Niggurath and the end text turns over page by page (FIRE
    turns it sooner). The last page asks ONE MORE TIME? -- FIRE takes you
    round again: the start map, no runes, a new game's guns. Your
    PlayerSkill, your no-death streak and the run's score come along.
    From loop 2 on, every monster shoots back as it dies -- unless you
    blow it to pieces (lasers at you:
    1 on loop 2, a fan of 3 on loop 3, 5 from loop 4 -- the Golden Left
    Hand swats them back), monsters run 10% faster a loop (up to +30%),
    and the Cyber Delta sprays lasers whenever it dodges.
    Every loop is worth more: each map's score (and an arena win's) counts
    1.4 times the last loop's -- loop 2 x1.4, loop 3 x1.96, loop 4 x2.74 ..
    Down the Cyber Delta without dying in THE ENDER and the whole run's
    score doubles (FLAWLESS).
    The run is everything from New Game on, over every loop; its score is
    the high score to beat. Every map also keeps its own best
    (quadexq_scores.txt). The map report says RUN SCORE / HIGH SCORE /
    map best, and NEW HIGH SCORE! or MAP BEST! in gold when you set one.

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

  QX.exe is a QuadEXQ build of the Mark V engine. With any other mod it
  behaves like plain Mark V.
  Source code (GPL v2): https://github.com/Bob-Kabra/QuadEXQ

  - HUD (bottom center):
      ADR   Adrenaline bar and %.
            - a tick mark at 150%
            - orange above 150%, red at max, gold during Quad Damage
            - "TIME x0.7" (or similar) while the world is slowed
      SKL   PlayerSkill bar ("MAX" at 100)
      JET   Jet bursts left: yellow = half power, orange = full power
      BOSS  Direction and distance to the boss (while it is alive)
  - Sound pitch drops during bullet time.
  - Bullet time takes you back to 1996: as the world slows down, the
    picture loses pixels and colours and the crosshair turns into the old
    "+". At the slowest (Quad) it is 640x480 in the Quake palette with
    point-sampled textures. Console and menus stay sharp.
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
      - it is written to qx_continue.sav, which the CONTINUE menu entry
        loads -- a file of its own, so saving over a load slot can't lose
        it -- and copied to load slot 20 (s19.sav) for the Load menu
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
  impulse 156              Delta team test: call them in now.
  impulse 158              THE ENDER test: the Cyber Delta goes down now,
                           and the ending goes on as if you'd won

  QuadEXQ engine:
  scr_qxhud 0/1            show the HUD (default 1)
  snd_qxpitch 0-1          how far the pitch drops in slow motion
                           (default 0.7, 0 = off)
  snd_qxpitch_self 0/1     also lower the pitch of your own sounds (default 0)
  sv_autosave_slot 0-20    load slot the autosave is also copied to
                           (default 20, 0 = off: slot 20 is all yours;
                           CONTINUE doesn't need it)
  sv_autosave 0            turn autosave off completely
  autosave                 autosave right now
  qx_playerskill           saved PlayerSkill + 1 (-1 = nothing saved yet)
  qx_autoswitch 0/1/2      switch to a weapon you pick up: 0 = never,
                           1 = only the Thunderbolt (default), 2 = always
                           (stock Quake)
  qx_retro 0/1/2/4/5       bullet time 1996 look: 1 = software-style
                           shading (default), 2 = plain palette colours,
                           0 = off. 4 = ALWAYS 1996, in any game or mod
                           (plain Quake, Arcane Dimensions ..): 640x480,
                           the Quake palette. 5 = always, at your full
                           resolution (only the 256 colours). Also in
                           Options > Preferences > Retro 1996 and
                           Options > QuadEXQ Settings
  qx_checkpoints 0        plain Quake / other mods: restart the map on
                           death instead of loading the checkpoint
  qx_centerscale 0.5-4     size of the messages in the middle of the
                           screen and of the end text (default 1.5,
                           1 = stock)
  qx_centerreadtime <s>    a longer message stays up this much longer for
                           each line (default 0.6, 0 = stock)
  qx_achievements          list the achievements (the ones still to find
                           about THE ENDER show as ???)
  qx_runstats              your stats over every game: kills and deaths
                           by monster, time, score, maps and episodes
                           cleared without dying, the best no-death streak,
                           the high score and this run's score and loop
                           (also written to quadexq_stats.txt)
  qx_runreset              start the stats over (the achievements, the high
                           score and the map bests stay)
  qx_hitchlog 30           stutters? log every frame over 30 ms and where
                           its time went (console, quadexq_hitch.txt).
                           0 = off (default)
  sv_protocol 999          network protocol (default 999, as QuakeSpasm:
                           big maps past +-4096; 666 = FitzQuake)
  crosshair 0-9            0 none, 1 Quake "+", 2 dot, 3 dot + arcs,
                           4 gap cross, 5 ring, 6 X, 7 chevron,
                           8 brackets, 9 scope
  crosshair_color 0-7      white, red, green, yellow, cyan, orange, pink,
                           blue
  crosshair_alpha 0.1-1    how solid the crosshair is (default 1)
  sndspeed 11025/22050/44100  sound mixing rate, after a restart (also in
                           Options > Preferences > Sound Quality)

  Options > QuadEXQ Settings has the QuadEXQ settings in one place: Retro
  1996, the QX HUD, weapon auto switch, checkpoints, message size and
  time, and the crosshair (shape, colour, alpha, scale, with a preview),
  per-weapon crosshairs and the status bar scale.

  The crosshair, status bar (viewsize, scr_sbar*, scr_qxhud), the message
  size and time and the qx_ settings are also saved to qx_config.cfg in the game's own folder on
  quit, and read last at start: every mod keeps its own, whatever its
  autoexec.cfg says. A mod with none yet starts from id1's.
  newgame_map <map>        map that NEW GAME starts on (QuadEXQ ships
                           "newgame_map start" in autoexec.cfg; empty =
                           guess from the maps in the mod folder)


==============================================================================
 12. Known issues and notes
==============================================================================

  - Balance may still change in later updates.
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

  v1.03
    QuadEXQ engine:
    - The engine is QX.exe now (was quadexq.exe), with a new icon: a
      framed blue QX. Delete the old quadexq.exe if you like.
    - Options > QuadEXQ Settings: the QuadEXQ settings in one menu, saved
      per game in qx_config.cfg.
    - Crosshairs: ten shapes (crosshair 0-9), eight colours
      (crosshair_color) and alpha (crosshair_alpha), with a preview in
      the menu.
    - Sound Quality (11 / 22 / 44 kHz) in Options > Preferences.
    - Screenshots are named QX_<game>_0000.png (QX_quadexq_, QX_ad_,
      QX_id1_ ..), so you know which mod each one is from.
    - The Levels menu lists only maps Quake can load (no Half-Life or
      Quake 3 maps), and a Half-Life map's textures from an outside .wad
      show as a checkerboard instead of crashing.
    - The 2021 re-release progs (Dimension of the Past / Machine) no
      longer fill the screen with "campaign not found".

  v1.02a
    QuadEXQ engine:
    - Scourge of Armagon's start-up demo plays its music now: a demo's
      forced CD track ignores a space before the number (it read as
      track 98).
    - qx_config.cfg is kept per game (QuadEXQ/, ad/ ..): every mod its
      own crosshair, HUD and qx_ settings. A mod with none yet starts
      from id1's.

  v1.02
    Game:
    - The jetpack has 6 stages: 1-3 add half-power bursts (yellow), 4-6
      bring them to full power (orange). It stays with you from one
      episode to the next, but lightning with no armor left fries a stage.
    - impulse 158: in THE ENDER's fight, the Cyber Delta goes down now
      (a test, to see the ending).
    - Loop 2 on: every monster shoots back as it dies, unless gibbed (1,
      3, then 5 lasers), monsters run faster (+10% a loop, up to +30%), and the
      Cyber Delta sprays lasers as it dodges -- a nod to Chou Ren Sha 68k.
    - Down the Cyber Delta without a death in THE ENDER: the run's score x2.
    - Scores grow every loop: x1.4, x1.96, x2.74 ..
    - CONTINUE has a save file of its own, qx_continue.sav: saving over
      load slot 20 no longer loses it. (QuadEXQ engine)
    - qx_hitchlog <ms>: logs a stutter and where its time went.

  v1.01
    Game:
    - Round again: after the end text, ONE MORE TIME? takes you back to
      the start map for another loop -- no runes, a new game's guns, but
      your PlayerSkill, no-death streak and score carry on. A high score
      for the whole run, a best for every map, both on the map report.
      The end text's pages turn with FIRE, and the end map counts as a
      cleared map now.
    - No deaths, more score: each map in a row without dying is worth
      3000 more than the last (+3000, +6000, +9000 ..), and a whole
      episode without dying is +10000. The stats count the maps and
      episodes cleared without dying, and the best streak.
    - The raging slipgate's warning is a dark purple ball now.
    QuadEXQ engine:
    - The 1996 look (qx_retro): the colour of pain, powerups and water goes
      on like the software renderer's palette shift -- the Ring of Shadows
      no longer whites the view out.

  v1.00 (v0.96 beta was never released)
    Game:
    - The end map has a story of its own now. Play it to the end.
      The Cyber Delta there fires big green rockets of its own: too heavy
      for the Golden Left Hand to swat back (it tells you so), and its
      scouts get tougher with your PlayerSkill.
      (It needs maps/ender.bsp and music/track12.mp3, both in the zip.)
    - The Ion cannon and the BFG left the weapon slots. The Ion's plasma
      is the Thunderbolt's bonus now (PlayerSkill above 50 and 300%
      adrenaline); the BFG turns up somewhere special, as a big green ball.
    - The BFG fiend (demon2) and the Juggernaut fire the same green ball.
    - The sight of a Shambler, a Vore or a BFG fiend gets the adrenaline
      going; Shub-Niggurath in sight means 300% at once.
    - The Golden Left Hand only swats shots coming from in front of you.
    - Rune Hunters take the axe to you if you get right in their face
      while you're nearly dead.
    - The Vore Lord no longer swats plasma back.
    - The Cyberdemon has left the main game: Shamblers no longer turn into
      one (that roll gives a BFG fiend now).
    - BFG chain lightning never jumps to Delta Team.
    - Score: a clear without dying is +3000 (was +300). An arena win is
      scored as the arena map's own clear, not added to the map you came
      from; a PERFECT 10 - 0 is worth the hunter (Tres 10000, K4B / G
      5000, GuroFighter 2000).
    - Achievements (42, a few of them not exactly flattering) and stats:
      kills and deaths by monster, time and score, adding up over every
      game you play. qx_achievements and qx_runstats in the console.
      (QuadEXQ engine)
    - Other engines (the DarkPlaces family such as Zircon, QuakeSpasm-Spiked
      ..): no more zoomed-in view a second after the start, and where the
      engine can't slow the world down there is no bullet time.
    QuadEXQ engine:
    - Retro 1996 in Options > Preferences (qx_retro): off, in bullet time,
      or always -- the DOS Quake look.
    - Bigger messages in the middle of the screen (and the end text), and
      longer ones stay up longer: qx_centerscale, qx_centerreadtime.
    - Frame interpolation in the menu, one by one: model animation,
      movement and stairs. Effects get "QMB + Classic Bolt".
    - The BFG glows green: its ball, and the gun in your hands (a new
      high-resolution skin).
    - With the ADR / SKL bars on the HUD, the 150-250% adrenaline and
      PlayerSkill banners stay quiet; BULLET TIME still announces.

  v0.9 beta
    Game:
    - One Vore in four is a VORE LORD: blood red, half again as tough,
      and it swats your rockets, grenades and nails straight back at you.
    - Bullet time on a moving lift: you ride it smoothly (no shaking).
    QuadEXQ engine:
    - Plays Arcane Dimensions: bigger map limits (leafs, lightmaps), a
      512 MB default heap, protocol 999 (now the default) and the signon
      split into buffers like QuakeSpasm. Big maps such as ad_tears and
      ad_sepulcher load and play.
    - See-through waterfalls and walls no longer white out (their glowing
      pixels are lit like the rest).
    - qx_retro 4: always the 1996 look (640x480, the Quake palette) in any
      game or mod; qx_retro 5: the same at full resolution.
    - Crosshair, status bar and qx_ settings shared by every game
      (id1/qx_config.cfg).
    - The menu's Continue matches the other entries under mods with their
      own menu art.
    - A new exe icon: the QuadEXQ logo, glowing blue.

  v0.8 beta
    Game:
    - The Golden Left Hand: auto melee hits an enemy on your left with a
      glowing left-handed punch (the axe takes the right). It throws you
      at the enemy and hits harder with more adrenaline and speed. It
      works with the axe in hand too.
    - At 250% adrenaline or more (or on Quad), enemy rockets, grenades,
      nails and magic that come close are swatted back at whoever fired
      them.
    - The Rune Hunter calls on every visit to start with 1 to 3 runes
      (none with all 4). K4B fires a double-tap super shotgun, and every
      hunter goes for the Quad: x4 damage, 2.5 x as fast, glowing blue.
    - A death calls an arena fight 20% of the time (was 30%), and coming
      back from the arena makes that spot your checkpoint.
    - Half the Death Knights (Lord, Bane and Super ones too) charge with a
      jetpack, and drop it.
    - Carry up to 200 cells.
    - Picking up a weapon switches to it only for the Thunderbolt
      (qx_autoswitch: 0 never, 1 Thunderbolt, 2 always).
    - The Thunderbolt's health drain stops at 1 HP: no more self-destruct.
    - The eel's zap does 3/4 of the damage.
    QuadEXQ engine:
    - The left hand is drawn left-handed and glowing.
    - qx_autoswitch. The project file is QuadEXQ.cbp.

  v0.7.1 beta (v0.7 beta was never released)
    Game:
    - DELTA TEAM: win a revenge match or an arena challenge and three
      allies fight beside you for the rest of that map (SNG / RL / LG,
      no armor, back 6 s after going down). After 3 losses Delta Labs
      calls them back. Their kills show in the map report.
    - The Shambler no longer takes x2.5 from explosions.
    - Arrive in an arena and its map name and title are shown.
    - Arenas: maps named "d" + a number (D1, D12 ...) are candidates too.
    - Jetpack: each one you find adds a burst per jump (1, 2, then 3).
    - Fix: Delta team (and a won-back rune) could be lost on the way back
      from the arena.
    QuadEXQ engine:
    - Bullet time takes you back to 1996 (qx_retro): fewer pixels and
      colours as the world slows, the old "+" crosshair, and at the
      slowest 640x480 in the Quake palette with point-sampled textures.

  v0.6.1 beta
    Game:
    - After a revenge match or an arena challenge you come back to where
      you died (your last safe footing), not to the checkpoint, with 3
      seconds of safety.
    - Map report: auto melee swings count as the Axe.
    - The Enforcer laser uses Quake's own model again.
    QuadEXQ engine:
    - Opening the menu or quitting autosaves too, when it is safe, so
      stopping right after a map change keeps the new map.
    - Plain Quake and other mods get the safe autosave and CONTINUE too:
      the engine itself checks that it is calm before it saves.
    - ...and death checkpoints: when their progs restarts the map after a
      death, the engine loads the map's autosave instead
      (qx_checkpoints 0 turns this off).

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
    - Arena challenge: with no rune at stake, each death has a 30% chance
      to call a challenge. Win and keep the arena weapons.
      10-0 is a PERFECT (2000-10000 points by hunter, the arena map's own
      score).
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
  Music               Bob Kabura. All of QuadEXQ's music (the track01
                      boss theme, track12 "Quad EXQ Theme" for the end
                      map, and the coming soundtrack) is made with
                      Mureka, an AI music generator.
  Mega Enforcer, Riot Gun and Thunderbolt models
                      Zerstorer - Nihilism Unlimited
  Bots                FrikBot - Ryan "Frika C" Smith
  Engine              Mark V - Baker and others (FitzQuake / QuakeSpasm lineage)
  Quake               id Software

  The engine is GPL v2, like Mark V. Its source code (and this mod's
  QuakeC source) is at:

    https://github.com/Bob-Kabra/QuadEXQ
