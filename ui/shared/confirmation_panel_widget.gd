extends Control
class_name ConfirmationPanelWidget

signal resolved(context_id: StringName, accepted: bool)
signal dialog_state_changed(is_open: bool)

var _context_id: StringName = &""
var _previous_focus: Control
@onready var _title_label: Label = $Center/Panel/Margin/Content/Title
@onready var _message_label: Label = $Center/Panel/Margin/Content/Message
@onready var _confirm_button: Button = $Center/Panel/Margin/Content/Buttons/ConfirmButton
@onready var _cancel_button: Button = $Center/Panel/Margin/Content/Buttons/CancelButton

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    process_mode = Node.PROCESS_MODE_ALWAYS
    z_index = 100
    LungSaUIStyle.apply_modal_panel($Center/Panel, LungSaUIStyle.COLOR_ACCENT)
    LungSaUIStyle.apply_title(_title_label, 26)
    LungSaUIStyle.apply_muted(_message_label, 13)
    LungSaUIStyle.apply_button(_cancel_button, false)
    LungSaUIStyle.apply_button(_confirm_button, true)
    _cancel_button.pressed.connect(_on_cancel_pressed)
    _confirm_button.pressed.connect(_on_confirm_pressed)
    visible = false

func open_confirmation(title: String, message: String, context_id: StringName = &"default", confirm_text: String = "Confirm", cancel_text: String = "Cancel") -> void:
    _context_id = context_id
    _previous_focus = get_viewport().gui_get_focus_owner()
    _title_label.text = title
    _message_label.text = message
    _confirm_button.text = confirm_text
    _cancel_button.text = cancel_text
    visible = true
    dialog_state_changed.emit(true)
    _cancel_button.grab_focus()

func close_without_result() -> void:
    if not visible:
        return
    visible = false
    dialog_state_changed.emit(false)
    _restore_previous_focus()

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"ui_cancel"):
        _resolve(false)
        _mark_input_handled()

func _resolve(accepted: bool) -> void:
    if not visible:
        return
    var resolved_context: StringName = _context_id
    visible = false
    dialog_state_changed.emit(false)
    resolved.emit(resolved_context, accepted)
    _restore_previous_focus()

func _restore_previous_focus() -> void:
    if _previous_focus != null and is_instance_valid(_previous_focus) and _previous_focus.is_inside_tree() and _previous_focus.is_visible_in_tree():
        _previous_focus.grab_focus()
    _previous_focus = null

func _on_cancel_pressed() -> void:
    _resolve(false)

func _on_confirm_pressed() -> void:
    _resolve(true)


func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
