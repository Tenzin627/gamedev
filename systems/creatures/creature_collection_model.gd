extends RefCounted
class_name CreatureCollectionModel

const PARTY_SIZE: int = 3
const EQUIPPED_MOVE_LIMIT: int = 4

func add_captured_creature(species_id: StringName, captured_zone_id: StringName = &"") -> CreatureInstanceData:
    var creature: CreatureInstanceData = CreatureInstanceData.create(species_id, captured_zone_id)
    GameSession.creature_instances.append(creature.to_dict())
    var joined_party: bool = false
    if GameSession.party_instance_ids.size() < PARTY_SIZE:
        GameSession.party_instance_ids.append(creature.instance_id)
        joined_party = true
    GameSession.notify_creature_collection_changed()
    CollectionEncyclopediaService.mark_creature_owned(species_id)
    ProgressionAwardService.award_taming(10)
    if joined_party:
        GameSession.notify_party_changed()
    return creature

func get_all_creatures() -> Array[CreatureInstanceData]:
    var result: Array[CreatureInstanceData] = []
    for entry_variant: Variant in GameSession.creature_instances:
        if entry_variant is Dictionary:
            result.append(CreatureInstanceData.from_dict(Dictionary(entry_variant)))
    return result

func get_creature(instance_id: String) -> CreatureInstanceData:
    for entry_variant: Variant in GameSession.creature_instances:
        if not entry_variant is Dictionary:
            continue
        var entry: Dictionary = Dictionary(entry_variant)
        if str(entry.get("instance_id", "")) == instance_id:
            return CreatureInstanceData.from_dict(entry)
    return null

func save_creature(creature: CreatureInstanceData) -> bool:
    if creature == null or creature.instance_id.is_empty():
        return false
    for index: int in range(GameSession.creature_instances.size()):
        var entry: Dictionary = GameSession.creature_instances[index]
        if str(entry.get("instance_id", "")) != creature.instance_id:
            continue
        GameSession.creature_instances[index] = creature.to_dict()
        GameSession.notify_creature_collection_changed()
        return true
    return false

func feed_creature(instance_id: String, food_id: StringName, inventory: InventoryComponent) -> Dictionary:
    var result: Dictionary = {
        "success": false,
        "message": "Feeding failed.",
        "growth_added": 0,
        "bond_added": 0,
        "new_moves": [],
    }
    if inventory == null:
        result["message"] = "No inventory is available."
        return result
    var food: CreatureFoodDefinition = ContentDB.get_definition(food_id) as CreatureFoodDefinition
    if food == null:
        result["message"] = "That item is not creature food."
        return result
    if not CarriedInventoryService.has_item(inventory, food_id, 1):
        result["message"] = "No %s remains in inventory." % food.display_name
        return result
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null:
        result["message"] = "Creature instance no longer exists."
        return result
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
    if species == null:
        result["message"] = "Creature species definition is missing."
        return result

    var remaining: int = CarriedInventoryService.remove_item(inventory, food_id, 1)
    if remaining > 0:
        result["message"] = "Could not consume the food item."
        return result

    creature.growth_xp += maxi(food.growth_xp, 0)
    creature.bond_level += maxi(food.bond_growth, 0)
    _add_tendency(creature, "attack", food.attack_tendency)
    _add_tendency(creature, "speed", food.speed_tendency)
    _add_tendency(creature, "guard", food.guard_tendency)

    var new_moves: Array[StringName] = []
    for move_id: StringName in food.unlock_move_ids:
        if move_id == &"" or not species.move_pool_ids.has(move_id) or not ContentDB.has_definition(move_id):
            continue
        if creature.learned_move_ids.has(move_id):
            continue
        creature.learned_move_ids.append(move_id)
        new_moves.append(move_id)
        if creature.equipped_move_ids.size() < EQUIPPED_MOVE_LIMIT:
            creature.equipped_move_ids.append(move_id)

    if not save_creature(creature):
        CarriedInventoryService.add_item(inventory, food_id, 1)
        result["message"] = "Creature update could not be saved; food was returned."
        return result

    result["success"] = true
    result["growth_added"] = maxi(food.growth_xp, 0)
    result["bond_added"] = maxi(food.bond_growth, 0)
    result["new_moves"] = new_moves
    result["message"] = "%s ate %s. +%d growth XP." % [_get_creature_display_name(creature), food.display_name, maxi(food.growth_xp, 0)]
    return result

