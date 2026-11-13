extends Node2D

@export var camera_path: NodePath
# Share of camera motion this layer keeps. 1 stays locked to the level.
@export var follow := 0.3

var _camera: Camera2D
var _base_x := 0.0
var _start_cam_x := 0.0


func _ready() -> void:
	_camera = get_node(camera_path) as Camera2D
	_base_x = global_position.x
	_start_cam_x = _camera.global_position.x


func _process(_delta: float) -> void:
	var dx := _camera.global_position.x - _start_cam_x
	global_position.x = _base_x + dx * (1.0 - follow)
