extends ContentDefinition
class_name BattleStatusDefinition

@export var default_duration_turns: int = 2
@export var damage_each_turn: int = 0
@export var healing_each_turn: int = 0
@export var power_modifier: int = 0
@export var priority_modifier: int = 0
@export var damage_taken_multiplier: float = 1.0

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if default_duration_turns <= 0:
        errors.append("default_duration_turns must be positive for %s" % String(content_id))
    if damage_taken_multiplier <= 0.0:
        errors.append("damage_taken_multiplier must be positive for %s" % String(content_id))
    return errors
