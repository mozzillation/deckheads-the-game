class_name Player
extends RefCounted

# ---
# Variables
# ---

var hp: int = 3
var max_hp: int
var gold: int = 0
var damage: int = 1

# ---
# Lifecycle
# ---

func _init() -> void:
	max_hp = hp

# ---
# Functions
# ---

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)

func is_alive() -> bool:
	return hp > 0
