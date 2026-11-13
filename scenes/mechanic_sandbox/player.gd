extends CharacterBody2D

# Design-doc feel values, multiplied by the 90/48 level scale so the
# enlarged deck and platforms stay reachable. Change only after a playtest.
const LEVEL_SCALE := 90.0 / 48.0
const SPEED := 180.0 * LEVEL_SCALE
# The design doc binds no sprint cap. 300 px/s is the previous sandbox value.
const SPRINT_SPEED := 300.0 * LEVEL_SCALE
const JUMP_SPEED := 420.0 * LEVEL_SCALE
const GRAVITY := 1200.0 * LEVEL_SCALE
const SLIDE_ANGLE := deg_to_rad(12.0)
const FLOOR_BIAS := 40.0 * LEVEL_SCALE
const LEVEL_LEFT := 0.0
const LEVEL_RIGHT := 3760.0
# Top of the 90px body rectangle. Feet stay at the origin.
const HEAD_LOCAL := Vector2(0, -90)
const Sea := preload("res://scenes/mechanic_sandbox/sea.gd")

@export var sea_path: NodePath
@export var camera_path: NodePath

var _slide_speed := 0.0
var _sea: Sea
var _camera: Camera2D
var _visual: Node2D
var _drowned := false


func _ready() -> void:
	floor_snap_length = 12.0 * LEVEL_SCALE
	_visual = get_node_or_null("Visual") as Node2D
	if not sea_path.is_empty():
		_sea = get_node(sea_path) as Sea
	if not camera_path.is_empty():
		_camera = get_node(camera_path) as Camera2D
	_bind_key(&"move_left", KEY_A)
	_bind_key(&"move_left", KEY_LEFT)
	_bind_key(&"move_right", KEY_D)
	_bind_key(&"move_right", KEY_RIGHT)
	_bind_key(&"jump", KEY_SPACE)
	_bind_key(&"sprint", KEY_SHIFT)


func _physics_process(delta: float) -> void:
	var input_x := Input.get_axis(&"move_left", &"move_right")
	var deck := _deck_underfoot()
	var jumping := Input.is_action_just_pressed(&"jump") and is_on_floor()

	if jumping:
		_slide_speed = 0.0
		velocity = Vector2(input_x * _move_speed(), -JUMP_SPEED)
		rotation = deck.rotation if deck != null else 0.0
	elif deck != null:
		rotation = deck.rotation
		_apply_deck_motion(deck.rotation, input_x, delta)
	elif is_on_floor():
		rotation = 0.0
		_slide_speed = 0.0
		velocity = Vector2(input_x * _move_speed(), 0.0)
	else:
		rotation = 0.0
		_slide_speed = 0.0
		velocity.x = input_x * _move_speed()
		velocity.y += GRAVITY * delta

	_face(input_x)
	move_and_slide()
	_follow_player()
	if _head_is_underwater():
		_drown()
		return


func _apply_deck_motion(surface_angle: float, input_x: float, delta: float) -> void:
	var tangent := Vector2.RIGHT.rotated(surface_angle)
	var control := tangent * input_x * _move_speed()
	if abs(surface_angle) > SLIDE_ANGLE:
		var downhill := tangent if tangent.dot(Vector2.DOWN) > 0.0 else -tangent
		_slide_speed += GRAVITY * sin(abs(surface_angle)) * delta
		velocity = control + downhill * _slide_speed
	else:
		_slide_speed = 0.0
		velocity = control
	velocity -= Vector2.UP.rotated(surface_angle) * FLOOR_BIAS


func _face(input_x: float) -> void:
	if _visual == null or input_x == 0.0:
		return
	var magnitude := absf(_visual.scale.x)
	# Unflipped parts point to the right.
	_visual.scale.x = magnitude if input_x > 0.0 else -magnitude


func _move_speed() -> float:
	if Input.is_action_pressed(&"sprint"):
		return SPRINT_SPEED
	return SPEED


func _follow_player() -> void:
	if _camera == null:
		return
	var half_width := 960.0 / (2.0 * _camera.zoom.x)
	var x := clampf(global_position.x, LEVEL_LEFT + half_width, LEVEL_RIGHT - half_width)
	_camera.global_position = Vector2(x, _camera.global_position.y)


func _head_is_underwater() -> bool:
	if _sea == null:
		return false
	var head := to_global(HEAD_LOCAL)
	if not _sea.covers(head.x):
		return false
	return head.y > _sea.surface_y(head.x)


func _drown() -> void:
	if _drowned:
		return
	_drowned = true
	get_tree().reload_current_scene()


func _deck_underfoot() -> Deck:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_normal().dot(Vector2.UP) < 0.5:
			continue
		var collider := collision.get_collider()
		if collider is Deck:
			return collider
	return null


func _bind_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
