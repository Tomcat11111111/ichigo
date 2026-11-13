extends Polygon2D

# Same period and phase as the deck tilt. The deck itself no longer heaves.
# WAVE_HEIGHT only moves the drawn surface; it is not a feel parameter.
const SAMPLES := 40
const LEVEL_SCALE := 90.0 / 48.0
const LEFT := 360.0 * LEVEL_SCALE
const RIGHT := 3760.0
const BOTTOM := 1100.0
const WAVE_LENGTH := 640.0 * LEVEL_SCALE
const WATERLINE := 6.0 * LEVEL_SCALE
const WAVE_HEIGHT := 32.0 * LEVEL_SCALE

@export var deck_path: NodePath

var _deck: Deck
var _wave := 0.0
var _crest: Line2D


func _ready() -> void:
	_deck = get_node(deck_path) as Deck
	_crest = get_node_or_null("Crest") as Line2D
	color = Color(0.05, 0.1, 0.14, 1)
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
	var surface := PackedVector2Array()
	for i in SAMPLES + 1:
		var x := lerpf(LEFT, RIGHT, float(i) / SAMPLES)
		surface.append(Vector2(x, surface_y(x)))
	var points := surface.duplicate()
	points.append(Vector2(RIGHT, BOTTOM))
	points.append(Vector2(LEFT, BOTTOM))
	polygon = points
	if _crest != null:
		_crest.points = surface
