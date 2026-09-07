extends PanelContainer
class_name QuestTrackerWidget

@export var story_chain_id: StringName = &""

@onready var _kicker: Label = $Margin/Content/Kicker
@onready var _title: Label = $Margin/Content/Title
@onready var _objective: Label = $Margin/Content/Objective
var _tracked_id: StringName = &""

func _ready() -> void:
    LungSaUIStyle.apply_panel(self, false)
    LungSaUIStyle.apply_kicker(_kicker)
    LungSaUIStyle.apply_title(_title, 16)
    LungSaUIStyle.apply_muted(_objective, 12)
    if not QuestService.quest_accepted.is_connected(_on_quest_changed):
        QuestService.quest_accepted.connect(_on_quest_changed)
    if not QuestService.quest_updated.is_connected(_on_quest_changed):
        QuestService.quest_updated.connect(_on_quest_changed)
    if not QuestService.quest_completed.is_connected(_on_quest_changed):
        QuestService.quest_completed.connect(_on_quest_changed)
    if not WorldStateService.world_state_changed.is_connected(_on_world_state_changed):
        WorldStateService.world_state_changed.connect(_on_world_state_changed)
    refresh()

func get_story_chain() -> StoryChainDefinition:
    var resolved_id: StringName = story_chain_id
    if resolved_id == &"":
        var profile: GameProfileDefinition = ContentDB.get_active_profile()
        if profile != null:
            resolved_id = profile.primary_story_chain_id
    return ContentDB.get_definition(resolved_id) as StoryChainDefinition

func refresh() -> void:
    var active: Array[StringName] = QuestService.get_active_quest_ids()
    if _tracked_id == &"" or not active.has(_tracked_id):
        _tracked_id = _choose_active_quest(active)

    visible = true
    var chain: StoryChainDefinition = get_story_chain()
    if _tracked_id == &"":
        _title.text = chain.display_name if chain != null else "Story"
        _objective.text = _get_next_story_hint(chain)
        return

    var definition: QuestDefinition = ContentDB.get_definition(_tracked_id) as QuestDefinition
    if definition == null:
        _title.text = chain.display_name if chain != null else "Story"
        _objective.text = _get_next_story_hint(chain)
        return

    _title.text = definition.display_name
    for resource: Resource in definition.objectives:
        var objective: QuestObjectiveDefinition = resource as QuestObjectiveDefinition
        if objective == null:
            continue
        var current: int = QuestService.get_objective_progress(_tracked_id, objective.objective_id)
        var required: int = maxi(objective.required_amount, 1)
        if current < required:
            _objective.text = "%s   %d/%d" % [objective.description, current, required]
            return
    _objective.text = "Objectives complete — return to the quest giver."

func _choose_active_quest(active: Array[StringName]) -> StringName:
    var chain: StoryChainDefinition = get_story_chain()
    if chain != null:
        for quest_id: StringName in chain.get_quest_ids():
            if active.has(quest_id):
                return quest_id
    return active[0] if not active.is_empty() else &""

func _get_next_story_hint(chain: StoryChainDefinition) -> String:
    if chain == null:
        return "Open [J] Journal for the current objective."
    for resource: Resource in chain.steps:
        var step: StoryStepDefinition = resource as StoryStepDefinition
        if step == null:
            continue
        var status: String = QuestService.get_quest_status(step.quest_id)
        if status != QuestService.STATUS_COMPLETED:
            if status == QuestService.STATUS_ACTIVE:
                return "Open [J] Journal for the current objective."
            return step.locked_hint
    if chain.completion_world_flag != &"" and not WorldStateService.get_flag(chain.completion_world_flag, false):
        if not chain.post_quest_hint.strip_edges().is_empty():
            return chain.post_quest_hint
        return "Story objectives complete. Resolve the final requirement."
    return "%s Complete. Explore, farm, and prepare for the road ahead." % chain.display_name

func _on_quest_changed(_quest_id: StringName) -> void:
    refresh()

func _on_world_state_changed(_key: StringName, _value: Variant) -> void:
    refresh()
