extends Node
class_name GlobalUtils

static func get_path_to_tile(
	#起始坐标
	start_pos: Vector2,
	#终点坐标
	target_pos: Vector2,
	#可行走图层
	tilemap: TileMapLayer,
	#阻塞的图层
	blocked_layer: TileMapLayer
) -> PackedVector2Array:
	print("Start pos (world): ", start_pos)
	print("Target pos (world): ", target_pos)
	
	#转网格
	var start_tile = tilemap.local_to_map(start_pos)
	var end_tile = tilemap.local_to_map(target_pos)
	
	print("Start tile (map): ", start_tile)
	print("End tile (map): ", end_tile)
	
	# If start and end are the same tile, return empty path
	if start_tile == end_tile:
		print("Start and end tiles are the same")
		return PackedVector2Array([])
	
	# Get all walkable tiles (excluding blocked tiles)
	var all_tiles = tilemap.get_used_cells()
	var blocked_tiles = blocked_layer.get_used_cells()
	var walkable_tiles = all_tiles.filter(func(tile): return not blocked_tiles.has(tile))
	print("Total tiles: ", all_tiles.size(), ", Blocked tiles: ", blocked_tiles.size(), ", Walkable tiles: ", walkable_tiles.size())
	
	# Create AStar2D pathfinder
	var astar = AStar2D.new()
	
	# 先把walkable_tiles网格加入astar中
	for tile in walkable_tiles:
		var point_id = _get_point_id(tile)
		# Store tile coordinates for pathfinding
		astar.add_point(point_id, Vector2(tile))
	
	# 建立连接，每次都重新绘制连接
	for tile in walkable_tiles:
		var point_id = _get_point_id(tile)
		
		for neighbor in _get_neighbors(tile):
			if walkable_tiles.has(neighbor):
				var neighbor_id = _get_point_id(neighbor)
				if not astar.are_points_connected(point_id, neighbor_id):
					astar.connect_points(point_id, neighbor_id)
	
	#获取开始和目的网格id
	var start_id = _get_point_id(start_tile)
	var end_id = _get_point_id(end_tile)
	
	# Return empty path if either start or end is not in the graph
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		print("No valid path: start or end point not in graph")
		return PackedVector2Array([])
	
	#返回一组路径点
	var tile_path = astar.get_point_path(start_id, end_id)
	
	#定义一组坐标点
	var world_path: PackedVector2Array = PackedVector2Array([])
	for tile_pos in tile_path:
		#返回网格中心坐标
		var world_pos = tilemap.map_to_local(Vector2i(tile_pos))
		# Include all points to ensure precise center-to-center movement 中心对中心的移动
		world_path.append(world_pos)
		print("Adding world pos to path: ", world_pos)
	
	print("Final path length: ", world_path.size())
	if world_path.is_empty():
		print("Warning: Generated path is empty!")
	else:
		print("First path point: ", world_path[0])
	return world_path


static func _get_point_id(tile: Vector2i) -> int:
	# Convert 2D coordinates to unique ID 康托尔配对函数
	var a = tile.x + 10000
	var b = tile.y + 10000
	return (a + b) * (a + b + 1) / 2 + b


static func _get_neighbors(tile: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	# Only orthogonal neighbors for isometric grid
	print("tile.x:",tile.x,",tile.y:",tile.y)
	neighbors.append(Vector2i(tile.x + 1, tile.y))#右下
	neighbors.append(Vector2i(tile.x - 1, tile.y))#左上
	neighbors.append(Vector2i(tile.x, tile.y + 1))#左下
	neighbors.append(Vector2i(tile.x, tile.y - 1))#右上
	neighbors.append(Vector2i(tile.x - 1, tile.y + 1))#左
	neighbors.append(Vector2i(tile.x + 1, tile.y - 1))#右
	return neighbors


#移动范围格子返回--洪水算法 广度优先、tilemap可行走的图层 blocked_layer 不可行走图层
static func find_range(gamer:Gamer, 
			tilemap: TileMapLayer,
			blocked_layer: TileMapLayer)-> Array[Vector2i]:
	var range:Array[Vector2i] = []
	var open:Array[Vector2i] = []
	var now:Array[Vector2i] = []
	
	#玩家当前位置
	var gamer_position = gamer.global_position
	print("gamer位置：", gamer.position)
	#转地图网格
	var tile = tilemap.local_to_map(gamer_position)
	print("gamer所在网格x：",tile.x,"gamer所在网格y：",tile.y)
	now.append(tile)
	#阻塞网格
	var blocked_tiles = blocked_layer.get_used_cells()
	#可用网格
	var walkable_tiles = tilemap.get_used_cells()

	for i in gamer.max_step:
		for j in now:
			var neighbours = _get_neighbors(j)
			for k in neighbours:
				if(!open.has(k) && k != tile 
				&& !blocked_tiles.has(k) && walkable_tiles.has(k)):
					open.append(k)
					range.append(k)
		now.clear()
		now.append_array(open)
	return range
