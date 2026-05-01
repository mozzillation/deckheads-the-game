class_name HealthBarController
extends Control

# ---
# Signals
# ---

signal initialized

# ---
# Variables
# ---

@export var tween_duration: float = 0.3
@export var blink_duration: float = 0.1

@onready var current_hp_label: Label = %CurrentHpLabel
@onready var max_hp_label: Label = %MaxHpLabel
@onready var bar: ColorRect = %Bar

var _current_hp: int = 0
var _max_hp: int = 0
var _actor: RefCounted = null
var _bar_tween: Tween = null
var _blink_tween: Tween = null

# ---
# Functions
# ---

func initialize(actor: RefCounted, initial_hp: int, max_hp: int) -> void:
	_actor = actor
	_current_hp = initial_hp
	_max_hp = max_hp
	_update_display()
	initialized.emit()

func connect_to_actor() -> void:
	if _actor == null:
		push_error("HealthBarController: No actor set. Call initialize() first.")
		return

	_actor.hp_changed.connect(_on_hp_changed)

func _update_display() -> void:
	if _max_hp <= 0:
		return

	var percentage := float(_current_hp) / float(_max_hp)
	percentage = clamp(percentage, 0.0, 1.0)

	# Update labels
	current_hp_label.text = str(_current_hp)
	max_hp_label.text = str(_max_hp)

	# Animate bar fill
	if _bar_tween:
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.set_trans(Tween.TRANS_CUBIC)
	_bar_tween.set_ease(Tween.EASE_OUT)
	_bar_tween.tween_property(bar, "scale:x", percentage, tween_duration)

# ---
# Signal Callbacks
# ---

func _on_hp_changed(new_hp: int, _max_hp_val: int) -> void:
	_current_hp = new_hp
	_max_hp = _max_hp_val
	_update_display()
	_blink_twice()

func _blink_twice() -> void:
	if _blink_tween:
		_blink_tween.kill()

	_blink_tween = create_tween()
	_blink_tween.set_parallel(false)

	# Blink 1: fade out
	_blink_tween.tween_property(bar, "modulate:a", 0.1, blink_duration)
	# Blink 1: fade in
	_blink_tween.tween_property(bar, "modulate:a", 1.0, blink_duration)
	# Blink 2: fade out
	_blink_tween.tween_property(bar, "modulate:a", 0.1, blink_duration)
	# Blink 2: fade in
	_blink_tween.tween_property(bar, "modulate:a", 1.0, blink_duration)