func get_evolution_options(instance_id: String) -> Array[CreatureEvolutionDefinition]:
    var result: Array[CreatureEvolutionDefinition] = []
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null or creature.life_stage == &"adult":
        return result
    for content_id_variant: Variant in ContentDB.get_all_ids():
        var content_id: StringName = StringName(str(content_id_variant))
        var evolution_definition: CreatureEvolutionDefinition = ContentDB.get_definition(content_id) as CreatureEvolutionDefinition
        if evolution_definition == null:
            continue
        if _evolution_qualifies(creature, evolution_definition):
            result.append(evolution_definition)
    result.sort_custom(func(a: CreatureEvolutionDefinition, b: CreatureEvolutionDefinition) -> bool: return String(a.content_id) < String(b.content_id))
    return result

func get_all_evolution_rules(instance_id: String) -> Array[CreatureEvolutionDefinition]:
    var result: Array[CreatureEvolutionDefinition] = []
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null or creature.life_stage == &"adult":
        return result
    for content_id_variant: Variant in ContentDB.get_all_ids():
        var content_id: StringName = StringName(str(content_id_variant))
        var evolution_definition: CreatureEvolutionDefinition = ContentDB.get_definition(content_id) as CreatureEvolutionDefinition
        if evolution_definition == null:
            continue
        if evolution_definition.source_species_id == creature.species_id and evolution_definition.source_stage == String(creature.life_stage):
            result.append(evolution_definition)
    result.sort_custom(func(a: CreatureEvolutionDefinition, b: CreatureEvolutionDefinition) -> bool: return String(a.content_id) < String(b.content_id))
    return result

func evolve_creature(instance_id: String, evolution_id: StringName) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "Evolution failed.", "old_species_id": &"", "new_species_id": &""}
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null:
        result["message"] = "Creature instance no longer exists."
        return result
    var evolution_definition: CreatureEvolutionDefinition = ContentDB.get_definition(evolution_id) as CreatureEvolutionDefinition
    if evolution_definition == null:
        result["message"] = "Evolution definition is missing."
        return result
    if not _evolution_qualifies(creature, evolution_definition):
        result["message"] = "This creature does not meet that evolution's requirements."
        return result
    var target_species: CreatureSpeciesDefinition = ContentDB.get_definition(evolution_definition.result_species_id) as CreatureSpeciesDefinition
    if target_species == null:
        result["message"] = "Evolution target species is missing."
        return result

    var old_species_id: StringName = creature.species_id
    var old_display_name: String = _get_creature_display_name(creature)
    var preserved_instance_id: String = creature.instance_id
    var preserved_nickname: String = creature.nickname
    var preserved_bond: int = creature.bond_level
    var preserved_learned_moves: Array[StringName] = creature.learned_move_ids.duplicate()
    var preserved_equipped_moves: Array[StringName] = creature.equipped_move_ids.duplicate()

    creature.species_id = evolution_definition.result_species_id
    creature.life_stage = StringName(target_species.life_stage.to_lower())
    creature.current_hp = target_species.base_health
    creature.instance_id = preserved_instance_id
    creature.nickname = preserved_nickname
    creature.bond_level = preserved_bond
    creature.learned_move_ids = preserved_learned_moves
    creature.equipped_move_ids = preserved_equipped_moves
    creature.reconcile_traits_for_species(target_species, true)

    if not save_creature(creature):
        result["message"] = "Evolution could not be saved."
        return result
    result["success"] = true
    result["old_species_id"] = old_species_id
    result["new_species_id"] = creature.species_id
    CollectionEncyclopediaService.mark_creature_evolved(creature.species_id)
    result["message"] = "%s evolved into %s." % [old_display_name, target_species.display_name]
    return result

