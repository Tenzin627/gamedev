extends Control
class_name DialoguePanel

signal advance_requested
signal choice_requested(choice_index: int)
signal close_requested
signal panel_state_changed(is_open: bool)

@onready var portrait_frame: PanelContainer = $BottomMargin/DialogueRow/PortraitColumn/PortraitFrame
@onready var portrait_texture: TextureRect = $BottomMargin/DialogueRow/PortraitColumn/PortraitFrame/PortraitMargin/Portrait
@onready var role_label: Label = $BottomMargin/DialogueRow/PortraitColumn/Role
@onready var panel: PanelContainer = $BottomMargin/DialogueRow/SpeechPanel
@onready var kicker_label: Label = $BottomMargin/DialogueRow/SpeechPanel/Margin/Column/ConversationKicker
@onready var speaker_label: Label = $BottomMargin/DialogueRow/SpeechPanel/Margin/Column/Speaker
@onready var body_label: RichTextLabel = $BottomMargin/DialogueRow/SpeechPanel/Margin/Column/Body
@onready var choices_box: VBoxContainer = $BottomMargin/DialogueRow/SpeechPanel/Margin/Column/Choices
@onready var hint_label: Label = $BottomMargin/DialogueRow/SpeechPanel/Margin/Column/Footer/Hint
@onready var continue_button: Button = $BottomMargin/DialogueRow/SpeechPanel/Margin/Column/Footer/Continue

var _portrait: Texture2D = null
var _role: String = "Resident"

func _ready() -> void:
    add_to_group(&"dialogue_panel")
    visible = false
    LungSaUIStyle.apply_modal_panel(panel, LungSaUIStyle.COLOR_ACCENT)
    LungSaUIStyle.apply_character_frame(portrait_frame, LungSaUIStyle.COLOR_ACCENT)
    LungSaUIStyle.apply_kicker(kicker_label)
    LungSaUIStyle.apply_title(speaker_label, 28)
    LungSaUIStyle.apply_kicker(role_label)
    LungSaUIStyle.apply_body(body_label, 17)
    LungSaUIStyle.apply_muted(hint_label, 11)
    LungSaUIStyle.apply_button(continue_button, true)
    continue_button.pressed.connect(func() -> void: advance_requested.emit())

func open_dialogue(speaker: String, text: String, choices: Array[DialogueChoice], portrait: Texture2D = null, role: String = "Resident") -> void:
    visible = true
    show_node(speaker, text, choices, portrait, role)
    panel_state_changed.emit(true)

func show_node(speaker: String, text: String, choices: Array[DialogueChoice], portrait: Texture2D = null, role: String = "Resident") -> void:
    _portrait = portrait
    _role = role if not role.is_empty() else "Resident"
    speaker_label.text = speaker
    body_label.text = text
    _refresh_character_context()
    for child: Node in choices_box.get_children():
        child.queue_free()
    continue_button.visible = choices.is_empty()
    hint_label.text = "[E] Continue   •   [ESC] Close" if choices.is_empty() else "Choose a response   •   [ESC] Close"
    for index: int in range(choices.size()):
        var choice: DialogueChoice = choices[index]
        var button: Button = Button.new()
        button.text = "%d.  %s" % [index + 1, choice.text]
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        LungSaUIStyle.apply_choice_button(button, index)
        button.pressed.connect(_emit_choice.bind(index))
        choices_box.add_child(button)
    call_deferred("_focus_first")

func close_dialogue() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)

func _refresh_character_context() -> void:
    portrait_texture.texture = _portrait
    portrait_texture.visible = _portrait != null
    role_label.text = _role.to_upper()
    if _portrait == null and _role == "Resident":
        role_label.text = "LUNG SA RESIDENT"

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"ui_cancel"):
        close_requested.emit()
        _mark_input_handled()
    elif event.is_action_pressed(&"interact"):
        if continue_button.visible:
            advance_requested.emit()
        elif choices_box.get_child_count() > 0:
            var focus_owner: Control = get_viewport().gui_get_focus_owner()
            if focus_owner is Button and choices_box.is_ancestor_of(focus_owner):
                (focus_owner as Button).pressed.emit()
            else:
                _emit_choice(0)
        _mark_input_handled()

func _emit_choice(index: int) -> void:
    choice_requested.emit(index)

func _focus_first() -> void:
    if not visible:
        return
    if choices_box.get_child_count() > 0:
        var first: Control = choices_box.get_child(0) as Control
        if first != null:
            first.grab_focus()
    elif continue_button.visible:
        continue_button.grab_focus()

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
