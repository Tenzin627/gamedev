extends ItemDefinition
class_name ToolDefinition

@export var tool_tag: StringName = &""
@export_range(1, 99, 1) var power: int = 1
@export_range(1, 10, 1) var tool_tier: int = 1
@export_range(16.0, 192.0, 1.0) var reach: float = 88.0
@export_range(0.0, 3.0, 0.01) var use_cooldown_seconds: float = 0.24

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if category != "Tool":
        errors.append("ToolDefinition category must be Tool for %s" % String(content_id))
    if tool_tag == &"":
        errors.append("ToolDefinition is missing tool_tag for %s" % String(content_id))
    if power <= 0:
        errors.append("ToolDefinition power must be greater than 0 for %s" % String(content_id))
    if tool_tier <= 0:
        errors.append("ToolDefinition tool_tier must be greater than 0 for %s" % String(content_id))
    if reach <= 0.0:
        errors.append("ToolDefinition reach must be greater than 0 for %s" % String(content_id))
    if max_stack != 1:
        errors.append("ToolDefinition max_stack should be 1 for %s" % String(content_id))
    return errors
