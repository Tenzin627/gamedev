extends RefCounted
class_name BattleStateFactory

static func create_from_player_party(opponent_species_ids: Array[StringName], encounter_kind: StringName = &"wild", environment_id: StringName = &"") -> BattleStateModel:
    var model: BattleStateModel = BattleStateModel.new()
    model.battle_id = _make_battle_id()
    model.encounter_kind = encounter_kind
    model.environment_id = environment_id
    model.player_team = BattleTeamState.new()
    model.player_team.side_id = &"player"
    model.player_team.display_name = "Player"
    model.opponent_team = BattleTeamState.new()
    model.opponent_team.side_id = &"opponent"
    model.opponent_team.display_name = "Wild Creatures" if encounter_kind == &"wild" else "Opponent"

    var collection: CreatureCollectionModel = CreatureCollectionModel.new()
    var party: Array[CreatureInstanceData] = collection.get_party()
    for index: int in range(party.size()):
        if index >= BattleTeamState.MAX_TEAM_SIZE:
            break
        model.player_team.add_creature(BattleCreatureState.from_creature_instance(party[index], &"player", index))

    for index: int in range(opponent_species_ids.size()):
        if index >= BattleTeamState.MAX_TEAM_SIZE:
            break
        var species_id: StringName = opponent_species_ids[index]
        if ContentDB.get_definition(species_id) is CreatureSpeciesDefinition:
            model.opponent_team.add_creature(BattleCreatureState.from_species(species_id, &"opponent", index))
    return model

static func create_debug_model() -> BattleStateModel:
    var model: BattleStateModel = BattleStateModel.new()
    model.battle_id = _make_battle_id()
    model.encounter_kind = &"debug"
    var profile: GameProfileDefinition = ContentDB.get_active_profile()
    var chain: StoryChainDefinition = null
    if profile != null:
        chain = ContentDB.get_definition(profile.primary_story_chain_id) as StoryChainDefinition
    model.environment_id = chain.region_id if chain != null else &""
    model.player_team = BattleTeamState.new()
    model.player_team.side_id = &"player"
    model.player_team.display_name = "Player Party"
    model.opponent_team = BattleTeamState.new()
    model.opponent_team.side_id = &"opponent"
    model.opponent_team.display_name = "Debug Opponents"

    var species_ids: Array[StringName] = []
    for content_id: StringName in ContentDB.get_all_ids():
        if ContentDB.get_definition(content_id) is CreatureSpeciesDefinition:
            species_ids.append(content_id)
    species_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
    if species_ids.is_empty():
        return model

    for index: int in range(mini(3, species_ids.size())):
        var state: BattleCreatureState = BattleCreatureState.from_species(species_ids[index], &"player", index)
        state.is_player_owned = true
        state.source_instance_id = "debug.player.%d" % index
        model.player_team.add_creature(state)

    for index: int in range(mini(2, species_ids.size())):
        var opponent_index: int = species_ids.size() - 1 - index
        model.opponent_team.add_creature(BattleCreatureState.from_species(species_ids[opponent_index], &"opponent", index))
    return model

static func _make_battle_id() -> String:
    return "battle.%d.%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
