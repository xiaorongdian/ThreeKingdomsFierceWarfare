# RangeComponent.gd
extends Node2D
class_name CangGongRangeComponent

# ===== 核心计算函数 =====
# 根据起始格和方向，返回所有受影响的格子坐标
#func get_affected_tiles(start_cell: Vector2i, direction: Vector2 = Vector2.RIGHT) -> Array[Vector2i]:
	#var tiles: Array[Vector2i] = []
	#var start_v2: Vector2 = Vector2(start_cell)
	#
	#match range_type:
		#RangeType.LINE:
			## 直线攻击（如长矛）
			#for i in range(min_range, range_value + 1):
				#var target_cell = start_v2 + direction * i
				#tiles.append(Vector2i(target_cell))
				#if not through_obstacle and _is_cell_blocked(Vector2i(target_cell)):
					#break  # 遇到障碍停止
		#
		#RangeType.CIRCLE:
			## 圆形/菱形范围（如炸弹）
			#for dx in range(-range_value, range_value + 1):
				#for dy in range(-range_value, range_value + 1):
					## 使用曼哈顿距离（菱形）或欧几里得距离（圆形）
					#var distance = abs(dx) + abs(dy)  # 曼哈顿距离
					## var distance = sqrt(dx*dx + dy*dy)  # 欧几里得距离
					#if distance >= min_range and distance <= range_value:
						#var target_cell = Vector2i(start_v2 + Vector2(dx, dy))
						#tiles.append(target_cell)
		#
		#RangeType.CONE:
			## 锥形范围（如喷火器）
			#for i in range(min_range, range_value + 1):
				#var width = i  # 锥形宽度随距离增加
				#for j in range(-width, width + 1):
					#var offset = direction * i + direction.orthogonal() * j
					#var target_cell = Vector2i(start_v2 + offset)
					#tiles.append(target_cell)
		#
		#RangeType.CROSS:
			## 十字形（如剑的横扫）
			#for i in range(1, range_value + 1):
				#tiles.append(Vector2i(start_v2 + Vector2.RIGHT * i))
				#tiles.append(Vector2i(start_v2 + Vector2.LEFT * i))
				#tiles.append(Vector2i(start_v2 + Vector2.DOWN * i))
				#tiles.append(Vector2i(start_v2 + Vector2.UP * i))
		#
		#RangeType.SELF_AREA:
			## 以自身为中心的范围
			#return get_affected_tiles(start_cell)  # 可以复用圆形逻辑
		#
		#RangeType.PROJECTILE:
			## 投射物路径（直到碰到障碍或最大距离）
			#for i in range(1, range_value + 1):
				#var target_cell = Vector2i(start_v2 + direction * i)
				#tiles.append(target_cell)
				#if not through_obstacle and _is_cell_blocked(target_cell):
					#break
		#
		#_:
			#push_error("未知的攻击范围类型")
#
	## 过滤掉无效的格子（如地图外、不可行走区域）
	#return _filter_valid_tiles(tiles)
	
func get_affected_tiles(owner_node:Node2D,
						tilemap: TileMapLayer) -> Array[Vector2i]:
	var owner_position = owner_node.global_position
	var tile = tilemap.local_to_map(owner_position)
	var rangeArray: Array[Vector2i] = []
	rangeArray.append(Vector2i(tile.x + 1, tile.y))#右下
	rangeArray.append(Vector2i(tile.x - 1, tile.y))#左上
	rangeArray.append(Vector2i(tile.x, tile.y + 1))#左下
	rangeArray.append(Vector2i(tile.x, tile.y - 1))#右上
	rangeArray.append(Vector2i(tile.x - 1, tile.y + 1))#左
	rangeArray.append(Vector2i(tile.x + 1, tile.y - 1))#右
	return _filter_valid_tiles(rangeArray, tilemap)


# ===== 辅助函数 =====
#func _is_cell_blocked(cell: Vector2i) -> bool:
	#if not _tile_map:
		#return false
	## 这里实现你的障碍检测逻辑
	## 例如：检查tile_map的某个图层，或者查询游戏单位的占用情况
	#return false  # 默认返回false


func _filter_valid_tiles(tiles: Array[Vector2i], tilemap: TileMapLayer) -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	for tile in tiles:
		if _is_tile_valid(tile, tilemap):
			valid_tiles.append(tile)
	return valid_tiles


func _is_tile_valid(cell: Vector2i, tilemap: TileMapLayer) -> bool:
	# 检查格子是否在地图范围内
	var all_tiles = tilemap.get_used_cells()
	if cell not in all_tiles:
		return false
	return true


# ===== 可视化函数（调试用） =====
#func highlight_tiles(tiles: Array[Vector2i], color: Color = Color(1, 0, 0, 0.5)):
	## 清除之前的高亮
	#for child in get_children():
		#child.queue_free()
	#
	## 为每个格子创建一个高亮方块
	#for tile in tiles:
		#var world_pos = _tile_map.map_to_local(tile) if _tile_map else Vector2(tile * 64)
		#var rect = ColorRect.new()
		#rect.color = color
		#rect.size = Vector2(64, 64)  # 假设格子大小64x64
		#rect.position = world_pos
		#rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		#add_child(rect)


func clear_highlight():
	for child in get_children():
		child.queue_free()
