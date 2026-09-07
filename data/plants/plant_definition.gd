extends ContentDefinition
class_name PlantDefinition

@export var harvest_item_id: StringName = &""
@export_range(1, 99, 1) var harvest_min: int = 1
@export_range(1, 99, 1) var harvest_max: int = 1
@export var region_ids: Array[StringName] = []
@export var discovery_id: StringName = &""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if harvest_item_id == &"":
        errors.append("Plant %s requires harvest_item_id" % String(content_id))
    if harvest_max < harvest_min:
        errors.append("Plant %s harvest_max must be >= harvest_min" % String(content_id))
    return errors
