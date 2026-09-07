extends PanelContainer
class_name LungSaTooltipWidget

@onready var _title_label: Label = $Margin/Content/Title
@onready var _body_label: Label = $Margin/Content/Body
var _anchor_rect: Rect2 = Rect2()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    z_index = 80
    LungSaUIStyle.apply_panel(self, true)
    _title_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_ACCENT)
    _body_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_INK)
    visible = false

func show_tooltip(title: String, body: String, anchor_rect: Rect2) -> void:
    if _title_label == null or _body_label == null:
        return
    _title_label.text = title
    _body_label.text = body
    _anchor_rect = anchor_rect
    visible = true
    call_deferred("_place_near_anchor")

func hide_tooltip() -> void:
    visible = false

func _place_near_anchor() -> void:
    if not visible:
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    var measured_size: Vector2 = size
    if measured_size.x < 1.0 or measured_size.y < 1.0:
        measured_size = Vector2(280.0, 100.0)
    var desired: Vector2 = _anchor_rect.position + Vector2(_anchor_rect.size.x + 10.0, 0.0)
    if desired.x + measured_size.x > viewport_size.x - 8.0:
        desired.x = _anchor_rect.position.x - measured_size.x - 10.0
    desired.x = clampf(desired.x, 8.0, maxf(8.0, viewport_size.x - measured_size.x - 8.0))
    desired.y = clampf(desired.y, 8.0, maxf(8.0, viewport_size.y - measured_size.y - 8.0))
    position = desired
