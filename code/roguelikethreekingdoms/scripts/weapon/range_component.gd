# RangeComponent.gd
extends Node2D

#这个是武器的攻击范围组件
enum RangeType {LINE, CIRCLE, CONE, CUSTOM_PATTERN, PROJECTILE}

@export var range_type: RangeType
@export var range_value: int = 1 # 范围值（如直线长度、半径）
@export var custom_pattern: PackedVector2Array # 用于自定义形状的偏移量数组

# 关键函数：根据起始格和方向，返回所有受影响的格子坐标
func get_affected_tiles(start_cell: Vector2, direction: Vector2 = Vector2.RIGHT) -> Array[Vector2]:
	var tiles: Array[Vector2] = []
	match range_type:
		RangeType.LINE:
			for i in range(1, range_value + 1):
				tiles.append(start_cell + direction * i)
		RangeType.CIRCLE:
			# 使用曼哈顿距离或欧几里得距离计算圆形/菱形范围
			for dx in range(-range_value, range_value + 1):
				for dy in range(-range_value, range_value + 1):
					if abs(dx) + abs(dy) <= range_value: # 菱形判断
						tiles.append(start_cell + Vector2(dx, dy))
		RangeType.CONE:
			# 锥形范围算法
			for i in range(1, range_value + 1):
				for j in range(-i, i + 1):
					tiles.append(start_cell + direction * i + direction.orthogonal() * j)
		RangeType.CUSTOM_PATTERN:
			for offset in custom_pattern:
				tiles.append(start_cell + offset)
		RangeType.PROJECTILE:
			# 投射物可能需要单独的逻辑链（如碰撞检测）
			tiles = _calculate_projectile_path(start_cell, direction)
	return tiles

func _calculate_projectile_path(start_cell: Vector2, direction: Vector2) -> Array[Vector2]:
	# 实现投射物的路径计算（例如，直到碰到障碍物）
	var path: Array[Vector2] = []
	var current = start_cell
	for i in range(range_value):
		current += direction
		path.append(current)
		# 可以在这里添加碰撞检测，如果碰到障碍物则break
	return path
