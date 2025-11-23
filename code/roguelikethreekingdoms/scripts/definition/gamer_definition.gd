class_name GamerDefinition
extends Resource

enum Type {
	Knight,
	Archer,
	Mage,
	Rogue,
	Peasant
}

@export var name: String
@export var type: Type
@export var frames: SpriteFrames
