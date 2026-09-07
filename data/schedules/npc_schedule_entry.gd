extends Resource
class_name NPCScheduleEntry

@export_range(0, 23, 1) var start_hour: int = 0
@export_range(0, 23, 1) var end_hour: int = 23
@export var zone_id: StringName = &""
@export var position: Vector2 = Vector2.ZERO
@export var activity_tag: StringName = &"idle"

func contains_hour(hour: int) -> bool:
    if start_hour <= end_hour:
        return hour >= start_hour and hour <= end_hour
    return hour >= start_hour or hour <= end_hour
