# Combat System — Blackjack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the blackjack combat system: a pure-logic `CombatManager` (RefCounted) that emits signals, and an animation-ready `CombatController` (Node) that queues those signals and drives Tweens/timers before re-enabling player input.

**Architecture:** `CombatManager` owns all rules and state, emitting fine-grained signals. `CombatController` receives them via an event queue, plays animations sequentially using `await`, and calls no manager method until the relevant animation completes. Monster dealer strategy is a `Resource` subclass on the `Monster` resource, making future playing styles a new file with no changes to `CombatManager`.

**Tech Stack:** Godot 4.6, GDScript 2.0. Logic classes extend `RefCounted`; dealer strategy extends `Resource`; scene controller extends `Node`.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `scripts/core/monsters/monster_dealer.gd` | Base class — `should_hit(total) -> bool` |
| Create | `scripts/core/monsters/standard_dealer.gd` | Hit below 17, stand at 17+ |
| Modify | `scripts/core/monsters/monster.gd` | Add `hp: int` and `dealer: MonsterDealer` |
| Create | `scripts/core/combat/combat_manager.gd` | All blackjack rules, state, and signals |
| Create | `scenes/combat/combat_controller.gd` | Event queue, animation stubs, button gating |
| Create | `scenes/combat/combat.tscn` | Minimal scene shell |
| Create | `tests/test_combat_manager.gd` | Headless tests for CombatManager logic |

---

### Task 1: MonsterDealer base class + StandardDealer

**Files:**
- Create: `scripts/core/monsters/monster_dealer.gd`
- Create: `scripts/core/monsters/standard_dealer.gd`
- Create: `tests/test_combat_manager.gd`

- [ ] **Create `scripts/core/monsters/monster_dealer.gd`**

```gdscript
class_name MonsterDealer
extends Resource

func should_hit(hand_total: int) -> bool:
	return false
```

- [ ] **Create `scripts/core/monsters/standard_dealer.gd`**

```gdscript
class_name StandardDealer
extends MonsterDealer

func should_hit(hand_total: int) -> bool:
	return hand_total < 17
```

- [ ] **Run headless import to register new class names**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: completes without errors; `.uid` files appear next to both new `.gd` files.

- [ ] **Create `tests/test_combat_manager.gd`**

```gdscript
extends SceneTree

var _pass := 0
var _fail := 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
		print("PASS: %s" % msg)
	else:
		_fail += 1
		print("FAIL: %s" % msg)

func _init() -> void:
	test_standard_dealer()
	print("\n%d passed, %d failed" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)

func test_standard_dealer() -> void:
	var dealer := StandardDealer.new()
	_check(dealer.should_hit(16), "StandardDealer hits on 16")
	_check(not dealer.should_hit(17), "StandardDealer stands on 17")
	_check(not dealer.should_hit(21), "StandardDealer stands on 21")
	_check(dealer.should_hit(0), "StandardDealer hits on 0")
```

- [ ] **Run test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat_manager.gd --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected:
```
PASS: StandardDealer hits on 16
PASS: StandardDealer stands on 17
PASS: StandardDealer stands on 21
PASS: StandardDealer hits on 0

4 passed, 0 failed
```

- [ ] **Commit**

```bash
git add scripts/core/monsters/monster_dealer.gd scripts/core/monsters/standard_dealer.gd tests/test_combat_manager.gd
git commit -m "feat: add MonsterDealer base class and StandardDealer"
```

---

### Task 2: Add `hp` and `dealer` to Monster

**Files:**
- Modify: `scripts/core/monsters/monster.gd`
- Modify: `tests/test_combat_manager.gd`

- [ ] **Add fields to `scripts/core/monsters/monster.gd`**

After `@export var base_damage: int = 1` add:

```gdscript
@export var hp: int = 3
@export var dealer: MonsterDealer
```

- [ ] **Add test — append `test_monster_fields()` call to `_init()` before the print line**

```gdscript
	test_monster_fields()
```

Then add the function:

```gdscript
func test_monster_fields() -> void:
	var m := Monster.new()
	m.hp = 5
	m.dealer = StandardDealer.new()
	_check(m.hp == 5, "Monster hp field stores value")
	_check(m.dealer.should_hit(10), "Monster dealer is accessible")
```

