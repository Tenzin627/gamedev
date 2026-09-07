extends ContentDefinition
class_name QuestDefinition

@export var region_id: StringName = &""
@export_enum("Main", "Regional", "Side") var quest_category: String = "Side"
@export var quest_chain_id: StringName = &""
@export var chain_order: int = 0
@export var consequence_summary: String = ""
@export var prerequisites: Array[ContentCondition] = []
@export var objectives: Array[QuestObjectiveDefinition] = []
@export var reward_currency: int = 0
@export var completion_actions: Array[ContentAction] = []
@export var auto_complete: bool = true

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("quest."):
        errors.append("Quest ID should use quest.* namespace")
    if objectives.is_empty():
        errors.append("Quest requires at least one objective")
    var seen: Dictionary = {}
    for objective: QuestObjectiveDefinition in objectives:
        if objective == null:
            errors.append("Quest contains invalid objective")
            continue
        for objective_error: String in objective.validate_objective():
            errors.append(objective_error)
        if objective.objective_id == &"":
            continue
        if seen.has(objective.objective_id):
            errors.append("Duplicate objective ID: %s" % String(objective.objective_id))
        seen[objective.objective_id] = true
    for condition: ContentCondition in prerequisites:
        if condition != null:
            errors.append_array(condition.validate_condition())
    for action: ContentAction in completion_actions:
        if action != null:
            errors.append_array(action.validate_action())
    return errors
