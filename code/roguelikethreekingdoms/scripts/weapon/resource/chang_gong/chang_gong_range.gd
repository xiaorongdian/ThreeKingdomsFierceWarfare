# RangeComponent.gd
extends Node2D
class_name CangGongRangeComponent

	
func get_affected_tiles(gamer:Gamer,
						tilemap: TileMapLayer) -> Array[Vector2i]:
	var tile = GlobalUtils.node_to_tile(gamer, tilemap)
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
