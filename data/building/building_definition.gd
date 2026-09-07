extends ContentDefinition
class_name BuildingDefinition

@export var footprint_tiles: Vector2i = Vector2i.ONE
@export var grid_snapped: bool = true
@export var costs: Array[BuildCostEntry] = []
@export var placement_tags: Array[StringName] = [&"outdoor"]
@export var removable: bool = true
@export var world_texture: Texture2D
@export var menu_category: StringName = &"building"
@export var menu_order: int = 100

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if footprint_tiles.x <= 0 or footprint_tiles.y <= 0:
        errors.append("footprint_tiles must be positive for %s" % String(content_id))
    if world_texture == null:
        errors.append("Building %s requires an explicit world_texture" % String(content_id))
    for cost: BuildCostEntry in costs:
        if cost == null:
            errors.append("null building cost in %s" % String(content_id))
        else:
            errors.append_array(cost.validate_cost())
    return errors
