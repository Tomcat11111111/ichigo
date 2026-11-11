extends CharacterBody2D

# Starting feel values from docs/GAME_DESIGN.md. Change only after a playtest.
const MAX_SPEED := 180.0
# The spec binds Shift but does not list a sprint cap yet.
const SPRINT_SPEED := 300.0
const ACCEL := 900.0
const COAST := 1200.0
const BRAKE := 1600.0
const JUMP_SPEED := 420.0
const GRAVITY := 1200.0
const FLOOR_BIAS := 40.0

# Grip stays full until the deck is near its steepest or fastest, then falls
# to MIN_GRIP. At ±15° that is low enough to slide, and still high enough
# that braking can slow the slide.
const STRAIN_START := 0.55
const MIN_GRIP := 0.22
const STRAIN_ACCEL := 2400.0
# Pose only. The torso stays with the stance unless balance is actually slipping.
const IMBALANCE_LEAN := deg_to_rad(6.0)
const RECOVERY_LEAN := deg_to_rad(10.0)

const BODY_COLOR := Color(0.9490196, 0.78039217, 0.63529414, 1)
const LIMB_COLOR := Color(0.76862746, 0.5764706, 0.43137255, 1)

var _along := 0.0
var _gait := 0.0

var _visual: Node2D
var _torso: Node2D
var _arm_l: Node2D
var _arm_r: Node2D
var _leg_l: Node2D
var _leg_r: Node2D


func _ready() -> void:
	floor_snap_length = 12.0
	floor_stop_on_slope = false
	_bind_key(&"move_left", KEY_A)
	_bind_key(&"move_left", KEY_LEFT)
	_bind_key(&"move_right", KEY_D)
	_bind_key(&"move_right", KEY_RIGHT)
	_bind_key(&"jump", KEY_SPACE)
	_bind_key(&"sprint", KEY_SHIFT)
	_build_body()


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	var normal := get_floor_normal() if on_floor else Vector2.UP
	var tangent := Vector2(-normal.y, normal.x)
	var deck := _deck_underfoot()
	var input_x := Input.get_axis(&"move_left", &"move_right")
	var jumping := Input.is_action_just_pressed(&"jump") and on_floor
	var along_accel := 0.0

	if jumping:
		# Horizontal speed is the speed already along the ground, not the input.
		velocity = Vector2((tangent * _along).x, -JUMP_SPEED)
	elif on_floor:
		along_accel = _move_on_floor(tangent, input_x, deck, delta)
		velocity = tangent * _along - normal * FLOOR_BIAS
	else:
		velocity.y += GRAVITY * delta

	move_and_slide()

	var grounded := is_on_floor() and not jumping
	if grounded and not on_floor:
		var floor_normal := get_floor_normal()
		var floor_tangent := Vector2(-floor_normal.y, floor_normal.x)
		_along = velocity.dot(floor_tangent)
	if grounded:
		_visual.rotation = get_floor_normal().angle() + PI * 0.5
	else:
		_visual.rotation = rotate_toward(_visual.rotation, 0.0, deg_to_rad(240.0) * delta)

	_update_pose(delta, input_x, deck, along_accel, grounded)


func _move_on_floor(tangent: Vector2, input_x: float, deck: Deck, delta: float) -> float:
	var before := _along
	_along += Vector2(0.0, GRAVITY).dot(tangent) * delta
	var grip := _grip(deck)
	if is_zero_approx(input_x):
		_along = move_toward(_along, 0.0, COAST * grip * delta)
	elif absf(_along) > 1.0 and signf(input_x) != signf(_along):
		_along = move_toward(_along, 0.0, BRAKE * grip * delta)
	else:
		var cap := SPRINT_SPEED if Input.is_action_pressed(&"sprint") else MAX_SPEED
		_along = move_toward(_along, input_x * cap, ACCEL * grip * delta)
	return 0.0 if delta == 0.0 else (_along - before) / delta


func _grip(deck: Deck) -> float:
	if deck == null:
		return 1.0
	var slope := clampf(absf(deck.rotation) / Deck.MAX_ANGLE, 0.0, 1.0)
	var spin := clampf(absf(deck.angular_velocity) / Deck.MAX_ANGULAR_SPEED, 0.0, 1.0)
	var loss := maxf(_factor_loss(slope), _factor_loss(spin))
	return lerpf(1.0, MIN_GRIP, loss)


func _factor_loss(amount: float) -> float:
	return smoothstep(STRAIN_START, 1.0, amount)


