class_name CardRef
extends RefCounted

# ---
# Enums
# ---

enum Rank {
	ACE = 1,
	TWO = 2,
	THREE = 3,
	FOUR = 4,
	FIVE = 5,
	SIX = 6,
	SEVEN = 7,
	EIGHT = 8,
	NINE = 9,
	TEN = 10,
	JACK = 11,
	QUEEN = 12,
	KING = 13,
}

enum Suit {
	HEARTS,
	DIAMONDS,
	CLUBS,
	SPADES,
}

# ---
# Variables
# ---

var rank: Rank
var suit: Suit

# ---
# Lifecycle
# ---

func _init(p_rank: Rank, p_suit: Suit) -> void:
	rank = p_rank
	suit = p_suit

# ---
# Functions
# ---

func blackjack_value() -> int:
	match rank:
		Rank.ACE:
			return 11
		Rank.JACK, Rank.QUEEN, Rank.KING:
			return 10
		_:
			return rank as int

func display_name() -> String:
	return "%s of %s" % [Rank.keys()[rank - 1], Suit.keys()[suit]]
