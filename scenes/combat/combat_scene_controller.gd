class_name CombatSceneController
extends Node2D

# ---
# Variables
# ---

var _manager: CombatManager
var _player: Player
var _monster: Monster
var _busy := false

@onready var player_hp_bar: HPBarController = $PlayerHPBar

# ---
# Lifecycle
# ---

func _ready() -> void:
	_player = Player.new()
	_monster = Monster.new()
	
	_manager = CombatManager.new(_player, _monster)
	_connect_signals()
	player_hp_bar.bind(_player.hp, _player.max_hp)
	_run_round_start()

# ---
# Functions
# ---

func _connect_signals() -> void:
	_manager.player_damaged.connect(_on_player_damaged)
	_manager.player_healed.connect(_on_player_healed)
	_manager.player_died.connect(_on_player_died)

func _sequence(steps: Callable) -> void:
	if _busy: return
	_busy = true
	await steps.call()
	_busy = false

func _run_round_start() -> void:
	_manager.start_round()
	_sequence(func():
		await _show_message("Round Start!")
		await _run_deal_sequence()
	)

func _run_deal_sequence() -> void:
	while _manager.has_cards_to_deal():
		var info := _manager.deal_next()
		await _animate_card_deal(info)

func _animate_card_deal(info: Dictionary) -> void:
	var target: String = "Player" if info.target == CombatManager.Target.PLAYER else "Monster"
	print_debug("[DEAL] %s → %s" % [info.card.display_name(), target])
	await get_tree().create_timer(0.3).timeout

func _show_message(text: String) -> void:
	print_debug("[MSG] %s" % text)
	await get_tree().create_timer(1.0).timeout

# ---
# Signal Callbacks
# ---

func _on_player_damaged(amount: int, hp: int) -> void:
	_sequence(func():
		await _show_message("-%d damage!" % amount)
		await player_hp_bar.on_hp_change(hp)
	)

func _on_player_healed(amount: int, hp: int) -> void:
	_sequence(func():
		await _show_message("+%d healed!" % amount)
		await player_hp_bar.on_hp_change(hp)
	)

func _on_player_died() -> void:
	_busy = true
	await _show_message("You died!")

func _unhandled_input(event: InputEvent) -> void:
	if _busy: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H: _manager.damage_player(1)
			KEY_S: _manager.heal_player(1)
