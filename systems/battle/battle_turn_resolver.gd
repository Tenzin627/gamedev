extends RefCounted
class_name BattleTurnResolver

signal turn_resolved(summary: String)

var effect_pipeline: BattleEffectPipeline = BattleEffectPipeline.new()
var player_inventory: InventoryComponent
var player_hotbar: HotbarComponent

func set_player_inventory(inventory: InventoryComponent, hotbar: HotbarComponent = null) -> void:
    player_inventory = inventory
    player_hotbar = hotbar

func begin_battle_effects(model: BattleStateModel) -> Array[String]:
    var messages: Array[String] = []
    if model == null:
        return messages
    _append_messages(model, messages, effect_pipeline.trigger_trait(model, model.get_player_active(), &"battle_start", model.get_opponent_active()))
    _append_messages(model, messages, effect_pipeline.trigger_trait(model, model.get_opponent_active(), &"battle_start", model.get_player_active()))
    model.state_changed.emit()
    return messages

func resolve_round(model: BattleStateModel, player_action: BattleAction, opponent_action: BattleAction) -> Array[String]:
    var messages: Array[String] = []
    if model == null or model.is_finished():
        return messages
    if player_action == null:
        messages.append("Player action is missing.")
        return messages

    model.set_phase_for_resolution(BattleStateModel.PHASE_RESOLVING)
    _append_messages(model, messages, effect_pipeline.trigger_trait(model, model.get_player_active(), &"turn_start", model.get_opponent_active()))
    _append_messages(model, messages, effect_pipeline.trigger_trait(model, model.get_opponent_active(), &"turn_start", model.get_player_active()))
    _resolve_faints(model, messages)
    if model.is_finished():
        return messages

    var ordered_actions: Array[BattleAction] = _order_actions(model, player_action, opponent_action)
    var player_switched: bool = false
    var opponent_switched: bool = false

    for action: BattleAction in ordered_actions:
        if action == null or model.is_finished():
            continue
        if not _actor_can_act(model, action):
            continue
        var result_messages: Array[String] = _resolve_action(model, action)
        _append_messages(model, messages, result_messages)
        if action.action_type == BattleAction.TYPE_SWITCH:
            if action.side_id == &"player":
                player_switched = true
            elif action.side_id == &"opponent":
                opponent_switched = true
        _resolve_faints(model, messages)

    if not model.is_finished():
        _tick_active_statuses(model, messages)
        _resolve_faints(model, messages)

    if not model.is_finished():
        if not player_switched and model.player_team != null:
            model.player_team.tick_switch_cooldown()
        if not opponent_switched and model.opponent_team != null:
            model.opponent_team.tick_switch_cooldown()
        model.round_number += 1
        model.set_phase_for_resolution(BattleStateModel.PHASE_AWAITING_PLAYER_COMMAND)

    model.state_changed.emit()
    var summary: String = _join_messages(messages, " ")
    turn_resolved.emit(summary)
    return messages

func _order_actions(model: BattleStateModel, player_action: BattleAction, opponent_action: BattleAction) -> Array[BattleAction]:
    var actions: Array[BattleAction] = []
    if opponent_action == null:
        actions.append(player_action)
        return actions
    var player_priority: int = _get_action_priority(model, player_action)
    var opponent_priority: int = _get_action_priority(model, opponent_action)
    if opponent_priority > player_priority:
        actions.append(opponent_action)
        actions.append(player_action)
    else:
        actions.append(player_action)
        actions.append(opponent_action)
    return actions

