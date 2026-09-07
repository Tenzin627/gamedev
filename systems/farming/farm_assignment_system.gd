extends RegionLocalSystem
class_name FarmAssignmentSystem

signal assignments_changed

@export var max_assigned_creatures: int = 6
var _assigned_ids: Array[String] = []

func get_assigned_ids() -> Array[String]:
    return _assigned_ids.duplicate()

func is_assigned(instance_id: String) -> bool:
    return _assigned_ids.has(instance_id)

func can_assign(instance_id: String) -> bool:
    if instance_id.is_empty() or is_assigned(instance_id) or _assigned_ids.size() >= max_assigned_creatures:
        return false
    return CreatureCollectionModel.new().get_creature(instance_id) != null

func assign_creature(instance_id: String) -> bool:
    if not can_assign(instance_id):
        return false
    _assigned_ids.append(instance_id)
    assignments_changed.emit()
    return true

func unassign_creature(instance_id: String) -> bool:
    var index: int = _assigned_ids.find(instance_id)
    if index < 0:
        return false
    _assigned_ids.remove_at(index)
    assignments_changed.emit()
    return true

func toggle_assignment(instance_id: String) -> bool:
    if is_assigned(instance_id):
        return unassign_creature(instance_id)
    return assign_creature(instance_id)

func export_runtime_state() -> Dictionary:
    return {"assigned_ids": _assigned_ids.duplicate()}

func import_runtime_state(state: Dictionary) -> void:
    _assigned_ids.clear()
    var value: Variant = state.get("assigned_ids", [])
    if value is Array:
        for id_value: Variant in Array(value):
            var instance_id: String = str(id_value)
            if not instance_id.is_empty() and CreatureCollectionModel.new().get_creature(instance_id) != null and not _assigned_ids.has(instance_id):
                _assigned_ids.append(instance_id)
                if _assigned_ids.size() >= max_assigned_creatures:
                    break
    assignments_changed.emit()
