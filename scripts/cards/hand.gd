class_name Hand
extends RefCounted

# ---
# Variables
# ---

var cards: Array[Card]

# ---
# Lifecycle
# ---

func _init() -> void:
	cards = []

# ---
# Functions
# ---

func add(card: Card, face_down: bool) -> void:
	cards.append(card)

func score() -> int:
	var total := 0
	var aces := 0
	for card in cards:
		if card.rank == Card.Rank.ACE:
			aces += 1
		total += card.blackjack_value()
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func is_burst() -> bool:
	return score() > 21

func is_blackjack() -> bool:
	return score() == 21 and cards.size() == 2
