extends ContentDefinition
class_name DialogueDefinition

@export var start_node_id: StringName = &"start"
@export var nodes: Array[DialogueNode] = []

func get_node_definition(node_id: StringName) -> DialogueNode:
    for node_definition: DialogueNode in nodes:
        if node_definition != null and node_definition.node_id == node_id:
            return node_definition
    return null

func get_first_available_node() -> DialogueNode:
    var preferred: DialogueNode = get_node_definition(start_node_id)
    if preferred != null and ContentConditionEvaluator.evaluate_all(preferred.conditions):
        return preferred
    for node_definition: DialogueNode in nodes:
        if node_definition != null and ContentConditionEvaluator.evaluate_all(node_definition.conditions):
            return node_definition
    return null

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("dialogue."):
        errors.append("Dialogue ID should use dialogue.* namespace")
    var seen: Dictionary = {}
    for node_definition: DialogueNode in nodes:
        if node_definition == null or node_definition.node_id == &"":
            errors.append("Dialogue contains invalid node")
            continue
        if seen.has(node_definition.node_id):
            errors.append("Duplicate dialogue node: %s" % String(node_definition.node_id))
        seen[node_definition.node_id] = true
    if get_node_definition(start_node_id) == null:
        errors.append("Missing start node: %s" % String(start_node_id))
    return errors
