extends ContentDefinition
class_name GameProfileDefinition

@export_group("Start")
@export_file("*.tscn") var start_scene_path: String = ""
@export var start_spawn_id: StringName = &"default"
@export var starter_zone_id: StringName = &""
@export var initial_currency: int = 0
@export var starter_species_ids: Array[StringName] = []
@export var starter_items: Array[StarterItemEntry] = []

@export_group("Story")
@export var primary_story_chain_id: StringName = &""
@export_multiline var welcome_message: String = ""
@export var completion_title: String = "Complete"
@export_multiline var completion_message: String = ""

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("profile."):
        errors.append("Game profile ID should use profile.* namespace")
    if start_scene_path.is_empty() or not ResourceLoader.exists(start_scene_path, "PackedScene"):
        errors.append("Game profile start_scene_path is missing or invalid: %s" % start_scene_path)
    if starter_zone_id != &"" and not ContentDB.get_definition(starter_zone_id) is ZoneDefinition:
        errors.append("Game profile references missing starter zone %s" % String(starter_zone_id))
    for species_id: StringName in starter_species_ids:
        if not ContentDB.get_definition(species_id) is CreatureSpeciesDefinition:
            errors.append("Game profile references missing starter creature %s" % String(species_id))
    for entry: StarterItemEntry in starter_items:
        if entry == null or entry.item_id == &"":
            errors.append("Game profile contains an invalid starter item entry")
        elif not ContentDB.get_definition(entry.item_id) is ItemDefinition:
            errors.append("Game profile references missing starter item %s" % String(entry.item_id))
    if primary_story_chain_id != &"" and not ContentDB.get_definition(primary_story_chain_id) is StoryChainDefinition:
        errors.append("Game profile references missing story chain %s" % String(primary_story_chain_id))
    return errors
