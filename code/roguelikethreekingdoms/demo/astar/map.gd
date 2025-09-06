extends Node2D

@onready var layer0: TileMapLayer = $Layer0

var hover_effect: Polygon2D


func _ready() -> void:
	setup_hover_polygon()

func _process(_delta: float) -> void:
	handle_hover_effect()

# utils
#鼠标移上去效果
func setup_hover_polygon() -> void:
	#多边形
	hover_effect = Polygon2D.new()
	hover_effect.polygon = PackedVector2Array([
		Vector2(0, -8), # Top
		Vector2(16, 0), # Right
		Vector2(0, 8), # Bottom
		Vector2(-16, 0) # Left
	])
	hover_effect.color = Color(1, 1, 0, 0.2)
	hover_effect.visible = false
	add_child(hover_effect)


func handle_hover_effect() -> void:
	#鼠标坐标
	var mouse_pos = get_local_mouse_position()
	#鼠标坐标转单元格
	var mouse_tile = layer0.local_to_map(mouse_pos)
	#可用网格
	var used_cells = layer0.get_used_cells()

	if used_cells.has(mouse_tile):
		# Convert tile position back to local coordinates for the hover effect
		var local_pos = layer0.map_to_local(mouse_tile)
		hover_effect.position = local_pos
		hover_effect.visible = true
	else:
		hover_effect.visible = false
