extends PanelContainer
class_name CraftingPanel

signal panel_state_changed(is_open: bool)
signal status_message_requested(message: String)

@onready var title_label: Label = $Margin/Layout/Header/Title
@onready var category_label: Label = $Margin/Layout/Header/Category
@onready var list_box: VBoxContainer = $Margin/Layout/Scroll/List
@onready var help_label: Label = $Margin/Layout/Help
@onready var close_button: Button = $Margin/Layout/CloseButton

var _inventory: InventoryComponent = null
var _station_tags: Array[StringName] = []

func _ready() -> void:
    visible = false
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_title(title_label, 27)
    LungSaUIStyle.apply_kicker(category_label)
    LungSaUIStyle.apply_muted(help_label, 11)
    LungSaUIStyle.apply_button(close_button, false)
    close_button.text = "Close  [Esc]"
    close_button.pressed.connect(close_panel)

func open_station(station_tags: Array[StringName], title: String, inventory: InventoryComponent) -> bool:
    if inventory == null:
        return false
    _station_tags = station_tags.duplicate()
    _inventory = inventory
    title_label.text = title
    category_label.text = "COOKING HEARTH" if _station_tags.has(&"cooking") else "FIELD CRAFTING"
    visible = true
    _refresh()
    panel_state_changed.emit(true)
    return true

func close_panel() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)

func _refresh() -> void:
    for child: Node in list_box.get_children():
        child.queue_free()
    var first_button: Button = null
    var recipe_count: int = 0
    for content_id: StringName in ContentDB.get_all_ids():
        var recipe: RecipeDefinition = ContentDB.get_definition(content_id) as RecipeDefinition
        if recipe == null or not CraftingService.can_use_at(recipe, _station_tags):
            continue
        recipe_count += 1
        var output: ItemDefinition = ContentDB.get_definition(recipe.output_item_id) as ItemDefinition
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(0.0, 62.0)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.text = "%s  ×%d\n%s" % [output.display_name if output != null else recipe.display_name, recipe.output_amount, CraftingService.ingredient_text(recipe, _inventory)]
        button.disabled = not CraftingService.can_craft(recipe, _inventory, _station_tags)
        LungSaUIStyle.apply_button(button, not button.disabled)
        button.pressed.connect(_craft.bind(recipe.content_id))
        list_box.add_child(button)
        if first_button == null and not button.disabled:
            first_button = button
    if recipe_count == 0:
        var empty: Label = Label.new()
        empty.text = "No recipes are available at this station."
        LungSaUIStyle.apply_muted(empty, 13)
        list_box.add_child(empty)
    help_label.text = "Ingredients are counted from Pack + Quick Bar. Finished items return to the Pack."
    if first_button != null:
        first_button.grab_focus()
    else:
        close_button.grab_focus()

func _craft(recipe_id: StringName) -> void:
    var recipe: RecipeDefinition = ContentDB.get_definition(recipe_id) as RecipeDefinition
    var result: Dictionary = CraftingService.craft(recipe, _inventory, _station_tags)
    status_message_requested.emit(str(result.get("message", "")))
    _refresh()
