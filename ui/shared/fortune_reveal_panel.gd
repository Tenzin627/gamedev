extends Control
class_name FortuneRevealPanel

signal panel_state_changed(is_open: bool)
signal closed

@onready var panel: PanelContainer = $Center/Panel
@onready var kicker_label: Label = $Center/Panel/Margin/VBox/Kicker
@onready var seal_label: Label = $Center/Panel/Margin/VBox/Seal
@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var amount_label: Label = $Center/Panel/Margin/VBox/Amount
@onready var body_label: Label = $Center/Panel/Margin/VBox/Body
@onready var continue_button: Button = $Center/Panel/Margin/VBox/Continue

var _previous_focus: Control = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    z_index = 120
    LungSaUIStyle.apply_modal_panel(panel, LungSaUIStyle.COLOR_ACCENT)
    LungSaUIStyle.apply_kicker(kicker_label)
    LungSaUIStyle.apply_title(title_label, 28)
    LungSaUIStyle.apply_title(amount_label, 24)
    LungSaUIStyle.apply_muted(body_label, 13)
    LungSaUIStyle.apply_button(continue_button, true)
    continue_button.pressed.connect(close_panel)
    visible = false

func open_reveal(kicker: String, title: String, amount_text: String, body: String, outcome: String = "reward", seal_text: String = "REVEALED") -> void:
    _previous_focus = get_viewport().gui_get_focus_owner()
    kicker_label.text = kicker.to_upper()
    title_label.text = title
    amount_label.text = amount_text
    body_label.text = body
    seal_label.text = seal_text.to_upper()
    _apply_outcome(outcome)
    visible = true
    modulate.a = 0.0
    panel.scale = Vector2(0.96, 0.96)
    panel.pivot_offset = panel.size * 0.5
    panel_state_changed.emit(true)
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(self, "modulate:a", 1.0, 0.12)
    tween.tween_property(panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    continue_button.grab_focus()

func close_panel() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)
    closed.emit()
    _restore_previous_focus()

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel"):
        close_panel()
        var viewport: Viewport = get_viewport()
        if viewport != null:
            viewport.set_input_as_handled()

func _apply_outcome(outcome: String) -> void:
    var normalized: String = outcome.to_lower()
    var accent: Color = LungSaUIStyle.COLOR_ACCENT
    if normalized == "win" or normalized == "success":
        accent = LungSaUIStyle.COLOR_SUCCESS
    elif normalized == "loss" or normalized == "danger":
        accent = LungSaUIStyle.COLOR_DANGER
    elif normalized == "debt":
        accent = LungSaUIStyle.COLOR_LEDGER
    seal_label.add_theme_color_override(&"font_color", accent)
    seal_label.add_theme_color_override(&"font_outline_color", Color("#09130FFF"))
    seal_label.add_theme_constant_override(&"outline_size", 5)
    amount_label.add_theme_color_override(&"font_color", accent)
    LungSaUIStyle.apply_modal_panel(panel, accent)

func _restore_previous_focus() -> void:
    if _previous_focus != null and is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
        _previous_focus.grab_focus()
    _previous_focus = null
