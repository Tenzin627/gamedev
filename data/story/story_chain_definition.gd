extends ContentDefinition
class_name StoryChainDefinition

@export var region_id: StringName = &""
@export var steps: Array[StoryStepDefinition] = []
@export var completion_world_flag: StringName = &""
@export var completion_label: String = "Story Complete"
@export_multiline var post_quest_hint: String = ""

func get_quest_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    for step: StoryStepDefinition in steps:
        if step != null and step.quest_id != &"":
            result.append(step.quest_id)
    return result

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("story_chain."):
        errors.append("Story chain ID should use story_chain.* namespace")
    if steps.is_empty():
        errors.append("Story chain requires at least one step")
    var seen: Dictionary = {}
    for step: StoryStepDefinition in steps:
        if step == null or step.quest_id == &"":
            errors.append("Story chain contains an invalid step")
            continue
        if seen.has(step.quest_id):
            errors.append("Story chain repeats quest %s" % String(step.quest_id))
        seen[step.quest_id] = true
        if not ContentDB.get_definition(step.quest_id) is QuestDefinition:
            errors.append("Story chain references missing quest %s" % String(step.quest_id))
    return errors
