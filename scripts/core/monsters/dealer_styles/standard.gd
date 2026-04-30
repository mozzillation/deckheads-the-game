class_name StandardDealerStyle
extends MonsterDealerStyle

func should_hit(hand_total: int) -> bool:
	return hand_total < 17
