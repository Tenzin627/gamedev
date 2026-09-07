extends Button
class_name ItemSlotWidget

signal item_activated(slot_index: int, item_id: StringName)
signal tooltip_requested(title: String, body: String, anchor_rect: Rect2)
signal tooltip_hidden
signal transfer_completed(source_container: ItemSlotContainerComponent, source_index: int, target_container: ItemSlotContainerComponent, target_index: int)
signal transfer_failed(message: String)

@export var slot_index: int = -1
@export var show_slot_number: bool = true
@export var compact: bool = false

@onready var _slot_label: Label = $Margin/VBox/SlotNumber
@onready var _icon_label: Label = $Margin/VBox/ItemLabel
@onready var _quantity_label: Label = $Margin/VBox/Quantity

var _art_icon: TextureRect

var _container: ItemSlotContainerComponent
var _item_id: StringName = &""
var _quantity: int = 0
var _slot_number: int = 0
var _selected: bool = false
var _pointer_inside: bool = false
var _quick_transfer_target: ItemSlotContainerComponent = null

func _ready() -> void:
    _art_icon = TextureRect.new()
    _art_icon.custom_minimum_size = Vector2(42,42) if compact else Vector2(48,48)
    _art_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _art_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _art_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _art_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    $Margin/VBox.add_child(_art_icon)
    $Margin/VBox.move_child(_art_icon, 1)
    text = ""
    focus_mode = Control.FOCUS_ALL
    LungSaUIStyle.apply_muted(_slot_label, 10)
    custom_minimum_size = Vector2(72.0, 64.0) if compact else Vector2(92.0, 82.0)
    pressed.connect(_on_pressed)
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)
    _refresh_from_container()
    _refresh_visuals()

func bind_slot(container: ItemSlotContainerComponent, index: int, display_number: int = 0) -> void:
    if _container != null and _container.slot_changed.is_connected(_on_container_slot_changed):
        _container.slot_changed.disconnect(_on_container_slot_changed)
    _container = container
    slot_index = index
    _slot_number = maxi(display_number, 0)
    if _container != null and not _container.slot_changed.is_connected(_on_container_slot_changed):
        _container.slot_changed.connect(_on_container_slot_changed)
    _refresh_from_container()
    _refresh_visuals()

func get_bound_container() -> ItemSlotContainerComponent:
    return _container

func set_quick_transfer_target(target: ItemSlotContainerComponent) -> void:
    _quick_transfer_target = target

func set_compact(value: bool) -> void:
    compact = value
    custom_minimum_size = Vector2(72.0, 64.0) if compact else Vector2(92.0, 82.0)
    if _icon_label != null:
        _icon_label.add_theme_font_size_override(&"font_size", 20 if compact else 24)

func set_selected(value: bool) -> void:
    _selected = value
    _refresh_visuals()

func refresh_from_container() -> void:
    _refresh_from_container()
    _refresh_visuals()

func set_item_state(item_id: StringName, quantity: int, slot_number: int = 0, selected: bool = false) -> void:
    _item_id = item_id
    _quantity = maxi(quantity, 0)
    _slot_number = maxi(slot_number, 0)
    _selected = selected
    _refresh_visuals()

func get_item_id() -> StringName:
    return _item_id

func get_quantity() -> int:
    return _quantity

func _get_drag_data(_at_position: Vector2) -> Variant:
    if _container == null or slot_index < 0 or _item_id == &"" or _quantity <= 0:
        return null

    tooltip_hidden.emit()
    var preview_scene: Resource = load("res://ui/shared/item_slot.tscn")
    if preview_scene is PackedScene:
        var preview: ItemSlotWidget = (preview_scene as PackedScene).instantiate() as ItemSlotWidget
        if preview != null:
            preview.show_slot_number = false
            preview.compact = true
            preview.set_item_state(_item_id, _quantity, 0, false)
            set_drag_preview(preview)

    return {
        "kind": &"lung_sa_item_slot",
        "source_container": _container,
        "source_index": slot_index,
    }

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
    if _container == null or slot_index < 0 or not data is Dictionary:
        return false
    var payload: Dictionary = Dictionary(data)
    if StringName(str(payload.get("kind", ""))) != &"lung_sa_item_slot":
        return false
    var source_value: Variant = payload.get("source_container", null)
    var source_container: ItemSlotContainerComponent = source_value as ItemSlotContainerComponent
    var source_index: int = int(payload.get("source_index", -1))
    if source_container == null:
        return false
    return source_container.can_transfer_slot_to(source_index, _container, slot_index)

func _drop_data(_at_position: Vector2, data: Variant) -> void:
    if not data is Dictionary:
        return
    var payload: Dictionary = Dictionary(data)
    var source_value: Variant = payload.get("source_container", null)
    var source_container: ItemSlotContainerComponent = source_value as ItemSlotContainerComponent
    var source_index: int = int(payload.get("source_index", -1))
    if source_container == null:
        return
    if source_container.transfer_slot_to(source_index, _container, slot_index):
        transfer_completed.emit(source_container, source_index, _container, slot_index)

func _refresh_from_container() -> void:
    if _container == null or slot_index < 0:
        return
    var stack: ItemStack = _container.get_stack_at(slot_index)
    if stack == null or stack.is_empty():
        _item_id = &""
        _quantity = 0
    else:
        _item_id = stack.item_id
        _quantity = stack.quantity

