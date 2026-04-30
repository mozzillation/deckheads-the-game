# Combat System — Blackjack Design

**Date:** 2026-04-30  
**Status:** Approved

---

## Overview

Combat in Deckheads is a round-based blackjack duel between the player and a monster. Each room in the roguelike presents a randomly selected monster. Combat continues until one side dies. Each round the deck resets, hands are dealt, the player hits or stands, then the monster plays automatically using its own dealer strategy.

---

## Data Model Changes

### `Monster` (extends `Resource`)

Add two fields:

```gdscript
@export var hp: int = 3
@export var dealer: MonsterDealer
```

`dealer` determines how the monster plays its hand. It is assigned per-monster in the editor, enabling each monster type to have a distinct playing style.

### `MonsterDealer` (extends `Resource`)

Base class with one method to override:

```gdscript
func should_hit(hand_total: int) -> bool
```

### `StandardDealer` (extends `MonsterDealer`)

Default implementation: hit below 17, stand at 17 and above.

```gdscript
func should_hit(hand_total: int) -> bool:
	return hand_total < 17
```

Future playing styles (e.g. "aggressive", "never hits twice") are new subclasses of `MonsterDealer` assigned to monster resources — no changes to `CombatManager`.

---

## `CombatManager` (extends `RefCounted`)

Located at `scripts/core/combat/combat_manager.gd`.

### Owned state

- `player: Player`
- `monster: Monster`
- `monster_hp: int` — initialized from `monster.hp` in `_init`; decremented directly (Monster is a Resource, has no `take_damage` method)
- `deck: Deck` — reset each round
- `player_hand: Array[CardRef]`
- `monster_hand: Array[CardRef]`

### Signals

```gdscript
signal card_dealt(target: String, card: CardRef, face_down: bool)
signal card_revealed(card: CardRef)       # monster hole card flipped on player_stand
signal player_bust(total: int)
signal monster_bust(total: int)
signal round_resolved(outcome: String)    # "player_win" | "monster_win" | "tie"
signal combat_ended(winner: String)       # "player" | "monster"
```

### Public API

```gdscript
func _init(p_player: Player, p_monster: Monster) -> void
func start_combat() -> void    # deals first round
func player_hit() -> void      # deals one card to player; may emit player_bust + round_resolved
func player_stand() -> void    # reveals hole card, runs monster turn, resolves round
```

The manager never waits. It emits a signal and returns immediately. The scene controller decides when to call the next method after animations finish.

### Hand total helpers

```gdscript
func _hand_total(hand: Array[CardRef]) -> int
```

Handles soft/hard Ace: starts with Ace = 11, converts to 1 if total exceeds 21. Applies `player.stats.hand_bonus` to the player's total only.

---

## Round Flow

1. **Deck reset** — `deck` is reconstructed and shuffled.
2. **Deal** — player receives 2 face-up cards; monster receives 1 face-up + 1 face-down. `card_dealt` emitted for each.
3. **Player turn** — scene calls `player_hit()` or `player_stand()` in response to UI input.
   - `player_hit()`: draws a card, emits `card_dealt`. If total > 21, emits `player_bust` then `round_resolved("monster_win")`.
   - `player_stand()`: emits `card_revealed` (hole card), then runs monster turn automatically.
4. **Monster turn** — manager loops `monster.dealer.should_hit(total)`. Each draw emits `card_dealt`. If total > 21, emits `monster_bust` then `round_resolved("player_win")`.
5. **Resolution** — compare totals. Emit `round_resolved` with outcome:
   - `"player_win"`: `monster_hp` decremented by 1. (`PlayerStats` has no damage stat yet; flat 1 is the value until one is added.)
   - `"monster_win"`: player takes `monster.base_damage` via `player.take_damage()`.
   - `"tie"`: no damage.
6. **Death check** — if `player.hp == 0` or `monster_hp == 0`, emit `combat_ended`. Otherwise start next round.

---

## `CombatController` (extends `Node`)

Located at `scenes/combat/combat_controller.gd`. Scene: `scenes/combat/combat.tscn`.

### Responsibilities

- Receives `Player` and `Monster` at scene entry.
- Instantiates `CombatManager` and connects all signals.
- Animates card deals, flips, and HP changes using `Tween` or `create_timer`.
- Enables/disables hit and stand buttons based on turn state and animation lock.
- Calls next manager method only after animation completes (`await`).

### Animation sequencing pattern

```gdscript
func _on_card_dealt(target: String, card: CardRef, face_down: bool) -> void:
    _set_buttons_enabled(false)
    await _animate_deal(target, card, face_down)
    _set_buttons_enabled(_is_player_turn)
```

### Monster deal pacing

```gdscript
@export var monster_deal_delay: float = 0.5
```

A short delay between each monster draw so the player can follow the monster's turn.

### Scene children (expected)

- Card nodes for player and monster hands
- HP bars for player and monster
- Hit and Stand buttons
- Round outcome label

---

## File Structure

```
scripts/core/combat/
	combat_manager.gd
scripts/core/monsters/
	monster.gd          (modified: add hp, dealer)
	monster_dealer.gd   (new base class)
	standard_dealer.gd  (new)
scenes/combat/
	combat.tscn
	combat_controller.gd
```

---

## Out of Scope (this iteration)

- `can_peek` mechanic (PlayerStats field exists, not yet wired)
- `extra_draws` beyond the standard hit loop
- Player damage stat (dealt as flat 1 for now)
- Monster playing style variants beyond `StandardDealer`
- Room/run integration (how monster is selected and passed to combat scene)
