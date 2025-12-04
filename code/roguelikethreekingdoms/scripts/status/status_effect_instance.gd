# 状态效果实例类
class_name StatusEffectInstance
extends RefCounted

var resource: StatusEffectResource
var remaining_turns: int
var current_stacks: int = 1
var source: Node = null  # 施加此效果的单位/武器
var custom_data: Dictionary = {}  # 存储实例特有的数据

func setup(effect_resource: StatusEffectResource):
	resource = effect_resource
	remaining_turns = resource.duration
	current_stacks = 1

# 每回合触发
func process_turn(target_unit) -> Dictionary:
	var results = {
		"damage": 0,
		"healing": 0,
		"displacement": null,
		"messages": []
	}
	
	if resource.processor_script:
		# 调用处理器脚本的process_turn方法
		var processor = resource.processor_script.new()
		if processor.has_method("process_turn"):
			results = processor.process_turn(self, target_unit, results)
	
	remaining_turns -= 1
	return results

# 尝试叠加效果
func try_stack(new_instance) -> bool:
	if current_stacks >= resource.max_stacks:
		return false
	current_stacks += 1
	# 刷新持续时间（通常新施加会刷新）
	remaining_turns = max(remaining_turns, resource.duration)
	return true

func is_expired() -> bool:
	return resource.duration > 0 and remaining_turns <= 0
