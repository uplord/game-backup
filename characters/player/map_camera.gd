extends Camera2D
## Phase 2.3: horizontal-only follow, map-height zoom and screen-space framing.
## Uses the native Camera2D so the preview works without editor plugin activation.
## Phantom Camera addon remains available for later transitions/look-ahead.

@export var target_path: NodePath = NodePath("../PlayerController")
@export var world_bounds: Rect2 = Rect2(0.0, 0.0, 3200.0, 1080.0)
@export var horizontal_smoothing: float = 7.0
@export var portrait_hud_height: float = 170.0
@export var max_landscape_aspect: float = 16.0 / 9.0

var _target: Node2D
var _frame: Rect2
var _usable_zoom: float = 1.0
var _initialized: bool = false
var _bars: Control

func _ready() -> void:
    _target = get_node_or_null(target_path) as Node2D
    make_current()
    _bars = Control.new()
    _bars.name = "ViewportBars"
    _bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var layer := CanvasLayer.new()
    layer.name = "CameraFraming"
    layer.layer = 90
    add_child(layer)
    layer.add_child(_bars)
    get_viewport().size_changed.connect(_recalculate)
    call_deferred("_recalculate")

func _process(delta: float) -> void:
    if not is_instance_valid(_target):
        return
    var half_visible_width: float = _frame.size.x / (2.0 * _usable_zoom)
    var left: float = world_bounds.position.x + half_visible_width
    var right: float = world_bounds.end.x - half_visible_width
    var desired_x: float = world_bounds.get_center().x if left > right else clampf(_target.global_position.x, left, right)
    if not _initialized:
        global_position.x = desired_x
        _initialized = true
    else:
        global_position.x = lerpf(global_position.x, desired_x, 1.0 - exp(-horizontal_smoothing * delta))
    # Y is fixed; only the viewport framing changes when resized.

func _recalculate() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x < 1.0 or viewport_size.y < 1.0:
        return
    var width: float = viewport_size.x
    var height: float = viewport_size.y
    var landscape: bool = width >= height
    var playable_height: float = height if landscape else maxf(1.0, height - minf(portrait_hud_height, height * 0.4))
    var playable_width: float = minf(width, playable_height * max_landscape_aspect) if landscape else width
    var left: float = (width - playable_width) * 0.5
    _frame = Rect2(left, 0.0, playable_width, playable_height)
    _usable_zoom = playable_height / maxf(1.0, world_bounds.size.y)
    zoom = Vector2.ONE * _usable_zoom
    # Align the map's vertical centre with the playable region (not the HUD).
    global_position.y = world_bounds.get_center().y + (height * 0.5 - _frame.get_center().y) / _usable_zoom
    _update_bars(viewport_size)
    _initialized = false

func _update_bars(viewport_size: Vector2) -> void:
    for child in _bars.get_children():
        child.queue_free()
    _add_bar(Rect2(0.0, 0.0, _frame.position.x, viewport_size.y))
    _add_bar(Rect2(_frame.end.x, 0.0, viewport_size.x - _frame.end.x, viewport_size.y))
    _add_bar(Rect2(0.0, _frame.end.y, viewport_size.x, viewport_size.y - _frame.end.y))

func _add_bar(rect: Rect2) -> void:
    if rect.size.x <= 0.0 or rect.size.y <= 0.0:
        return
    var bar := ColorRect.new()
    bar.color = Color.BLACK
    bar.position = rect.position
    bar.size = rect.size
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _bars.add_child(bar)