func _refresh_visuals() -> void:
    if _slot_label == null or _icon_label == null or _quantity_label == null:
        return
    _slot_label.text = str(_slot_number) if show_slot_number and _slot_number > 0 else ""
    if _item_id == &"":
        _icon_label.text = "·"
        _quantity_label.text = ""
    else:
        var definition: ItemDefinition = ContentDB.get_definition(_item_id) as ItemDefinition
        var display_name: String = definition.display_name if definition != null else String(_item_id)
        _icon_label.text = _make_abbreviation(display_name)
        _quantity_label.text = "x%d" % _quantity if _quantity > 0 else "0"

    if _art_icon != null:
        var definition_for_icon: ItemDefinition = ContentDB.get_definition(_item_id) as ItemDefinition
        var direct_icon: Texture2D = definition_for_icon.icon if definition_for_icon != null else null
        _art_icon.visible = direct_icon != null
        _icon_label.visible = not _art_icon.visible
        _art_icon.texture = direct_icon
    var border: Color = LungSaUIStyle.COLOR_FOCUS if _selected else LungSaUIStyle.COLOR_BORDER_SOFT
    var fill: Color = Color("#405A4AF5") if _selected else Color("#1B3028F0")
    _icon_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_ACCENT if _selected else LungSaUIStyle.COLOR_INK)
    _quantity_label.add_theme_color_override(&"font_color", LungSaUIStyle.COLOR_INK if _quantity > 0 else LungSaUIStyle.COLOR_MUTED)
    add_theme_stylebox_override(&"normal", LungSaUIStyle.panel_style(fill, border, 2 if _selected else 1, LungSaUIStyle.BUTTON_RADIUS, 4.0))
    add_theme_stylebox_override(&"hover", LungSaUIStyle.panel_style(Color("#304B3EFA"), LungSaUIStyle.COLOR_ACCENT_SOFT, 2, LungSaUIStyle.BUTTON_RADIUS, 4.0))
    add_theme_stylebox_override(&"pressed", LungSaUIStyle.panel_style(Color("#456251FF"), LungSaUIStyle.COLOR_ACCENT, 2, LungSaUIStyle.BUTTON_RADIUS, 4.0))
    add_theme_stylebox_override(&"focus", LungSaUIStyle.panel_style(Color("#2C4439FA"), LungSaUIStyle.COLOR_FOCUS, 2, LungSaUIStyle.BUTTON_RADIUS, 4.0))

func _make_abbreviation(display_name: String) -> String:
    var trimmed: String = display_name.strip_edges()
    if trimmed.is_empty():
        return "?"
    var words: PackedStringArray = trimmed.split(" ", false)
    if words.size() >= 2:
        return (words[0].left(1) + words[1].left(1)).to_upper()
    return trimmed.left(2).to_upper()

func _request_tooltip() -> void:
    if _item_id == &"":
        return
    var definition: ItemDefinition = ContentDB.get_definition(_item_id) as ItemDefinition
    var title: String = definition.display_name if definition != null else String(_item_id)
    var body_lines: Array[String] = []
    if definition != null:
        body_lines.append(definition.category)
        if not definition.description.strip_edges().is_empty():
            body_lines.append(definition.description.strip_edges())
        if definition is ToolDefinition:
            var tool: ToolDefinition = definition as ToolDefinition
            body_lines.append("Tool: %s  Power: %d  Reach: %d px" % [String(tool.tool_tag), tool.power, int(tool.reach)])
    body_lines.append("Quantity: %d" % _quantity)
    body_lines.append("Drag to move/swap. Shift-click or double-click moves the stack; right-click moves one.")
    tooltip_requested.emit(title, "\n".join(body_lines), get_global_rect())

func _try_hide_tooltip() -> void:
    if _pointer_inside or has_focus():
        return
    tooltip_hidden.emit()

func _on_container_slot_changed(changed_index: int, _stack: ItemStack) -> void:
    if changed_index != slot_index:
        return
    _refresh_from_container()
    _refresh_visuals()

func _on_pressed() -> void:
    if Input.is_key_pressed(KEY_SHIFT) and _quick_transfer(false):
        return
    item_activated.emit(slot_index, _item_id)

func _gui_input(event: InputEvent) -> void:
    if not event is InputEventMouseButton:
        return
    var mouse_event: InputEventMouseButton = event as InputEventMouseButton
    if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.double_click:
        if _quick_transfer(false):
            accept_event()
    elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
        if _quick_transfer(true):
            accept_event()

func _quick_transfer(single_item: bool) -> bool:
    if _container == null or _quick_transfer_target == null or slot_index < 0:
        return false
    var moved: bool = _container.transfer_amount_to_first_available(slot_index, _quick_transfer_target, 1) if single_item else _container.transfer_slot_to_first_available(slot_index, _quick_transfer_target)
    if moved:
        transfer_completed.emit(_container, slot_index, _quick_transfer_target, -1)
    else:
        transfer_failed.emit("No compatible space is available.")
    return moved

func _on_mouse_entered() -> void:
    _pointer_inside = true
    _request_tooltip()

func _on_mouse_exited() -> void:
    _pointer_inside = false
    _try_hide_tooltip()

func _on_focus_entered() -> void:
    _request_tooltip()

func _on_focus_exited() -> void:
    _try_hide_tooltip()
