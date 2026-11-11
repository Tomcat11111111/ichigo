class_name Deck
extends AnimatableBody2D

# Starting feel values from docs/GAME_DESIGN.md. Change only after a playtest.
const PERIOD := 4.0
const MAX_ANGLE := deg_to_rad(15.0)
const HEAVE := 32.0
const MAX_ANGULAR_SPEED := TAU / PERIOD * MAX_ANGLE

var phase := 0.0
var angular_velocity := 0.0
var rest_position := Vector2.ZERO

var _rest_y := 0.0
var _applied_rotation := 0.0


func _ready() -> void:
	rest_position = position
	_rest_y = position.y


func _physics_process(delta: float) -> void:
	phase = fposmod(phase + delta / PERIOD * TAU, TAU)
	var wave := sin(phase)
	var next_rotation := wave * MAX_ANGLE
	# One transform write. With sync_to_physics, separate position and rotation
	# writes revert each other and the deck only keeps the last one.
	transform = Transform2D(next_rotation, Vector2(rest_position.x, _rest_y - wave * HEAVE))
	angular_velocity = 0.0 if delta == 0.0 else (next_rotation - _applied_rotation) / delta
	_applied_rotation = next_rotation
