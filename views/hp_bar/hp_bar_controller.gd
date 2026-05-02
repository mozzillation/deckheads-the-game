class_name HPBarController
extends Control

# ---
# Variables
# ---

@export var hp: int = 0
@export var max_hp: int = 0

@onready var current_hp_label: Label = %CurrentHPLabel

# ---
# Lifecycle
# ---

func bind(_hp: int, _max_hp: int) -> void:
	hp = _hp
	max_hp = _max_hp
	_update()

# ---
# Functions
# ---

func _update() -> void:
	current_hp_label.text = str(hp)

func on_hp_change(_new_hp: int) -> void:
	# Store old HP value
	var old_hp := hp 
	
	# Update HP value
	hp = _new_hp
	
	if _new_hp < old_hp:                                                                                        
		await _animate_damage()                                                     
	elif _new_hp > old_hp:                                                                                      
		await _animate_heal()   

	_update()

# ---
# Animations
# ---

func _animate_damage() -> void:
	var tween := create_tween()
	tween.tween_property(current_hp_label, "modulate:a", 0.5, 0.1)
	tween.tween_property(current_hp_label, "modulate:a", 1.0, 0.1)
	await tween.finished

func _animate_heal() -> void:
	var tween := create_tween()
	tween.tween_property(current_hp_label, "modulate", Color.GREEN, 0.1)
	tween.tween_property(current_hp_label, "modulate", Color.WHITE, 0.2)
	await tween.finished
