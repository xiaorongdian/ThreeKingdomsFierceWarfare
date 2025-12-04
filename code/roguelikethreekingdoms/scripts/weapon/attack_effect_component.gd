# AttackEffectComponent.gd
extends Node
#武器攻击效果组件 施加伤害、状态效果和判断友军伤害
@export var base_damage: int = 10
@export var can_hurt_allies: bool = false
@export var status_effects: Array[StatusEffectResource] # 自定义的状态效果资源数组

# AttackEffectComponent.gd (修改apply_effects函数部分)
func apply_effects(target_unit, attacker, weapon):
	# 1. 友军伤害判断
	if not can_hurt_allies and target_unit.is_in_group("ally"):
		return

	# 2. 获取伤害值（关键修改！）
	# 方法A：如果weapon参数有get_damage()方法
	var final_damage = weapon.get_damage() if weapon.has_method("get_damage") else base_damage
	
	target_unit.take_damage(final_damage)

	# 3. 应用状态效果
	for effect in status_effects:
		if effect.chance >= randf():
			target_unit.apply_status_effect(effect.duplicate())
