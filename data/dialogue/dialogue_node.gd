extends Resource
class_name DialogueNode

@export var node_id: StringName = &""
@export var entry_point: bool = true
@export_group("Presentation")
@export var speaker_npc_id: StringName = &""
@export var speaker_override: String = ""
@export var role_override: String = ""
@export var show_portrait: bool = true
@export_group("")
@export_multiline var text: String = ""
@export var conditions: Array[ContentCondition] = []
@export var actions: Array[ContentAction] = []
@export var choices: Array[DialogueChoice] = []
@export var next_node_id: StringName = &""
