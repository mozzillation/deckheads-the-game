class_name PlayerStats
extends Resource

# ---
# Variables
# ---

## Base HP ceiling before bonuses.
@export var base_max_hp: int = 5

## Flat HP added on top of base_max_hp (e.g. from relics/upgrades).
@export var max_hp_bonus: int = 0

## Multiplier applied to gold earned.
@export var gold_multiplier: float = 1.0

## Extra cards the player may draw per hand before standing.
@export var extra_draws: int = 0

## If true, the player can peek at one dealer hole card per round.
@export var can_peek: bool = false

## Flat bonus added to every hand total (e.g. a relic that counts as +1).
@export var hand_bonus: int = 0

## Base HP ceiling before bonuses.
@export var base_damage: int = 1

@export var strength: int = 0

# ---
# Functions
# ---

func max_hp() -> int:
	return base_max_hp + max_hp_bonus

func damage() -> int:
	return base_damage + strength
