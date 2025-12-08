extends Node2D
class_name Weapon

 ## 信号：发一个信号给主场景，加入武器攻击范围高亮图块
const EventBus = CoreSystem.EventBus
var event_bus : EventBus = CoreSystem.event_bus

@export var def : WeaponData

#武器的目标选择器组件
#@export var target_selector_component: PackedScene
#武器攻击效果组件 施加伤害、状态效果和判断友军伤害
#@export var attac_effect_component: PackedScene
#处理各种位移效果
#@export var displacement_component: PackedScene
#特效音效
#@export var visual_effect_component: PackedScene
#基础伤害
@export var base_damage: int = 1

#攻击范围实例
@onready var _range_instance

#攻击范围网格数组
var _weapon_range_array: Array[Vector2i] = []
#画N个多边形高亮用来显示攻击范围
var _weapon_range_show: Array[Polygon2D] = []
#画N个多边形高亮用来显示攻击范围-还未选中时
var _weapon_range_show_no_selected: Array[Polygon2D] = []


func _ready() -> void:
	if def:
		if def.range_component:
			## 1. 加载场景模板（PackedScene）
			var range_scene = load(def.range_component.resource_path)
			## 2. 实例化场景，得到真正的节点对象（关键步骤！）
			_range_instance = range_scene.instantiate()


func _process(delta: float) -> void:
	pass
	
	
#当武器被选中时，显示攻击范围
func show_attack_range(tilemap: TileMapLayer):
	if _range_instance == null:
		return
	
	#1.获取受影响的格子
	var affected_tiles = _range_instance.get_affected_tiles(self.get_parent(), tilemap)
	print("affected_tiles:" , affected_tiles)

	_weapon_range_array = affected_tiles
	#2.可视化显示（调试或给玩家看）
	#range_instance.highlight_tiles(affected_tiles,Color(1,0.3,0.3,0.5))
	_highlight_tiles(tilemap, Color(1,0.3,0.3,0.5))
	#3.也可以将格子数据传递给UI或战斗系统
	return affected_tiles


#高亮攻击范围网格
func _highlight_tiles(tile_map:TileMapLayer, color:Color = Color(1,0.3,0.3,0.5)):
	if _weapon_range_show:
		return
	for i in _weapon_range_array:
		#转换网格到坐标
		var local_pos = tile_map.map_to_local(i)
		#多边形
		var one_weapon_range = Polygon2D.new()
		one_weapon_range.polygon = PackedVector2Array([
			Vector2(0, -16), 
			Vector2(-32, -8), 
			Vector2(-32, 11), 
			Vector2(0, 19), 
			Vector2(32, 11), 
			Vector2(32, -8)
		])
		one_weapon_range.color = Color(1,0.3,0.3,0.5)
		one_weapon_range.visible = true
		one_weapon_range.position = local_pos
		_weapon_range_show.append(one_weapon_range)
	event_bus.push_event("add_weapon_range", [_weapon_range_show])


##1. 点击目标格子攻击 
## 假设传入的是攻击者的格子坐标 (attacker_cell) 和被点击的目标格子坐标 (target_cell)
#func get_attack_direction_from_cells(attacker_cell: Vector2i, target_cell: Vector2i) -> Vector2:
	## 计算格子坐标的差值，并转换为标准化向量（即长度为1的方向）
	#var direction_vector = Vector2(target_cell - attacker_cell)
	#return direction_vector.normalized()
#
#
##2. 使用方向键/摇杆选择 (传统战棋)
## 在某个处理输入的函数中（例如 _unhandled_input）
#func get_attack_direction_from_input() -> Vector2:
	#var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	## 确保玩家确实按下了方向键，而不是零向量
	#if input_direction != Vector2.ZERO:
		#return input_direction.normalized()
	## 如果没有输入，可以返回一个默认方向，如 Vector2.RIGHT
	#return Vector2.RIGHT
	#
	#
## 3. 鼠标悬停/自由选择方向 假设这个函数在武器节点中调用，且武器是 Node2D 类型
#func get_attack_direction_to_mouse() -> Vector2:
	## 获取鼠标在游戏世界中的全局位置
	#var mouse_pos = get_global_mouse_position()
	## 计算从武器自身指向鼠标位置的方向
	#var direction = global_position.direction_to(mouse_pos)
	#return direction
#
#
##计算出武器本次攻击的目标方向
##1. 点击目标格子攻击 (最直观)	方向由攻击者位置指向被点击的格子。
##2. 使用方向键/摇杆选择 (传统战棋)	方向由玩家按下的方向键决定。
##3. 鼠标悬停/自由选择方向	方向由攻击者位置指向鼠标光标的世界坐标。
#func _get_aim_direction() -> Vector2:
	#return Vector2.RIGHT

#隐藏武器范围
func _disable_range_height_tile():
	for i in _weapon_range_show:
		i.queue_free()
	for i in _weapon_range_show_no_selected:
		i.queue_free()	
	_weapon_range_show = []
	_weapon_range_show_no_selected = []
	_weapon_range_array = []
