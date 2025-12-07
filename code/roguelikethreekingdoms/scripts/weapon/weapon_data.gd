# WeaponData.gd
extends Resource
class_name WeaponData

#武器名称
@export var name: String = ""
#武器图标
@export var icon: Texture2D
#武器攻击范围
@export var range_component: PackedScene
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
