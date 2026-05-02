class_name MonsterStrategy

static func should_hit(style: Monster.PlayStyle, score: int) -> bool:
	match style:
		Monster.PlayStyle.AGGRESSIVE:
			return score < 19
		Monster.PlayStyle.CAUTIOUS:
			return score < 14
		Monster.PlayStyle.RANDOM:
			return randi() % 2 == 0
		Monster.PlayStyle.TACTICAL:
			return score < 17
		_:
			return false
