extends ContentDefinition
class_name RecipeDefinition

@export_enum("Crafting", "Cooking") var recipe_category: String = "Crafting"
@export var station_tags: Array[StringName] = []
@export var ingredients: Array[RecipeIngredient] = []
@export var output_item_id: StringName = &""
@export_range(1, 999, 1) var output_amount: int = 1
@export var discovered_by_default: bool = true
@export var required_conditions: Array[ContentCondition] = []

func validate_definition() -> PackedStringArray:
    var errors: PackedStringArray = super.validate_definition()
    if output_item_id == &"":
        errors.append("output_item_id cannot be empty for %s" % String(content_id))
    if ingredients.is_empty():
        errors.append("ingredients cannot be empty for %s" % String(content_id))
    for ingredient: RecipeIngredient in ingredients:
        if ingredient == null:
            errors.append("null ingredient in %s" % String(content_id))
        else:
            errors.append_array(ingredient.validate_ingredient())
    for condition: ContentCondition in required_conditions:
        if condition != null:
            errors.append_array(condition.validate_condition())
    return errors
