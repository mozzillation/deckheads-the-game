# Monster Play Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give each monster a `PlayStyle` that controls its blackjack hit/stand decisions, replacing the hardcoded global threshold.

**Architecture:** `Monster` resource gets a `PlayStyle` enum export. A new static class `MonsterStrategy` owns the hit/stand logic per style. `CombatManager` delegates to `MonsterStrategy`; the now-redundant `CombatResolution.should_monster_hit()` is deleted.

**Tech Stack:** Godot 4.6, GDScript

---

## Files

- **Modify:** `scripts/monster/monster.gd` — add `PlayStyle` enum + `@export var play_style`
- **Create:** `scripts/combat/monster_strategy.gd` — static class with `should_hit()` logic
- **Modify:** `scripts/combat/combat_manager.gd:105-106` — delegate to `MonsterStrategy`
- **Modify:** `scripts/combat/combat_resolution.gd` — remove `should_monster_hit()` and `MONSTER_HIT_THRESHOLD`

---

### Task 1: Add PlayStyle to Monster

**Files:**
- Modify: `scripts/monster/monster.gd`

- [ ] **Step 1: Add PlayStyle enum and export**

Open `scripts/monster/monster.gd`. Replace the `# ---\n# Enums\n# ---` section (lines 4–14) so the file reads:

```gdscript
class_name Monster
extends Resource

# ---
# Enums
# ---

enum Type {
	UNKNOWN,
	BEAST,
	UNDEAD,
	DEMON,
	HUMAN,
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	MYTHIC,
}

enum PlayStyle {
	AGGRESSIVE,
	CAUTIOUS,
	RANDOM,
	TACTICAL,
}

# ---
# Variables
# ---

@export var name: String = "Undefined"
@export var type: Type = Type.UNKNOWN
@export var rarity: Rarity = Rarity.COMMON
@export var play_style: PlayStyle = PlayStyle.TACTICAL
@export var base_damage: int = 1
@export var hp: int = 1

var max_hp: int

# ---
# Lifecycle
# ---

func _init() -> void:
	max_hp = hp

# ---
# Functions
# ---

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)

func is_alive() -> bool:
	return hp > 0
```

- [ ] **Step 2: Reimport to generate UID**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: exits cleanly (possibly with import log output), no errors.

- [ ] **Step 3: Commit**

```bash
git add scripts/monster/monster.gd
git commit -m "feat: add PlayStyle enum to Monster resource"
```

---

### Task 2: Create MonsterStrategy

**Files:**
- Create: `scripts/combat/monster_strategy.gd`

- [ ] **Step 1: Create the file**

```gdscript
class_name MonsterStrategy

static func should_hit(style: Monster.PlayStyle, score: int) -> bool:
	match style:
		Monster.PlayStyle.AGGRESSIVE:
			return score < 19
		Monster.PlayStyle.CAUTIOUS:
			return score < 14
		Monster.PlayStyle.RANDOM:
			return randi() % 2 == 0
		Monster.PlayStyle.TACTICAL:
			return score < 17
		_:
			return false
```

Save to `scripts/combat/monster_strategy.gd`.

- [ ] **Step 2: Reimport**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: exits cleanly.

- [ ] **Step 3: Commit**

```bash
git add scripts/combat/monster_strategy.gd scripts/combat/monster_strategy.gd.uid
git commit -m "feat: add MonsterStrategy with PlayStyle hit logic"
```

---

### Task 3: Wire CombatManager and clean up CombatResolution

**Files:**
- Modify: `scripts/combat/combat_manager.gd`
- Modify: `scripts/combat/combat_resolution.gd`

- [ ] **Step 1: Update monster_should_hit() in CombatManager**

In `scripts/combat/combat_manager.gd`, replace lines 105–106:

```gdscript
func monster_should_hit() -> bool:
	return CombatResolution.should_monster_hit(monster_hand.score())
```

With:

```gdscript
func monster_should_hit() -> bool:
	return MonsterStrategy.should_hit(monster.play_style, monster_hand.score())
```

- [ ] **Step 2: Remove should_monster_hit() from CombatResolution**

In `scripts/combat/combat_resolution.gd`, remove the `MONSTER_HIT_THRESHOLD` constant and `should_monster_hit()` function. The file should become:

```gdscript
class_name CombatResolution

# ---
# Functions
# ---

static func player_wins_standoff(player_score: int, monster_score: int) -> bool:
	return player_score > monster_score

static func damage_to_player(monster: Monster) -> int:
	return monster.base_damage

static func damage_to_monster(_player: Player) -> int:
	return 1
```

- [ ] **Step 3: Verify scene runs**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: exits cleanly, no script parse errors.

- [ ] **Step 4: Commit**

```bash
git add scripts/combat/combat_manager.gd scripts/combat/combat_resolution.gd
git commit -m "refactor: delegate monster hit logic to MonsterStrategy"
```
