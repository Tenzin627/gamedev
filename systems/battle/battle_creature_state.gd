extends RefCounted
class_name BattleCreatureState

var battle_actor_id: String = ""
var source_instance_id: String = ""
var species_id: StringName = &""
var display_name: String = "Unknown Creature"
var archetype: StringName = &"attack"
var life_stage: StringName = &"baby"
var current_hp: int = 1
var max_hp: int = 1
var base_power: int = 1
var active_trait_id: StringName = &""
var equipped_move_ids: Array[StringName] = []
var status_effect_ids: Array[StringName] = []
var status_turns_remaining: Dictionary = {}
var power_modifier: int = 0
var priority_modifier: int = 0
var damage_taken_multiplier: float = 1.0
var guarding: bool = false
var is_player_owned: bool = false

static func from_creature_instance(creature: CreatureInstanceData, side_id: StringName, slot_index: int) -> BattleCreatureState:
    var result: BattleCreatureState = BattleCreatureState.new()
    if creature == null:
        return result
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
    result.source_instance_id = creature.instance_id
    result.species_id = creature.species_id
    result.battle_actor_id = _build_actor_id(side_id, slot_index, creature.instance_id)
    result.is_player_owned = true
    result.active_trait_id = creature.active_trait_id
    result.equipped_move_ids = creature.equipped_move_ids.duplicate()
    result.life_stage = creature.life_stage
    result.current_hp = maxi(creature.current_hp, 0)
    if species != null:
        result.display_name = creature.nickname if not creature.nickname.is_empty() else species.display_name
        result.archetype = StringName(species.archetype.to_lower())
        result.max_hp = maxi(species.base_health, 1)
        result.base_power = maxi(species.base_power, 1)
        result.current_hp = clampi(result.current_hp, 0, result.max_hp)
    else:
        result.display_name = creature.nickname if not creature.nickname.is_empty() else String(creature.species_id)
        result.max_hp = maxi(result.current_hp, 1)
    return result

static func from_species(species_id_value: StringName, side_id: StringName, slot_index: int) -> BattleCreatureState:
    var result: BattleCreatureState = BattleCreatureState.new()
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(species_id_value) as CreatureSpeciesDefinition
    result.species_id = species_id_value
    result.battle_actor_id = _build_actor_id(side_id, slot_index, "wild")
    result.is_player_owned = false
    if species == null:
        result.display_name = String(species_id_value)
        return result
    result.display_name = species.display_name
    result.archetype = StringName(species.archetype.to_lower())
    result.life_stage = StringName(species.life_stage.to_lower())
    result.max_hp = maxi(species.base_health, 1)
    result.current_hp = result.max_hp
    result.base_power = maxi(species.base_power, 1)
    result.equipped_move_ids = CreatureInstanceData.build_starting_moves(species)
    var candidates: Array[StringName] = CreatureInstanceData.build_trait_candidates(species)
    if not candidates.is_empty():
        result.active_trait_id = candidates[0]
    return result

func is_fainted() -> bool:
    return current_hp <= 0

func get_hp_ratio() -> float:
    if max_hp <= 0:
        return 0.0
    return clampf(float(current_hp) / float(max_hp), 0.0, 1.0)

func duplicate_state() -> BattleCreatureState:
    var result: BattleCreatureState = BattleCreatureState.new()
    result.battle_actor_id = battle_actor_id
    result.source_instance_id = source_instance_id
    result.species_id = species_id
    result.display_name = display_name
    result.archetype = archetype
    result.life_stage = life_stage
    result.current_hp = current_hp
    result.max_hp = max_hp
    result.base_power = base_power
    result.active_trait_id = active_trait_id
    result.equipped_move_ids = equipped_move_ids.duplicate()
    result.status_effect_ids = status_effect_ids.duplicate()
    result.status_turns_remaining = status_turns_remaining.duplicate(true)
    result.power_modifier = power_modifier
    result.priority_modifier = priority_modifier
    result.damage_taken_multiplier = damage_taken_multiplier
    result.guarding = guarding
    result.is_player_owned = is_player_owned
    return result

func to_debug_dict() -> Dictionary:
    var moves: Array[String] = []
    for move_id: StringName in equipped_move_ids:
        moves.append(String(move_id))
    return {
        "battle_actor_id": battle_actor_id,
        "source_instance_id": source_instance_id,
        "species_id": String(species_id),
        "display_name": display_name,
        "archetype": String(archetype),
        "life_stage": String(life_stage),
        "current_hp": current_hp,
        "max_hp": max_hp,
        "base_power": base_power,
        "active_trait_id": String(active_trait_id),
        "equipped_move_ids": moves,
        "status_effect_ids": status_effect_ids.duplicate(),
        "status_turns_remaining": status_turns_remaining.duplicate(true),
        "power_modifier": power_modifier,
        "priority_modifier": priority_modifier,
        "damage_taken_multiplier": damage_taken_multiplier,
        "guarding": guarding,
        "is_player_owned": is_player_owned,
    }

static func _build_actor_id(side_id: StringName, slot_index: int, identity: String) -> String:
    return "battle_actor.%s.%d.%s" % [String(side_id), slot_index, identity]