- [ ] **Run test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat_manager.gd --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: `6 passed, 0 failed`

- [ ] **Commit**

```bash
git add scripts/core/monsters/monster.gd tests/test_combat_manager.gd
git commit -m "feat: add hp and dealer fields to Monster"
```

---

### Task 3: CombatManager scaffold + `_hand_total`

**Files:**
- Create: `scripts/core/combat/combat_manager.gd`
- Modify: `tests/test_combat_manager.gd`

`_hand_total` implements the soft/hard Ace rule: each Ace starts as 11; when the total exceeds 21 and there are Aces remaining, reduce one Ace from 11 to 1 (subtract 10) and repeat. `_player_total()` adds `player.stats.hand_bonus` on top.

- [ ] **Create `scripts/core/combat/combat_manager.gd`**

```gdscript
class_name CombatManager
extends RefCounted

# ---
# Signals
# ---

signal card_dealt(target: String, card: CardRef, face_down: bool)
signal card_revealed(card: CardRef)
signal player_turn_ready
signal player_bust(total: int)
signal monster_bust(total: int)
signal round_resolved(outcome: String)
signal combat_ended(winner: String)

# ---
# Variables
# ---

var player: Player
var monster: Monster
var monster_hp: int
var deck: Deck
var player_hand: Array[CardRef] = []
var monster_hand: Array[CardRef] = []

# ---
# Lifecycle
# ---

func _init(p_player: Player, p_monster: Monster) -> void:
	player = p_player
	monster = p_monster
	monster_hp = p_monster.hp

# ---
# Functions
# ---

func start_combat() -> void:
	_start_round()

func player_hit() -> void:
	pass

func player_stand() -> void:
	pass

func _start_round() -> void:
	deck = Deck.new()
	player_hand.clear()
	monster_hand.clear()

func _deal_to_player() -> void:
	var card := deck.draw()
	player_hand.append(card)
	card_dealt.emit("player", card, false)

func _deal_to_monster(face_down: bool) -> void:
	var card := deck.draw()
	monster_hand.append(card)
	card_dealt.emit("monster", card, face_down)

func _hand_total(hand: Array[CardRef]) -> int:
	var total := 0
	var aces := 0
	for card in hand:
		if card.rank == CardRef.Rank.ACE:
			aces += 1
		total += card.blackjack_value()
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func _player_total() -> int:
	return _hand_total(player_hand) + player.stats.hand_bonus

func _monster_total() -> int:
	return _hand_total(monster_hand)

func _compare_hands() -> String:
	var pt := _player_total()
	var mt := _monster_total()
	if pt > mt:
		return "player_win"
	elif mt > pt:
		return "monster_win"
	else:
		return "tie"

func _resolve_round(_outcome: String) -> void:
	pass
```

- [ ] **Run headless import**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --import --path /Users/giuliano.mozzillo/Games/deckheads
```

- [ ] **Add helper factories and `_hand_total` tests — add `test_hand_total()` call to `_init()` before print, then add:**

```gdscript
func _make_player() -> Player:
	var stats := PlayerStats.new()
	stats.base_max_hp = 10
	return Player.new(stats)

func _make_monster() -> Monster:
	var m := Monster.new()
	m.hp = 3
	m.base_damage = 1
	m.dealer = StandardDealer.new()
	return m

func test_hand_total() -> void:
	var mgr := CombatManager.new(_make_player(), _make_monster())

	var two_tens: Array[CardRef] = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.SPADES),
	]
	_check(mgr._hand_total(two_tens) == 20, "_hand_total: two tens = 20")

	var ace_ten: Array[CardRef] = [
		CardRef.new(CardRef.Rank.ACE, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.SPADES),
	]
	_check(mgr._hand_total(ace_ten) == 21, "_hand_total: ace + ten = 21 (soft)")

	var ace_ten_five: Array[CardRef] = [
		CardRef.new(CardRef.Rank.ACE, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.SPADES),
		CardRef.new(CardRef.Rank.FIVE, CardRef.Suit.CLUBS),
	]
	_check(mgr._hand_total(ace_ten_five) == 16, "_hand_total: ace + ten + five = 16 (hard)")

	var two_aces: Array[CardRef] = [
		CardRef.new(CardRef.Rank.ACE, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.ACE, CardRef.Suit.SPADES),
	]
	_check(mgr._hand_total(two_aces) == 12, "_hand_total: two aces = 12")

	# hand_bonus is added in _player_total, not _hand_total
	var bonus_player := _make_player()
	bonus_player.stats.hand_bonus = 2
	var mgr_bonus := CombatManager.new(bonus_player, _make_monster())
	mgr_bonus.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.SEVEN, CardRef.Suit.SPADES),
	]
	_check(mgr_bonus._player_total() == 19, "_player_total: hand_bonus applied (17 + 2 = 19)")
