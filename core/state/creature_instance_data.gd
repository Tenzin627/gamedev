extends RefCounted
class_name CreatureInstanceData

const MAX_TRAIT_CANDIDATES: int = 2
const MAX_EQUIPPED_MOVES: int = 4

var instance_id: String = ""
var species_id: StringName = &""
var life_stage: StringName = &"baby"
var trait_candidate_ids: Array[StringName] = []
var active_trait_id: StringName = &""
var equipped_move_ids: Array[StringName] = []
var learned_move_ids: Array[StringName] = []
var growth_xp: int = 0
var evolution_tendencies: Dictionary = {"attack": 0, "speed": 0, "guard": 0}
var current_hp: int = 1
var nickname: String = ""
var bond_level: int = 0
var captured_at_zone_id: StringName = &""

static func create(species: StringName, zone_id: StringName = &"") -> CreatureInstanceData:
    var result: CreatureInstanceData = CreatureInstanceData.new()
    result.instance_id = _make_instance_id()
    result.species_id = species
    result.captured_at_zone_id = zone_id

    var definition: CreatureSpeciesDefinition = ContentDB.get_definition(species) as CreatureSpeciesDefinition
    if definition == null:
        return result

    result.life_stage = StringName(definition.life_stage.to_lower())
    result.current_hp = definition.base_health
    result.trait_candidate_ids = build_trait_candidates(definition)
    if not result.trait_candidate_ids.is_empty():
        result.active_trait_id = result.trait_candidate_ids[0]
    result.equipped_move_ids = build_starting_moves(definition)
    result.learned_move_ids = result.equipped_move_ids.duplicate()
    return result

func to_dict() -> Dictionary:
    var candidate_strings: Array[String] = []
    for trait_id: StringName in trait_candidate_ids:
        candidate_strings.append(String(trait_id))

    var move_strings: Array[String] = []
    for move_id: StringName in equipped_move_ids:
        move_strings.append(String(move_id))

    var learned_move_strings: Array[String] = []
    for move_id: StringName in learned_move_ids:
        learned_move_strings.append(String(move_id))

    return {
        "instance_id": instance_id,
        "species_id": String(species_id),
        "life_stage": String(life_stage),
        "trait_candidate_ids": candidate_strings,
        "active_trait_id": String(active_trait_id),
        "equipped_move_ids": move_strings,
        "learned_move_ids": learned_move_strings,
        "growth_xp": growth_xp,
        "evolution_tendencies": _normalized_tendencies(evolution_tendencies),
        "current_hp": current_hp,
        "nickname": nickname,
        "bond_level": bond_level,
        "captured_at_zone_id": String(captured_at_zone_id),
    }

static func from_dict(data: Dictionary) -> CreatureInstanceData:
    var result: CreatureInstanceData = CreatureInstanceData.new()
    result.instance_id = str(data.get("instance_id", ""))
    result.species_id = StringName(str(data.get("species_id", "")))

    var species_definition: CreatureSpeciesDefinition = ContentDB.get_definition(result.species_id) as CreatureSpeciesDefinition
    var fallback_stage: String = "baby"
    if species_definition != null:
        fallback_stage = species_definition.life_stage.to_lower()
    result.life_stage = StringName(str(data.get("life_stage", fallback_stage)).to_lower())

    var candidates_variant: Variant = data.get("trait_candidate_ids", [])
    if candidates_variant is Array:
        for trait_variant: Variant in Array(candidates_variant):
            var trait_id: StringName = StringName(str(trait_variant))
            if trait_id == &"" or result.trait_candidate_ids.has(trait_id):
                continue
            result.trait_candidate_ids.append(trait_id)
            if result.trait_candidate_ids.size() >= MAX_TRAIT_CANDIDATES:
                break

    result.active_trait_id = StringName(str(data.get("active_trait_id", "")))
    if species_definition != null:
        result.reconcile_traits_for_species(species_definition, true)
    elif not result.trait_candidate_ids.is_empty() and not result.trait_candidate_ids.has(result.active_trait_id):
        result.active_trait_id = result.trait_candidate_ids[0]

    var equipped_variant: Variant = data.get("equipped_move_ids", [])
    if equipped_variant is Array:
        for move_variant: Variant in Array(equipped_variant):
            var equipped_id: StringName = StringName(str(move_variant))
            if equipped_id == &"" or result.equipped_move_ids.has(equipped_id):
                continue
            result.equipped_move_ids.append(equipped_id)
            if result.equipped_move_ids.size() >= MAX_EQUIPPED_MOVES:
                break

    var learned_variant: Variant = data.get("learned_move_ids", [])
    if learned_variant is Array:
        for move_variant: Variant in Array(learned_variant):
            var learned_id: StringName = StringName(str(move_variant))
            if learned_id != &"" and not result.learned_move_ids.has(learned_id):
                result.learned_move_ids.append(learned_id)
    if result.learned_move_ids.is_empty():
        result.learned_move_ids = result.equipped_move_ids.duplicate()

    var normalized_equipped: Array[StringName] = []
    for equipped_id: StringName in result.equipped_move_ids:
        if result.learned_move_ids.has(equipped_id) and not normalized_equipped.has(equipped_id):
            normalized_equipped.append(equipped_id)
        if normalized_equipped.size() >= MAX_EQUIPPED_MOVES:
            break
    result.equipped_move_ids = normalized_equipped

    result.growth_xp = maxi(int(data.get("growth_xp", 0)), 0)
    var tendencies_variant: Variant = data.get("evolution_tendencies", {})
    if tendencies_variant is Dictionary:
        result.evolution_tendencies = _normalized_tendencies(Dictionary(tendencies_variant))
    else:
        result.evolution_tendencies = _normalized_tendencies({})

    var loaded_hp: int = maxi(int(data.get("current_hp", 1)), 0)
    if species_definition != null:
        result.current_hp = clampi(loaded_hp, 0, species_definition.base_health)
    else:
        result.current_hp = loaded_hp

    result.nickname = str(data.get("nickname", ""))
    result.bond_level = maxi(int(data.get("bond_level", 0)), 0)
    result.captured_at_zone_id = StringName(str(data.get("captured_at_zone_id", "")))
    return result

