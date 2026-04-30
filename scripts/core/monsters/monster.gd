class_name Monster
extends Resource

# ---
# Signals
# ---

signal hp_changed(current: int, maximum: int)
signal died

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
@export var hp: int = 1
@export var dealer_style: MonsterDealerStyle

var max_hp: int

# ---
# Functions
# ---

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()

func is_alive() -> bool:
	return hp > 0