func _get_action_priority(model: BattleStateModel, action: BattleAction) -> int:
    if action == null:
        return -999999
    if action.action_type == BattleAction.TYPE_ESCAPE:
        return 10000
    if action.action_type == BattleAction.TYPE_ITEM:
        return 7500
    if action.action_type == BattleAction.TYPE_BOND:
        return 8000
    if action.action_type == BattleAction.TYPE_SWITCH:
        return 5000
    if action.action_type == BattleAction.TYPE_MOVE:
        var move_definition: MoveDefinition = ContentDB.get_definition(action.move_id) as MoveDefinition
        var base_priority: int = 0 if move_definition == null else move_definition.priority
        var team: BattleTeamState = _get_team(model, action.side_id)
        var active: BattleCreatureState = null if team == null else team.get_active_creature()
        if active != null:
            base_priority += active.priority_modifier + effect_pipeline.get_status_priority_modifier(active)
        return base_priority
    return -1000

func _actor_can_act(model: BattleStateModel, action: BattleAction) -> bool:
    if action.action_type == BattleAction.TYPE_SWITCH or action.action_type == BattleAction.TYPE_ESCAPE or action.action_type == BattleAction.TYPE_ITEM or action.action_type == BattleAction.TYPE_BOND:
        return true
    var team: BattleTeamState = _get_team(model, action.side_id)
    if team == null:
        return false
    var active: BattleCreatureState = team.get_active_creature()
    if active == null or active.is_fainted():
        return false
    return active.battle_actor_id == action.actor_id

func _resolve_action(model: BattleStateModel, action: BattleAction) -> Array[String]:
    if action.action_type == BattleAction.TYPE_MOVE:
        return _resolve_move(model, action)
    if action.action_type == BattleAction.TYPE_SWITCH:
        return _one(_resolve_switch(model, action))
    if action.action_type == BattleAction.TYPE_ITEM:
        return _resolve_item(model, action)
    if action.action_type == BattleAction.TYPE_ESCAPE:
        return _one(_resolve_escape(model, action))
    if action.action_type == BattleAction.TYPE_BOND:
        return _one("The Bond attempt took the party action.")
    return _one("Unsupported battle action.")

func _resolve_move(model: BattleStateModel, action: BattleAction) -> Array[String]:
    var messages: Array[String] = []
    var attacker_team: BattleTeamState = _get_team(model, action.side_id)
    var defender_team: BattleTeamState = _get_other_team(model, action.side_id)
    if attacker_team == null or defender_team == null:
        return _one("Move failed because a battle team is missing.")
    var attacker: BattleCreatureState = attacker_team.get_active_creature()
    var defender: BattleCreatureState = defender_team.get_active_creature()
    if attacker == null or defender == null:
        return _one("Move failed because an active creature is missing.")
    var move_definition: MoveDefinition = ContentDB.get_definition(action.move_id) as MoveDefinition
    if move_definition == null or not attacker.equipped_move_ids.has(action.move_id):
        return _one("%s could not use that move." % attacker.display_name)

    if move_definition.role == "Damage":
        var damage: int = _calculate_damage(model, attacker, defender, move_definition)
        defender.current_hp = maxi(defender.current_hp - damage, 0)
        var relation_text: String = _archetype_relation_text(attacker.archetype, defender.archetype)
        var guard_text: String = ""
        if defender.guarding:
            guard_text = " Guarding softened the hit."
            defender.guarding = false
        messages.append("%s used %s for %d damage.%s%s" % [attacker.display_name, move_definition.display_name, damage, relation_text, guard_text])
        if not move_definition.effect_ids.is_empty():
            messages.append_array(effect_pipeline.apply_effect_ids(model, attacker, defender, move_definition.effect_ids, attacker))
        messages.append_array(effect_pipeline.trigger_trait(model, attacker, &"after_attack", defender))
        if not defender.is_fainted():
            messages.append_array(effect_pipeline.trigger_trait(model, defender, &"after_damaged", attacker))
        return messages

    messages.append("%s used %s." % [attacker.display_name, move_definition.display_name])
    if not move_definition.effect_ids.is_empty():
        messages.append_array(effect_pipeline.apply_effect_ids(model, attacker, defender, move_definition.effect_ids, attacker))
    elif move_definition.role == "Defense" or move_definition.tags.has(&"guard"):
        attacker.guarding = true
        messages.append("%s braced for the next hit." % attacker.display_name)
    return messages

