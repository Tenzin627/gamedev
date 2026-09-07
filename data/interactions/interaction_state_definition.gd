extends Resource
class_name InteractionStateDefinition

@export var conditions: Array[ContentCondition] = []
@export var prompt_text: String = "Interact"
@export_multiline var feedback_text: String = ""
@export var actions: Array[ContentAction] = []
@export var quest_event_target_id: StringName = &""
@export_range(1, 999, 1) var quest_event_amount: int = 1

func validate_state() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if prompt_text.strip_edges().is_empty():
        errors.append("Interaction state is missing prompt_text")
    for condition: ContentCondition in conditions:
        if condition != null:
            errors.append_array(condition.validate_condition())
    for action: ContentAction in actions:
        if action != null:
            errors.append_array(action.validate_action())
    return errors
