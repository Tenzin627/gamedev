extends RegionLocalSystem
class_name BuildingPlacementController

const PLACED_SCENE: PackedScene = preload("res://world/shared/building/placed_building.tscn")

@export var auto_discover_buildings: bool = true
@export var available_building_ids: Array[StringName] = []
@export var placement_collision_mask: int = 1

var _player: PlayerActor = null
var _hud: CoreHUD = null
var _inventory: InventoryComponent = null
var _preview: BuildingPreview = null
var _active: bool = false
var _remove_mode: bool = false
var _farm_plot_mode: bool = false
var _farm_plots_remaining: int = 0
var _selected_building_id: StringName = &""
var _placed_records: Array[Dictionary] = []
var _next_serial: int = 1
var _tool_upgrade_service: ToolUpgradeService = ToolUpgradeService.new()

func _on_region_bound() -> void:
    call_deferred("_bind_world")

func _bind_world() -> void:
    if region_root == null:
        return
    if auto_discover_buildings:
        _refresh_available_buildings()
    _player = region_root.get_node_or_null(^"PlayerActor") as PlayerActor
    _hud = region_root.get_node_or_null(^"CoreHUD") as CoreHUD
    _inventory = _player.inventory_component if _player != null else null
    if _hud != null and _hud.build_menu_panel != null:
        var menu: BuildMenuPanel = _hud.build_menu_panel
        if not menu.building_requested.is_connected(begin_placement):
            menu.building_requested.connect(begin_placement)
        if not menu.farm_plot_requested.is_connected(begin_farm_plot_placement):
            menu.farm_plot_requested.connect(begin_farm_plot_placement)
        if not menu.tool_upgrade_requested.is_connected(_on_tool_upgrade_requested):
            menu.tool_upgrade_requested.connect(_on_tool_upgrade_requested)
        if not menu.remove_mode_requested.is_connected(begin_remove_mode):
            menu.remove_mode_requested.connect(begin_remove_mode)
    set_process_unhandled_input(true)

func _refresh_available_buildings() -> void:
    available_building_ids.clear()
    for content_id: StringName in ContentDB.get_all_ids():
        var definition: BuildingDefinition = ContentDB.get_definition(content_id) as BuildingDefinition
        if definition != null and definition.tags.has(&"building"):
            available_building_ids.append(content_id)
    available_building_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))

func _process(_delta: float) -> void:
    if not _active or _remove_mode or _preview == null:
        return
    if _farm_plot_mode:
        var farm: FarmPlotSystem = _farm_system()
        if farm == null:
            return
        var cell: Vector2i = farm.world_to_farm_cell(region_root.get_global_mouse_position())
        var target: Vector2 = farm.farm_cell_to_world_center(cell)
        _preview.global_position = target
        _preview.configure(Vector2i.ONE, _is_farm_plot_position_valid(farm, cell, target))
        return
    var definition: BuildingDefinition = _selected_definition()
    if definition == null:
        return
    var target: Vector2 = _target_world_position(definition)
    _preview.global_position = target
    _preview.configure(definition.footprint_tiles, _is_position_valid(definition, target) and BuildingPlacementService.can_afford(definition, _inventory))

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"toggle_build"):
        if _active:
            _stop_mode(false)
            _open_build_menu()
        elif _hud != null and _hud.build_menu_panel != null and _hud.build_menu_panel.visible:
            _hud.build_menu_panel.close_panel()
        else:
            _open_build_menu()
        _mark_input_handled()
        return
    if not _active:
        return
    if event.is_action_pressed(&"ui_cancel"):
        _stop_mode()
        _mark_input_handled()
        return
    if _remove_mode:
        if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed:
            _try_remove_at_cursor()
            _mark_input_handled()
        return
    if event.is_action_pressed(&"ui_accept") or (event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed):
        if _farm_plot_mode:
            _try_place_farm_plot()
        else:
            _try_place_selected()
        _mark_input_handled()
        return
    if event.is_action_pressed(&"remove_building"):
        begin_remove_mode()
        _mark_input_handled()

func _open_build_menu() -> void:
    if _hud == null or _player == null:
        return
    _hud.open_build_menu(region_root, _player)

func begin_placement(building_id: StringName) -> void:
    var definition: BuildingDefinition = ContentDB.get_definition(building_id) as BuildingDefinition
    if definition == null or _player == null:
        return
    if building_id not in available_building_ids:
        available_building_ids.append(building_id)
    _stop_mode(false)
    _selected_building_id = building_id
    _active = true
    _remove_mode = false
    _farm_plot_mode = false
    _farm_plots_remaining = 0
    _player.set_input_enabled(false)
    _preview = BuildingPreview.new()
    region_root.add_child(_preview)
    _show_selected_hint()

func begin_remove_mode() -> void:
    if _player == null:
        return
    _stop_mode(false)
    _active = true
    _remove_mode = true
    _farm_plot_mode = false
    _farm_plots_remaining = 0
    _player.set_input_enabled(false)
    _status("REMOVE: click a placed building • Esc to finish")

