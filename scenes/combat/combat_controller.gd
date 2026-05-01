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

@onready var _player_hand_container: HBoxContainer = %PlayerHand
@onready var _monster_hand_container: HBoxContainer = %MonsterHand
@onready var _player_hp_bar: HealthBarController = %PlayerHealthBar
@onready var _monster_hp_bar: HealthBarController = %MonsterHealthBar

var _manager: CombatManager
var _is_player_turn: bool = false
var _event_queue: Array = []
var _processing_queue: bool = false
var _monster_hole_card_view: CardViewController = null

var _stats: PlayerStats
var _player: Player

# ---
# Lifecycle
# ---

func _ready() -> void:
	_stats = PlayerStats.new()
	_player = Player.new(_stats)
	setup(_player)

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
	_manager = CombatManager.new(player, monster)
	_manager.round_started.connect(func(): _enqueue("round_started", null))
	_manager.card_dealt.connect(func(t, c, fd): _enqueue("card_dealt", [t, c, fd]))
	_manager.card_revealed.connect(func(c): _enqueue("card_revealed", c))
	_manager.player_turn_ready.connect(func(): _enqueue("player_turn_ready", null))
	_manager.player_bust.connect(func(t): _enqueue("player_bust", t))
	_manager.monster_bust.connect(func(t): _enqueue("monster_bust", t))
	_manager.round_resolved.connect(func(o, pt, mt): _enqueue("round_resolved", [o, pt, mt]))
	_manager.combat_ended.connect(func(w): _enqueue("combat_ended", w))

	_player_hp_bar.initialize(player, player.hp, player.stats.max_hp())
	_player_hp_bar.connect_to_actor()
	_monster_hp_bar.initialize(monster, monster.hp, monster.max_hp)
	_monster_hp_bar.connect_to_actor()

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
			_on_round_started()
		"card_dealt":
			await _on_card_dealt(event["data"])
		"card_revealed":
			await _on_card_revealed(event["data"])
		"player_turn_ready":
			_on_player_turn_ready()
		"player_bust":
			await _on_bust(CombatManager.Target.PLAYER, event["data"])
		"monster_bust":
			await _on_bust(CombatManager.Target.MONSTER, event["data"])
		"round_resolved":
			await _on_round_resolved(event["data"])
		"combat_ended":
			_on_combat_ended(event["data"])

func _on_round_started() -> void:
	for child in _player_hand_container.get_children():
		child.queue_free()
	for child in _monster_hand_container.get_children():
		child.queue_free()
	_monster_hole_card_view = null

func _on_card_dealt(args: Array) -> void:
	var target: CombatManager.Target = args[0]
	var card: CardRef = args[1]
	var face_down: bool = args[2]
	var view: CardViewController = CARD_VIEW.instantiate()
	var container := _player_hand_container if target == CombatManager.Target.PLAYER else _monster_hand_container
	container.add_child(view)
	if target == CombatManager.Target.MONSTER:
		container.move_child(view, 0)
	view.setup(card, face_down)
	if face_down:
		_monster_hole_card_view = view
	await view.animate_in()

func _on_card_revealed(card: CardRef) -> void:
	if _monster_hole_card_view:
		await _monster_hole_card_view.reveal(card)
		_monster_hole_card_view = null
	await get_tree().create_timer(reveal_delay).timeout

func _on_player_turn_ready() -> void:
	_is_player_turn = true

func _on_bust(target: CombatManager.Target, _total: int) -> void:
	var label := "Player" if target == CombatManager.Target.PLAYER else "Monster"
	print("[BUST] %s busts at %d" % [label, _total])
	await get_tree().create_timer(0.8).timeout

func _on_round_resolved(data: Array) -> void:
	var outcome: String = data[0]
	var player_total: int = data[1]
	var monster_total: int = data[2]
	match outcome:
		"player_win":
			print("[RESOLVE] Player wins (%d > %d)" % [player_total, monster_total])
		"monster_win":
			print("[RESOLVE] Monster wins (%d > %d)" % [monster_total, player_total])
		"tie":
			print("[RESOLVE] Tie (%d = %d)" % [player_total, monster_total])
	_manager.on_round_complete(outcome)

func _on_combat_ended(winner: CombatManager.Target) -> void:
	var label := "Player" if winner == CombatManager.Target.PLAYER else "Monster"
	print("=== COMBAT OVER: %s wins! ===" % label)
	combat_finished.emit(winner)
