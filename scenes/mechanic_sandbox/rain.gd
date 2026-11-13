extends Node2D

const DROP_COUNT := 90
const VIEW_HALF := Vector2(760, 460)
const FALL := 820.0
const WIND := 160.0

@export var camera_path: NodePath

var _camera: Camera2D
var _drops := PackedVector2Array()
var _lengths := PackedFloat32Array()


func _ready() -> void:
	_camera = get_node(camera_path) as Camera2D
	for _i in DROP_COUNT:
		_drops.append(Vector2(
			randf_range(-VIEW_HALF.x, VIEW_HALF.x),
			randf_range(-VIEW_HALF.y, VIEW_HALF.y)
		))
		_lengths.append(randf_range(14.0, 32.0))


func _process(delta: float) -> void:
	global_position = _camera.global_position
	for i in DROP_COUNT:
		var drop := _drops[i]
		drop.x += WIND * delta
		drop.y += FALL * delta
		if drop.y > VIEW_HALF.y:
			drop.y = -VIEW_HALF.y
			drop.x = randf_range(-VIEW_HALF.x, VIEW_HALF.x)
		elif drop.x > VIEW_HALF.x:
			drop.x = -VIEW_HALF.x
		_drops[i] = drop
	queue_redraw()


func _draw() -> void:
	var color := Color(0.72, 0.78, 0.82, 0.28)
	for i in DROP_COUNT:
		var drop := _drops[i]
		draw_line(drop, drop + Vector2(5, _lengths[i]), color, 1.0)
