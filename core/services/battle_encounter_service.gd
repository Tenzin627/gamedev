extends Node

signal encounter_prepared(encounter_id: String)
signal encounter_cleared(encounter_id: String)

var _active_context: BattleEncounterContext = null

func has_active_encounter() -> bool:
    return _active_context != null and _active_context.is_valid()

func get_active_context() -> BattleEncounterContext:
    return _active_context

func prepare_wild_encounter(actor: WildCreatureActor) -> BattleEncounterContext:
    if actor == null or not is_instance_valid(actor):
        return null
    var context: BattleEncounterContext = BattleEncounterContext.new()
    context.encounter_id = "encounter.%d.%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
    context.encounter_kind = &"wild"
    context.source_region_id = SceneRouter.current_region_id
    context.source_zone_id = SceneRouter.current_zone_id
    context.source_scene_path = SceneRouter.current_scene_path
    context.source_spawn_token = actor.spawn_token
    context.source_habitat_instance_id = actor.habitat_instance_id
    context.opponent_species_ids.append(actor.species_id)
    context.environment_id = SceneRouter.current_region_id
    _active_context = context
    encounter_prepared.emit(context.encounter_id)
    return context

func clear_active_encounter() -> void:
    if _active_context == null:
        return
    var encounter_id: String = _active_context.encounter_id
    _active_context = null
    encounter_cleared.emit(encounter_id)
