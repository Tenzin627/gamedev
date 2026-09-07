extends RefCounted
class_name PlayerProgressionService

const TRACK_FARMER: StringName = &"farmer"
const TRACK_TAMER: StringName = &"tamer"
const TRACK_EXPLORER: StringName = &"explorer"
const PROFILE_KEY: StringName = &"player_progression"

static func get_points(track_id: StringName) -> int:
    var state: Dictionary = _get_state()
    var tracks: Dictionary = Dictionary(state.get("tracks", {}))
    return maxi(int(tracks.get(String(track_id), 0)), 0)

static func add_points(track_id: StringName, amount: int) -> int:
    if track_id == &"" or amount <= 0:
        return get_points(track_id)
    var state: Dictionary = _get_state()
    var tracks: Dictionary = Dictionary(state.get("tracks", {})).duplicate(true)
    var value: int = maxi(int(tracks.get(String(track_id), 0)) + amount, 0)
    tracks[String(track_id)] = value
    state["tracks"] = tracks
    GameSession.set_value(PROFILE_KEY, state)
    _claim_eligible_milestones()
    return value

static func get_rank(track_id: StringName) -> int:
    var rank: int = 0
    var points: int = get_points(track_id)
    for definition: ProgressionMilestoneDefinition in _get_milestones(track_id):
        if points >= definition.required_points:
            rank = maxi(rank, definition.rank)
    return rank

static func get_profile_tags() -> Array[StringName]:
    var tags: Array[StringName] = []
    for track_id: StringName in [TRACK_FARMER, TRACK_TAMER, TRACK_EXPLORER]:
        var rank: int = get_rank(track_id)
        if rank > 0:
            tags.append(StringName("%s_rank_%d" % [String(track_id), rank]))
    var scores: Array[Dictionary] = [
        {"track": TRACK_FARMER, "points": get_points(TRACK_FARMER)},
        {"track": TRACK_TAMER, "points": get_points(TRACK_TAMER)},
        {"track": TRACK_EXPLORER, "points": get_points(TRACK_EXPLORER)},
    ]
    scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["points"]) > int(b["points"]))
    if not scores.is_empty() and int(scores[0]["points"]) >= 25:
        tags.append(StringName("path.%s" % String(scores[0]["track"])))
    if scores.size() >= 3 and int(scores[2]["points"]) >= 25:
        tags.append(&"path.wayfarer")
    return tags

static func has_unlock_tag(tag: StringName) -> bool:
    if tag == &"":
        return true
    for definition: ProgressionMilestoneDefinition in _get_milestones(&""):
        if definition.unlock_tags.has(tag) and get_points(definition.track_id) >= definition.required_points:
            return true
    return false

static func get_summary() -> Dictionary:
    return {
        "farmer_points": get_points(TRACK_FARMER), "farmer_rank": get_rank(TRACK_FARMER),
        "tamer_points": get_points(TRACK_TAMER), "tamer_rank": get_rank(TRACK_TAMER),
        "explorer_points": get_points(TRACK_EXPLORER), "explorer_rank": get_rank(TRACK_EXPLORER),
        "profile_tags": get_profile_tags(),
    }

static func _claim_eligible_milestones() -> void:
    var state: Dictionary = _get_state()
    var claimed: Array = Array(state.get("claimed_milestones", [])).duplicate()
    var changed: bool = false
    for definition: ProgressionMilestoneDefinition in _get_milestones(&""):
        var key: String = String(definition.content_id)
        if claimed.has(key) or get_points(definition.track_id) < definition.required_points:
            continue
        claimed.append(key)
        if definition.reward_currency > 0:
            var currency: int = int(GameSession.get_value(&"currency", 0))
            GameSession.set_value(&"currency", currency + definition.reward_currency)
        changed = true
    if changed:
        state = _get_state()
        state["claimed_milestones"] = claimed
        GameSession.set_value(PROFILE_KEY, state)

static func _get_milestones(track_id: StringName) -> Array[ProgressionMilestoneDefinition]:
    var result: Array[ProgressionMilestoneDefinition] = []
    for content_id: StringName in ContentDB.get_all_ids():
        var definition: ProgressionMilestoneDefinition = ContentDB.get_definition(content_id) as ProgressionMilestoneDefinition
        if definition == null:
            continue
        if track_id == &"" or definition.track_id == track_id:
            result.append(definition)
    result.sort_custom(func(a: ProgressionMilestoneDefinition, b: ProgressionMilestoneDefinition) -> bool: return a.rank < b.rank)
    return result

static func _get_state() -> Dictionary:
    var stored: Variant = GameSession.get_value(PROFILE_KEY, {})
    if stored is Dictionary:
        return Dictionary(stored).duplicate(true)
    return {"tracks": {}, "claimed_milestones": []}
