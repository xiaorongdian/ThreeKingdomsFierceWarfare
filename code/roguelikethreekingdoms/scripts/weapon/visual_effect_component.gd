# VisualEffectComponent.gd
extends Node
class_name VisualEffectComponent

# ===== 配置参数 =====
# --- 预加载的特效资源 ---
@export var melee_attack_animation: PackedScene
@export var ranged_attack_animation: PackedScene
@export var aoe_impact_animation: PackedScene
@export var projectile_scene: PackedScene  # 用于投射物武器

@export var hit_particles: PackedScene     # 命中粒子
@export var ground_target_indicator: PackedScene  # 地面目标指示器

# --- 屏幕效果 ---
@export var screen_shake_enabled: bool = true
@export var screen_shake_intensity: float = 2.0
@export var screen_shake_duration: float = 0.3

# --- 音效 ---
@export var attack_sounds: Array[AudioStreamWAV]
@export var hit_sounds: Array[AudioStreamWAV]
@export var status_apply_sounds: Dictionary = {}  # 状态名 -> 音效

# ===== 内部变量 =====
var _camera: Camera2D
var _tween: Tween

# ===== 初始化 =====
func _ready():
	# 尝试查找主摄像机（假设它位于场景根节点下并标记为主摄像机）
	_camera = get_tree().root.find_child("MainCamera", true, false) as Camera2D
	if not _camera and get_viewport().get_camera_2d():
		_camera = get_viewport().get_camera_2d()
	
	_tween = create_tween()
	_tween.kill()  # 先停止，后续再使用

# ===== 公开API：攻击特效 =====
# 播放近战攻击动画（从攻击者到目标）
func play_melee_attack(attacker_position: Vector2, target_position: Vector2, weapon_range: float = 1.0):
	if melee_attack_animation:
		var anim = melee_attack_animation.instantiate()
		get_tree().root.add_child(anim)
		
		# 设置动画位置和方向
		anim.global_position = attacker_position
		anim.look_at(target_position)
		
		# 计算距离并播放（假设动画有play_attack方法）
		if anim.has_method("play_attack"):
			anim.play_attack(attacker_position, target_position, weapon_range)
		else:
			# 如果动画没有自定义方法，就使用补间动画
			var tween = create_tween()
			tween.tween_property(anim, "global_position", target_position, 0.2)
			tween.tween_callback(anim.queue_free)
	
	_play_random_sound(attack_sounds)
	_do_screen_shake(0.5)  # 轻微屏幕抖动

# 播放远程/投射物攻击
func play_ranged_attack(attacker_position: Vector2, target_position: Vector2, is_ground_target: bool = false):
	# 1. 播放发射动画
	if ranged_attack_animation:
		var anim = ranged_attack_animation.instantiate()
		get_tree().root.add_child(anim)
		anim.global_position = attacker_position
		if anim.has_method("play_toward"):
			anim.play_toward(target_position)
	
	# 2. 创建投射物（如果有）
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
		projectile.global_position = attacker_position
		
		# 假设投射物有fly_to方法
		if projectile.has_method("fly_to"):
			projectile.fly_to(target_position, 300.0)  # 300像素/秒
		
		# 投射物命中后回调
		if projectile.has_signal("reached_target"):
			projectile.reached_target.connect(_on_projectile_hit.bind(target_position, is_ground_target), CONNECT_ONE_SHOT)
		else:
			# 如果没有信号，使用延时
			await get_tree().create_timer(0.5).timeout
			_on_projectile_hit(target_position, is_ground_target)
	
	_play_random_sound(attack_sounds)

