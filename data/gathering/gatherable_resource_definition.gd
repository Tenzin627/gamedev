extends ContentDefinition
class_name GatherableResourceDefinition

## Data definition for a common painted resource such as a tree or rock.
## TileMap content decides where/which tile is displayed; this Resource owns
## gameplay behavior so designers do not edit gathering scripts.

@export var accepted_tool_tags: PackedStringArray = PackedStringArray()
@export_range(0, 10, 1) var minimum_tool_tier: int = 0
@export_range(1, 99, 1) var durability: int = 3
@export var loot_table_id: StringName = &""
@export_range(0.0, 86400.0, 0.1) var respawn_seconds: float = 0.0

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("resource."):
        errors.append("Gatherable resource ID should use resource.* namespace")
    if accepted_tool_tags.is_empty():
        errors.append("Gatherable resource %s requires at least one accepted tool tag" % String(content_id))
    if durability <= 0:
        errors.append("Gatherable resource %s requires durability > 0" % String(content_id))
    if loot_table_id == &"" or not ContentDB.get_definition(loot_table_id) is LootTableDefinition:
        errors.append("Gatherable resource %s references missing loot table %s" % [String(content_id), String(loot_table_id)])
    return errors