func get_evolution_requirement_text(creature: CreatureInstanceData, evolution_definition: CreatureEvolutionDefinition) -> String:
    if creature == null or evolution_definition == null:
        return "Unavailable"
    var parts: Array[String] = []
    parts.append("Growth %d/%d" % [creature.growth_xp, evolution_definition.min_growth_xp])
    if evolution_definition.min_bond_level > 0:
        parts.append("Bond %d/%d" % [creature.bond_level, evolution_definition.min_bond_level])
    var tendency_key: String = evolution_definition.get_required_tendency_key()
    if not tendency_key.is_empty():
        var current_tendency: int = int(creature.evolution_tendencies.get(tendency_key, 0))
        parts.append("%s %d/%d" % [tendency_key.capitalize(), current_tendency, evolution_definition.minimum_tendency])
    return " | ".join(parts)

func _evolution_qualifies(creature: CreatureInstanceData, evolution_definition: CreatureEvolutionDefinition) -> bool:
    if creature == null or evolution_definition == null:
        return false
    if creature.species_id != evolution_definition.source_species_id:
        return false
    if String(creature.life_stage) != evolution_definition.source_stage:
        return false
    if creature.growth_xp < evolution_definition.min_growth_xp:
        return false
    if creature.bond_level < evolution_definition.min_bond_level:
        return false
    var tendency_key: String = evolution_definition.get_required_tendency_key()
    if not tendency_key.is_empty() and int(creature.evolution_tendencies.get(tendency_key, 0)) < evolution_definition.minimum_tendency:
        return false
    return true

func set_active_trait(instance_id: String, trait_id: StringName) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "Trait selection failed."}
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null:
        result["message"] = "Creature instance no longer exists."
        return result
    if creature.trait_candidate_ids.is_empty():
        result["message"] = "This creature has no trait candidates."
        return result
    if not creature.trait_candidate_ids.has(trait_id):
        result["message"] = "That trait is not one of this creature's candidates."
        return result
    var trait_definition: TraitDefinition = ContentDB.get_definition(trait_id) as TraitDefinition
    if trait_definition == null:
        result["message"] = "Trait definition is missing."
        return result
    creature.active_trait_id = trait_id
    if not save_creature(creature):
        result["message"] = "Trait selection could not be saved."
        return result
    result["success"] = true
    result["message"] = "%s selected %s." % [_get_creature_display_name(creature), trait_definition.display_name]
    return result

func equip_move(instance_id: String, move_id: StringName) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "Move could not be equipped."}
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null:
        result["message"] = "Creature instance no longer exists."
        return result
    if not creature.learned_move_ids.has(move_id):
        result["message"] = "That move has not been learned."
        return result
    if creature.equipped_move_ids.has(move_id):
        result["message"] = "That move is already equipped."
        return result
    if creature.equipped_move_ids.size() >= EQUIPPED_MOVE_LIMIT:
        result["message"] = "A creature can equip at most %d moves." % EQUIPPED_MOVE_LIMIT
        return result
    var move_definition: MoveDefinition = ContentDB.get_definition(move_id) as MoveDefinition
    if move_definition == null:
        result["message"] = "Move definition is missing."
        return result
    creature.equipped_move_ids.append(move_id)
    if not save_creature(creature):
        result["message"] = "Move loadout could not be saved."
        return result
    result["success"] = true
    result["message"] = "%s equipped %s." % [_get_creature_display_name(creature), move_definition.display_name]
    return result

func unequip_move(instance_id: String, move_id: StringName) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "Move could not be unequipped."}
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null:
        result["message"] = "Creature instance no longer exists."
        return result
    var index: int = creature.equipped_move_ids.find(move_id)
    if index < 0:
        result["message"] = "That move is not equipped."
        return result
    creature.equipped_move_ids.remove_at(index)
    if not save_creature(creature):
        result["message"] = "Move loadout could not be saved."
        return result
    result["success"] = true
    result["message"] = "%s unequipped %s." % [_get_creature_display_name(creature), CreatureDetailPresentationModel.get_move_name(move_id)]
    return result

