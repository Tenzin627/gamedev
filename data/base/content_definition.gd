extends Resource
class_name ContentDefinition

@export var content_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var tags: Array[StringName] = []

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if content_id == &"":
        errors.append("Missing content_id")
    elif not String(content_id).contains("."):
        errors.append("content_id should be namespaced, e.g. item.iron_ore")
    if display_name.strip_edges().is_empty():
        errors.append("Missing display_name for %s" % String(content_id))
    return errors
