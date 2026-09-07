extends ContentDefinition
class_name NPCDefinition

@export var default_dialogue_id: StringName = &""
@export var role: String = "Resident"
@export var portrait_key: StringName = &""
@export var portrait_texture: Texture2D
@export var world_texture: Texture2D

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("npc."):
        errors.append("NPC ID should use npc.* namespace")
    if default_dialogue_id != &"" and not ContentDB.has_definition(default_dialogue_id):
        errors.append("Unknown dialogue: %s" % String(default_dialogue_id))
    return errors
