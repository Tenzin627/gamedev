extends Resource
class_name DialogueChoice

@export var text: String = "Continue"
@export var next_node_id: StringName = &""
@export var conditions: Array[ContentCondition] = []
@export var actions: Array[ContentAction] = []
