extends ContentDefinition
class_name CropDefinition

@export var seed_item_id: StringName = &""
@export var harvest_item_id: StringName = &""
@export_range(1, 8, 1) var growth_stages: int = 4
@export_range(1, 30, 1) var watered_days_per_stage: int = 1
@export_range(1, 99, 1) var harvest_min: int = 1
@export_range(1, 99, 1) var harvest_max: int = 2
@export_range(0, 20, 1) var regrow_watered_days: int = 0
@export var requires_water: bool = true

@export_group("Farm Visual")
@export var farm_stage_source_ids: Array[int] = []
@export var farm_ready_source_id: int = -1

func get_farm_tile_source(stage: int, ready: bool) -> int:
    if ready and farm_ready_source_id >= 0:
        return farm_ready_source_id
    if farm_stage_source_ids.is_empty():
        return -1
    return farm_stage_source_ids[clampi(stage, 0, farm_stage_source_ids.size() - 1)]

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if seed_item_id == &"":
        errors.append("CropDefinition missing seed_item_id for %s" % String(content_id))
    elif not ContentDB.has_definition(seed_item_id):
        errors.append("CropDefinition seed item missing: %s" % String(seed_item_id))
    if harvest_item_id == &"":
        errors.append("CropDefinition missing harvest_item_id for %s" % String(content_id))
    elif not ContentDB.has_definition(harvest_item_id):
        errors.append("CropDefinition harvest item missing: %s" % String(harvest_item_id))
    if harvest_max < harvest_min:
        errors.append("CropDefinition harvest_max must be >= harvest_min for %s" % String(content_id))
    if farm_stage_source_ids.size() < growth_stages:
        errors.append("CropDefinition %s needs at least %d farm_stage_source_ids" % [String(content_id), growth_stages])
    if farm_ready_source_id < 0:
        errors.append("CropDefinition %s requires farm_ready_source_id" % String(content_id))
    return errors
