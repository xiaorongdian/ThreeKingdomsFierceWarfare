extends Node2D

class_name Gamer

#大地图
@onready var hex_grid: Node2D = $"../.."

#移动距离
@export var max_step:int = 3
#是玩家还是敌人 1我方 2敌人 3友军单位 4山脉 5民房 6要保护/摧毁 建筑
@export var gamer_type:int = 1
#是否仙人 
var is_immortal:bool = false
#是否名将 
var is_famous_generals:bool
#是否在移动 
var is_moving:bool = false

#是否已移动 只有 我方 和 可移动友军有意义
var is_moved:bool = false


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass
