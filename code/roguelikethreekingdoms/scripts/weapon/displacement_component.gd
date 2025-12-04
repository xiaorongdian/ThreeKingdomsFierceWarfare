# 处理各种位移效果.gd
extends Node

enum DisplaceTarget {SELF, TARGET}
@export var displace_target: DisplaceTarget
@export var displace_pattern: PackedVector2Array # 位移的相对路径

func execute_displacement(user_cell: Vector2, target_cell: Vector2) -> Vector2:
	var final_cell: Vector2
	match displace_target:
		DisplaceTarget.SELF:
			final_cell = user_cell + displace_pattern[0] # 简单示例
			# 实际可能需要根据方向或目标位置计算
		DisplaceTarget.TARGET:
			final_cell = target_cell + displace_pattern[0]
	# 这里应该添加碰撞检测、是否出界等逻辑
	return final_cell
