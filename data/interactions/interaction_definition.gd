extends ContentDefinition
class_name InteractionDefinition

@export var action_name: StringName = &"interact"
@export var states: Array[InteractionStateDefinition] = []
@export var fallback_prompt: String = "Interact"
@export_multiline var fallback_feedback: String = "Nothing happens."

func get_matching_state() -> InteractionStateDefinition:
    for state: InteractionStateDefinition in states:
        if state != null and ContentConditionEvaluator.evaluate_all(state.conditions):
            return state
    return null

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("interaction."):
        errors.append("Interaction ID should use interaction.* namespace")
    if states.is_empty():
        errors.append("Interaction should define at least one state")
    return errors
