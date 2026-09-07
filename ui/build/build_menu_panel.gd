extends PanelContainer
class_name BuildMenuPanel

signal panel_state_changed(is_open: bool)
signal building_requested(building_id: StringName)
signal farm_plot_requested(plot_count: int)
signal tool_upgrade_requested(upgrade_id: StringName)
signal remove_mode_requested

@onready var title_label: Label = $Margin/Layout/Header/Title
@onready var category_label: Label = $Margin/Layout/Header/Category
@onready var list_box: VBoxContainer = $Margin/Layout/Scroll/List
@onready var help_label: Label = $Margin/Layout/Help
@onready var remove_button: Button = $Margin/Layout/RemoveButton
@onready var close_button: Button = $Margin/Layout/CloseButton

var _region_root: RegionRoot = null
var _player: PlayerActor = null

func _ready() -> void:
    visible = false
    LungSaUIStyle.apply_panel(self, true)
    LungSaUIStyle.apply_title(title_label, 27)
    LungSaUIStyle.apply_kicker(category_label)
    LungSaUIStyle.apply_muted(help_label, 11)
    LungSaUIStyle.apply_button(remove_button, false)
    LungSaUIStyle.apply_button(close_button, false)
    remove_button.text = "Remove Building  [R]"
    close_button.text = "Close  [Esc]"
    remove_button.pressed.connect(_request_remove_mode)
    close_button.pressed.connect(close_panel)

func open_panel(region_root: RegionRoot, player: PlayerActor) -> void:
    _region_root = region_root
    _player = player
    visible = true
    refresh()
    panel_state_changed.emit(true)

func close_panel() -> void:
    if not visible:
        return
    visible = false
    panel_state_changed.emit(false)

func refresh() -> void:
    for child: Node in list_box.get_children():
        child.queue_free()

    var inventory: InventoryComponent = _player.inventory_component if _player != null else null
    var buildings: Array[BuildingDefinition] = []
    var upgrades: Array[ToolUpgradeDefinition] = []

    for content_id: StringName in ContentDB.get_all_ids():
        var building: BuildingDefinition = ContentDB.get_definition(content_id) as BuildingDefinition
        if building != null and building.tags.has(&"building"):
            buildings.append(building)
            continue
        var upgrade: ToolUpgradeDefinition = ContentDB.get_definition(content_id) as ToolUpgradeDefinition
        if upgrade != null:
            upgrades.append(upgrade)

    buildings.sort_custom(func(a: BuildingDefinition, b: BuildingDefinition) -> bool:
        if a.menu_order == b.menu_order:
            return a.display_name < b.display_name
        return a.menu_order < b.menu_order
    )
    upgrades.sort_custom(func(a: ToolUpgradeDefinition, b: ToolUpgradeDefinition) -> bool:
        return a.display_name < b.display_name
    )

    var first_button: Button = null

    if not buildings.is_empty():
        _add_section_label("BUILDINGS")
        for definition: BuildingDefinition in buildings:
            var button: Button = Button.new()
            button.custom_minimum_size = Vector2(0.0, 58.0)
            button.alignment = HORIZONTAL_ALIGNMENT_LEFT
            button.text = "%s\n%s" % [definition.display_name, BuildingPlacementService.cost_text(definition, inventory)]
            button.disabled = not BuildingPlacementService.can_afford(definition, inventory)
            LungSaUIStyle.apply_button(button, not button.disabled)
            button.pressed.connect(_request_building.bind(definition.content_id))
            list_box.add_child(button)
            if first_button == null and not button.disabled:
                first_button = button

    var farm: FarmPlotSystem = _farm_system()
    if farm != null:
        var placeable_count: int = farm.get_placeable_plot_count()
        _add_section_label("FARM")
        var plot_button: Button = Button.new()
        plot_button.custom_minimum_size = Vector2(0.0, 52.0)
        plot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        plot_button.text = "Place Farm Plots\n%d currently available" % placeable_count
        plot_button.disabled = placeable_count <= 0
        LungSaUIStyle.apply_button(plot_button, not plot_button.disabled)
        plot_button.pressed.connect(_request_farm_plots.bind(placeable_count))
        list_box.add_child(plot_button)
        if first_button == null and not plot_button.disabled:
            first_button = plot_button

    if not upgrades.is_empty():
        _add_section_label("TOOL UPGRADES")
        for upgrade: ToolUpgradeDefinition in upgrades:
            var upgrade_button: Button = Button.new()
            upgrade_button.custom_minimum_size = Vector2(0.0, 48.0)
            upgrade_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
            upgrade_button.text = upgrade.display_name
            LungSaUIStyle.apply_button(upgrade_button, true)
            upgrade_button.pressed.connect(_request_tool_upgrade.bind(upgrade.content_id))
            list_box.add_child(upgrade_button)
            if first_button == null:
                first_button = upgrade_button

    if list_box.get_child_count() == 0:
        var empty: Label = Label.new()
        empty.text = "No building options are available in this region."
        LungSaUIStyle.apply_muted(empty, 13)
        list_box.add_child(empty)

    help_label.text = "Build costs use Pack + Quick Bar. Select an option, then place it in the world."
    remove_button.disabled = _region_root == null
    if first_button != null:
        first_button.grab_focus()
    else:
        close_button.grab_focus()

func _add_section_label(text: String) -> void:
    var label: Label = Label.new()
    label.text = text
    LungSaUIStyle.apply_kicker(label)
    list_box.add_child(label)

func _farm_system() -> FarmPlotSystem:
    if _region_root == null:
        return null
    return _region_root.get_local_system(&"FarmPlotSystem") as FarmPlotSystem

func _request_building(building_id: StringName) -> void:
    close_panel()
    building_requested.emit(building_id)

func _request_farm_plots(plot_count: int) -> void:
    if plot_count <= 0:
        return
    close_panel()
    farm_plot_requested.emit(plot_count)

func _request_tool_upgrade(upgrade_id: StringName) -> void:
    tool_upgrade_requested.emit(upgrade_id)
    call_deferred("refresh")

func _request_remove_mode() -> void:
    close_panel()
    remove_mode_requested.emit()
