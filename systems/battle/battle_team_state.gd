extends RefCounted
class_name BattleTeamState

const MAX_TEAM_SIZE: int = 3

var side_id: StringName = &""
var display_name: String = ""
var creatures: Array[BattleCreatureState] = []
var active_index: int = 0
var switch_cooldown_turns_remaining: int = 0

func add_creature(creature: BattleCreatureState) -> bool:
    if creature == null or creatures.size() >= MAX_TEAM_SIZE:
        return false
    creatures.append(creature)
    if creatures.size() == 1:
        active_index = 0
    return true

func get_active_creature() -> BattleCreatureState:
    if active_index < 0 or active_index >= creatures.size():
        return null
    return creatures[active_index]

func set_active_index(index: int) -> bool:
    if index < 0 or index >= creatures.size():
        return false
    var candidate: BattleCreatureState = creatures[index]
    if candidate == null or candidate.is_fainted():
        return false
    active_index = index
    return true

func ensure_active_available() -> bool:
    var active: BattleCreatureState = get_active_creature()
    if active != null and not active.is_fainted():
        return true
    var available: Array[int] = get_available_indices()
    if available.is_empty():
        return false
    active_index = available[0]
    return true

func get_available_indices() -> Array[int]:
    var result: Array[int] = []
    for index: int in range(creatures.size()):
        var creature: BattleCreatureState = creatures[index]
        if creature != null and not creature.is_fainted():
            result.append(index)
    return result

func has_available_creature() -> bool:
    return not get_available_indices().is_empty()

func is_defeated() -> bool:
    return not has_available_creature()

func tick_switch_cooldown() -> void:
    switch_cooldown_turns_remaining = maxi(switch_cooldown_turns_remaining - 1, 0)

func to_debug_dict() -> Dictionary:
    var creature_rows: Array[Dictionary] = []
    for creature: BattleCreatureState in creatures:
        creature_rows.append(creature.to_debug_dict() if creature != null else {})
    return {
        "side_id": String(side_id),
        "display_name": display_name,
        "active_index": active_index,
        "switch_cooldown_turns_remaining": switch_cooldown_turns_remaining,
        "creatures": creature_rows,
    }
