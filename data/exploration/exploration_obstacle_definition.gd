extends ContentDefinition
class_name ExplorationObstacleDefinition

@export var required_tool_tag: StringName = &""
@export_range(0, 10, 1) var minimum_tool_tier: int = 0
@export var required_world_flag: StringName = &""
@export var completion_world_flag: StringName = &""
@export var blocked_prompt: String = "The way is blocked"
@export var clear_prompt: String = "Clear obstacle"

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if required_tool_tag == &"" and required_world_flag == &"":
        errors.append("Obstacle %s needs a tool or world-state requirement" % String(content_id))
    if completion_world_flag == &"":
        errors.append("Obstacle %s requires completion_world_flag" % String(content_id))
    return errors
