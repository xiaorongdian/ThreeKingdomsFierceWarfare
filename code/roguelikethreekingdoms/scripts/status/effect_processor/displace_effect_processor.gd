# 位移效果处理器（立即执行，非持续）
class_name DisplaceEffectProcessor

static func on_apply(effect_instance, target_unit, source_position):
	var params = effect_instance.resource.effect_parameters
	var direction_type = params.get("displace_direction", "away")
	var distance = params.get("displace_distance", 2)
	
	var direction: Vector2
	
	match direction_type:
		"away":
			direction = (target_unit.grid_position - source_position).normalized()
		"toward":
			direction = (source_position - target_unit.grid_position).normalized()
		"random":
			direction = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
		"custom":
			var custom_dir = params.get("custom_direction", Vector2.RIGHT)
			direction = custom_dir.normalized()
	
	# 计算目标位置
	var target_pos = target_unit.grid_position + (direction * distance)
	
	# 返回位移信息，由战斗系统执行
	return {
		"type": "displace",
		"from": target_unit.grid_position,
		"to": target_pos,
		"unit": target_unit
	}
