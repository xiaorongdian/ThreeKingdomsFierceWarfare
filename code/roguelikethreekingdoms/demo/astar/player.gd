extends Node2D

#移动速度
@export var move_speed: float = 100.0
#阈值
@export var arrival_threshold: float = 1.0 # Smaller threshold for precise center alignment

#目标位置
var target_position: Vector2
#路径一组坐标点
var path: PackedVector2Array
#是否正在移动
var is_moving: bool = false

@onready var layer0: TileMapLayer = $"../Layer0"
@onready var layer1: TileMapLayer = $"../Layer1"

func _ready() -> void:
	# Snap initial position to tile center
	#玩家当前位置所在位置转网格
	var current_tile = layer0.local_to_map(global_position)
	#确定玩家位置在网格中心
	global_position = layer0.map_to_local(current_tile)
	print("Player initial position (snapped to center): ", global_position)


#未处理的输入事件捕获
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			#鼠标点击位置坐标
			var click_pos = get_global_mouse_position()
			print("\nNew movement requested")
			print("From: ", global_position)
			print("To: ", click_pos)
			
			#一组路径坐标点
			var new_path = MovementUtils.get_path_to_tile(
				global_position,
				click_pos,
				layer0,
				layer1
			)
			
			if not new_path.is_empty():
				path = new_path
				is_moving = true
				#第一个目的位置
				target_position = path[0]
				print("Path accepted, first target: ", target_position)
				#检查距离小于阈值不移动
				if target_position.distance_to(global_position) < arrival_threshold:
					print("Warning: First target too close to current position!")
					_advance_to_next_target()
			else:
				print("Path was empty, movement cancelled")
			

func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	if not is_moving or path.is_empty():
		return
		
	var distance_to_target = global_position.distance_to(target_position)
	print("Distance to target: ", distance_to_target)
	
	if distance_to_target < arrival_threshold:
		# Snap to exact center when close enough
		global_position = target_position
		_advance_to_next_target()
	else:
		var direction = (target_position - global_position).normalized()
		var movement = direction * move_speed * delta
		# Prevent overshooting by clamping movement to remaining distance
		if movement.length() > distance_to_target:
			movement = direction * distance_to_target
		global_position += movement
		print("Moving: dir=", direction, " movement=", movement, " new_pos=", global_position)


func _advance_to_next_target() -> void:
	path.remove_at(0)
	print("Point reached, remaining points: ", path.size())
	
	if path.is_empty():
		print("Path completed")
		is_moving = false
		return
		
	target_position = path[0]
	if target_position.distance_to(global_position) < arrival_threshold:
		print("Next target too close, skipping")
		_advance_to_next_target()
	else:
		print("New target set: ", target_position)
