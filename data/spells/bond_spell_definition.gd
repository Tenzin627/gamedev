extends ContentDefinition
class_name BondSpellDefinition

@export_range(0, 999999, 1) var retry_currency_cost: int = 25
@export var standard_attempts_per_encounter: int = 1
@export_range(0, 8, 1) var max_paid_retries_per_encounter: int = 1

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if retry_currency_cost < 0:
        errors.append("Bond spell retry_currency_cost must be >= 0")
    if standard_attempts_per_encounter != 1:
        errors.append("Lung Sa Bond spell currently requires exactly one standard attempt per encounter")
    if max_paid_retries_per_encounter < 0:
        errors.append("Bond spell max_paid_retries_per_encounter must be >= 0")
    return errors
