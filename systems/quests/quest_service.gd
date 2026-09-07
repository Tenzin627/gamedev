extends Node

signal quest_accepted(quest_id: StringName)
signal quest_updated(quest_id: StringName)
signal quest_completed(quest_id: StringName)
signal quest_event_recorded(kind: int, target_id: StringName, total: int)

const STATE_KEY: StringName = &"quest_runtime"
const EVENT_STATE_KEY: StringName = &"quest_event_counts"
const TALK_STATE_KEY: StringName = &"content_talked_npcs"
const STATUS_LOCKED: String = "locked"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"

var _runtime: Dictionary = {}
var _talked_npcs: Dictionary = {}
var _event_counts: Dictionary = {}

func _ready() -> void:
    _load_runtime()
    if not GameSession.session_imported.is_connected(_on_session_imported):
        GameSession.session_imported.connect(_on_session_imported)
    if not GameSession.session_started.is_connected(_on_session_started):
        GameSession.session_started.connect(_on_session_started)
    if not GameSession.session_state_changed.is_connected(_on_session_state_changed):
        GameSession.session_state_changed.connect(_on_session_state_changed)
    if not WorldStateService.world_state_changed.is_connected(_on_world_state_changed):
        WorldStateService.world_state_changed.connect(_on_world_state_changed)
    if not SceneRouter.location_changed.is_connected(_on_location_changed):
        SceneRouter.location_changed.connect(_on_location_changed)

func can_accept(quest_id: StringName) -> bool:
    var definition: QuestDefinition = ContentDB.get_definition(quest_id) as QuestDefinition
    return definition != null and get_quest_status(quest_id) == STATUS_LOCKED and ContentConditionEvaluator.evaluate_all(definition.prerequisites)

func accept_quest(quest_id: StringName) -> bool:
    if not can_accept(quest_id):
        return false
    _runtime[String(quest_id)] = {"status": STATUS_ACTIVE, "objectives": {}}
    _sync()
    quest_accepted.emit(quest_id)
    evaluate_quest(quest_id)
    return true

func get_quest_status(quest_id: StringName) -> String:
    var entry: Variant = _runtime.get(String(quest_id), {})
    if entry is Dictionary:
        return str(Dictionary(entry).get("status", STATUS_LOCKED))
    return STATUS_LOCKED

func get_objective_progress(quest_id: StringName, objective_id: StringName) -> int:
    var entry: Variant = _runtime.get(String(quest_id), {})
    if not entry is Dictionary:
        return 0
    var objectives_variant: Variant = Dictionary(entry).get("objectives", {})
    if not objectives_variant is Dictionary:
        return 0
    return int(Dictionary(objectives_variant).get(String(objective_id), 0))

func notify_talked_to_npc(npc_id: StringName) -> void:
    _talked_npcs[String(npc_id)] = true
    GameSession.set_value(TALK_STATE_KEY, _talked_npcs.duplicate(true))
    notify_event(QuestObjectiveDefinition.Kind.TALK_TO_NPC, npc_id, 1, false)
    evaluate_all_active()

func notify_event(kind: int, target_id: StringName, amount: int = 1, evaluate_after: bool = true) -> void:
    if target_id == &"" or amount <= 0:
        return
    var key: String = _event_key(kind, target_id)
    var total: int = int(_event_counts.get(key, 0)) + amount
    _event_counts[key] = total
    GameSession.set_value(EVENT_STATE_KEY, _event_counts.duplicate(true))
    quest_event_recorded.emit(kind, target_id, total)
    if evaluate_after:
        evaluate_all_active()

func get_event_count(kind: int, target_id: StringName) -> int:
    return int(_event_counts.get(_event_key(kind, target_id), 0))

func evaluate_all_active() -> void:
    for key: Variant in _runtime.keys():
        var quest_id: StringName = StringName(str(key))
        if get_quest_status(quest_id) == STATUS_ACTIVE:
            evaluate_quest(quest_id)

func evaluate_quest(quest_id: StringName) -> void:
    if get_quest_status(quest_id) != STATUS_ACTIVE:
        return
    var definition: QuestDefinition = ContentDB.get_definition(quest_id) as QuestDefinition
    if definition == null:
        return
    var entry: Dictionary = Dictionary(_runtime.get(String(quest_id), {})).duplicate(true)
    var progress: Dictionary = Dictionary(entry.get("objectives", {})).duplicate(true)
    var all_complete: bool = true
    for resource: Resource in definition.objectives:
        var objective: QuestObjectiveDefinition = resource as QuestObjectiveDefinition
        if objective == null:
            continue
        var current: int = _evaluate_objective(objective)
        progress[String(objective.objective_id)] = current
        if current < maxi(objective.required_amount, 1):
            all_complete = false
    entry["objectives"] = progress
    _runtime[String(quest_id)] = entry
    _sync()
    quest_updated.emit(quest_id)
    if all_complete and definition.auto_complete:
        complete_quest(quest_id)

