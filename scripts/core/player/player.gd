class_name Player
extends RefCounted

# ---
# Signals
# ---

signal hp_changed(current: int, maximum: int)
signal gold_changed(current: int)
signal died

# ---
# Variables
# ---

var stats: PlayerStats
var hp: int
var gold: int
var damage: int

# ---
# Lifecycle
# ---

func _init(p_stats: PlayerStats) -> void:
	stats = p_stats
	hp = stats.max_hp()
	gold = 0
	damage = stats.damage()

# ---
# Functions
# ---

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	hp_changed.emit(hp, stats.max_hp())
	if hp == 0:
		died.emit()

func heal(amount: int) -> void:
	hp = min(hp + amount, stats.max_hp())
	hp_changed.emit(hp, stats.max_hp())

func earn_gold(amount: int) -> void:
	gold += int(amount * stats.gold_multiplier)
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func is_alive() -> bool:
	return hp > 0
