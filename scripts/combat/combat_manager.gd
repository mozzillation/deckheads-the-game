class_name CombatManager
extends RefCounted

# ---
# Enums
# ---

enum Target { PLAYER, MONSTER }
enum Stage { START, DEAL, PLAYER_TURN, MONSTER_TURN, DONE }

# ---
# Signals
# ---

signal round_started
signal stage_changed(new_stage: Stage)
signal card_drawn(card: Card, target: Target)
signal monster_hand_revealed
signal player_bust
signal monster_bust
signal round_resolved(winner: Target)
signal player_damaged(amount: int, new_hp: int)
signal player_healed(amount: int, new_hp: int)
signal player_died
signal monster_died

# ---
# Variables
# ---

var stage: Stage = Stage.START

var monster: Monster
var player: Player
var deck: Deck

var player_hand: Hand
var monster_hand: Hand

var _deal_index: int = 0
const _DEAL_ORDER: Array = [Target.PLAYER, Target.MONSTER, Target.PLAYER, Target.MONSTER]

# ---
# Lifecycle
# ---

func _init(_player: Player, _monster: Monster) -> void:
	player = _player
	monster = _monster

# ---
# Functions
# ---

func start_round() -> void:
	deck = Deck.new()
	player_hand = Hand.new()
	monster_hand = Hand.new()
	_deal_index = 0
	_set_stage_to(Stage.DEAL)
	round_started.emit()

func finish_deal() -> void:
	_set_stage_to(Stage.PLAYER_TURN)

func has_cards_to_deal() -> bool:
	return _deal_index < _DEAL_ORDER.size()

func deal_next() -> Dictionary:
	var target: Target = _DEAL_ORDER[_deal_index]
	var card := deck.draw()
	var face_down := target == Target.MONSTER and _deal_index == 1
	if target == Target.PLAYER:
		player_hand.add(card, face_down)
	else:
		monster_hand.add(card, face_down)
	_deal_index += 1
	return { card = card, target = target, face_down = face_down }

func player_hit() -> void:
	var card := deck.draw()
	player_hand.add(card, false)
	card_drawn.emit(card, Target.PLAYER)
	if player_hand.is_burst():
		player_bust.emit()
		_resolve_round(Target.MONSTER)

func player_stand() -> void:
	monster_hand.reveal_all()
	monster_hand_revealed.emit()
	_set_stage_to(Stage.MONSTER_TURN)

func monster_hit() -> void:
	var card := deck.draw()
	monster_hand.add(card, false)
	card_drawn.emit(card, Target.MONSTER)
	if monster_hand.is_burst():
		monster_bust.emit()
		_resolve_round(Target.PLAYER)

func monster_stand() -> void:
	var wins := CombatResolution.player_wins_standoff(player_hand.score(), monster_hand.score())
	_resolve_round(Target.PLAYER if wins else Target.MONSTER)

func monster_should_hit() -> bool:
	return MonsterStrategy.should_hit(monster.play_style, monster_hand.score())

func damage_player(amount: int) -> void:
	player.take_damage(amount)
	if not player.is_alive():
		player_died.emit()
	else:
		player_damaged.emit(amount, player.hp)

func heal_player(amount: int) -> void:
	player.heal(amount)
	player_healed.emit(amount, player.hp)

# ---
# Functions (Private)
# ---

func _resolve_round(winner: Target) -> void:
	_set_stage_to(Stage.DONE)
	round_resolved.emit(winner)
	if winner == Target.MONSTER:
		damage_player(CombatResolution.damage_to_player(monster))
	else:
		monster.take_damage(CombatResolution.damage_to_monster(player))
		if not monster.is_alive():
			monster_died.emit()

func _set_stage_to(_stage: Stage) -> void:
	if stage == _stage: return
	stage = _stage
	stage_changed.emit(stage)
