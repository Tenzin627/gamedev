extends RefCounted
class_name BattleStateModel

signal state_changed
signal phase_changed(previous_phase: StringName, current_phase: StringName)
signal command_requested(command_type: StringName)
signal battle_finished(winner_side_id: StringName, reason: StringName)

const PHASE_INITIALIZING: StringName = &"initializing"
const PHASE_AWAITING_PLAYER_COMMAND: StringName = &"awaiting_player_command"
const PHASE_AWAITING_OPPONENT_COMMAND: StringName = &"awaiting_opponent_command"
const PHASE_RESOLVING: StringName = &"resolving"
const PHASE_VICTORY: StringName = &"victory"
const PHASE_DEFEAT: StringName = &"defeat"
const PHASE_ESCAPED: StringName = &"escaped"
const PHASE_ENDED: StringName = &"ended"

const COMMAND_MOVES: StringName = &"moves"
const COMMAND_ITEM: StringName = &"item"
const COMMAND_SWITCH: StringName = &"switch"
const COMMAND_ESCAPE: StringName = &"escape"
const COMMAND_BOND: StringName = &"bond"

var battle_id: String = ""
var encounter_kind: StringName = &"wild"
var environment_id: StringName = &""
var ruleset_id: StringName = &"battle_rules.standard"
var phase: StringName = PHASE_INITIALIZING
var round_number: int = 0
var turn_number: int = 0
var player_team: BattleTeamState
var opponent_team: BattleTeamState
var winner_side_id: StringName = &""
var result_reason: StringName = &""
var opponent_ai_profile_id: StringName = &"battle_ai.standard"
var outcome_committed: bool = false
var last_command_request: StringName = &""
var event_log: Array[String] = []
var bond_standard_attempt_used: bool = false
var bond_paid_attempts: int = 0
var bonded_instance_id: String = ""

func begin_battle() -> bool:
    if not is_valid_setup():
        return false
    round_number = 1
    turn_number = 1
    winner_side_id = &""
    result_reason = &""
    event_log.clear()
    bond_standard_attempt_used = false
    bond_paid_attempts = 0
    bonded_instance_id = ""
    event_log.append("Battle started.")
    _set_phase(PHASE_AWAITING_PLAYER_COMMAND)
    return true

func is_valid_setup() -> bool:
    if player_team == null or opponent_team == null:
        return false
    if player_team.creatures.is_empty() or opponent_team.creatures.is_empty():
        return false
    var ruleset: BattleRulesetDefinition = get_ruleset()
    var allowed_party_size: int = BattleTeamState.MAX_TEAM_SIZE if ruleset == null else clampi(ruleset.party_size, 1, BattleTeamState.MAX_TEAM_SIZE)
    if player_team.creatures.size() > allowed_party_size:
        return false
    if opponent_team.creatures.size() > allowed_party_size:
        return false
    return player_team.ensure_active_available() and opponent_team.ensure_active_available()

func get_player_active() -> BattleCreatureState:
    return null if player_team == null else player_team.get_active_creature()

func get_opponent_active() -> BattleCreatureState:
    return null if opponent_team == null else opponent_team.get_active_creature()

func can_accept_player_command() -> bool:
    return phase == PHASE_AWAITING_PLAYER_COMMAND and not is_finished()

func request_player_command(command_type: StringName) -> bool:
    if not can_accept_player_command() or not is_valid_command_type(command_type):
        return false
    last_command_request = command_type
    event_log.append("Player requested command: %s" % String(command_type))
    command_requested.emit(command_type)
    state_changed.emit()
    return true

func is_valid_command_type(command_type: StringName) -> bool:
    return command_type == COMMAND_MOVES or command_type == COMMAND_ITEM or command_type == COMMAND_SWITCH or command_type == COMMAND_ESCAPE or command_type == COMMAND_BOND

func set_active_creature(side_id: StringName, index: int) -> bool:
    var team: BattleTeamState = _get_team(side_id)
    if team == null or not team.set_active_index(index):
        return false
    event_log.append("%s active slot changed to %d." % [String(side_id), index])
    state_changed.emit()
    return true

func set_phase_for_resolution(new_phase: StringName) -> bool:
    if new_phase != PHASE_AWAITING_PLAYER_COMMAND and new_phase != PHASE_AWAITING_OPPONENT_COMMAND and new_phase != PHASE_RESOLVING:
        return false
    _set_phase(new_phase)
    return true

func finish_battle(winner: StringName, reason: StringName) -> void:
    if is_finished():
        return
    winner_side_id = winner
    result_reason = reason
    if winner == &"player":
        _set_phase(PHASE_VICTORY)
    elif winner == &"opponent":
        _set_phase(PHASE_DEFEAT)
    elif reason == &"escaped":
        _set_phase(PHASE_ESCAPED)
    else:
        _set_phase(PHASE_ENDED)
    event_log.append("Battle finished: %s / %s" % [String(winner_side_id), String(result_reason)])
    battle_finished.emit(winner_side_id, result_reason)

func is_finished() -> bool:
    return phase == PHASE_VICTORY or phase == PHASE_DEFEAT or phase == PHASE_ESCAPED or phase == PHASE_ENDED

func get_ruleset() -> BattleRulesetDefinition:
    return ContentDB.get_definition(ruleset_id) as BattleRulesetDefinition

func to_debug_dict() -> Dictionary:
    return {
        "battle_id": battle_id,
        "encounter_kind": String(encounter_kind),
        "environment_id": String(environment_id),
        "ruleset_id": String(ruleset_id),
        "phase": String(phase),
        "round_number": round_number,
        "turn_number": turn_number,
        "winner_side_id": String(winner_side_id),
        "result_reason": String(result_reason),
        "opponent_ai_profile_id": String(opponent_ai_profile_id),
        "outcome_committed": outcome_committed,
        "last_command_request": String(last_command_request),
        "player_team": {} if player_team == null else player_team.to_debug_dict(),
        "opponent_team": {} if opponent_team == null else opponent_team.to_debug_dict(),
        "event_log": event_log.duplicate(),
        "bond_standard_attempt_used": bond_standard_attempt_used,
        "bond_paid_attempts": bond_paid_attempts,
        "bonded_instance_id": bonded_instance_id,
    }

func _get_team(side_id: StringName) -> BattleTeamState:
    if side_id == &"player":
        return player_team
    if side_id == &"opponent":
        return opponent_team
    return null

func _set_phase(new_phase: StringName) -> void:
    if phase == new_phase:
        state_changed.emit()
        return
    var previous: StringName = phase
    phase = new_phase
    phase_changed.emit(previous, phase)
    state_changed.emit()
