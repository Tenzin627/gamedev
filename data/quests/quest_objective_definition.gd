extends Resource
class_name QuestObjectiveDefinition

enum Kind {
    TALK_TO_NPC,
    WORLD_FLAG,
    COLLECT_ITEM,
    HARVEST_ITEM,
    DEFEAT_CREATURE,
    BOND_CREATURE,
    DISCOVER_CONTENT,
    CRAFT_RECIPE,
    INTERACT_WITH,
    ACTIVATE_WAYMARK,
    PLACE_BUILDING,
    REACH_ZONE,
    SESSION_COUNTER,
}

@export var objective_id: StringName = &""
@export var kind: Kind = Kind.TALK_TO_NPC
@export var target_id: StringName = &""
@export_range(1, 9999, 1) var required_amount: int = 1
@export_multiline var description: String = ""

func validate_objective() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if objective_id == &"":
        errors.append("Objective is missing objective_id")
    if target_id == &"":
        errors.append("Objective %s is missing target_id" % String(objective_id))
    if description.strip_edges().is_empty():
        errors.append("Objective %s is missing description" % String(objective_id))
    if target_id == &"":
        return errors
    match kind:
        Kind.TALK_TO_NPC:
            if not ContentDB.get_definition(target_id) is NPCDefinition:
                errors.append("Objective references missing NPC %s" % String(target_id))
        Kind.COLLECT_ITEM, Kind.HARVEST_ITEM:
            if not ContentDB.get_definition(target_id) is ItemDefinition:
                errors.append("Objective references missing item %s" % String(target_id))
        Kind.DEFEAT_CREATURE, Kind.BOND_CREATURE:
            if not ContentDB.get_definition(target_id) is CreatureSpeciesDefinition:
                errors.append("Objective references missing creature %s" % String(target_id))
        Kind.DISCOVER_CONTENT, Kind.INTERACT_WITH:
            if not ContentDB.has_definition(target_id):
                errors.append("Objective references missing content %s" % String(target_id))
        Kind.CRAFT_RECIPE:
            if not ContentDB.get_definition(target_id) is RecipeDefinition:
                errors.append("Objective references missing recipe %s" % String(target_id))
        Kind.ACTIVATE_WAYMARK:
            if not ContentDB.get_definition(target_id) is WaymarkDefinition:
                errors.append("Objective references missing waymark %s" % String(target_id))
        Kind.PLACE_BUILDING:
            if not ContentDB.get_definition(target_id) is BuildingDefinition:
                errors.append("Objective references missing building %s" % String(target_id))
        Kind.REACH_ZONE:
            if not ContentDB.get_definition(target_id) is ZoneDefinition:
                errors.append("Objective references missing zone %s" % String(target_id))
    return errors
