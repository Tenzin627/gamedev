extends Node
class_name WorldStateBindingComponent

signal active_changed(active: bool)
signal binding_refreshed(state_key: StringName, active: bool)

@export var state_key: StringName = &""
@export var default_active: bool = false
@export var invert_value: bool = false
@export var warn_on_non_boolean: bool = true

var _active: bool = false
var _initialized: bool = false

func _ready() -> void:
    if state_key == &"":
        push_warning("WorldStateBindingComponent has no state_key")
        return
    if not WorldStateService.world_state_changed.is_connected(_on_world_state_changed):
        WorldStateService.world_state_changed.connect(_on_world_state_changed)
    refresh_from_service()

func _exit_tree() -> void:
    if WorldStateService.world_state_changed.is_connected(_on_world_state_changed):
        WorldStateService.world_state_changed.disconnect(_on_world_state_changed)

func refresh_from_service() -> void:
    if state_key == &"":
        return
    var raw_value: Variant = WorldStateService.get_value(state_key, default_active)
    var resolved_active: bool = default_active
    if raw_value is bool:
        resolved_active = bool(raw_value)
    elif warn_on_non_boolean:
        push_warning("WorldStateBindingComponent expected bool for %s; using default." % String(state_key))
    if invert_value:
        resolved_active = not resolved_active
    _apply_resolved_active(resolved_active)
    binding_refreshed.emit(state_key, _active)

func set_active(active: bool) -> void:
    if state_key == &"":
        return
    var stored_value: bool = active
    if invert_value:
        stored_value = not stored_value
    WorldStateService.set_flag(state_key, stored_value)

func toggle_active() -> void:
    set_active(not _active)

func is_active() -> bool:
    return _active

func _apply_resolved_active(next_active: bool) -> void:
    if _initialized and _active == next_active:
        return
    _active = next_active
    _initialized = true
    active_changed.emit(_active)

func _on_world_state_changed(changed_key: StringName, _value: Variant) -> void:
    if changed_key != state_key:
        return
    refresh_from_service()
