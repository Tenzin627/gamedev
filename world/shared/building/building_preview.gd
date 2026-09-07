extends Node2D
class_name BuildingPreview

var footprint_tiles: Vector2i = Vector2i.ONE
var valid_placement: bool = false

func configure(footprint: Vector2i, valid: bool) -> void:
    footprint_tiles = footprint
    valid_placement = valid
    queue_redraw()

func _draw() -> void:
    var size_px: Vector2 = Vector2(footprint_tiles * WorldGrid.TILE_SIZE_PX)
    var rect: Rect2 = Rect2(-size_px * 0.5, size_px)
    var fill: Color = Color(0.35, 0.85, 0.48, 0.28) if valid_placement else Color(0.9, 0.3, 0.28, 0.28)
    var edge: Color = Color(0.45, 1.0, 0.6, 0.9) if valid_placement else Color(1.0, 0.4, 0.35, 0.9)
    draw_rect(rect, fill, true)
    draw_rect(rect, edge, false, 3.0)
