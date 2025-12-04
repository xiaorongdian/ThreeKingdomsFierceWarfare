# StatusEffectResource.gd
extends Resource
class_name StatusEffectResource

@export var effect_id: String = ""  # 唯一标识，如 "burn", "freeze"
@export var display_name: String = "效果"
@export_multiline var description: String = "效果描述"
@export var icon: Texture2D
@export_color_no_alpha var ui_color: Color = Color.WHITE

# --- 基础属性 ---
@export var duration: int = 3  # 持续回合数（0表示永久直到手动清除）
@export var max_stacks: int = 1  # 最大叠加层数
@export var application_chance: float = 1.0  # 应用时的触发概率

# --- 效果类型标签（用于互斥判断等）---
enum EffectType { DAMAGE_OVER_TIME, MOVEMENT_MOD, STAT_MOD, DISPLACEMENT, CONTROL }
@export var effect_type: EffectType = EffectType.DAMAGE_OVER_TIME

# --- 互斥规则 ---
@export var mutually_exclusive_with: Array[String] = []  # 与此效果互斥的effect_id数组

# --- 视觉/音频反馈 ---
@export var particle_scene: PackedScene  # 附着在单位身上的粒子特效
@export var application_sound: AudioStream
@export var loop_sound: AudioStream  # 持续期间循环音效
@export var shader_material: ShaderMaterial  # 应用到单位Sprite的特殊着色器

# --- 具体效果配置 ---
# 使用字典存储灵活的效果参数，根据effect_id解析
@export var effect_parameters: Dictionary = {}

# 示例参数键值（具体含义由处理器脚本解析）:
# - "damage_per_turn": 每回合伤害值
# - "movement_reduction": 移动力减少比例 (0-1)
# - "stun_chance": 每回合眩晕概率
# - "displace_distance": 位移格数
# - "displace_direction": "away", "toward", "random", "custom"
# - "heal_per_turn": 每回合治疗量

# --- 执行逻辑 ---
# 关联一个处理器脚本，专门负责此效果的具体逻辑
@export var processor_script: GDScript

# 工具方法：创建此效果的实例
func create_instance() -> StatusEffectInstance:
	var instance = StatusEffectInstance.new()
	instance.setup(self)
	return instance

# 检查是否与另一个效果互斥
func is_mutually_exclusive_with(other_effect_id: String) -> bool:
	return mutually_exclusive_with.has(other_effect_id)
