# RangeComponent.gd
extends Node2D
class_name ZhuGeNuRangeComponent

# ===== 配置参数 =====
enum RangeType {LINE, CIRCLE, CONE, CROSS, SELF_AREA, PROJECTILE}
@export var range_type: RangeType = RangeType.LINE
@export var range_value: int = 3  # 直线长度、圆形半径等
@export var min_range: int = 0    # 最小距离（例如，弓箭不能攻击脚下）
@export var through_obstacle: bool = false  # 是否穿透障碍
@export var custom_pattern: PackedVector2Array = []  # 自定义形状的偏移量


# ===== 内部节点引用 =====
@onready var _tile_map: TileMap = get_tree().root.find_child("TileMap", true, false)  # 假设你的地图叫TileMap
	
func get_affected_tiles(owner_node:Node2D,
						tilemap: TileMapLayer) -> Array[Vector2i]:
	var owner_position = owner_node.global_position
	var tile = tilemap.local_to_map(owner_position)
	#可用网格
	var walkable_tiles = tilemap.get_used_cells()
	var rangeArray: Array[Vector2i] = []
	for i in 3:
		var youxia = Vector2i(tile.x + 2 + i, tile.y)#右下
		if walkable_tiles.has(youxia):
			rangeArray.append(youxia)
			
		var zuoshang = Vector2i(tile.x - 2 - i, tile.y)#左上
		if walkable_tiles.has(zuoshang):
			rangeArray.append(zuoshang)
			
		var zuoxia = Vector2i(tile.x, tile.y + 2 + i)#左下
		if walkable_tiles.has(zuoxia):
			rangeArray.append(zuoxia)
			
		var youshang = Vector2i(tile.x, tile.y - 2 - i)#右上
		if walkable_tiles.has(youshang):
			rangeArray.append(youshang)
			
		var zuo = Vector2i(tile.x - 2 - i, tile.y + 2 + i)#左
		if walkable_tiles.has(zuo):
			rangeArray.append(zuo)
			
		var you = Vector2i(tile.x + 2 + i, tile.y - 2 - i)#右
		if walkable_tiles.has(you):
			rangeArray.append(you)
	return rangeArray


# ===== 辅助函数 =====
func _is_cell_blocked(cell: Vector2i) -> bool:
	if not _tile_map:
		return false
	# 这里实现你的障碍检测逻辑
	# 例如：检查tile_map的某个图层，或者查询游戏单位的占用情况
	return false  # 默认返回false


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
func highlight_tiles(tiles: Array[Vector2i], color: Color = Color(1, 0, 0, 0.5)):
	# 清除之前的高亮
	for child in get_children():
		child.queue_free()
	
	# 为每个格子创建一个高亮方块
	for tile in tiles:
		var world_pos = _tile_map.map_to_local(tile) if _tile_map else Vector2(tile * 64)
		var rect = ColorRect.new()
		rect.color = color
		rect.size = Vector2(64, 64)  # 假设格子大小64x64
		rect.position = world_pos
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)

func clear_highlight():
	for child in get_children():
		child.queue_free()
