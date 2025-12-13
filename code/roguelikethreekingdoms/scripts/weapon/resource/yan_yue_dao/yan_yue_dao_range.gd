# RangeComponent.gd
extends Node2D
class_name YanYueDaoRangeComponent

# ===== 配置参数 =====
enum RangeType {LINE, CIRCLE, CONE, CROSS, SELF_AREA, PROJECTILE}
@export var range_type: RangeType = RangeType.LINE
@export var range_value: int = 3  # 直线长度、圆形半径等
@export var min_range: int = 0    # 最小距离（例如，弓箭不能攻击脚下）
@export var through_obstacle: bool = false  # 是否穿透障碍
@export var custom_pattern: PackedVector2Array = []  # 自定义形状的偏移量

func get_affected_tiles(owner_node:Node2D,
						tilemap: TileMapLayer) -> Array[Vector2i]:
	var owner_position = owner_node.global_position
	var tile = tilemap.local_to_map(owner_position)
	var rangeArray: Array[Vector2i] = []
	for i in 2:
		rangeArray.append(Vector2i(tile.x + 1 + i, tile.y))#右下
		rangeArray.append(Vector2i(tile.x - 1 - i, tile.y))#左上
		rangeArray.append(Vector2i(tile.x, tile.y + 1 + i))#左下
		rangeArray.append(Vector2i(tile.x, tile.y - 1 - i))#右上
		rangeArray.append(Vector2i(tile.x - 1 - i, tile.y + 1 + i))#左
		rangeArray.append(Vector2i(tile.x + 1 + i, tile.y - 1 - i))#右
		
		
	return _filter_valid_tiles(rangeArray, tilemap)


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
