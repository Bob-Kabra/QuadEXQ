# CLAUDE.md

# QuadEXQ Development Guide

# Claude Rules

Never execute git push without explicit user approval.

Never create tags without approval.

Ask before modifying more than 10 files.

Keep engine behavior compatible with existing saves.

## Project Philosophy

QuadEXQ is a fast-paced dimensional chaos mod inspired by Quake.

Fun is more important than realism.

Do not optimize the fun out of the game.

Unexpected behavior may become a feature.

If something seems slightly insane but improves excitement,
consider that it may be intentional.


## Core Design Rules

Modern FPS conventions are not automatically improvements.

When in doubt, prefer Quake-style gameplay over modern shooter design.

The goal is not realism.

The goal is intensity.

The goal is not balance.

The goal is controlled chaos.

Do not simplify mechanics unless explicitly requested.


## Development Culture

If a feature appears strange, play with it before removing it.

If a bug is entertaining, investigate whether it should become a feature.

Unexpected gameplay may be promoted to official design.

Do not immediately remove weird behavior.

Ask before removing behavior that appears unusual.


## Scope Control

Do not expand the scope of tasks without approval.

Do not modify unrelated systems.

Keep commits focused and reversible.

One logical change per commit.

Commit frequently.

Use clear commit messages.


## Slipgate Philosophy

The Slipgate network is unstable.

Unexpected enemy arrivals are often intentional.

Do not automatically fix situations that appear chaotic.

Dimensional instability is a feature, not a bug.


## Gameplay Rules

Preserve adrenaline gameplay.

Preserve emergent gameplay whenever possible.

Preserve player skill expression.

Do not replace skill-based gameplay with automation.

Do not reduce challenge unless explicitly requested.


## Adrenaline System

High adrenaline states may alter visual perception.

Reduced color depth during adrenaline effects may be intentional.

Visual degradation can represent sensory overload.

Do not automatically remove visual distortion effects.

At extreme adrenaline levels, visual fidelity may decrease intentionally.


## Monster Design

Jetpack Knight intentionally uses a jetpack to charge directly at the player.

This behavior is intentional.

Do not attempt to make the monster more realistic, tactical, or cautious.

The monster is designed to be reckless and intimidating.

High aggression is preferred over realism.


## Engine Rules

Do not modify core engine systems unless explicitly requested.

Engine changes and gameplay changes should be committed separately.

Renderer changes should be isolated in their own commits.

Ask before large-scale engine refactors.


## Quake Principle

Quake is the primary design reference.

Modern game design is optional.

If Quake would do something weird,
consider it first.

If a feature feels old-school, brutal, unfair, chaotic, and fun,
it is probably heading in the correct direction.


## Developer Note

If something appears irrational but fun,
it may already be an intended feature.

If unsure whether something is a bug or a feature:

Assume it is a feature.

Then ask.

