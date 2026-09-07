extends ContentDefinition
class_name DiscoveryDefinition

@export_enum("Landmark", "Hidden", "Plant", "Resource") var discovery_kind: String = "Landmark"
@export var region_id: StringName = &""
@export var zone_id: StringName = &""
@export_range(0, 100, 1) var completion_weight: int = 10
@export var world_flag_on_discover: StringName = &""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if region_id == &"":
        errors.append("Discovery %s requires region_id" % String(content_id))
    if completion_weight < 0:
        errors.append("Discovery %s completion_weight cannot be negative" % String(content_id))
    return errors
