class_name GamerDefinition
extends Resource

enum Type {
	Knight,
	Archer,
	Mage,
	Rogue,
	Peasant
}
#名称
@export var gamer_name: String
#类型
@export var type: Type
#动画
@export var frames: SpriteFrames
#移动距离
@export var max_step:int
#是玩家还是敌人 1我方 2敌人 3友军单位 4山脉 5民房 6要保护/摧毁的建筑
@export var gamer_type:int
#是否仙人 
@export var is_immortal:bool
#是否习水 
@export var is_water_skilled:bool
