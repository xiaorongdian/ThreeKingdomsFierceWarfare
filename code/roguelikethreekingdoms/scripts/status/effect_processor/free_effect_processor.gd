
# 冰冻效果处理器
class_name FreezeEffectProcessor

static func process_turn(effect_instance, target_unit, results) -> Dictionary:
	var params = effect_instance.resource.effect_parameters
	
	# 减少移动力
	var movement_reduction = params.get("movement_reduction", 0.5)
	if target_unit.has_method("set_movement_modifier"):
		target_unit.set_movement_modifier("freeze", movement_reduction)
	
	# 一定概率完全定身
	var stun_chance = params.get("stun_chance", 0.3)
	if randf() < stun_chance:
		results.messages.append("目标被冻僵了！")
		if target_unit.has_method("stun"):
			target_unit.stun(1)  # 眩晕1回合
	
	return results
