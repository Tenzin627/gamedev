extends ContentDefinition
class_name RegionDefinition

@export_file("*.tscn") var scene_path: String = ""
@export var default_spawn_id: StringName = &"default"
@export var default_zone_id: StringName = &""
@export var zone_ids: Array[StringName] = []
@export var neighbor_region_ids: Array[StringName] = []
@export var region_tags: Array[StringName] = []

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if scene_path.is_empty():
        errors.append("Region %s is missing scene_path" % String(content_id))
    elif not ResourceLoader.exists(scene_path, "PackedScene"):
        errors.append("Region %s scene_path does not exist: %s" % [String(content_id), scene_path])
    if default_spawn_id == &"":
        errors.append("Region %s is missing default_spawn_id" % String(content_id))
    if default_zone_id != &"" and not String(default_zone_id).begins_with("zone."):
        errors.append("Region %s default_zone_id should use zone.* stable ID: %s" % [String(content_id), String(default_zone_id)])
    if default_zone_id != &"" and not zone_ids.has(default_zone_id):
        errors.append("Region %s default_zone_id is not listed in zone_ids: %s" % [String(content_id), String(default_zone_id)])
    for zone_id: StringName in zone_ids:
        if zone_id == &"":
            errors.append("Region %s has an empty zone_id" % String(content_id))
        elif not String(zone_id).begins_with("zone."):
            errors.append("Region %s zone should use zone.* stable ID: %s" % [String(content_id), String(zone_id)])
    for neighbor_id: StringName in neighbor_region_ids:
        if neighbor_id == &"":
            errors.append("Region %s has an empty neighbor_region_id" % String(content_id))
        elif not String(neighbor_id).begins_with("region."):
            errors.append("Region %s neighbor should use region.* stable ID: %s" % [String(content_id), String(neighbor_id)])
    return errors
