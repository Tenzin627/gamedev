extends ContentDefinition
class_name ResourceDistributionDefinition

@export var region_id: StringName = &""
@export var zone_id: StringName = &""
@export var resource_tags: Array[StringName] = []
@export var forage_tags: Array[StringName] = []
@export_range(0.0, 4.0, 0.05) var abundance: float = 1.0
@export_range(0.0, 4.0, 0.05) var recovery_rate: float = 1.0

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if region_id == &"" or zone_id == &"":
        errors.append("Resource distribution requires region_id and zone_id")
    if resource_tags.is_empty() and forage_tags.is_empty():
        errors.append("Resource distribution should expose resource or forage tags")
    return errors
