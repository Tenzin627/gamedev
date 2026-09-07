extends RefCounted
class_name CraftingService

static func is_discovered(recipe: RecipeDefinition) -> bool:
    if recipe == null:
        return false
    if recipe.discovered_by_default:
        return true
    var unlocked: Array = Array(GameSession.get_value(&"discovered_recipes", []))
    return unlocked.has(String(recipe.content_id))

static func discover(recipe_id: StringName) -> bool:
    var recipe: RecipeDefinition = ContentDB.get_definition(recipe_id) as RecipeDefinition
    if recipe == null:
        return false
    var unlocked: Array = Array(GameSession.get_value(&"discovered_recipes", [])).duplicate()
    var key: String = String(recipe_id)
    if unlocked.has(key):
        return false
    unlocked.append(key)
    GameSession.set_value(&"discovered_recipes", unlocked)
    return true

static func can_use_at(recipe: RecipeDefinition, station_tags: Array[StringName]) -> bool:
    if recipe == null or not is_discovered(recipe):
        return false
    for required_tag: StringName in recipe.station_tags:
        if not station_tags.has(required_tag):
            return false
    for condition: ContentCondition in recipe.required_conditions:
        if condition != null and not ContentConditionEvaluator.evaluate(condition):
            return false
    return true

static func can_craft(recipe: RecipeDefinition, inventory: InventoryComponent, station_tags: Array[StringName]) -> bool:
    if inventory == null or not can_use_at(recipe, station_tags):
        return false
    for ingredient: RecipeIngredient in recipe.ingredients:
        if ingredient == null or _get_carried_quantity(inventory, ingredient.item_id) < ingredient.amount:
            return false
    return _can_fit_after_consumption(recipe, inventory)

static func craft(recipe: RecipeDefinition, inventory: InventoryComponent, station_tags: Array[StringName]) -> Dictionary:
    var result: Dictionary = {"success": false, "message": ""}
    if recipe == null or inventory == null:
        result["message"] = "Recipe is unavailable."
        return result
    if not can_use_at(recipe, station_tags):
        result["message"] = "This recipe cannot be made here."
        return result
    for ingredient: RecipeIngredient in recipe.ingredients:
        if ingredient == null or _get_carried_quantity(inventory, ingredient.item_id) < ingredient.amount:
            result["message"] = "Missing ingredients."
            return result
    if not _can_fit_after_consumption(recipe, inventory):
        result["message"] = "Inventory has no room for the result."
        return result
    var transaction_state: Dictionary = CarriedInventoryService.export_state(inventory)
    for ingredient: RecipeIngredient in recipe.ingredients:
        var remaining: int = _remove_carried_item(inventory, ingredient.item_id, ingredient.amount)
        if remaining > 0:
            CarriedInventoryService.restore_state(inventory, transaction_state)
            result["message"] = "Ingredients changed before crafting completed."
            return result
    var leftover: int = CarriedInventoryService.add_item(inventory, recipe.output_item_id, recipe.output_amount)
    if leftover > 0:
        CarriedInventoryService.restore_state(inventory, transaction_state)
        result["message"] = "Could not store the crafted item."
        return result
    var output: ItemDefinition = ContentDB.get_definition(recipe.output_item_id) as ItemDefinition
    result["success"] = true
    QuestService.notify_event(QuestObjectiveDefinition.Kind.CRAFT_RECIPE, recipe.content_id, 1)
    result["message"] = "Made %s ×%d." % [output.display_name if output != null else String(recipe.output_item_id), recipe.output_amount]
    return result

static func ingredient_text(recipe: RecipeDefinition, inventory: InventoryComponent) -> String:
    if recipe == null:
        return ""
    var parts: PackedStringArray = []
    for ingredient: RecipeIngredient in recipe.ingredients:
        if ingredient == null:
            continue
        var item: ItemDefinition = ContentDB.get_definition(ingredient.item_id) as ItemDefinition
        var owned: int = _get_carried_quantity(inventory, ingredient.item_id) if inventory != null else 0
        parts.append("%s %d/%d" % [item.display_name if item != null else String(ingredient.item_id), owned, ingredient.amount])
    return "  •  ".join(parts)

static func _can_fit_after_consumption(recipe: RecipeDefinition, inventory: InventoryComponent) -> bool:
    var hotbar: HotbarComponent = CarriedInventoryService.get_hotbar(inventory)
    var state: Dictionary = CarriedInventoryService.export_state(inventory, hotbar)
    var temp: InventoryComponent = InventoryComponent.new()
    temp.sync_with_game_session = false
    temp.import_state(Dictionary(state.get("inventory", {})), false)
    var temp_hotbar: HotbarComponent = HotbarComponent.new()
    temp_hotbar.sync_with_game_session = false
    temp_hotbar.import_state(Dictionary(state.get("hotbar", {})), false)
    for ingredient: RecipeIngredient in recipe.ingredients:
        if ingredient != null:
            CarriedInventoryService.remove_item(temp, ingredient.item_id, ingredient.amount, temp_hotbar)
    var fits: bool = CarriedInventoryService.can_add_item(temp, recipe.output_item_id, recipe.output_amount, temp_hotbar)
    temp.free()
    temp_hotbar.free()
    return fits

static func _get_carried_quantity(inventory: InventoryComponent, item_id: StringName) -> int:
    if inventory == null:
        return 0
    return CarriedInventoryService.get_total_quantity(inventory, item_id)

static func _remove_carried_item(inventory: InventoryComponent, item_id: StringName, amount: int) -> int:
    if inventory == null or amount <= 0:
        return maxi(amount, 0)
    return CarriedInventoryService.remove_item(inventory, item_id, amount)
