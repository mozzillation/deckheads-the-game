class_name Deck
extends RefCounted

# ---
# Variables
# ---

var _cards: Array[Card] = []

# ---
# Lifecycle
# ---

func _init() -> void:
	generate()
	shuffle()

# ---
# Functions
# ---

func generate() -> void:
	_cards.clear()
	for suit in Card.Suit.values():
		for rank in Card.Rank.values():
			_cards.append(Card.new(rank, suit))

func shuffle() -> void:
	_cards.shuffle()

func draw() -> Card:
	if _cards.is_empty():
		generate()
		shuffle()
	return _cards.pop_back()

func remaining() -> int:
	return _cards.size()
