extends CanvasLayer
class_name SceneTransitionOverlay

@onready var root: Control = $Root
@onready var fade_rect: ColorRect = $Root/Fade
@onready var title_label: Label = $Root/LocationTitle

var _fade_tween: Tween = null
var _title_tween: Tween = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    hide_overlay()

func begin_blocking() -> void:
    _cancel_title_tween()
    root.visible = true
    root.mouse_filter = Control.MOUSE_FILTER_STOP

func stop_blocking() -> void:
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_to(alpha: float, duration: float) -> void:
    root.visible = true
    _cancel_fade_tween()
    var target: Color = fade_rect.color
    target.a = clampf(alpha, 0.0, 1.0)
    _fade_tween = create_tween()
    _fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _fade_tween.tween_property(fade_rect, "color", target, maxf(duration, 0.01))
    await _fade_tween.finished
    _fade_tween = null

func show_location_title(title: String) -> void:
    if title.is_empty():
        return
    _cancel_title_tween()
    root.visible = true
    title_label.text = title
    title_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

func animate_title_out(hold_seconds: float, fade_seconds: float) -> void:
    _cancel_title_tween()
    _title_tween = create_tween()
    _title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _title_tween.tween_interval(maxf(hold_seconds, 0.0))
    _title_tween.tween_property(title_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), maxf(fade_seconds, 0.01))
    _title_tween.tween_callback(hide_overlay)

func hide_overlay() -> void:
    root.visible = false
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
    var color: Color = fade_rect.color
    color.a = 0.0
    fade_rect.color = color

func _cancel_fade_tween() -> void:
    if _fade_tween != null and _fade_tween.is_valid():
        _fade_tween.kill()
    _fade_tween = null

func _cancel_title_tween() -> void:
    if _title_tween != null and _title_tween.is_valid():
        _title_tween.kill()
    _title_tween = null
