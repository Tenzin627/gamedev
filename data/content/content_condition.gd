extends Resource
class_name ContentCondition

enum Kind {
    ALWAYS,
    WORLD_FLAG,
    QUEST_STATUS,
    INVENTORY_ITEM,
    SESSION_VALUE,
    CURRENCY,
    CREATURE_OWNED,
    WAYMARK_ACTIVE,
    RECIPE_DISCOVERED,
    BUILDING_PLACED,
    DISCOVERY_FOUND,
    CURRENT_ZONE,
}

enum Compare { EQUAL, NOT_EQUAL, AT_LEAST, AT_MOST, GREATER, LESS }

@export var kind: Kind = Kind.ALWAYS
@export var key: StringName = &""
@export var expected_value: String = "true"
@export var amount: int = 1
@export var comparison: Compare = Compare.EQUAL
@export var inverted: bool = false

func validate_condition() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if kind == Kind.ALWAYS or kind == Kind.CURRENCY:
        return errors
    if key == &"":
        errors.append("Condition is missing key/target")
        return errors
    match kind:
        Kind.QUEST_STATUS:
            if not ContentDB.get_definition(key) is QuestDefinition:
                errors.append("Condition references missing quest %s" % String(key))
        Kind.INVENTORY_ITEM:
            if not ContentDB.get_definition(key) is ItemDefinition:
                errors.append("Condition references missing item %s" % String(key))
        Kind.CREATURE_OWNED:
            if not ContentDB.get_definition(key) is CreatureSpeciesDefinition:
                errors.append("Condition references missing creature %s" % String(key))
        Kind.WAYMARK_ACTIVE:
            if not ContentDB.get_definition(key) is WaymarkDefinition:
                errors.append("Condition references missing waymark %s" % String(key))
        Kind.RECIPE_DISCOVERED:
            if not ContentDB.get_definition(key) is RecipeDefinition:
                errors.append("Condition references missing recipe %s" % String(key))
        Kind.BUILDING_PLACED:
            if not ContentDB.get_definition(key) is BuildingDefinition:
                errors.append("Condition references missing building %s" % String(key))
        Kind.DISCOVERY_FOUND:
            if not ContentDB.has_definition(key):
                errors.append("Condition references missing discovery/content %s" % String(key))
        Kind.CURRENT_ZONE:
            if not ContentDB.get_definition(key) is ZoneDefinition:
                errors.append("Condition references missing zone %s" % String(key))
    return errors
