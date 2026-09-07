extends RegionLocalSystem
class_name RegionEcologySystem

signal ecology_changed(health: float, state_tag: StringName)

@export var ecology_profile_id: StringName = &""
var _health: float = 0.0
var _state_tag: StringName = &"strained"

func _on_region_bound() -> void:
    if not WorldStateService.world_state_changed.is_connected(_on_world_state_changed):
        WorldStateService.world_state_changed.connect(_on_world_state_changed)
    refresh()

func refresh() -> void:
    var profile: EcologyProfileDefinition = ContentDB.get_definition(ecology_profile_id) as EcologyProfileDefinition
    if profile == null:
        return
    var restored_count: int = 0
    for flag: StringName in profile.restoration_flags:
        if WorldStateService.get_flag(flag, false):
            restored_count += 1
    _health = clampf(profile.base_health + float(restored_count) * profile.restoration_value_per_flag, 0.0, 1.0)
    if _health >= 0.8:
        _state_tag = &"thriving"
    elif _health >= 0.55:
        _state_tag = &"recovering"
    else:
        _state_tag = &"strained"
    WorldStateService.set_value(StringName("ecology.%s.health" % String(get_region_id())), _health)
    WorldStateService.set_value(StringName("ecology.%s.state" % String(get_region_id())), String(_state_tag))
    ecology_changed.emit(_health, _state_tag)

func get_health() -> float:
    return _health

func get_state_tag() -> StringName:
    return _state_tag

func _on_world_state_changed(key: StringName, _value: Variant) -> void:
    if String(key).begins_with("world."):
        refresh()
