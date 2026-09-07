extends ContentDefinition
class_name ZoneDefinition

@export var region_id: StringName = &""
@export_file("*.tscn") var scene_path: String = ""
@export var default_spawn_id: StringName = &"default"
@export var neighbor_zone_ids: Array[StringName] = []
@export var zone_tags: Array[StringName] = []
@export var weather_profile_id: StringName = &""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if region_id == &"":
        errors.append("Zone %s is missing region_id" % String(content_id))
    elif not String(region_id).begins_with("region."):
        errors.append("Zone %s region_id should use region.* stable ID: %s" % [String(content_id), String(region_id)])
    if scene_path.is_empty():
        errors.append("Zone %s is missing scene_path" % String(content_id))
    elif not ResourceLoader.exists(scene_path, "PackedScene"):
        errors.append("Zone %s scene_path does not exist: %s" % [String(content_id), scene_path])
    if default_spawn_id == &"":
        errors.append("Zone %s is missing default_spawn_id" % String(content_id))
    for neighbor_id: StringName in neighbor_zone_ids:
        if neighbor_id == &"":
            errors.append("Zone %s has an empty neighbor_zone_id" % String(content_id))
        elif not String(neighbor_id).begins_with("zone."):
            errors.append("Zone %s neighbor should use zone.* stable ID: %s" % [String(content_id), String(neighbor_id)])
    if weather_profile_id != &"" and not String(weather_profile_id).begins_with("weather_profile."):
        errors.append("Zone %s weather_profile_id should use weather_profile.* stable ID: %s" % [String(content_id), String(weather_profile_id)])
    return errors
