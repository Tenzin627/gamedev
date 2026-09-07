extends ContentDefinition
class_name FarmWorkProfileDefinition

@export var rules: Array[FarmWorkRule] = []
@export_range(0.05, 3.0, 0.05) var work_rate_multiplier: float = 1.0
@export_range(0, 40, 1) var auto_till_cell_limit: int = 8

func get_enabled_rules() -> Array[FarmWorkRule]:
    var result: Array[FarmWorkRule] = []
    for rule: FarmWorkRule in rules:
        if rule != null and rule.enabled:
            result.append(rule)
    result.sort_custom(func(a: FarmWorkRule, b: FarmWorkRule) -> bool: return a.priority > b.priority)
    return result

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if not String(content_id).begins_with("farm_work."):
        errors.append("Farm work profile ID should use farm_work.* namespace")
    if rules.is_empty():
        errors.append("Farm work profile should define at least one rule")
    return errors
