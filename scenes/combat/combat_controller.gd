class_name CombatController
extends Node

# ---
# Signals
# ---

signal combat_finished(winner: CombatManager.Target)

# ---
# Variables
# ---

const CARD_VIEW = preload("res://scenes/components/card_view/card_view.tscn")

@export var monster: Monster
@export var reveal_delay: float = 0.5
@export var monster_deal_delay: float = 0.5

@onready var _player_hand_container: HBoxContainer = %PlayerHand
@onready var _monster_hand_container: HBoxContainer = %MonsterHand

var _manager: CombatManager
var _is_player_turn: bool = false
var _event_queue: Array = []
var _processing_queue: bool = false
var _monster_hole_card_view: CardViewController = null

# ---
# Lifecycle
# ---

func _ready() -> void:
	var stats := PlayerStats.new()
	var player := Player.new(stats)
	setup(player)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_player_turn:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				_on_hit_pressed()
			KEY_S:
				_on_stand_pressed()

# ---
# Functions
# ---

func setup(player: Player) -> void:
	print("=== COMBAT START: Player (HP:%d) vs %s (HP:%d) ===" % [
		player.hp, monster.display_name, monster.hp
	])
	_manager = CombatManager.new(player, monster)
	_manager.round_started.connect(func(): _enqueue("round_started", null))
	_manager.card_dealt.connect(func(t, c, fd): _enqueue("card_dealt", [t, c, fd]))
	_manager.card_revealed.connect(func(c): _enqueue("card_revealed", c))
	_manager.player_turn_ready.connect(func(): _enqueue("player_turn_ready", null))
	_manager.player_bust.connect(func(t): _enqueue("player_bust", t))
	_manager.monster_bust.connect(func(t): _enqueue("monster_bust", t))
	_manager.round_resolved.connect(func(o): _enqueue("round_resolved", o))
	_manager.combat_ended.connect(func(w): _enqueue("combat_ended", w))
	_manager.start_combat()

func _on_hit_pressed() -> void:
	if not _is_player_turn:
		return
	_is_player_turn = false
	_manager.player_hit()

func _on_stand_pressed() -> void:
	if not _is_player_turn:
		return
	_is_player_turn = false
	_manager.player_stand()

# ---
# Signal Callbacks
# ---

func _enqueue(event_type: String, data: Variant) -> void:
	_event_queue.append({"type": event_type, "data": data})
	if not _processing_queue:
		_process_queue()

func _process_queue() -> void:
	_processing_queue = true
	while not _event_queue.is_empty():
		var event: Dictionary = _event_queue.pop_front()
		await _handle_event(event)
	_processing_queue = false

func _handle_event(event: Dictionary) -> void:
	match event["type"]:
		"round_started":
			_clear_hands()
		"card_dealt":
			var args: Array = event["data"]
			var target: CombatManager.Target = args[0]
			var card: CardRef = args[1]
			var face_down: bool = args[2]
			var card_str := "[face down]" if face_down else "%s (%d)" % [card.display_name(), card.blackjack_value()]
			print("[DEAL] %s: %s" % [_target_name(target), card_str])
			await _animate_deal(target, card, face_down)
		"card_revealed":
			var card: CardRef = event["data"]
			print("[REVEAL] Monster hole card: %s (%d)" % [card.display_name(), card.blackjack_value()])
			await _animate_reveal(card)
		"player_turn_ready":
			var player_total := _manager._player_total()
			var monster_visible := _manager._hand_total([_manager.monster_hand[0]])
			print("[TURN] Player: %d | Monster shows: %d — press H to hit, S to stand" % [player_total, monster_visible])
			_is_player_turn = true
		"player_bust":
			print("[BUST] Player busts at %d" % event["data"])
			await _animate_bust("player")
		"monster_bust":
			print("[BUST] Monster busts at %d" % event["data"])
			await _animate_bust("monster")
		"round_resolved":
			match event["data"]:
				"player_win":
					print("[RESOLVE] Player wins — Monster HP: %d" % _manager.monster.hp)
				"monster_win":
					print("[RESOLVE] Monster wins — Player HP: %d/%d" % [_manager.player.hp, _manager.player.stats.max_hp()])
				"tie":
					print("[RESOLVE] Tie — no damage")
		"combat_ended":
			var winner: CombatManager.Target = event["data"]
			print("=== COMBAT OVER: %s wins! ===" % _target_name(winner))
			combat_finished.emit(event["data"])

func _clear_hands() -> void:
	for child in _player_hand_container.get_children():
		child.queue_free()
	for child in _monster_hand_container.get_children():
		child.queue_free()
	_monster_hole_card_view = null

func _target_name(target: CombatManager.Target) -> String:
	return "Player" if target == CombatManager.Target.PLAYER else "Monster"

func _animate_deal(target: CombatManager.Target, card: CardRef, face_down: bool) -> void:
	var view: CardViewController = CARD_VIEW.instantiate()
	var container := _player_hand_container if target == CombatManager.Target.PLAYER else _monster_hand_container
	container.add_child(view)
	if target == CombatManager.Target.MONSTER:
		container.move_child(view, 0)
	view.setup(card, face_down)
	if face_down:
		_monster_hole_card_view = view
	await view.animate_in()

func _animate_reveal(card: CardRef) -> void:
	if _monster_hole_card_view:
		await _monster_hole_card_view.reveal(card)
		_monster_hole_card_view = null
	await get_tree().create_timer(reveal_delay).timeout

func _animate_bust(_target: String) -> void:
	await get_tree().create_timer(0.8).timeout

func _set_buttons_enabled(_enabled: bool) -> void:
	pass
