extends RefCounted
class_name CreatureDetailPresentationModel

static func get_creature_name(creature: CreatureInstanceData) -> String:
    if creature == null:
        return "Unknown Creature"
    if not creature.nickname.is_empty():
        return creature.nickname
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
    return String(creature.species_id) if species == null else species.display_name

static func get_species_name(creature: CreatureInstanceData) -> String:
    if creature == null:
        return "Unknown"
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
    return String(creature.species_id) if species == null else species.display_name

static func get_trait_name(trait_id: StringName) -> String:
    if trait_id == &"":
        return "None"
    var trait_definition: TraitDefinition = ContentDB.get_definition(trait_id) as TraitDefinition
    return String(trait_id) if trait_definition == null else trait_definition.display_name

static func get_trait_description(trait_id: StringName) -> String:
    var trait_definition: TraitDefinition = ContentDB.get_definition(trait_id) as TraitDefinition
    if trait_definition == null:
        return "Trait definition unavailable."
    var effect_text: String = ", ".join(_string_names_to_strings(trait_definition.effect_ids)) if not trait_definition.effect_ids.is_empty() else "No effects configured yet"
    return "%s archetype | Trigger: %s | %s" % [trait_definition.archetype, String(trait_definition.trigger), effect_text]

static func get_move_name(move_id: StringName) -> String:
    if move_id == &"":
        return "Empty"
    var move_definition: MoveDefinition = ContentDB.get_definition(move_id) as MoveDefinition
    return String(move_id) if move_definition == null else move_definition.display_name

static func get_move_description(move_id: StringName) -> String:
    var move_definition: MoveDefinition = ContentDB.get_definition(move_id) as MoveDefinition
    if move_definition == null:
        return "Move definition unavailable."
    var effect_text: String = ", ".join(_string_names_to_strings(move_definition.effect_ids)) if not move_definition.effect_ids.is_empty() else "No effects configured yet"
    return "%s | Power %d | Priority %d | %s" % [move_definition.role, move_definition.power, move_definition.priority, effect_text]

static func get_summary(creature: CreatureInstanceData) -> String:
    if creature == null:
        return ""
    var tendencies: Dictionary = creature.evolution_tendencies
    return "%s • %s | Growth %d | Bond %d | A:%d S:%d G:%d" % [
        get_species_name(creature),
        String(creature.life_stage).capitalize(),
        creature.growth_xp,
        creature.bond_level,
        int(tendencies.get("attack", 0)),
        int(tendencies.get("speed", 0)),
        int(tendencies.get("guard", 0)),
    ]

static func _string_names_to_strings(values: Array[StringName]) -> Array[String]:
    var result: Array[String] = []
    for value: StringName in values:
        result.append(String(value))
    return result
