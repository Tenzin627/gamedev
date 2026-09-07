extends ItemSlotContainerComponent
class_name InventoryComponent

signal inventory_changed

@export_range(1, 200, 1) var slot_capacity: int = 24
@export var sync_with_game_session: bool = true

var _sync_guard: bool = false

func _ready() -> void:
    configure_slots(slot_capacity)
    if not container_changed.is_connected(_on_container_changed):
        container_changed.connect(_on_container_changed)
    if sync_with_game_session:
        if not GameSession.session_started.is_connected(_on_session_replaced):
            GameSession.session_started.connect(_on_session_replaced)
        if GameSession.has_signal("session_imported") and not GameSession.session_imported.is_connected(_on_session_imported):
            GameSession.session_imported.connect(_on_session_imported)
        _load_from_session()

func move_slot(from_index: int, to_index: int) -> bool:
    return transfer_slot_to(from_index, self, to_index)

func clear() -> void:
    clear_all_slots()

func export_state() -> Dictionary:
    return {
        "slot_capacity": slot_capacity,
        "slots": export_slots(),
    }

func import_state(data: Dictionary, write_back: bool = false) -> void:
    _sync_guard = true
    slot_capacity = maxi(int(data.get("slot_capacity", slot_capacity)), 1)
    var serialized_slots: Array = Array(data.get("slots", []))
    import_slots(serialized_slots, slot_capacity)
    _sync_guard = false
    if write_back:
        _sync_to_session()

func _on_container_changed() -> void:
    inventory_changed.emit()
    _sync_to_session()

func _sync_to_session() -> void:
    if not sync_with_game_session or _sync_guard:
        return
    _sync_guard = true
    GameSession.set_value(&"inventory_slots", export_state())
    _sync_guard = false

func _load_from_session() -> void:
    if not sync_with_game_session:
        return
    var stored: Variant = GameSession.get_value(&"inventory_slots", null)
    if stored is Dictionary:
        import_state(Dictionary(stored), false)
        return

    var legacy: Variant = GameSession.get_value(&"inventory", {})
    if legacy is Dictionary and not Dictionary(legacy).is_empty():
        _sync_guard = true
        configure_slots(slot_capacity)
        for i: int in range(get_slot_count()):
            _slots[i] = null
        _sync_guard = false
        for key: Variant in Dictionary(legacy).keys():
            add_item(StringName(str(key)), int(Dictionary(legacy)[key]))
    else:
        import_state({"slot_capacity": slot_capacity, "slots": []}, false)
        _sync_to_session()

func _on_session_replaced(_profile_id: String) -> void:
    _load_from_session()

func _on_session_imported() -> void:
    _load_from_session()
