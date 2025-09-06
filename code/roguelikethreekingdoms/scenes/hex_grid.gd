extends Node2D
#图层
#玩家 2
#山脉 3
#可行走地图 0

@onready var walkable_map: TileMapLayer = $walkable_map
@onready var block_map: TileMapLayer = $block_map
@onready var gamer_manager: Node2D = $GamerManager

#高亮颜色
const HIGHLIGHT_COLOR = Color(1, 0.5, 0.5, 0.7)

#画一个多边形高亮用来鼠标经过地图显示
var hover_effect: Polygon2D

#画N个多边形高亮用来显示移动范围
var move_range_show: Array[Polygon2D] = []

#当前选中角色
var now_selected_gamer: Gamer


func _ready():
	#把一个多边形加入到树中
	setup_hover_polygon()


func _process(_delta):
	#处理鼠标经过高亮
	handle_hover_effect()


#鼠标移上去效果
func setup_hover_polygon() -> void:
	#多边形
	hover_effect = Polygon2D.new()
	hover_effect.polygon = PackedVector2Array([
		Vector2(0, -16), 
		Vector2(-32, -8), 
		Vector2(-32, 11), 
		Vector2(0, 19), 
		Vector2(32, 11), 
		Vector2(32, -8)
	])
	hover_effect.color = Color(1, 1, 0, 0.2)
	hover_effect.visible = true
	add_child(hover_effect)


#处理鼠标经过高亮
func handle_hover_effect() -> void:
	#鼠标坐标
	var mouse_pos = get_local_mouse_position()
	#鼠标坐标转单元格
	var mouse_tile = walkable_map.local_to_map(mouse_pos)
	#可用网格
	var used_cells = walkable_map.get_used_cells()

	if used_cells.has(mouse_tile):
		#转换网格到坐标
		var local_pos = walkable_map.map_to_local(mouse_tile)
		hover_effect.position = local_pos
		hover_effect.visible = true
	else:
		hover_effect.visible = false


#显示角色移动范围
func show_walk_height_tile(gamer:Gamer):
	#先清一下
	disable_walk_height_tile()
	#获取移动范围全部单元格
	var walk_range = GlobalUtils.find_range(gamer, walkable_map, block_map, gamer_manager)
	
	for i in walk_range:
		#转换网格到坐标
		var local_pos = walkable_map.map_to_local(i)
		#多边形
		var hover_effect = Polygon2D.new()
		hover_effect.polygon = PackedVector2Array([
			Vector2(0, -16), 
			Vector2(-32, -8), 
			Vector2(-32, 11), 
			Vector2(0, 19), 
			Vector2(32, 11), 
			Vector2(32, -8)
		])
		hover_effect.color = Color(1, 1, 0, 0.4)
		hover_effect.visible = true
		hover_effect.position = local_pos
		move_range_show.append(hover_effect)
		add_child(hover_effect)
	
	
#选中
func select_gamer(gamer:Gamer):
	if(now_selected_gamer == null):
		if(gamer.gamer_type == 2):
			show_walk_height_tile(gamer)
	elif(now_selected_gamer != gamer):
		show_walk_height_tile(gamer)
	now_selected_gamer = gamer	

#隐藏高亮范围
func disable_walk_height_tile():
	for i in move_range_show:
		i.queue_free()
	move_range_show = []
	

#未处理的输入事件捕获
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			now_selected_gamer = null
			disable_walk_height_tile()
		if event.button_index == MOUSE_BUTTON_LEFT:
			#点击左键如果有选择的对象则做如下处理
			if(now_selected_gamer != null):
				var gamer_type = now_selected_gamer.gamer_type
				#if(gamer_type == 2):
					#disable_walk_height_tile()	
			
