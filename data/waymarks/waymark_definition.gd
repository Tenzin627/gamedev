extends ContentDefinition
class_name WaymarkDefinition

@export var region_id: StringName = &""
@export var zone_id: StringName = &""
@export var spawn_id: StringName = &"default"
@export var activation_state_key: StringName = &""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if region_id == &"":
        errors.append("Waymark %s is missing region_id" % String(content_id))
    elif not String(region_id).begins_with("region."):
        errors.append("Waymark %s region_id should use region.* stable ID" % String(content_id))
    if zone_id == &"":
        errors.append("Waymark %s is missing zone_id" % String(content_id))
    elif not String(zone_id).begins_with("zone."):
        errors.append("Waymark %s zone_id should use zone.* stable ID" % String(content_id))
    if spawn_id == &"":
        errors.append("Waymark %s is missing spawn_id" % String(content_id))
    if activation_state_key == &"":
        errors.append("Waymark %s is missing activation_state_key" % String(content_id))
    elif not String(activation_state_key).begins_with("world."):
        errors.append("Waymark %s activation_state_key should use world.* stable key" % String(content_id))
    return errors
