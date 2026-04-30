class_name CombatManager
extends RefCounted

# ---
# Enums
# ---

enum Target {
	PLAYER,
	MONSTER
}

# ---
# Signals
# ---

signal card_dealt(target: Target, card: CardRef, face_down: bool)
signal card_revealed(card: CardRef)
signal player_turn_ready
signal player_bust(total: int)
signal monster_bust(total: int)
signal round_resolved(outcome: String)
signal combat_ended(winner: Target)

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
	_deal_to_player()
	var total := _player_total()
	if total > 21:
		player_bust.emit(total)
		_resolve_round("monster_win")

func player_stand() -> void:
	pass

func _start_round() -> void:
	deck = Deck.new()
	player_hand.clear()
	monster_hand.clear()
	_deal_to_player()
	_deal_to_player()
	_deal_to_monster(false)
	_deal_to_monster(true)
	player_turn_ready.emit()

func _deal_to_player() -> void:
	var card := deck.draw()
	player_hand.append(card)
	card_dealt.emit(Target.PLAYER, card, false)

func _deal_to_monster(face_down: bool) -> void:
	var card := deck.draw()
	monster_hand.append(card)
	card_dealt.emit(Target.MONSTER, card, face_down)

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
