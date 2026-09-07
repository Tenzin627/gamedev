extends Control

var _time_seconds: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    _time_seconds += delta
    queue_redraw()

func _draw() -> void:
    var view_size: Vector2 = size
    if view_size.x <= 0.0 or view_size.y <= 0.0:
        return

    _draw_sky(view_size)
    _draw_far_landscape(view_size)
    _draw_ground(view_size)
    _draw_mist(view_size)
    _draw_stage_marks(view_size)
    _draw_vignette(view_size)

func _draw_sky(view_size: Vector2) -> void:
    var bands: int = 9
    for index: int in range(bands):
        var t: float = float(index) / float(maxi(bands - 1, 1))
        var top_color: Color = Color("#172d2d")
        var bottom_color: Color = Color("#5c6d55")
        var band_color: Color = top_color.lerp(bottom_color, t)
        var band_top: float = view_size.y * 0.0 + view_size.y * 0.48 * t
        var band_height: float = view_size.y * 0.48 / float(bands) + 2.0
        draw_rect(Rect2(0.0, band_top, view_size.x, band_height), band_color)

    var sun_center: Vector2 = Vector2(view_size.x * 0.77, view_size.y * 0.15)
    draw_circle(sun_center, view_size.y * 0.055, Color("#dccb93aa"))
    draw_circle(sun_center, view_size.y * 0.035, Color("#f1dfaa88"))

func _draw_far_landscape(view_size: Vector2) -> void:
    var horizon_y: float = view_size.y * 0.48
    var ridge_back: PackedVector2Array = PackedVector2Array([
        Vector2(0.0, horizon_y),
        Vector2(view_size.x * 0.10, horizon_y - 92.0),
        Vector2(view_size.x * 0.20, horizon_y - 38.0),
        Vector2(view_size.x * 0.31, horizon_y - 128.0),
        Vector2(view_size.x * 0.43, horizon_y - 52.0),
        Vector2(view_size.x * 0.55, horizon_y - 112.0),
        Vector2(view_size.x * 0.67, horizon_y - 45.0),
        Vector2(view_size.x * 0.80, horizon_y - 122.0),
        Vector2(view_size.x * 0.91, horizon_y - 56.0),
        Vector2(view_size.x, horizon_y - 88.0),
        Vector2(view_size.x, horizon_y + 44.0),
        Vector2(0.0, horizon_y + 44.0),
    ])
    draw_colored_polygon(ridge_back, Color("#203a31"))

    var ridge_front: PackedVector2Array = PackedVector2Array([
        Vector2(0.0, horizon_y + 54.0),
        Vector2(view_size.x * 0.12, horizon_y - 10.0),
        Vector2(view_size.x * 0.25, horizon_y + 26.0),
        Vector2(view_size.x * 0.39, horizon_y - 34.0),
        Vector2(view_size.x * 0.54, horizon_y + 18.0),
        Vector2(view_size.x * 0.69, horizon_y - 24.0),
        Vector2(view_size.x * 0.83, horizon_y + 22.0),
        Vector2(view_size.x, horizon_y - 6.0),
        Vector2(view_size.x, horizon_y + 92.0),
        Vector2(0.0, horizon_y + 92.0),
    ])
    draw_colored_polygon(ridge_front, Color("#294638"))

func _draw_ground(view_size: Vector2) -> void:
    var ground_top: float = view_size.y * 0.48
    draw_rect(Rect2(0.0, ground_top, view_size.x, view_size.y - ground_top), Color("#233b2a"))

    var near_ground: PackedVector2Array = PackedVector2Array([
        Vector2(0.0, view_size.y * 0.66),
        Vector2(view_size.x * 0.28, view_size.y * 0.60),
        Vector2(view_size.x * 0.52, view_size.y * 0.68),
        Vector2(view_size.x * 0.76, view_size.y * 0.59),
        Vector2(view_size.x, view_size.y * 0.64),
        Vector2(view_size.x, view_size.y),
        Vector2(0.0, view_size.y),
    ])
    draw_colored_polygon(near_ground, Color("#1a3123"))

    var path: PackedVector2Array = PackedVector2Array([
        Vector2(view_size.x * 0.33, view_size.y),
        Vector2(view_size.x * 0.45, view_size.y * 0.60),
        Vector2(view_size.x * 0.57, view_size.y * 0.60),
        Vector2(view_size.x * 0.72, view_size.y),
    ])
    draw_colored_polygon(path, Color("#4a5038aa"))

func _draw_mist(view_size: Vector2) -> void:
    var base_y: float = view_size.y * 0.46
    for index: int in range(7):
        var drift: float = sin(_time_seconds * 0.10 + float(index) * 1.4) * 34.0
        var center: Vector2 = Vector2(view_size.x * (0.08 + float(index) * 0.15) + drift, base_y + sin(float(index)) * 20.0)
        var points: PackedVector2Array = _oval_points(center, Vector2(128.0, 24.0), 28)
        draw_colored_polygon(points, Color("#c4d2bd12"))

func _draw_stage_marks(view_size: Vector2) -> void:
    _draw_platform(Vector2(view_size.x * 0.25, view_size.y * 0.52), Vector2(150.0, 38.0), Color("#6f81602c"))
    _draw_platform(Vector2(view_size.x * 0.73, view_size.y * 0.63), Vector2(178.0, 44.0), Color("#7e8b6533"))

func _draw_platform(center: Vector2, radius: Vector2, fill: Color) -> void:
    var points: PackedVector2Array = _oval_points(center, radius, 40)
    draw_colored_polygon(points, fill)
    var outline: PackedVector2Array = points.duplicate()
    if not outline.is_empty():
        outline.append(outline[0])
    draw_polyline(outline, Color("#d5c98a33"), 2.0, true)

func _draw_vignette(view_size: Vector2) -> void:
    var edge: float = 24.0
    draw_rect(Rect2(0.0, 0.0, view_size.x, edge), Color("#07110d40"))
    draw_rect(Rect2(0.0, view_size.y - edge, view_size.x, edge), Color("#07110d55"))
    draw_rect(Rect2(0.0, 0.0, edge, view_size.y), Color("#07110d35"))
    draw_rect(Rect2(view_size.x - edge, 0.0, edge, view_size.y), Color("#07110d35"))

func _oval_points(center: Vector2, radius: Vector2, segments: int) -> PackedVector2Array:
    var result: PackedVector2Array = PackedVector2Array()
    var safe_segments: int = maxi(segments, 8)
    for index: int in range(safe_segments):
        var angle: float = TAU * float(index) / float(safe_segments)
        result.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    return result
