extends ItemDefinition
class_name BattleConsumableDefinition

@export var battle_effect_ids: Array[StringName] = []
@export_enum("ActiveAlly", "AnyAlly") var target_mode: String = "ActiveAlly"
@export var usable_in_battle: bool = true

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if category != "Consumable":
        errors.append("BattleConsumableDefinition category should be Consumable for %s" % String(content_id))
    if battle_effect_ids.is_empty():
        errors.append("battle_effect_ids cannot be empty for %s" % String(content_id))
    return errors
