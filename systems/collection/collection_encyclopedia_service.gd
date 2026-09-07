extends Node

signal collection_changed

const SEEN_KEY: StringName = &"encyclopedia_seen_creatures"
const OWNED_HISTORY_KEY: StringName = &"encyclopedia_owned_creatures"
const EVOLVED_KEY: StringName = &"encyclopedia_evolved_creatures"

func _ready() -> void:
    GameSession.creature_collection_changed.connect(_on_creature_collection_changed)
    GameSession.session_imported.connect(_on_session_imported)
    call_deferred("sync_owned_creatures")

func mark_creature_seen(species_id: StringName) -> bool:
    if not ContentDB.get_definition(species_id) is CreatureSpeciesDefinition:
        return false
    var changed: bool = _add_unique(SEEN_KEY, species_id)
    if changed:
        collection_changed.emit()
    return changed

func mark_creature_owned(species_id: StringName) -> bool:
    if not ContentDB.get_definition(species_id) is CreatureSpeciesDefinition:
        return false
    var changed: bool = _add_unique(OWNED_HISTORY_KEY, species_id)
    _add_unique(SEEN_KEY, species_id)
    if changed:
        collection_changed.emit()
    return changed

func mark_creature_evolved(species_id: StringName) -> bool:
    var changed: bool = _add_unique(EVOLVED_KEY, species_id)
    mark_creature_owned(species_id)
    if changed:
        collection_changed.emit()
    return changed

func sync_owned_creatures() -> void:
    var changed: bool = false
    for entry_variant: Variant in GameSession.creature_instances:
        if not entry_variant is Dictionary:
            continue
        var species_id: StringName = StringName(str(Dictionary(entry_variant).get("species_id", "")))
        if species_id != &"":
            changed = _add_unique(OWNED_HISTORY_KEY, species_id) or changed
            changed = _add_unique(SEEN_KEY, species_id) or changed
    if changed:
        collection_changed.emit()

func is_creature_seen(species_id: StringName) -> bool:
    return _has_id(SEEN_KEY, species_id)

func is_creature_owned(species_id: StringName) -> bool:
    return _has_id(OWNED_HISTORY_KEY, species_id)

func is_creature_evolved(species_id: StringName) -> bool:
    return _has_id(EVOLVED_KEY, species_id)

func get_creature_species() -> Array[CreatureSpeciesDefinition]:
    var result: Array[CreatureSpeciesDefinition] = []
    for content_id: StringName in ContentDB.get_all_ids():
        var definition: CreatureSpeciesDefinition = ContentDB.get_definition(content_id) as CreatureSpeciesDefinition
        if definition != null:
            result.append(definition)
    result.sort_custom(func(a: CreatureSpeciesDefinition, b: CreatureSpeciesDefinition) -> bool: return String(a.content_id) < String(b.content_id))
    return result

func get_plants() -> Array[PlantDefinition]:
    var result: Array[PlantDefinition] = []
    for content_id: StringName in ContentDB.get_all_ids():
        var definition: PlantDefinition = ContentDB.get_definition(content_id) as PlantDefinition
        if definition != null:
            result.append(definition)
    return result

func is_plant_discovered(definition: PlantDefinition) -> bool:
    if definition == null:
        return false
    if definition.discovery_id == &"":
        return false
    var ids: Variant = GameSession.get_value(&"exploration_discoveries", [])
    return ids is Array and Array(ids).has(String(definition.discovery_id))

func get_creature_completion() -> Dictionary:
    var species: Array[CreatureSpeciesDefinition] = get_creature_species()
    var seen: int = 0
    var owned: int = 0
    for definition: CreatureSpeciesDefinition in species:
        if is_creature_seen(definition.content_id):
            seen += 1
        if is_creature_owned(definition.content_id):
            owned += 1
    return {"seen": seen, "owned": owned, "total": species.size()}

func get_plant_completion() -> Dictionary:
    var plants: Array[PlantDefinition] = get_plants()
    var found: int = 0
    for definition: PlantDefinition in plants:
        if is_plant_discovered(definition):
            found += 1
    return {"found": found, "total": plants.size()}

func _on_creature_collection_changed() -> void:
    sync_owned_creatures()

func _on_session_imported() -> void:
    sync_owned_creatures()
    collection_changed.emit()

func _add_unique(key: StringName, content_id: StringName) -> bool:
    var values: Array[String] = _get_ids(key)
    var text: String = String(content_id)
    if text.is_empty() or values.has(text):
        return false
    values.append(text)
    GameSession.set_value(key, values)
    return true

func _has_id(key: StringName, content_id: StringName) -> bool:
    return _get_ids(key).has(String(content_id))

func _get_ids(key: StringName) -> Array[String]:
    var result: Array[String] = []
    var value: Variant = GameSession.get_value(key, [])
    if value is Array:
        for entry: Variant in Array(value):
            var text: String = str(entry)
            if not text.is_empty() and not result.has(text):
                result.append(text)
    return result
