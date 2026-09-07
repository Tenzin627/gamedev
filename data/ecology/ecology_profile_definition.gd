extends ContentDefinition
class_name EcologyProfileDefinition

@export var region_id: StringName = &""
@export var habitat_ids: Array[StringName] = []
@export var resource_tags: Array[StringName] = []
@export var restoration_flags: Array[StringName] = []
@export_range(0.0, 1.0, 0.01) var base_health: float = 0.45
@export_range(0.0, 1.0, 0.01) var restoration_value_per_flag: float = 0.12

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if region_id == &"" or not String(region_id).begins_with("region."):
        errors.append("Ecology profile requires a region.* ID")
    for habitat_id: StringName in habitat_ids:
        if not ContentDB.get_definition(habitat_id) is HabitatDefinition:
            errors.append("Unknown habitat in ecology profile: %s" % String(habitat_id))
    return errors
