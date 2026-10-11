extends Node2D
## Wide map to demonstrate horizontal follow and edge clamping.
func _draw() -> void:
    draw_rect(Rect2(0, 0, 3200, 1080), Color(0.16, 0.27, 0.19), true)
    for x in range(0, 3201, 64):
        draw_line(Vector2(x, 0), Vector2(x, 1080), Color(0.24, 0.36, 0.26), 1.0)
    for y in range(0, 1081, 64):
        draw_line(Vector2(0, y), Vector2(3200, y), Color(0.24, 0.36, 0.26), 1.0)
    draw_rect(Rect2(0, 0, 3200, 1080), Color(0.85, 0.85, 0.65), false, 6.0)
