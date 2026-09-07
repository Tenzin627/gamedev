extends Resource
class_name RecipeIngredient

@export var item_id: StringName = &""
@export_range(1, 999, 1) var amount: int = 1

func validate_ingredient() -> PackedStringArray:
    var errors: PackedStringArray = []
    if item_id == &"":
        errors.append("ingredient item_id cannot be empty")
    if amount <= 0:
        errors.append("ingredient amount must be positive")
    return errors
