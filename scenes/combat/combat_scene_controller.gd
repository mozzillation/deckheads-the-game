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
	## Player Signals
	_manager.player_damaged.connect(_on_player_damaged)
	_manager.player_healed.connect(_on_player_healed)
	_manager.player_died.connect(_on_player_died)
	_manager.player_bust.connect(_on_player_bust)
	## Monster Signals
	_manager.monster_bust.connect(_on_monster_bust)
	_manager.monster_died.connect(_on_monster_died)

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
	_manager.finish_deal()

func _run_monster_turn() -> void:
	_sequence(func():
		await _show_message("Monster's turn!")
		while _manager.monster_should_hit():
			var info := _manager.monster_hit()
			await _animate_card_deal(info)
			if _manager.monster_hand.is_burst():
				await _animate_bust(CombatManager.Target.MONSTER)
				_manager.apply_monster_bust()
				return
		_manager.monster_stand()
		var msg := "Player wins!" if _manager.player_hand.score() > _manager.monster_hand.score() else "Monster wins!"
		await _show_message(msg)
	)

func _animate_card_deal(info: Dictionary) -> void:
	var target: String = "Player" if info.target == CombatManager.Target.PLAYER else "Monster"
	print_debug("[DEAL] %s → %s" % [info.card.display_name(), target])
	await get_tree().create_timer(0.3).timeout

func _animate_bust(target: CombatManager.Target) -> void:
	var who: String = "Player" if target == CombatManager.Target.PLAYER else "Monster"
	print_debug("[BUST] %s bust!" % who)
	await get_tree().create_timer(0.8).timeout

func _show_message(text: String) -> void:
	print_debug("[MSG] %s" % text)
	await get_tree().create_timer(1.0).timeout

# ---
# Input
# ---

func _unhandled_input(event: InputEvent) -> void:
	if _busy: return
	if _manager.stage != CombatManager.Stage.PLAYER_TURN: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				_sequence(func():
					var info := _manager.player_hit()
					await _animate_card_deal(info)
					if _manager.player_hand.is_burst():
						await _animate_bust(CombatManager.Target.PLAYER)
						_manager.apply_player_bust()
				)
			KEY_S:
				_manager.player_stand()
				_run_monster_turn()

# ---
# Signal Callbacks
# ---

func _on_player_damaged(amount: int, hp: int) -> void:
	print_debug("[HP] Player -%d → %d" % [amount, hp])
	player_hp_bar.on_hp_change(hp)

func _on_player_healed(amount: int, hp: int) -> void:
	print_debug("[HP] Player +%d → %d" % [amount, hp])
	player_hp_bar.on_hp_change(hp)

func _on_player_died() -> void:
	_busy = true
	await _show_message("You died!")

func _on_player_bust() -> void:
	print_debug("[BUST] Player bust")

func _on_monster_bust() -> void:
	print_debug("[BUST] Monster bust")

func _on_monster_died() -> void:
	print_debug("[MONSTER] Defeated!")
