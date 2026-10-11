extends CanvasLayer
## Development-only HUD. F3 toggles it; disabled in non-debug exports.
var _panel: PanelContainer
var _label: Label
var _visible_debug := false

func _ready() -> void:
    if not OS.is_debug_build():
        queue_free()
        return
    layer = 100
    _panel = PanelContainer.new()
    _panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _panel.position = Vector2(12, 12)
    _panel.custom_minimum_size = Vector2(290, 0)
    add_child(_panel)
    _label = Label.new()
    _label.add_theme_color_override("font_color", Color.WHITE)
    _panel.add_child(_label)
    _panel.visible = false
    set_process(true)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        _visible_debug = not _visible_debug
        _panel.visible = _visible_debug
        get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
    if not _visible_debug:
        return
    var current_area := str(GameState.get("current_area")) if GameState.get("current_area") != null else "n/a"
    _label.text = "UPLORD DEBUG [F3]\nFPS: %d\nMode: %s\nArea: %s\nLog entries: %d" % [Engine.get_frames_per_second(), str(GameManager.mode), current_area, DevLogger.entries().size()]
