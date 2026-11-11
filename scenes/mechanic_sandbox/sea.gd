extends Polygon2D

# Same period and phase as the deck: the surface at the deck's rest point
# rises when the deck rises. This stage is still geometry, not ocean art.
const SAMPLES := 16
const LEFT := 360.0
const RIGHT := 960.0
const BOTTOM := 540.0
const WAVE_LENGTH := 640.0
const WATERLINE := 6.0

@export var deck_path: NodePath

var _deck: Deck


func _ready() -> void:
	_deck = get_node(deck_path) as Deck
	color = Color(0.16, 0.34, 0.4, 1)


func _physics_process(_delta: float) -> void:
	var wave := sin(_deck.phase)
	var points := PackedVector2Array()
	for i in SAMPLES + 1:
		var x := lerpf(LEFT, RIGHT, float(i) / SAMPLES)
		var along := cos((x - _deck.rest_position.x) / WAVE_LENGTH * TAU)
		var y := _deck.rest_position.y + WATERLINE - wave * Deck.HEAVE * along
		points.append(Vector2(x, y))
	points.append(Vector2(RIGHT, BOTTOM))
	points.append(Vector2(LEFT, BOTTOM))
	polygon = points
