# Monster Play Style Design

## Summary

Monsters define their blackjack hit/stand logic through a `PlayStyle` enum exported on the `Monster` resource. A new static class `MonsterStrategy` owns the AI logic, keeping `CombatResolution` focused on resolution rules.

## Data Model

`Monster` gains a `PlayStyle` enum and an exported property:

```gdscript
enum PlayStyle { AGGRESSIVE, CAUTIOUS, RANDOM, TACTICAL }
@export var play_style: PlayStyle = PlayStyle.TACTICAL
```

Set per monster in the Godot inspector when authoring `.tres` resource files. `Monster` remains a pure data class — no behavior.

## MonsterStrategy

New file: `scripts/combat/monster_strategy.gd`

Static class with a single entry point:

```gdscript
static func should_hit(style: Monster.PlayStyle, score: int) -> bool
```

Strategy behaviors:

| Strategy   | Rule                          |
|------------|-------------------------------|
| AGGRESSIVE | Hit if score < 19             |
| CAUTIOUS   | Hit if score < 14             |
| RANDOM     | Hit randomly (randi() % 2)    |
| TACTICAL   | Hit if score < 17 (default)   |

## CombatManager

`monster_should_hit()` delegates to `MonsterStrategy`:

```gdscript
func monster_should_hit() -> bool:
	return MonsterStrategy.should_hit(monster.play_style, monster_hand.score())
```

## Removals

- `CombatResolution.should_monster_hit()` — deleted, replaced by `MonsterStrategy`
- `CombatResolution.MONSTER_HIT_THRESHOLD` constant — deleted