func _stop_mode(show_message: bool = true) -> void:
    _active = false
    _remove_mode = false
    _farm_plot_mode = false
    _farm_plots_remaining = 0
    _selected_building_id = &""
    if is_instance_valid(_preview):
        _preview.queue_free()
    _preview = null
    if _player != null:
        _player.set_input_enabled(true)
    if show_message:
        _status("Build mode closed.")

func _show_selected_hint() -> void:
    var definition: BuildingDefinition = _selected_definition()
    if definition == null:
        return
    _status("PLACE: %s  |  %s  |  click/Enter place • R remove • B menu • Esc close" % [definition.display_name, BuildingPlacementService.cost_text(definition, _inventory)])

func _try_place_selected() -> void:
    var definition: BuildingDefinition = _selected_definition()
    if definition == null or _inventory == null:
        return
    var target: Vector2 = _target_world_position(definition)
    if not _is_position_valid(definition, target):
        _status("Cannot build there.")
        return
    if not BuildingPlacementService.consume_cost(definition, _inventory):
        _status("Missing building materials.")
        return
    var stable_id: StringName = StringName("placed.%s.%d" % [String(region_root.get_zone_id()), _next_serial])
    _next_serial += 1
    _spawn_building(definition, stable_id, target)
    _placed_records.append({"placement_id": String(stable_id), "building_id": String(definition.content_id), "x": target.x, "y": target.y})
    QuestService.notify_event(QuestObjectiveDefinition.Kind.PLACE_BUILDING, definition.content_id, 1)
    _status("Built %s. Place another or press B for the menu." % definition.display_name)

func begin_farm_plot_placement(plot_count: int) -> void:
    var farm: FarmPlotSystem = _farm_system()
    if farm == null or _player == null:
        _status("Farm plot placement is not available here.")
        return
    var available: int = mini(plot_count, farm.get_placeable_plot_count())
    if available <= 0:
        _status("No farm plots are unlocked to place yet.")
        return
    _stop_mode(false)
    _active = true
    _remove_mode = false
    _farm_plot_mode = true
    _farm_plots_remaining = available
    _player.set_input_enabled(false)
    _preview = BuildingPreview.new()
    region_root.add_child(_preview)
    _status("FARM PLOTS: place %d inside the marked farm space • click/Enter place • B menu • Esc close" % _farm_plots_remaining)

func _try_place_farm_plot() -> void:
    var farm: FarmPlotSystem = _farm_system()
    if farm == null:
        return
    var cell: Vector2i = farm.world_to_farm_cell(region_root.get_global_mouse_position())
    var target: Vector2 = farm.farm_cell_to_world_center(cell)
    if not _is_farm_plot_position_valid(farm, cell, target):
        _status("Farm plots can only be placed in an empty predefined farm space.")
        return
    if not farm.place_farm_plot(cell):
        _status("That farm plot cannot be placed.")
        return
    _farm_plots_remaining = mini(_farm_plots_remaining - 1, farm.get_placeable_plot_count())
    if _farm_plots_remaining <= 0:
        _status("Farm plots placed. More unlock as your Farmer level rises.")
        _stop_mode(false)
    else:
        _status("Placed farm plot. %d remaining." % _farm_plots_remaining)

func _is_farm_plot_position_valid(farm: FarmPlotSystem, cell: Vector2i, target: Vector2) -> bool:
    if farm == null or not farm.can_place_farm_plot(cell):
        return false
    var half_size: Vector2 = Vector2(WorldGrid.TILE_SIZE_PX, WorldGrid.TILE_SIZE_PX) * 0.5
    if _player != null and Rect2(target - half_size, half_size * 2.0).grow(10.0).has_point(_player.global_position):
        return false
    var buildings: Node = region_root.get_node_or_null(^"Buildings")
    if buildings != null:
        var candidate: Rect2 = Rect2(target - half_size, half_size * 2.0)
        for child: Node in buildings.get_children():
            if child is PlacedBuilding:
                var placed: PlacedBuilding = child as PlacedBuilding
                var placed_half: Vector2 = Vector2(placed.footprint_tiles * WorldGrid.TILE_SIZE_PX) * 0.5
                if candidate.intersects(Rect2(placed.global_position - placed_half, placed_half * 2.0)):
                    return false
    return true

func _farm_system() -> FarmPlotSystem:
    if region_root == null:
        return null
    return region_root.get_local_system(&"FarmPlotSystem") as FarmPlotSystem

func _on_tool_upgrade_requested(upgrade_id: StringName) -> void:
    if _player == null:
        return
    var definition: ToolUpgradeDefinition = ContentDB.get_definition(upgrade_id) as ToolUpgradeDefinition
    if definition == null:
        return
    var result: Dictionary = _tool_upgrade_service.perform_upgrade(definition, _player.inventory_component, _player.hotbar_component)
    if bool(result.get("ok", false)):
        var tool: ToolDefinition = ContentDB.get_definition(definition.to_tool_id) as ToolDefinition
        _status("Upgraded %s." % (tool.display_name if tool != null else definition.display_name))
    else:
        _status(_tool_upgrade_failure_text(str(result.get("reason", "invalid"))))
    if _hud != null and _hud.build_menu_panel != null:
        _hud.build_menu_panel.refresh()

