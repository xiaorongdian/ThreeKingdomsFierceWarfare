# 燃烧效果处理器
class_name BurnEffectProcessor

static func process_turn(effect_instance, target_unit, results) -> Dictionary:
	var params = effect_instance.resource.effect_parameters
	var damage = params.get("damage_per_turn", 5) * effect_instance.current_stacks
	
	results.damage = damage
	results.messages.append("燃烧造成 %d 点伤害" % damage)
	
	# 可选：递减伤害（每回合减少）
	if params.get("damage_decay", false):
		params["damage_per_turn"] = max(1, params["damage_per_turn"] - 1)
	
	return results
