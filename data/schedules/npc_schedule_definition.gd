extends ContentDefinition
class_name NPCScheduleDefinition

@export var npc_id: StringName = &""
@export var entries: Array[Resource] = []

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not ContentDB.get_definition(npc_id) is NPCDefinition:
        errors.append("NPC schedule has unknown npc_id: %s" % String(npc_id))
    if entries.is_empty():
        errors.append("NPC schedule has no entries")
    for entry: Resource in entries:
        if not entry is NPCScheduleEntry:
            errors.append("NPC schedule contains invalid entry")
    return errors