```

- [ ] **Run test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat_manager.gd --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: `11 passed, 0 failed`

- [ ] **Commit**

```bash
git add scripts/core/combat/combat_manager.gd tests/test_combat_manager.gd
git commit -m "feat: CombatManager scaffold with _hand_total and soft/hard Ace"
```

---

### Task 4: CombatManager — deal flow (`_start_round` + `player_turn_ready`)

**Files:**
- Modify: `scripts/core/combat/combat_manager.gd`
- Modify: `tests/test_combat_manager.gd`

`_start_round` deals 2 cards to the player (face up) and 2 to the monster (first face up, second face down). After dealing, it emits `player_turn_ready` so the controller knows to enable the Hit/Stand buttons.

- [ ] **Replace `_start_round` body in `combat_manager.gd`**

```gdscript
func _start_round() -> void:
	deck = Deck.new()
	player_hand.clear()
	monster_hand.clear()
	_deal_to_player()
	_deal_to_player()
	_deal_to_monster(false)
	_deal_to_monster(true)
	player_turn_ready.emit()
```

- [ ] **Add deal flow test — add `test_start_combat_deal()` call to `_init()` before print, then add:**

```gdscript
func test_start_combat_deal() -> void:
	var mgr := CombatManager.new(_make_player(), _make_monster())
	var events: Array = []
	var turn_ready: Array = []
	mgr.card_dealt.connect(func(target, _c, face_down): events.append({"t": target, "fd": face_down}))
	mgr.player_turn_ready.connect(func(): turn_ready.append(true))
	mgr.start_combat()

	_check(events.size() == 4, "deal: four card_dealt events")
	_check(events[0]["t"] == "player" and not events[0]["fd"], "deal: player card 1 face up")
	_check(events[1]["t"] == "player" and not events[1]["fd"], "deal: player card 2 face up")
	_check(events[2]["t"] == "monster" and not events[2]["fd"], "deal: monster card 1 face up")
	_check(events[3]["t"] == "monster" and events[3]["fd"], "deal: monster card 2 face down")
	_check(mgr.player_hand.size() == 2, "deal: player hand has 2 cards")
	_check(mgr.monster_hand.size() == 2, "deal: monster hand has 2 cards")
	_check(turn_ready.size() == 1, "deal: player_turn_ready emitted once")
```

- [ ] **Run test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat_manager.gd --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: `18 passed, 0 failed`

- [ ] **Commit**

```bash
git add scripts/core/combat/combat_manager.gd tests/test_combat_manager.gd
git commit -m "feat: implement deal flow and player_turn_ready signal"
```

---

### Task 5: CombatManager — `player_hit` + bust detection

**Files:**
- Modify: `scripts/core/combat/combat_manager.gd`
- Modify: `tests/test_combat_manager.gd`

`player_hit` draws one card for the player. If the resulting total exceeds 21, it emits `player_bust` and resolves the round immediately as `"monster_win"`. The `_resolve_round` stub (pass) is enough for this task; full implementation follows in Task 7.

- [ ] **Replace `player_hit` stub in `combat_manager.gd`**

```gdscript
func player_hit() -> void:
	_deal_to_player()
	var total := _player_total()
	if total > 21:
		player_bust.emit(total)
		_resolve_round("monster_win")
