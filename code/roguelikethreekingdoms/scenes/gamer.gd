extends Node2D

class_name Gamer

#大地图
@onready var hex_grid: Node2D = $"../.."
#血条
@onready var health_ui: Control = $HealthUI
#血条容器
@onready var h_box_container: HBoxContainer = $HealthUI/HBoxContainer

#移动距离
@export var max_step:int = 3
#是玩家还是敌人 1我方 2敌人 3友军单位 4山脉 5民房 6要保护/摧毁的建筑
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
	health_ui.visible = false;
	if gamer_type == 5:
		var text_array = h_box_container.get_children() as Array[TextureRect]
		for text in text_array:
			text.texture = load("res://Tiles/tile_0070.png")
		


func _process(delta: float) -> void:
	pass
