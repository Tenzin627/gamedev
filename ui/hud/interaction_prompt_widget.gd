extends PanelContainer
class_name InteractionPromptWidget

@export var input_hint: String = "E"
@export_range(0.2, 2.0, 0.1) var failure_display_seconds: float = 0.8

var _interactor: InteractorComponent
var _failure_token: int = 0
@onready var _key_label: Label = $Margin/Row/KeyLabel
@onready var _action_label: Label = $Margin/Row/ActionLabel

func _ready() -> void:
    LungSaUIStyle.apply_toast(self)
    _key_label.text = "[%s]" % input_hint
    _key_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_ACCENT)
    _action_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_INK)
    visible = false

func bind_interactor(interactor: InteractorComponent) -> void:
    if _interactor != null:
        if _interactor.prompt_changed.is_connected(_on_prompt_changed):
            _interactor.prompt_changed.disconnect(_on_prompt_changed)
        if _interactor.interaction_failed.is_connected(_on_interaction_failed):
            _interactor.interaction_failed.disconnect(_on_interaction_failed)
    _interactor = interactor
    _failure_token += 1
    if _interactor != null:
        if not _interactor.prompt_changed.is_connected(_on_prompt_changed):
            _interactor.prompt_changed.connect(_on_prompt_changed)
        if not _interactor.interaction_failed.is_connected(_on_interaction_failed):
            _interactor.interaction_failed.connect(_on_interaction_failed)
        var initial_action: StringName = &""
        if _interactor.focused_interactable != null:
            initial_action = _interactor.focused_interactable.action_name
        _on_prompt_changed(_interactor.get_prompt_text(), initial_action)
    else:
        _on_prompt_changed("", &"")

func _on_prompt_changed(text: String, _action: StringName) -> void:
    _failure_token += 1
    _show_text(text, true)

func _on_interaction_failed(text: String) -> void:
    _failure_token += 1
    var token := _failure_token
    _show_text(text, false)
    await get_tree().create_timer(failure_display_seconds).timeout
    if token != _failure_token:
        return
    var prompt := _interactor.get_prompt_text() if _interactor != null else ""
    _show_text(prompt, true)

func _show_text(text: String, show_key: bool) -> void:
    visible = not text.is_empty()
    if _key_label != null:
        _key_label.visible = show_key and not text.is_empty()
        _key_label.text = "[%s]" % input_hint
    if _action_label != null:
        _action_label.text = text