func move_equipped_move(instance_id: String, from_index: int, to_index: int) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "Move order could not be changed."}
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null:
        result["message"] = "Creature instance no longer exists."
        return result
    if from_index < 0 or from_index >= creature.equipped_move_ids.size():
        result["message"] = "Source move slot is invalid."
        return result
    if to_index < 0 or to_index >= creature.equipped_move_ids.size():
        result["message"] = "Destination move slot is invalid."
        return result
    if from_index == to_index:
        result["success"] = true
        result["message"] = "Move order unchanged."
        return result
    var move_id: StringName = creature.equipped_move_ids[from_index]
    creature.equipped_move_ids.remove_at(from_index)
    creature.equipped_move_ids.insert(to_index, move_id)
    if not save_creature(creature):
        result["message"] = "Move order could not be saved."
        return result
    result["success"] = true
    result["message"] = "Moved %s to slot %d." % [CreatureDetailPresentationModel.get_move_name(move_id), to_index + 1]
    return result

func set_equipped_move_order(instance_id: String, ordered_move_ids: Array[StringName]) -> Dictionary:
    var result: Dictionary = {"success": false, "message": "Move loadout could not be changed."}
    var creature: CreatureInstanceData = get_creature(instance_id)
    if creature == null:
        result["message"] = "Creature instance no longer exists."
        return result
    if ordered_move_ids.size() > EQUIPPED_MOVE_LIMIT:
        result["message"] = "A creature can equip at most %d moves." % EQUIPPED_MOVE_LIMIT
        return result
    var seen: Dictionary = {}
    for move_id: StringName in ordered_move_ids:
        if move_id == &"" or seen.has(move_id) or not creature.learned_move_ids.has(move_id):
            result["message"] = "Move loadout contains an invalid or duplicate move."
            return result
        seen[move_id] = true
    creature.equipped_move_ids = ordered_move_ids.duplicate()
    if not save_creature(creature):
        result["message"] = "Move loadout could not be saved."
        return result
    result["success"] = true
    result["message"] = "Move loadout updated."
    return result

func is_in_party(instance_id: String) -> bool:
    return GameSession.party_instance_ids.has(instance_id)

func add_to_party(instance_id: String) -> bool:
    if instance_id.is_empty() or is_in_party(instance_id):
        return false
    if GameSession.party_instance_ids.size() >= PARTY_SIZE:
        return false
    if get_creature(instance_id) == null:
        return false
    GameSession.party_instance_ids.append(instance_id)
    GameSession.notify_party_changed()
    return true

func remove_from_party(instance_id: String) -> bool:
    var index: int = GameSession.party_instance_ids.find(instance_id)
    if index < 0:
        return false
    GameSession.party_instance_ids.remove_at(index)
    GameSession.notify_party_changed()
    return true

func get_party() -> Array[CreatureInstanceData]:
    var result: Array[CreatureInstanceData] = []
    for instance_id: String in GameSession.party_instance_ids:
        var creature: CreatureInstanceData = get_creature(instance_id)
        if creature != null:
            result.append(creature)
    return result

func restore_all_health() -> int:
    var restored: int = 0
    for creature: CreatureInstanceData in get_all_creatures():
        if creature == null:
            continue
        var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
        if species == null:
            continue
        var target_hp: int = maxi(species.base_health, 1)
        if creature.current_hp != target_hp:
            creature.current_hp = target_hp
            save_creature(creature)
            restored += 1
    return restored

func restore_party_health() -> int:
    var restored: int = 0
    for creature: CreatureInstanceData in get_party():
        if creature == null:
            continue
        var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
        if species == null:
            continue
        var target_hp: int = maxi(species.base_health, 1)
        if creature.current_hp != target_hp:
            creature.current_hp = target_hp
            save_creature(creature)
            restored += 1
    return restored

func _add_tendency(creature: CreatureInstanceData, key: String, amount: int) -> void:
    if amount <= 0:
        return
    var current: int = int(creature.evolution_tendencies.get(key, 0))
    creature.evolution_tendencies[key] = current + amount

func _get_creature_display_name(creature: CreatureInstanceData) -> String:
    if not creature.nickname.is_empty():
        return creature.nickname
    var species: CreatureSpeciesDefinition = ContentDB.get_definition(creature.species_id) as CreatureSpeciesDefinition
    return String(creature.species_id) if species == null else species.display_name