func _resolve_item(model: BattleStateModel, action: BattleAction) -> Array[String]:
    if action.side_id != &"player":
        return _one("Only the player can use inventory items in battle.")
    if player_inventory == null:
        return _one("No battle inventory is bound.")
    var item_definition: BattleConsumableDefinition = ContentDB.get_definition(action.item_id) as BattleConsumableDefinition
    if item_definition == null or not item_definition.usable_in_battle:
        return _one("That item cannot be used in battle.")
    if not CarriedInventoryService.has_item(player_inventory, action.item_id, 1, player_hotbar):
        return _one("That item is no longer in the inventory.")
    var target: BattleCreatureState = _get_item_target(model.player_team, action.target_index, item_definition)
    if target == null:
        return _one("No valid creature can receive that item.")
    var leftover: int = CarriedInventoryService.remove_item(player_inventory, action.item_id, 1, player_hotbar)
    if leftover != 0:
        return _one("The item could not be consumed.")
    var messages: Array[String] = ["Used %s on %s." % [item_definition.display_name, target.display_name]]
    messages.append_array(effect_pipeline.apply_effect_ids(model, model.get_player_active(), model.get_opponent_active(), item_definition.battle_effect_ids, target))
    return messages

func _get_item_target(team: BattleTeamState, target_index: int, item_definition: BattleConsumableDefinition) -> BattleCreatureState:
    if team == null:
        return null
    if item_definition.target_mode == "ActiveAlly":
        return team.get_active_creature()
    if target_index < 0 or target_index >= team.creatures.size():
        return null
    var target: BattleCreatureState = team.creatures[target_index]
    if target == null or target.is_fainted():
        return null
    return target

func _resolve_switch(model: BattleStateModel, action: BattleAction) -> String:
    var team: BattleTeamState = _get_team(model, action.side_id)
    if team == null:
        return "Switch failed because the team is missing."
    if action.switch_index == team.active_index:
        return "%s is already active." % team.display_name
    if team.switch_cooldown_turns_remaining > 0:
        return "%s cannot switch yet (%d turn cooldown)." % [team.display_name, team.switch_cooldown_turns_remaining]
    var previous: BattleCreatureState = team.get_active_creature()
    if not team.set_active_index(action.switch_index):
        return "%s could not switch to that slot." % team.display_name
    var ruleset: BattleRulesetDefinition = model.get_ruleset()
    team.switch_cooldown_turns_remaining = 1 if ruleset == null else maxi(ruleset.switch_cooldown_turns, 0)
    var current: BattleCreatureState = team.get_active_creature()
    var previous_name: String = "Creature" if previous == null else previous.display_name
    var current_name: String = "Creature" if current == null else current.display_name
    return "%s switched %s → %s." % [team.display_name, previous_name, current_name]

func _resolve_escape(model: BattleStateModel, action: BattleAction) -> String:
    if action.side_id != &"player":
        return "Only the player side can escape."
    var ruleset: BattleRulesetDefinition = model.get_ruleset()
    if ruleset != null and not ruleset.allow_escape:
        return "Escape is disabled for this battle."
    if model.encounter_kind != &"wild" and model.encounter_kind != &"debug":
        return "You cannot escape this encounter."
    model.finish_battle(&"", &"escaped")
    return "The party escaped safely."

func _calculate_damage(model: BattleStateModel, attacker: BattleCreatureState, defender: BattleCreatureState, move_definition: MoveDefinition) -> int:
    var ruleset: BattleRulesetDefinition = model.get_ruleset()
    var total_power: int = maxi(attacker.base_power + attacker.power_modifier + effect_pipeline.get_status_power_modifier(attacker) + move_definition.power, 1)
    var base_damage: float = float(total_power)
    var multiplier: float = defender.damage_taken_multiplier * effect_pipeline.get_status_damage_taken_multiplier(defender)
    var relation: int = _get_archetype_relation(attacker.archetype, defender.archetype)
    if ruleset != null:
        if relation > 0:
            multiplier *= ruleset.archetype_advantage_multiplier
        elif relation < 0:
            multiplier *= ruleset.archetype_disadvantage_multiplier
        if defender.guarding:
            multiplier *= ruleset.guard_damage_multiplier
    elif defender.guarding:
        multiplier *= 0.65
    return maxi(int(round(base_damage * multiplier)), 1)

