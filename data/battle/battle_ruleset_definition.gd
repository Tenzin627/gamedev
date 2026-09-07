extends ContentDefinition
class_name BattleRulesetDefinition

@export_range(1, 3, 1) var party_size: int = 3
@export var active_creatures_per_side: int = 1
@export_range(0, 8, 1) var switch_cooldown_turns: int = 1
@export var allow_items: bool = true
@export var allow_escape: bool = true
@export_range(1.0, 3.0, 0.05) var archetype_advantage_multiplier: float = 1.25
@export_range(0.1, 1.0, 0.05) var archetype_disadvantage_multiplier: float = 0.80
@export_range(0.1, 1.0, 0.05) var guard_damage_multiplier: float = 0.65

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if party_size < 1 or party_size > 3:
        errors.append("party_size must be between 1 and 3.")
    if active_creatures_per_side != 1:
        errors.append("Lung Sa currently supports exactly one active creature per side.")
    if switch_cooldown_turns < 0:
        errors.append("switch_cooldown_turns cannot be negative.")
    if archetype_advantage_multiplier < 1.0:
        errors.append("archetype_advantage_multiplier must be >= 1.0.")
    if archetype_disadvantage_multiplier <= 0.0 or archetype_disadvantage_multiplier > 1.0:
        errors.append("archetype_disadvantage_multiplier must be > 0 and <= 1.0.")
    if guard_damage_multiplier <= 0.0 or guard_damage_multiplier > 1.0:
        errors.append("guard_damage_multiplier must be > 0 and <= 1.0.")
    return errors
