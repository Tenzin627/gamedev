extends ContentDefinition
class_name WorldReactionDefinition

@export var region_id: StringName = &""
@export var conditions: Array[ContentCondition] = []
@export var actions: Array[ContentAction] = []
@export var completion_world_flag: StringName = &""
@export var reaction_event_id: StringName = &""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("world_reaction."):
        errors.append("World reaction ID should use world_reaction.* namespace")
    if region_id == &"":
        errors.append("World reaction is missing region_id")
    elif not ContentDB.get_definition(region_id) is RegionDefinition:
        errors.append("World reaction references missing region %s" % String(region_id))
    if conditions.is_empty():
        errors.append("World reaction should define at least one condition")
    for condition: ContentCondition in conditions:
        if condition != null:
            errors.append_array(condition.validate_condition())
    for action: ContentAction in actions:
        if action != null:
            errors.append_array(action.validate_action())
    return errors