func reconcile_traits_for_species(definition: CreatureSpeciesDefinition, preserve_compatible: bool = true) -> void:
    if definition == null:
        return

    var reconciled: Array[StringName] = []
    if preserve_compatible:
        for trait_id: StringName in trait_candidate_ids:
            if _is_trait_compatible(trait_id, definition) and not reconciled.has(trait_id):
                reconciled.append(trait_id)
            if reconciled.size() >= MAX_TRAIT_CANDIDATES:
                break

    for trait_id: StringName in build_trait_candidates(definition):
        if not reconciled.has(trait_id):
            reconciled.append(trait_id)
        if reconciled.size() >= MAX_TRAIT_CANDIDATES:
            break

    trait_candidate_ids = reconciled
    if trait_candidate_ids.is_empty():
        active_trait_id = &""
    elif not trait_candidate_ids.has(active_trait_id):
        active_trait_id = trait_candidate_ids[0]

static func build_trait_candidates(definition: CreatureSpeciesDefinition) -> Array[StringName]:
    var result: Array[StringName] = []
    if definition == null:
        return result
    for trait_id: StringName in definition.trait_pool_ids:
        if not _is_trait_compatible(trait_id, definition) or result.has(trait_id):
            continue
        result.append(trait_id)
        if result.size() >= MAX_TRAIT_CANDIDATES:
            break
    return result

static func build_starting_moves(definition: CreatureSpeciesDefinition) -> Array[StringName]:
    var result: Array[StringName] = []
    if definition == null:
        return result
    for move_id: StringName in definition.move_pool_ids:
        if ContentDB.get_definition(move_id) is MoveDefinition and not result.has(move_id):
            result.append(move_id)
        if result.size() >= MAX_EQUIPPED_MOVES:
            break
    return result

static func _is_trait_compatible(trait_id: StringName, definition: CreatureSpeciesDefinition) -> bool:
    if trait_id == &"" or definition == null or not definition.trait_pool_ids.has(trait_id):
        return false
    var trait_definition: TraitDefinition = ContentDB.get_definition(trait_id) as TraitDefinition
    return trait_definition != null and trait_definition.archetype == definition.archetype

static func _normalized_tendencies(source: Dictionary) -> Dictionary:
    return {
        "attack": maxi(int(source.get("attack", 0)), 0),
        "speed": maxi(int(source.get("speed", 0)), 0),
        "guard": maxi(int(source.get("guard", 0)), 0),
    }

static func _make_instance_id() -> String:
    var unix_seconds: int = int(Time.get_unix_time_from_system())
    var ticks_usec: int = Time.get_ticks_usec()
    var random_part: int = randi()
    return "creature_instance.%d.%d.%d" % [unix_seconds, ticks_usec, random_part]
