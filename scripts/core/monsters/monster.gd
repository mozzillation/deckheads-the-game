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

# ---
# Variables
# ---

@export var display_name: String = "Undefined"
@export var type: Type = Type.UNKNOWN
@export var rarity: Rarity = Rarity.COMMON
@export var base_damage: int = 1
