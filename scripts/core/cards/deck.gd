class_name Deck
extends RefCounted

# ---
# Variables
# ---

var _cards: Array[CardRef] = []

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
	for suit in CardRef.Suit.values():
		for rank in CardRef.Rank.values():
			_cards.append(CardRef.new(rank, suit))

func shuffle() -> void:
	_cards.shuffle()

func draw() -> CardRef:
	if _cards.is_empty():
		generate()
		shuffle()
	return _cards.pop_back()

func remaining() -> int:
	return _cards.size()