func _update_pose(
	delta: float,
	input_x: float,
	deck: Deck,
	along_accel: float,
	grounded: bool,
) -> void:
	var slope := 0.0
	var spin := 0.0
	if deck != null and grounded:
		slope = clampf(absf(deck.rotation) / Deck.MAX_ANGLE, 0.0, 1.0)
		spin = clampf(absf(deck.angular_velocity) / Deck.MAX_ANGULAR_SPEED, 0.0, 1.0)
	var accel_factor := clampf(absf(along_accel) / STRAIN_ACCEL, 0.0, 1.0)
	var strain := maxf(slope, maxf(spin, accel_factor))
	var slowing := is_zero_approx(input_x) or (absf(_along) > 1.0 and signf(input_x) != signf(_along))
	var recovering := grounded and strain >= STRAIN_START and slowing and absf(_along) > 40.0
	var blend := 1.0 - exp(-12.0 * delta)

	var facing := signf(_along) if absf(_along) > 12.0 else signf(input_x)
	if facing == 0.0:
		facing = 1.0

	var stride := 0.0
	var swing_l := 0.0
	var swing_r := 0.0
	if grounded and absf(_along) > 12.0:
		_gait += absf(_along) / 14.0 * delta
		stride = deg_to_rad(18.0) * clampf(absf(_along) / MAX_SPEED, 0.0, SPRINT_SPEED / MAX_SPEED)
		stride *= 1.0 + strain * 0.9
		if recovering:
			stride *= 1.35
		var wobble := sin(_gait * 2.17) * strain * stride * 0.45
		swing_l = sin(_gait) * stride + wobble
		swing_r = sin(_gait + PI) * stride - wobble
		if recovering:
			swing_l += stride * 0.55

	var spread := lerpf(0.2, 1.15, strain if grounded else 1.0)
	if recovering:
		spread = 1.55
	if not grounded:
		spread = 2.15
		swing_l = deg_to_rad(18.0)
		swing_r = deg_to_rad(-24.0)

	var lean := 0.0
	if grounded and strain >= STRAIN_START:
		var depth := 1.0 if recovering else smoothstep(STRAIN_START, 1.0, strain)
		var amount := RECOVERY_LEAN if recovering else IMBALANCE_LEAN
		lean = _imbalance_tip(deck) * amount * depth

	_leg_l.rotation = lerp_angle(_leg_l.rotation, -swing_l * facing, blend)
	_leg_r.rotation = lerp_angle(_leg_r.rotation, -swing_r * facing, blend)
	_arm_l.rotation = lerp_angle(_arm_l.rotation, -spread, blend)
	_arm_r.rotation = lerp_angle(_arm_r.rotation, spread, blend)
	_torso.rotation = lerp_angle(_torso.rotation, lean, blend)


func _imbalance_tip(deck: Deck) -> float:
	if deck != null:
		var slope_tip := deck.rotation / Deck.MAX_ANGLE
		var spin_tip := deck.angular_velocity / Deck.MAX_ANGULAR_SPEED
		return clampf(slope_tip + spin_tip, -1.0, 1.0)
	return clampf(_along / MAX_SPEED, -1.0, 1.0)


func _deck_underfoot() -> Deck:
	if not is_on_floor():
		return null
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_normal().dot(Vector2.UP) < 0.5:
			continue
		var collider := collision.get_collider()
		if collider is Deck:
			return collider
	return null


func _build_body() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)

	_leg_l = _limb(_visual, Vector2(-4, -20), 6.0, 20.0)
	_leg_r = _limb(_visual, Vector2(4, -20), 6.0, 20.0)
	_torso = Node2D.new()
	_torso.name = "Torso"
	_torso.position = Vector2(0, -20)
	_visual.add_child(_torso)
	_box(_torso, Rect2(-8, -18, 16, 18), BODY_COLOR)
	_box(_torso, Rect2(-6, -28, 12, 10), BODY_COLOR)
	_arm_l = _limb(_torso, Vector2(-8, -16), 4.0, 14.0)
	_arm_r = _limb(_torso, Vector2(8, -16), 4.0, 14.0)


func _limb(parent: Node2D, at: Vector2, width: float, length: float) -> Node2D:
	var pivot := Node2D.new()
	pivot.position = at
	parent.add_child(pivot)
	var half := width * 0.5
	_box(pivot, Rect2(-half, 0.0, width, length), LIMB_COLOR)
	return pivot


func _box(parent: Node2D, rect: Rect2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
	])
	parent.add_child(poly)


func _bind_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing in InputMap.action_get_events(action):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
