extends Control
class_name WaymarkTravelPanelWidget

signal close_requested
signal destination_selected(waymark_id: StringName)

@onready var panel: PanelContainer = $Center/Panel
@onready var title_label: Label = $Center/Panel/Margin/VBox/Title
@onready var origin_label: Label = $Center/Panel/Margin/VBox/Origin
@onready var destination_list: VBoxContainer = $Center/Panel/Margin/VBox/Scroll/DestinationList
@onready var close_button: Button = $Center/Panel/Margin/VBox/CloseButton

var origin_waymark_id: StringName = &""

func _ready() -> void:
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP
    LungSaUIStyle.apply_modal_panel(panel, LungSaUIStyle.COLOR_ACCENT)
    LungSaUIStyle.apply_title(title_label, 28)
    LungSaUIStyle.apply_muted(origin_label, 12)
    LungSaUIStyle.apply_button(close_button, false)
    if not close_button.pressed.is_connected(close_panel):
        close_button.pressed.connect(close_panel)

func _unhandled_input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed(&"ui_cancel"):
        close_panel()
        _mark_input_handled()

func open_panel(value_origin_waymark_id: StringName) -> void:
    origin_waymark_id = value_origin_waymark_id
    _rebuild_destination_list()
    visible = true
    var first_focus: Control = _find_first_enabled_destination_button()
    if first_focus != null:
        first_focus.grab_focus()
    else:
        close_button.grab_focus()

func close_panel() -> void:
    if not visible:
        return
    visible = false
    origin_waymark_id = &""
    close_requested.emit()

func _rebuild_destination_list() -> void:
    for child: Node in destination_list.get_children():
        destination_list.remove_child(child)
        child.queue_free()

    var origin_definition: WaymarkDefinition = ContentDB.get_definition(origin_waymark_id) as WaymarkDefinition
    if origin_definition != null:
        origin_label.text = "From: %s" % origin_definition.display_name
    else:
        origin_label.text = "From: Activated Waymark"
    title_label.text = "WAYMARK TRAVEL"

    var waymark_ids: Array[String] = []
    for content_id_variant: Variant in ContentDB.get_all_ids():
        var content_id: StringName = StringName(str(content_id_variant))
        var definition: WaymarkDefinition = ContentDB.get_definition(content_id) as WaymarkDefinition
        if definition == null:
            continue
        if not WorldStateService.get_flag(definition.activation_state_key, false):
            continue
        waymark_ids.append(String(content_id))
    waymark_ids.sort()

    if waymark_ids.is_empty():
        _add_empty_label("No activated Waymarks are available.")
        return

    var destination_count: int = 0
    for waymark_id_text: String in waymark_ids:
        var waymark_id: StringName = StringName(waymark_id_text)
        var definition: WaymarkDefinition = ContentDB.get_definition(waymark_id) as WaymarkDefinition
        if definition == null:
            continue
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(0.0, 44.0)
        button.text = definition.display_name
        button.focus_mode = Control.FOCUS_ALL
        if waymark_id == origin_waymark_id:
            button.text += "  •  CURRENT"
            button.disabled = true
        else:
            destination_count += 1
            button.pressed.connect(_on_destination_button_pressed.bind(waymark_id))
        LungSaUIStyle.apply_button(button, waymark_id != origin_waymark_id)
        destination_list.add_child(button)

    if destination_count == 0:
        _add_empty_label("Activate another Waymark to unlock fast travel.")

func _add_empty_label(message: String) -> void:
    var label: Label = Label.new()
    label.text = message
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_MUTED)
    label.custom_minimum_size = Vector2(0.0, 52.0)
    destination_list.add_child(label)

func _find_first_enabled_destination_button() -> Control:
    for child: Node in destination_list.get_children():
        if child is Button:
            var button: Button = child as Button
            if not button.disabled:
                return button
    return null

func _on_destination_button_pressed(waymark_id: StringName) -> void:
    destination_selected.emit(waymark_id)

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