```

- [ ] **Add player_hit test — add `test_player_hit()` call to `_init()` before print, then add:**

```gdscript
func test_player_hit() -> void:
	var mgr := CombatManager.new(_make_player(), _make_monster())
	mgr.start_combat()

	# Force player hand to 20; next card from deck is a Ten → bust at 30
	mgr.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.SPADES),
	]
	mgr.deck._cards = [CardRef.new(CardRef.Rank.TEN, CardRef.Suit.CLUBS)]

	var busted: Array = []
	var resolved: Array = []
	var dealt: Array = []
	mgr.player_bust.connect(func(t): busted.append(t))
	mgr.round_resolved.connect(func(o): resolved.append(o))
	mgr.card_dealt.connect(func(target, _c, _fd): dealt.append(target))

	mgr.player_hit()
	_check(dealt.size() == 1 and dealt[0] == "player", "player_hit: deals one card to player")
	_check(busted.size() == 1 and busted[0] == 30, "player_hit: player_bust emitted with total 30")
	_check(resolved.size() == 1 and resolved[0] == "monster_win", "player_hit: round resolved as monster_win on bust")
```

- [ ] **Run test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat_manager.gd --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: `21 passed, 0 failed`

- [ ] **Commit**

```bash
git add scripts/core/combat/combat_manager.gd tests/test_combat_manager.gd
git commit -m "feat: implement player_hit with bust detection"
```

---

### Task 6: CombatManager — `player_stand` + monster turn

**Files:**
- Modify: `scripts/core/combat/combat_manager.gd`
- Modify: `tests/test_combat_manager.gd`

`player_stand` emits `card_revealed` for the hole card, then loops `monster.dealer.should_hit()` until the monster stands or busts. If the monster busts, resolves as `"player_win"` immediately. Otherwise calls `_compare_hands()` to determine the outcome.

- [ ] **Replace `player_stand` stub in `combat_manager.gd`**

```gdscript
func player_stand() -> void:
	card_revealed.emit(monster_hand[1])
	while monster.dealer.should_hit(_monster_total()):
		_deal_to_monster(false)
		if _monster_total() > 21:
			monster_bust.emit(_monster_total())
			_resolve_round("player_win")
			return
	_resolve_round(_compare_hands())
```

- [ ] **Add player_stand tests — add `test_player_stand()` call to `_init()` before print, then add:**

```gdscript
func test_player_stand() -> void:
	# tie: player 18, monster 18, dealer stands
	var mgr := CombatManager.new(_make_player(), _make_monster())
	mgr.start_combat()
	mgr.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.EIGHT, CardRef.Suit.SPADES),
	]
	mgr.monster_hand = [
		CardRef.new(CardRef.Rank.NINE, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.NINE, CardRef.Suit.SPADES),
	]
	var revealed: Array = []
	var resolved: Array = []
	mgr.card_revealed.connect(func(c): revealed.append(c))
	mgr.round_resolved.connect(func(o): resolved.append(o))
	mgr.player_stand()
	_check(revealed.size() == 1, "player_stand: hole card revealed")
	_check(resolved.size() == 1 and resolved[0] == "tie", "player_stand: tie when totals equal")

	# monster bust: monster has 16, dealer hits, next card is Ten → 26
	var mgr2 := CombatManager.new(_make_player(), _make_monster())
	mgr2.start_combat()
	mgr2.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.SIX, CardRef.Suit.SPADES),
	]
	mgr2.monster_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.SIX, CardRef.Suit.SPADES),
	]
	mgr2.deck._cards = [CardRef.new(CardRef.Rank.TEN, CardRef.Suit.CLUBS)]
	var busted: Array = []
	var resolved2: Array = []
	mgr2.monster_bust.connect(func(t): busted.append(t))
	mgr2.round_resolved.connect(func(o): resolved2.append(o))
	mgr2.player_stand()
	_check(busted.size() == 1 and busted[0] == 26, "player_stand: monster_bust emitted with total 26")
	_check(resolved2.size() == 1 and resolved2[0] == "player_win", "player_stand: player_win on monster bust")

	# player wins on higher total: player 20, monster 18, dealer stands
	var mgr3 := CombatManager.new(_make_player(), _make_monster())
	mgr3.start_combat()
	mgr3.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.SPADES),
	]
	mgr3.monster_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.EIGHT, CardRef.Suit.SPADES),
	]
	var resolved3: Array = []
	mgr3.round_resolved.connect(func(o): resolved3.append(o))
	mgr3.player_stand()
	_check(resolved3.size() == 1 and resolved3[0] == "player_win", "player_stand: player_win on higher total")
