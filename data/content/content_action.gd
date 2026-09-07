extends Resource
class_name ContentAction

enum Kind {
    NONE,
    SET_WORLD_FLAG,
    ACCEPT_QUEST,
    COMPLETE_QUEST,
    ADD_CURRENCY,
    SET_SESSION_VALUE,
    DISCOVER_RECIPE,
    ACTIVATE_WAYMARK,
    DISCOVER_CONTENT,
    ADD_ITEM,
    REMOVE_ITEM,
    APPLY_PAYMENT_CREDIT,
}

@export var kind: Kind = Kind.NONE
@export var key: StringName = &""
@export var value: String = "true"
@export var amount: int = 0

func validate_action() -> PackedStringArray:
    var errors: PackedStringArray = PackedStringArray()
    if kind == Kind.NONE:
        return errors
    if kind != Kind.ADD_CURRENCY and kind != Kind.APPLY_PAYMENT_CREDIT and key == &"":
        errors.append("Action is missing key/target")
        return errors
    match kind:
        Kind.ACCEPT_QUEST, Kind.COMPLETE_QUEST:
            if not ContentDB.get_definition(key) is QuestDefinition:
                errors.append("Action references missing quest %s" % String(key))
        Kind.DISCOVER_RECIPE:
            if not ContentDB.get_definition(key) is RecipeDefinition:
                errors.append("Action references missing recipe %s" % String(key))
        Kind.ACTIVATE_WAYMARK:
            if not ContentDB.get_definition(key) is WaymarkDefinition:
                errors.append("Action references missing waymark %s" % String(key))
        Kind.DISCOVER_CONTENT:
            if not ContentDB.has_definition(key):
                errors.append("Action references missing content %s" % String(key))
        Kind.ADD_ITEM, Kind.REMOVE_ITEM:
            if not ContentDB.get_definition(key) is ItemDefinition:
                errors.append("Action references missing item %s" % String(key))
            if amount <= 0:
                errors.append("Item action amount must be positive")
        Kind.APPLY_PAYMENT_CREDIT:
            if amount <= 0:
                errors.append("Payment-credit action amount must be positive")
    return errors
