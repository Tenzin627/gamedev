extends RefCounted
class_name DialogueRunner

var dialogue: DialogueDefinition = null
var npc_id: StringName = &""
var speaker_name: String = ""
var current_node: DialogueNode = null

func begin(definition: DialogueDefinition, source_npc_id: StringName, default_speaker: String) -> bool:
    dialogue = definition
    npc_id = source_npc_id
    speaker_name = default_speaker
    current_node = dialogue.get_first_available_node() if dialogue != null else null
    if current_node == null:
        return false
    ContentActionExecutor.execute_all(current_node.actions)
    return true

func get_speaker() -> String:
    if current_node == null:
        return speaker_name
    return current_node.speaker_override if not current_node.speaker_override.is_empty() else speaker_name

func get_text() -> String:
    return current_node.text if current_node != null else ""

func get_available_choices() -> Array[DialogueChoice]:
    var result: Array[DialogueChoice] = []
    if current_node == null:
        return result
    for resource: Resource in current_node.choices:
        var choice: DialogueChoice = resource as DialogueChoice
        if choice != null and ContentConditionEvaluator.evaluate_all(choice.conditions):
            result.append(choice)
    return result

func advance(choice_index: int = -1) -> bool:
    if current_node == null:
        return false
    var next_id: StringName = current_node.next_node_id
    var choices: Array[DialogueChoice] = get_available_choices()
    if not choices.is_empty():
        if choice_index < 0 or choice_index >= choices.size():
            return false
        var choice: DialogueChoice = choices[choice_index]
        ContentActionExecutor.execute_all(choice.actions)
        next_id = choice.next_node_id
    if next_id == &"":
        current_node = null
        return false
    var next_node: DialogueNode = dialogue.get_node_definition(next_id)
    if next_node == null or not ContentConditionEvaluator.evaluate_all(next_node.conditions):
        current_node = null
        return false
    current_node = next_node
    ContentActionExecutor.execute_all(current_node.actions)
    return true
