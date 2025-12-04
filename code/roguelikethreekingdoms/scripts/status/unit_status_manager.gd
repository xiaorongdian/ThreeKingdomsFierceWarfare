# 单位状态管理.gd
extends Node
class_name UnitStatusManager

signal effect_applied(effect_instance)
signal effect_expired(effect_instance)
signal effect_processed(effect_instance, results)

var active_effects: Dictionary = {}  # effect_id -> StatusEffectInstance

# 尝试应用新效果
func apply_effect(effect_resource: StatusEffectResource, source: Node = null) -> bool:
	# 1. 检查概率
	if randf() > effect_resource.application_chance:
		return false
	
	# 2. 检查互斥
	for existing_id in active_effects.keys():
		if effect_resource.is_mutually_exclusive_with(existing_id):
			# 移除互斥效果
			remove_effect(existing_id)
	
	# 3. 应用效果
	var effect_id = effect_resource.effect_id
	
	if active_effects.has(effect_id):
		# 尝试叠加
		if not active_effects[effect_id].try_stack(effect_resource.create_instance()):
			return false
	else:
		# 新效果
		var instance = effect_resource.create_instance()
		instance.source = source
		active_effects[effect_id] = instance
		
		# 应用视觉效果
		_apply_visual_effects(effect_resource, instance)
	
	emit_signal("effect_applied", active_effects[effect_id])
	return true

# 移除效果
func remove_effect(effect_id: String):
	if active_effects.has(effect_id):
		var instance = active_effects[effect_id]
		_remove_visual_effects(instance.resource)
		active_effects.erase(effect_id)

# 每回合处理所有效果
func process_turn_effects():
	var effects_to_remove = []
	
	for effect_id in active_effects.keys():
		var instance = active_effects[effect_id]
		var results = instance.process_turn(get_parent())
		
		emit_signal("effect_processed", instance, results)
		
		# 处理伤害、治疗等
		_apply_effect_results(results)
		
		# 检查是否过期
		if instance.is_expired():
			effects_to_remove.append(effect_id)
	
	# 移除过期效果
	for effect_id in effects_to_remove:
		emit_signal("effect_expired", active_effects[effect_id])
		remove_effect(effect_id)

# 检查是否有特定类型的效果
func has_effect_type(effect_type: StatusEffectResource.EffectType) -> bool:
	for instance in active_effects.values():
		if instance.resource.effect_type == effect_type:
			return true
	return false

# 获取效果实例
func get_effect_instance(effect_id: String) -> StatusEffectInstance:
	return active_effects.get(effect_id)

func _apply_visual_effects(resource: StatusEffectResource, instance: StatusEffectInstance):
	if resource.particle_scene:
		var particle = resource.particle_scene.instantiate()
		particle.name = "EffectParticle_%s" % resource.effect_id
		get_parent().add_child(particle)
		instance.custom_data["particle_node"] = particle
	
	if resource.shader_material and get_parent().has_node("Sprite"):
		var sprite = get_parent().get_node("Sprite")
		# 保存原始材质以便恢复
		if not instance.custom_data.has("original_material"):
			instance.custom_data["original_material"] = sprite.material
		sprite.material = resource.shader_material

func _remove_visual_effects(resource: StatusEffectResource):
	if resource.shader_material and get_parent().has_node("Sprite"):
		var sprite = get_parent().get_node("Sprite")
		var particle_node = get_parent().get_node_or_null("EffectParticle_%s" % resource.effect_id)
		if particle_node:
			particle_node.queue_free()

func _apply_effect_results(results: Dictionary):
	var unit = get_parent()
	
	if results.get("damage", 0) > 0 and unit.has_method("take_damage"):
		unit.take_damage(results.damage)
	
	if results.get("healing", 0) > 0 and unit.has_method("heal"):
		unit.heal(results.healing)
	
	if results.get("displacement") and unit.has_method("displace_to"):
		var disp = results.displacement
		if disp.unit == unit:
			unit.displace_to(disp.to)
