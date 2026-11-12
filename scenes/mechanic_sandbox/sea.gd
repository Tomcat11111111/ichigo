extends Polygon2D

# Same period and phase as the deck tilt. The deck itself no longer heaves;
# WAVE_HEIGHT is only the drawn surface. Geometry, not ocean art.
const SAMPLES := 16
const LEVEL_SCALE := 90.0 / 48.0
const LEFT := 360.0 * LEVEL_SCALE
const RIGHT := 960.0 * LEVEL_SCALE
const BOTTOM := 540.0 * LEVEL_SCALE
const WAVE_LENGTH := 640.0 * LEVEL_SCALE
const WATERLINE := 6.0 * LEVEL_SCALE
const WAVE_HEIGHT := 32.0 * LEVEL_SCALE

@export var deck_path: NodePath

var _deck: Deck
var _wave := 0.0


func _ready() -> void:
	_deck = get_node(deck_path) as Deck
	color = Color(0.16, 0.34, 0.4, 1)
	_rebuild()


func _physics_process(_delta: float) -> void:
	_wave = sin(_deck.phase)
	_rebuild()


func covers(x: float) -> bool:
	return x >= LEFT and x <= RIGHT


func surface_y(x: float) -> float:
	var along := cos((x - _deck.position.x) / WAVE_LENGTH * TAU)
	return _deck.position.y + WATERLINE - _wave * WAVE_HEIGHT * along


func _rebuild() -> void:
	var points := PackedVector2Array()
	for i in SAMPLES + 1:
		var x := lerpf(LEFT, RIGHT, float(i) / SAMPLES)
		points.append(Vector2(x, surface_y(x)))
	points.append(Vector2(RIGHT, BOTTOM))
	points.append(Vector2(LEFT, BOTTOM))
	polygon = points
