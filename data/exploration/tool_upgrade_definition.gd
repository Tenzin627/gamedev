extends ContentDefinition
class_name ToolUpgradeDefinition

@export var from_tool_id: StringName = &""
@export var to_tool_id: StringName = &""
@export var material_costs: Dictionary = {}
@export_range(0, 99999, 1) var currency_cost: int = 0
@export var required_progression_tag: StringName = &""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if from_tool_id == &"" or to_tool_id == &"":
        errors.append("Tool upgrade %s requires from/to tool IDs" % String(content_id))
    return errors
