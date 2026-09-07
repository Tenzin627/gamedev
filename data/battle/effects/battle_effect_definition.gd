extends ContentDefinition
class_name BattleEffectDefinition

@export_enum("Damage", "Heal", "Guard", "PowerModifier", "DamageTakenModifier", "PriorityModifier", "ApplyStatus", "Cleanse") var effect_type: String = "Damage"
@export_enum("Self", "Opponent", "SelectedAlly") var target_scope: String = "Opponent"
@export var amount: int = 0
@export var multiplier: float = 1.0
@export var status_id: StringName = &""
@export var status_duration_turns: int = 0

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if effect_type == "ApplyStatus" and status_id == &"":
        errors.append("ApplyStatus requires status_id for %s" % String(content_id))
    if effect_type == "Heal" and amount <= 0:
        errors.append("Heal amount must be positive for %s" % String(content_id))
    return errors
