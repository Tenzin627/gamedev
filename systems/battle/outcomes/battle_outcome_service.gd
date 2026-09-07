extends RefCounted
class_name BattleOutcomeService

const WILD_VICTORY_CURRENCY: int = 20
const WILD_VICTORY_GROWTH: int = 8

func commit(model: BattleStateModel) -> Dictionary:
    var result: Dictionary = {"committed": false, "currency_awarded": 0, "growth_awarded": 0, "message": ""}
    if model == null or not model.is_finished():
        result["message"] = "Battle is not finished."
        return result
    _commit_player_hp(model.player_team)
    if model.result_reason == &"bonded":
        result["message"] = "Bond formed. Party HP was preserved; no defeat rewards were granted."
    elif model.winner_side_id == &"player":
        var currency_reward: int = WILD_VICTORY_CURRENCY if model.encounter_kind == &"wild" or model.encounter_kind == &"debug" else 0
        var growth_reward: int = WILD_VICTORY_GROWTH
        if currency_reward > 0:
            var currency: int = int(GameSession.get_value(&"currency", 0))
            GameSession.set_value(&"currency", currency + currency_reward)
        _award_growth(model.player_team, growth_reward)
        _record_defeated_creatures(model.opponent_team)
        result["currency_awarded"] = currency_reward
        result["growth_awarded"] = growth_reward
        result["message"] = "Victory rewards: +%d currency, +%d growth to participating party." % [currency_reward, growth_reward]
    elif model.result_reason == &"escaped":
        result["message"] = "Escaped. Current party HP was preserved."
    else:
        var collection: CreatureCollectionModel = CreatureCollectionModel.new()
        collection.restore_party_health()
        result["message"] = "Defeat. Your active party recovered at the homestead."
    result["committed"] = true
    return result

func _record_defeated_creatures(team: BattleTeamState) -> void:
    if team == null:
        return
    for battle_creature: BattleCreatureState in team.creatures:
        if battle_creature != null and battle_creature.species_id != &"":
            QuestService.notify_event(QuestObjectiveDefinition.Kind.DEFEAT_CREATURE, battle_creature.species_id, 1, false)
    QuestService.evaluate_all_active()

func _commit_player_hp(team: BattleTeamState) -> void:
    if team == null:
        return
    var collection: CreatureCollectionModel = CreatureCollectionModel.new()
    for battle_creature: BattleCreatureState in team.creatures:
        if battle_creature == null or battle_creature.source_instance_id.is_empty():
            continue
        var creature: CreatureInstanceData = collection.get_creature(battle_creature.source_instance_id)
        if creature == null:
            continue
        creature.current_hp = clampi(battle_creature.current_hp, 0, battle_creature.max_hp)
        collection.save_creature(creature)

func _award_growth(team: BattleTeamState, amount: int) -> void:
    if team == null or amount <= 0:
        return
    var collection: CreatureCollectionModel = CreatureCollectionModel.new()
    for battle_creature: BattleCreatureState in team.creatures:
        if battle_creature == null or battle_creature.source_instance_id.is_empty():
            continue
        var creature: CreatureInstanceData = collection.get_creature(battle_creature.source_instance_id)
        if creature == null:
            continue
        creature.growth_xp += amount
        collection.save_creature(creature)
