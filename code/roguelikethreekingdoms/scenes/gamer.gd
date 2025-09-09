extends Node2D

class_name Gamer

#大地图
@onready var hex_grid: Node2D = $"../.."

#移动距离
var max_step:int = 3
#是玩家还是敌人 1玩家 2敌人 3中立
@export var gamer_type:int = 1
#是否仙人 1是 0否
var is_immortal:bool = false
#是否名将 1是 0否
var is_famous_generals:bool
#是否在移动 1是 0否
var is_moving:bool = false


func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass


#鼠标经过角色
func on_mouse_entered():
	print("鼠标经过角色")
	#移动范围网格高亮
	if(gamer_type != 2 && hex_grid.now_selected_gamer == null):
		hex_grid.show_walk_height_tile(self)
	
	
#输入事件 视窗、事件、坐标
func on_input_event(viewport:Node, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		var input_event  = event as InputEventMouseButton
		if input_event.is_pressed():
			if(input_event.button_index == MouseButton.MOUSE_BUTTON_LEFT):
				#选中
				hex_grid.select_gamer(self)
				print("鼠标左键事件触发选中对象")


func on_mouse_exited():
	print("鼠标移走角色")
	#if(hex_grid.now_selected_gamer == null):
		#移走取消移动范围高亮
		#hex_grid.disable_walk_height_tile(self)
