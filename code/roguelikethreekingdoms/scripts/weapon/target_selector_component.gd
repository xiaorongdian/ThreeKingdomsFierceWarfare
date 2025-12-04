# TargetSelectorComponent.gd
extends Node
#武器的目标选择器组件
enum SelectMode {NONE, DIRECTION, TARGET_CELL, TWO_POINTS}
var current_mode = SelectMode.NONE
var first_selection: Vector2

signal selection_completed(selected_cells: Array[Vector2])

func begin_selection(mode: SelectMode):
	current_mode = mode
	first_selection = Vector2.ZERO
	# 这里可以启用UI提示或输入监听

func handle_cell_click(cell: Vector2):
	match current_mode:
		SelectMode.DIRECTION:
			emit_signal("selection_completed", [cell])
		SelectMode.TWO_POINTS:
			if first_selection == Vector2.ZERO:
				first_selection = cell
				# 提示进行第二次选择
			else:
				emit_signal("selection_completed", [first_selection, cell])
				current_mode = SelectMode.NONE