func _tool_upgrade_failure_text(reason: String) -> String:
    match reason:
        "missing_tool": return "You need the matching tool first."
        "materials": return "Not enough upgrade materials."
        "currency": return "Not enough coins."
        "progression": return "That upgrade is still locked."
        "inventory_full": return "No room for the upgraded tool."
        _: return "Tool upgrade failed."

func _try_remove_at_cursor() -> void:
    var buildings: Node = region_root.get_node_or_null(^"Buildings")
    if buildings == null:
        return
    var cursor: Vector2 = region_root.get_global_mouse_position()
    var nearest: PlacedBuilding = null
    var nearest_distance: float = 72.0
    for child: Node in buildings.get_children():
        if child is PlacedBuilding:
            var placed: PlacedBuilding = child as PlacedBuilding
            var distance: float = placed.global_position.distance_to(cursor)
            if placed.removable and distance < nearest_distance:
                nearest = placed
                nearest_distance = distance
    if nearest == null:
        _status("No removable building under cursor.")
        return
    var removed_id: String = String(nearest.placement_id)
    for i: int in range(_placed_records.size() - 1, -1, -1):
        if String(_placed_records[i].get("placement_id", "")) == removed_id:
            _placed_records.remove_at(i)
            break
    nearest.queue_free()
    _status("Building removed.")

func _spawn_building(definition: BuildingDefinition, stable_id: StringName, position: Vector2) -> void:
    var buildings: Node = region_root.get_node_or_null(^"Buildings")
    if buildings == null:
        return
    var placed: PlacedBuilding = PLACED_SCENE.instantiate() as PlacedBuilding
    buildings.add_child(placed)
    placed.global_position = position
    placed.configure(definition, stable_id)

func _target_world_position(definition: BuildingDefinition) -> Vector2:
    var raw: Vector2 = region_root.get_global_mouse_position()
    if definition != null and definition.grid_snapped:
        var local_raw: Vector2 = region_root.to_local(raw)
        var tile: Vector2i = WorldGrid.local_to_cell(local_raw)
        return region_root.to_global(WorldGrid.cell_to_center(tile))
    return raw

func _is_position_valid(definition: BuildingDefinition, target: Vector2) -> bool:
    if definition == null or region_root == null:
        return false
    var farm: FarmPlotSystem = _farm_system()
    if farm != null:
        var extent: Vector2i = definition.footprint_tiles
        var center_cell: Vector2i = farm.world_to_farm_cell(target)
        var start_cell: Vector2i = center_cell - Vector2i((extent.x - 1) / 2, (extent.y - 1) / 2)
        for yy: int in range(extent.y):
            for xx: int in range(extent.x):
                var cell: Vector2i = start_cell + Vector2i(xx, yy)
                if not farm.is_cell_in_build_area(cell) or farm.is_cell_in_farm(cell):
                    return false
    var half_size: Vector2 = Vector2(definition.footprint_tiles * WorldGrid.TILE_SIZE_PX) * 0.5
    if _player != null and Rect2(target - half_size, half_size * 2.0).grow(20.0).has_point(_player.global_position):
        return false
    var buildings: Node = region_root.get_node_or_null(^"Buildings")
    if buildings != null:
        var candidate: Rect2 = Rect2(target - half_size, half_size * 2.0)
        for child: Node in buildings.get_children():
            if child is PlacedBuilding:
                var placed: PlacedBuilding = child as PlacedBuilding
                var placed_half: Vector2 = Vector2(placed.footprint_tiles * WorldGrid.TILE_SIZE_PX) * 0.5
                if candidate.intersects(Rect2(placed.global_position - placed_half, placed_half * 2.0)):
                    return false
    return true

func _selected_definition() -> BuildingDefinition:
    if _selected_building_id == &"":
        return null
    return ContentDB.get_definition(_selected_building_id) as BuildingDefinition

func export_runtime_state() -> Dictionary:
    return {"placed": _placed_records.duplicate(true), "next_serial": _next_serial}

func import_runtime_state(state: Dictionary) -> void:
    _placed_records.clear()
    var records: Array = Array(state.get("placed", []))
    for value: Variant in records:
        if not value is Dictionary:
            continue
        var record: Dictionary = Dictionary(value)
        var definition: BuildingDefinition = ContentDB.get_definition(StringName(str(record.get("building_id", "")))) as BuildingDefinition
        if definition == null:
            continue
        var stable_id: StringName = StringName(str(record.get("placement_id", "")))
        var position: Vector2 = Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0)))
        _placed_records.append(record.duplicate(true))
        _spawn_building(definition, stable_id, position)
    _next_serial = maxi(int(state.get("next_serial", 1)), 1)

func _status(message: String) -> void:
    if _hud != null:
        _hud.show_status_message(message, 3.0)

func _mark_input_handled() -> void:
    var viewport: Viewport = get_viewport()
    if viewport != null:
        viewport.set_input_as_handled()
