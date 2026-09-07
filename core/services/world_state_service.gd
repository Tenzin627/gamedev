extends Node

signal world_state_changed(key: StringName, value: Variant)

var _state: Dictionary = {}

func set_value(key: StringName, value: Variant) -> void:
    var string_key: String = String(key)
    if _state.has(string_key) and _state[string_key] == value:
        return
    _state[string_key] = value
    world_state_changed.emit(key, value)

func set_flag(key: StringName, enabled: bool) -> void:
    set_value(key, enabled)

func get_value(key: StringName, default_value: Variant = null) -> Variant:
    return _state.get(String(key), default_value)

func get_flag(key: StringName, default_value: bool = false) -> bool:
    var value: Variant = get_value(key, default_value)
    if value is bool:
        return bool(value)
    return default_value

func has_value(key: StringName) -> bool:
    return _state.has(String(key))

func erase_value(key: StringName) -> void:
    var string_key: String = String(key)
    if not _state.has(string_key):
        return
    _state.erase(string_key)
    world_state_changed.emit(key, null)

func clear_all() -> void:
    var previous_keys: Array = _state.keys()
    _state.clear()
    for key_variant: Variant in previous_keys:
        world_state_changed.emit(StringName(str(key_variant)), null)

func export_state() -> Dictionary:
    return _state.duplicate(true)

func import_state(data: Dictionary) -> void:
    var previous_keys: Array = _state.keys()
    _state = data.duplicate(true)

    for old_key_variant: Variant in previous_keys:
        var old_key: String = str(old_key_variant)
        if not _state.has(old_key):
            world_state_changed.emit(StringName(old_key), null)

    for key_variant: Variant in _state.keys():
        var key: String = str(key_variant)
        world_state_changed.emit(StringName(key), _state[key])

func count() -> int:
    return _state.size()