```

- [ ] **Run test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat_manager.gd --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: `28 passed, 0 failed`

- [ ] **Commit**

```bash
git add scripts/core/combat/combat_manager.gd tests/test_combat_manager.gd
git commit -m "feat: implement player_stand with monster turn and bust"
```

---

### Task 7: CombatManager — round resolution + combat loop

**Files:**
- Modify: `scripts/core/combat/combat_manager.gd`
- Modify: `tests/test_combat_manager.gd`

`_resolve_round` emits `round_resolved`, applies damage (`monster_hp -= 1` on player win; `player.take_damage(monster.base_damage)` on monster win; nothing on tie), then checks for death. If combat is over, emits `combat_ended`. Otherwise calls `_start_round()` to begin the next round.

- [ ] **Replace `_resolve_round` stub in `combat_manager.gd`**

```gdscript
func _resolve_round(outcome: String) -> void:
	round_resolved.emit(outcome)
	match outcome:
		"player_win":
			monster_hp -= 1
		"monster_win":
			player.take_damage(monster.base_damage)
	if monster_hp <= 0:
		combat_ended.emit("player")
	elif not player.is_alive():
		combat_ended.emit("monster")
	else:
		_start_round()
```

- [ ] **Add resolution tests — add `test_resolution()` call to `_init()` before print, then add:**

```gdscript
func test_resolution() -> void:
	# player wins, monster hp reaches 0 → combat ends
	var m1 := _make_monster()
	m1.hp = 1
	var mgr := CombatManager.new(_make_player(), m1)
	mgr.start_combat()
	mgr.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.NINE, CardRef.Suit.SPADES),
	]
	mgr.monster_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.EIGHT, CardRef.Suit.SPADES),
	]
	var ended: Array = []
	mgr.combat_ended.connect(func(w): ended.append(w))
	mgr.player_stand()
	_check(mgr.monster_hp == 0, "resolution: monster_hp reaches 0")
	_check(ended.size() == 1 and ended[0] == "player", "resolution: combat_ended with player winner")

	# monster wins, player hp reaches 0 → combat ends
	var p2 := _make_player()
	p2.hp = 1
	var m2 := _make_monster()
	m2.base_damage = 1
	var mgr2 := CombatManager.new(p2, m2)
	mgr2.start_combat()
	mgr2.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.SIX, CardRef.Suit.SPADES),
	]
	mgr2.monster_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.NINE, CardRef.Suit.SPADES),
	]
	var ended2: Array = []
	mgr2.combat_ended.connect(func(w): ended2.append(w))
	mgr2.player_stand()
	_check(p2.hp == 0, "resolution: player hp reaches 0")
	_check(ended2.size() == 1 and ended2[0] == "monster", "resolution: combat_ended with monster winner")

	# tie: no damage, next round starts (player hand resets to 2 new cards)
	var mgr3 := CombatManager.new(_make_player(), _make_monster())
	mgr3.start_combat()
	mgr3.player_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.EIGHT, CardRef.Suit.SPADES),
	]
	mgr3.monster_hand = [
		CardRef.new(CardRef.Rank.TEN, CardRef.Suit.HEARTS),
		CardRef.new(CardRef.Rank.EIGHT, CardRef.Suit.SPADES),
	]
	mgr3.player_stand()
	_check(mgr3.player_hand.size() == 2, "resolution: next round started after tie")
	_check(mgr3.monster_hp == 3, "resolution: no damage on tie (monster_hp still 3)")
```

- [ ] **Run test**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --script res://tests/test_combat_manager.gd --path /Users/giuliano.mozzillo/Games/deckheads
```

Expected: `34 passed, 0 failed`

- [ ] **Commit**

```bash
git add scripts/core/combat/combat_manager.gd tests/test_combat_manager.gd
git commit -m "feat: implement round resolution, damage, and combat loop"
```

---

### Task 8: CombatController + scene stub

