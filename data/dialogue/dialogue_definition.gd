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
        if node_definition.speaker_npc_id != &"" and not ContentDB.get_definition(node_definition.speaker_npc_id) is NPCDefinition:
            errors.append("Dialogue node %s references missing speaker NPC %s" % [String(node_definition.node_id), String(node_definition.speaker_npc_id)])
        for condition: ContentCondition in node_definition.conditions:
            if condition != null:
                errors.append_array(condition.validate_condition())
        for action: ContentAction in node_definition.actions:
            if action != null:
                errors.append_array(action.validate_action())
        for choice: DialogueChoice in node_definition.choices:
            if choice == null:
                errors.append("Dialogue node %s contains an invalid choice" % String(node_definition.node_id))
                continue
            for condition: ContentCondition in choice.conditions:
                if condition != null:
                    errors.append_array(condition.validate_condition())
            for action: ContentAction in choice.actions:
                if action != null:
                    errors.append_array(action.validate_action())
    if get_node_definition(start_node_id) == null:
        errors.append("Missing start node: %s" % String(start_node_id))
    return errors
