extends Node
class_name ExplorationProgressService

signal discovery_added(discovery_id: StringName)
signal region_progress_changed(region_id: StringName, percent: int)

const DISCOVERED_KEY: String = "exploration_discoveries"

func discover(discovery_id: StringName) -> bool:
    var definition: DiscoveryDefinition = ContentDB.get_definition(discovery_id) as DiscoveryDefinition
    if definition == null:
        return false
    var discoveries: Array[String] = _get_discoveries()
    var key: String = String(discovery_id)
    if discoveries.has(key):
        return false
    discoveries.append(key)
    GameSession.set_value(&"exploration_discoveries", discoveries)
    if definition.world_flag_on_discover != &"":
        WorldStateService.set_flag(definition.world_flag_on_discover, true)
    QuestService.notify_event(QuestObjectiveDefinition.Kind.DISCOVER_CONTENT, discovery_id, 1)
    discovery_added.emit(discovery_id)
    region_progress_changed.emit(definition.region_id, get_region_completion_percent(definition.region_id))
    return true

func is_discovered(discovery_id: StringName) -> bool:
    return _get_discoveries().has(String(discovery_id))

func get_region_completion_percent(region_id: StringName) -> int:
    var total: int = 0
    var earned: int = 0
    for content_id: StringName in ContentDB.get_all_ids():
        var definition: DiscoveryDefinition = ContentDB.get_definition(content_id) as DiscoveryDefinition
        if definition == null or definition.region_id != region_id:
            continue
        total += definition.completion_weight
        if is_discovered(content_id):
            earned += definition.completion_weight
    if total <= 0:
        return 0
    return clampi(int(round(float(earned) * 100.0 / float(total))), 0, 100)

func get_discovered_count(region_id: StringName = &"") -> int:
    if region_id == &"":
        return _get_discoveries().size()
    var count: int = 0
    for id_text: String in _get_discoveries():
        var definition: DiscoveryDefinition = ContentDB.get_definition(StringName(id_text)) as DiscoveryDefinition
        if definition != null and definition.region_id == region_id:
            count += 1
    return count

func _get_discoveries() -> Array[String]:
    var result: Array[String] = []
    var value: Variant = GameSession.get_value(&"exploration_discoveries", [])
    if value is Array:
        for entry: Variant in Array(value):
            var text: String = str(entry)
            if not text.is_empty() and not result.has(text):
                result.append(text)
    return result
