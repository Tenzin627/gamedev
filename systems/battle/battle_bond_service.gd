extends RefCounted
class_name BattleBondService

const BOND_SPELL_ID: StringName = &"spell.bond"

func get_attempt_info(model: BattleStateModel) -> Dictionary:
    var info: Dictionary = {
        "available": false,
        "display_name": "Creature",
        "chance": 0.0,
        "retry_cost": _get_retry_cost(),
        "currency": int(GameSession.get_value(&"currency", 0)),
        "standard_used": false,
        "paid_attempts": 0,
        "max_paid_retries": _get_max_paid_retries(),
        "paid_retry_available": false,
    }
    if model == null or model.encounter_kind != &"wild" or model.is_finished():
        return info
    var target: BattleCreatureState = model.get_opponent_active()
    if target == null or target.is_fainted():
        return info
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(target.species_id) as CreatureSpeciesDefinition
    if species == null:
        return info
    var health_ratio: float = 1.0
    if target.max_hp > 0:
        health_ratio = clampf(float(target.current_hp) / float(target.max_hp), 0.0, 1.0)
    info["available"] = true
    info["display_name"] = target.display_name
    info["chance"] = BondRules.calculate_bond_chance(species, health_ratio)
    info["standard_used"] = model.bond_standard_attempt_used
    info["paid_attempts"] = model.bond_paid_attempts
    info["paid_retry_available"] = model.bond_standard_attempt_used and model.bond_paid_attempts < int(info["max_paid_retries"])
    return info

func attempt(model: BattleStateModel, context: BattleEncounterContext, paid_retry: bool) -> Dictionary:
    var result: Dictionary = {
        "resolved": false,
        "success": false,
        "paid_retry": paid_retry,
        "message": "Bond attempt could not be made.",
        "instance_id": "",
    }
    if model == null or not model.can_accept_player_command() or model.encounter_kind != &"wild":
        result["message"] = "Bond can only be used during your turn in a wild encounter."
        return result
    var target: BattleCreatureState = model.get_opponent_active()
    if target == null or target.is_fainted():
        result["message"] = "There is no active wild creature to Bond."
        return result
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(target.species_id) as CreatureSpeciesDefinition
    if species == null:
        result["message"] = "Wild creature data is missing."
        return result

    if paid_retry:
        if not model.bond_standard_attempt_used:
            result["message"] = "Use the standard Bond attempt first."
            return result
        var max_paid_retries: int = _get_max_paid_retries()
        if model.bond_paid_attempts >= max_paid_retries:
            result["message"] = "Fate is spent for this encounter. No Bond retries remain."
            return result
        var cost: int = _get_retry_cost()
        var currency: int = int(GameSession.get_value(&"currency", 0))
        if currency < cost:
            result["message"] = "Not enough currency for another Bond attempt."
            return result
        GameSession.set_value(&"currency", currency - cost)
        model.bond_paid_attempts += 1
    else:
        if model.bond_standard_attempt_used:
            result["message"] = "The standard Bond attempt has already been used."
            return result
        model.bond_standard_attempt_used = true

    var health_ratio: float = 1.0
    if target.max_hp > 0:
        health_ratio = clampf(float(target.current_hp) / float(target.max_hp), 0.0, 1.0)
    var chance: float = BondRules.calculate_bond_chance(species, health_ratio)
    var attempt_number: int = 1 + model.bond_paid_attempts
    var seed_text: String = "%s|%s|bond|%d" % [model.battle_id, String(target.species_id), attempt_number]
    var success: bool = BondRules.roll_success(chance, seed_text)
    result["resolved"] = true
    result["success"] = success

    if success:
        var captured_zone_id: StringName = &"" if context == null else context.source_zone_id
        var collection: CreatureCollectionModel = CreatureCollectionModel.new()
        var creature: CreatureInstanceData = collection.add_captured_creature(target.species_id, captured_zone_id)
        model.bonded_instance_id = creature.instance_id
        model.event_log.append("Bond succeeded: %s" % target.display_name)
        model.finish_battle(&"player", &"bonded")
        var joined_party: bool = collection.is_in_party(creature.instance_id)
        result["instance_id"] = creature.instance_id
        QuestService.notify_event(QuestObjectiveDefinition.Kind.BOND_CREATURE, target.species_id, 1)
        result["message"] = "%s accepted the Bond.%s" % [target.display_name, " Joined your active party." if joined_party else " Added to your creature roster."]
    else:
        model.event_log.append("Bond failed: %s" % target.display_name)
        result["message"] = "The Bond did not settle. The wild creature responds."
        model.state_changed.emit()
    return result

func _get_retry_cost() -> int:
    var spell: BondSpellDefinition = ContentDB.get_definition(BOND_SPELL_ID) as BondSpellDefinition
    return BondRules.DEFAULT_RETRY_COST if spell == null else maxi(spell.retry_currency_cost, 0)

func _get_max_paid_retries() -> int:
    var spell: BondSpellDefinition = ContentDB.get_definition(BOND_SPELL_ID) as BondSpellDefinition
    return 1 if spell == null else maxi(spell.max_paid_retries_per_encounter, 0)