**Files:**
- Create: `scenes/combat/combat_controller.gd`
- Create: `scenes/combat/combat.tscn`

The controller uses an event queue so all signals emitted synchronously by `player_stand()` (multiple `card_dealt` + `round_resolved`) are animated in sequence. `_processing_queue` prevents re-entrant queue starts when new events arrive while a previous animation is running.

Animation methods (`_animate_deal`, `_animate_reveal`, `_animate_bust`) are stubs with timer delays — wire them to actual Tween animations once the scene is built out visually.

- [ ] **Create `scenes/combat/combat_controller.gd`**

```gdscript
class_name CombatController
extends Node

# ---
# Signals
# ---

signal combat_finished(winner: String)

# ---
# Variables
# ---

@export var monster_deal_delay: float = 0.5

var _manager: CombatManager
var _is_player_turn: bool = false
var _event_queue: Array = []
var _processing_queue: bool = false

# ---
# Functions
# ---

func setup(player: Player, monster: Monster) -> void:
	_manager = CombatManager.new(player, monster)
	_manager.card_dealt.connect(func(t, c, fd): _enqueue("card_dealt", [t, c, fd]))
	_manager.card_revealed.connect(func(c): _enqueue("card_revealed", c))
	_manager.player_turn_ready.connect(func(): _enqueue("player_turn_ready", null))
	_manager.player_bust.connect(func(t): _enqueue("player_bust", t))
	_manager.monster_bust.connect(func(t): _enqueue("monster_bust", t))
	_manager.round_resolved.connect(func(o): _enqueue("round_resolved", o))
	_manager.combat_ended.connect(func(w): _enqueue("combat_ended", w))
	_manager.start_combat()

func _on_hit_pressed() -> void:
	if not _is_player_turn:
		return
	_is_player_turn = false
	_set_buttons_enabled(false)
	_manager.player_hit()

func _on_stand_pressed() -> void:
	if not _is_player_turn:
		return
	_is_player_turn = false
	_set_buttons_enabled(false)
	_manager.player_stand()

# ---
# Signal Callbacks
# ---

func _enqueue(event_type: String, data: Variant) -> void:
	_event_queue.append({"type": event_type, "data": data})
	if not _processing_queue:
		_process_queue()

func _process_queue() -> void:
	_processing_queue = true
	while not _event_queue.is_empty():
		var event: Dictionary = _event_queue.pop_front()
		await _handle_event(event)
	_processing_queue = false

func _handle_event(event: Dictionary) -> void:
	match event["type"]:
		"card_dealt":
			var args: Array = event["data"]
			await _animate_deal(args[0], args[1], args[2])
		"card_revealed":
			await _animate_reveal(event["data"])
		"player_turn_ready":
			_is_player_turn = true
			_set_buttons_enabled(true)
		"player_bust":
			await _animate_bust("player")
		"monster_bust":
			await _animate_bust("monster")
		"round_resolved":
			await get_tree().create_timer(0.3).timeout
		"combat_ended":
			combat_finished.emit(event["data"])

func _animate_deal(_target: String, _card: CardRef, _face_down: bool) -> void:
	await get_tree().create_timer(monster_deal_delay).timeout

func _animate_reveal(_card: CardRef) -> void:
	await get_tree().create_timer(0.2).timeout

func _animate_bust(_target: String) -> void:
	await get_tree().create_timer(0.4).timeout

func _set_buttons_enabled(_enabled: bool) -> void:
	pass
```

- [ ] **Create `scenes/combat/combat.tscn`**

Open the Godot editor (or use the text format below). Create a scene with a `Node` root named `Combat`, attach `combat_controller.gd`, and save.

Minimal text format (replace `uid://REPLACE` with a real UID from the editor):

```
[gd_scene load_steps=2 format=3 uid="uid://REPLACE"]

[ext_resource type="Script" path="res://scenes/combat/combat_controller.gd" id="1_xxxxx"]

[node name="Combat" type="Node"]
script = ExtResource("1_xxxxx")
```

- [ ] **Commit**

```bash
git add scenes/combat/combat_controller.gd scenes/combat/combat.tscn
git commit -m "feat: add CombatController with event queue and combat scene stub"
```