func _tick_active_statuses(model: BattleStateModel, messages: Array[String]) -> void:
    _append_messages(model, messages, effect_pipeline.tick_statuses(model.get_player_active()))
    _append_messages(model, messages, effect_pipeline.tick_statuses(model.get_opponent_active()))

func _resolve_faints(model: BattleStateModel, messages: Array[String]) -> void:
    _resolve_team_faint(model, model.player_team, &"player", messages)
    if model.is_finished():
        return
    _resolve_team_faint(model, model.opponent_team, &"opponent", messages)

func _resolve_team_faint(model: BattleStateModel, team: BattleTeamState, side_id: StringName, messages: Array[String]) -> void:
    if team == null:
        return
    var active: BattleCreatureState = team.get_active_creature()
    if active == null or not active.is_fainted():
        return
    var faint_message: String = "%s fainted." % active.display_name
    if messages.is_empty() or messages[messages.size() - 1] != faint_message:
        messages.append(faint_message)
        model.event_log.append(faint_message)
    if team.is_defeated():
        if side_id == &"player":
            model.finish_battle(&"opponent", &"all_player_creatures_fainted")
        else:
            model.finish_battle(&"player", &"all_opponent_creatures_fainted")
        return
    var available: Array[int] = team.get_available_indices()
    if not available.is_empty():
        team.active_index = available[0]
        var replacement: BattleCreatureState = team.get_active_creature()
        if replacement != null:
            var switch_message: String = "%s automatically sent out %s." % [team.display_name, replacement.display_name]
            messages.append(switch_message)
            model.event_log.append(switch_message)

func _get_archetype_relation(attacker_archetype: StringName, defender_archetype: StringName) -> int:
    if attacker_archetype == defender_archetype:
        return 0
    if attacker_archetype == &"attack" and defender_archetype == &"speed":
        return 1
    if attacker_archetype == &"speed" and defender_archetype == &"guard":
        return 1
    if attacker_archetype == &"guard" and defender_archetype == &"attack":
        return 1
    if defender_archetype == &"attack" and attacker_archetype == &"speed":
        return -1
    if defender_archetype == &"speed" and attacker_archetype == &"guard":
        return -1
    if defender_archetype == &"guard" and attacker_archetype == &"attack":
        return -1
    return 0

func _archetype_relation_text(attacker_archetype: StringName, defender_archetype: StringName) -> String:
    var relation: int = _get_archetype_relation(attacker_archetype, defender_archetype)
    if relation > 0:
        return " Archetype advantage!"
    if relation < 0:
        return " Archetype resisted."
    return ""

func _get_team(model: BattleStateModel, side_id: StringName) -> BattleTeamState:
    if side_id == &"player":
        return model.player_team
    if side_id == &"opponent":
        return model.opponent_team
    return null

func _get_other_team(model: BattleStateModel, side_id: StringName) -> BattleTeamState:
    if side_id == &"player":
        return model.opponent_team
    if side_id == &"opponent":
        return model.player_team
    return null

func _append_messages(model: BattleStateModel, target: Array[String], additions: Array[String]) -> void:
    for message: String in additions:
        if message.is_empty():
            continue
        target.append(message)
        model.event_log.append(message)

func _one(message: String) -> Array[String]:
    var result: Array[String] = []
    result.append(message)
    return result

func _join_messages(messages: Array[String], separator: String) -> String:
    var result: String = ""
    for index: int in range(messages.size()):
        if index > 0:
            result += separator
        result += messages[index]
    return result
