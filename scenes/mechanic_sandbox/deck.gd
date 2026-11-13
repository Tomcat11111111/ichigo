class_name Deck
extends AnimatableBody2D

# Starting feel values from docs/GAME_DESIGN.md. Change only after a playtest.
const PERIOD := 4.0
const MAX_ANGLE := deg_to_rad(15.0)

@export var phase_offset := 0.0

var phase := 0.0


func _ready() -> void:
	phase = phase_offset


func _physics_process(delta: float) -> void:
	phase = fposmod(phase + delta / PERIOD * TAU, TAU)
	rotation = sin(phase) * MAX_ANGLE
