extends Node2D

class_name Gamer

var state_machine_manager : CoreSystem.StateMachineManager = CoreSystem.state_machine_manager

#动画以及其他定义
@export var def: GamerDefinition
#名称
@onready var gamer_name: String
#武器
@onready var weapon1: Weapon = $Weapon1
@onready var weapon2: Weapon = $Weapon2
#血条
@onready var health_ui: Control = $HealthUI
#血条容器
@onready var h_box_container: HBoxContainer = $HealthUI/HBoxContainer
#状态动画
@onready var sprite: AnimatedSprite2D = %StatusSprite

#移动距离
@export var max_step:int
#是玩家还是敌人 1我方 2敌人 3友军单位 4山脉 5民房 6要保护/摧毁的建筑
@export var gamer_type:int
#是否仙人 
@export var is_immortal:bool
#是否习水(false水中淹死) 
@export var is_water_skilled:bool

#是否在移动 
var is_moving:bool = false
#是否已移动 只有 我方 和 可移动友军有意义
var is_moved:bool = false
#是否已攻击(回合结束) 只有 我方 和 可移动友军有意义
var is_attacked:bool = false


func _ready() -> void:
	_init_def()
	health_ui.visible = false;
	#民房血条
	if gamer_type == 5:
		var text_array = h_box_container.get_children() as Array[TextureRect]
		for text in text_array:
			text.texture = load("res://assets/Tiles/tile_0070.png")
		
		
func _init_def() -> void:
	sprite.sprite_frames = def.frames
	sprite.play()
	#移动距离
	max_step = def.max_step
	gamer_type = def.gamer_type
	is_immortal = def.is_immortal
	is_water_skilled = def.is_water_skilled
		
		
func _process(delta: float) -> void:
	pass
