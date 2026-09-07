extends ContentDefinition
class_name BattleAIProfileDefinition

@export_range(0.0, 1.0, 0.01) var switch_hp_threshold: float = 0.25
@export_range(0.0, 5.0, 0.05) var advantage_weight: float = 1.25
@export_range(0.0, 5.0, 0.05) var damage_weight: float = 1.0
@export_range(0.0, 5.0, 0.05) var defense_weight: float = 0.45
@export_range(0.0, 5.0, 0.05) var status_weight: float = 0.35
@export var allow_tactical_switch: bool = true

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if switch_hp_threshold < 0.0 or switch_hp_threshold > 1.0:
        errors.append("Battle AI profile %s has invalid switch threshold" % String(content_id))
    return errors
