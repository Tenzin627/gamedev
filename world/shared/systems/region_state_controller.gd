extends RegionLocalSystem
class_name RegionStateController

signal refresh_requested
signal local_state_changed(key: StringName, value: Variant)

var _local_state: Dictionary = {}

func request_refresh() -> void:
    refresh_requested.emit()

func set_local_value(key: StringName, value: Variant) -> void:
    var string_key: String = String(key)
    if _local_state.has(string_key) and _local_state[string_key] == value:
        return
    _local_state[string_key] = value
    local_state_changed.emit(key, value)

func get_local_value(key: StringName, default_value: Variant = null) -> Variant:
    return _local_state.get(String(key), default_value)

func has_local_value(key: StringName) -> bool:
    return _local_state.has(String(key))

func erase_local_value(key: StringName) -> void:
    var string_key: String = String(key)
    if not _local_state.has(string_key):
        return
    _local_state.erase(string_key)
    local_state_changed.emit(key, null)

func export_runtime_state() -> Dictionary:
    return _local_state.duplicate(true)

func import_runtime_state(state: Dictionary) -> void:
    _local_state = state.duplicate(true)
    for key: Variant in _local_state.keys():
        local_state_changed.emit(StringName(str(key)), _local_state[key])
    refresh_requested.emit()
