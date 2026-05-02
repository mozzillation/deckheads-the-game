class_name CombatResolution

# ---
# Functions
# ---

static func player_wins_standoff(player_score: int, monster_score: int) -> bool:
	return player_score > monster_score

static func damage_to_player(monster: Monster) -> int:
	return monster.damage

static func damage_to_monster(player: Player) -> int:
	return player.damage
