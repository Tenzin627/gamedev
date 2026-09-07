extends Node
class_name RegionLocalSystem

var region_root: RegionRoot = null

func bind_region(value: RegionRoot) -> void:
    region_root = value
    _on_region_bound()

func _on_region_bound() -> void:
    pass

func get_region_id() -> StringName:
    if region_root == null:
        return &""
    return region_root.get_region_id()

func get_zone_id() -> StringName:
    if region_root == null:
        return &""
    return region_root.get_zone_id()

func export_runtime_state() -> Dictionary:
    return {}

func import_runtime_state(_state: Dictionary) -> void:
    pass
