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
