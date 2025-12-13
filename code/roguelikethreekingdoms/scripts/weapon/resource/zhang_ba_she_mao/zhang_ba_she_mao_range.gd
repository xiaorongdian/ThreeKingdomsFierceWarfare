# RangeComponent.gd
extends Node2D
class_name ZangBaSheMaoRangeComponent

# ===== 配置参数 =====
enum RangeType {LINE, CIRCLE, CONE, CROSS, SELF_AREA, PROJECTILE}
@export var range_type: RangeType = RangeType.LINE
@export var range_value: int = 3  # 直线长度、圆形半径等
@export var min_range: int = 0    # 最小距离（例如，弓箭不能攻击脚下）
@export var through_obstacle: bool = false  # 是否穿透障碍
@export var custom_pattern: PackedVector2Array = []  # 自定义形状的偏移量


# ===== 内部节点引用 =====
@onready var _tile_map: TileMap = get_tree().root.find_child("TileMap", true, false)  # 假设你的地图叫TileMap
	
func get_affected_tiles(gamer:Gamer, 
			tilemap: TileMapLayer)-> Array[Vector2i]:
	var move_range:Array[Vector2i] = []
	var open:Array[Vector2i] = []
	var now:Array[Vector2i] = []
	#玩家当前位置
	var gamer_position = gamer.global_position
	#转地图网格
	var tile = tilemap.local_to_map(gamer_position)
	now.append(tile)
	#可用网格
	var walkable_tiles = tilemap.get_used_cells()
	#攻击范围2
	for i in 2:
		for j in now:
			var neighbours = GlobalUtils.get_neighbors(j)
			for k in neighbours:
				if(!open.has(k) && k != tile && walkable_tiles.has(k)):
					open.append(k)
					move_range.append(k)
		now.clear()
		now.append_array(open)
	return move_range


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
