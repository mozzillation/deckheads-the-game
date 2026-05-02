class_name Hand
extends RefCounted

# ---
# Variables
# ---

var cards: Array[Card]
var _face_down: Array[bool]

# ---
# Lifecycle
# ---

func _init() -> void:
	cards = []
	_face_down = []

# ---
# Functions
# ---

func add(card: Card, face_down: bool) -> void:
	cards.append(card)
	_face_down.append(face_down)

func reveal(index: int) -> void:
	_face_down[index] = false

func reveal_all() -> void:
	for i in _face_down.size():
		_face_down[i] = false

func score() -> int:
	return _calculate_score(false)

func total() -> int:
	return _calculate_score(true)

func is_burst() -> bool:
	return total() > 21

func is_blackjack() -> bool:
	return total() == 21 and cards.size() == 2

# ---
# Functions (Private)
# ---

func _calculate_score(include_face_down: bool) -> int:
	var value := 0
	var aces := 0
	for i in cards.size():
		if not include_face_down and _face_down[i]:
			continue
		var card := cards[i]
		if card.rank == Card.Rank.ACE:
			aces += 1
		value += card.blackjack_value()
	while value > 21 and aces > 0:
		value -= 10
		aces -= 1
	return value