# 播放范围攻击（AOE）效果
func play_aoe_attack(center_position: Vector2, radius: float, delay_per_ring: float = 0.1):
	if aoe_impact_animation:
		var anim = aoe_impact_animation.instantiate()
		get_tree().root.add_child(anim)
		anim.global_position = center_position
		anim.scale = Vector2.ONE * (radius / 50.0)  # 根据半径调整大小
		
		if anim.has_method("play_impact"):
			anim.play_impact()
	
	# 可以添加多层波纹效果
	for i in range(3):
		_create_impact_ring(center_position, radius * (i + 1) / 3.0, i * delay_per_ring)
	
	_play_random_sound(attack_sounds)
	_do_screen_shake(1.0)  # 较强屏幕抖动

# ===== 公开API：命中与状态特效 =====
# 播放命中效果
func play_hit_effect(position: Vector2, is_critical: bool = false, damage: int = 0):
	# 1. 粒子特效
	if hit_particles:
		var particles = hit_particles.instantiate()
		get_tree().root.add_child(particles)
		particles.global_position = position
		particles.emitting = true
		
		# 根据是否暴击调整
		if is_critical and particles.has_method("set_critical"):
			particles.set_critical(true)
		
		# 自动清理
		particles.finished.connect(particles.queue_free)
	
	# 2. 伤害数字弹出
	_spawn_damage_number(position, damage, is_critical)
	
	# 3. 音效
	_play_random_sound(hit_sounds)
	
	# 4. 轻微屏幕抖动
	_do_screen_shake(0.2)

# 附着状态效果到单位
func attach_status_effect(unit_node: Node2D, status_id: String, duration: float) -> Node:
	var effect_node: Node = null
	
	# 根据状态类型创建不同特效
	match status_id:
		"burn", "fire":
			effect_node = _create_fire_effect(unit_node)
		"freeze", "ice":
			effect_node = _create_ice_effect(unit_node)
		#"poison":
		  #  effect_node = _create_poison_effect(unit_node)
		#"stun":
		  #  effect_node = _create_stun_effect(unit_node)
		_:
			# 默认粒子效果
			effect_node = _create_generic_status_effect(unit_node, status_id)
	
	if effect_node:
		# 设置持续时间后自动移除
		if duration > 0:
			var timer = get_tree().create_timer(duration)
			timer.timeout.connect(effect_node.queue_free)
		
		# 播放状态施加音效
		if status_apply_sounds.has(status_id):
			var sound_player = AudioStreamPlayer2D.new()
			sound_player.stream = status_apply_sounds[status_id]
			sound_player.global_position = unit_node.global_position
			get_tree().root.add_child(sound_player)
			sound_player.play()
			sound_player.finished.connect(sound_player.queue_free)
	
	return effect_node

# 播放位移效果
func play_displacement_effect(from_position: Vector2, to_position: Vector2, is_self: bool = false):
	# 1. 创建拖尾效果
	var trail_points = [from_position, to_position]
	_create_trail_effect(trail_points, Color.SKY_BLUE if is_self else Color.ORANGE_RED)
	
	# 2. 落地/撞击效果
	var impact_pos = to_position if is_self else from_position
	play_hit_effect(impact_pos, false, 0)
	
	# 3. 屏幕抖动
	_do_screen_shake(0.3)

# ===== 公开API：UI与指示器 =====
# 显示攻击范围指示器
func show_range_indicator(center: Vector2, range_tiles: Array[Vector2], tile_size: Vector2 = Vector2(64, 64)):
	# 清除之前的指示器
	_clear_old_indicators("RangeIndicator")
	
	for tile_pos in range_tiles:
		if ground_target_indicator:
			var indicator = ground_target_indicator.instantiate()
			indicator.name = "RangeIndicator"
			get_tree().root.add_child(indicator)
			
			# 将格子坐标转换为像素坐标
			var world_pos = Vector2(
				center.x + tile_pos.x * tile_size.x,
				center.y + tile_pos.y * tile_size.y
			)
			indicator.global_position = world_pos

# 清除所有指示器
func clear_indicators():
	_clear_old_indicators("RangeIndicator")
	_clear_old_indicators("TargetIndicator")

