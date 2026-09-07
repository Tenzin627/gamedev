extends RefCounted
class_name BattleOpponentPolicy

const DEFAULT_PROFILE_ID: StringName = &"battle_ai.standard"

static func choose_action(model: BattleStateModel, profile_id: StringName = DEFAULT_PROFILE_ID) -> BattleAction:
    if model == null or model.opponent_team == null:
        return null
    var team: BattleTeamState = model.opponent_team
    var active: BattleCreatureState = team.get_active_creature()
    if active == null or active.is_fainted():
        return _forced_switch(team, active)
    var profile: BattleAIProfileDefinition = ContentDB.get_definition(profile_id) as BattleAIProfileDefinition
    if profile == null:
        profile = BattleAIProfileDefinition.new()
    var player_active: BattleCreatureState = model.get_player_active()
    var tactical_switch: BattleAction = _choose_tactical_switch(team, active, player_active, profile)
    if tactical_switch != null:
        return tactical_switch
    return _choose_best_move(active, player_active, profile)

static func _forced_switch(team: BattleTeamState, active: BattleCreatureState) -> BattleAction:
    var available: Array[int] = team.get_available_indices()
    if available.is_empty():
        return null
    return BattleAction.switch_action(&"opponent", active, available[0])

static func _choose_tactical_switch(team: BattleTeamState, active: BattleCreatureState, enemy: BattleCreatureState, profile: BattleAIProfileDefinition) -> BattleAction:
    if not profile.allow_tactical_switch or team.switch_cooldown_turns_remaining > 0 or enemy == null:
        return null
    var current_relation: int = _relation(active.archetype, enemy.archetype)
    var low_hp: bool = active.get_hp_ratio() <= profile.switch_hp_threshold
    if not low_hp and current_relation >= 0:
        return null
    var best_index: int = -1
    var best_relation: int = current_relation
    for index: int in team.get_available_indices():
        if index == team.active_index:
            continue
        var candidate: BattleCreatureState = team.creatures[index]
        var candidate_relation: int = _relation(candidate.archetype, enemy.archetype)
        if candidate_relation > best_relation:
            best_relation = candidate_relation
            best_index = index
    if best_index >= 0 and (low_hp or best_relation > current_relation):
        return BattleAction.switch_action(&"opponent", active, best_index)
    return null

static func _choose_best_move(active: BattleCreatureState, enemy: BattleCreatureState, profile: BattleAIProfileDefinition) -> BattleAction:
    var best_move_id: StringName = &""
    var best_score: float = -999999.0
    for move_id: StringName in active.equipped_move_ids:
        var move_definition: MoveDefinition = ContentDB.get_definition(move_id) as MoveDefinition
        if move_definition == null:
            continue
        var score: float = float(move_definition.priority) * 0.15
        if move_definition.role == "Damage":
            score += float(move_definition.power) * profile.damage_weight
            if enemy != null:
                score += float(_relation(active.archetype, enemy.archetype)) * profile.advantage_weight * 5.0
        elif move_definition.role == "Defense" or move_definition.role == "Recovery":
            score += profile.defense_weight * 5.0
            if active.get_hp_ratio() < 0.5:
                score += 3.0
        else:
            score += profile.status_weight * 5.0
        if score > best_score or (is_equal_approx(score, best_score) and String(move_id) < String(best_move_id)):
            best_score = score
            best_move_id = move_id
    if best_move_id == &"":
        return null
    return BattleAction.move_action(&"opponent", active, best_move_id)

static func _relation(attacker: StringName, defender: StringName) -> int:
    if attacker == defender:
        return 0
    if (attacker == &"attack" and defender == &"speed") or (attacker == &"speed" and defender == &"guard") or (attacker == &"guard" and defender == &"attack"):
        return 1
    if (defender == &"attack" and attacker == &"speed") or (defender == &"speed" and attacker == &"guard") or (defender == &"guard" and attacker == &"attack"):
        return -1
    return 0
