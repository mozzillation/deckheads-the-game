class_name CardViewController
extends Control

# ---
# Variables
# ---

@onready var _motion_group: Control = $MotionGroup
var _idle_tween: Tween
@onready var front_face: Control = $MotionGroup/FrontFace
@onready var back_face: Control = $MotionGroup/BackFace
@onready var rank_label: Label = $MotionGroup/FrontFace/RankLabel

# ---
# Functions
# ---

func setup(card: CardRef, face_down: bool) -> void:
	rank_label.text = _rank_abbr(card.rank)
	front_face.visible = not face_down
	back_face.visible = face_down

func reveal(card: CardRef) -> void:
	_motion_group.pivot_offset = _motion_group.size / 2.0
	_motion_group.scale.y = 0.5
	rank_label.text = _rank_abbr(card.rank)
	front_face.visible = true
	back_face.visible = false
	var t2 := create_tween()
	t2.tween_property(_motion_group, "scale:y", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	await t2.finished

func animate_in() -> void:
	_motion_group.position.y = -10
	modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_motion_group, "position:y", 0.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	await tween.finished
	_start_idle()

func _start_idle() -> void:
	if _idle_tween:
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_motion_group, "position:y", 1, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_idle_tween.tween_property(_motion_group, "position:y", -1, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func _rank_abbr(rank: CardRef.Rank) -> String:
	match rank:
		CardRef.Rank.ACE: return "A"
		CardRef.Rank.JACK: return "J"
		CardRef.Rank.QUEEN: return "Q"
		CardRef.Rank.KING: return "K"
		_: return str(rank as int)