# ===== 私有辅助方法 =====
func _on_projectile_hit(target_position: Vector2, is_ground_target: bool):
	if is_ground_target:
		play_aoe_attack(target_position, 50.0)
	else:
		play_hit_effect(target_position)

func _create_impact_ring(center: Vector2, radius: float, delay: float):
	await get_tree().create_timer(delay).timeout
	
	# 创建圆形冲击波
	var ring = Line2D.new()
	ring.name = "ImpactRing"
	get_tree().root.add_child(ring)
	
	# 生成圆形点
	var points: PackedVector2Array = []
	var segments = 32
	for i in range(segments + 1):
		var angle = i * TAU / segments
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	ring.points = points
	ring.width = 3.0
	ring.default_color = Color(1, 0.8, 0.2, 0.7)
	
	# 动画：扩大并淡出
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * 1.5, 0.3)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.tween_callback(ring.queue_free)

func _spawn_damage_number(position: Vector2, damage: int, is_critical: bool):
	var label = Label.new()
	label.name = "DamageNumber"
	get_tree().root.add_child(label)
	
	label.text = str(damage)
	label.position = position
	label.add_theme_font_size_override("font_size", 24 if is_critical else 18)
	label.modulate = Color.RED if is_critical else Color.WHITE
	
	# 向上飘动并淡出
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", position.y - 50, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _create_fire_effect(unit: Node2D) -> Node:
	var particles = CPUParticles2D.new()
	unit.add_child(particles)
	
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.8
	particles.direction = Vector2(0, -1)
	particles.spread = 45
	particles.gravity = Vector2(0, 98)
	particles.initial_velocity = 20
	
	var material = ParticleProcessMaterial.new()
	material.trail_color_modifier = Gradient.new()
	material.trail_color_modifier.offsets = [0.0, 1.0]
	material.trail_color_modifier.colors = [Color.ORANGE_RED, Color.TRANSPARENT]
	particles.process_material = material
	
	return particles

func _create_ice_effect(unit: Node2D) -> Node:
	var sprite = Sprite2D.new()
	unit.add_child(sprite)
	
	# 这里应该加载一个冰霜纹理
	# sprite.texture = preload("res://effects/ice_overlay.png")
	sprite.modulate = Color(0.5, 0.8, 1.0, 0.6)
	sprite.z_index = 10
	
	return sprite

func _create_trail_effect(points: Array, color: Color):
	var line = Line2D.new()
	get_tree().root.add_child(line)
	
	line.points = points
	line.width = 4.0
	line.default_color = color
	line.modulate.a = 0.7
	
	# 淡出并消失
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	tween.tween_callback(line.queue_free)

func _do_screen_shake(intensity_multiplier: float = 1.0):
	if not screen_shake_enabled or not _camera:
		return
	
	var original_offset = _camera.offset
	var shake_intensity = screen_shake_intensity * intensity_multiplier
	
	# 创建随机抖动
	var tween = create_tween()
	for i in range(5):
		var random_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		tween.tween_property(_camera, "offset", original_offset + random_offset, 0.05)
	
	tween.tween_property(_camera, "offset", original_offset, 0.1)

func _play_random_sound(sounds: Array[AudioStreamWAV]):
	if sounds.size() == 0:
		return
	
	var sound_player = AudioStreamPlayer2D.new()
	get_tree().root.add_child(sound_player)
	
	sound_player.stream = sounds[randi() % sounds.size()]
	sound_player.play()
	sound_player.finished.connect(sound_player.queue_free)

func _clear_old_indicators(tag: String):
	for node in get_tree().root.get_children():
		if node.name == tag:
			node.queue_free()

func _create_generic_status_effect(unit: Node2D, status_id: String) -> Node:
	# 创建一个简单的粒子效果作为默认
	var particles = CPUParticles2D.new()
	unit.add_child(particles)
	
	particles.emitting = true
	particles.amount = 8
	particles.lifetime = 1.5
	particles.explosiveness = 0.8
	
	return particles