func complete_quest(quest_id: StringName) -> bool:
    if get_quest_status(quest_id) != STATUS_ACTIVE:
        return false
    var definition: QuestDefinition = ContentDB.get_definition(quest_id) as QuestDefinition
    if definition == null:
        return false
    var entry: Dictionary = Dictionary(_runtime.get(String(quest_id), {})).duplicate(true)
    entry["status"] = STATUS_COMPLETED
    _runtime[String(quest_id)] = entry
    if definition.reward_currency != 0:
        var currency: int = int(GameSession.get_value(&"currency", 0))
        GameSession.set_value(&"currency", currency + definition.reward_currency)
    ContentActionExecutor.execute_all(definition.completion_actions)
    _sync()
    quest_completed.emit(quest_id)
    return true

func get_completed_quest_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _runtime.keys():
        var quest_id: StringName = StringName(str(key))
        if get_quest_status(quest_id) == STATUS_COMPLETED:
            result.append(quest_id)
    return result

func get_known_quest_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _runtime.keys():
        result.append(StringName(str(key)))
    return result

func get_active_quest_ids() -> Array[StringName]:
    var result: Array[StringName] = []
    for key: Variant in _runtime.keys():
        var quest_id: StringName = StringName(str(key))
        if get_quest_status(quest_id) == STATUS_ACTIVE:
            result.append(quest_id)
    return result

func _evaluate_objective(objective: QuestObjectiveDefinition) -> int:
    match objective.kind:
        QuestObjectiveDefinition.Kind.TALK_TO_NPC:
            return 1 if _talked_npcs.has(String(objective.target_id)) else get_event_count(objective.kind, objective.target_id)
        QuestObjectiveDefinition.Kind.WORLD_FLAG:
            return 1 if WorldStateService.get_flag(objective.target_id, false) else 0
        QuestObjectiveDefinition.Kind.COLLECT_ITEM:
            return ContentConditionEvaluator._get_inventory_quantity(objective.target_id)
        QuestObjectiveDefinition.Kind.ACTIVATE_WAYMARK:
            return 1 if ContentConditionEvaluator._is_waymark_active(objective.target_id) else get_event_count(objective.kind, objective.target_id)
        QuestObjectiveDefinition.Kind.PLACE_BUILDING:
            return ContentConditionEvaluator._get_placed_building_count(objective.target_id)
        QuestObjectiveDefinition.Kind.REACH_ZONE:
            return 1 if SceneRouter.current_zone_id == objective.target_id else get_event_count(objective.kind, objective.target_id)
        QuestObjectiveDefinition.Kind.SESSION_COUNTER:
            return int(GameSession.get_value(objective.target_id, 0))
        _:
            return get_event_count(objective.kind, objective.target_id)

func _event_key(kind: int, target_id: StringName) -> String:
    return "%d|%s" % [kind, String(target_id)]

func _sync() -> void:
    GameSession.set_value(STATE_KEY, _runtime.duplicate(true))

func _load_runtime() -> void:
    var stored: Variant = GameSession.get_value(STATE_KEY, {})
    _runtime = Dictionary(stored).duplicate(true) if stored is Dictionary else {}
    var talked: Variant = GameSession.get_value(TALK_STATE_KEY, {})
    _talked_npcs = Dictionary(talked).duplicate(true) if talked is Dictionary else {}
    var events: Variant = GameSession.get_value(EVENT_STATE_KEY, {})
    _event_counts = Dictionary(events).duplicate(true) if events is Dictionary else {}

func _on_session_imported() -> void:
    _load_runtime()
    evaluate_all_active()

func _on_session_started(_profile_id: String) -> void:
    _runtime.clear()
    _talked_npcs.clear()
    _event_counts.clear()
    GameSession.set_value(TALK_STATE_KEY, {})
    GameSession.set_value(EVENT_STATE_KEY, {})
    _sync()

func _on_session_state_changed(key: StringName, _value: Variant) -> void:
    # Quest-owned state is written from _sync()/notify_event(); re-evaluating those
    # keys would recurse. All other session changes are legitimate inputs for
    # SESSION_COUNTER and economy/inventory-driven objectives.
    if key == STATE_KEY or key == EVENT_STATE_KEY or key == TALK_STATE_KEY:
        return
    evaluate_all_active()

func _on_world_state_changed(_key: StringName, _value: Variant) -> void:
    evaluate_all_active()

func _on_location_changed(_region_id: StringName, zone_id: StringName, _spawn_id: StringName) -> void:
    notify_event(QuestObjectiveDefinition.Kind.REACH_ZONE, zone_id)
