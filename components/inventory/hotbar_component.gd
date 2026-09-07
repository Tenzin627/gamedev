extends ItemSlotContainerComponent
class_name HotbarComponent

signal hotbar_changed
signal selection_changed(slot_index: int, item_id: StringName)

@export_range(1, 12, 1) var slot_count: int = 8
@export var sync_with_game_session: bool = true
@export var input_enabled: bool = true

var selected_index: int = 0
var _sync_guard: bool = false

func _ready() -> void:
    configure_slots(slot_count)
    if not container_changed.is_connected(_on_container_changed):
        container_changed.connect(_on_container_changed)
    if sync_with_game_session:
        if not GameSession.session_started.is_connected(_on_session_replaced):
            GameSession.session_started.connect(_on_session_replaced)
        if GameSession.has_signal("session_imported") and not GameSession.session_imported.is_connected(_on_session_imported):
            GameSession.session_imported.connect(_on_session_imported)
        _load_from_session()
    set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
    if not input_enabled:
        return
    if event is InputEventKey and (event as InputEventKey).echo:
        return
    for i: int in range(slot_count):
        var action: StringName = StringName("hotbar_%d" % (i + 1))
        if InputMap.has_action(action) and event.is_action_pressed(action):
            select_slot(i)
            _mark_input_handled()
            return
    if InputMap.has_action(&"hotbar_next") and event.is_action_pressed(&"hotbar_next"):
        select_slot(posmod(selected_index + 1, slot_count))
        _mark_input_handled()
    elif InputMap.has_action(&"hotbar_prev") and event.is_action_pressed(&"hotbar_prev"):
        select_slot(posmod(selected_index - 1, slot_count))
        _mark_input_handled()

func set_input_enabled(value: bool) -> void:
    input_enabled = value

func select_slot(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= slot_count:
        return false
    selected_index = slot_index
    selection_changed.emit(selected_index, get_selected_item_id())
    hotbar_changed.emit()
    _sync_to_session()
    return true

func get_selected_item_id() -> StringName:
    return get_item_id(selected_index)

func get_selected_stack() -> ItemStack:
    return get_stack_at(selected_index)

func get_quantity_for_slot(slot_index: int) -> int:
    return get_quantity_at(slot_index)

func assign_item(slot_index: int, item_id: StringName, quantity: int = 1) -> bool:
    if item_id == &"":
        return clear_slot(slot_index)
    var definition: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
    if definition == null:
        push_warning("HotbarComponent: refusing unknown/non-item content_id %s" % String(item_id))
        return false
    var safe_quantity: int = clampi(quantity, 1, maxi(definition.max_stack, 1))
    return replace_stack_at(slot_index, ItemStack.new(item_id, safe_quantity))

func clear_all() -> void:
    clear_all_slots()

func bind_first_empty(item_id: StringName, quantity: int = 1) -> int:
    for i: int in range(slot_count):
        var stack: ItemStack = get_stack_at(i)
        if stack == null or stack.is_empty():
            if assign_item(i, item_id, quantity):
                return i
    return -1

func export_state() -> Dictionary:
    return {
        "slot_count": slot_count,
        "selected_index": selected_index,
        "slots": export_slots(),
    }

func import_state(data: Dictionary, write_back: bool = false) -> void:
    _sync_guard = true
    slot_count = maxi(int(data.get("slot_count", slot_count)), 1)

    var serialized_slots: Array = Array(data.get("slots", []))
    if serialized_slots.is_empty() and data.has("bindings"):
        serialized_slots = _convert_legacy_bindings(Array(data.get("bindings", [])))

    import_slots(serialized_slots, slot_count)
    selected_index = clampi(int(data.get("selected_index", 0)), 0, slot_count - 1)
    _sync_guard = false
    hotbar_changed.emit()
    selection_changed.emit(selected_index, get_selected_item_id())
    if write_back:
        _sync_to_session()

func _convert_legacy_bindings(bindings: Array) -> Array:
    var result: Array = []
    for i: int in range(slot_count):
        if i >= bindings.size():
            result.append({})
            continue
        var item_id: StringName = StringName(str(bindings[i]))
        var definition: ItemDefinition = ContentDB.get_definition(item_id) as ItemDefinition
        if item_id == &"" or definition == null:
            result.append({})
        else:
            result.append(ItemStack.new(item_id, 1).to_dict())
    return result

func _on_container_changed() -> void:
    hotbar_changed.emit()
    _sync_to_session()

func _sync_to_session() -> void:
    if not sync_with_game_session or _sync_guard:
        return
    _sync_guard = true
    GameSession.set_value(&"hotbar", export_state())
    _sync_guard = false

func _load_from_session() -> void:
    if not sync_with_game_session:
        return
    var stored: Variant = GameSession.get_value(&"hotbar", null)
    if stored is Dictionary:
        import_state(Dictionary(stored), false)
    else:
        import_state({"slot_count": slot_count, "selected_index": 0, "slots": []}, false)
        _sync_to_session()

func _on_session_replaced(_profile_id: String) -> void:
    _load_from_session()

func _on_session_imported() -> void:
    _load_from_session()


func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
