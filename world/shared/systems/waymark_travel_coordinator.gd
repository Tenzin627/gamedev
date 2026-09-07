extends RegionLocalSystem
class_name WaymarkTravelCoordinator

var _hud: CoreHUD = null
var _origin_waymark_id: StringName = &""
var _bound_waymarks: Array[WaymarkPoint2D] = []

func _on_region_bound() -> void:
    call_deferred("_bind_loaded_waymarks_and_ui")

func _exit_tree() -> void:
    _disconnect_bound_waymarks()
    _disconnect_hud()

func _bind_loaded_waymarks_and_ui() -> void:
    if not is_inside_tree() or region_root == null:
        return
    _disconnect_bound_waymarks()
    var waymarks_container: Node = region_root.get_region_container(&"Waymarks")
    if waymarks_container != null:
        _collect_and_bind_waymarks(waymarks_container)
    _find_and_bind_hud()

func _collect_and_bind_waymarks(node: Node) -> void:
    for child: Node in node.get_children():
        if child is WaymarkPoint2D:
            var point: WaymarkPoint2D = child as WaymarkPoint2D
            if not point.travel_menu_requested.is_connected(_on_travel_menu_requested):
                point.travel_menu_requested.connect(_on_travel_menu_requested)
            if not point.waymark_activated.is_connected(_on_waymark_activated):
                point.waymark_activated.connect(_on_waymark_activated)
            _bound_waymarks.append(point)
        _collect_and_bind_waymarks(child)

func _find_and_bind_hud() -> void:
    _disconnect_hud()
    if get_tree() == null:
        return
    for node: Node in get_tree().get_nodes_in_group(&"waymark_travel_ui"):
        if node is CoreHUD:
            _hud = node as CoreHUD
            break
    if _hud == null:
        return
    if not _hud.waymark_destination_selected.is_connected(_on_destination_selected):
        _hud.waymark_destination_selected.connect(_on_destination_selected)

func _on_travel_menu_requested(origin_waymark_id: StringName, _interactor: Node) -> void:
    _origin_waymark_id = origin_waymark_id
    if _hud == null or not is_instance_valid(_hud):
        _find_and_bind_hud()
    if _hud != null:
        _hud.open_waymark_travel(origin_waymark_id)

func _on_waymark_activated(waymark_id: StringName) -> void:
    if _hud == null or not is_instance_valid(_hud):
        _find_and_bind_hud()
    var definition: WaymarkDefinition = ContentDB.get_definition(waymark_id) as WaymarkDefinition
    if _hud != null and definition != null:
        _hud.show_status_message("%s activated. Interact again to travel." % definition.display_name, 2.2)

func _on_destination_selected(destination_waymark_id: StringName) -> void:
    var definition: WaymarkDefinition = ContentDB.get_definition(destination_waymark_id) as WaymarkDefinition
    if definition == null:
        if _hud != null:
            _hud.show_status_message("Unknown Waymark destination.", 1.8)
        return
    if not WorldStateService.get_flag(definition.activation_state_key, false):
        if _hud != null:
            _hud.show_status_message("That Waymark has not been activated.", 1.8)
        return
    if destination_waymark_id == _origin_waymark_id:
        return
    if _hud != null:
        _hud.close_waymark_travel()
    SceneRouter.travel_to_zone(definition.zone_id, definition.spawn_id)

func _disconnect_bound_waymarks() -> void:
    for point: WaymarkPoint2D in _bound_waymarks:
        if not is_instance_valid(point):
            continue
        if point.travel_menu_requested.is_connected(_on_travel_menu_requested):
            point.travel_menu_requested.disconnect(_on_travel_menu_requested)
        if point.waymark_activated.is_connected(_on_waymark_activated):
            point.waymark_activated.disconnect(_on_waymark_activated)
    _bound_waymarks.clear()

func _disconnect_hud() -> void:
    if _hud != null and is_instance_valid(_hud):
        if _hud.waymark_destination_selected.is_connected(_on_destination_selected):
            _hud.waymark_destination_selected.disconnect(_on_destination_selected)
    _hud = null
