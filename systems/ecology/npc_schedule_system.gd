extends RegionLocalSystem
class_name NPCScheduleSystem

@export var schedule_ids: Array[StringName] = []

func _on_region_bound() -> void:
    if not WorldTimeService.time_changed.is_connected(_on_time_changed):
        WorldTimeService.time_changed.connect(_on_time_changed)
    _apply_hour(WorldTimeService.get_hour())

func _on_time_changed(_day: int, hour: int, _minute: int, _total: int) -> void:
    _apply_hour(hour)

func _apply_hour(hour: int) -> void:
    if region_root == null:
        return
    for schedule_id: StringName in schedule_ids:
        var schedule: NPCScheduleDefinition = ContentDB.get_definition(schedule_id) as NPCScheduleDefinition
        if schedule == null:
            continue
        var actor: Node2D = _find_npc(schedule.npc_id)
        if actor == null:
            continue
        for entry_resource: Resource in schedule.entries:
            var entry: NPCScheduleEntry = entry_resource as NPCScheduleEntry
            if entry != null and entry.zone_id == get_zone_id() and entry.contains_hour(hour):
                actor.position = entry.position
                actor.set_meta(&"schedule_activity", entry.activity_tag)
                break

func _find_npc(npc_id: StringName) -> Node2D:
    var npcs: Node = region_root.get_node_or_null(^"NPCs")
    if npcs == null:
        return null
    for child: Node in npcs.get_children():
        if child.get("npc_definition_id") == npc_id:
            return child as Node2D
    return null
