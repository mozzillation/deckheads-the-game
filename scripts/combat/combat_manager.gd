class_name CombatManager
extends RefCounted

# ---
# Enums
# ---

enum Target { PLAYER, MONSTER }

# ---
# Signals
# ---

signal round_started
signal player_damaged(amount: int, new_hp: int)
signal player_healed(amount: int, new_hp: int)
signal player_died

# ---
# Variables
# ---

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
	round_started.emit()

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

func damage_player(amount: int) -> void:
	player.take_damage(amount)
	if not player.is_alive():
		player_died.emit()
	else:
		player_damaged.emit(amount, player.hp)

func heal_player(amount: int) -> void:
	player.heal(amount)
	player_healed.emit(amount, player.hp)
